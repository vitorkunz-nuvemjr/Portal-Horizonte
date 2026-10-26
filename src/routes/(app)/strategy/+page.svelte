<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { enhance } from '$app/forms';
	import { onMount } from 'svelte';
	import CycleFilterBar from '$lib/components/filter/CycleFilterBar.svelte';
	import CascadeTreeBoard from '$lib/components/canvas/CascadeTreeBoard.svelte';
	import StrategyCanvas from '$lib/components/canvas/StrategyCanvas.svelte';
	import OutlineView from '$lib/components/canvas/OutlineView.svelte';
	import NodeDrawer from '$lib/components/drawer/NodeDrawer.svelte';
	import ObjectiveDossierModal from '$lib/components/modal/ObjectiveDossierModal.svelte';
	import KeyResultDossierModal from '$lib/components/modal/KeyResultDossierModal.svelte';
	import KpiDossierModal from '$lib/components/modal/KpiDossierModal.svelte';
	import PaperColorPicker from '$lib/components/ui/PaperColorPicker.svelte';
	import { getDossierTheme } from '$lib/dossier-theme';
	import {
		applyValueLens,
		enrichNodes,
		filterStrategyNodes,
		filterVisible,
		getActiveMissionForYear,
		getActiveValuesForYears
	} from '$lib/progress';
	import { enhanceFormValidation } from '$lib/utils';
	import type { NodeType, NodeWithExtras } from '$lib/types';
	import { AlertCircle, Plus, X } from 'lucide-svelte';

	let { data, form } = $props();

	let searchQuery = $state('');
	let selectedNodeId = $state<string | null>(null);

	// Modal state for creating a new node (Objective, KR, or KPI)
	let createModal = $state<{
		open: boolean;
		type: NodeType;
		parent: NodeWithExtras | null;
		selectedParentId: string;
		color: string;
	}>({
		open: false,
		type: 'objective',
		parent: null,
		selectedParentId: '',
		color: '#0058bd'
	});

	const createModalTheme = $derived(getDossierTheme(createModal.color));

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

	const availableYears = $derived.by(() => {
		const yrs = new Set<number>([2024, 2025, 2026, 2027]);
		for (const c of data.cycles) yrs.add(c.year);
		for (const n of data.nodes) {
			if (n.year) yrs.add(n.year);
			if (n.start_year) yrs.add(n.start_year);
		}
		return Array.from(yrs).sort();
	});

	// Read filter & lens state from URL searchParams
	const selectedYears = $derived.by(() => {
		const raw = $page.url.searchParams.get('years');
		if (!raw) return [2026];
		return raw
			.split(',')
			.map(Number)
			.filter((n) => !Number.isNaN(n));
	});

	const selectedSemesters = $derived.by(() => {
		const raw = $page.url.searchParams.get('semesters');
		if (!raw) return [1, 2];
		return raw
			.split(',')
			.map(Number)
			.filter((n) => n === 1 || n === 2);
	});

	const strictMode = $derived($page.url.searchParams.get('strict') === '1');
	const activeLensId = $derived($page.url.searchParams.get('lens'));
	const rawViewParam = $derived($page.url.searchParams.get('view'));
	const viewMode = $derived<'tree' | 'outline' | 'canvas'>(
		rawViewParam === 'outline' ? 'outline' : rawViewParam === 'canvas' ? 'canvas' : 'tree'
	);

	// Team and User filters from URL searchParams
	const selectedTeamId = $derived($page.url.searchParams.get('team') || 'all');
	const selectedUserId = $derived($page.url.searchParams.get('user') || 'all');

	// Restore user preferences from localStorage on direct visit without query params
	onMount(() => {
		if (typeof window === 'undefined') return;
		try {
			const raw = localStorage.getItem('plano_strategy_filters');
			if (!raw) return;
			const prefs = JSON.parse(raw);
			if (!prefs || typeof prefs !== 'object') return;

			let shouldUpdate = false;
			const url = new URL($page.url);
			for (const key of ['view', 'years', 'semesters', 'strict', 'team', 'user']) {
				if (!url.searchParams.has(key) && prefs[key]) {
					url.searchParams.set(key, prefs[key]);
					shouldUpdate = true;
				}
			}
			if (shouldUpdate) {
				goto(url.toString(), { replaceState: true, noScroll: true, keepFocus: true });
			}
		} catch (e) {
			// ignore storage errors
		}
	});

	// Sync global header search param (?q=...), direct node selection (?select=...), and quick create (?create=...)
	$effect(() => {
		const urlQ = $page.url.searchParams.get('q') ?? '';
		if (urlQ !== searchQuery) {
			searchQuery = urlQ;
		}
		const selectParam = $page.url.searchParams.get('select');
		if (selectParam && enriched.byId.has(selectParam)) {
			const cleanUrl = new URL($page.url);
			cleanUrl.searchParams.delete('select');
			goto(cleanUrl.toString(), { replaceState: true, noScroll: true });
			selectedNodeId = selectParam;
		}
		const createAction = $page.url.searchParams.get('create');
		if (createAction === 'objective' || createAction === 'kr') {
			const cleanUrl = new URL($page.url);
			cleanUrl.searchParams.delete('create');
			goto(cleanUrl.toString(), { replaceState: true, noScroll: true });
			if (createAction === 'objective') {
				openCreateObjective();
			} else {
				openCreateQuickKR();
			}
		}
	});

	// Resolve the Mission active for the primary filtered year
	const activeYear = $derived(selectedYears[0] ?? 2026);
	const activeCycleCode = $derived(`${activeYear}-S${selectedSemesters[0] ?? 1}`);
	const activeMission = $derived(getActiveMissionForYear(enriched.identityRoots, activeYear));
	const activeEraValues = $derived(getActiveValuesForYears(enriched.valuesList, selectedYears));

	// Visible node IDs from cycle filter + team filter + user filter + search query
	const visibleIds = $derived.by(() => {
		const baseVisible = filterVisible(data.nodes, data.cycles, {
			years: selectedYears,
			semesters: selectedSemesters,
			strict: strictMode,
			includePermanent: false
		});

		return filterStrategyNodes(enriched, baseVisible, {
			searchQuery,
			teamId: selectedTeamId,
			userId: selectedUserId
		});
	});

	const visibleStrategyNodes = $derived(
		Array.from(enriched.byId.values()).filter(
			(n) => n.tree === 'strategy' && visibleIds.has(n.id)
		)
	);

	const allObjectives = $derived(
		Array.from(enriched.byId.values()).filter((n) => n.type === 'objective')
	);
	const allKRs = $derived(
		Array.from(enriched.byId.values()).filter((n) => n.type === 'key_result')
	);

	const lens = $derived(applyValueLens(data.nodes, data.values, activeLensId));

	const selectedNode = $derived(
		selectedNodeId ? (enriched.byId.get(selectedNodeId) ?? null) : null
	);

	let collapsedIds = $state<Set<string>>(new Set());

	function toggleCollapse(id: string) {
		const next = new Set(collapsedIds);
		if (next.has(id)) {
			next.delete(id);
		} else {
			next.add(id);
		}
		collapsedIds = next;
	}

	function collapseAll() {
		const next = new Set<string>();
		for (const n of visibleStrategyNodes) {
			if (n.children.some((c) => visibleIds.has(c.id))) {
				next.add(n.id);
			}
		}
		collapsedIds = next;
	}

	function expandAll() {
		collapsedIds = new Set();
	}

	function openCreateObjective() {
		createModal = {
			open: true,
			type: 'objective',
			parent: null,
			selectedParentId: '',
			color: '#0058bd'
		};
	}

	function openCreateQuickKR() {
		const defaultObj =
			enriched.strategyRoots.find((r) => visibleIds.has(r.id)) ??
			enriched.strategyRoots[0] ??
			null;
		createModal = {
			open: true,
			type: 'key_result',
			parent: defaultObj,
			selectedParentId: defaultObj?.id ?? '',
			color: defaultObj?.color || '#b30069'
		};
	}

	function openCreateQuickKPI() {
		const defaultKR =
			allKRs.find((k) => visibleIds.has(k.id)) ??
			allKRs[0] ??
			enriched.strategyRoots[0] ??
			null;
		createModal = {
			open: true,
			type: 'kpi',
			parent: defaultKR,
			selectedParentId: defaultKR?.id ?? '',
			color: defaultKR?.color || '#00665a'
		};
	}

	function openCreateChild(parent: NodeWithExtras) {
		if (collapsedIds.has(parent.id)) {
			const next = new Set(collapsedIds);
			next.delete(parent.id);
			collapsedIds = next;
		}
		createModal = {
			open: true,
			type: parent.type === 'objective' ? 'key_result' : 'kpi',
			parent,
			selectedParentId: parent.id,
			color: parent.color || (parent.type === 'objective' ? '#b30069' : '#00665a')
		};
	}
