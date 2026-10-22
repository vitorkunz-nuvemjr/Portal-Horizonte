<script lang="ts">
	import type { Profile, Team, Cycle } from '$lib/types';
	import { formatDate, downloadSnapshot } from '$lib/components/admin/admin-utils';

	let { data, form } = $props();

	// Active tab: 'teams' | 'members' | 'cycles' | 'backup'
	let activeTab = $state<'teams' | 'members' | 'cycles' | 'backup'>('teams');

	// Feedback dismiss state
	let dismissedFeedback = $state(false);

	$effect(() => {
		if (form) {
			dismissedFeedback = false;
		}
	});

	// Modals & popovers
	let activeTeamModal = $state<{
		mode: 'create' | 'edit';
		id: string;
		name: string;
		description: string;
		color: string;
		icon: string;
		memberIds: string[];
	} | null>(null);

	let teamToDelete = $state<Team | null>(null);
	let editingUserTeams = $state<Profile | null>(null);
	let cycleToDelete = $state<Cycle | null>(null);
	let showResetModal = $state(false);

	const isAdmin = $derived(data.user?.role === 'admin');

	// URL hash synchronization for deep linking (#equipes, #membros, #ciclos, #backup)
	$effect(() => {
		if (typeof window !== 'undefined') {
			const hash = window.location.hash.toLowerCase();
			if (hash.includes('membro') || hash.includes('permiss')) {
				activeTab = 'members';
			} else if (hash.includes('ciclo')) {
				activeTab = 'cycles';
			} else if (hash.includes('backup') || hash.includes('snapshot')) {
				activeTab = 'backup';
			} else if (hash.includes('equipe') || hash.includes('diretoria')) {
				activeTab = 'teams';
			}
		}
	});

	function setTab(tab: 'teams' | 'members' | 'cycles' | 'backup') {
		activeTab = tab;
		if (typeof window !== 'undefined') {
			const hash = tab === 'teams' ? 'equipes' : tab === 'members' ? 'membros' : tab === 'cycles' ? 'ciclos' : 'backup';
			window.history.replaceState(null, '', `#${hash}`);
		}
	}

	// Active cycle calculation
	const activeCycle = $derived.by(() => {
		if (!data.cycles || data.cycles.length === 0) return null;
		const now = new Date().toISOString().slice(0, 10);
		const current = data.cycles.find((c: Cycle) => c.start_date <= now && c.end_date >= now);
		return current || data.cycles.find((c: Cycle) => c.code.includes('2026')) || data.cycles[data.cycles.length - 1];
	});

	// KRs and metrics alignment metrics
	const krNodes = $derived(data.nodes?.filter((n: any) => n.type === 'key_result') ?? []);
	const krsWithMetrics = $derived(
		krNodes.filter((kr: any) => {
			const hasAssignee = data.assigns?.some((a: any) => a.node_id === kr.id);
			const hasValue = data.values?.some((v: any) => v.node_id === kr.id);
			const hasTeam = data.nodeTeams?.some((nt: any) => nt.node_id === kr.id);
			return hasAssignee || hasValue || hasTeam || kr.metric_target != null;
		})
	);
	const alignmentPct = $derived(
		krNodes.length > 0 ? Math.round((krsWithMetrics.length / krNodes.length) * 100) : 100
	);

	const adminCount = $derived(data.profiles?.filter((p: Profile) => p.role === 'admin').length ?? 0);

	// Separate departmental teams from cross-cutting / transversal team
	const transversalTeam = $derived(
		data.teams?.find((t: Team) =>
			t.name.toLowerCase().includes('todas') || t.name.toLowerCase().includes('geral')
		)
	);
	const departmentalTeams = $derived(
		data.teams?.filter((t: Team) => t.id !== transversalTeam?.id) ?? []
	);

	function handleDownload() {
		downloadSnapshot(data);
	}
</script>

<svelte:head>
	<title>Equipes & Administração | Horizonte OKRs</title>
</svelte:head>

