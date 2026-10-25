<script lang="ts">
	import { enhance } from '$app/forms';
	import type { NodeWithExtras, StrategicEra, StrategyNode } from '$lib/types';
	import { enhanceFormValidation, formatNumber } from '$lib/utils';
	import { getDossierTheme } from '$lib/dossier-theme';
	import PaperColorPicker from '$lib/components/ui/PaperColorPicker.svelte';
	import PaperIconPicker from '$lib/components/ui/PaperIconPicker.svelte';
	import { AlertCircle } from 'lucide-svelte';
	import { onMount } from 'svelte';

	interface Props {
		mode: 'create' | 'edit';
		valueNode: NodeWithExtras | null;
		era: StrategicEra;
		stats?: { total: number; okrs: number; krs: number; kpis: number; avgPct: number };
		alignedNodes?: NodeWithExtras[];
		canEdit: boolean;
		onClose: () => void;
	}

	let {
		mode,
		valueNode,
		era,
		stats = { total: 0, okrs: 0, krs: 0, kpis: 0, avgPct: 0 },
		alignedNodes = [],
		canEdit,
		onClose
	}: Props = $props();

	// Local mutable states
	let title = $state('');
	let description = $state('');
	let color = $state('#0058bd');
	let icon = $state('verified');
	let startYear = $state(2026);
	let endYear = $state<number | null>(null);

	let showDeleteConfirm = $state(false);

	// Synchronize when valueNode changes
	$effect(() => {
		if (valueNode) {
			title = valueNode.title;
			description = valueNode.description ?? '';
			color = valueNode.color || '#0058bd';
			icon = valueNode.icon || 'verified';
			startYear = valueNode.start_year ?? era.start_year;
			endYear = valueNode.end_year ?? null;
		} else {
			title = '';
			description = '';
			color = '#0058bd';
			icon = 'verified';
			startYear = era.start_year;
			endYear = null;
		}
	});

	// Derived physical folder theme based on active color
	const theme = $derived(getDossierTheme(color));

	// Tag code identifier
	const tagCode = $derived.by(() => {
		const clean = (title || 'VAL')
			.normalize('NFD')
			.replace(/[\u0300-\u036f]/g, '')
			.replace(/[^a-zA-Z]/g, '')
			.slice(0, 3)
			.toUpperCase();
		return `TAG #${clean || 'VAL'}-${String(startYear || era.start_year).slice(-2)}`;
	});

	// Keyboard shortcut listener
	function handleKeyDown(e: KeyboardEvent) {
		if (e.key === 'Escape') {
			if (showDeleteConfirm) {
				showDeleteConfirm = false;
			} else {
				onClose();
			}
		}
	}

	onMount(() => {
		document.addEventListener('keydown', handleKeyDown);
		return () => {
			document.removeEventListener('keydown', handleKeyDown);
		};
	});
</script>

