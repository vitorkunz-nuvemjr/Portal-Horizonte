<script lang="ts">
	import { Handle, Position } from '@xyflow/svelte';
	import type { NodeWithExtras } from '$lib/types';
	import { formatNumber, formatPct, getInitials } from '$lib/utils';
	import { valueColor } from '$lib/value-colors';
	import { getDossierTheme } from '$lib/dossier-theme';
	import {
		Target,
		Flag,
		Activity,
		AlertTriangle,
		Plus,
		TrendingUp,
		TrendingDown,
		ChevronUp,
		ChevronDown,
		Eye,
		EyeOff
	} from 'lucide-svelte';

	interface CardData {
		node: NodeWithExtras;
		highlighted: boolean;
		dimmed: boolean;
		selected: boolean;
		canEdit: boolean;
		direction: 'TB' | 'LR';
		childCount: number;
		collapsed: boolean;
		onSelect: (id: string) => void;
		onAddChild: (parent: NodeWithExtras) => void;
		onToggleCollapse: (id: string) => void;
	}

	let { data }: { data: CardData } = $props();

	const node = $derived(data.node);
	const pct = $derived(Math.round(node.progress * 100));
	const customTheme = $derived(node.color ? getDossierTheme(node.color) : null);

	const typeMeta = $derived.by(() => {
		switch (node.type) {
			case 'objective':
				return {
					label: 'OBJETIVO',
					badgeClass: 'bg-primary-fixed text-on-primary-fixed border-primary/20',
					borderClass: 'border-outline-variant/50 bg-surface-container-lowest hover:border-primary',
					barClass: 'bg-primary'
				};
			case 'key_result':
				return {
					label: 'KEY RESULT',
					badgeClass: 'bg-[#FDE047] text-[#78350F] border-[#FBBF24]',
					borderClass: 'border-[#FDE047] bg-[#FEF9C3] hover:border-[#CA8A04]',
					barClass: 'bg-[#CA8A04]'
				};
			default:
				return {
					label: 'KPI',
					badgeClass: 'bg-[#BBF7D0] text-[#14532D] border-[#86EFAC]',
					borderClass: 'border-[#BBF7D0] bg-[#DCFCE7] hover:border-[#16A34A]',
					barClass: 'bg-[#16A34A]'
				};
		}
	});

	const statusBadge = $derived.by(() => {
		if (node.status === 'done') return { text: 'Concluído', cls: 'bg-[#DCFCE7] text-[#166534]' };
		if (node.atRisk || node.status === 'at_risk')
			return { text: 'Em Risco', cls: 'bg-secondary-fixed text-on-secondary-fixed-variant' };
		if (node.status === 'off_track')
			return { text: 'Atrasado', cls: 'bg-error-container text-on-error-container' };
		if (node.status === 'on_track')
			return { text: 'No Alvo', cls: 'bg-primary-fixed text-on-primary-fixed' };
		return { text: 'Não Iniciado', cls: 'bg-surface-container text-on-surface-variant' };
	});
</script>