</script>

<div class="flex flex-col w-full p-3.5 sm:p-gutter">
	<CycleFilterBar
		cycles={data.cycles}
		valuesList={activeEraValues.length > 0 ? activeEraValues : enriched.valuesList}
		teams={data.teams}
		profiles={data.profiles}
		{activeMission}
		{availableYears}
		{selectedYears}
		{selectedSemesters}
		{selectedTeamId}
		{selectedUserId}
		{strictMode}
		{activeLensId}
		{viewMode}
		{searchQuery}
		{canEdit}
		onSearchChange={(q) => (searchQuery = q)}
		onSelectNode={(id) => (selectedNodeId = id)}
		onCreateObjective={openCreateObjective}
		onCreateKR={openCreateQuickKR}
		onCreateKPI={openCreateQuickKPI}
	/>

	{#if form?.message}
		<div
			class="mb-space-md flex items-center justify-between rounded-xl bg-error-container px-4 py-3 text-xs font-semibold text-on-error-container shadow-sm"
		>
			<span class="flex items-center gap-2">
				<AlertCircle class="h-4 w-4" />
				{form.message}
			</span>
		</div>
	{/if}

	<!-- Main Workspace: 3-Column Cascade Board (Árvore), Outline Ledger (Lista), or 2D Graph (Canvas) -->
	{#if viewMode === 'tree'}
		<CascadeTreeBoard
			roots={enriched.strategyRoots}
			{visibleIds}
			highlightedIds={lens.highlighted}
			dimmedIds={lens.dimmed}
			{selectedNodeId}
			{activeYear}
			{activeCycleCode}
			{canEdit}
			onSelectNode={(id) => (selectedNodeId = id)}
			onAddChild={openCreateChild}
			onCreateObjective={openCreateObjective}
		/>
	{:else if viewMode === 'outline'}
		<div
			class="relative w-full rounded-2xl bg-surface-container-low p-2.5 sm:p-space-md shadow-[inset_0_2px_6px_rgba(36,34,30,0.05),0_1px_0_#ffffff] min-h-[560px] sm:min-h-[700px]"
		>
			<OutlineView
				roots={enriched.strategyRoots}
				{activeMission}
				{visibleIds}
				highlightedIds={lens.highlighted}
				dimmedIds={lens.dimmed}
				{selectedNodeId}
				{collapsedIds}
				{canEdit}
				onSelectNode={(id) => (selectedNodeId = id)}
				onAddChild={openCreateChild}
				onToggleCollapse={toggleCollapse}
				onCollapseAll={collapseAll}
				onExpandAll={expandAll}
			/>
		</div>
	{:else}
		<div
			class="relative w-full h-[68dvh] min-h-[460px] sm:h-[740px] rounded-2xl overflow-hidden bg-surface-container-low shadow-[inset_0_2px_6px_rgba(36,34,30,0.05),0_1px_0_#ffffff]"
		>
			<StrategyCanvas
				visibleNodes={visibleStrategyNodes}
				{activeMission}
				highlightedIds={lens.highlighted}
				dimmedIds={lens.dimmed}
				{selectedNodeId}
				{collapsedIds}
				{canEdit}
				onSelectNode={(id) => (selectedNodeId = id)}
				onAddChild={openCreateChild}
				onToggleCollapse={toggleCollapse}
				onCollapseAll={collapseAll}
				onExpandAll={expandAll}
			/>
		</div>
	{/if}
</div>

<!-- Node Edit: Dossier Modals for Objectives, Key Results, and KPIs; Drawer for Identity nodes (Mission, Value) -->
{#if selectedNode?.type === 'objective'}
	<ObjectiveDossierModal
		node={selectedNode}
		allNodes={data.nodes}
		cycles={data.cycles}
		profiles={enriched.profilesWithTeams}
		teams={data.teams}
		valuesList={enriched.valuesList}
		{canEdit}
		onClose={() => (selectedNodeId = null)}
		onAddChild={openCreateChild}
		onOpenNode={(id: string) => (selectedNodeId = id)}
	/>
{:else if selectedNode?.type === 'key_result'}
	<KeyResultDossierModal
		node={selectedNode}
		allNodes={data.nodes}
		cycles={data.cycles}
		profiles={enriched.profilesWithTeams}
		teams={data.teams}
		valuesList={enriched.valuesList}
		{canEdit}
		onClose={() => (selectedNodeId = null)}
		onAddChild={openCreateChild}
		onOpenNode={(id: string) => (selectedNodeId = id)}
	/>
{:else if selectedNode?.type === 'kpi'}
	<KpiDossierModal
		node={selectedNode}
		allNodes={data.nodes}
		cycles={data.cycles}
		profiles={enriched.profilesWithTeams}
		teams={data.teams}
		{canEdit}
		onClose={() => (selectedNodeId = null)}
		onOpenParent={(id: string) => (selectedNodeId = id)}
	/>
{:else if selectedNode}
	<NodeDrawer
		node={selectedNode}
		allNodes={data.nodes}
		cycles={data.cycles}
		profiles={enriched.profilesWithTeams}
		teams={data.teams}
		valuesList={enriched.valuesList}
		{canEdit}
		{collapsedIds}
		onClose={() => (selectedNodeId = null)}
		onAddChild={openCreateChild}
		onToggleCollapse={toggleCollapse}
	/>
{/if}

<!-- Create Node Modal (Objective / KR / KPI): Hanging-Folder Dossier -->
{#if createModal.open}
	<div
		role="presentation"
		onclick={() => (createModal.open = false)}
		class="fixed inset-0 z-[150] flex items-center justify-center bg-[#181613]/60 backdrop-blur-[5px] p-2.5 sm:p-6 overflow-y-auto overscroll-contain"
	>
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			aria-labelledby="create-modal-title"
			onclick={(e) => e.stopPropagation()}
			class="relative w-full max-w-xl rounded-2xl pt-2 pb-0 flex flex-col border-2 hanging-folder-shadow transition-colors duration-200 overflow-hidden"
			style="background-color: {createModalTheme.folderBg}; border-color: {createModalTheme.folderBorder};"
		>
			<!-- Top Protruding Tab & Action Strip -->
			<div class="px-4 sm:px-6 pt-3 pb-2 flex items-center justify-between gap-3 border-b border-black/5">
				<!-- Protruding Tab Look -->
				<div
					class="inline-flex items-center gap-2 px-3 sm:px-4 py-1.5 rounded-t-xl border-t border-x -mb-2 shadow-xs min-w-0"
					style="background-color: {createModalTheme.cardBg}; border-color: {createModalTheme.folderBorder};"
				>
					<span
						class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider shrink-0"
						style="background-color: {createModalTheme.badgeBg}; border: 1px solid {createModalTheme.badgeBorder}; color: {createModalTheme.badgeText};"
					>
						{createModal.type === 'objective'
							? 'NOVO OBJETIVO'
							: createModal.type === 'key_result'
								? 'NOVO RESULTADO-CHAVE'
								: 'NOVO INDICADOR KPI'}
					</span>
					{#if createModal.parent}
						<span class="font-label-sm text-xs text-on-surface-variant truncate max-w-[140px] sm:max-w-[200px]">
							{createModal.parent.title}
						</span>
					{/if}
				</div>

				<!-- Right Controls: Color Picker + Close Button -->
				<div class="flex items-center gap-1.5 relative z-40 shrink-0">
					<PaperColorPicker bind:value={createModal.color} align="right" />
					<button
						type="button"
						onclick={() => (createModal.open = false)}
						class="w-8 h-8 rounded-full flex items-center justify-center transition-all bg-black/5 hover:bg-black/10 text-on-surface-variant hover:text-on-surface cursor-pointer"
						title="Fechar"
					>
						<X class="h-4 w-4" />
					</button>
				</div>
			</div>

			<!-- Structural Reinforcement Bar -->
			<div
				class="h-[3px] w-full"
				style="background: linear-gradient(90deg, {createModalTheme.accent} 0%, {createModalTheme.folderBorder} 100%);"
			></div>

			<!-- Modal Body (Inner Cardstock) -->
			<div class="p-4 sm:p-6 overflow-y-auto max-h-[calc(85dvh-130px)]">
				<form
					method="POST"
					action="?/createNode"
					use:enhance={() => {
						return async ({ result, update }) => {
							if (result.type === 'success') {
								createModal.open = false;
								if (result.data && typeof result.data === 'object' && 'createdId' in result.data) {
									selectedNodeId = String((result.data as { createdId?: string }).createdId);
								}
							}
							await update({ reset: false });
						};
					}}
					use:enhanceFormValidation
					class="space-y-4"
				>
					<input type="hidden" name="color" value={createModal.color} />
					{#if createModal.type === 'objective'}
						<input type="hidden" name="parentId" value="" />
						<input type="hidden" name="type" value="objective" />
					{:else}
						<div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
							<div>
								<label
									for="create-type"
									class="block font-label-md text-label-md font-bold text-on-surface"
								>
									Tipo do Item
								</label>
								<select
									id="create-type"
									name="type"
									bind:value={createModal.type}
									class="mt-1 w-full rounded-lg bg-surface-container px-3 py-2 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:outline-none focus:ring-1 focus:ring-primary"
								>
									<option value="key_result">Key Result (Escopo Semestral)</option>
									<option value="kpi">Indicador KPI</option>
								</select>
							</div>

							<div>
								<label
									for="create-parent"
									class="block font-label-md text-label-md font-bold text-on-surface"
								>
									Vincular a <span class="text-error">*</span>
								</label>
								<select
									id="create-parent"
									name="parentId"
									required
									bind:value={createModal.selectedParentId}
									class="mt-1 w-full rounded-lg bg-surface-container px-3 py-2 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:outline-none focus:ring-1 focus:ring-primary"
								>
									{#if createModal.type === 'key_result'}
										{#each allObjectives as obj (obj.id)}
											<option value={obj.id}>[OBJ] {obj.title}</option>
										{/each}
									{:else}
										{#each allKRs as kr (kr.id)}
											<option value={kr.id}>[KR] {kr.title}</option>
										{/each}
										{#each allObjectives as obj (obj.id)}
											<option value={obj.id}>[OBJ] {obj.title}</option>
										{/each}
									{/if}
								</select>
							</div>
						</div>
					{/if}

					<div>
						<label
							for="create-title"
							class="block font-label-md text-label-md font-bold text-on-surface"
						>
							Título <span class="text-error">*</span>
						</label>
						<input
							id="create-title"
							name="title"
							type="text"
							required
							placeholder={createModal.type === 'objective'
								? 'Ex.: Consolidar Liderança de Mercado em Soluções Cloud'
								: createModal.type === 'key_result'
									? 'Ex.: Atingir R$ 4.2M em ARR até o fim do semestre'
									: 'Ex.: MRR Novo Contratado'}
							aria-errormessage="create-title-err"
							class="mt-1 w-full rounded-lg bg-surface-container px-3 py-2 font-body-md text-body-md text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:outline-none focus:ring-1 focus:ring-primary"
						/>
						<div id="create-title-err" class="error-msg">
							<AlertCircle class="h-3.5 w-3.5" />
							<span>O título é obrigatório.</span>
						</div>
					</div>

					<div>
						<label
							for="create-desc"
							class="block font-label-md text-label-md font-bold text-on-surface"
						>
							Descrição
						</label>
						<textarea
							id="create-desc"
							name="description"
							rows="2"
							placeholder="Contexto estratégico opcional ou critérios de aceitação..."
							class="mt-1 w-full rounded-lg bg-surface-container px-3 py-2 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:outline-none focus:ring-1 focus:ring-primary"
						></textarea>
					</div>

					{#if createModal.type === 'objective'}
						<div class="grid grid-cols-2 gap-3">
							<div>
								<label
									for="create-year"
									class="block font-label-md text-label-md font-bold text-on-surface"
								>
									Ano <span class="text-error">*</span>
								</label>
								<input
									id="create-year"
									name="year"
									type="number"
									required
									value={selectedYears[0] ?? 2026}
									aria-errormessage="create-year-err"
									class="mt-1 w-full rounded-lg bg-surface-container px-3 py-1.5 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
								/>
								<div id="create-year-err" class="error-msg">
									<AlertCircle class="h-3 w-3" />
									<span>O ano é obrigatório.</span>
								</div>
							</div>
							<div>
								<label
									for="create-quarter"
									class="block font-label-md text-label-md font-bold text-on-surface"
								>
									Trimestre (Opcional)
								</label>
								<select
									id="create-quarter"
									name="quarter"
									class="mt-1 w-full rounded-lg bg-surface-container px-3 py-1.5 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
								>
									<option value="">Ano Inteiro</option>
									<option value="1">T1</option>
									<option value="2">T2</option>
									<option value="3">T3</option>
									<option value="4">T4</option>
								</select>
							</div>
						</div>
					{:else}
						<div>
							<label
								for="create-cycle"
								class="block font-label-md text-label-md font-bold text-on-surface"
							>
								Ciclo Semestral
							</label>
							<select
								id="create-cycle"
								name="cycle_id"
								class="mt-1 w-full rounded-lg bg-surface-container px-3 py-1.5 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
							>
								{#each data.cycles as cyc (cyc.id)}
									<option
										value={cyc.id}
										selected={cyc.id === (createModal.parent?.cycle_id ?? 'cyc-2026-s1')}
									>
										{cyc.code} ({cyc.start_date} → {cyc.end_date})
									</option>
								{/each}
							</select>
						</div>
					{/if}

					{#if createModal.type === 'kpi'}
						<div class="grid grid-cols-2 sm:grid-cols-4 gap-2.5 border-t border-outline-variant/40 pt-3">
							<div>
								<label
									for="new-kpi-unit"
									class="block font-label-sm text-label-sm uppercase text-on-surface-variant"
								>
									Unidade
								</label>
								<input
									id="new-kpi-unit"
									name="unit"
									type="text"
									placeholder="R$, %, pts"
									class="mt-1 w-full rounded-lg bg-surface-container px-2 py-1.5 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
								/>
							</div>
							<div>
								<label
									for="new-kpi-base"
									class="block font-label-sm text-label-sm uppercase text-on-surface-variant"
								>
									Base
								</label>
								<input
									id="new-kpi-base"
									name="baseline"
									type="number"
									step="any"
									value="0"
									class="mt-1 w-full rounded-lg bg-surface-container px-2 py-1.5 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
								/>
							</div>
							<div>
								<label
									for="new-kpi-target"
									class="block font-label-sm text-label-sm uppercase text-on-surface-variant"
								>
									Meta
								</label>
								<input
									id="new-kpi-target"
									name="target_value"
									type="number"
									step="any"
									value="100"
									class="mt-1 w-full rounded-lg bg-surface-container px-2 py-1.5 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
								/>
							</div>
							<div>
								<label
									for="new-kpi-dir"
									class="block font-label-sm text-label-sm uppercase text-on-surface-variant"
								>
									Direção
								</label>
								<select
									id="new-kpi-dir"
									name="direction"
									class="mt-1 w-full rounded-lg bg-surface-container px-2 py-1.5 font-body-sm text-body-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
								>
									<option value="up">Crescente (↑)</option>
									<option value="down">Decrescente (↓)</option>
								</select>
							</div>
						</div>
					{/if}

					<!-- Stitched Perforation Footer Inside Form -->
					<div
						class="pt-3 border-t mt-4 -mx-4 sm:-mx-6 px-4 sm:px-6 flex items-center justify-end gap-2"
						style="border-color: {createModalTheme.folderBorder}; background-color: {createModalTheme.footerBg};"
					>
						<button
							type="button"
							onclick={() => (createModal.open = false)}
							class="rounded-lg bg-surface-container px-4 py-2 font-label-md text-label-md text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface cursor-pointer"
						>
							Cancelar
						</button>
						<button
							type="submit"
							class="inline-flex items-center gap-1.5 rounded-lg px-4 py-2 font-label-md text-label-md font-bold text-white active:translate-y-px cursor-pointer"
							style="background-color: {createModalTheme.accent}; box-shadow: 0 2px 0 {createModalTheme.accentShadow};"
						>
							<Plus class="h-3.5 w-3.5" />
							Criar Item
						</button>
					</div>
				</form>
			</div>
		</div>
	</div>
{/if}
