<script lang="ts">
	import {
		PROJECT_MAIN_COLORS,
		getDossierTheme,
		hsvToRgb,
		parseHexToRgb,
		rgbToHex,
		rgbToHsv,
		type ColorPreset
	} from '$lib/dossier-theme';
	import { tick } from 'svelte';

	interface Props {
		value: string;
		onChange?: (newHex: string) => void;
		presets?: ColorPreset[];
		disabled?: boolean;
		label?: string;
		align?: 'left' | 'right';
		compactTrigger?: boolean;
	}

	let {
		value = $bindable('#0058bd'),
		onChange,
		presets = PROJECT_MAIN_COLORS,
		disabled = false,
		label = 'Cor',
		align = 'right',
		compactTrigger = false
	}: Props = $props();

	let isOpen = $state(false);
	let isExpanded = $state(false);
	let expandDirection = $state<'down' | 'up'>('down');
	let horizontalAlign = $state<'left' | 'right'>('right');

	let triggerEl = $state<HTMLElement | null>(null);
	let svBoxEl = $state<HTMLElement | null>(null);
	let hueBarEl = $state<HTMLElement | null>(null);
	let satBarEl = $state<HTMLElement | null>(null);

	// Internal HSV state for the 2D picker & sliders
	let h = $state(212);
	let s = $state(100);
	let v = $state(74);
	let hexInputText = $state('#0058BD');
	let isDraggingSv = $state(false);
	let isDraggingHue = $state(false);
	let isDraggingSat = $state(false);

	// Sync HSV when external `value` changes (and user is not actively dragging)
	$effect(() => {
		if (!isDraggingSv && !isDraggingHue && !isDraggingSat) {
			const [r, g, b] = parseHexToRgb(value);
			const [nh, ns, nv] = rgbToHsv(r, g, b);
			// Preserve hue if saturation is 0
			if (ns > 0) h = nh;
			s = ns;
			v = nv;
			hexInputText = rgbToHex(r, g, b).toUpperCase();
		}
	});

	const theme = $derived(getDossierTheme(value));

	const isPresetSelected = $derived(
		presets.some((p) => p.hex.toLowerCase() === (value || '').trim().toLowerCase())
	);

	function applyHsv(nh: number, ns: number, nv: number) {
		h = Math.max(0, Math.min(360, Math.round(nh)));
		s = Math.max(0, Math.min(100, Math.round(ns)));
		v = Math.max(0, Math.min(100, Math.round(nv)));
		const [r, g, b] = hsvToRgb(h, s, v);
		const nextHex = rgbToHex(r, g, b);
		value = nextHex;
		hexInputText = nextHex.toUpperCase();
		onChange?.(nextHex);
	}

	function selectPreset(hex: string) {
		if (disabled) return;
		const [r, g, b] = parseHexToRgb(hex);
		const [nh, ns, nv] = rgbToHsv(r, g, b);
		if (ns > 0) h = nh;
		s = ns;
		v = nv;
		const normalized = rgbToHex(r, g, b);
		value = normalized;
		hexInputText = normalized.toUpperCase();
		onChange?.(normalized);
	}

	async function computePosition() {
		await tick();
		if (!triggerEl || typeof window === 'undefined') return;
		const rect = triggerEl.getBoundingClientRect();
		const neededHeight = isExpanded ? 330 : 120;
		const spaceBelow = window.innerHeight - rect.bottom;
		const spaceAbove = rect.top;

		if (spaceBelow < neededHeight && spaceAbove > spaceBelow) {
			expandDirection = 'up';
		} else {
			expandDirection = 'down';
		}

		if (align === 'left') {
			horizontalAlign = rect.left + 320 > window.innerWidth ? 'right' : 'left';
		} else {
			horizontalAlign = rect.right - 320 < 8 ? 'left' : 'right';
		}
	}

	function toggleOpen(e: MouseEvent) {
		e.stopPropagation();
		if (disabled) return;
		isOpen = !isOpen;
		if (isOpen) {
			// Always open first in the compact mode showing the main project colors
			isExpanded = false;
			computePosition();
		}
	}

	function toggleExpandCustom(e: MouseEvent) {
		e.stopPropagation();
		if (disabled) return;
		isExpanded = !isExpanded;
		computePosition();
	}

	function handleHexInput(e: Event) {
		const target = e.target as HTMLInputElement;
		let raw = target.value.trim();
		if (!raw.startsWith('#')) {
			raw = '#' + raw.replace(/#/g, '');
		}
		hexInputText = raw.toUpperCase();

		const clean = raw.replace(/^#/, '');
		if (/^[0-9a-fA-F]{6}$/.test(clean)) {
			const [r, g, b] = parseHexToRgb(raw);
			const [nh, ns, nv] = rgbToHsv(r, g, b);
			if (ns > 0) h = nh;
			s = ns;
			v = nv;
			const normalized = rgbToHex(r, g, b);
			value = normalized;
			onChange?.(normalized);
		}
	}

	function handleHexBlur() {
		const clean = hexInputText.replace(/^#/, '');
		if (/^[0-9a-fA-F]{3}$/.test(clean) || /^[0-9a-fA-F]{6}$/.test(clean)) {
			const [r, g, b] = parseHexToRgb(clean);
			const normalized = rgbToHex(r, g, b);
			value = normalized;
			hexInputText = normalized.toUpperCase();
			onChange?.(normalized);
		} else {
			hexInputText = (value || '#0058bd').toUpperCase();
		}
	}

	// Pointer dragging for 2D SV Canvas
	function updateSvFromPointer(clientX: number, clientY: number) {
		if (!svBoxEl) return;
		const rect = svBoxEl.getBoundingClientRect();
		const relX = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
		const relY = Math.max(0, Math.min(1, (clientY - rect.top) / rect.height));
		applyHsv(h, relX * 100, (1 - relY) * 100);
	}

	function onSvPointerDown(e: PointerEvent) {
		if (disabled) return;
		e.preventDefault();
		e.stopPropagation();
		isDraggingSv = true;
		(e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
		updateSvFromPointer(e.clientX, e.clientY);
	}

	function onSvPointerMove(e: PointerEvent) {
		if (!isDraggingSv) return;
		updateSvFromPointer(e.clientX, e.clientY);
	}

	function onSvPointerUp(e: PointerEvent) {
		if (!isDraggingSv) return;
		isDraggingSv = false;
		try {
			(e.currentTarget as HTMLElement).releasePointerCapture(e.pointerId);
		} catch {}
	}

	// Pointer dragging for Hue Bar
	function updateHueFromPointer(clientX: number) {
		if (!hueBarEl) return;
		const rect = hueBarEl.getBoundingClientRect();
		const relX = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
		applyHsv(relX * 360, s === 0 ? 75 : s, v < 15 ? 80 : v);
	}

	function onHuePointerDown(e: PointerEvent) {
		if (disabled) return;
		e.preventDefault();
		e.stopPropagation();
		isDraggingHue = true;
		(e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
		updateHueFromPointer(e.clientX);
	}

	function onHuePointerMove(e: PointerEvent) {
		if (!isDraggingHue) return;
		updateHueFromPointer(e.clientX);
	}

	function onHuePointerUp(e: PointerEvent) {
		if (!isDraggingHue) return;
		isDraggingHue = false;
		try {
			(e.currentTarget as HTMLElement).releasePointerCapture(e.pointerId);
		} catch {}
	}

	// Pointer dragging for Saturation / Tone Bar
	function updateSatFromPointer(clientX: number) {
		if (!satBarEl) return;
		const rect = satBarEl.getBoundingClientRect();
		const relX = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
		applyHsv(h, relX * 100, v);
	}

	function onSatPointerDown(e: PointerEvent) {
		if (disabled) return;
		e.preventDefault();
		e.stopPropagation();
		isDraggingSat = true;
		(e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
		updateSatFromPointer(e.clientX);
	}

	function onSatPointerMove(e: PointerEvent) {
		if (!isDraggingSat) return;
		updateSatFromPointer(e.clientX);
	}

	function onSatPointerUp(e: PointerEvent) {
		if (!isDraggingSat) return;
		isDraggingSat = false;
		try {
			(e.currentTarget as HTMLElement).releasePointerCapture(e.pointerId);
		} catch {}
	}

	const pureHueHex = $derived.by(() => {
		const [r, g, b] = hsvToRgb(h, 100, 100);
		return rgbToHex(r, g, b);
	});
</script>

<div class="relative inline-block select-none" bind:this={triggerEl}>
	<!-- Trigger Keycap Button -->
	<button
		type="button"
		onclick={toggleOpen}
		{disabled}
		class="group inline-flex items-center gap-2 rounded-xl bg-white/95 hover:bg-white px-2.5 py-1.5 border border-[#cfc5b4] shadow-[0_2px_0_#d8d2c2,inset_0_1px_0_#ffffff] active:translate-y-0.5 transition-all cursor-pointer disabled:opacity-60 disabled:cursor-not-allowed"
		title="Selecionar cor do cartão e dossiê"
	>
		<!-- Dual-tone swatch indicator: selected color + muted card preview -->
		<span class="relative flex items-center justify-center w-5 h-5 rounded-md border border-black/15 shadow-xs overflow-hidden shrink-0" style="background-color: {theme.badgeBg};">
			<span
				class="w-3 h-3 rounded-[4px] shadow-xs"
				style="background-color: {theme.accent};"
			></span>
		</span>

		{#if !compactTrigger}
			<span class="font-mono text-[10px] uppercase font-bold text-[#424753] tracking-wider hidden sm:inline">
				{label}:
			</span>
			<span
				class="font-mono text-[10.5px] font-bold px-1.5 py-0.5 rounded border hidden min-[420px]:inline"
				style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
			>
				{theme.rawHex.toUpperCase()}
			</span>
		{/if}

		<span class="material-symbols-outlined text-[15px] text-[#727784] group-hover:text-[#1d1b17] transition-transform {isOpen ? 'rotate-180' : ''}">
			expand_more
		</span>
	</button>

	{#if isOpen}
		<!-- Invisible backdrop to close on outside click -->
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_static_element_interactions -->
		<div
			class="fixed inset-0 z-[120]"
			onclick={(e) => {
				e.stopPropagation();
				isOpen = false;
			}}
		></div>

		<!-- Floating Paper Strategist Color Picker Popover -->
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_static_element_interactions -->
		<div
			onclick={(e) => e.stopPropagation()}
			class="fixed inset-x-3 top-20 mx-auto max-w-[336px] sm:mx-0 sm:inset-x-auto sm:absolute z-[130] sm:w-[336px] rounded-2xl bg-[#fff8f2] border-2 border-[#cfc5b4] p-3 shadow-[0_20px_50px_rgba(29,27,23,0.26),0_4px_14px_rgba(29,27,23,0.1),inset_0_1px_0_#ffffff] flex flex-col gap-2.5 animate-in fade-in zoom-in-95 duration-150 {expandDirection === 'up'
				? 'sm:top-auto sm:bottom-full sm:mb-2'
				: 'sm:top-full sm:mt-2'} {horizontalAlign === 'right' ? 'sm:right-0' : 'sm:left-0'}"
		>
			<!-- Top Header Bar (Stationery Inspector Header) -->
			<div class="flex items-center justify-between px-2.5 py-1.5 rounded-xl bg-[#f3ede6] border border-[#e2d9cd] shadow-[inset_0_1px_3px_rgba(36,34,30,0.06)]">
				<div class="flex items-center gap-2">
					<span
						class="w-5 h-5 rounded-full flex items-center justify-center text-white shadow-xs shrink-0"
						style="background-color: {theme.accent};"
					>
						<span class="material-symbols-outlined text-[12px]">palette</span>
					</span>
					<span class="font-mono text-[10px] font-bold uppercase tracking-wider text-[#424753]">
						Paleta do Projeto
					</span>
				</div>

				<!-- Muted Card Preview Pill -->
				<div class="flex items-center gap-1.5">
					<span
						class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md font-mono text-[10px] font-bold border shadow-2xs"
						style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
						title="Tom suave aplicado nos cards e chips"
					>
						<span class="w-1.5 h-1.5 rounded-full" style="background-color: {theme.accent};"></span>
						<span>Tom Suave</span>
					</span>
				</div>
			</div>

			<!-- STAGE 1: Main Project Colour Swatches Row + Last Option '+' Rainbow Expander -->
			<div class="grid grid-cols-9 gap-1.5 items-center px-0.5 py-0.5">
				{#each presets as sw (sw.hex)}
					{@const isSelected = (value || '').trim().toLowerCase() === sw.hex.toLowerCase()}
					{@const swTheme = getDossierTheme(sw.hex)}
					<button
						type="button"
						onclick={() => selectPreset(sw.hex)}
						class="relative h-7 w-full rounded-lg border transition-all cursor-pointer flex items-center justify-center hover:-translate-y-0.5 active:translate-y-0.5 {isSelected
							? 'ring-2 ring-[#1d1b17] ring-offset-1 ring-offset-[#fff8f2] scale-105'
							: 'border-black/15 opacity-90 hover:opacity-100'}"
						style="background-color: {sw.hex}; box-shadow: 0 2px 0 {swTheme.accentShadow}, inset 0 1px 0 rgba(255,255,255,0.28);"
						title="{sw.name} ({sw.hex})"
					>
						{#if isSelected}
							<span class="w-1.5 h-1.5 rounded-full bg-white shadow-[0_1px_2px_rgba(0,0,0,0.6)]"></span>
						{/if}
					</button>
				{/each}

				<!-- LAST OPTION: Rainbow '+' Button to Expand Full Custom Picker -->
				<button
					type="button"
					onclick={toggleExpandCustom}
					class="relative h-7 w-full rounded-lg border border-black/20 transition-all cursor-pointer flex items-center justify-center hover:-translate-y-0.5 active:translate-y-0.5 {isExpanded || !isPresetSelected
						? 'ring-2 ring-[#1d1b17] ring-offset-1 ring-offset-[#fff8f2] scale-105'
						: ''}"
					style="background: linear-gradient(135deg, #ff2a54 0%, #ff8800 22%, #ffe327 42%, #10b981 62%, #3080f9 82%, #9333ea 100%); box-shadow: 0 2px 0 #524d45, inset 0 1px 0 rgba(255,255,255,0.4);"
					title={isExpanded ? 'Recolher seletor avançado' : 'Personalizar cor e código Hex (+)'}
				>
					<span
						class="material-symbols-outlined text-[16px] font-black text-white drop-shadow-[0_1px_2px_rgba(0,0,0,0.65)] transition-transform duration-200 {isExpanded ? 'rotate-45' : ''}"
					>
						add
					</span>
				</button>
			</div>

			<!-- STAGE 2: Expanded Full Color Picker (2D SV Canvas + Hue & Tone Sliders + Hex Input) -->
			{#if isExpanded}
				<div class="pt-2 border-t border-dashed border-[#d5cebe] flex flex-col gap-2.5 animate-in fade-in slide-in-from-top-1 duration-150">
					<!-- 2D Saturation / Value Gradient Box -->
					<div
						bind:this={svBoxEl}
						onpointerdown={onSvPointerDown}
						onpointermove={onSvPointerMove}
						onpointerup={onSvPointerUp}
						onpointercancel={onSvPointerUp}
						class="relative w-full h-36 rounded-xl border border-[#cfc5b4] shadow-[inset_0_2px_4px_rgba(29,27,23,0.15)] cursor-crosshair overflow-hidden touch-none select-none"
						style="background-color: {pureHueHex};"
					>
						<!-- White to Transparent Horizontal Gradient -->
						<div
							class="absolute inset-0 pointer-events-none"
							style="background: linear-gradient(to right, #ffffff 0%, rgba(255,255,255,0) 100%);"
						></div>
						<!-- Transparent to Black Vertical Gradient -->
						<div
							class="absolute inset-0 pointer-events-none"
							style="background: linear-gradient(to bottom, rgba(0,0,0,0) 0%, #000000 100%);"
						></div>

						<!-- Circular Thumb Indicator -->
						<div
							class="absolute w-4 h-4 -ml-2 -mt-2 rounded-full border-2 border-white shadow-[0_1px_4px_rgba(0,0,0,0.65),inset_0_0_2px_rgba(0,0,0,0.3)] pointer-events-none"
							style="left: {s}%; top: {100 - v}%; background-color: {value};"
						></div>
					</div>

					<!-- Bottom Controls Row: Two Sliders on Left + Hex Input Box on Right -->
					<div class="flex items-center gap-2.5">
						<div class="flex-1 flex flex-col gap-2">
							<!-- Slider 1: Rainbow Hue Bar -->
							<div
								bind:this={hueBarEl}
								onpointerdown={onHuePointerDown}
								onpointermove={onHuePointerMove}
								onpointerup={onHuePointerUp}
								onpointercancel={onHuePointerUp}
								class="relative h-3.5 w-full rounded-full border border-black/15 shadow-inner cursor-pointer touch-none select-none"
								style="background: linear-gradient(to right, #ff0000 0%, #ffff00 17%, #00ff00 33%, #00ffff 50%, #0000ff 67%, #ff00ff 83%, #ff0000 100%);"
							>
								<div
									class="absolute top-1/2 -translate-y-1/2 -ml-2 w-4 h-4 rounded-full border-2 border-white shadow-[0_1px_3px_rgba(0,0,0,0.5)] pointer-events-none"
									style="left: {(h / 360) * 100}%; background-color: {pureHueHex};"
								></div>
							</div>

							<!-- Slider 2: Tone / Saturation Intensity Bar with Drafting Grid Pattern -->
							<div
								bind:this={satBarEl}
								onpointerdown={onSatPointerDown}
								onpointermove={onSatPointerMove}
								onpointerup={onSatPointerUp}
								onpointercancel={onSatPointerUp}
								class="relative h-3.5 w-full rounded-full border border-[#cfc5b4] overflow-hidden cursor-pointer touch-none select-none"
								style="background-image: linear-gradient(45deg, #d5cebe 25%, transparent 25%), linear-gradient(-45deg, #d5cebe 25%, transparent 25%), linear-gradient(45deg, transparent 75%, #d5cebe 75%), linear-gradient(-45deg, transparent 75%, #d5cebe 75%); background-size: 8px 8px; background-position: 0 0, 0 4px, 4px -4px, -4px 0;"
							>
								<div
									class="absolute inset-0 pointer-events-none"
									style="background: linear-gradient(to right, rgba(243,237,230,0.85) 0%, {pureHueHex} 100%);"
								></div>
								<div
									class="absolute top-1/2 -translate-y-1/2 -ml-2 w-4 h-4 rounded-full border-2 border-white shadow-[0_1px_3px_rgba(0,0,0,0.5)] pointer-events-none"
									style="left: {s}%; background-color: {theme.accent};"
								></div>
							</div>
						</div>

						<!-- Hex Code Input Well (#7038F4) -->
						<div
							class="w-[98px] shrink-0 rounded-xl bg-[#f3ede6] border border-[#cfc5b4] px-2.5 py-2 shadow-[inset_0_2px_4px_rgba(36,34,30,0.08),0_1px_0_#ffffff] focus-within:border-[#0058bd] focus-within:ring-2 focus-within:ring-[#0058bd]/20 transition-all"
						>
							<input
								type="text"
								maxlength="7"
								value={hexInputText}
								oninput={handleHexInput}
								onblur={handleHexBlur}
								aria-label="Código Hex da cor"
								placeholder="#0058BD"
								class="w-full bg-transparent border-0 p-0 text-center font-mono text-[12px] font-bold tracking-tight text-[#1d1b17] focus:outline-none focus:ring-0 uppercase"
							/>
						</div>
					</div>

					<!-- Vibrant Light Card & Chip Preview Strip -->
					<div
						class="flex items-center justify-between px-3 py-2 rounded-xl border text-[11px] transition-colors"
						style="background-color: {theme.folderBg}; border-color: {theme.folderBorder}; color: {theme.accentShadow};"
					>
						<div class="flex items-center gap-2 min-w-0">
							<span class="w-2.5 h-2.5 rounded-full shrink-0" style="background-color: {theme.accent};"></span>
							<span class="font-bold truncate">Prévia do Card &amp; Texto</span>
						</div>
						<span
							class="font-mono text-[10px] font-bold px-2 py-0.5 rounded-md border shrink-0"
							style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
						>
							Chip / Tag
						</span>
					</div>
				</div>
			{/if}
		</div>
	{/if}
</div>
