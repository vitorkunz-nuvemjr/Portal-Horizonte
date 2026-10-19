<script lang="ts">
	import type { Cycle, NodeWithExtras, Profile, StrategyNode, Team } from '$lib/types';
	import { enhanceFormValidation, formatNumber, formatPct, getInitials } from '$lib/utils';
	import { valueColor } from '$lib/value-colors';
	import {
		X,
		Trash2,
		ArrowUpRight,
		Sparkles,
		Users,
		LineChart,
		AlertCircle,
		CheckCircle2,
		Plus,
		ChevronDown,
		ChevronRight
	} from 'lucide-svelte';

	interface Props {
		node: NodeWithExtras | null;
		allNodes: StrategyNode[];
		cycles: Cycle[];
		profiles: Profile[];
		teams: Team[];
		valuesList: StrategyNode[];
		canEdit: boolean;
		collapsedIds?: Set<string>;
		onClose: () => void;
		onAddChild: (parent: NodeWithExtras) => void;
		onToggleCollapse?: (id: string) => void;
	}

	let {
		node,
		allNodes,
		cycles,
		profiles,
		teams,
		valuesList,
		canEdit,
		collapsedIds = new Set(),
		onClose,
		onAddChild,
		onToggleCollapse
	}: Props = $props();

	const typeLabels: Record<string, string> = {
		objective: 'Objetivo',
		key_result: 'Resultado-Chave',
		kpi: 'KPI',
		mission: 'Missão',
		value: 'Valor'
	};

	const typeBadgeClasses: Record<string, string> = {
		objective: 'bg-primary text-on-primary border-primary',
		key_result: 'bg-secondary-fixed text-on-secondary-fixed border-outline-variant',
		kpi: 'bg-tertiary-fixed text-on-tertiary-fixed border-outline-variant',
		mission: 'bg-surface-container-highest text-on-surface border-outline-variant',
		value: 'bg-primary-fixed text-on-primary-fixed border-outline-variant'
	};

	// Possible valid parents for reparenting
	const validParents = $derived.by(() => {
		if (!node) return [];
		if (node.type === 'objective' || node.type === 'mission') return [];
		// Prevent descendant cycles
		const descendants = new Set<string>([node.id]);
		let added = true;
		while (added) {
			added = false;
			for (const n of allNodes) {
				if (n.parent_id && descendants.has(n.parent_id) && !descendants.has(n.id)) {
					descendants.add(n.id);
					added = true;
				}
			}
		}

		return allNodes.filter((candidate) => {
			if (descendants.has(candidate.id)) return false;
			if (node.type === 'key_result') return candidate.type === 'objective';
			if (node.type === 'kpi')
				return candidate.type === 'key_result' || candidate.type === 'objective';
			if (node.type === 'value') return candidate.type === 'mission';
			return false;
		});
	});

	// Can children be promoted to node.parent_id if node is deleted?
	const canPromoteChildren = $derived.by(() => {
		if (!node || node.children.length === 0) return false;
		// Only KRs with KPI children under an Objective can promote their KPIs to that Objective
		if (node.type === 'key_result' && node.parent_id) {
			return node.children.every((c) => c.type === 'kpi');
		}
		return false;
	});

	// Build SVG sparkline points for KPI metric history
	const sparklinePoints = $derived.by(() => {
		if (!node || node.type !== 'kpi') return null;
		const chron = [...node.metricUpdates].reverse();
		if (chron.length === 0) return null;
		const vals = chron.map((m) => m.value);
		if (node.baseline != null) vals.unshift(node.baseline);
		if (vals.length < 2) return null;

		const min = Math.min(...vals, node.target_value ?? vals[0]);
		const max = Math.max(...vals, node.target_value ?? vals[0]);
		const range = max - min || 1;
		const W = 320;
		const H = 80;
		const pad = 10;

		const coords = vals.map((v, idx) => {
			const x = pad + (idx / (vals.length - 1)) * (W - pad * 2);
			const y = H - pad - ((v - min) / range) * (H - pad * 2);
			return { x, y, v };
		});

		const targetY =
			node.target_value != null
				? H - pad - ((node.target_value - min) / range) * (H - pad * 2)
				: null;

		return {
			polyline: coords.map((c) => `${c.x},${c.y}`).join(' '),
			coords,
			targetY,
			W,
			H
		};
	});
