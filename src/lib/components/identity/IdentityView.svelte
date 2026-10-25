<script lang="ts">
	import { goto } from '$app/navigation';
	import { enhance } from '$app/forms';
	import type { NodeValue, NodeWithExtras, StrategicEra, StrategyNode } from '$lib/types';
	import { enhanceFormValidation, formatNumber, getInitials, getTeamIcon } from '$lib/utils';
	import { getDossierTheme } from '$lib/dossier-theme';
	import { AlertCircle, Pencil, Trash2, X } from 'lucide-svelte';
	import ValueDossierModal from './ValueDossierModal.svelte';

	interface Props {
		eras: StrategicEra[];
		valuesList: NodeWithExtras[];
		nodeValues: NodeValue[];
		strategyNodes?: NodeWithExtras[];
		canEdit: boolean;
	}

	let { eras, valuesList, nodeValues, strategyNodes = [], canEdit }: Props = $props();

	// Selected tab: era key or 'timeline'
	let selectedTab = $state<string | null>(null);
	const activeEraKey = $derived(selectedTab ?? eras[0]?.key ?? '');

	let editingMission = $state(false);
	let activeValueModal = $state<{
		mode: 'create' | 'edit';
		value: NodeWithExtras | null;
	} | null>(null);
	let showAddValue = $state(false);
	let editingValueId = $state<string | null>(null);
	let showNewEraModal = $state(false);
	let matrixFilter = $state<string>('all');
	let showAllRows = $state(false);
	let currentPage = $state(1);
	const pageSize = 8;

	$effect(() => {
		// Reset page when filter changes
		const _ = matrixFilter;
		currentPage = 1;
	});

	const selectedEra = $derived(eras.find((e) => e.key === activeEraKey) ?? eras[0] ?? null);

	// Tonal themes for Value cards & badges
	const valueThemes = [
		{
			hex: '#0058bd',
			cardBg: 'bg-primary-fixed/20',
			cardShadow:
				'shadow-[0_1px_2px_rgba(36,34,30,0.05),0_6px_16px_rgba(0,88,189,0.08),0_-1px_0_rgba(255,255,255,0.9)_inset]',
			cornerBg: 'bg-primary/10',
			dotBg: 'bg-primary',
			iconBox:
				'bg-primary/15 text-primary shadow-[inset_0_1px_1px_rgba(255,255,255,0.8),0_2px_4px_rgba(0,88,189,0.12)]',
			iconName: 'verified',
			pillarLabel: 'Pilar Operacional',
			pillarText: 'text-primary',
			titleText: 'text-on-primary-fixed',
			gaugeStroke: 'text-primary',
			btnClass:
				'bg-surface-container-lowest hover:bg-primary hover:text-on-primary text-primary',
			pillClass: 'bg-primary-fixed text-on-primary-fixed-variant',
			barClass: 'bg-primary',
			tagPrefix: 'EXC'
		},
		{
			hex: '#c2ac00',
			cardBg: 'bg-tertiary-fixed/30',
			cardShadow:
				'shadow-[0_1px_2px_rgba(36,34,30,0.05),0_6px_16px_rgba(108,94,0,0.08),0_-1px_0_rgba(255,255,255,0.9)_inset]',
			cornerBg: 'bg-tertiary/10',
			dotBg: 'bg-tertiary',
			iconBox:
				'bg-tertiary-fixed-dim/40 text-on-tertiary-container shadow-[inset_0_1px_1px_rgba(255,255,255,0.8),0_2px_4px_rgba(108,94,0,0.12)]',
			iconName: 'cloud_done',
			pillarLabel: 'Pilar Cultural',
			pillarText: 'text-tertiary',
			titleText: 'text-on-tertiary-container',
			gaugeStroke: 'text-tertiary-container',
			btnClass:
				'bg-surface-container-lowest hover:bg-tertiary-container hover:text-surface text-on-tertiary-container',
			pillClass: 'bg-tertiary-fixed text-on-tertiary-fixed-variant',
			barClass: 'bg-tertiary-fixed-dim',
			tagPrefix: 'NUV'
		},
		{
			hex: '#b30069',
			cardBg: 'bg-secondary-fixed/30',
			cardShadow:
				'shadow-[0_1px_2px_rgba(36,34,30,0.05),0_6px_16px_rgba(179,0,105,0.08),0_-1px_0_rgba(255,255,255,0.9)_inset]',
			cornerBg: 'bg-secondary/10',
			dotBg: 'bg-secondary',
			iconBox:
				'bg-secondary/15 text-secondary shadow-[inset_0_1px_1px_rgba(255,255,255,0.8),0_2px_4px_rgba(179,0,105,0.12)]',
			iconName: 'groups_3',
			pillarLabel: 'Pilar Relacional',
			pillarText: 'text-secondary',
			titleText: 'text-on-secondary-fixed-variant',
			gaugeStroke: 'text-secondary',
			btnClass:
				'bg-surface-container-lowest hover:bg-secondary hover:text-on-secondary text-secondary',
			pillClass: 'bg-secondary-fixed text-on-secondary-fixed-variant',
			barClass: 'bg-secondary',
			tagPrefix: 'CLI'
		},
		{
			hex: '#7c3aed',
			cardBg: 'bg-[#ede7f6]',
			cardShadow:
				'shadow-[0_1px_2px_rgba(36,34,30,0.05),0_6px_16px_rgba(124,58,237,0.08),0_-1px_0_rgba(255,255,255,0.9)_inset]',
			cornerBg: 'bg-[#7c3aed]/10',
			dotBg: 'bg-[#7c3aed]',
			iconBox:
				'bg-[#7c3aed]/15 text-[#6d28d9] shadow-[inset_0_1px_1px_rgba(255,255,255,0.8),0_2px_4px_rgba(124,58,237,0.12)]',
			iconName: 'lightbulb',
			pillarLabel: 'Pilar Inovação & Dono',
			pillarText: 'text-[#6d28d9]',
			titleText: 'text-[#4c1d95]',
			gaugeStroke: 'text-[#7c3aed]',
			btnClass:
				'bg-surface-container-lowest hover:bg-[#7c3aed] hover:text-white text-[#6d28d9]',
			pillClass: 'bg-[#ede9fe] text-[#5b21b6]',
			barClass: 'bg-[#7c3aed]',
			tagPrefix: 'DON'
		}
	];

	function getValueTheme(
		valOrId: { id: string; color?: string | null; icon?: string | null } | string,
		fallbackIndex = 0
	) {
		const id = typeof valOrId === 'string' ? valOrId : valOrId?.id;
		let base = valueThemes[fallbackIndex % valueThemes.length];
		if (id === 'val-excelencia') base = valueThemes[0];
		else if (id === 'val-jornada-membro') base = valueThemes[1];
		else if (id === 'val-desenvolvimento-coletivo') base = valueThemes[2];
		else if (id === 'val-sentimento-dono') base = valueThemes[3];
		else {
			const idx = valuesList.findIndex((v) => v.id === id);
			if (idx >= 0) base = valueThemes[idx % valueThemes.length];
		}

		const valColor = typeof valOrId === 'object' && valOrId?.color ? valOrId.color : base.hex;
		const valIcon = typeof valOrId === 'object' && valOrId?.icon ? valOrId.icon : base.iconName;

		return {
			...base,
			defaultHex: base.hex,
			hex: valColor,
			iconName: valIcon
		};
	}

	function getValueStats(valueId: string) {
		const alignedNodeIds = new Set(
			nodeValues.filter((nv) => nv.value_id === valueId).map((nv) => nv.node_id)
		);
		const alignedNodes = strategyNodes.filter((n) => alignedNodeIds.has(n.id));
		const okrs = alignedNodes.filter((n) => n.type === 'objective').length;
		const krs = alignedNodes.filter((n) => n.type === 'key_result').length;
		const kpis = alignedNodes.filter((n) => n.type === 'kpi').length;
		const total = alignedNodes.length;
		const avgPct =
			total > 0
				? Math.round(
						(alignedNodes.reduce((s, n) => s + n.progress, 0) / total) * 100
					)
				: 78;
		return { total, okrs, krs, kpis, avgPct };
	}

	const eraObjectivesCount = $derived.by(() => {
		if (!selectedEra) return 0;
		const objs = strategyNodes.filter(
			(n) =>
				n.type === 'objective' &&
				(n.year == null ||
					(n.year >= selectedEra.start_year &&
						(selectedEra.end_year == null || n.year <= selectedEra.end_year)))
		);
		return objs.length || strategyNodes.filter((n) => n.type === 'objective').length;
	});

	// Build Alignment Matrix rows linking Values to Strategy Objectives / KRs
	const allMatrixRows = $derived.by(() => {
		const rows: {
			id: string;
			val: NodeWithExtras;
			theme: ReturnType<typeof getValueTheme>;
			node: NodeWithExtras;
			isObjective: boolean;
			subLabel: string;
			metricLabel: string;
			targetFormatted: string | null;
			currentFormatted: string | null;
			teamName: string;
			teamColor: string;
			teamInitials: string;
			pct: number;
			atRisk: boolean;
			otherValues: StrategyNode[];
		}[] = [];

		const activeValues = selectedEra?.values ?? valuesList;
		activeValues.forEach((val, vIdx) => {
			const linkedIds = new Set(
				nodeValues.filter((nv) => nv.value_id === val.id).map((nv) => nv.node_id)
			);
			const linkedNodes = strategyNodes.filter(
				(n) => linkedIds.has(n.id) && (n.type === 'objective' || n.type === 'key_result')
			);
			for (const n of linkedNodes) {
				const isObjective = n.type === 'objective';
				const firstChild = n.children[0];

				let subLabel = '';
				let metricLabel = '';
				let targetFormatted: string | null = null;
				let currentFormatted: string | null = null;

				if (isObjective) {
					const krs = n.children.filter((c) => c.type === 'key_result');
					const completed = krs.filter((c) => c.progress >= 1).length;
					metricLabel =
						krs.length > 0 ? `${completed} de ${krs.length} KRs concluídos` : 'Objetivo Estratégico';
					subLabel = firstChild
						? `KR: ${firstChild.title}`
						: n.description || 'Objetivo Estratégico do Ciclo';
				} else {
					// It is a key_result
					const kpi = n.children.find((c) => c.type === 'kpi');
					if (kpi && kpi.target_value != null) {
						const cur = kpi.current_value ?? 0;
						const tgt = kpi.target_value;
						currentFormatted = formatNumber(cur, kpi.unit);
						targetFormatted = formatNumber(tgt, kpi.unit);
						metricLabel = `${currentFormatted} de ${targetFormatted}`;
						subLabel = `KPI: ${kpi.title}`;
					} else if (n.target_value != null) {
						const cur = n.current_value ?? 0;
						const tgt = n.target_value;
						currentFormatted = formatNumber(cur, n.unit);
						targetFormatted = formatNumber(tgt, n.unit);
						metricLabel = `${currentFormatted} de ${targetFormatted}`;
						subLabel = n.description || 'Resultado-Chave';
					} else {
						metricLabel = `${Math.round(n.progress * 100)}% concluído`;
						subLabel = firstChild
							? `${firstChild.type === 'key_result' ? 'KR' : 'KPI'}: ${firstChild.title}`
							: n.description || 'Iniciativa vinculada';
					}
				}

				const teamName = n.teams[0]?.name ?? n.assignees[0]?.name ?? 'Diretoria Executiva';
				const teamColor = n.teams[0]?.color || n.color || '#0058bd';
				const otherValues = (n.alignedValues ?? []).filter((v) => v.id !== val.id);

				rows.push({
					id: `${val.id}-${n.id}`,
					val,
					theme: getValueTheme(val, vIdx),
					node: n,
					isObjective,
					subLabel,
					metricLabel,
					targetFormatted,
					currentFormatted,
					teamName,
					teamColor,
					teamInitials: getInitials(teamName),
					pct: Math.round(n.progress * 100),
					atRisk: Boolean(n.atRisk || n.status === 'at_risk' || n.status === 'off_track'),
					otherValues
				});
			}
		});

		return rows;
	});

	const filteredMatrixRows = $derived.by(() => {
		if (matrixFilter === 'restricted') {
			return allMatrixRows.filter((r) => r.atRisk || r.pct < 70);
		}
		if (matrixFilter === 'team') {
			return [...allMatrixRows].sort((a, b) => a.teamName.localeCompare(b.teamName));
		}
		if (matrixFilter !== 'all') {
			return allMatrixRows.filter((r) => r.val.id === matrixFilter);
		}
		return allMatrixRows;
	});

	const totalPages = $derived(Math.max(1, Math.ceil(filteredMatrixRows.length / pageSize)));
	const displayedMatrixRows = $derived(
		showAllRows
			? filteredMatrixRows
			: filteredMatrixRows.slice((currentPage - 1) * pageSize, currentPage * pageSize)
	);
