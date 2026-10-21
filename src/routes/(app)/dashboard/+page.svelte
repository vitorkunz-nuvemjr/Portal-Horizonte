<script lang="ts">
	import { enrichNodes } from '$lib/progress';
	import { enhanceFormValidation, formatNumber, formatPct, getInitials, getTeamIcon } from '$lib/utils';
	import { valueColor } from '$lib/value-colors';
	import { getDossierTheme } from '$lib/dossier-theme';
	import {
		AlertTriangle,
		CheckCircle2,
		Clock,
		Target,
		Flag,
		Activity,
		Sparkles,
		ArrowRight
	} from 'lucide-svelte';

	let { data } = $props();

	let selectedCycleId = $state<string>('all');

	const canEdit = $derived(data.user?.role === 'admin' || data.user?.role === 'member');

	const enriched = $derived(
		enrichNodes(
			data.nodes,
			data.assigns,
			data.values,
			data.profiles,
			data.cycles,
			data.metricUpdates,
			data.teams,
			data.teamMembers,
			data.nodeTeams
		)
	);

	const allStrategyNodes = $derived(
		Array.from(enriched.byId.values()).filter((n) => n.tree === 'strategy')
	);

	const objectives = $derived(enriched.strategyRoots);

	const filteredKRs = $derived(
		allStrategyNodes.filter(
			(n) =>
				n.type === 'key_result' &&
				(selectedCycleId === 'all' || n.cycle_id === selectedCycleId)
		)
	);

	const filteredKPIs = $derived(
		allStrategyNodes.filter(
			(n) =>
				n.type === 'kpi' &&
				(selectedCycleId === 'all' || n.cycle?.id === selectedCycleId)
		)
	);

	const overallProgress = $derived.by(() => {
		if (objectives.length === 0) return 0;
		const totalWeight = objectives.reduce((s, o) => s + (o.weight || 1), 0);
		if (totalWeight === 0) return 0;
		return (
			objectives.reduce((s, o) => s + o.progress * (o.weight || 1), 0) / totalWeight
		);
	});

	// Attention list: Objectives or KRs that are atRisk or off_track
	const attentionList = $derived(
		allStrategyNodes.filter(
			(n) =>
				(n.type === 'objective' || n.type === 'key_result') &&
				(selectedCycleId === 'all' ||
					n.type === 'objective' ||
					n.cycle_id === selectedCycleId) &&
				(n.atRisk || n.status === 'at_risk' || n.status === 'off_track')
		)
	);

	// KPIs due for update (sort by oldest metric update or missing updates)
	const kpisDue = $derived(
		[...filteredKPIs].sort((a, b) => {
			const aDate = a.metricUpdates[0]?.created_at ?? '1970-01-01';
			const bDate = b.metricUpdates[0]?.created_at ?? '1970-01-01';
			return aDate.localeCompare(bDate);
		})
	);
</script>

