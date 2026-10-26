<script lang="ts">
	import { enhance } from '$app/forms';
	import { formatNumber } from '$lib/utils';
	import { getDossierTheme } from '$lib/dossier-theme';
	import type { NodeWithExtras } from '$lib/types';

	interface Props {
		enriched: any;
		filteredSortedKPIs: NodeWithExtras[];
		open: boolean;
		initialKpiId?: string;
	}

	let {
		enriched,
		filteredSortedKPIs,
		open = $bindable(false),
		initialKpiId = ''
	}: Props = $props();

	let quickKpiId = $state<string>('');
	let quickValue = $state<string>('');
	let quickNote = $state<string>('');

	const currentSelectedKpi = $derived(
		quickKpiId ? enriched.byId.get(quickKpiId) : null
	);

	const kpiTheme = $derived(
		getDossierTheme(
			currentSelectedKpi?.color ||
				currentSelectedKpi?.teams?.[0]?.color ||
				'#00665a'
		)
	);

	$effect(() => {
		if (open) {
			quickKpiId = initialKpiId || (filteredSortedKPIs.length > 0 ? filteredSortedKPIs[0].id : '');
			const targetKpi = quickKpiId ? enriched.byId.get(quickKpiId) : null;
			quickValue = targetKpi?.current_value != null ? String(targetKpi.current_value) : '';
			quickNote = '';
		}
	});
</script>