</script>

<div class="relative w-full pb-16 flex flex-col gap-8">
	<!-- Subtle Decorative Atmospheric Elements -->
	<div
		class="absolute -top-6 -right-10 w-96 h-96 bg-primary-fixed/20 rounded-full blur-3xl pointer-events-none -z-10"
	></div>
	<div
		class="absolute top-1/2 -left-12 w-80 h-80 bg-secondary-fixed/30 rounded-full blur-3xl pointer-events-none -z-10"
	></div>

	<!-- Page Title & Header Actions -->
	<div class="flex flex-col lg:flex-row lg:items-end justify-between gap-space-md pb-space-xs">
		<div class="flex flex-col gap-space-xs max-w-3xl">
			<div class="flex items-center gap-space-xs">
				<span
					class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-surface-container-high text-primary font-label-sm text-label-sm uppercase tracking-wider shadow-sm"
				>
					Estrutura de Liderança • Matriz {selectedEra?.start_year ?? 2026}.1
				</span>
			</div>
			<h1
				class="font-headline-xl text-headline-xl text-on-surface tracking-tight leading-tight"
			>
				Identidade Organizacional
			</h1>
			<p class="font-body-md text-body-md text-on-surface-variant">
				Missão Estratégica e Valores Fundamentais estruturados ao longo dos ciclos de gestão, servindo
				como bússola de alinhamento executivo.
			</p>
		</div>

		<!-- Action Buttons -->
		{#if canEdit}
			<div class="flex items-center gap-3 shrink-0">
				<!-- + Novo Valor (Sunshine Yellow) -->
				{#if selectedEra && activeEraKey !== 'timeline'}
					<button
						type="button"
						onclick={() => (activeValueModal = { mode: 'create', value: null })}
						class="group relative px-4 py-2.5 rounded-lg bg-tertiary-fixed text-on-tertiary-fixed font-label-md text-label-md font-bold flex items-center gap-2 shadow-[0_2px_0_#c2ac00,0_4px_10px_rgba(194,172,0,0.2)] active:translate-y-0.5 active:shadow-[0_1px_0_#c2ac00] transition-all cursor-pointer"
					>
						<span
							class="material-symbols-outlined text-[18px] group-hover:rotate-90 transition-transform duration-300"
						>
							add
						</span>
						<span>Novo Valor</span>
					</button>
				{/if}

				<!-- + Nova Era (Electric Blue) -->
				<button
					type="button"
					onclick={() => (showNewEraModal = true)}
					class="group relative px-4 py-2.5 rounded-lg bg-primary text-on-primary font-label-md text-label-md font-bold flex items-center gap-2 shadow-[0_2px_0_#004494,0_4px_12px_rgba(0,88,189,0.25)] active:translate-y-0.5 active:shadow-[0_1px_0_#004494] transition-all"
				>
					<span class="material-symbols-outlined text-[18px]">calendar_add_on</span>
					<span>Nova Era</span>
				</button>
			</div>
		{/if}
	</div>

	<!-- Eras Navigation Bar (Folder tabs styling) -->
	{#if eras.length > 0}
		<div class="relative flex flex-wrap items-end gap-1.5 pt-2">
			{#each eras as era (era.key)}
				{@const isSelected = activeEraKey === era.key}
				{#if isSelected}
					<!-- Active Folder Tab -->
					<button
						type="button"
						onclick={() => {
							selectedTab = era.key;
							editingMission = false;
							activeValueModal = null;
						}}
						class="relative group z-20 flex items-center gap-2.5 px-6 py-3 bg-surface-container-lowest text-primary font-label-md text-label-md rounded-t-xl shadow-[0_-3px_8px_rgba(36,34,30,0.05),-2px_0_4px_rgba(36,34,30,0.03),2px_0_4px_rgba(36,34,30,0.03)] cursor-default"
					>
						<!-- Folded Corner Effect top-right -->
						<div
							class="absolute top-0 right-0 w-3.5 h-3.5 bg-surface-container-high rounded-bl-sm pointer-events-none shadow-[inset_1px_-1px_2px_rgba(0,0,0,0.08)]"
						></div>
						{#if era.isCurrent}
							<span class="flex h-2 w-2 relative">
								<span
									class="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75"
								></span>
								<span class="relative inline-flex rounded-full h-2 w-2 bg-primary"></span>
							</span>
						{:else}
							<span class="w-2 h-2 rounded-full bg-primary"></span>
						{/if}
						<span class="font-bold tracking-tight">
							Era {era.start_year}{era.end_year ? `–${era.end_year}` : ' (Atual)'}
						</span>
						<span
							class="ml-1 px-1.5 py-0.5 rounded text-[10px] bg-primary-fixed text-on-primary-fixed font-bold uppercase tracking-wider"
						>
							{era.isCurrent ? 'Vigente' : 'Arquivada'}
						</span>
					</button>
				{:else}
					<!-- Inactive Folder Tab -->
					<button
						type="button"
						onclick={() => {
							selectedTab = era.key;
							editingMission = false;
							activeValueModal = null;
						}}
						class="relative group z-10 flex items-center gap-2 px-5 py-2.5 bg-surface-container-high text-on-surface-variant hover:text-on-surface font-label-md text-label-md rounded-t-lg shadow-[inset_0_-2px_4px_rgba(36,34,30,0.04)] transition-colors"
					>
						<span class="w-1.5 h-1.5 rounded-full bg-outline"></span>
						<span>Era {era.start_year}{era.end_year ? `–${era.end_year}` : ''}</span>
						<span class="ml-1 font-label-sm text-label-sm opacity-60">
							{era.isCurrent ? 'Vigente' : 'Consolidada'}
						</span>
					</button>
				{/if}
			{/each}

			<!-- Timeline Tab -->
			<button
				type="button"
				onclick={() => {
					selectedTab = 'timeline';
					editingMission = false;
					activeValueModal = null;
				}}
				class="relative group z-0 flex items-center gap-2 px-5 py-2.5 font-label-md text-label-md rounded-t-lg transition-colors {activeEraKey ===
				'timeline'
					? 'z-20 bg-surface-container-lowest text-primary font-bold shadow-[0_-3px_8px_rgba(36,34,30,0.05)]'
					: 'bg-surface-container-high text-on-surface-variant hover:text-on-surface shadow-[inset_0_-2px_4px_rgba(36,34,30,0.04)]'}"
			>
				<span class="material-symbols-outlined text-[16px] text-outline">history</span>
				<span>Linha do Tempo / Histórico</span>
			</button>

			<div class="flex-1 pb-2 flex justify-end items-center pr-2">
				<span
					class="font-label-sm text-label-sm text-outline uppercase tracking-widest hidden sm:inline-block"
				>
					Snapshot de Governança Corporativa
				</span>
			</div>
		</div>
	{/if}

	<!-- TAB 1: ALL ERAS TIMELINE VIEW -->
	{#if activeEraKey === 'timeline'}
		<div class="space-y-6 -mt-1">
			{#each eras as era (era.key)}
				<div
					class="relative rounded-2xl bg-surface-container-lowest p-6 md:p-8 shadow-[0_1px_1px_rgba(36,34,30,0.05),0_4px_12px_rgba(36,34,30,0.06),0_-1px_0_rgba(255,255,255,0.9)_inset]"
				>
					<div
						class="flex flex-wrap items-center justify-between gap-2 border-b border-outline-variant/40 pb-3"
					>
						<div class="flex items-center gap-2.5">
							<span
								class="px-2.5 py-0.5 rounded-full font-label-sm text-label-sm font-bold uppercase {era.isCurrent
									? 'bg-primary-fixed text-on-primary-fixed'
									: 'bg-surface-container text-on-surface-variant'}"
							>
								{era.isCurrent ? 'Era Vigente' : 'Ciclo Consolidado'}
							</span>
							<h3 class="font-headline-sm text-headline-sm text-on-surface">{era.label}</h3>
						</div>
						<span class="font-label-sm text-label-sm text-outline uppercase">
							{era.values.length} {era.values.length === 1 ? 'Valor Fundamental' : 'Valores Fundamentais'}
						</span>
					</div>

					{#if era.mission}
						<div class="mt-4 rounded-xl bg-surface-container-low p-5 shadow-[inset_0_1px_2px_rgba(36,34,30,0.05)]">
							<div class="font-label-sm text-label-sm font-bold text-primary uppercase tracking-wider">
								Declaração de Missão
							</div>
							<blockquote class="mt-1 font-headline-sm text-headline-sm italic text-on-surface">
								“{era.mission.title}”
							</blockquote>
							{#if era.mission.description}
								<p class="mt-1 font-body-sm text-body-sm text-on-surface-variant">
									{era.mission.description}
								</p>
							{/if}
						</div>
					{/if}

					<div class="mt-5 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
						{#each era.values as val, vIdx (val.id)}
							{@const theme = getValueTheme(val, vIdx)}
							{@const dTheme = getDossierTheme(theme.hex)}
							{@const isCustom = Boolean(val.color && val.color !== theme.defaultHex)}
							{@const cardIcon = val.icon || theme.iconName}
							<div
								class="rounded-xl p-4 transition-colors {isCustom ? 'border' : `${theme.cardBg} ${theme.cardShadow}`}"
								style={isCustom
									? `background-color: ${dTheme.cardBg}; border-color: ${dTheme.cardBorder};`
									: undefined}
							>
								<div class="flex items-center gap-2">
									<span
										class="material-symbols-outlined text-[18px]"
										style={isCustom ? `color: ${dTheme.accent};` : undefined}
									>
										{cardIcon}
									</span>
									<span
										class="font-title-md text-title-md font-bold"
										style={isCustom ? `color: ${dTheme.accentDark};` : undefined}
									>
										{val.title}
									</span>
								</div>
								{#if val.description}
									<p class="mt-1.5 font-body-sm text-body-sm text-on-surface-variant line-clamp-2">
										{val.description}
									</p>
								{/if}
							</div>
						{/each}
					</div>
				</div>
			{/each}
		</div>

	<!-- TAB 2: SPECIFIC ERA VIEW (Active or Archived) -->
	{:else if selectedEra}
		{@const era = selectedEra}
		{@const mission = era.mission}
		{@const valuesInEra = era.values}

		<!-- Missão Estratégica Box (Archival Parchment Paper Card with Brass Pin Accents) -->
		{#if mission}
			<div
				class="relative w-full rounded-2xl bg-surface-container-lowest p-8 md:p-10 shadow-[0_1px_1px_rgba(36,34,30,0.05),0_4px_12px_rgba(36,34,30,0.06),0_-1px_0_rgba(255,255,255,0.9)_inset] overflow-hidden -mt-1"
			>
				<!-- Top edge simulated parchment ruler mark -->
				<div class="absolute top-0 left-0 right-0 h-1 bg-surface-variant mat-ruler-h opacity-70"></div>

				<!-- Brass Pin Accents at corners -->
				<div
					class="absolute top-4 left-4 w-3 h-3 rounded-full bg-gradient-to-br from-tertiary-fixed to-tertiary shadow-[0_1px_2px_rgba(0,0,0,0.3),inset_0_1px_1px_rgba(255,255,255,0.6)] flex items-center justify-center"
				>
					<div class="w-1 h-1 rounded-full bg-tertiary-container"></div>
				</div>
				<div
					class="absolute top-4 right-4 w-3 h-3 rounded-full bg-gradient-to-br from-tertiary-fixed to-tertiary shadow-[0_1px_2px_rgba(0,0,0,0.3),inset_0_1px_1px_rgba(255,255,255,0.6)] flex items-center justify-center"
				>
					<div class="w-1 h-1 rounded-full bg-tertiary-container"></div>
				</div>

				<div class="flex flex-col gap-6">
					<!-- Mission Header & Edit Trigger -->
					<div class="flex flex-wrap items-center justify-between gap-4 pb-2">
						<div class="flex items-center gap-3">
							<span class="w-2.5 h-2.5 bg-primary rounded-sm rotate-45"></span>
							<span class="font-label-md text-label-md tracking-widest uppercase text-primary font-bold">
								MISSÃO ESTRATÉGICA DA ERA ({era.start_year}{era.end_year ? `–${era.end_year}` : ''})
							</span>
						</div>

						{#if canEdit}
							<button
								type="button"
								onclick={() => (editingMission = !editingMission)}
								class="px-3.5 py-1.5 rounded-lg bg-surface-container hover:bg-surface-container-high text-on-surface font-label-md text-label-md flex items-center gap-1.5 shadow-[inset_0_1px_0_rgba(255,255,255,0.9),0_1px_2px_rgba(36,34,30,0.06)] transition-colors active:translate-y-px"
							>
								<span class="material-symbols-outlined text-[16px] text-outline">edit_note</span>
								<span>{editingMission ? 'Cancelar Edição' : 'Editar Missão'}</span>
							</button>
						{/if}
					</div>

					{#if editingMission}
						<form
							method="POST"
							action="?/updateIdentityNode"
							use:enhance={() => {
								return async ({ result, update }) => {
									if (result.type === 'success') {
										editingMission = false;
									}
									await update({ reset: false });
								};
							}}
							use:enhanceFormValidation
							class="space-y-4 rounded-xl bg-surface-container-low p-5 shadow-[inset_0_2px_4px_rgba(36,34,30,0.05)]"
						>
							<input type="hidden" name="nodeId" value={mission.id} />
							<div>
								<label
									for="edit-mission-title"
									class="block font-label-md text-label-md font-bold text-on-surface"
								>
									Declaração de Missão <span class="text-error">*</span>
								</label>
								<input
									id="edit-mission-title"
									name="title"
									type="text"
									required
									value={mission.title}
									aria-errormessage="edit-mission-err"
									class="mt-1 w-full rounded-lg bg-surface-container-lowest px-3.5 py-2 font-body-md text-body-md text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:outline-none focus:ring-1 focus:ring-primary"
								/>
								<div id="edit-mission-err" class="error-msg">
									<AlertCircle class="h-3.5 w-3.5" />
									<span>A declaração de missão não pode ficar vazia.</span>
								</div>
							</div>
							<div>
								<label
									for="edit-mission-desc"
									class="block font-label-md text-label-md font-bold text-on-surface"
								>
									Escopo / Narrativa Estratégica
								</label>
								<textarea
									id="edit-mission-desc"
									name="description"
									rows="2"
									class="mt-1 w-full rounded-lg bg-surface-container-lowest px-3.5 py-2 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:outline-none focus:ring-1 focus:ring-primary"
									>{mission.description ?? ''}</textarea
								>
							</div>
							<div class="grid grid-cols-2 gap-3">
								<div>
									<label
										for="m-start"
										class="block font-label-sm text-label-sm uppercase text-on-surface-variant"
									>
										Ano Inicial
									</label>
									<input
										id="m-start"
										name="start_year"
										type="number"
										value={mission.start_year ?? era.start_year}
										class="mt-1 w-full rounded-lg bg-surface-container-lowest px-3 py-1.5 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
									/>
								</div>
								<div>
									<label
										for="m-end"
										class="block font-label-sm text-label-sm uppercase text-on-surface-variant"
									>
										Ano Final (Em branco se vigente)
									</label>
									<input
										id="m-end"
										name="end_year"
										type="number"
										placeholder="Em andamento"
										value={mission.end_year ?? ''}
										class="mt-1 w-full rounded-lg bg-surface-container-lowest px-3 py-1.5 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
									/>
								</div>
							</div>
							<div class="flex justify-end gap-2 pt-2">
								<button
									type="button"
									onclick={() => (editingMission = false)}
									class="px-3.5 py-1.5 rounded-lg bg-surface-container text-on-surface-variant font-label-md text-label-md"
								>
									Cancelar
								</button>
								<button
									type="submit"
									class="px-4 py-1.5 rounded-lg bg-primary text-on-primary font-label-md text-label-md font-bold shadow-[0_2px_0_#004494]"
								>
									Salvar Alterações
								</button>
							</div>
						</form>
					{:else}
						<!-- Editorial Quote Display -->
						<div class="relative pl-6 md:pl-8 py-2">
							<span
								class="absolute left-0 top-0 text-6xl font-display-lg text-primary/20 leading-none select-none"
							>
								“
							</span>
							<blockquote
								class="font-headline-xl text-2xl md:text-headline-xl text-on-surface italic tracking-tight leading-snug max-w-4xl"
							>
								{mission.title}
							</blockquote>
						</div>
					{/if}

					<!-- Metadata & Scope Tags -->
					<div
						class="flex flex-wrap items-center justify-between gap-4 pt-4 bg-surface-container-low/60 rounded-xl p-4 shadow-[inset_0_1px_2px_rgba(36,34,30,0.04)]"
					>
						<div class="flex flex-wrap items-center gap-3 md:gap-6">
							<div class="flex items-center gap-2">
								<span class="material-symbols-outlined text-[18px] text-primary">domain</span>
								<span class="font-body-md text-body-md text-on-surface font-semibold">
									Escopo: {era.start_year} - Nuvem
								</span>
							</div>
							<div class="h-4 w-px bg-outline-variant/60"></div>
							<div class="flex items-center gap-2">
								<span class="material-symbols-outlined text-[18px] text-tertiary">hub</span>
								<span class="font-body-md text-body-md text-on-surface">
									Alinhada com <strong class="font-bold text-primary">{eraObjectivesCount} Objetivos Anuais</strong>
								</span>
							</div>
							<div class="h-4 w-px bg-outline-variant/60 hidden sm:block"></div>
							<div class="hidden sm:flex items-center gap-2">
								<span class="material-symbols-outlined text-[18px] text-secondary">verified</span>
								<span class="font-body-md text-body-md text-on-surface-variant">
									Revisão trimestral concluída
								</span>
							</div>
						</div>

						<!-- Small Mini Sparkline Graph Indicator -->
						<div class="flex items-center gap-2">
							<span class="font-label-sm text-label-sm text-outline uppercase tracking-wider">
								Aderência:
							</span>
							<div class="flex items-end gap-1">
								<div class="w-1.5 h-3.5 bg-primary rounded-xs"></div>
								<div class="w-1.5 h-4.5 bg-primary rounded-xs"></div>
								<div class="w-1.5 h-5.5 bg-primary rounded-xs"></div>
								<div class="w-1.5 h-6.5 bg-primary rounded-xs"></div>
								<div class="w-1.5 h-7.5 bg-tertiary-fixed-dim rounded-xs"></div>
							</div>
							<span class="font-label-md text-label-md font-bold text-on-surface ml-1">94%</span>
						</div>
					</div>
				</div>
			</div>



			<!-- Section: Valores Fundamentais -->
			<div class="flex flex-col gap-5 pt-2">
				<div class="flex flex-col md:flex-row md:items-end justify-between gap-2">
					<div class="flex flex-col">
						<div class="flex items-center gap-2">
							<span class="material-symbols-outlined text-primary text-[20px]">
								filter_center_focus
							</span>
							<h2
								class="font-headline-sm text-headline-sm text-on-surface tracking-tight uppercase"
							>
								Valores Fundamentais
							</h2>
						</div>
						<span class="font-label-md text-label-md text-on-surface-variant">
							Lente de Alinhamento para priorização de investimentos, projetos e dinâmicas de pessoas
						</span>
					</div>
					<div
						class="flex items-center gap-2 text-outline font-label-sm text-label-sm uppercase tracking-wider"
					>
						<span>Arraste ou clique para inspeção direta</span>
					</div>
				</div>

				<!-- Colorful Skeuomorphic Cards Mosaic Grid -->
				<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
					{#each valuesInEra as val, idx (val.id)}
						{@const theme = getValueTheme(val, idx)}
						{@const stats = getValueStats(val.id)}
						{@const tagCode = `TAG #${theme.tagPrefix}-${String(era.start_year).slice(-2)}`}
						{@const dTheme = getDossierTheme(theme.hex)}
						{@const isCustom = Boolean(val.color && val.color !== theme.defaultHex)}
						{@const cardIcon = val.icon || theme.iconName}

						<div
							class="relative group rounded-2xl p-6 flex flex-col justify-between hover:-translate-y-1 transition-all duration-300 {isCustom ? 'border' : theme.cardBg}"
							style={isCustom
								? `background-color: ${dTheme.cardBg}; border-color: ${dTheme.cardBorder}; box-shadow: 0 1px 2px rgba(36,34,30,0.05), 0 6px 16px color-mix(in srgb, ${dTheme.accent} 12%, transparent), inset 0 1px 0 rgba(255,255,255,0.9);`
								: undefined}
							class:shadow-[0_1px_2px_rgba(36,34,30,0.05),0_6px_16px_rgba(0,88,189,0.08),0_-1px_0_rgba(255,255,255,0.9)_inset]={!isCustom && theme.tagPrefix === 'EXC'}
							class:shadow-[0_1px_2px_rgba(36,34,30,0.05),0_6px_16px_rgba(108,94,0,0.08),0_-1px_0_rgba(255,255,255,0.9)_inset]={!isCustom && theme.tagPrefix === 'NUV'}
							class:shadow-[0_1px_2px_rgba(36,34,30,0.05),0_6px_16px_rgba(179,0,105,0.08),0_-1px_0_rgba(255,255,255,0.9)_inset]={!isCustom && theme.tagPrefix === 'CLI'}
							class:shadow-[0_1px_2px_rgba(36,34,30,0.05),0_6px_16px_rgba(124,58,237,0.08),0_-1px_0_rgba(255,255,255,0.9)_inset]={!isCustom && theme.tagPrefix === 'DON'}
						>
							<!-- Folder corner tab accent -->
							<div
								class="absolute top-0 right-0 w-8 h-8 rounded-bl-xl flex items-center justify-center transition-colors {isCustom ? '' : theme.cornerBg}"
								style={isCustom ? `background-color: ${dTheme.badgeBg};` : undefined}
							>
								<div
									class="w-2 h-2 rounded-full transition-colors {isCustom ? '' : theme.dotBg}"
									style={isCustom ? `background-color: ${dTheme.accent};` : undefined}
								></div>
							</div>

							<div class="flex flex-col gap-4">
								<!-- Header Icon + Title + Edit/Delete Actions -->
								<div class="flex items-start justify-between gap-2 pr-4">
									<div class="flex items-start gap-3">
										<div
											class="w-12 h-12 rounded-xl flex items-center justify-center shrink-0 transition-colors {isCustom ? 'border shadow-xs' : theme.iconBox}"
											style={isCustom
												? `background-color: ${dTheme.badgeBg}; border-color: ${dTheme.badgeBorder}; color: ${dTheme.accentDark};`
												: undefined}
										>
											<span class="material-symbols-outlined text-[26px]">{cardIcon}</span>
										</div>
										<div class="flex flex-col">
											<span
												class="font-label-sm text-label-sm uppercase tracking-widest font-bold {isCustom ? '' : theme.pillarText}"
												style={isCustom ? `color: ${dTheme.accent};` : undefined}
											>
												{theme.pillarLabel}
											</span>
											<h3
												class="font-title-md text-title-md font-bold leading-tight {isCustom ? '' : theme.titleText}"
												style={isCustom ? `color: ${dTheme.accentDark};` : undefined}
											>
												{val.title}
											</h3>
										</div>
									</div>

									{#if canEdit}
										<div
											class="flex items-center gap-0.5 opacity-0 group-hover:opacity-100 transition-opacity"
										>
											<button
												type="button"
												onclick={() => (activeValueModal = { mode: 'edit', value: val })}
												class="p-1 rounded hover:bg-white/60 text-on-surface-variant hover:text-on-surface cursor-pointer"
												title="Editar Valor"
											>
												<Pencil class="h-3.5 w-3.5" />
											</button>
											<form
												method="POST"
												action="?/deleteIdentityNode"
												use:enhance={() => {
													return async ({ update }) => {
														await update({ reset: false });
													};
												}}
											>
												<input type="hidden" name="nodeId" value={val.id} />
												<button
													type="submit"
													class="p-1 rounded hover:bg-error-container text-on-surface-variant hover:text-error cursor-pointer"
													title="Excluir Valor"
												>
													<Trash2 class="h-3.5 w-3.5" />
												</button>
											</form>
										</div>
									{/if}
								</div>

								<!-- Description -->
								<p class="font-body-md text-body-md text-on-surface leading-relaxed">
									{val.description ||
										'Compromisso intransigente com padrões de excelência e impacto estratégico.'}
								</p>

								<!-- Metric Box (Debossed Well) -->
								<div
									class="rounded-xl bg-surface-container-lowest/80 p-3 shadow-[inset_0_2px_4px_rgba(36,34,30,0.05)] flex items-center justify-between"
								>
									<div class="flex flex-col">
										<span class="font-label-sm text-label-sm text-outline uppercase">
											Impacto Atual
										</span>
										<span class="font-label-md text-label-md font-bold text-on-surface">
											{stats.total} {stats.total === 1 ? 'item alinhado' : 'itens alinhados'}
										</span>
										<span class="font-body-sm text-body-sm text-on-surface-variant">
											{stats.okrs} OKRs • {stats.krs} KRs • {stats.kpis} KPIs
										</span>
									</div>

									<!-- Radial Mini gauge visual -->
									<div class="relative w-10 h-10 flex items-center justify-center shrink-0">
										<svg class="w-10 h-10 -rotate-90" viewBox="0 0 36 36">
											<path
												class="text-surface-container-high"
												d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
												fill="none"
												stroke="currentColor"
												stroke-width="3.5"
											></path>
											<path
												class={isCustom ? '' : theme.gaugeStroke}
												d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
												fill="none"
												stroke={isCustom ? dTheme.accent : 'currentColor'}
												stroke-dasharray="{stats.avgPct}, 100"
												stroke-linecap="round"
												stroke-width="3.5"
											></path>
										</svg>
										<span
											class="absolute font-label-sm text-[10px] font-bold {isCustom ? '' : theme.pillarText}"
											style={isCustom ? `color: ${dTheme.accentDark};` : undefined}
										>
											{stats.avgPct}%
										</span>
									</div>
								</div>
							</div>

							<!-- Bottom Action Button -->
							<div class="pt-5 flex items-center justify-between">
								<span class="font-label-sm text-label-sm text-outline">{tagCode}</span>
								<button
									type="button"
									onclick={() => goto(`/strategy?lens=${val.id}`)}
									class="group/btn px-3 py-1.5 rounded-lg font-label-md text-label-md shadow-[0_1px_3px_rgba(36,34,30,0.06)] flex items-center gap-1 transition-all cursor-pointer {isCustom ? 'bg-surface-container-lowest' : theme.btnClass}"
									style={isCustom ? `color: ${dTheme.accentDark};` : undefined}
								>
									<span>Ver no Canvas</span>
									<span
										class="material-symbols-outlined text-[16px] group-hover/btn:translate-x-0.5 transition-transform"
									>
										arrow_forward
									</span>
								</button>
							</div>
						</div>
					{/each}
				</div>
			</div>

			<!-- Bottom Drawer: Matriz de Alinhamento Tático Rápido (Table linking values to OKRs & Teams) -->
			<div
				class="relative w-full rounded-2xl bg-surface-container-lowest p-6 md:p-8 shadow-[0_1px_1px_rgba(36,34,30,0.05),0_6px_16px_rgba(36,34,30,0.04),0_-1px_0_rgba(255,255,255,0.9)_inset]"
			>
				<div class="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-6">
					<div class="flex items-center gap-3">
						<div class="p-2 rounded-lg bg-surface-container text-on-surface">
							<span class="material-symbols-outlined text-[20px]">table_chart_view</span>
						</div>
						<div>
							<h3 class="font-title-md text-title-md text-on-surface font-bold">
								Matriz de Alinhamento Rápido: Valores x OKRs Vigentes
							</h3>
							<p class="font-body-sm text-body-sm text-on-surface-variant">
								Distribuição cruzada de iniciativas de liderança por equipe no Ciclo {era.start_year}-S1
							</p>
						</div>
					</div>

					<!-- Filter Pill Buttons -->
					<div class="flex items-center gap-2 flex-wrap">
						<span
							class="font-label-sm text-label-sm text-outline uppercase tracking-wider hidden sm:inline"
						>
							Exibir:
						</span>
						<div class="flex flex-wrap bg-surface-container p-1 rounded-lg gap-1">
							<button
								type="button"
								onclick={() => (matrixFilter = 'all')}
								class="px-2.5 py-1 rounded font-label-sm text-label-sm transition-all {matrixFilter ===
								'all'
									? 'bg-surface-container-lowest text-primary font-bold shadow-sm'
									: 'text-on-surface-variant hover:text-on-surface'}"
							>
								Todos ({allMatrixRows.length})
							</button>

							{#each (selectedEra?.values ?? valuesList) as val, vIdx}
								{@const count = allMatrixRows.filter((r) => r.val.id === val.id).length}
								{@const vTheme = getValueTheme(val, vIdx)}
								{@const isCustomV = Boolean(val.color && val.color !== vTheme.defaultHex)}
								<button
									type="button"
									onclick={() => (matrixFilter = val.id)}
									class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded font-label-sm text-label-sm transition-all {matrixFilter ===
									val.id
										? 'bg-surface-container-lowest text-primary font-bold shadow-sm'
										: 'text-on-surface-variant hover:text-on-surface'}"
								>
									<span
										class="w-1.5 h-1.5 rounded-full {isCustomV ? '' : vTheme.dotBg}"
										style={isCustomV ? `background-color: ${vTheme.hex};` : undefined}
									></span>
									<span>{val.title} ({count})</span>
								</button>
							{/each}

							<button
								type="button"
								onclick={() => (matrixFilter = 'team')}
								class="px-2.5 py-1 rounded font-label-sm text-label-sm transition-all {matrixFilter ===
								'team'
									? 'bg-surface-container-lowest text-primary font-bold shadow-sm'
									: 'text-on-surface-variant hover:text-on-surface'}"
							>
								Por Equipe
							</button>
							<button
								type="button"
								onclick={() => (matrixFilter = 'restricted')}
								class="px-2.5 py-1 rounded font-label-sm text-label-sm transition-all {matrixFilter ===
								'restricted'
									? 'bg-surface-container-lowest text-primary font-bold shadow-sm'
									: 'text-on-surface-variant hover:text-on-surface'}"
							>
								Com Restrições
							</button>
						</div>
					</div>
				</div>

				<!-- Alignment Ledger Table -->
				<div class="w-full overflow-x-auto">
					<table class="w-full text-left">
						<thead>
							<tr
								class="bg-surface-container-low text-on-surface-variant font-label-sm text-label-sm uppercase tracking-wider"
							>
								<th class="py-3 px-4 rounded-l-lg">Valor Vinculado</th>
								<th class="py-3 px-4">Objetivo Estratégico (OKR)</th>
								<th class="py-3 px-4">Equipe Responsável</th>
								<th class="py-3 px-4">Progresso do Ciclo</th>
								<th class="py-3 px-4 text-right rounded-r-lg">Ação</th>
							</tr>
						</thead>
						<tbody class="font-body-md text-body-md divide-y divide-surface-container">
							{#each displayedMatrixRows as row (row.id)}
								{@const theme = row.theme}
								{@const tTheme = getDossierTheme(row.teamColor)}
								{@const isCustomRow = Boolean(row.val.color && row.val.color !== theme.defaultHex)}
								{@const rowDossier = getDossierTheme(theme.hex)}
								<tr class="hover:bg-surface-container/60 transition-colors">
									<td class="py-4 px-4 align-top">
										<div class="flex flex-col items-start gap-1">
											<span
												class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full font-label-sm text-label-sm font-bold shadow-xs {isCustomRow
													? 'border'
													: theme.pillClass}"
												style={isCustomRow
													? `background-color: ${rowDossier.badgeBg}; border-color: ${rowDossier.badgeBorder}; color: ${rowDossier.accentDark};`
													: undefined}
											>
												<span
													class="w-1.5 h-1.5 rounded-full {isCustomRow ? '' : theme.dotBg}"
													style={isCustomRow ? `background-color: ${rowDossier.accent};` : undefined}
												></span>
												{row.val.title}
											</span>
											{#if row.otherValues.length > 0}
												<div class="flex flex-wrap items-center gap-1 mt-0.5">
													{#each row.otherValues as ov}
														{@const ovTheme = getValueTheme(ov)}
														{@const isCustomOv = Boolean(ov.color && ov.color !== ovTheme.defaultHex)}
														{@const ovDossier = getDossierTheme(ovTheme.hex)}
														<span
															class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-bold {isCustomOv
																? 'border'
																: ovTheme.pillClass}"
															style={isCustomOv
																? `background-color: ${ovDossier.badgeBg}; border-color: ${ovDossier.badgeBorder}; color: ${ovDossier.accentDark};`
																: undefined}
															title={`Também alinhado a ${ov.title}`}
														>
															<span
																class="w-1 h-1 rounded-full {isCustomOv ? '' : ovTheme.dotBg}"
																style={isCustomOv ? `background-color: ${ovDossier.accent};` : undefined}
															></span>
															{ov.title}
														</span>
													{/each}
												</div>
											{/if}
										</div>
									</td>
									<td class="py-4 px-4 align-top">
										<div class="flex items-start gap-2">
											<span
												class="px-1.5 py-0.5 rounded text-[9px] font-bold uppercase tracking-wider shrink-0 mt-0.5 {row.isObjective
													? 'bg-primary/10 text-primary'
													: 'bg-surface-container-high text-on-surface-variant'}"
											>
												{row.isObjective ? 'OKR' : 'KR'}
											</span>
											<div class="flex flex-col">
												<span class="font-semibold text-on-surface leading-snug">
													{row.node.title}
												</span>
												<div
													class="mt-0.5 flex flex-wrap items-center gap-x-2 gap-y-0.5 font-body-sm text-body-sm text-on-surface-variant"
												>
													<span>{row.subLabel}</span>
													{#if row.targetFormatted}
														<span class="text-outline">•</span>
														<span class="font-medium text-on-surface">
															Meta: {row.targetFormatted}
														</span>
													{/if}
												</div>
											</div>
										</div>
									</td>
									<td class="py-4 px-4 align-top">
										<span
											class="inline-flex items-center gap-1 rounded-full border px-2 py-0.5 font-label-sm text-label-sm font-bold"
											title="Equipe: {row.teamName}"
											style="background-color: {tTheme.badgeBg}; border-color: {tTheme.badgeBorder}; color: {tTheme.badgeText};"
										>
											<span
												class="material-symbols-outlined text-[13px] shrink-0"
												style="color: {tTheme.accent};"
											>
												{getTeamIcon(row.teamName)}
											</span>
											<span class="max-w-[120px] truncate">{row.teamName}</span>
										</span>
									</td>
									<td class="py-4 px-4 align-top">
										<div class="flex flex-col gap-1 min-w-[160px]">
											<div class="flex items-center gap-3">
												<div
													class="flex-1 h-2 rounded-full bg-surface-container shadow-[inset_0_1px_2px_rgba(36,34,30,0.06)] overflow-hidden"
												>
													<div
														class="h-full {theme.barClass} rounded-full transition-all duration-300"
														style="width: {row.pct}%"
													></div>
												</div>
												<span
													class="font-label-sm text-label-sm font-bold text-on-surface w-9 text-right shrink-0"
												>
													{row.pct}%
												</span>
											</div>
											<!-- Valores métricos dos OKRs e KPIs -->
											<span class="text-[11px] text-on-surface-variant font-mono font-medium">
												{row.metricLabel}
											</span>
										</div>
									</td>
									<td class="py-4 px-4 text-right align-top">
										<button
											type="button"
											onclick={() => goto(`/strategy?lens=${row.val.id}`)}
											class="p-1.5 hover:bg-surface-container rounded text-outline hover:text-on-surface transition-colors"
											title="Ver no Canvas Estratégico"
										>
											<span class="material-symbols-outlined text-[20px]">open_in_new</span>
										</button>
									</td>
								</tr>
							{:else}
								<tr>
									<td colspan="5" class="py-8 text-center font-body-sm text-body-sm text-outline">
										Nenhum item encontrado para o filtro selecionado.
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>

				<!-- Pagination & Summary Controls -->
				{#if filteredMatrixRows.length > 0}
					<div
						class="mt-4 pt-4 border-t border-surface-container flex flex-wrap items-center justify-between text-on-surface-variant font-body-sm text-body-sm gap-3"
					>
						<div class="flex items-center gap-2">
							<span class="material-symbols-outlined text-[16px] text-tertiary">info</span>
							<span>
								Exibindo <strong class="text-on-surface">{displayedMatrixRows.length}</strong> de <strong class="text-on-surface">{filteredMatrixRows.length}</strong> conexões
								{#if matrixFilter !== 'all'}
									(filtrado)
								{/if}
							</span>
						</div>

						<div class="flex items-center gap-2">
							{#if filteredMatrixRows.length > pageSize}
								<button
									type="button"
									onclick={() => (showAllRows = !showAllRows)}
									class="px-2.5 py-1 rounded bg-surface-container hover:bg-surface-container-high text-on-surface font-label-sm text-label-sm transition-colors"
								>
									{showAllRows ? `Mostrar ${pageSize} por página` : `Ver todos (${filteredMatrixRows.length})`}
								</button>
							{/if}

							{#if !showAllRows && totalPages > 1}
								<div class="flex items-center gap-1 bg-surface-container rounded-lg p-0.5">
									<button
										type="button"
										onclick={() => (currentPage = Math.max(1, currentPage - 1))}
										disabled={currentPage === 1}
										class="p-1 rounded hover:bg-surface-container-lowest disabled:opacity-30 disabled:pointer-events-none text-on-surface"
										title="Página Anterior"
									>
										<span class="material-symbols-outlined text-[18px]">chevron_left</span>
									</button>
									<span class="px-2 font-label-sm text-xs font-semibold text-on-surface">
										{currentPage} / {totalPages}
									</span>
									<button
										type="button"
										onclick={() => (currentPage = Math.min(totalPages, currentPage + 1))}
										disabled={currentPage === totalPages}
										class="p-1 rounded hover:bg-surface-container-lowest disabled:opacity-30 disabled:pointer-events-none text-on-surface"
										title="Próxima Página"
									>
										<span class="material-symbols-outlined text-[18px]">chevron_right</span>
									</button>
								</div>
							{/if}
						</div>
					</div>
				{/if}

				<!-- Quick Ledger Footer -->
				<div
					class="mt-4 pt-4 border-t border-surface-container flex flex-wrap items-center justify-between text-on-surface-variant font-body-sm text-body-sm gap-2"
				>
					<div class="flex items-center gap-2">
						<span class="material-symbols-outlined text-[16px] text-tertiary">info</span>
						<span>
							Valores auditados e indexados com a Árvore Estratégica do ciclo em andamento.
						</span>
					</div>
					<a
						class="font-label-md text-label-md text-primary hover:underline font-bold flex items-center gap-1"
						href="/strategy"
					>
						<span>Abrir visualização completa da matriz ({allMatrixRows.length} conexões)</span>
						<span class="material-symbols-outlined text-[16px]">chevron_right</span>
					</a>
				</div>
			</div>
		{:else}
			<div
				class="rounded-2xl border border-dashed border-outline-variant bg-surface-container-lowest p-10 text-center font-body-md text-on-surface-variant"
			>
				Nenhuma missão definida para esta era.
			</div>
		{/if}
	{/if}
</div>

<!-- Modal: Start New Strategic Era -->
{#if showNewEraModal}
	<div
		role="presentation"
		onclick={() => (showNewEraModal = false)}
		class="fixed inset-0 z-50 flex items-center justify-center bg-on-surface/35 p-4 backdrop-blur-xs"
	>
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			aria-labelledby="new-era-title"
			onclick={(e) => e.stopPropagation()}
			class="w-full max-w-lg rounded-2xl border border-outline-variant/40 bg-surface-container-lowest p-6 shadow-[0_20px_28px_-4px_rgba(36,34,30,0.16)]"
		>
			<div class="flex items-center justify-between border-b border-outline-variant/40 pb-3">
				<div>
					<h3 id="new-era-title" class="font-headline-sm text-headline-sm text-on-surface">
						Iniciar Nova Era Estratégica
					</h3>
					<p class="mt-0.5 font-body-sm text-body-sm text-on-surface-variant">
						Arquive o ciclo atual e formule a nova Missão e Valores Fundamentais.
					</p>
				</div>
				<button
					type="button"
					onclick={() => (showNewEraModal = false)}
					class="rounded-lg p-1.5 text-outline hover:bg-surface-container hover:text-on-surface"
				>
					<X class="h-4 w-4" />
				</button>
			</div>

			<form
				method="POST"
				action="?/archiveAndCreateEra"
				use:enhance={() => {
					return async ({ result, update }) => {
						if (result.type === 'success') {
							showNewEraModal = false;
						}
						await update({ reset: false });
					};
				}}
				use:enhanceFormValidation
				class="mt-4 space-y-4"
			>
				<div class="grid grid-cols-2 gap-3">
					<div>
						<label
							for="archive-year"
							class="block font-label-md text-label-md font-bold text-on-surface"
						>
							Arquivar Era Anterior no Ano <span class="text-error">*</span>
						</label>
						<input
							id="archive-year"
							name="archivePriorEndYear"
							type="number"
							required
							value="2026"
							class="mt-1 w-full rounded-lg bg-surface-container px-3 py-1.5 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
						/>
					</div>
					<div>
						<label
							for="new-start-year"
							class="block font-label-md text-label-md font-bold text-on-surface"
						>
							Ano Inicial da Nova Era <span class="text-error">*</span>
						</label>
						<input
							id="new-start-year"
							name="newStartYear"
							type="number"
							required
							value="2027"
							class="mt-1 w-full rounded-lg bg-surface-container px-3 py-1.5 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
						/>
					</div>
				</div>

				<div>
					<label
						for="new-era-mission"
						class="block font-label-md text-label-md font-bold text-on-surface"
					>
						Nova Declaração de Missão <span class="text-error">*</span>
					</label>
					<textarea
						id="new-era-mission"
						name="missionTitle"
						rows="2"
						required
						placeholder="Nova missão estratégica para o próximo ciclo plurianual..."
						aria-errormessage="new-mission-err"
						class="mt-1 w-full rounded-lg bg-surface-container px-3 py-2 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
					></textarea>
					<div id="new-mission-err" class="error-msg">
						<AlertCircle class="h-3.5 w-3.5" />
						<span>A nova declaração de missão é obrigatória.</span>
					</div>
				</div>

				<div>
					<label
						for="new-era-mdesc"
						class="block font-label-md text-label-md font-bold text-on-surface"
					>
						Propósito e Narrativa Estratégica
					</label>
					<textarea
						id="new-era-mdesc"
						name="missionDescription"
						rows="2"
						placeholder="Contexto, visão e direcionadores para esta renovação estratégica..."
						class="mt-1 w-full rounded-lg bg-surface-container px-3 py-2 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
					></textarea>
				</div>

				<div class="border-t border-outline-variant/40 pt-3">
					<div class="font-label-md text-label-md font-bold text-on-surface">
						Valores Fundamentais Iniciais (Opcional)
					</div>
					<div class="mt-2 space-y-2">
						{#each [1, 2] as i}
							<div class="flex gap-2">
								<input
									name="valueTitles"
									type="text"
									placeholder="Título do Valor #{i}..."
									class="w-1/2 rounded-lg bg-surface-container px-2.5 py-1.5 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
								/>
								<input
									name="valueDescriptions"
									type="text"
									placeholder="Definição / comportamento..."
									class="w-1/2 rounded-lg bg-surface-container px-2.5 py-1.5 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
								/>
							</div>
						{/each}
					</div>
				</div>

				<div class="flex justify-end gap-2 border-t border-outline-variant/40 pt-4">
					<button
						type="button"
						onclick={() => (showNewEraModal = false)}
						class="rounded-lg bg-surface-container px-4 py-2 font-label-md text-label-md text-on-surface-variant"
					>
						Cancelar
					</button>
					<button
						type="submit"
						class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-4 py-2 font-label-md text-label-md font-bold text-on-primary shadow-[0_2px_0_#004494]"
					>
						Criar Nova Era
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}

<!-- Modal Dossiê de Edição e Criação de Valores Fundamentais -->
{#if activeValueModal && selectedEra}
	{@const modalVal = activeValueModal.value}
	{@const modalStats = modalVal ? getValueStats(modalVal.id) : { total: 0, okrs: 0, krs: 0, kpis: 0, avgPct: 0 }}
	{@const linkedNodes = modalVal
		? strategyNodes.filter((n) => {
				const linkedIds = new Set(
					nodeValues.filter((nv) => nv.value_id === modalVal.id).map((nv) => nv.node_id)
				);
				return linkedIds.has(n.id);
		  })
		: []}
	<ValueDossierModal
		mode={activeValueModal.mode}
		valueNode={modalVal}
		era={selectedEra}
		stats={modalStats}
		alignedNodes={linkedNodes}
		{canEdit}
		onClose={() => (activeValueModal = null)}
	/>
{/if}
