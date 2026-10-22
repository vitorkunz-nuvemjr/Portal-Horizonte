<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { base } from '$app/paths';
	import type { Profile } from '$lib/types';
	import { getInitials } from '$lib/utils';
	import type { Snippet } from 'svelte';
	import Footer from '$lib/components/layout/Footer.svelte';

	interface Props {
		user: Profile;
		profiles?: Profile[];
		mode: 'local' | 'supabase';
		atRiskCount?: number;
		overallProgressPct?: number;
		children: Snippet;
	}

	let {
		user,
		profiles = [],
		mode,
		atRiskCount = 0,
		overallProgressPct = 64,
		children
	}: Props = $props();

	let showProfileMenu = $state(false);
	let globalSearch = $state($page.url.searchParams.get('q') ?? '');
	let sidebarPinned = $state(false);
	let sidebarHovered = $state(false);

	const isSidebarExpanded = $derived(sidebarPinned || sidebarHovered);

	$effect(() => {
		if (typeof window !== 'undefined') {
			const saved = localStorage.getItem('sidebar_pinned');
			if (saved !== null) {
				sidebarPinned = saved === 'true';
			}
		}
	});

	function togglePinSidebar() {
		sidebarPinned = !sidebarPinned;
		if (typeof window !== 'undefined') {
			localStorage.setItem('sidebar_pinned', String(sidebarPinned));
		}
	}

	let searchInputEl = $state<HTMLInputElement | null>(null);

	function handleKeydown(e: KeyboardEvent) {
		if ((e.ctrlKey || e.metaKey) && (e.key === 'b' || e.key === 'B')) {
			e.preventDefault();
			togglePinSidebar();
		}
		if ((e.ctrlKey || e.metaKey) && (e.key === 'k' || e.key === 'K')) {
			e.preventDefault();
			searchInputEl?.focus();
			searchInputEl?.select();
		}
	}

	const roleLabels: Record<Profile['role'], string> = {
		admin: 'Administrador',
		member: 'Membro',
		viewer: 'Visualizador'
	};

	const activeCycleLabel = $derived.by(() => {
		const yrs = $page.url.searchParams.get('years')?.split(',')[0] || '2026';
		const sems = $page.url.searchParams.get('semesters')?.split(',')[0] || '1';
		return `Ciclo ${yrs}-S${sems}`;
	});

	function handleGlobalSearch(e: Event) {
		const val = (e.currentTarget as HTMLInputElement).value;
		globalSearch = val;
		const url = new URL($page.url);
		if (!url.pathname.startsWith('/strategy')) {
			const target = new URL('/strategy', $page.url.origin);
			if (val.trim()) target.searchParams.set('q', val.trim());
			goto(target.toString(), { keepFocus: true, noScroll: true });
		} else {
			if (val.trim()) {
				url.searchParams.set('q', val.trim());
			} else {
				url.searchParams.delete('q');
			}
			goto(url.toString(), { replaceState: true, keepFocus: true, noScroll: true });
		}
	}

	function triggerQuickAction(action: 'objective' | 'kr') {
		const url = new URL('/strategy', $page.url.origin);
		// Preserve current filter params if already on /strategy
		if ($page.url.pathname.startsWith('/strategy')) {
			$page.url.searchParams.forEach((v, k) => url.searchParams.set(k, v));
		}
		url.searchParams.set('create', action);
		goto(url.toString(), { noScroll: true });
	}
</script>

<!-- Ambient Cutting Mat Grid Overlay -->
<div class="fixed inset-0 pointer-events-none z-0 mat-grid-pattern opacity-40"></div>

<!-- Top Fixed Header -->
<header
	class="fixed top-0 left-0 right-0 z-50 h-20 bg-surface-container-low/95 backdrop-blur-md shadow-[0_2px_12px_rgba(29,27,23,0.06)]"