{#if open}
	<!-- svelte-ignore a11y_click_events_have_key_events -->
	<!-- svelte-ignore a11y_no_static_element_interactions -->
	<div
		class="fixed inset-0 z-[100] bg-[#181613]/60 backdrop-blur-[5px] flex items-center justify-center p-2.5 sm:p-6 overflow-y-auto overscroll-contain"
		onclick={(e) => {
			if (e.target === e.currentTarget) open = false;
		}}
	>
		<div
			onclick={(e) => e.stopPropagation()}
			class="w-full max-w-lg my-auto flex flex-col items-stretch relative animate-in fade-in zoom-in-95 duration-150"
		>
			<!-- 1. TOPO DA PASTA: ABA SALIENTE COM VISOR DE ACETATO -->
			<div class="flex items-end justify-between gap-2 px-2 sm:px-5 -mb-[1px] relative z-20">
				<div
					class="min-w-0 relative flex items-center gap-2 px-3 sm:px-5 py-2 border-t-2 border-l-2 border-r-2 rounded-t-xl transition-colors duration-200"
					style="background-color: {kpiTheme.folderBg}; border-color: {kpiTheme.folderBorder};"
				>
					<div
						class="min-w-0 flex items-center gap-1.5 px-2.5 py-0.5 rounded bg-white/95 border shadow-[inset_0_1px_2px_rgba(0,0,0,0.05)]"
						style="border-color: {kpiTheme.badgeBorder};"
					>
						<span class="w-2 h-2 rounded-full animate-pulse shrink-0" style="background-color: {kpiTheme.accent};"></span>
						<span class="font-mono text-[10px] sm:text-[11px] font-bold uppercase tracking-wider truncate" style="color: {kpiTheme.accentDark};">
							CHECK-IN RÁPIDO DE KPI
						</span>
					</div>
					<span
						class="absolute -bottom-1 left-0 right-0 h-2 transition-colors duration-200"
						style="background-color: {kpiTheme.folderBg};"
					></span>
				</div>

				<button
					type="button"
					onclick={() => (open = false)}
					class="w-8 h-8 mb-1.5 rounded-full bg-white/95 hover:bg-white text-[#524d45] hover:text-[#1d1b17] border border-[#cfc5b4] shadow-sm flex items-center justify-center transition-all cursor-pointer"
					title="Fechar Pasta"
				>
					<span class="material-symbols-outlined text-[18px]">close</span>
				</button>
			</div>

			<!-- 2. CORPO DA PASTA FÍSICA -->
			<form
				method="POST"
				action="?/logMetric"
				use:enhance={() => {
					return async ({ result, update }) => {
						if (result.type === 'success') {
							open = false;
						}
						await update();
					};
				}}
				class="w-full border-2 rounded-2xl hanging-folder-shadow flex flex-col relative z-10 overflow-hidden transition-colors duration-200"
				style="background-color: {kpiTheme.folderBg}; border-color: {kpiTheme.folderBorder};"
			>
				<div
					class="h-1.5 w-full border-b"
					style="background: linear-gradient(to right, color-mix(in srgb, {kpiTheme.accent} 25%, transparent), color-mix(in srgb, {kpiTheme.accent} 45%, transparent), color-mix(in srgb, {kpiTheme.accent} 20%, transparent)); border-color: {kpiTheme.folderBorder};"
				></div>

				<div class="p-3.5 sm:p-5 space-y-4 max-h-[calc(88dvh-130px)] overflow-y-auto overscroll-contain custom-scroll">
					<div
						class="p-4 rounded-xl border shadow-2xs space-y-4"
						style="background-color: {kpiTheme.cardBg}; border-color: {kpiTheme.cardBorder};"
					>
						<div>
							<label
								for="quick-kpi"
								class="block font-mono text-[10.5px] font-bold uppercase tracking-wider mb-1"
								style="color: {kpiTheme.accentDark};"
							>
								Selecione o KPI / Indicador
							</label>
							<select
								id="quick-kpi"
								name="nodeId"
								bind:value={quickKpiId}
								onchange={() => {
									const selected = enriched.byId.get(quickKpiId);
									if (selected) {
										quickValue =
											selected.current_value != null ? String(selected.current_value) : '';
									}
								}}
								required
								class="w-full px-3 py-2 rounded-xl text-xs font-semibold text-[#1d1b17] outline-none border cursor-pointer"
								style="background-color: {kpiTheme.inputBg}; border-color: {kpiTheme.inputBorder};"
							>
								{#each filteredSortedKPIs as kpi (kpi.id)}
									<option value={kpi.id}>
										{kpi.title} (Meta: {formatNumber(kpi.target_value, kpi.unit)})
									</option>
								{/each}
							</select>
						</div>

						{#if currentSelectedKpi}
							<div
								class="p-3 rounded-xl border flex items-center justify-between text-xs"
								style="background-color: {kpiTheme.badgeBg}; border-color: {kpiTheme.badgeBorder}; color: {kpiTheme.badgeText};"
							>
								<div>
									<span class="opacity-80">Valor Atual:</span>
									<strong class="font-bold ml-1" style="color: {kpiTheme.accentDark};">
										{formatNumber(currentSelectedKpi.current_value ?? 0, currentSelectedKpi.unit)}
									</strong>
								</div>
								<div>
									<span class="opacity-80">Meta:</span>
									<strong class="font-bold ml-1" style="color: {kpiTheme.accentDark};">
										{formatNumber(currentSelectedKpi.target_value ?? 0, currentSelectedKpi.unit)}
									</strong>
								</div>
							</div>
						{/if}

						<div>
							<label
								for="quick-value"
								class="block font-mono text-[10.5px] font-bold uppercase tracking-wider mb-1 text-[#424753]"
							>
								Novo Valor Realizado {currentSelectedKpi?.unit ? `(${currentSelectedKpi.unit})` : ''}
							</label>
							<input
								id="quick-value"
								name="value"
								type="number"
								step="any"
								bind:value={quickValue}
								required
								placeholder="Ex: 100"
								class="w-full px-3 py-2 rounded-xl text-sm font-bold text-[#1d1b17] outline-none border shadow-inner"
								style="background-color: {kpiTheme.inputBg}; border-color: {kpiTheme.inputBorder};"
							/>
						</div>

						<div>
							<label
								for="quick-note"
								class="block font-mono text-[10.5px] font-bold uppercase tracking-wider mb-1 text-[#424753]"
							>
								Nota ou Comentário de Contexto
							</label>
							<textarea
								id="quick-note"
								name="note"
								rows="3"
								bind:value={quickNote}
								placeholder="Ex: Fechamento de contrato de consultoria ou apuração semanal de CSAT..."
								class="w-full px-3 py-2 rounded-xl text-xs font-medium text-[#1d1b17] outline-none border shadow-inner resize-none"
								style="background-color: {kpiTheme.inputBg}; border-color: {kpiTheme.inputBorder};"
							></textarea>
						</div>
					</div>
				</div>

				<!-- 3. RODAPÉ DA PASTA COM COSTURA -->
				<div
					class="px-4 sm:px-5 py-3 border-t flex items-center justify-end gap-2.5 relative transition-colors duration-200"
					style="background-color: {kpiTheme.footerBg}; border-color: {kpiTheme.folderBorder};"
				>
					<div
						class="absolute top-0.5 left-0 right-0 h-[1px] opacity-60"
						style="background-image: repeating-linear-gradient(to right, {kpiTheme.stitchedColor} 0px, {kpiTheme.stitchedColor} 6px, transparent 6px, transparent 11px);"
					></div>
					<button
						type="button"
						onclick={() => (open = false)}
						class="px-4 py-2 rounded-xl bg-white hover:bg-slate-50 border border-[#cfc5b4] text-xs font-bold text-[#1d1b17] shadow-xs active:translate-y-0.5 transition-all cursor-pointer"
					>
						Cancelar
					</button>
					<button
						type="submit"
						class="px-5 py-2 rounded-xl text-white text-xs font-bold active:translate-y-0.5 transition-all hover:brightness-105 cursor-pointer flex items-center gap-1.5"
						style="background-color: {kpiTheme.accent}; box-shadow: 0 2.5px 0 {kpiTheme.accentShadow};"
					>
						<span class="material-symbols-outlined text-[16px]">check</span>
						<span>Registrar Check-in</span>
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}
