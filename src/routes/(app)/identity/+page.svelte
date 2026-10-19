<script lang="ts">
	import IdentityView from '$lib/components/identity/IdentityView.svelte';
	import { enrichNodes } from '$lib/progress';
	import { AlertCircle } from 'lucide-svelte';

	let { data, form } = $props();

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

	const strategyNodes = $derived(
		Array.from(enriched.byId.values()).filter((n) => n.tree === 'strategy')
	);
</script>

<div class="flex flex-col w-full p-gutter">
	{#if form?.message}
		<div
			class="mb-space-md flex items-center gap-2 rounded-xl bg-error-container px-4 py-3 text-xs font-semibold text-on-error-container shadow-sm"
		>
			<AlertCircle class="h-4 w-4" />
			<span>{form.message}</span>
		</div>
	{/if}

	<IdentityView
		eras={enriched.eras}
		valuesList={enriched.valuesList}
		nodeValues={data.values}
		{strategyNodes}
		{canEdit}
	/>
</div>