<div class="p-4 sm:p-6 lg:p-8 relative min-h-[calc(100vh-80px)]">
	<div class="relative z-10 max-w-7xl mx-auto flex flex-col gap-5">
		<!-- 1. TOP HEADER SECTION -->
		<div class="flex flex-col sm:flex-row sm:items-end justify-between gap-space-md pb-space-xs">
			<div class="flex flex-col gap-space-xs max-w-3xl">
				<div class="flex items-center gap-space-xs">
					<span
						class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-surface-container-high text-primary font-label-sm text-label-sm uppercase tracking-wider shadow-sm"
					>
						Governança &amp; Acessos • Gestão de Equipes, Ciclos e Permissões
					</span>
				</div>
				<h1
					class="font-headline-xl text-headline-xl text-on-surface tracking-tight leading-tight"
				>
					Equipes &amp; Administração
				</h1>
				<p class="font-body-md text-body-md text-on-surface-variant">
					Central de acessos e gerenciamento de diretorias das OKRs da Nuvem Jr., permissões de membros,
					ciclos semestrais e backup.
				</p>
			</div>
			<button
				type="button"
				onclick={handleDownload}
				class="flex items-center gap-2 px-4 py-2 rounded-xl bg-[#f9f3ec] border border-[#d5cebe] text-[#1d1b17] hover:bg-[#ede7e0] active:translate-y-0.5 transition-all shadow-[0_1px_2px_rgba(0,0,0,0.05)] text-[12px] font-bold font-sans shrink-0 cursor-pointer"
				title="Exportar backup completo em JSON"
			>
				<span class="material-symbols-outlined text-[18px] text-[#004190]">cloud_download</span>
				<span>Exportar</span>
			</button>
		</div>

		<!-- FEEDBACK TOAST / BANNER (Apenas exibido em caso de erro ou atualização) -->
		{#if form?.message && !dismissedFeedback}
			<div class="flex items-center justify-between px-4 py-3 bg-[#fee2e2] border border-[#fca5a5] text-[#991b1b] rounded-xl shadow-[0_1px_3px_rgba(153,27,27,0.05)]">
				<div class="flex items-center gap-2.5">
					<span class="material-symbols-outlined text-[18px] text-[#dc2626]">error</span>
					<span class="text-[12.5px] font-medium font-sans">{form.message}</span>
				</div>
				<button
					type="button"
					class="p-1 rounded-md hover:bg-[#991b1b]/10 text-[#991b1b] transition-colors cursor-pointer"
					onclick={() => (dismissedFeedback = true)}
					title="Dispensar aviso"
				>
					<span class="material-symbols-outlined text-[16px]">close</span>
				</button>
			</div>
		{/if}

		{#if form?.notice && !dismissedFeedback}
			<div class="flex items-center justify-between px-4 py-3 bg-[#e8f8ee] border border-[#a7f3d0] text-[#14532d] rounded-xl shadow-[0_1px_3px_rgba(20,83,45,0.04)]" id="status-toast">
				<div class="flex items-center gap-2.5">
					<span class="w-5 h-5 rounded-full bg-[#14532d]/15 text-[#14532d] flex items-center justify-center font-bold text-[13px]">✓</span>
					<span class="text-[12.5px] font-medium font-sans">{form.notice}</span>
				</div>
				<button
					type="button"
					class="p-1 rounded-md hover:bg-[#14532d]/10 text-[#14532d] transition-colors cursor-pointer"
					onclick={() => (dismissedFeedback = true)}
					title="Dispensar aviso"
				>
					<span class="material-symbols-outlined text-[16px]">close</span>
				</button>
			</div>
		{/if}

		{#if !isAdmin}
			<div class="flex items-center gap-2.5 rounded-xl border border-[#fed7aa] bg-[#fff7ed] px-4 py-3 text-[12.5px] text-[#9a3412]">
				<span class="material-symbols-outlined text-[18px] text-[#ea580c]">info</span>
				<span>
					Você está navegando como <strong>{data.user?.role === 'member' ? 'Membro' : 'Visualizador'}</strong>. Para gerenciar equipes, ciclos ou permissões, faça login com uma conta de <strong>Administrador</strong>.
				</span>
			</div>
		{/if}

		<!-- 2. FOUR KPI SUMMARY CARDS -->
		<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
			<!-- Card 1: Total de Equipes -->
			<div class="bg-white border border-[#e8e2d8] rounded-xl p-4 shadow-[0_2px_6px_rgba(36,34,30,0.04)] flex items-start justify-between">
				<div class="flex flex-col">
					<span class="text-[10px] font-bold uppercase tracking-wider text-[#727784] font-mono">TOTAL DE EQUIPES</span>
					<div class="flex items-baseline gap-2 mt-1">
						<span class="text-2xl font-black text-[#1d1b17] font-display">{data.teams?.length ?? 0}</span>
						<span class="text-[11px] font-bold text-[#004190]">{departmentalTeams.length} Ativas</span>
					</div>
					<span class="text-[11px] text-[#727784] font-sans mt-0.5">1 Equipe Geral</span>
				</div>
				<div class="w-9 h-9 rounded-lg bg-[#d8e2ff]/50 text-[#004190] flex items-center justify-center shrink-0">
					<span class="material-symbols-outlined text-[20px]">corporate_fare</span>
				</div>
			</div>

			<!-- Card 2: Membros Ativos -->
			<div class="bg-white border border-[#e8e2d8] rounded-xl p-4 shadow-[0_2px_6px_rgba(36,34,30,0.04)] flex items-start justify-between">
				<div class="flex flex-col">
					<span class="text-[10px] font-bold uppercase tracking-wider text-[#727784] font-mono">MEMBROS ATIVOS</span>
					<div class="flex items-baseline gap-2 mt-1">
						<span class="text-2xl font-black text-[#1d1b17] font-display">{data.profiles?.length ?? 0}</span>
						<span class="text-[11px] font-bold text-[#14532d]">Membros</span>
					</div>
					<span class="text-[11px] text-[#727784] font-sans mt-0.5">{adminCount} {adminCount === 1 ? 'Administrador' : 'Administradores'}</span>
				</div>
				<div class="w-9 h-9 rounded-lg bg-[#ffd9e4]/60 text-[#b7076c] flex items-center justify-center shrink-0">
					<span class="material-symbols-outlined text-[20px]">groups</span>
				</div>
			</div>

			<!-- Card 3: Ciclo Vigente -->
			<div class="bg-white border border-[#e8e2d8] rounded-xl p-4 shadow-[0_2px_6px_rgba(36,34,30,0.04)] flex items-start justify-between">
				<div class="flex flex-col">
					<span class="text-[10px] font-bold uppercase tracking-wider text-[#727784] font-mono">CICLO VIGENTE</span>
					<div class="flex items-center gap-2 mt-1">
						<span class="text-xl font-black text-[#1d1b17] font-display">{activeCycle?.code ?? '2026-S1'}</span>
						<span class="text-[9px] font-bold uppercase px-1.5 py-0.5 rounded bg-[#fef9c3] text-[#78350f] border border-[#fef08a]">ATIVO</span>
					</div>
					<span class="text-[11px] text-[#727784] font-sans mt-0.5">
						{formatDate(activeCycle?.start_date)} → {formatDate(activeCycle?.end_date)}
					</span>
				</div>
				<div class="w-9 h-9 rounded-lg bg-[#ffe327]/30 text-[#78350f] flex items-center justify-center shrink-0">
					<span class="material-symbols-outlined text-[20px]">calendar_month</span>
				</div>
			</div>

			<!-- Card 4: Alinhamento de KRs -->
			<div class="bg-white border border-[#e8e2d8] rounded-xl p-4 shadow-[0_2px_6px_rgba(36,34,30,0.04)] flex items-start justify-between">
				<div class="flex flex-col">
					<span class="text-[10px] font-bold uppercase tracking-wider text-[#727784] font-mono">ALINHAMENTO DE KRS</span>
					<div class="flex items-baseline gap-2 mt-1">
						<span class="text-2xl font-black text-[#1d1b17] font-display">{alignmentPct}%</span>
						<span class="text-[11px] font-bold text-[#14532d]">{krsWithMetrics.length}/{krNodes.length || 32} KRs</span>
					</div>
					<span class="text-[11px] text-[#727784] font-sans mt-0.5">Todos os KRs com indicadores vinculados</span>
				</div>
				<div class="w-9 h-9 rounded-lg bg-[#dcfce7] text-[#14532d] flex items-center justify-center shrink-0">
					<span class="material-symbols-outlined text-[20px]">track_changes</span>
				</div>
			</div>
		</div>

		<!-- 3. PHYSICAL FILING FOLDER TABS SYSTEM -->
		<div class="mt-3 flex flex-col">
			<!-- Tabs Strip -->
			<div class="flex items-end gap-1.5 px-3 sm:px-6 overflow-x-auto no-scrollbar relative z-20 -mb-[1px]">
				<!-- Tab 1: Equipes & Diretorias -->
				{#if activeTab === 'teams'}
					<button
						type="button"
						class="group relative flex items-center gap-2.5 px-5 py-3 rounded-t-2xl bg-white border-t-2 border-t-[#0058bd] border-x border-[#d5cebe] text-[#004190] font-bold text-[13px] shadow-[-2px_-2px_6px_rgba(0,0,0,0.03)] cursor-default transition-all select-none"
					>
						<span class="w-2.5 h-2.5 rounded-full bg-[#004190]"></span>
						<span class="material-symbols-outlined text-[19px] text-[#004190]" style="font-variation-settings: 'FILL' 1;">corporate_fare</span>
						<span class="tracking-tight font-sans whitespace-nowrap text-[#004190]">1. Equipes &amp; Diretorias</span>
						<span class="text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-[#d8e2ff] text-[#004494]">{data.teams?.length ?? 0}</span>
						<span class="absolute -bottom-1 left-0 right-0 h-2 bg-white"></span>
					</button>
				{:else}
					<button
						type="button"
						onclick={() => setTab('teams')}
						class="group relative flex items-center gap-2 px-4 py-2.5 rounded-t-xl bg-[#ede7e0]/80 hover:bg-[#ede3d8] border-t border-x border-[#d5cebe] text-[#1d1b17] font-medium text-[13px] transition-all whitespace-nowrap cursor-pointer select-none"
					>
						<span class="material-symbols-outlined text-[18px] text-[#004190] group-hover:scale-110 transition-transform">corporate_fare</span>
						<span class="font-sans text-[#1d1b17] font-semibold">1. Equipes &amp; Diretorias</span>
						<span class="text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-[#e8e2db] text-[#424753]">{data.teams?.length ?? 0}</span>
					</button>
				{/if}

				<!-- Tab 2: Membros & Permissões -->
				{#if activeTab === 'members'}
					<button
						type="button"
						class="group relative flex items-center gap-2.5 px-5 py-3 rounded-t-2xl bg-white border-t-2 border-t-[#0058bd] border-x border-[#d5cebe] text-[#004190] font-bold text-[13px] shadow-[-2px_-2px_6px_rgba(0,0,0,0.03)] cursor-default transition-all select-none"
					>
						<span class="w-2.5 h-2.5 rounded-full bg-[#004190]"></span>
						<span class="material-symbols-outlined text-[19px] text-[#004190]" style="font-variation-settings: 'FILL' 1;">badge</span>
						<span class="tracking-tight font-sans whitespace-nowrap text-[#004190]">2. Membros &amp; Permissões</span>
						<span class="text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-[#d8e2ff] text-[#004494]">{data.profiles?.length ?? 0}</span>
						<span class="absolute -bottom-1 left-0 right-0 h-2 bg-white"></span>
					</button>
				{:else}
					<button
						type="button"
						onclick={() => setTab('members')}
						class="group relative flex items-center gap-2 px-4 py-2.5 rounded-t-xl bg-[#ede7e0]/80 hover:bg-[#ede3d8] border-t border-x border-[#d5cebe] text-[#1d1b17] font-medium text-[13px] transition-all whitespace-nowrap cursor-pointer select-none"
					>
						<span class="material-symbols-outlined text-[18px] text-[#004190] group-hover:scale-110 transition-transform">badge</span>
						<span class="font-sans text-[#1d1b17] font-semibold">2. Membros &amp; Permissões</span>
						<span class="text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-[#e8e2db] text-[#424753]">{data.profiles?.length ?? 0}</span>
					</button>
				{/if}

				<!-- Tab 3: Ciclos Semestrais -->
				{#if activeTab === 'cycles'}
					<button
						type="button"
						class="group relative flex items-center gap-2.5 px-5 py-3 rounded-t-2xl bg-white border-t-2 border-t-amber-600 border-x border-[#d5cebe] text-amber-700 font-bold text-[13px] shadow-[-2px_-2px_6px_rgba(0,0,0,0.03)] cursor-default transition-all select-none"
					>
						<span class="w-2.5 h-2.5 rounded-full bg-amber-600"></span>
						<span class="material-symbols-outlined text-[19px] text-amber-600" style="font-variation-settings: 'FILL' 1;">calendar_month</span>
						<span class="tracking-tight font-sans whitespace-nowrap text-amber-800">3. Ciclos Semestrais</span>
						<span class="text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-amber-100 text-amber-900">{data.cycles?.length ?? 0}</span>
						<span class="absolute -bottom-1 left-0 right-0 h-2 bg-white"></span>
					</button>
				{:else}
					<button
						type="button"
						onclick={() => setTab('cycles')}
						class="group relative flex items-center gap-2 px-4 py-2.5 rounded-t-xl bg-[#ede7e0]/80 hover:bg-[#ede3d8] border-t border-x border-[#d5cebe] text-[#1d1b17] font-medium text-[13px] transition-all whitespace-nowrap cursor-pointer select-none"
					>
						<span class="material-symbols-outlined text-[18px] text-amber-600 group-hover:scale-110 transition-transform">calendar_month</span>
						<span class="font-sans text-[#1d1b17] font-semibold">3. Ciclos Semestrais</span>
						<span class="text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-[#e8e2db] text-[#424753]">{data.cycles?.length ?? 0}</span>
					</button>
				{/if}

				<!-- Tab 4: Gestão de Snapshot & Backup EJ -->
				{#if activeTab === 'backup'}
					<button
						type="button"
						class="group relative flex items-center gap-2.5 px-5 py-3 rounded-t-2xl bg-white border-t-2 border-t-[#b7076c] border-x border-[#d5cebe] text-[#b7076c] font-bold text-[13px] shadow-[-2px_-2px_6px_rgba(0,0,0,0.03)] cursor-default transition-all select-none"
					>
						<span class="w-2.5 h-2.5 rounded-full bg-[#b7076c]"></span>
						<span class="material-symbols-outlined text-[19px] text-[#b7076c]" style="font-variation-settings: 'FILL' 1;">folder_zip</span>
						<span class="tracking-tight font-sans whitespace-nowrap text-[#b7076c]">4. Gestão de Snapshot &amp; Backup EJ</span>
						<span class="absolute -bottom-1 left-0 right-0 h-2 bg-white"></span>
					</button>
				{:else}
					<button
						type="button"
						onclick={() => setTab('backup')}
						class="group relative flex items-center gap-2 px-4 py-2.5 rounded-t-xl bg-[#ede7e0]/80 hover:bg-[#ede3d8] border-t border-x border-[#d5cebe] text-[#1d1b17] font-medium text-[13px] transition-all whitespace-nowrap cursor-pointer select-none"
					>
						<span class="material-symbols-outlined text-[18px] text-[#b7076c] group-hover:scale-110 transition-transform">folder_zip</span>
						<span class="font-sans text-[#1d1b17] font-semibold">4. Gestão de Snapshot &amp; Backup EJ</span>
					</button>
				{/if}
			</div>

			<!-- 4. MAIN FOLDER BODY WITH LAZY-LOADED TABS -->
			<div class="relative z-10 bg-white border border-[#d5cebe] rounded-2xl rounded-tl-none p-6 sm:p-7 shadow-[0_4px_16px_rgba(36,34,30,0.06)] flex flex-col gap-6 min-h-[420px]">
				{#if activeTab === 'teams'}
					{#await import('$lib/components/admin/AdminTeamsTab.svelte')}
						<div class="p-12 text-center text-[#727784] font-sans flex flex-col items-center justify-center gap-3 animate-pulse">
							<span class="material-symbols-outlined text-[32px] text-[#004190]">apartment</span>
							<span class="text-sm font-semibold">Carregando painel de equipes...</span>
						</div>
					{:then { default: AdminTeamsTab }}
						<AdminTeamsTab
							{data}
							{isAdmin}
							bind:activeTeamModal
							bind:teamToDelete
						/>
					{/await}
				{:else if activeTab === 'members'}
					{#await import('$lib/components/admin/AdminMembersTab.svelte')}
						<div class="p-12 text-center text-[#727784] font-sans flex flex-col items-center justify-center gap-3 animate-pulse">
							<span class="material-symbols-outlined text-[32px] text-[#004190]">badge</span>
							<span class="text-sm font-semibold">Carregando membros e permissões...</span>
						</div>
					{:then { default: AdminMembersTab }}
						<AdminMembersTab
							{data}
							{isAdmin}
							bind:editingUserTeams
						/>
					{/await}
				{:else if activeTab === 'cycles'}
					{#await import('$lib/components/admin/AdminCyclesTab.svelte')}
						<div class="p-12 text-center text-[#727784] font-sans flex flex-col items-center justify-center gap-3 animate-pulse">
							<span class="material-symbols-outlined text-[32px] text-amber-600">calendar_month</span>
							<span class="text-sm font-semibold">Carregando ciclos semestrais...</span>
						</div>
					{:then { default: AdminCyclesTab }}
						<AdminCyclesTab
							{data}
							{isAdmin}
							bind:cycleToDelete
						/>
					{/await}
				{:else if activeTab === 'backup'}
					{#await import('$lib/components/admin/AdminBackupTab.svelte')}
						<div class="p-12 text-center text-[#727784] font-sans flex flex-col items-center justify-center gap-3 animate-pulse">
							<span class="material-symbols-outlined text-[32px] text-[#b7076c]">folder_zip</span>
							<span class="text-sm font-semibold">Carregando gestão de backup...</span>
						</div>
					{:then { default: AdminBackupTab }}
						<AdminBackupTab
							{data}
							{isAdmin}
							bind:showResetModal
						/>
					{/await}
				{/if}
			</div>
		</div>
	</div>
</div>

<!-- LAZY-LOADED MODALS -->
{#if activeTeamModal}
	{#await import('$lib/components/admin/AdminTeamModal.svelte') then { default: AdminTeamModal }}
		<AdminTeamModal
			{data}
			bind:activeTeamModal
			bind:teamToDelete
		/>
	{/await}
{/if}

{#if editingUserTeams}
	{#await import('$lib/components/admin/AdminUserTeamsModal.svelte') then { default: AdminUserTeamsModal }}
		<AdminUserTeamsModal
			{data}
			bind:editingUserTeams
		/>
	{/await}
{/if}

{#if teamToDelete || cycleToDelete || showResetModal}
	{#await import('$lib/components/admin/AdminConfirmModals.svelte') then { default: AdminConfirmModals }}
		<AdminConfirmModals
			bind:teamToDelete
			bind:cycleToDelete
			bind:showResetModal
		/>
	{/await}
{/if}
