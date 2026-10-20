<script lang="ts">
	import { Handle, Position } from '@xyflow/svelte';
	import type { NodeWithExtras } from '$lib/types';
	import { formatNumber, formatPct, getInitials } from '$lib/utils';
	import { valueColor } from '$lib/value-colors';
	import { getDossierTheme } from '$lib/dossier-theme';
	import AttributionPile from '$lib/components/ui/AttributionPile.svelte';
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
	const customTheme = $derived(
		getDossierTheme(
			node.color ||
				(node.teams[0]?.color ||
					(node.type === 'objective'
						? '#0058bd'
						: node.type === 'key_result'
							? '#ca8a04'
							: '#059669'))
		)
	);

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
				<span
					class="rounded px-1.5 py-0.5 text-[10px] font-bold"
					style="background-color: rgba(255,255,255,0.75); color: {customTheme.accentDark}; border: 1px solid {customTheme.cardBorder};"
				>
					{node.year}{node.quarter ? ` · Q${node.quarter}` : ''}
				</span>
			{:else if node.cycle}
				<span
					class="rounded px-1.5 py-0.5 text-[10px] font-bold"
					style="background-color: rgba(255,255,255,0.75); color: {customTheme.accentDark}; border: 1px solid {customTheme.cardBorder};"
				>
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
	<h3
		class="mt-2 line-clamp-2 text-xs font-bold leading-snug"
		style="color: {customTheme.accentShadow};"
	>
		{node.title}
	</h3>

	<!-- Progress Bar or KPI Readout -->
	<div class="mt-2.5">
		{#if node.type === 'kpi'}
			<div class="flex items-baseline justify-between text-[11px]">
				<span
					class="flex items-center gap-1 font-bold"
					style="color: {customTheme.accentShadow};"
				>
					{#if node.direction === 'down'}
						<TrendingDown class="h-3 w-3" style="color: {customTheme.accent};" />
					{:else}
						<TrendingUp class="h-3 w-3" style="color: {customTheme.accent};" />
					{/if}
					{formatNumber(node.current_value, node.unit)}
					<span class="font-medium" style="color: {customTheme.accentDark};">
						/ {formatNumber(node.target_value, node.unit)}
					</span>
				</span>
				<span class="font-bold" style="color: {customTheme.accentShadow};">{formatPct(node.progress)}</span>
			</div>
		{:else}
			<div class="flex items-center justify-between text-[11px]">
				<span class="font-semibold" style="color: {customTheme.accentDark};">Progresso</span>
				<span class="font-bold" style="color: {customTheme.accentShadow};">{pct}%</span>
			</div>
		{/if}
		<div
			class="mt-1 h-2 w-full overflow-hidden rounded-full p-0.5"
			style="background-color: {customTheme.badgeBg}; border: 1px solid {customTheme.badgeBorder};"
		>
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
	<div
		class="mt-2.5 flex items-start justify-between border-t border-dashed pt-2 gap-2"
		style="border-color: {customTheme.cardBorder};"
	>
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

		</div>

		<!-- Right: Attribution Pile (Squircle team + circle member with hover animations & tooltips) & Quick Add -->
		<div class="flex shrink-0 items-center gap-1.5 pt-0.5">
			<AttributionPile
				teams={node.teams}
				assignees={node.assignees}
				size="sm"
			/>

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
