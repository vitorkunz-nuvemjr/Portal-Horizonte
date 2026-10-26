<script lang="ts">
	import {
		PROJECT_ICONS,
		PROJECT_ICON_CATEGORIES,
		getProjectIcon,
		type ProjectIcon,
		type IconCategory
	} from '$lib/project-icons';
	import { getDossierTheme } from '$lib/dossier-theme';
	import { tick } from 'svelte';

	interface Props {
		value: string;
		onChange?: (newIcon: string) => void;
		color?: string;
		disabled?: boolean;
		label?: string;
		align?: 'left' | 'right';
		compactTrigger?: boolean;
	}

	let {
		value = $bindable('storefront'),
		onChange,
		color = '#0058bd',
		disabled = false,
		label = 'Ícone',
		align = 'left',
		compactTrigger = false
	}: Props = $props();

	let isOpen = $state(false);
	let searchQuery = $state('');
	let selectedCategory = $state<IconCategory | 'all'>('all');
	let hoveredIcon = $state<ProjectIcon | null>(null);
	let expandDirection = $state<'down' | 'up'>('down');
	let horizontalAlign = $state<'left' | 'right'>('left');

	let triggerEl = $state<HTMLElement | null>(null);
	let searchInputEl = $state<HTMLInputElement | null>(null);
	let catScrollEl = $state<HTMLElement | null>(null);
	let canScrollLeft = $state(false);
	let canScrollRight = $state(false);

	const theme = $derived(getDossierTheme(color || '#0058bd'));

	const currentIcon = $derived.by(() => {
		const found = getProjectIcon(value);
		if (found) return found;
		return {
			name: value || 'storefront',
			label: value || 'Storefront',
			desc: 'Ícone Personalizado',
			category: 'teams' as IconCategory,
			tags: []
		};
	});

	const activePreviewIcon = $derived(hoveredIcon || currentIcon);

	// Filtered icons based on search query or selected category
	const filteredIcons = $derived.by(() => {
		const q = searchQuery.trim().toLowerCase();
		if (q) {
			return PROJECT_ICONS.filter((item) => {
				return (
					item.name.toLowerCase().includes(q) ||
					item.label.toLowerCase().includes(q) ||
					item.desc.toLowerCase().includes(q) ||
					item.tags.some((tag) => tag.toLowerCase().includes(q))
				);
			});
		}

		if (selectedCategory === 'all') {
			return PROJECT_ICONS;
		}

		return PROJECT_ICONS.filter((item) => item.category === selectedCategory);
	});

	// Check if search query can be used as a custom Google Material Symbol
	const cleanSearchName = $derived(
		searchQuery.trim().toLowerCase().replace(/[\s-]+/g, '_').replace(/[^a-z0-9_]/g, '')
	);

	const canUseCustomSymbol = $derived(
		cleanSearchName.length >= 2 &&
			!PROJECT_ICONS.some((ic) => ic.name.toLowerCase() === cleanSearchName)
	);

	async function computePosition() {
		await tick();
		if (!triggerEl || typeof window === 'undefined') return;
		const rect = triggerEl.getBoundingClientRect();
		const neededHeight = 390;
		const spaceBelow = window.innerHeight - rect.bottom;
		const spaceAbove = rect.top;

		if (spaceBelow < neededHeight && spaceAbove > spaceBelow) {
			expandDirection = 'up';
		} else {
			expandDirection = 'down';
		}

		if (align === 'left') {
			horizontalAlign = rect.left + 350 > window.innerWidth ? 'right' : 'left';
		} else {
			horizontalAlign = rect.right - 350 < 8 ? 'left' : 'right';
		}
	}

	function updateCategoryScrollState() {
		if (!catScrollEl) return;
		canScrollLeft = catScrollEl.scrollLeft > 2;
		canScrollRight =
			catScrollEl.scrollLeft + catScrollEl.clientWidth < catScrollEl.scrollWidth - 2;
	}

	function scrollCategories(amount: number) {
		if (!catScrollEl) return;
		catScrollEl.scrollBy({ left: amount, behavior: 'smooth' });
	}

	function chooseCategory(catId: IconCategory | 'all', el?: HTMLElement) {
		selectedCategory = catId;
		if (catId !== 'all') {
			searchQuery = '';
		}
		if (el && catScrollEl) {
			el.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
		}
		setTimeout(updateCategoryScrollState, 150);
	}

	function toggleOpen(e: MouseEvent) {
		e.stopPropagation();
		if (disabled) return;
		isOpen = !isOpen;
		if (isOpen) {
			searchQuery = '';
			selectedCategory = 'all';
			hoveredIcon = null;
			computePosition();
			tick().then(() => {
				searchInputEl?.focus();
				updateCategoryScrollState();
			});
		}
	}

	function selectIcon(iconName: string) {
		if (disabled) return;
		value = iconName;
		onChange?.(iconName);
		isOpen = false;
	}

	function handleSearchKeydown(e: KeyboardEvent) {
		if (e.key === 'Escape') {
			isOpen = false;
		} else if (e.key === 'Enter') {
			if (filteredIcons.length > 0) {
				e.preventDefault();
				selectIcon(filteredIcons[0].name);
			} else if (canUseCustomSymbol) {
				e.preventDefault();
				selectIcon(cleanSearchName);
			}
		}
	}