<div class="p-gutter space-y-6">
	<!-- Header & Cycle Selector -->
	<div class="flex flex-wrap items-end justify-between gap-4 border-b border-outline-variant pb-4">
		<div>
			<div class="flex items-center gap-2 mb-1">
				<span class="px-2 py-0.5 rounded-[2px] bg-primary-fixed text-on-primary-fixed text-label-sm font-bold uppercase tracking-widest border border-outline-variant">
					Ciclos &amp; Métricas
				</span>
				<span class="text-label-sm text-outline">•</span>
				<span class="text-label-sm text-on-surface-variant font-medium">Acompanhamento Semestral e Rituais de Check-in</span>
			</div>
			<h2 class="text-headline-lg font-bold tracking-tight text-on-surface">
				Painel Executivo de Estratégia
			</h2>
			<p class="mt-0.5 text-body-sm text-on-surface-variant">
				Visão consolidada em tempo real de Objetivos anuais, Resultados-Chave semestrais, alertas de risco e check-ins de KPIs.
			</p>
		</div>

		<div class="flex items-center gap-2 rounded-[4px] border border-outline-variant bg-surface-container-low px-3 py-1.5 shadow-[0_2px_0_#D8D2C2]">
			<label for="dash-cycle" class="text-label-sm font-bold text-on-surface-variant uppercase tracking-wider">Ciclo Semestral:</label>
			<select
				id="dash-cycle"
				bind:value={selectedCycleId}
				class="rounded-[2px] border border-outline-variant bg-surface-container-lowest px-2.5 py-1 text-xs font-bold text-on-surface focus:border-primary focus:outline-none"
			>
				<option value="all">Todos os Ciclos</option>
				{#each data.cycles as cyc (cyc.id)}
					<option value={cyc.id}>{cyc.code} ({cyc.start_date} → {cyc.end_date})</option>
				{/each}
			</select>
		</div>
	</div>

	<!-- Top Summary Cards -->
	<div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
		<div class="rounded-[6px] border border-outline-variant bg-surface-container-lowest p-5 shadow-[0_2px_8px_rgba(36,34,30,0.05)]">
			<div class="flex items-center justify-between text-label-sm font-bold text-on-surface-variant uppercase tracking-wider">
				<span>Progresso Estratégico Geral</span>
				<Target class="h-4 w-4 text-primary" />
			</div>
			<div class="mt-2 text-2xl font-bold text-on-surface">{formatPct(overallProgress)}</div>
			<div class="mt-2.5 h-2 w-full overflow-hidden rounded-[2px] border border-outline-variant/50 bg-surface-container-high">
				<div
					class="h-full rounded-[1px] bg-primary"
					style="width: {Math.round(overallProgress * 100)}%"
				></div>
			</div>
		</div>

		<div class="rounded-[6px] border border-outline-variant bg-surface-container-lowest p-5 shadow-[0_2px_8px_rgba(36,34,30,0.05)]">
			<div class="flex items-center justify-between text-label-sm font-bold text-on-surface-variant uppercase tracking-wider">
				<span>Resultados-Chave Ativos</span>
				<Flag class="h-4 w-4 text-tertiary" />
			</div>
			<div class="mt-2 text-2xl font-bold text-on-surface">{filteredKRs.length}</div>
			<p class="mt-1 text-xs font-medium text-on-surface-variant">
				{filteredKRs.filter((k) => k.status === 'done' || k.progress >= 1).length} concluído(s)
			</p>
		</div>

		<div class="rounded-[6px] border border-outline-variant bg-secondary-fixed/60 p-5 shadow-[0_2px_8px_rgba(36,34,30,0.05)]">
			<div class="flex items-center justify-between text-label-sm font-bold text-on-secondary-fixed uppercase tracking-wider">
				<span>Atenção Necessária (Em Risco)</span>
				<AlertTriangle class="h-4 w-4 text-secondary" />
			</div>
			<div class="mt-2 text-2xl font-bold text-on-secondary-fixed">{attentionList.length}</div>
			<p class="mt-1 text-xs font-medium text-on-secondary-fixed/80">
				Baseado no tempo decorrido do semestre/ano e status
			</p>
		</div>

		<div class="rounded-[6px] border border-outline-variant bg-tertiary-fixed/50 p-5 shadow-[0_2px_8px_rgba(36,34,30,0.05)]">
			<div class="flex items-center justify-between text-label-sm font-bold text-on-tertiary-fixed uppercase tracking-wider">
				<span>KPIs Monitorados</span>
				<Activity class="h-4 w-4 text-tertiary" />
			</div>
			<div class="mt-2 text-2xl font-bold text-on-tertiary-fixed">{filteredKPIs.length}</div>
			<p class="mt-1 text-xs font-medium text-on-tertiary-fixed/80">
				{data.metricUpdates.length} check-ins registrados no histórico
			</p>
		</div>
	</div>

	<!-- Main Grid: Attention List + KPIs Due -->
	<div class="grid grid-cols-1 gap-6 lg:grid-cols-12">
		<!-- Left 7 Cols: Attention List & Objectives Rollup -->
		<div class="space-y-6 lg:col-span-7">
			<!-- Attention List -->
			<section class="rounded-[6px] border border-outline-variant bg-surface-container-lowest p-5 shadow-[0_2px_8px_rgba(36,34,30,0.05)]">
				<div class="flex items-center justify-between border-b border-outline-variant/60 pb-3">
					<h3 class="flex items-center gap-2 text-sm font-bold text-on-surface">
						<AlertTriangle class="h-4 w-4 text-secondary" />
						Lista de Atenção (Em Risco &amp; Atrasados)
					</h3>
					<span class="rounded-[2px] border border-outline-variant bg-secondary-fixed px-2.5 py-0.5 text-xs font-bold text-on-secondary-fixed">
						{attentionList.length}
					</span>
				</div>

				<div class="mt-4 space-y-3">
					{#each attentionList as item (item.id)}
						{@const itemTheme = getDossierTheme(
							item.color || item.teams[0]?.color || '#B6006A'
						)}
						<div
							class="flex items-center justify-between gap-4 rounded-[4px] border p-3.5"
							style="background-color: {itemTheme.folderBg}; border-color: {itemTheme.folderBorder}; border-left: 3px solid {itemTheme.accent};"
						>
							<div class="min-w-0 flex-1">
								<div class="flex flex-wrap items-center gap-2">
									<span
										class="rounded-[2px] border px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wider"
										style="background-color: {itemTheme.badgeBg}; color: {itemTheme.badgeText}; border-color: {itemTheme.badgeBorder};"
									>
										{item.type === 'objective'
											? 'Objetivo'
											: item.type === 'key_result'
												? 'Resultado-Chave'
												: 'KPI'}
									</span>
									{#if item.cycle}
										<span class="text-[11px] font-bold" style="color: {itemTheme.accent};">
											{item.cycle.code}
										</span>
									{:else if item.year}
										<span class="text-[11px] font-bold" style="color: {itemTheme.accent};">
											{item.year}{item.quarter ? ` · T${item.quarter}` : ''}
										</span>
									{/if}
									{#each item.teams.slice(0, 2) as team (team.id)}
										{@const tTheme = getDossierTheme(team.color || '#0058bd')}
										<span
											class="inline-flex items-center gap-1 rounded-[2px] border px-1.5 py-0.5 text-[9px] font-bold uppercase tracking-wider"
											style="background-color: {tTheme.badgeBg}; color: {tTheme.badgeText}; border-color: {tTheme.badgeBorder};"
										>
											<span
												class="material-symbols-outlined text-[12px] shrink-0"
												style="color: {tTheme.accent};"
											>
												{getTeamIcon(team)}
											</span>
											{team.name}
										</span>
									{/each}
								</div>
								<p
									class="mt-1 truncate text-xs font-bold"
									style="color: {itemTheme.accentShadow};"
								>
									{item.title}
								</p>
							</div>

							<div class="flex shrink-0 items-center gap-3">
								<div class="text-right">
									<div
										class="text-xs font-bold"
										style="color: {itemTheme.accentShadow};"
									>
										{formatPct(item.progress)}
									</div>
									<div class="text-[10px] font-semibold" style="color: {itemTheme.accentDark};">Abaixo do ritmo</div>
								</div>
								<div class="flex -space-x-1">
									{#each item.assignees.slice(0, 2) as person (person.id)}
										{@const pTheme = getDossierTheme(person.color || '#005AC2')}
										<span
											class="inline-flex h-6 w-6 items-center justify-center rounded-full text-[9px] font-bold text-white ring-1 ring-surface-container-lowest"
											style="background-color: {pTheme.accentMuted}"
											title={person.name}
										>
											{getInitials(person.name)}
										</span>
									{/each}
								</div>
							</div>
						</div>
					{:else}
						<div class="flex items-center gap-2 rounded-[4px] border border-outline-variant bg-tertiary-fixed/50 p-4 text-xs font-bold text-on-tertiary-fixed">
							<CheckCircle2 class="h-4 w-4 text-tertiary" />
							Todos os Objetivos e Resultados-Chave estão dentro do ritmo esperado!
						</div>
					{/each}
				</div>
			</section>

			<!-- Annual Objectives Rollup + Value Alignment Coverage -->
			<section class="rounded-[6px] border border-outline-variant bg-surface-container-lowest p-5 shadow-[0_2px_8px_rgba(36,34,30,0.05)]">
				<h3 class="flex items-center gap-2 border-b border-outline-variant/60 pb-3 text-sm font-bold text-on-surface">
					<Sparkles class="h-4 w-4 text-primary" />
					Alinhamento com Valores Organizacionais
				</h3>
				<div class="mt-4 space-y-2.5">
					{#each enriched.valuesList as val (val.id)}
						{@const count = data.values.filter((nv: { value_id: string }) => nv.value_id === val.id).length}
						{@const color = valueColor(val.id)}
						<div class="flex items-center justify-between rounded-[4px] border border-outline-variant bg-surface-container-low/60 px-4 py-2.5">
							<div class="flex items-center gap-2.5">
								<span class="h-3 w-3 rounded-full" style="background-color: {color}"></span>
								<span class="text-xs font-bold text-on-surface">{val.title}</span>
							</div>
							<a
								href="/strategy?lens={val.id}"
								class="inline-flex items-center gap-1 text-xs font-bold text-primary hover:underline"
							>
								<span>{count} {count === 1 ? 'item estratégico' : 'itens estratégicos'}</span>
								<ArrowRight class="h-3.5 w-3.5" />
							</a>
						</div>
					{/each}
				</div>
			</section>
		</div>

		<!-- Right 5 Cols: KPIs Due for Check-In -->
		<div class="lg:col-span-5">
			<section class="rounded-[6px] border border-outline-variant bg-surface-container-lowest p-5 shadow-[0_2px_8px_rgba(36,34,30,0.05)]">
				<div class="flex items-center justify-between border-b border-outline-variant/60 pb-3">
					<h3 class="flex items-center gap-2 text-sm font-bold text-on-surface">
						<Clock class="h-4 w-4 text-tertiary" />
						Fila de Check-In de KPIs
					</h3>
					<span class="text-[11px] font-semibold text-on-surface-variant">Mais antigos primeiro</span>
				</div>

				<div class="mt-4 space-y-3">
					{#each kpisDue as kpi (kpi.id)}
						{@const lastUpdate = kpi.metricUpdates[0]}
						{@const kpiTheme = getDossierTheme(
							kpi.color || kpi.teams[0]?.color || '#6c5e00'
						)}
						<div
							class="rounded-[4px] border p-3.5"
							style="background-color: {kpiTheme.folderBg}; border-color: {kpiTheme.folderBorder}; border-left: 3px solid {kpiTheme.accent};"
						>
							<div class="flex items-start justify-between gap-2">
								<div>
									<div class="flex flex-wrap items-center gap-1.5">
										<span class="text-xs font-bold" style="color: {kpiTheme.accentShadow};">{kpi.title}</span>
										{#each kpi.teams.slice(0, 2) as team (team.id)}
											{@const tTheme = getDossierTheme(team.color || '#0058bd')}
											<span
												class="inline-flex items-center gap-1 rounded-[2px] border px-1.5 py-0.5 text-[9px] font-bold uppercase tracking-wider"
												style="background-color: {tTheme.badgeBg}; color: {tTheme.badgeText}; border-color: {tTheme.badgeBorder};"
											>
												<span
													class="material-symbols-outlined text-[12px] shrink-0"
													style="color: {tTheme.accent};"
												>
													{getTeamIcon(team)}
												</span>
												{team.name}
											</span>
										{/each}
									</div>
									<div class="mt-0.5 text-[11px] font-medium" style="color: {kpiTheme.accentDark};">
										Atual:
										<strong class="font-bold" style="color: {kpiTheme.accentShadow};"
											>{formatNumber(kpi.current_value, kpi.unit)}</strong
										>
										/ Meta: {formatNumber(kpi.target_value, kpi.unit)} ({formatPct(
											kpi.progress
										)})
									</div>
								</div>
								<span
									class="rounded-[2px] border px-2 py-0.5 text-[10px] font-bold"
									style="background-color: {kpiTheme.badgeBg}; color: {kpiTheme.badgeText}; border-color: {kpiTheme.badgeBorder};"
								>
									{lastUpdate ? `Atualizado em ${lastUpdate.created_at.slice(0, 10)}` : 'Nunca atualizado'}
								</span>
							</div>

							{#if canEdit}
								<form
									method="POST"
									action="/strategy?/logMetric"
									use:enhanceFormValidation
									class="mt-2.5 flex items-center gap-2"
								>
									<input type="hidden" name="nodeId" value={kpi.id} />
									<input
										name="value"
										type="number"
										step="any"
										required
										placeholder="Novo valor ({kpi.unit || '#'})"
										class="w-32 rounded-[4px] border bg-surface-container-lowest px-2.5 py-1 text-xs font-semibold text-on-surface"
										style="border-color: {kpiTheme.inputBorder};"
									/>
									<input
										name="note"
										type="text"
										placeholder="Nota rápida..."
										class="min-w-0 flex-1 rounded-[4px] border bg-surface-container-lowest px-2.5 py-1 text-xs text-on-surface"
										style="border-color: {kpiTheme.inputBorder};"
									/>
									<button
										type="submit"
										class="shrink-0 rounded-[4px] px-2.5 py-1 text-xs font-bold text-white hover:opacity-95"
										style="background-color: {kpiTheme.accent}; box-shadow: 0 2px 0 {kpiTheme.accentShadow};"
									>
										Registrar
									</button>
								</form>
							{/if}
						</div>
					{/each}
				</div>
			</section>
		</div>
	</div>
</div>