</script>

{#if node}
	<!-- Backdrop -->
	<div
		role="presentation"
		onclick={onClose}
		class="fixed inset-0 z-40 bg-on-surface/30 backdrop-blur-[2px] transition-opacity"
	></div>

	<!-- Slide-over Panel -->
	<aside
		aria-label="Editar detalhes do nó"
		class="fixed top-0 right-0 z-50 flex h-full w-full max-w-xl flex-col border-l border-outline-variant bg-surface-container-lowest shadow-[0_8px_32px_rgba(36,34,30,0.16)]"
	>
		<!-- Drawer Header -->
		<div class="flex items-center justify-between border-b border-outline-variant bg-surface-container-low px-6 py-4">
			<div class="flex items-center gap-2.5">
				<span
					class="rounded-[2px] border px-2.5 py-0.5 text-[10px] font-bold tracking-widest uppercase {typeBadgeClasses[
						node.type
					] ?? 'bg-on-surface text-surface'}"
				>
					{typeLabels[node.type] ?? node.type}
				</span>
				<span class="text-xs font-medium text-on-surface-variant">
					Progresso: <strong class="font-bold text-on-surface">{formatPct(node.progress)}</strong>
				</span>
			</div>

			<div class="flex items-center gap-2">
				{#if node.children.length > 0 && onToggleCollapse}
					{@const isCollapsed = collapsedIds.has(node.id)}
					<button
						type="button"
						onclick={() => onToggleCollapse(node.id)}
						class="inline-flex items-center gap-1 rounded-[4px] border px-2.5 py-1 text-xs font-bold transition {isCollapsed
							? 'border-on-surface bg-on-surface text-surface hover:opacity-90'
							: 'border-outline-variant bg-surface-container-lowest text-on-surface-variant hover:border-outline hover:text-on-surface'}"
					>
						{#if isCollapsed}
							<ChevronRight class="h-3.5 w-3.5" />
							Mostrar Filhos ({node.children.length})
						{:else}
							<ChevronDown class="h-3.5 w-3.5" />
							Ocultar Filhos ({node.children.length})
						{/if}
					</button>
				{/if}
				{#if canEdit && (node.type === 'objective' || node.type === 'key_result')}
					<button
						type="button"
						onclick={() => onAddChild(node)}
						class="inline-flex items-center gap-1 rounded-[4px] border border-outline-variant bg-surface-container-lowest px-2.5 py-1 text-xs font-bold text-on-surface shadow-[0_2px_0_#D8D2C2] transition-all hover:bg-primary hover:text-on-primary hover:border-primary"
					>
						<Plus class="h-3.5 w-3.5" />
						Adicionar {node.type === 'objective' ? 'Resultado-Chave' : 'KPI'}
					</button>
				{/if}
				<button
					type="button"
					onclick={onClose}
					class="rounded-[4px] p-1.5 text-on-surface-variant hover:bg-surface-container hover:text-on-surface"
				>
					<X class="h-5 w-5" />
				</button>
			</div>
		</div>

		<!-- Scrollable Drawer Body -->
		<div class="flex-1 space-y-6 overflow-y-auto px-6 py-5">
			<!-- 1. Core Node Details Form -->
			<form
				method="POST"
				action="/strategy?/updateNode"
				use:enhanceFormValidation
				class="space-y-4 rounded-[6px] border border-outline-variant bg-surface-container-low/60 p-4 shadow-[0_2px_6px_rgba(36,34,30,0.04)]"
			>
				<input type="hidden" name="nodeId" value={node.id} />

				<div>
					<label for="drawer-title" class="block text-label-sm font-bold text-on-surface-variant uppercase tracking-wider">
						Título <span class="text-error">*</span>
					</label>
					<input
						id="drawer-title"
						name="title"
						type="text"
						required
						disabled={!canEdit}
						value={node.title}
						aria-errormessage="drawer-title-error"
						class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-3 py-2 text-sm font-semibold text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:border-primary focus:bg-surface-container-lowest focus:outline-none disabled:opacity-60"
					/>
					<div id="drawer-title-error" class="error-msg">
						<AlertCircle class="h-3.5 w-3.5 shrink-0" />
						<span>O título do nó é obrigatório.</span>
					</div>
				</div>

				<div>
					<label for="drawer-desc" class="block text-label-sm font-bold text-on-surface-variant uppercase tracking-wider">
						Descrição e Contexto Estratégico
					</label>
					<textarea
						id="drawer-desc"
						name="description"
						rows="2"
						disabled={!canEdit}
						class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-3 py-2 text-xs text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:border-primary focus:bg-surface-container-lowest focus:outline-none disabled:opacity-60"
						>{node.description ?? ''}</textarea
					>
				</div>

				<!-- Status, Weight, and Scope -->
				<div class="grid grid-cols-3 gap-3">
					<div>
						<label for="drawer-status" class="block text-label-sm font-bold text-on-surface-variant uppercase tracking-wider">
							Status
						</label>
						<select
							id="drawer-status"
							name="status"
							disabled={!canEdit}
							class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2.5 py-1.5 text-xs font-medium text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:border-primary focus:bg-surface-container-lowest focus:outline-none"
						>
							<option value="not_started" selected={node.status === 'not_started'}
								>Não Iniciado</option
							>
							<option value="on_track" selected={node.status === 'on_track'}>No Prazo</option>
							<option value="at_risk" selected={node.status === 'at_risk'}>Em Risco</option>
							<option value="off_track" selected={node.status === 'off_track'}>Atrasado</option>
							<option value="done" selected={node.status === 'done'}>Concluído</option>
						</select>
					</div>

					<div>
						<label for="drawer-weight" class="block text-label-sm font-bold text-on-surface-variant uppercase tracking-wider">
							Peso
						</label>
						<input
							id="drawer-weight"
							name="weight"
							type="number"
							step="0.1"
							min="0.1"
							disabled={!canEdit}
							value={node.weight}
							class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2.5 py-1.5 text-xs font-medium text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:border-primary focus:bg-surface-container-lowest focus:outline-none"
						/>
					</div>

					{#if node.type === 'objective'}
						<div>
							<label for="drawer-year" class="block text-label-sm font-bold text-on-surface-variant uppercase tracking-wider">
								Ano <span class="text-error">*</span>
							</label>
							<input
								id="drawer-year"
								name="year"
								type="number"
								required
								disabled={!canEdit}
								value={node.year ?? 2026}
								aria-errormessage="drawer-year-err"
								class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2.5 py-1.5 text-xs font-medium text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:border-primary focus:bg-surface-container-lowest focus:outline-none"
							/>
							<div id="drawer-year-err" class="error-msg">
								<AlertCircle class="h-3 w-3" />
								<span>Ano obrigatório</span>
							</div>
						</div>
					{:else if node.type === 'key_result' || node.type === 'kpi'}
						<div>
							<label for="drawer-cycle" class="block text-label-sm font-bold text-on-surface-variant uppercase tracking-wider">
								Ciclo Semestral
							</label>
							<select
								id="drawer-cycle"
								name="cycle_id"
								disabled={!canEdit}
								class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2.5 py-1.5 text-xs font-medium text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:border-primary focus:bg-surface-container-lowest focus:outline-none"
							>
								<option value="">Herdar / Nenhum</option>
								{#each cycles as cyc (cyc.id)}
									<option value={cyc.id} selected={node.cycle_id === cyc.id}>{cyc.code}</option>
								{/each}
							</select>
						</div>
					{/if}
				</div>

				{#if node.type === 'objective'}
					<div class="grid grid-cols-2 gap-3">
						<div>
							<label for="drawer-quarter" class="block text-label-sm font-bold text-on-surface-variant uppercase tracking-wider">
								Trimestre Alvo (Opcional)
							</label>
							<select
								id="drawer-quarter"
								name="quarter"
								disabled={!canEdit}
								class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2.5 py-1.5 text-xs font-medium text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
							>
								<option value="" selected={!node.quarter}>Ano Inteiro (Sem trimestre)</option>
								<option value="1" selected={node.quarter === 1}>1º Tri (Q1)</option>
								<option value="2" selected={node.quarter === 2}>2º Tri (Q2)</option>
								<option value="3" selected={node.quarter === 3}>3º Tri (Q3)</option>
								<option value="4" selected={node.quarter === 4}>4º Tri (Q4)</option>
							</select>
						</div>
					</div>
				{/if}

				{#if (node.type === 'key_result' || node.type === 'objective') && node.children.length === 0}
					<div>
						<label for="drawer-manual-prog" class="block text-label-sm font-bold text-on-surface-variant uppercase tracking-wider">
							Progresso Manual (0–100%, quando não há KPIs filhos)
						</label>
						<input
							id="drawer-manual-prog"
							name="manual_progress_pct"
							type="number"
							min="0"
							max="100"
							disabled={!canEdit}
							value={Math.round((node.manual_progress ?? 0) * 100)}
							class="mt-1 w-32 rounded-[4px] border border-outline-variant bg-surface-container px-2.5 py-1.5 text-xs font-medium text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
						/>
					</div>
				{/if}

				{#if node.type === 'kpi'}
					<div class="grid grid-cols-4 gap-2.5 border-t border-outline-variant/60 pt-3">
						<div>
							<label for="kpi-unit" class="block text-[10px] font-bold text-on-surface-variant uppercase"
								>Unidade</label
							>
							<input
								id="kpi-unit"
								name="unit"
								type="text"
								placeholder="R$, %, pts"
								disabled={!canEdit}
								value={node.unit ?? ''}
								class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2 py-1.5 text-xs font-medium text-on-surface"
							/>
						</div>
						<div>
							<label for="kpi-baseline" class="block text-[10px] font-bold text-on-surface-variant uppercase"
								>Linha Base</label
							>
							<input
								id="kpi-baseline"
								name="baseline"
								type="number"
								step="any"
								disabled={!canEdit}
								value={node.baseline ?? 0}
								class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2 py-1.5 text-xs font-medium text-on-surface"
							/>
						</div>
						<div>
							<label for="kpi-target" class="block text-[10px] font-bold text-on-surface-variant uppercase"
								>Meta</label
							>
							<input
								id="kpi-target"
								name="target_value"
								type="number"
								step="any"
								disabled={!canEdit}
								value={node.target_value ?? 100}
								class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2 py-1.5 text-xs font-medium text-on-surface"
							/>
						</div>
						<div>
							<label for="kpi-dir" class="block text-[10px] font-bold text-on-surface-variant uppercase"
								>Direção</label
							>
							<select
								id="kpi-dir"
								name="direction"
								disabled={!canEdit}
								class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2 py-1.5 text-xs font-medium text-on-surface"
							>
								<option value="up" selected={node.direction !== 'down'}>Aumentar (↑)</option>
								<option value="down" selected={node.direction === 'down'}>Diminuir (↓)</option>
							</select>
						</div>
					</div>
				{/if}

				{#if validParents.length > 0}
					<div class="border-t border-outline-variant/60 pt-3">
						<label for="drawer-parent" class="block text-label-sm font-bold text-on-surface-variant uppercase tracking-wider">
							Nó Pai (Reorganizar / Mover)
						</label>
						<select
							id="drawer-parent"
							name="parent_id"
							disabled={!canEdit}
							class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2.5 py-1.5 text-xs font-medium text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)]"
						>
							{#each validParents as p (p.id)}
								<option value={p.id} selected={node.parent_id === p.id}>
									[{(typeLabels[p.type] ?? p.type).toUpperCase()}] {p.title}
								</option>
							{/each}
						</select>
					</div>
				{:else}
					<input type="hidden" name="parent_id" value={node.parent_id ?? ''} />
				{/if}

				{#if canEdit}
					<div class="flex justify-end pt-1">
						<button
							type="submit"
							class="inline-flex items-center gap-1.5 rounded-[4px] bg-primary px-4 py-2 text-xs font-bold text-on-primary shadow-[0_2px_0_#004494] transition-all hover:opacity-95"
						>
							<CheckCircle2 class="h-3.5 w-3.5" />
							Salvar Alterações
						</button>
					</div>
				{/if}
			</form>

			<!-- 2. KPI Metric Check-in & Sparkline History -->
			{#if node.type === 'kpi'}
				<section class="rounded-[6px] border border-outline-variant bg-tertiary-fixed/40 p-4">
					<div class="flex items-center justify-between">
						<h4 class="flex items-center gap-1.5 text-xs font-bold text-on-tertiary-fixed uppercase tracking-wider">
							<LineChart class="h-4 w-4 text-tertiary" />
							Histórico de Métricas e Check-In do KPI
						</h4>
						<span class="text-xs font-bold text-on-tertiary-fixed">
							Atual: {formatNumber(node.current_value, node.unit)} / Meta: {formatNumber(
								node.target_value,
								node.unit
							)}
						</span>
					</div>

					{#if sparklinePoints}
						<div class="mt-3 rounded-[4px] border border-outline-variant bg-surface-container-lowest p-3">
							<svg
								viewBox="0 0 {sparklinePoints.W} {sparklinePoints.H}"
								class="h-20 w-full overflow-visible"
							>
								{#if sparklinePoints.targetY != null}
									<line
										x1="0"
										y1={sparklinePoints.targetY}
										x2={sparklinePoints.W}
										y2={sparklinePoints.targetY}
										stroke="#857E70"
										stroke-dasharray="4 4"
										stroke-width="1"
									/>
								{/if}
								<polyline
									fill="none"
									stroke="#00665A"
									stroke-width="2.5"
									stroke-linecap="round"
									stroke-linejoin="round"
									points={sparklinePoints.polyline}
								/>
								{#each sparklinePoints.coords as pt}
									<circle cx={pt.x} cy={pt.y} r="3.5" class="fill-tertiary stroke-surface-container-lowest stroke-2">
										<title>{formatNumber(pt.v, node.unit)}</title>
									</circle>
								{/each}
							</svg>
						</div>
					{/if}

					{#if canEdit}
						<form
							method="POST"
							action="/strategy?/logMetric"
							use:enhanceFormValidation
							class="mt-3 grid grid-cols-12 gap-2"
						>
							<input type="hidden" name="nodeId" value={node.id} />
							<div class="col-span-4">
								<label for="metric-val" class="sr-only">Novo Valor</label>
								<input
									id="metric-val"
									name="value"
									type="number"
									step="any"
									required
									placeholder="Novo valor..."
									aria-errormessage="metric-val-err"
									class="w-full rounded-[4px] border border-outline-variant bg-surface-container-lowest px-2.5 py-1.5 text-xs font-semibold text-on-surface"
								/>
								<div id="metric-val-err" class="error-msg">
									<AlertCircle class="h-3 w-3" />
									<span>Obrigatório</span>
								</div>
							</div>
							<div class="col-span-5">
								<label for="metric-note" class="sr-only">Nota</label>
								<input
									id="metric-note"
									name="note"
									type="text"
									placeholder="Nota de check-in (opcional)..."
									class="w-full rounded-[4px] border border-outline-variant bg-surface-container-lowest px-2.5 py-1.5 text-xs text-on-surface"
								/>
							</div>
							<div class="col-span-3">
								<button
									type="submit"
									class="w-full rounded-[4px] bg-tertiary px-3 py-1.5 text-xs font-bold text-on-tertiary shadow-[0_2px_0_#00201B] hover:opacity-95"
								>
									Registrar Check-In
								</button>
							</div>
						</form>
					{/if}

					{#if node.metricUpdates.length > 0}
						<div class="mt-3 max-h-40 space-y-1.5 overflow-y-auto pr-1">
							{#each node.metricUpdates as mu (mu.id)}
								<div
									class="flex items-center justify-between rounded-[4px] border border-outline-variant/60 bg-surface-container-lowest px-3 py-1.5 text-xs"
								>
									<div>
										<span class="font-bold text-on-surface">
											{formatNumber(mu.value, node.unit)}
										</span>
										{#if mu.note}
											<span class="ml-1.5 text-on-surface-variant">— {mu.note}</span>
										{/if}
									</div>
									<span class="text-[10px] font-semibold text-outline">
										{mu.created_at.slice(0, 10)}
									</span>
								</div>
							{/each}
						</div>
					{/if}
				</section>
			{/if}

			<!-- 3. Value Alignment (Strategy Nodes <-> Values) -->
			{#if node.tree === 'strategy'}
				<form
					method="POST"
					action="/strategy?/setValues"
					class="rounded-[6px] border border-outline-variant bg-surface-container-lowest p-4"
				>
					<input type="hidden" name="nodeId" value={node.id} />
					<div class="flex items-center justify-between">
						<h4 class="flex items-center gap-1.5 text-xs font-bold text-on-surface uppercase tracking-wider">
							<Sparkles class="h-3.5 w-3.5 text-secondary" />
							Alinhamento de Valores (Identidade)
						</h4>
						{#if canEdit}
							<button
								type="submit"
								class="rounded-[4px] border border-outline-variant bg-surface-container-low px-2.5 py-1 text-[11px] font-bold text-on-surface shadow-[0_2px_0_#D8D2C2] hover:bg-primary hover:text-on-primary hover:border-primary"
							>
								Atualizar Alinhamento
							</button>
						{/if}
					</div>
					<p class="mt-0.5 text-[11px] text-on-surface-variant">
						Alinhe este nó estratégico a um ou mais valores fundamentais da empresa.
					</p>

					<div class="mt-3 grid grid-cols-1 gap-2 sm:grid-cols-2">
						{#each valuesList as val (val.id)}
							{@const checked = node.alignedValues.some((v) => v.id === val.id)}
							<label
								class="flex cursor-pointer items-center gap-2 rounded-[4px] border p-2 text-xs transition {checked
									? 'border-on-surface bg-surface-container-low font-bold text-on-surface'
									: 'border-outline-variant bg-surface-container-lowest text-on-surface-variant hover:bg-surface-container-low'}"
							>
								<input
									type="checkbox"
									name="valueIds"
									value={val.id}
									checked={checked}
									disabled={!canEdit}
									class="rounded-[2px] border-outline-variant text-primary"
								/>
								<span
									class="h-2.5 w-2.5 shrink-0 rounded-full"
									style="background-color: {valueColor(val.id)}"
								></span>
								<span class="truncate">{val.title}</span>
							</label>
						{/each}
					</div>
				</form>
			{/if}

			<!-- 4. Assignees: Teams & Individual Members -->
			<form
				method="POST"
				action="/strategy?/setAssignees"
				class="rounded-[6px] border border-outline-variant bg-surface-container-lowest p-4 space-y-4"
			>
				<input type="hidden" name="nodeId" value={node.id} />
				<div class="flex items-center justify-between">
					<div>
						<h4 class="flex items-center gap-1.5 text-xs font-bold text-on-surface uppercase tracking-wider">
							<Users class="h-3.5 w-3.5 text-primary" />
							Responsáveis e Atribuições
						</h4>
						<p class="mt-0.5 text-[11px] text-on-surface-variant">
							Atribua departamentos responsáveis (equipes), membros individuais ou ambos.
						</p>
					</div>
					{#if canEdit}
						<button
							type="submit"
							class="rounded-[4px] bg-primary px-3 py-1.5 text-[11px] font-bold text-on-primary shadow-[0_2px_0_#004494] hover:opacity-95"
						>
							Salvar Atribuições
						</button>
					{/if}
				</div>

				<!-- Teams Sub-section -->
				{#if teams.length > 0}
					<div class="rounded-[4px] border border-outline-variant/60 bg-surface-container-low/60 p-3">
						<div class="flex items-center justify-between">
							<span class="text-[11px] font-bold text-on-surface uppercase tracking-wider">
								Equipes / Departamentos Atribuídos
							</span>
							<span class="text-[10px] font-semibold text-on-surface-variant">{node.teams.length} atribuída(s)</span>
						</div>
						<div class="mt-2.5 grid grid-cols-1 gap-2 sm:grid-cols-2">
							{#each teams as t (t.id)}
								{@const teamAssigned = node.teams.some((nt) => nt.id === t.id)}
								<label
									class="flex cursor-pointer items-center justify-between rounded-[4px] border p-2 text-xs transition {teamAssigned
										? 'border-primary bg-primary-fixed/40 font-bold text-on-surface'
										: 'border-outline-variant bg-surface-container-lowest text-on-surface-variant hover:bg-surface-container-low'}"
								>
									<div class="flex items-center gap-2 min-w-0">
										<input
											type="checkbox"
											name="teamIds"
											value={t.id}
											checked={teamAssigned}
											disabled={!canEdit}
											class="rounded-[2px] border-outline-variant text-primary"
										/>
										<span
											class="h-2.5 w-2.5 shrink-0 rounded-full"
											style="background-color: {t.color || '#005AC2'}"
										></span>
										<span class="truncate">{t.name}</span>
									</div>
								</label>
							{/each}
						</div>
					</div>
				{/if}

				<!-- Individual Members Sub-section -->
				<div>
					<div class="flex items-center justify-between mb-2">
						<span class="text-[11px] font-bold text-on-surface uppercase tracking-wider">
							Membros Responsáveis Individuais
						</span>
						<span class="text-[10px] font-semibold text-on-surface-variant">{node.assignees.length} atribuído(s)</span>
					</div>
					<div class="grid grid-cols-1 gap-2 sm:grid-cols-2">
						{#each profiles as prof (prof.id)}
							{@const assigned = node.assignees.some((a) => a.id === prof.id)}
							<label
								class="flex cursor-pointer items-center justify-between rounded-[4px] border p-2 text-xs transition {assigned
									? 'border-on-surface bg-surface-container-low font-bold text-on-surface'
									: 'border-outline-variant bg-surface-container-lowest text-on-surface-variant hover:bg-surface-container-low'}"
							>
								<div class="flex items-center gap-2 min-w-0">
									<input
										type="checkbox"
										name="userIds"
										value={prof.id}
										checked={assigned}
										disabled={!canEdit}
										class="rounded-[2px] border-outline-variant text-primary"
									/>
									<span
										class="inline-flex h-5 w-5 shrink-0 items-center justify-center rounded-full text-[9px] font-bold text-white"
										style="background-color: {prof.color || '#005AC2'}"
									>
										{getInitials(prof.name)}
									</span>
									<span class="truncate">{prof.name}</span>
								</div>
								{#if prof.teams && prof.teams.length > 0}
									<div class="flex items-center gap-1 shrink-0 ml-1">
										{#each prof.teams as pTeam (pTeam.id)}
											<span
												class="h-1.5 w-1.5 rounded-full"
												style="background-color: {pTeam.color || '#005AC2'}"
												title={pTeam.name}
											></span>
										{/each}
									</div>
								{/if}
							</label>
						{/each}
					</div>
				</div>
			</form>

			<!-- 5. Danger Zone (Delete / Promote Children) -->
			{#if canEdit}
				<div class="rounded-[6px] border border-error/40 bg-error-container/40 p-4">
					<h4 class="text-xs font-bold text-on-error-container uppercase tracking-wider">Zona de Perigo</h4>
					<p class="mt-0.5 text-[11px] text-on-error-container/80">
						Excluir um nó apaga seus filhos em cascata, a menos que você os promova ao nó pai.
					</p>
					<div class="mt-3 flex flex-wrap items-center gap-2">
						<form method="POST" action="/strategy?/deleteNode">
							<input type="hidden" name="nodeId" value={node.id} />
							<input type="hidden" name="promote" value="0" />
							<button
								type="submit"
								class="inline-flex items-center gap-1.5 rounded-[4px] bg-error px-3 py-1.5 text-xs font-bold text-on-error shadow-[0_2px_0_#410002] hover:opacity-95"
							>
								<Trash2 class="h-3.5 w-3.5" />
								Excluir Nó{node.children.length > 0
									? ` e ${node.children.length} ${node.children.length === 1 ? 'Filho' : 'Filhos'}`
									: ''}
							</button>
						</form>

						{#if canPromoteChildren}
							<form method="POST" action="/strategy?/deleteNode">
								<input type="hidden" name="nodeId" value={node.id} />
								<input type="hidden" name="promote" value="1" />
								<button
									type="submit"
									class="inline-flex items-center gap-1.5 rounded-[4px] border border-error/40 bg-surface-container-lowest px-3 py-1.5 text-xs font-bold text-error hover:bg-error-container"
								>
									<ArrowUpRight class="h-3.5 w-3.5" />
									Excluir e Promover Filhos
								</button>
							</form>
						{/if}
					</div>
				</div>
			{/if}
		</div>
	</aside>
{/if}
