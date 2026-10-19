<script lang="ts">
	import AppShell from '$lib/components/layout/AppShell.svelte';
	import { enrichNodes } from '$lib/progress';
	import type { Snippet } from 'svelte';

	let { data, children }: { data: App.PageData & Record<string, any>; children: Snippet } =
		$props();

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

	const atRiskCount = $derived.by(() => {
		let count = 0;
		for (const n of enriched.byId.values()) {
			if (n.tree === 'strategy' && (n.atRisk || n.status === 'off_track')) {
				count++;
			}
		}
		return count;
	});

	const overallProgressPct = $derived.by(() => {
		const objs = enriched.strategyRoots;
		if (objs.length === 0) return 64;
		const totalWeight = objs.reduce((s, o) => s + (o.weight || 1), 0);
		if (totalWeight === 0) return 64;
		const avg = objs.reduce((s, o) => s + o.progress * (o.weight || 1), 0) / totalWeight;
		return Math.round(avg * 100);
	});
</script>

<AppShell
	user={data.user!}
	profiles={data.profiles}
	mode={data.mode ?? 'local'}
	{atRiskCount}
	{overallProgressPct}
>
	{@render children()}
</AppShell>
