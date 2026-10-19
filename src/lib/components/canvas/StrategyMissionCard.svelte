<script lang="ts">
	import { Handle, Position } from '@xyflow/svelte';
	import type { NodeWithExtras } from '$lib/types';
	import {
		Compass,
		Sparkles,
		ExternalLink,
		ChevronUp,
		ChevronDown,
		Eye,
		EyeOff
	} from 'lucide-svelte';

	interface CardData {
		node: NodeWithExtras;
		direction: 'TB' | 'LR';
		childCount?: number;
		collapsed?: boolean;
		onSelect: (id: string) => void;
		onToggleCollapse?: (id: string) => void;
	}

	let { data }: { data: CardData } = $props();

	const node = $derived(data.node);
	const eraLabel = $derived.by(() => {
		if (node.start_year) {
			return node.end_year ? `${node.start_year}–${node.end_year}` : `${node.start_year}–Presente`;
		}
		return 'Horizonte Estratégico';
	});
</script>

<div class="relative w-[560px]">
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
		class="group relative w-full cursor-pointer rounded-2xl border border-outline-variant/50 bg-surface-container-lowest p-4 text-left text-on-surface shadow-[0_4px_12px_rgba(36,34,30,0.08)] transition-all duration-200 hover:border-primary hover:shadow-xl {(data.childCount ?? 0) > 0 ? 'pb-5' : ''}"
	>
		<!-- Top Row: Badge + Era Label -->
		<div class="flex items-center justify-between gap-2">
			<div class="flex items-center gap-2">
				<span
					class="inline-flex items-center gap-1.5 rounded-full bg-primary-fixed px-2.5 py-0.5 text-[10px] font-bold tracking-wider text-on-primary-fixed uppercase"
				>
					<Compass class="h-3 w-3 text-primary" />
					Missão Organizacional
				</span>

				<span
					class="rounded-full bg-surface-container px-2.5 py-0.5 text-[10px] font-semibold text-on-surface-variant"
				>
					{eraLabel}
				</span>
			</div>

			<div class="flex items-center gap-2">
				{#if node.children.length > 0}
					<span
						class="inline-flex items-center gap-1 text-[11px] font-medium text-on-surface-variant"
						title="{node.children.length} {node.children.length === 1 ? 'Valor Fundamental definido' : 'Valores Fundamentais definidos'} nesta era"
					>
						<Sparkles class="h-3 w-3 text-tertiary-container" />
						{node.children.length} {node.children.length === 1 ? 'Valor Fundamental' : 'Valores Fundamentais'}
					</span>
				{/if}
				<ExternalLink class="h-3.5 w-3.5 text-outline opacity-60 transition group-hover:opacity-100" />
			</div>
		</div>

		<!-- Mission Statement Quote -->
		<div class="mt-2 text-xs font-semibold italic leading-relaxed tracking-tight text-on-surface sm:text-sm">
			“{node.title}”
		</div>

		{#if node.description}
			<p class="mt-1 line-clamp-1 text-[11px] text-on-surface-variant">
				{node.description}
			</p>
		{/if}
	</div>

	{#if (data.childCount ?? 0) > 0 && data.onToggleCollapse}
		<button
			type="button"
			onpointerdown={(e) => e.stopPropagation()}
			onmousedown={(e) => e.stopPropagation()}
			onclick={(e) => {
				e.stopPropagation();
				data.onToggleCollapse?.(node.id);
			}}
			class="nodrag nopan absolute -bottom-3 left-1/2 z-20 inline-flex -translate-x-1/2 items-center gap-1 rounded-full border px-3 py-0.5 text-[10px] font-semibold whitespace-nowrap shadow-sm transition {data.collapsed
				? 'border-amber-400 bg-amber-400 text-slate-950 shadow-md hover:bg-amber-300'
				: 'border-slate-700 bg-slate-800 text-slate-100 hover:border-amber-400 hover:bg-amber-400 hover:text-slate-950'}"
			title={data.collapsed
				? `Mostrar ${data.childCount} ${data.childCount === 1 ? 'objetivo filho' : 'objetivos filhos'}`
				: `Ocultar ${data.childCount} ${data.childCount === 1 ? 'objetivo filho' : 'objetivos filhos'}`}
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

<!-- Source handle (outgoing to Annual Objectives) -->
<Handle
	type="source"
	position={data.direction === 'TB' ? Position.Bottom : Position.Right}
	class="pointer-events-none !h-3 !w-3 !border-2 !border-white !bg-amber-400"
/>