<!-- Target handle (incoming from parent) -->
{#if node.parent_id}
	<Handle
		type="target"
		position={data.direction === 'TB' ? Position.Top : Position.Left}
		class="pointer-events-none !h-2.5 !w-2.5 !border-2 !border-white !bg-slate-400"
	/>
{/if}

<div class="relative w-[290px]">
	<div
		role="button"
		tabindex="0"
		onclick={() => data.onSelect(node.id)}
		onkeydown={(e) => {
			if (e.key === 'Enter' || e.key === ' ') {
				e.preventDefault();
				data.onSelect(node.id);
			}
		}}
		class="group relative w-full cursor-pointer rounded-xl border bg-white p-3.5 text-left shadow-xs transition-all duration-200 {data.childCount > 0 ? 'pb-4' : ''} {customTheme ? '' : typeMeta.borderClass} {data.selected
			? 'ring-2 ring-slate-900 shadow-md'
			: ''} {data.highlighted
			? 'ring-2 ring-amber-500 shadow-lg scale-[1.02]'
			: ''} {data.dimmed ? 'opacity-25 saturate-50 hover:opacity-60' : ''}"
		style={customTheme ? `background-color: ${customTheme.folderBg}; border-color: ${customTheme.folderBorder};` : ''}
	>
	<!-- Top Row: Type Badge + Scope + Status -->
	<div class="flex items-center justify-between gap-1.5">
		<div class="flex items-center gap-1.5">
			<span
				class="inline-flex items-center gap-1 rounded border px-1.5 py-0.5 text-[10px] font-bold tracking-wider {customTheme ? '' : typeMeta.badgeClass}"
				style={customTheme ? `background-color: ${customTheme.badgeBg}; color: ${customTheme.badgeText}; border-color: ${customTheme.badgeBorder};` : ''}
			>
				{#if node.type === 'objective'}
					<Target class="h-2.5 w-2.5" />
				{:else if node.type === 'key_result'}
					<Flag class="h-2.5 w-2.5" />
				{:else}
					<Activity class="h-2.5 w-2.5" />
				{/if}
				{typeMeta.label}
			</span>

			{#if node.type === 'objective' && node.year}
				<span class="rounded bg-slate-100 px-1.5 py-0.5 text-[10px] font-semibold text-slate-600">
					{node.year}{node.quarter ? ` · Q${node.quarter}` : ''}
				</span>
			{:else if node.cycle}
				<span class="rounded bg-slate-100 px-1.5 py-0.5 text-[10px] font-semibold text-slate-600">
					{node.cycle.code}
				</span>
			{/if}
		</div>

		<span
			class="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-semibold {statusBadge.cls}"
		>
			{#if node.atRisk && node.status !== 'done'}
				<AlertTriangle class="h-2.5 w-2.5" />
			{/if}
			{statusBadge.text}
		</span>
	</div>

	<!-- Title -->
	<h3 class="mt-2 line-clamp-2 text-xs font-semibold leading-snug text-slate-900">
		{node.title}
	</h3>

	<!-- Progress Bar or KPI Readout -->
	<div class="mt-2.5">
		{#if node.type === 'kpi'}
			<div class="flex items-baseline justify-between text-[11px]">
				<span class="flex items-center gap-1 font-semibold text-slate-800">
					{#if node.direction === 'down'}
						<TrendingDown class="h-3 w-3 text-sky-600" />
					{:else}
						<TrendingUp class="h-3 w-3 text-sky-600" />
					{/if}
					{formatNumber(node.current_value, node.unit)}
					<span class="font-normal text-slate-400">
						/ {formatNumber(node.target_value, node.unit)}
					</span>
				</span>
				<span class="font-bold text-slate-700">{formatPct(node.progress)}</span>
			</div>
		{:else}
			<div class="flex items-center justify-between text-[11px]">
				<span class="text-slate-500">Progresso</span>
				<span class="font-bold text-slate-800">{pct}%</span>
			</div>
		{/if}
		<div class="mt-1 h-1.5 w-full overflow-hidden rounded-full bg-slate-100">
			<div
				class="h-full rounded-full transition-all duration-300 {node.atRisk
					? 'bg-amber-500'
					: customTheme ? '' : typeMeta.barClass}"
				style="width: {pct}%; {customTheme && !node.atRisk ? `background-color: ${customTheme.accent};` : ''}"
			></div>
		</div>
	</div>

	<!-- Footer: Aligned Values + Assignees + Quick Add Child -->
	<!-- Footer: Aligned Values + Teams below them + Assignees + Quick Add Child -->
	<div class="mt-2.5 flex items-start justify-between border-t border-slate-100 pt-2 gap-2">
		<!-- Left: Aligned Values and Responsible Teams below them -->
		<div class="flex min-w-0 flex-1 flex-col gap-1">
			{#if node.alignedValues.length > 0}
				<div class="flex flex-wrap items-center gap-1">
					{#each node.alignedValues as val (val.id)}
						<span
							class="inline-flex items-center gap-1 rounded-full border border-slate-200 bg-slate-50 px-1.5 py-0.2 text-[9px] font-medium text-slate-700"
							title="Alinhado ao Valor: {val.title}"
						>
							<span
								class="h-1.5 w-1.5 rounded-full"
								style="background-color: {valueColor(val.id)}"
							></span>
							<span class="max-w-[72px] truncate">{val.title}</span>
						</span>
					{/each}
				</div>
			{/if}

			{#if (node.type === 'objective' || node.type === 'key_result') && node.teams && node.teams.length > 0}
				<div class="flex flex-wrap items-center gap-1">
					{#each node.teams.slice(0, 2) as t (t.id)}
						<span
							class="inline-flex items-center gap-1 rounded-md border border-slate-200/80 bg-slate-50 px-1.5 py-0.5 text-[9px] font-semibold text-slate-700"
							title="Equipe: {t.name}"
						>
							<span
								class="h-1.5 w-1.5 rounded-full"
								style="background-color: {t.color || '#2563eb'}"
							></span>
							<span class="max-w-[64px] truncate">{t.name}</span>
						</span>
					{/each}
					{#if node.teams.length > 2}
						<span class="text-[9px] font-bold text-slate-400">+{node.teams.length - 2}</span>
					{/if}
				</div>
			{/if}
		</div>

		<!-- Right: Teams (for KPI only), Assignees & Quick Add -->
		<div class="flex shrink-0 items-center gap-1.5 pt-0.5">
			<!-- Assigned Teams Badges (KPI only) -->
			{#if node.type === 'kpi' && node.teams && node.teams.length > 0}
				<div class="flex items-center gap-1">
					{#each node.teams.slice(0, 1) as t (t.id)}
						<span
							class="inline-flex items-center gap-1 rounded-md border border-slate-200/80 bg-slate-50 px-1.5 py-0.5 text-[9px] font-semibold text-slate-700"
							title="Equipe: {t.name}"
						>
							<span
								class="h-1.5 w-1.5 rounded-full"
								style="background-color: {t.color || '#2563eb'}"
							></span>
							<span class="max-w-[64px] truncate">{t.name}</span>
						</span>
					{/each}
				</div>
			{/if}

			<!-- Assignee Avatars -->
			{#if node.assignees.length > 0}
				<div class="flex -space-x-1.5">
					{#each node.assignees.slice(0, 3) as person (person.id)}
						<span
							class="inline-flex h-5 w-5 items-center justify-center rounded-full text-[9px] font-bold text-white ring-1 ring-white"
							style="background-color: {person.color || '#475569'}"
							title={person.name}
						>
							{getInitials(person.name)}
						</span>
					{/each}
				</div>
			{/if}

			{#if data.canEdit && (node.type === 'objective' || node.type === 'key_result')}
				<button
					type="button"
					onpointerdown={(e) => e.stopPropagation()}
					onmousedown={(e) => e.stopPropagation()}
					onclick={(e) => {
						e.stopPropagation();
						data.onAddChild(node);
					}}
					class="nodrag nopan inline-flex h-5 w-5 items-center justify-center rounded-md border border-slate-200 bg-slate-50 text-slate-600 opacity-85 transition hover:border-slate-400 hover:bg-slate-900 hover:text-white"
					title="Adicionar {node.type === 'objective' ? 'Resultado-Chave' : 'KPI'}"
				>
					<Plus class="h-3 w-3" />
				</button>
			{/if}
		</div>
	</div>
	</div>

	{#if data.childCount > 0}
		<button
			type="button"
			onpointerdown={(e) => e.stopPropagation()}
			onmousedown={(e) => e.stopPropagation()}
			onclick={(e) => {
				e.stopPropagation();
				data.onToggleCollapse(node.id);
			}}
			class="nodrag nopan absolute -bottom-3 left-1/2 z-20 inline-flex -translate-x-1/2 items-center gap-1 rounded-full border px-2.5 py-0.5 text-[10px] font-semibold whitespace-nowrap shadow-xs transition {data.collapsed
				? 'border-slate-900 bg-slate-900 text-white shadow-md hover:bg-slate-700'
				: 'border-slate-300 bg-white text-slate-700 hover:border-slate-900 hover:bg-slate-900 hover:text-white'}"
			title={data.collapsed
				? `Mostrar ${data.childCount} ${data.childCount === 1 ? 'item filho' : 'itens filhos'}`
				: `Ocultar ${data.childCount} ${data.childCount === 1 ? 'item filho' : 'itens filhos'}`}
			aria-expanded={!data.collapsed}
		>
			{#if data.collapsed}
				<Eye class="h-3 w-3" />
				<span>Mostrar filhos ({data.childCount})</span>
				<ChevronDown class="h-3 w-3" />
			{:else}
				<EyeOff class="h-3 w-3" />
				<span>Ocultar filhos ({data.childCount})</span>
				<ChevronUp class="h-3 w-3" />
			{/if}
		</button>
	{/if}
</div>

<!-- Source handle (outgoing to children) -->
{#if node.type !== 'kpi'}
	<Handle
		type="source"
		position={data.direction === 'TB' ? Position.Bottom : Position.Right}
		class="pointer-events-none !h-2.5 !w-2.5 !border-2 !border-white !bg-slate-400"
	/>
{/if}
