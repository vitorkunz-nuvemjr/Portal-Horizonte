<script lang="ts">
	import { getIconSvg } from '$lib/icons/registry';

	interface Props {
		name: string;
		size?: number | string;
		class?: string;
		[key: string]: any;
	}

	let { name, size = 16, class: className = '', ...restProps }: Props = $props();

	const svgContent = $derived(getIconSvg(name));
</script>

{#if svgContent}
	<svg
		viewBox="0 0 14 14"
		width={size}
		height={size}
		class={className}
		fill="none"
		xmlns="http://www.w3.org/2000/svg"
		{...restProps}
	>
		<!-- eslint-disable-next-line svelte/no-at-html-tags -->
		{@html svgContent}
	</svg>
{/if}