>
	<!-- Top 4px Parchment Ruler Strip -->
	<div class="w-full h-1 bg-surface-variant mat-ruler-h"></div>

	<div class="w-full h-[76px] px-gutter flex items-center justify-between gap-space-md">
		<!-- Left: Brand -->
		<div class="flex items-center gap-space-md">
			<a href="/strategy" class="flex items-center gap-space-sm group">
				<div
					class="w-9 h-9 flex items-center justify-center overflow-hidden"
				>
					<img src="{base}/favicon.png" alt="Horizonte OKRs" class="w-full h-full object-contain scale-105" />
				</div>
				<div class="flex flex-col">
					<span
						class="font-label-md text-label-md tracking-wider text-on-surface font-bold"
					>
						Horizonte OKRs
					</span>
					<span
						class="font-label-sm text-label-sm text-on-surface-variant tracking-wide"
					>
						Planejamento Estratégico
					</span>
				</div>
			</a>
		</div>

		<!-- Center: Global Search -->
		<div class="flex-1 max-w-md mx-auto relative hidden md:block">
			<span
				class="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-on-surface-variant text-[18px] pointer-events-none"
			>
				search
			</span>
			<input
				bind:this={searchInputEl}
				type="search"
				value={$page.url.searchParams.get('q') ?? globalSearch}
				oninput={handleGlobalSearch}
				placeholder="Pesquisar OKRs, KRs ou tags..."
				class="w-full pl-10 pr-16 py-2 bg-surface-container rounded-lg font-body-sm text-body-sm text-on-surface placeholder:text-on-surface-variant shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:outline-none focus:ring-1 focus:ring-primary transition-all"
			/>
			<div
				class="absolute right-2.5 top-1/2 -translate-y-1/2 inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded bg-surface-container-high text-on-surface-variant font-label-sm text-[10px] shadow-[0_1px_1px_rgba(36,34,30,0.06)] pointer-events-none select-none font-semibold"
			>
				<span>Ctrl</span>
				<span>K</span>
			</div>
		</div>

		<!-- Right: Cycle Badge, Notifications, and User Profile -->
		<div class="flex items-center gap-space-sm">
			<div
				class="hidden sm:flex items-center gap-1.5 bg-surface-container px-3 py-1.5 rounded-full shadow-[inset_0_1px_2px_rgba(36,34,30,0.08)]"
			>
				<span class="w-2 h-2 rounded-full bg-tertiary-container"></span>
				<span class="font-label-sm text-label-sm text-on-surface font-bold tracking-wide uppercase">
					{activeCycleLabel}
				</span>
			</div>

			<a
				href="/dashboard"
				class="p-2 text-on-surface-variant hover:text-on-surface hover:bg-surface-container rounded-lg transition-colors relative"
				title={atRiskCount > 0
					? `${atRiskCount} itens em risco — Ver Ciclos & Métricas`
					: 'Notificações e Riscos'}
			>
				<span class="material-symbols-outlined text-[20px]">notifications</span>
				{#if atRiskCount > 0}
					<span class="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-secondary"></span>
				{/if}
			</a>

			<div class="relative flex items-center gap-space-xs pl-space-xs">
				<button
					type="button"
					onclick={() => (showProfileMenu = !showProfileMenu)}
					class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold text-white shadow-[0_1px_3px_rgba(29,27,23,0.15)] ring-2 ring-surface-container-lowest transition-transform active:scale-95"
					style="background-color: {user.color || '#0058bd'}"
					title="{user.name} ({roleLabels[user.role]})"
				>
					{getInitials(user.name)}
				</button>

				{#if showProfileMenu}
					<!-- svelte-ignore a11y_click_events_have_key_events -->
					<!-- svelte-ignore a11y_no_static_element_interactions -->
					<div
						class="fixed inset-0 z-40"
						onclick={() => (showProfileMenu = false)}
					></div>
					<div
						class="absolute right-0 top-full mt-2 w-72 rounded-xl bg-surface-container-lowest p-3 shadow-[0_16px_32px_rgba(36,34,30,0.14)] border border-outline-variant/40 z-50"
					>
						<div class="flex items-center justify-between gap-2 pb-2.5 border-b border-outline-variant/30">
							<div class="min-w-0">
								<div class="font-label-md text-label-md font-bold text-on-surface truncate">
									{user.name}
								</div>
								<div class="font-body-sm text-body-sm text-on-surface-variant truncate">
									{user.email || user.id}
								</div>
							</div>
							<span
								class="px-2 py-0.5 rounded-full bg-primary-fixed text-on-primary-fixed font-label-sm text-label-sm font-bold uppercase shrink-0"
							>
								{roleLabels[user.role]}
							</span>
						</div>

						<div class="mt-3 pt-2.5 border-t border-outline-variant/30 flex items-center justify-between">
							<span class="font-label-sm text-label-sm text-outline flex items-center gap-1.5">
								<span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
								Supabase Cloud
							</span>
							<form method="POST" action="/login?/logout">
								<button
									type="submit"
									class="px-2.5 py-1 rounded-lg bg-surface-container hover:bg-error-container hover:text-on-error-container font-label-sm text-label-sm font-bold text-on-surface transition-colors flex items-center gap-1"
								>
									<span class="material-symbols-outlined text-[14px]">logout</span>
									Sair
								</button>
							</form>
						</div>
					</div>
				{/if}
			</div>
		</div>
	</div>
</header>

<svelte:window onkeydown={handleKeydown} />

<!-- Left Sidebar (Collapsible Rail with Hover Expand & Pin) -->
<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
<aside
	id="main-sidebar"
	onmouseenter={() => (sidebarHovered = true)}
	onmouseleave={() => (sidebarHovered = false)}
	class="fixed left-0 top-20 bottom-0 z-40 hidden md:flex flex-col justify-between py-space-md bg-surface-container-low/95 backdrop-blur-md border-r border-outline-variant/40 shadow-[1px_0_12px_rgba(29,27,23,0.06)] transition-all duration-300 ease-in-out select-none {isSidebarExpanded
		? 'w-64'
		: 'w-16'}"
	aria-label="Barra Lateral de Navegação"
>
	<div class="flex flex-col gap-space-md {isSidebarExpanded ? 'px-space-md' : 'px-2'}">
		<!-- Pin / Collapse Control Header & Brand -->
		<div class="flex items-center {isSidebarExpanded ? 'justify-between px-1' : 'justify-center'} pb-2 border-b border-outline-variant/30 min-h-[40px]">
			<div class="flex items-center {isSidebarExpanded ? 'gap-2.5 min-w-0' : 'justify-center'}">
				<div class="w-7 h-7 flex items-center justify-center shrink-0" title="Nuvem Jr.">
					<img src="{base}/logo-nuvem.png" alt="Nuvem Jr." class="w-full h-full object-contain" />
				</div>
				{#if isSidebarExpanded}
					<span class="font-bold text-sm tracking-tight text-on-surface truncate">
						Nuvem Jr.
					</span>
				{/if}
			</div>

			{#if isSidebarExpanded}
				<button
					type="button"
					id="sidebar-pin-btn"
					onclick={togglePinSidebar}
					class="p-1.5 rounded-lg text-on-surface-variant hover:text-on-surface hover:bg-surface-container transition-all flex items-center justify-center shrink-0"
					title={sidebarPinned ? 'Desafixar barra lateral (Ctrl+B)' : 'Fixar barra lateral aberta (Ctrl+B)'}
					aria-label={sidebarPinned ? 'Desafixar barra lateral' : 'Fixar barra lateral aberta'}
					aria-expanded={sidebarPinned}
				>
					{#if sidebarPinned}
						<!-- Pinned icon -->
						<span class="material-symbols-outlined text-[18px] text-primary" style="font-variation-settings: 'FILL' 1;">
							keep
						</span>
					{:else}
						<!-- Unpinned icon -->
						<span class="material-symbols-outlined text-[18px]">
							keep_off
						</span>
					{/if}
				</button>
			{/if}
		</div>

		<!-- Navigation Links -->
		<nav class="flex flex-col gap-1">
			<a
				href="/strategy"
				class="flex items-center {isSidebarExpanded ? 'gap-3 px-3' : 'justify-center px-0'} py-2.5 rounded-lg font-body-sm text-body-sm transition-all {$page.url.pathname.startsWith(
					'/strategy'
				) && $page.url.searchParams.get('view') !== 'outline'
					? 'bg-surface-container-lowest text-primary font-semibold shadow-[0_1px_3px_rgba(36,34,30,0.06)]'
					: 'text-on-surface-variant hover:bg-surface-container hover:text-on-surface'}"
				title="Visão Holística"
			>
				<span class="material-symbols-outlined text-[20px] shrink-0">lan</span>
				{#if isSidebarExpanded}
					<span class="truncate">Visão Holística</span>
				{/if}
			</a>

			<a
				href="/dashboard"
				class="flex items-center {isSidebarExpanded ? 'justify-between px-3' : 'justify-center px-0'} py-2.5 rounded-lg font-body-sm text-body-sm transition-all {$page.url.pathname.startsWith(
					'/dashboard'
				)
					? 'bg-surface-container-lowest text-primary font-semibold shadow-[0_1px_3px_rgba(36,34,30,0.06)]'
					: 'text-on-surface-variant hover:bg-surface-container hover:text-on-surface'}"
				title="Metas & KPIs {atRiskCount > 0 ? `(${atRiskCount} em risco)` : ''}"
			>
				<span class="flex items-center gap-3 min-w-0">
					<span class="material-symbols-outlined text-[20px] shrink-0">query_stats</span>
					{#if isSidebarExpanded}
						<span class="truncate">Metas &amp; KPIs</span>
					{/if}
				</span>
				{#if atRiskCount > 0}
					<span
						class="px-1.5 py-0.2 rounded-full bg-secondary-fixed text-on-secondary-fixed-variant font-label-sm text-[10px] font-bold {isSidebarExpanded
							? ''
							: 'absolute top-1 right-1'}"
					>
						{atRiskCount}
					</span>
				{/if}
			</a>

			<a
				href="/identity"
				class="flex items-center {isSidebarExpanded ? 'gap-3 px-3' : 'justify-center px-0'} py-2.5 rounded-lg font-body-sm text-body-sm transition-all {$page.url.pathname.startsWith(
					'/identity'
				)
					? 'bg-surface-container-lowest text-primary font-semibold shadow-[0_1px_3px_rgba(36,34,30,0.06)]'
					: 'text-on-surface-variant hover:bg-surface-container hover:text-on-surface'}"
				title="Identidade & Eras"
			>
				<span class="material-symbols-outlined text-[20px] shrink-0">explore</span>
				{#if isSidebarExpanded}
					<span class="truncate">Identidade &amp; Eras</span>
				{/if}
			</a>

			<a
				href="/admin"
				class="flex items-center {isSidebarExpanded ? 'gap-3 px-3' : 'justify-center px-0'} py-2.5 rounded-lg font-body-sm text-body-sm transition-all {$page.url.pathname.startsWith(
					'/admin'
				)
					? 'bg-surface-container-lowest text-primary font-semibold shadow-[0_1px_3px_rgba(36,34,30,0.06)]'
					: 'text-on-surface-variant hover:bg-surface-container hover:text-on-surface'}"
				title="Equipes & Admin"
			>
				<span class="material-symbols-outlined text-[20px] shrink-0">groups</span>
				{#if isSidebarExpanded}
					<span class="truncate">Equipes &amp; Admin</span>
				{/if}
			</a>
		</nav>

		<div class="h-px bg-outline-variant/40 mx-1"></div>

		<!-- Quick Actions -->
		{#if isSidebarExpanded}
			<div class="flex flex-col gap-2">
				<span
					class="font-label-sm text-label-sm text-on-surface-variant uppercase tracking-widest px-1"
				>
					Ações Rápidas
				</span>
				<button
					type="button"
					onclick={() => triggerQuickAction('objective')}
					class="w-full flex items-center justify-center gap-2 py-2 px-3 bg-primary text-on-primary font-label-md text-label-md rounded-lg shadow-[0_2px_0_#004494] hover:brightness-105 active:translate-y-px transition-all"
				>
					<span class="material-symbols-outlined text-[18px]">add</span>
					<span>Novo Objetivo</span>
				</button>
				<button
					type="button"
					onclick={() => triggerQuickAction('kr')}
					class="w-full flex items-center justify-center gap-2 py-2 px-3 bg-secondary text-on-secondary font-label-md text-label-md rounded-lg shadow-[0_2px_0_#8d0051] hover:brightness-105 active:translate-y-px transition-all"
				>
					<span class="material-symbols-outlined text-[18px]">flag</span>
					<span>Vincular KR</span>
				</button>
			</div>
		{:else}
			<div class="flex flex-col items-center gap-2">
				<button
					type="button"
					onclick={() => triggerQuickAction('objective')}
					title="Novo Objetivo"
					class="w-10 h-10 flex items-center justify-center bg-primary text-on-primary rounded-lg shadow-[0_2px_0_#004494] hover:brightness-105 active:translate-y-px transition-all"
				>
					<span class="material-symbols-outlined text-[20px]">add</span>
				</button>
				<button
					type="button"
					onclick={() => triggerQuickAction('kr')}
					title="Vincular KR"
					class="w-10 h-10 flex items-center justify-center bg-secondary text-on-secondary rounded-lg shadow-[0_2px_0_#8d0051] hover:brightness-105 active:translate-y-px transition-all"
				>
					<span class="material-symbols-outlined text-[20px]">flag</span>
				</button>
			</div>
		{/if}
	</div>

	<!-- Bottom Sidebar: Active User & Cycle Status -->
	<div class="{isSidebarExpanded ? 'px-space-md' : 'px-2'} pt-space-sm flex flex-col gap-2.5">
		{#if isSidebarExpanded}
			<div class="px-2.5 py-2 rounded-xl bg-surface-container flex items-center gap-2.5 min-w-0 shadow-[inset_0_1px_2px_rgba(36,34,30,0.04)]">
				<div
					class="w-7 h-7 rounded-full flex items-center justify-center text-[11px] font-bold text-white shrink-0 shadow-xs"
					style="background-color: {user.color || '#0058bd'}"
				>
					{getInitials(user.name)}
				</div>
				<div class="flex flex-col min-w-0">
					<span class="font-label-sm text-label-sm font-bold text-on-surface truncate">
						{user.name}
					</span>
					<span class="font-label-sm text-[10px] text-on-surface-variant uppercase tracking-wider font-semibold">
						{roleLabels[user.role]}
					</span>
				</div>
			</div>
		{:else}
			<div class="flex items-center justify-center" title="{user.name} ({roleLabels[user.role]})">
				<div
					class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold text-white shadow-xs"
					style="background-color: {user.color || '#0058bd'}"
				>
					{getInitials(user.name)}
				</div>
			</div>
		{/if}

		{#if isSidebarExpanded}
			<div
				class="p-3 bg-surface-container rounded-xl shadow-[inset_0_1px_2px_rgba(36,34,30,0.05)] flex items-center justify-between"
			>
				<div class="flex flex-col min-w-0">
					<span class="font-label-sm text-label-sm text-on-surface-variant truncate">Status do Ciclo</span>
					<span class="font-label-md text-label-md font-bold text-on-surface">
						{overallProgressPct}% Concluído
					</span>
				</div>
				<span class="w-3 h-3 rounded-full bg-tertiary-fixed shadow-xs shrink-0"></span>
			</div>
		{:else}
			<div
				class="w-10 h-10 mx-auto bg-surface-container rounded-lg flex items-center justify-center shadow-[inset_0_1px_2px_rgba(36,34,30,0.05)]"
				title="Status do Ciclo: {overallProgressPct}% Concluído"
			>
				<span class="text-[11px] font-bold text-on-surface">{overallProgressPct}%</span>
			</div>
		{/if}
	</div>
</aside>

<!-- Main Content Container (Pushes content by 64px if pinned, or 16px if unpinned rail) -->
<div class="transition-all duration-300 ease-in-out {sidebarPinned ? 'md:pl-64' : 'md:pl-16'} relative flex flex-col min-h-screen">
	<main class="relative pt-20 flex-1 bg-transparent flex flex-col">
		{@render children()}
	</main>
	<Footer />
</div>
