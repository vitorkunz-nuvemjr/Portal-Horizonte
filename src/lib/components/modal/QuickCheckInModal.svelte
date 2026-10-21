<script lang="ts">
	import { enhance } from '$app/forms';
	import { formatNumber } from '$lib/utils';
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
		class="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4"
		onclick={(e) => {
			if (e.target === e.currentTarget) open = false;
		}}
	>
		<div
			class="w-full max-w-lg rounded-2xl bg-surface-container-lowest p-6 shadow-2xl border border-outline-variant/60 flex flex-col gap-4 animate-in fade-in zoom-in-95 duration-150"
		>
			<div class="flex items-center justify-between border-b border-outline-variant/40 pb-3">
				<div class="flex items-center gap-2">
					<span class="material-symbols-outlined text-primary text-[22px]">add_circle</span>
					<h3 class="font-headline-sm text-headline-sm text-on-surface">Novo Check-in de KPI</h3>
				</div>
				<button
					type="button"
					onclick={() => (open = false)}
					class="p-1 rounded-lg text-outline hover:text-on-surface hover:bg-surface-container transition-colors cursor-pointer"
				>
					<span class="material-symbols-outlined text-[20px]">close</span>
				</button>
			</div>

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
				class="flex flex-col gap-4"
			>
				<div>
					<label
						for="quick-kpi"
						class="block font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wider mb-1"
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
						class="w-full px-3 py-2 bg-surface-container rounded-lg font-title-md text-body-sm text-on-surface outline-none focus:ring-1 focus:ring-primary border border-outline-variant/40 cursor-pointer"
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
						class="p-3 rounded-lg bg-surface-container-low flex items-center justify-between text-body-sm"
					>
						<div>
							<span class="text-on-surface-variant">Valor Atual:</span>
							<strong class="text-on-surface font-semibold ml-1">
								{formatNumber(currentSelectedKpi.current_value ?? 0, currentSelectedKpi.unit)}
							</strong>
						</div>
						<div>
							<span class="text-on-surface-variant">Meta:</span>
							<strong class="text-primary font-semibold ml-1">
								{formatNumber(currentSelectedKpi.target_value ?? 0, currentSelectedKpi.unit)}
							</strong>
						</div>
					</div>
				{/if}

				<div>
					<label
						for="quick-value"
						class="block font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wider mb-1"
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
						class="w-full px-3 py-2 bg-surface-container rounded-lg font-title-md text-body-sm text-on-surface outline-none focus:ring-1 focus:ring-primary border border-outline-variant/40"
					/>
				</div>

				<div>
					<label
						for="quick-note"
						class="block font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wider mb-1"
					>
						Nota ou Comentário de Contexto
					</label>
					<textarea
						id="quick-note"
						name="note"
						rows="3"
						bind:value={quickNote}
						placeholder="Ex: Fechamento de contrato de consultoria ou apuração semanal de CSAT..."
						class="w-full px-3 py-2 bg-surface-container rounded-lg font-body-sm text-body-sm text-on-surface outline-none focus:ring-1 focus:ring-primary border border-outline-variant/40"
					></textarea>
				</div>

				<div class="flex items-center justify-end gap-2 pt-2 border-t border-outline-variant/40">
					<button
						type="button"
						onclick={() => (open = false)}
						class="px-4 py-2 rounded-lg bg-surface-container hover:bg-surface-container-high text-on-surface font-title-md text-body-sm transition-colors cursor-pointer"
					>
						Cancelar
					</button>
					<button
						type="submit"
						class="px-5 py-2 rounded-lg bg-primary hover:bg-primary-container text-on-primary font-title-md text-body-sm shadow transition-all cursor-pointer"
					>
						Registrar Check-in
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}