<div
	role="presentation"
	onclick={onClose}
	class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-[#181613]/60 backdrop-blur-[5px] overflow-y-auto"
>
	<!-- WRAPPER: CLÁSSICA PASTA DE ARQUIVO SUSPENSA COM ABA SALIENTE -->
	<!-- svelte-ignore a11y_click_events_have_key_events -->
	<div
		role="dialog"
		tabindex="-1"
		aria-modal="true"
		onclick={(e) => e.stopPropagation()}
		class="relative w-full max-w-4xl my-auto flex flex-col items-stretch animate-in fade-in zoom-in-95 duration-200"
		style="font-family: 'Poppins', sans-serif;"
	>
		<!-- 1. TOPO DA PASTA: ABA SALIENTE COM VISOR DE ACETATO E ETIQUETA ENCAIXADA -->
		<div class="flex items-end justify-between px-3 sm:px-6 -mb-[1px] relative z-20">
			<!-- Aba Saliente de Arquivo Manilha -->
			<div
				class="relative flex items-center gap-3 px-5 sm:px-7 py-2.5 border-t-2 border-l-2 border-r-2 rounded-t-xl transition-colors duration-200"
				style="background-color: {theme.folderBg}; border-color: {theme.folderBorder}; box-shadow: 0 -3px 10px rgba(0,0,0,0.06), inset 0 1px 0 rgba(255,255,255,0.9);"
			>
				<!-- Visor de Acetato Transparente com Cartão Interno -->
				<div
					class="flex items-center gap-2 px-2.5 py-1 rounded bg-white/95 border shadow-[inset_0_1px_2px_rgba(0,0,0,0.06)]"
					style="border-color: {theme.badgeBorder};"
				>
					<span
						class="material-symbols-outlined text-[17px] shrink-0"
						style="color: {color};"
					>
						{icon || 'verified'}
					</span>
					<span
						class="font-mono text-[11.5px] font-bold tracking-wider uppercase"
						style="color: {theme.accentDark};"
					>
						{mode === 'create'
							? 'NOVO VALOR • PILAR ESTRATÉGICO'
							: `DOSSIÊ VALOR • ${era.start_year}`}
					</span>
				</div>

				<!-- Indicador de Itens Alinhados acoplado à aba -->
				{#if mode === 'edit'}
					<div
						class="flex items-center gap-1.5 px-2 py-0.5 rounded-md font-mono text-[11px] font-bold border transition-colors hidden sm:flex"
						style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
					>
						<span class="material-symbols-outlined text-[14px]" style="color: {theme.accent};">
							hub
						</span>
						<span>{stats.total} ITENS ALINHADOS</span>
						<span class="text-xs font-black ml-0.5">({stats.avgPct}%)</span>
					</div>
				{/if}

				<!-- Conector contínuo para o corpo da pasta -->
				<span
					class="absolute -bottom-1 left-0 right-0 h-2 transition-colors duration-200"
					style="background-color: {theme.folderBg};"
				></span>
			</div>

			<!-- Canto Superior Direito: Seletor de Cor & Botão Fechar -->
			<div class="flex items-center gap-2 pb-1.5 pr-1 relative z-40">
				<PaperColorPicker bind:value={color} disabled={!canEdit} align="right" />
				<button
					type="button"
					onclick={onClose}
					class="w-8 h-8 rounded-full bg-white/95 hover:bg-white text-[#524d45] hover:text-[#1d1b17] border border-[#cfc5b4] shadow-sm flex items-center justify-center transition-all hover:scale-105 active:scale-95 cursor-pointer"
					title="Fechar Pasta"
				>
					<span class="material-symbols-outlined text-[18px]">close</span>
				</button>
			</div>
		</div>

		<!-- 2. CORPO DA PASTA FÍSICA -->
		<form
			method="POST"
			action={mode === 'create' ? '?/createValue' : '?/updateIdentityNode'}
			use:enhance={() => {
				return async ({ result, update }) => {
					if (result.type === 'success') {
						onClose();
					}
					await update({ reset: false });
				};
			}}
			use:enhanceFormValidation
			class="w-full border-2 rounded-2xl hanging-folder-shadow flex flex-col relative overflow-hidden transition-colors duration-200"
			style="background-color: {theme.folderBg}; border-color: {theme.folderBorder};"
		>
			{#if mode === 'edit' && valueNode}
				<input type="hidden" name="nodeId" value={valueNode.id} />
			{:else if mode === 'create'}
				<input type="hidden" name="parentId" value={era.mission?.id || ''} />
			{/if}
			<input type="hidden" name="color" value={color} />
			<input type="hidden" name="icon" value={icon} />

			<!-- Linha de reforço estrutural com gradiente sutil na cor do valor -->
			<div
				class="h-1.5 w-full relative z-10 border-b transition-colors duration-200"
				style="background: linear-gradient(to right, color-mix(in srgb, {color} 25%, transparent), color-mix(in srgb, {color} 45%, transparent), color-mix(in srgb, {color} 20%, transparent)); border-color: {theme.folderBorder};"
			></div>

			<!-- ÁREA INTERNA DA PASTA -->
			<div class="p-4 sm:p-6 lg:p-7 max-h-[calc(88vh-130px)] overflow-y-auto custom-scroll relative z-10 space-y-6">
				<div class="grid grid-cols-1 lg:grid-cols-12 gap-5 lg:gap-6 items-start">
					<!-- ============================================================== -->
					<!-- COLUNA DA ESQUERDA: IDENTIFICAÇÃO, ÍCONE & COR (7/12 ~ 58%) -->
					<!-- ============================================================== -->
					<div class="lg:col-span-7 space-y-4">
						<div
							class="p-5 rounded-2xl border shadow-xs space-y-4 transition-colors"
							style="background-color: {theme.cardBg}; border-color: {theme.cardBorder};"
						>
							<!-- Título do Valor -->
							<div class="space-y-1.5">
								<div class="flex items-center justify-between">
									<label
										for="val-title-input"
										class="flex items-center gap-1.5 font-mono text-[11px] uppercase tracking-wider font-bold transition-colors"
										style="color: {theme.accentDark};"
									>
										<span class="material-symbols-outlined text-[16px]" style="color: {theme.accent};">
											drive_file_rename_outline
										</span>
										Nome do Valor Fundamental <span class="text-error">*</span>
									</label>
									<span
										class="text-[11px] font-mono font-semibold px-2 py-0.5 rounded border transition-colors"
										style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
									>
										{tagCode}
									</span>
								</div>
								<div
									class="relative flex items-center rounded-xl px-3.5 py-2.5 shadow-inner transition-all border"
									style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
								>
									<input
										id="val-title-input"
										name="title"
										type="text"
										required
										bind:value={title}
										placeholder="Ex.: Excelência em Cada Entrega"
										aria-errormessage="val-title-err"
										class="w-full bg-transparent border-0 p-0 text-[#1d1b17] font-display text-[18px] sm:text-[20px] font-bold tracking-tight focus:ring-0 focus:outline-none"
									/>
									<span class="material-symbols-outlined text-[20px] ml-2 shrink-0" style="color: {theme.accent};">
										edit
									</span>
								</div>
								<div id="val-title-err" class="error-msg">
									<AlertCircle class="h-3.5 w-3.5" />
									<span>O nome do valor é obrigatório.</span>
								</div>
							</div>

							<!-- SELETOR DE ÍCONE E COR DO VALOR (SIMILAR AO MODAL DE EQUIPES) -->
							<div class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-1 border-t border-[#edf4ee] items-start">
								<!-- Seletor de Ícone -->
								<div class="space-y-2.5">
									<div class="flex items-center justify-between">
										<span class="font-mono text-[10.5px] uppercase tracking-wider font-bold text-[#424753]">
											Ícone do Valor
										</span>
									</div>
									<div class="pt-0.5">
										<PaperIconPicker
											bind:value={icon}
											{color}
											disabled={!canEdit}
											label="Alterar Ícone"
											align="left"
										/>
									</div>
								</div>

								<!-- Seletor de Cor -->
								<div class="space-y-2.5 sm:border-l sm:border-[#edf4ee] sm:pl-4">
									<div class="flex items-center justify-between">
										<span class="font-mono text-[10.5px] uppercase tracking-wider font-bold text-[#424753]">
											Cor do Valor &amp; Cartão
										</span>
									</div>
									<div class="pt-0.5">
										<PaperColorPicker
											bind:value={color}
											disabled={!canEdit}
											label="Alterar Cor"
											align="left"
										/>
									</div>
								</div>
							</div>

							<!-- Descrição / Definição Comportamental -->
							<div class="space-y-1.5 pt-1 border-t border-[#edf4ee]">
								<div class="flex items-center justify-between">
									<label
										for="val-desc-input"
										class="flex items-center gap-1.5 font-mono text-[11px] uppercase tracking-wider font-bold"
										style="color: {theme.accentDark};"
									>
										<span class="material-symbols-outlined text-[16px]" style="color: {theme.accent};">
											description
										</span>
										Definição Comportamental &amp; Diretriz
									</label>
									<span class="font-mono text-[10px] text-[#727784]">CONDUTA</span>
								</div>
								<div
									class="rounded-xl p-3 shadow-inner transition-all border"
									style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
								>
									<textarea
										id="val-desc-input"
										name="description"
										rows="3"
										bind:value={description}
										placeholder="Como este valor orienta decisões executivas, comportamentos e entregas práticas da equipe..."
										class="w-full bg-transparent border-0 p-0 text-[#1d1b17] font-sans text-[13px] leading-relaxed focus:ring-0 focus:outline-none resize-none font-medium"
									></textarea>
								</div>
							</div>

							<!-- Escopo Temporal / Vigência da Era -->
							<div class="space-y-2 pt-1 border-t border-[#edf4ee]">
								<div class="flex items-center justify-between">
									<span class="font-mono text-[10.5px] uppercase tracking-wider font-bold text-[#424753]">
										Vigência do Ciclo
									</span>
									<span class="font-mono text-[10px] text-[#727784]">
										{era.label}
									</span>
								</div>
								<div class="grid grid-cols-2 gap-3">
									<div>
										<label
											for="val-start-year"
											class="block font-mono text-[10px] uppercase text-[#727784]"
										>
											Ano Inicial
										</label>
										<input
											id="val-start-year"
											name="start_year"
											type="number"
											bind:value={startYear}
											class="mt-1 w-full rounded-xl px-3 py-1.5 font-mono text-[12px] font-bold text-[#1d1b17] border shadow-xs transition-colors"
											style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
										/>
									</div>
									<div>
										<label
											for="val-end-year"
											class="block font-mono text-[10px] uppercase text-[#727784]"
										>
											Ano Final (Vazio se ativo)
										</label>
										<input
											id="val-end-year"
											name="end_year"
											type="number"
											placeholder="Em vigor"
											value={endYear ?? ''}
											oninput={(e) => {
												const val = (e.target as HTMLInputElement).value;
												endYear = val ? Number(val) : null;
											}}
											class="mt-1 w-full rounded-xl px-3 py-1.5 font-mono text-[12px] font-bold text-[#1d1b17] border shadow-xs transition-colors"
											style="background-color: {theme.inputBg}; border-color: {theme.inputBorder};"
										/>
									</div>
								</div>
							</div>
						</div>
					</div>

					<!-- ============================================================== -->
					<!-- COLUNA DA DIREITA: PRÉVIA AO VIVO & IMPACTO ESTRATÉGICO (5/12 ~ 42%) -->
					<!-- ============================================================== -->
					<div class="lg:col-span-5 space-y-4">
						<!-- Live Card Preview -->
						<div class="space-y-2">
							<div class="flex items-center justify-between px-1">
								<span
									class="flex items-center gap-1.5 font-mono text-[10.5px] uppercase tracking-wider font-bold"
									style="color: {theme.accentDark};"
								>
									<span class="material-symbols-outlined text-[15px]" style="color: {theme.accent};">
										visibility
									</span>
									Prévia em Tempo Real
								</span>
								<span class="font-mono text-[10px] text-[#727784]">CARD MOSAICO</span>
							</div>

							<!-- The Live Value Card Preview matching the page cards -->
							<div
								class="relative group rounded-2xl p-5 flex flex-col justify-between border transition-all duration-300"
								style="background-color: {theme.cardBg}; border-color: {theme.cardBorder}; box-shadow: 0 1px 2px rgba(36,34,30,0.05), 0 6px 16px color-mix(in srgb, {theme.accent} 12%, transparent), inset 0 1px 0 rgba(255,255,255,0.9);"
							>
								<!-- Folder corner tab accent -->
								<div
									class="absolute top-0 right-0 w-8 h-8 rounded-bl-xl flex items-center justify-center transition-colors"
									style="background-color: {theme.badgeBg};"
								>
									<div class="w-2 h-2 rounded-full transition-colors" style="background-color: {theme.accent};"></div>
								</div>

								<div class="flex flex-col gap-3">
									<!-- Header Icon + Title -->
									<div class="flex items-start gap-3 pr-6">
										<div
											class="w-11 h-11 rounded-xl flex items-center justify-center shrink-0 border transition-colors shadow-xs"
											style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.accentDark};"
										>
											<span class="material-symbols-outlined text-[24px]">{icon || 'verified'}</span>
										</div>
										<div class="flex flex-col min-w-0">
											<span
												class="font-mono text-[10px] uppercase tracking-wider font-bold"
												style="color: {theme.accent};"
											>
												Pilar Estratégico
											</span>
											<h3
												class="font-title-md text-[16px] font-bold leading-tight truncate"
												style="color: {theme.accentDark};"
											>
												{title || 'Título do Valor'}
											</h3>
										</div>
									</div>

									<!-- Description -->
									<p class="font-body-sm text-[12.5px] text-[#424753] leading-relaxed line-clamp-3">
										{description || 'Como este valor orienta decisões executivas e entregas...'}
									</p>

									<!-- Metric Box (Debossed Well) -->
									<div
										class="rounded-xl bg-white/80 p-2.5 shadow-[inset_0_2px_4px_rgba(36,34,30,0.05)] border border-[#ede8de] flex items-center justify-between"
									>
										<div class="flex flex-col">
											<span class="font-mono text-[9.5px] text-[#727784] uppercase tracking-wider">
												Impacto Atual
											</span>
											<span class="font-sans text-[12px] font-bold text-[#1d1b17]">
												{stats.total} {stats.total === 1 ? 'item alinhado' : 'itens alinhados'}
											</span>
											<span class="font-sans text-[10.5px] text-[#727784]">
												{stats.okrs} OKRs • {stats.krs} KRs • {stats.kpis} KPIs
											</span>
										</div>

										<!-- Radial Mini Gauge -->
										<div class="relative w-9 h-9 flex items-center justify-center shrink-0">
											<svg class="w-9 h-9 -rotate-90" viewBox="0 0 36 36">
												<path
													class="text-[#ede8de]"
													d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
													fill="none"
													stroke="currentColor"
													stroke-width="3.5"
												></path>
												<path
													d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
													fill="none"
													stroke={theme.accent}
													stroke-dasharray="{stats.avgPct}, 100"
													stroke-linecap="round"
													stroke-width="3.5"
												></path>
											</svg>
											<span class="absolute font-mono text-[9px] font-bold" style="color: {theme.accentDark};">
												{stats.avgPct}%
											</span>
										</div>
									</div>
								</div>

								<!-- Bottom Action Button Preview -->
								<div class="pt-3 flex items-center justify-between border-t border-[#ede8de]/60 mt-3">
									<span class="font-mono text-[10px] text-[#727784]">{tagCode}</span>
									<span
										class="px-2.5 py-1 rounded-md text-[11px] font-bold flex items-center gap-1 shadow-xs border"
										style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.accentDark};"
									>
										<span>Ver no Canvas</span>
										<span class="material-symbols-outlined text-[13px]">arrow_forward</span>
									</span>
								</div>
							</div>
						</div>

						<!-- Impacto & Alinhamento Estratégico List -->
						<div
							class="p-4 rounded-2xl border shadow-xs space-y-3 transition-colors"
							style="background-color: {theme.cardBg}; border-color: {theme.cardBorder};"
						>
							<div class="flex items-center justify-between pb-1 border-b border-[#edf4ee]">
								<div class="flex items-center gap-2">
									<span class="material-symbols-outlined text-[17px]" style="color: {theme.accent};">
										hub
									</span>
									<h4
										class="font-mono text-[11px] uppercase tracking-wider font-bold"
										style="color: {theme.accentDark};"
									>
										Iniciativas Vinculadas ({stats.total})
									</h4>
								</div>
								<span
									class="font-mono text-[10px] font-bold px-2 py-0.5 rounded border"
									style="background-color: {theme.badgeBg}; border-color: {theme.badgeBorder}; color: {theme.badgeText};"
								>
									{stats.okrs} OKRs • {stats.krs} KRs
								</span>
							</div>

							{#if alignedNodes.length > 0}
								<div class="space-y-2 max-h-48 overflow-y-auto custom-scroll pr-1">
									{#each alignedNodes as node (node.id)}
										<div
											class="p-2.5 rounded-xl border bg-white/80 flex items-start gap-2 shadow-2xs hover:bg-white transition-colors"
											style="border-color: {theme.inputBorder};"
										>
											<span
												class="px-1.5 py-0.5 rounded text-[9px] font-bold uppercase tracking-wider shrink-0 mt-0.5"
												style="background-color: {theme.badgeBg}; color: {theme.accentDark};"
											>
												{node.type === 'objective' ? 'OKR' : node.type === 'key_result' ? 'KR' : 'KPI'}
											</span>
											<div class="flex flex-col min-w-0">
												<span class="font-sans text-[12px] font-semibold text-[#1d1b17] leading-snug line-clamp-2">
													{node.title}
												</span>
												<span class="font-mono text-[10px] text-[#727784] mt-0.5">
													{Math.round(node.progress * 100)}% concluído
												</span>
											</div>
										</div>
									{/each}
								</div>
							{:else}
								<div class="p-3 rounded-xl bg-white/60 border border-dashed border-[#d5cebe] text-center">
									<p class="font-sans text-[12px] text-[#727784] italic">
										Nenhum objetivo ou KR alinhado diretamente a este valor neste ciclo.
									</p>
								</div>
							{/if}
						</div>
					</div>
				</div>
			</div>

			<!-- 3. RODAPÉ DA PASTA: LINHA DE COSTURA SUTIL E BOTÕES DE AÇÃO -->
			<div
				class="relative z-10 border-t px-5 sm:px-7 py-3.5 transition-colors duration-200"
				style="background-color: {theme.footerBg}; border-color: {theme.folderBorder};"
			>
				<!-- Linha de Costura / Picote Sutil de Papel Manilha -->
				<div
					class="h-[1.5px] w-full mb-3 opacity-75"
					style="background-image: repeating-linear-gradient(to right, {theme.stitchedColor} 0px, {theme.stitchedColor} 6px, transparent 6px, transparent 11px);"
				></div>

				<div class="flex flex-col sm:flex-row items-center justify-between gap-3">
					<!-- Botão Excluir Valor -->
					{#if mode === 'edit' && canEdit && valueNode}
						<button
							type="button"
							onclick={() => (showDeleteConfirm = true)}
							class="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-[#ba1a1a] hover:bg-[#ffdad6]/60 font-sans text-[12.5px] font-semibold transition-colors self-start sm:self-auto cursor-pointer"
						>
							<span class="material-symbols-outlined text-[16px]">delete</span>
							<span>Excluir Valor</span>
						</button>
					{:else}
						<div></div>
					{/if}

					<div class="flex items-center gap-2.5 w-full sm:w-auto justify-end">
						<button
							type="button"
							onclick={onClose}
							class="px-4 py-2 rounded-xl bg-white hover:bg-slate-50 text-[#1d1b17] border font-sans text-[12.5px] font-semibold shadow-xs active:translate-y-0.5 transition-all cursor-pointer"
							style="border-color: {theme.inputBorder};"
						>
							Cancelar
						</button>

						{#if canEdit}
							<button
								type="submit"
								class="inline-flex items-center gap-2 px-5 py-2 rounded-xl text-white font-sans text-[12.5px] font-bold active:translate-y-0.5 transition-all cursor-pointer hover:brightness-105"
								style="background-color: {theme.accent}; box-shadow: 0 2.5px 0 {theme.accentShadow};"
							>
								<span class="material-symbols-outlined text-[17px]">check</span>
								<span>{mode === 'create' ? 'Criar Valor' : 'Salvar Alterações'}</span>
							</button>
						{/if}
					</div>
				</div>
			</div>
		</form>
	</div>
</div>

<!-- Modal de Confirmação de Exclusão -->
{#if showDeleteConfirm && valueNode}
	<div
		role="presentation"
		onclick={() => (showDeleteConfirm = false)}
		class="fixed inset-0 z-[110] flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs"
	>
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			onclick={(e) => e.stopPropagation()}
			class="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl border border-[#d5cebe] space-y-4"
		>
			<div class="flex items-center gap-3 text-[#ba1a1a]">
				<span class="material-symbols-outlined text-[28px]">warning</span>
				<h3 class="font-bold text-lg text-[#1d1b17]">Excluir Valor Fundamental?</h3>
			</div>

			<p class="text-sm text-[#424753] leading-relaxed">
				Você tem certeza de que deseja excluir o valor fundamental <strong>"{valueNode.title}"</strong>?
				{#if stats.total > 0}
					<br />
					<span class="text-xs text-[#ba1a1a] font-semibold mt-1 block">
						Atenção: Existem {stats.total} itens estratégicos ({stats.okrs} OKRs e {stats.krs} KRs) vinculados a este valor.
					</span>
				{/if}
			</p>

			<form
				method="POST"
				action="?/deleteIdentityNode"
				use:enhance={() => {
					return async ({ result, update }) => {
						if (result.type === 'success') {
							showDeleteConfirm = false;
							onClose();
						}
						await update({ reset: false });
					};
				}}
				use:enhanceFormValidation
				class="space-y-4 pt-2"
			>
				<input type="hidden" name="nodeId" value={valueNode.id} />

				<div class="flex items-center justify-end gap-2 pt-2">
					<button
						type="button"
						onclick={() => (showDeleteConfirm = false)}
						class="px-4 py-2 rounded-xl border border-[#d5cebe] text-xs font-bold text-[#424753] hover:bg-slate-50 cursor-pointer"
					>
						Cancelar
					</button>
					<button
						type="submit"
						class="px-4 py-2 rounded-xl bg-[#ba1a1a] text-white text-xs font-bold hover:bg-[#991b1b] shadow-xs cursor-pointer"
					>
						Confirmar Exclusão
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}

<style>
	.hanging-folder-shadow {
		box-shadow: 
			0 2px 8px rgba(29, 27, 23, 0.08),
			0 18px 45px -8px rgba(0, 88, 189, 0.16),
			0 30px 70px -15px rgba(29, 27, 23, 0.35),
			inset 0 1px 0 rgba(255, 255, 255, 0.95);
	}
	.custom-scroll::-webkit-scrollbar {
		width: 6px;
	}
	.custom-scroll::-webkit-scrollbar-track {
		background: #f1ede4;
		border-radius: 4px;
	}
	.custom-scroll::-webkit-scrollbar-thumb {
		background: #c7beaf;
		border-radius: 4px;
	}
	.custom-scroll::-webkit-scrollbar-thumb:hover {
		background: #a89d8d;
	}
</style>