</script>

<div class="relative inline-block select-none" bind:this={triggerEl}>
	<!-- Trigger Keycap Button matching PaperColorPicker -->
	<button
		type="button"
		onclick={toggleOpen}
		{disabled}
		class="group inline-flex items-center gap-2 rounded-xl bg-white/95 hover:bg-white px-2.5 py-1.5 border border-[#cfc5b4] shadow-[0_2px_0_#d8d2c2,inset_0_1px_0_#ffffff] active:translate-y-0.5 transition-all cursor-pointer disabled:opacity-60 disabled:cursor-not-allowed"
		title="Selecionar ícone da equipe e diretoria"
	>
		<!-- Dual-tone icon indicator: selected icon with dynamic team color tone -->
		<span
			class="relative flex items-center justify-center w-6 h-6 rounded-md border border-black/15 shadow-xs overflow-hidden shrink-0 transition-colors"
			style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder};"
		>
			<span class="material-symbols-outlined text-[17px]" style="color: {theme.accent};">
				{value || 'storefront'}
			</span>
		</span>

		{#if !compactTrigger}
			<span class="font-mono text-[10px] uppercase font-bold text-[#424753] tracking-wider hidden sm:inline">
				{label}:
			</span>
			<span
				class="font-mono text-[10.5px] font-bold px-1.5 py-0.5 rounded border max-w-[110px] truncate"
				style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
			>
				{currentIcon.label}
			</span>
		{/if}

		<span
			class="material-symbols-outlined text-[15px] text-[#727784] group-hover:text-[#1d1b17] transition-transform {isOpen
				? 'rotate-180'
				: ''}"
		>
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

		<!-- Floating Paper Strategist Icon Picker Popover -->
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_static_element_interactions -->
		<div
			onclick={(e) => e.stopPropagation()}
			class="fixed inset-x-3 top-20 mx-auto max-w-[356px] sm:mx-0 sm:inset-x-auto sm:absolute z-[130] sm:w-[356px] rounded-2xl bg-[#fff8f2] border-2 border-[#cfc5b4] p-3 shadow-[0_20px_50px_rgba(29,27,23,0.26),0_4px_14px_rgba(29,27,23,0.1),inset_0_1px_0_#ffffff] flex flex-col gap-2.5 animate-in fade-in zoom-in-95 duration-150 {expandDirection ===
			'up'
				? 'sm:top-auto sm:bottom-full sm:mb-2'
				: 'sm:top-full sm:mt-2'} {horizontalAlign === 'right' ? 'sm:right-0' : 'sm:left-0'}"
		>
			<!-- Top Header Bar (Stationery Inspector Header) -->
			<div
				class="flex items-center justify-between px-2.5 py-1.5 rounded-xl bg-[#f3ede6] border border-[#e2d9cd] shadow-[inset_0_1px_3px_rgba(36,34,30,0.06)]"
			>
				<div class="flex items-center gap-2">
					<span
						class="w-5 h-5 rounded-full flex items-center justify-center text-white shadow-xs shrink-0"
						style="background-color: {theme.accent};"
					>
						<span class="material-symbols-outlined text-[13px]">{value || 'category'}</span>
					</span>
					<span class="font-mono text-[10px] font-bold uppercase tracking-wider text-[#424753]">
						Ícones do Projeto
					</span>
				</div>

				<!-- Count / Keyboard Hint Pill -->
				<div class="flex items-center gap-1.5">
					<span
						class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md font-mono text-[10px] font-bold border shadow-2xs"
						style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
					>
						<span class="w-1.5 h-1.5 rounded-full" style="background-color: {theme.accent};"></span>
						<span>{filteredIcons.length} ícones</span>
					</span>
				</div>
			</div>

			<!-- SEARCH TOOL: Search Input with Magnifier & Clear Button -->
			<div
				class="relative flex items-center rounded-xl bg-[#f3ede6] border border-[#cfc5b4] px-2.5 py-1.5 shadow-[inset_0_1px_3px_rgba(36,34,30,0.08)] focus-within:border-[#0058bd] focus-within:ring-2 focus-within:ring-[#0058bd]/20 transition-all"
			>
				<span class="material-symbols-outlined text-[17px] text-[#727784] shrink-0 mr-1.5">
					search
				</span>
				<input
					bind:this={searchInputEl}
					type="text"
					bind:value={searchQuery}
					onkeydown={handleSearchKeydown}
					placeholder="Buscar ícone (ex: vendas, tech, pessoas)..."
					class="w-full bg-transparent border-0 p-0 text-[12px] font-sans font-medium text-[#1d1b17] placeholder:text-[#9c9589] focus:outline-none focus:ring-0"
				/>
				{#if searchQuery}
					<button
						type="button"
						onclick={() => {
							searchQuery = '';
							searchInputEl?.focus();
						}}
						class="p-0.5 hover:bg-black/10 rounded-full text-[#727784] hover:text-[#1d1b17] transition-colors shrink-0"
						title="Limpar busca"
					>
						<span class="material-symbols-outlined text-[14px]">close</span>
					</button>
				{/if}
			</div>

			<!-- EMOJI KEYBOARD STYLE CATEGORY TABS WITH ARROWS & SCROLLBAR -->
			<div class="relative flex items-center gap-1">
				<!-- Left Arrow Button -->
				<button
					type="button"
					onclick={() => scrollCategories(-120)}
					disabled={!canScrollLeft}
					class="w-6 h-7 rounded-lg bg-[#f3ede6] hover:bg-[#e8e0d5] text-[#524d45] border border-[#cfc5b4]/70 flex items-center justify-center shrink-0 transition-all disabled:opacity-25 disabled:cursor-not-allowed cursor-pointer shadow-2xs active:scale-95"
					title="Rolar categorias para a esquerda"
					aria-label="Rolar categorias para a esquerda"
				>
					<span class="material-symbols-outlined text-[15px]">chevron_left</span>
				</button>

				<!-- Scrollable Category Track with Left/Right Navigation -->
				<div
					bind:this={catScrollEl}
					onscroll={updateCategoryScrollState}
					class="flex-1 flex items-center gap-1 overflow-x-auto py-0.5 px-0.5 no-scrollbar scroll-smooth select-none"
				>
					<button
						type="button"
						onclick={(e) => chooseCategory('all', e.currentTarget as HTMLElement)}
						class="flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10.5px] font-mono font-bold transition-all shrink-0 cursor-pointer {selectedCategory ===
						'all'
							? 'text-white shadow-xs'
							: 'bg-[#f3ede6] hover:bg-[#e8e0d5] text-[#524d45] border border-[#cfc5b4]/50'}"
						style={selectedCategory === 'all'
							? `background-color: ${theme.accent};`
							: ''}
						title="Todos os ícones"
					>
						<span class="material-symbols-outlined text-[13px]">apps</span>
						<span>Todos</span>
					</button>

					{#each PROJECT_ICON_CATEGORIES as cat (cat.id)}
						{@const isActive = selectedCategory === cat.id}
						<button
							type="button"
							onclick={(e) => chooseCategory(cat.id, e.currentTarget as HTMLElement)}
							class="flex items-center gap-1 px-2.5 py-1 rounded-lg text-[10.5px] font-mono font-bold transition-all shrink-0 cursor-pointer {isActive
								? 'text-white shadow-xs'
								: 'bg-[#f3ede6] hover:bg-[#e8e0d5] text-[#524d45] border border-[#cfc5b4]/50'}"
							style={isActive ? `background-color: ${theme.accent};` : ''}
							title={cat.label}
						>
							<span class="material-symbols-outlined text-[13px]">{cat.icon}</span>
							<span>{cat.label.split(' ')[0]}</span>
						</button>
					{/each}
				</div>

				<!-- Right Arrow Button -->
				<button
					type="button"
					onclick={() => scrollCategories(120)}
					disabled={!canScrollRight}
					class="w-6 h-7 rounded-lg bg-[#f3ede6] hover:bg-[#e8e0d5] text-[#524d45] border border-[#cfc5b4]/70 flex items-center justify-center shrink-0 transition-all disabled:opacity-25 disabled:cursor-not-allowed cursor-pointer shadow-2xs active:scale-95"
					title="Rolar categorias para a direita"
					aria-label="Rolar categorias para a direita"
				>
					<span class="material-symbols-outlined text-[15px]">chevron_right</span>
				</button>
			</div>

			<!-- EMOJI KEYBOARD STYLE ICON GRID -->
			<div class="max-h-[210px] overflow-y-auto custom-scroll pr-1 space-y-2">
				{#if searchQuery.trim() === '' && selectedCategory === 'all'}
					<!-- Grouped view like iOS / Slack emoji picker -->
					{#each PROJECT_ICON_CATEGORIES as cat (cat.id)}
						{@const catIcons = PROJECT_ICONS.filter((ic) => ic.category === cat.id)}
						{#if catIcons.length > 0}
							<div>
								<div class="flex items-center gap-1.5 px-1 pb-1 pt-0.5">
									<span class="material-symbols-outlined text-[12px] text-[#727784]">{cat.icon}</span>
									<span class="font-mono text-[9.5px] font-bold uppercase tracking-wider text-[#727784]">
										{cat.label}
									</span>
								</div>
								<div class="grid grid-cols-6 sm:grid-cols-7 gap-1.5">
									{#each catIcons as ic (ic.name)}
										{@const isSelected = value === ic.name}
										<button
											type="button"
											onclick={() => selectIcon(ic.name)}
											onmouseenter={() => (hoveredIcon = ic)}
											onmouseleave={() => (hoveredIcon = null)}
											class="h-9 w-full rounded-xl flex items-center justify-center transition-all cursor-pointer {isSelected
												? 'text-white shadow-md ring-2 ring-offset-1 ring-offset-[#fff8f2] scale-105'
												: 'bg-white/85 hover:bg-white text-[#424753] hover:text-[#1d1b17] border border-[#cfc5b4]/70 hover:border-[#1d1b17]/40 hover:scale-110 active:scale-95 shadow-2xs'}"
											style={isSelected
												? `background-color: ${theme.accent}; ring-color: ${theme.accent};`
												: ''}
											title="{ic.label} ({ic.desc})"
										>
											<span class="material-symbols-outlined text-[19px]">{ic.name}</span>
										</button>
									{/each}
								</div>
							</div>
						{/if}
					{/each}
				{:else if filteredIcons.length > 0}
					<!-- Flat Grid View for searched or category-filtered icons -->
					<div class="grid grid-cols-6 sm:grid-cols-7 gap-1.5 pt-0.5">
						{#each filteredIcons as ic (ic.name)}
							{@const isSelected = value === ic.name}
							<button
								type="button"
								onclick={() => selectIcon(ic.name)}
								onmouseenter={() => (hoveredIcon = ic)}
								onmouseleave={() => (hoveredIcon = null)}
								class="h-9 w-full rounded-xl flex items-center justify-center transition-all cursor-pointer {isSelected
									? 'text-white shadow-md ring-2 ring-offset-1 ring-offset-[#fff8f2] scale-105'
									: 'bg-white/85 hover:bg-white text-[#424753] hover:text-[#1d1b17] border border-[#cfc5b4]/70 hover:border-[#1d1b17]/40 hover:scale-110 active:scale-95 shadow-2xs'}"
								style={isSelected
									? `background-color: ${theme.accent}; ring-color: ${theme.accent};`
									: ''}
								title="{ic.label} ({ic.desc})"
							>
								<span class="material-symbols-outlined text-[19px]">{ic.name}</span>
							</button>
						{/each}
					</div>
				{:else}
					<!-- Empty state when no icons match -->
					<div class="py-6 px-3 text-center space-y-2">
						<span class="material-symbols-outlined text-[28px] text-[#9c9589]">search_off</span>
						<p class="text-[12px] text-[#524d45] font-medium">
							Nenhum ícone encontrado para <span class="font-bold">"{searchQuery}"</span>
						</p>
					</div>
				{/if}

				<!-- Extensibility Fallback: Allow selecting ANY custom Material Symbol typed by user -->
				{#if canUseCustomSymbol}
					<div class="pt-2 border-t border-dashed border-[#d5cebe]">
						<button
							type="button"
							onclick={() => selectIcon(cleanSearchName)}
							class="w-full p-2 rounded-xl bg-white/90 hover:bg-white border border-[#cfc5b4] hover:border-[#0058bd] flex items-center justify-between gap-2 text-left transition-all cursor-pointer group shadow-xs"
						>
							<div class="flex items-center gap-2 min-w-0">
								<span
									class="w-7 h-7 rounded-lg flex items-center justify-center shrink-0 border"
									style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.accent};"
								>
									<span class="material-symbols-outlined text-[18px]">{cleanSearchName}</span>
								</span>
								<div class="min-w-0">
									<div class="text-[11px] font-bold text-[#1d1b17] truncate">
										Usar símbolo "{cleanSearchName}"
									</div>
									<div class="text-[9.5px] text-[#727784] font-mono">
										Google Material Symbol
									</div>
								</div>
							</div>
							<span
								class="material-symbols-outlined text-[16px] text-[#727784] group-hover:text-[#0058bd] group-hover:translate-x-0.5 transition-all"
							>
								arrow_forward
							</span>
						</button>
					</div>
				{/if}
			</div>

			<!-- FOOTER PREVIEW BAR (Matches PaperColorPicker stationery preview strip) -->
			<div
				class="flex items-center justify-between px-3 py-2 rounded-xl border text-[11px] transition-colors"
				style="background-color: {theme.folderBg}; border-color: {theme.folderBorder}; color: {theme.accentShadow};"
			>
				<div class="flex items-center gap-2 min-w-0">
					<span
						class="w-7 h-7 rounded-lg flex items-center justify-center shrink-0 border shadow-2xs"
						style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.accent};"
					>
						<span class="material-symbols-outlined text-[18px]">
							{activePreviewIcon.name}
						</span>
					</span>
					<div class="min-w-0 flex flex-col">
						<span class="font-bold truncate text-[11.5px] leading-tight text-[#1d1b17]">
							{activePreviewIcon.label}
						</span>
						<span class="text-[9.5px] text-[#524d45] truncate font-sans">
							{activePreviewIcon.desc}
						</span>
					</div>
				</div>

				<span
					class="font-mono text-[9.5px] font-bold px-2 py-0.5 rounded-md border shrink-0"
					style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
				>
					{activePreviewIcon.name}
				</span>
			</div>
		</div>
	{/if}
</div>

<style>
	.no-scrollbar::-webkit-scrollbar {
		display: none;
	}
	.no-scrollbar {
		-ms-overflow-style: none;
		scrollbar-width: none;
	}
</style>
