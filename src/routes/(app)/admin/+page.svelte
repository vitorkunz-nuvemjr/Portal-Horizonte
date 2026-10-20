<script lang="ts">
	import { enhanceFormValidation, getInitials } from '$lib/utils';
	import { getDossierTheme } from '$lib/dossier-theme';
	import PaperColorPicker from '$lib/components/ui/PaperColorPicker.svelte';
	import type { Profile, Team, Cycle } from '$lib/types';

	let { data, form } = $props();

	// Active tab: 'teams' | 'members' | 'cycles' | 'backup'
	let activeTab = $state<'teams' | 'members' | 'cycles' | 'backup'>('teams');

	// Banner dismiss state
	let showBanner = $state(true);

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

	let showAddMemberDropdown = $state(false);
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

	// Format date from YYYY-MM-DD to DD/MM/YYYY
	function formatDate(iso: string | null | undefined): string {
		if (!iso) return '—';
		const parts = iso.split('-');
		if (parts.length === 3) {
			return `${parts[2]}/${parts[1]}/${parts[0]}`;
		}
		return iso;
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

	const adminCount = $derived(data.profiles.filter((p: Profile) => p.role === 'admin').length);

	// Separate departmental teams from cross-cutting / transversal team
	const transversalTeam = $derived(
		data.teams.find((t: Team) =>
			t.name.toLowerCase().includes('todas') || t.name.toLowerCase().includes('geral')
		)
	);
	const departmentalTeams = $derived(
		data.teams.filter((t: Team) => t.id !== transversalTeam?.id)
	);

	function getUserTeams(userId: string): Team[] {
		const tids = (data.teamMembers ?? [])
			.filter((tm: any) => tm.user_id === userId)
			.map((tm: any) => tm.team_id);
		return data.teams.filter((t: Team) => tids.includes(t.id));
	}

	function getTeamMembers(teamId: string): Profile[] {
		const uids = (data.teamMembers ?? [])
			.filter((tm: any) => tm.team_id === teamId)
			.map((tm: any) => tm.user_id);
		return data.profiles.filter((p: Profile) => uids.includes(p.id));
	}

	// Visual theme mappings matching the Paper Strategist design system with muted tones
	function getTeamVisual(name: string, fallbackColor?: string | null) {
		const n = (name || '').toLowerCase();
		let icon = 'apartment';
		let defaultHex = '#0058bd';

		if (n.includes('presid') || n.includes('governan') || n.includes('institu')) {
			icon = 'account_balance';
			defaultHex = '#0058bd';
		} else if (n.includes('finan') || n.includes('adm') || n.includes('juríd') || n.includes('jurid')) {
			icon = 'payments';
			defaultHex = '#0284c7';
		} else if (n.includes('comerc') || n.includes('venda')) {
			icon = 'storefront';
			defaultHex = '#059669';
		} else if (n.includes('market') || n.includes('mkt') || n.includes('comunic')) {
			icon = 'campaign';
			defaultHex = '#ea580c';
		} else if (n.includes('projet') || n.includes('dev') || n.includes('consult')) {
			icon = 'rocket_launch';
			defaultHex = '#7c3aed';
		} else if (n.includes('pesso') || n.includes('gp') || n.includes('gente') || n.includes('rh')) {
			icon = 'groups';
			defaultHex = '#ca8a04';
		} else if (n.includes('todas') || n.includes('geral')) {
			icon = 'hub';
			defaultHex = '#ca8a04';
		}

		const activeHex = fallbackColor && fallbackColor.trim() ? fallbackColor : defaultHex;
		const theme = getDossierTheme(activeHex);

		return {
			icon,
			theme,
			iconColor: theme.accent,
			bgStyle: `background-color: ${theme.folderBg}; border-color: ${theme.folderBorder};`,
			pillStyle: `background-color: ${theme.badgeBg}; border-color: ${theme.badgeBorder}; color: ${theme.badgeText};`,
			dotColor: theme.accent
		};
	}

	function downloadSnapshot() {
		const blob = new Blob([data.snapshotJson], { type: 'application/json' });
		const url = URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = `horizonte-okrs-export-${new Date().toISOString().slice(0, 10)}.json`;
		a.click();
		URL.revokeObjectURL(url);
	}

	function openUserTeamsModal(prof: Profile) {
		editingUserTeams = prof;
	}

	// Preset colors matching the classic suspension file folder design
	const modalColorPresets = [
		{ hex: '#059669', name: 'Verde Esmeralda' },
		{ hex: '#0058bd', name: 'Azul Estratégico' },
		{ hex: '#b7076c', name: 'Magenta' },
		{ hex: '#ca8a04', name: 'Âmbar' },
		{ hex: '#7c3aed', name: 'Violeta' },
		{ hex: '#0284c7', name: 'Ciano' }
	];

	// Team icons selectable in modal
	const teamIcons = [
		{ name: 'storefront', label: 'Storefront', desc: 'Comercial' },
		{ name: 'handshake', label: 'Handshake', desc: 'Parcerias' },
		{ name: 'trending_up', label: 'Trending Up', desc: 'Vendas' },
		{ name: 'campaign', label: 'Campaign', desc: 'Marketing' },
		{ name: 'groups', label: 'Groups', desc: 'Pessoas' },
		{ name: 'rocket_launch', label: 'Rocket Launch', desc: 'Projetos' },
		{ name: 'account_balance', label: 'Account Balance', desc: 'Presidência' },
		{ name: 'payments', label: 'Payments', desc: 'Financeiro' },
		{ name: 'hub', label: 'Hub', desc: 'Transversal' }
	];

	// Dynamic soft-tone theme generator: the modal color is a softer tone of the selected team color
	interface ModalTheme {
		folderBg: string;
		folderBorder: string;
		footerBg: string;
		stitchedColor: string;
		cardBorder: string;
		inputBg: string;
		inputBorder: string;
		accent: string;
		accentDark: string;
		accentShadow: string;
		badgeBg: string;
		badgeText: string;
		badgeBorder: string;
	}

	function getModalTheme(color: string): ModalTheme {
		const c = (color || '#059669').toLowerCase();

		if (c.includes('059669') || c.includes('10b981') || c.includes('14532d') || c.includes('15803d') || c.includes('16a34a')) {
			return {
				folderBg: '#e8efe8',
				folderBorder: '#b9cebc',
				footerBg: '#ddeade',
				stitchedColor: '#b4c8b7',
				cardBorder: '#cbe0ce',
				inputBg: '#f8fbf8',
				inputBorder: '#aed5b3',
				accent: '#059669',
				accentDark: '#14532d',
				accentShadow: '#065f46',
				badgeBg: '#dcfce7',
				badgeText: '#14532d',
				badgeBorder: '#a7f3d0'
			};
		}
		if (c.includes('0058bd') || c.includes('004190') || c.includes('2563eb') || c.includes('3b82f6') || c.includes('1d4ed8')) {
			return {
				folderBg: '#e8f0fe',
				folderBorder: '#b5ccf5',
				footerBg: '#dbe7fb',
				stitchedColor: '#a6c3ef',
				cardBorder: '#c8daf7',
				inputBg: '#f8faff',
				inputBorder: '#adc6ff',
				accent: '#0058bd',
				accentDark: '#002b66',
				accentShadow: '#00204d',
				badgeBg: '#d8e2ff',
				badgeText: '#004494',
				badgeBorder: '#adc6ff'
			};
		}
		if (c.includes('b7076c') || c.includes('db2777') || c.includes('ec4899') || c.includes('f43f5e') || c.includes('f52a95')) {
			return {
				folderBg: '#fdf0f5',
				folderBorder: '#f5c2d8',
				footerBg: '#f7e1ec',
				stitchedColor: '#eeb4cb',
				cardBorder: '#f8d4e4',
				inputBg: '#fffbfd',
				inputBorder: '#f9a8d4',
				accent: '#b7076c',
				accentDark: '#700442',
				accentShadow: '#570334',
				badgeBg: '#ffd9e4',
				badgeText: '#8d0051',
				badgeBorder: '#f9a8d4'
			};
		}
		if (c.includes('ca8a04') || c.includes('d97706') || c.includes('f59e0b') || c.includes('b45309') || c.includes('eab308')) {
			return {
				folderBg: '#fcf6e8',
				folderBorder: '#ebd6a5',
				footerBg: '#f5ebd2',
				stitchedColor: '#dec58d',
				cardBorder: '#f2e2be',
				inputBg: '#fffdf7',
				inputBorder: '#fde68a',
				accent: '#ca8a04',
				accentDark: '#713f12',
				accentShadow: '#58310d',
				badgeBg: '#fef9c3',
				badgeText: '#854d0e',
				badgeBorder: '#fde047'
			};
		}
		if (c.includes('7c3aed') || c.includes('8b5cf6') || c.includes('6d28d9') || c.includes('9333ea') || c.includes('a855f7')) {
			return {
				folderBg: '#f4f0fd',
				folderBorder: '#d4c2f7',
				footerBg: '#eae0fb',
				stitchedColor: '#c6aff0',
				cardBorder: '#dfd2f9',
				inputBg: '#fbf9ff',
				inputBorder: '#c4b5fd',
				accent: '#7c3aed',
				accentDark: '#4c1d95',
				accentShadow: '#3b0764',
				badgeBg: '#ede9fe',
				badgeText: '#5b21b6',
				badgeBorder: '#ddd6fe'
			};
		}
		if (c.includes('0284c7') || c.includes('0891b2') || c.includes('06b6d4') || c.includes('0369a1') || c.includes('0ea5e9')) {
			return {
				folderBg: '#eaf5f8',
				folderBorder: '#b4deea',
				footerBg: '#dbeff4',
				stitchedColor: '#a0d1de',
				cardBorder: '#c5e6ef',
				inputBg: '#f7fcfd',
				inputBorder: '#bae6fd',
				accent: '#0284c7',
				accentDark: '#0369a1',
				accentShadow: '#075985',
				badgeBg: '#e0f2fe',
				badgeText: '#0369a1',
				badgeBorder: '#bae6fd'
			};
		}
		if (c.includes('ea580c') || c.includes('f97316') || c.includes('c2410c')) {
			return {
				folderBg: '#fef3ec',
				folderBorder: '#fed0b3',
				footerBg: '#fbe6d8',
				stitchedColor: '#f8be99',
				cardBorder: '#feddc7',
				inputBg: '#fffbf9',
				inputBorder: '#fdba74',
				accent: '#ea580c',
				accentDark: '#9a3412',
				accentShadow: '#7c2d12',
				badgeBg: '#ffedd5',
				badgeText: '#9a3412',
				badgeBorder: '#fed7aa'
			};
		}

		// Fallback for custom hex
		return {
			folderBg: `color-mix(in srgb, ${c} 12%, #fff8f2)`,
			folderBorder: `color-mix(in srgb, ${c} 30%, #d5cebe)`,
			footerBg: `color-mix(in srgb, ${c} 18%, #fff8f2)`,
			stitchedColor: `color-mix(in srgb, ${c} 35%, #b4c8b7)`,
			cardBorder: `color-mix(in srgb, ${c} 22%, #e8e2d8)`,
			inputBg: `color-mix(in srgb, ${c} 5%, #ffffff)`,
			inputBorder: `color-mix(in srgb, ${c} 32%, #d5cebe)`,
			accent: c,
			accentDark: `color-mix(in srgb, ${c} 80%, #000000)`,
			accentShadow: `color-mix(in srgb, ${c} 70%, #000000)`,
			badgeBg: `color-mix(in srgb, ${c} 15%, #ffffff)`,
			badgeText: `color-mix(in srgb, ${c} 85%, #000000)`,
			badgeBorder: `color-mix(in srgb, ${c} 35%, #ffffff)`
		};
	}

	// Active modal theme derived from the currently chosen team color
	const modalTheme = $derived(
		activeTeamModal ? getDossierTheme(activeTeamModal.color) : getDossierTheme('#059669')
	);

	function openCreateTeamModal() {
		activeTeamModal = {
			mode: 'create',
			id: '',
			name: '',
			description: '',
			color: '#059669',
			icon: 'storefront',
			memberIds: []
		};
		showAddMemberDropdown = false;
	}

	function openEditTeamModal(team: Team) {
		const visual = getTeamVisual(team.name, team.color);
		const currentMemberIds = getTeamMembers(team.id).map((m) => m.id);
		activeTeamModal = {
			mode: 'edit',
			id: team.id,
			name: team.name,
			description: team.description ?? '',
			color: team.color || visual.dotColor,
			icon: visual.icon,
			memberIds: currentMemberIds
		};
		showAddMemberDropdown = false;
	}

	const teamIndex = $derived.by(() => {
		if (!activeTeamModal || !activeTeamModal.id) return '01';
		const idx = data.teams.findIndex((t: Team) => t.id === activeTeamModal!.id);
		return idx >= 0 ? String(idx + 1).padStart(2, '0') : '01';
	});

	// KRs associated with active modal team
	const modalTeamKRs = $derived.by(() => {
		if (!activeTeamModal || !activeTeamModal.id) return [];
		const directNodeIds = new Set(
			(data.nodeTeams ?? [])
				.filter((nt: any) => nt.team_id === activeTeamModal!.id)
				.map((nt: any) => nt.node_id)
		);

		return (data.nodes ?? []).filter((n: any) => {
			if (n.type !== 'key_result') return false;
			if (directNodeIds.has(n.id)) return true;
			if (n.parent_id && directNodeIds.has(n.parent_id)) return true;
			return false;
		});
	});

	function getKRProgress(kr: any): number {
		if (kr.manual_progress != null) return Math.round(kr.manual_progress * 100);
		if (kr.target_value && kr.current_value != null && kr.baseline != null && kr.target_value !== kr.baseline) {
			const raw = (kr.current_value - kr.baseline) / (kr.target_value - kr.baseline);
			return Math.round(Math.min(1, Math.max(0, raw)) * 100);
		}
		return 60;
	}

	function removeMemberFromModal(userId: string) {
		if (!activeTeamModal) return;
		activeTeamModal.memberIds = activeTeamModal.memberIds.filter((id) => id !== userId);
	}

	function addMemberToModal(userId: string) {
		if (!activeTeamModal) return;
		if (!activeTeamModal.memberIds.includes(userId)) {
			activeTeamModal.memberIds = [...activeTeamModal.memberIds, userId];
		}
		showAddMemberDropdown = false;
	}
</script>

<svelte:head>
	<title>Equipes & Administração | Horizonte OKRs</title>
</svelte:head>

<div class="p-4 sm:p-6 lg:p-8 relative min-h-[calc(100vh-80px)]">
	<div class="relative z-10 max-w-7xl mx-auto flex flex-col gap-5">
		<!-- 1. TOP HEADER SECTION -->
		<div class="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
			<div>
				<h1 class="text-2xl sm:text-3xl font-extrabold text-[#1d1b17] tracking-tight font-display">
					Equipes &amp; Administração
				</h1>
				<p class="text-[13px] text-[#424753] leading-relaxed font-sans mt-1 max-w-3xl">
					Central de acessos e gerenciamento de diretorias das OKRs da Nuvem Jr., permissões de membros, ciclos semestrais e backup.
				</p>
			</div>
			<button
				type="button"
				onclick={downloadSnapshot}
				class="self-start flex items-center gap-2 px-4 py-2 rounded-xl bg-[#f9f3ec] border border-[#d5cebe] text-[#1d1b17] hover:bg-[#ede7e0] active:translate-y-0.5 transition-all shadow-[0_1px_2px_rgba(0,0,0,0.05)] text-[12px] font-bold font-sans shrink-0 cursor-pointer"
				title="Exportar backup completo em JSON"
			>
				<span class="material-symbols-outlined text-[18px] text-[#004190]">cloud_download</span>
				<span>Exportar</span>
			</button>
		</div>

		<!-- FEEDBACK TOAST / BANNER -->
		{#if form?.message}
			<div class="flex items-center justify-between px-4 py-3 bg-[#fee2e2] border border-[#fca5a5] text-[#991b1b] rounded-xl shadow-[0_1px_3px_rgba(153,27,27,0.05)]">
				<div class="flex items-center gap-2.5">
					<span class="material-symbols-outlined text-[18px] text-[#dc2626]">error</span>
					<span class="text-[12.5px] font-medium font-sans">{form.message}</span>
				</div>
			</div>
		{/if}

		{#if form?.notice}
			<div class="flex items-center justify-between px-4 py-3 bg-[#e8f8ee] border border-[#a7f3d0] text-[#14532d] rounded-xl shadow-[0_1px_3px_rgba(20,83,45,0.04)]">
				<div class="flex items-center gap-2.5">
					<span class="w-5 h-5 rounded-full bg-[#14532d]/15 text-[#14532d] flex items-center justify-center font-bold text-[13px]">✓</span>
					<span class="text-[12.5px] font-medium font-sans">{form.notice}</span>
				</div>
			</div>
		{:else if showBanner}
			<!-- Default synchronization status alert banner -->
			<div class="flex items-center justify-between px-4 py-3 bg-[#e8f8ee] border border-[#a7f3d0] text-[#14532d] rounded-xl shadow-[0_1px_3px_rgba(20,83,45,0.04)]" id="status-toast">
				<div class="flex items-center gap-2.5">
					<span class="w-5 h-5 rounded-full bg-[#14532d]/15 text-[#14532d] flex items-center justify-center font-bold text-[13px]">✓</span>
					<span class="text-[12.5px] font-medium font-sans">
						Vínculos de equipes e parâmetros de governança atualizados e sincronizados com a nuvem.
					</span>
				</div>
				<button
					type="button"
					class="p-1 rounded-md hover:bg-[#14532d]/10 text-[#14532d] transition-colors cursor-pointer"
					onclick={() => (showBanner = false)}
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
						<span class="text-2xl font-black text-[#1d1b17] font-display">{data.teams.length}</span>
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
						<span class="text-2xl font-black text-[#1d1b17] font-display">{data.profiles.length}</span>
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
			<!-- Tabs Strip (Elevated, physical folder tab design) -->
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
						<span class="text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-[#d8e2ff] text-[#004494]">{data.teams.length}</span>
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
						<span class="text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-[#e8e2db] text-[#424753]">{data.teams.length}</span>
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
						<span class="text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-[#d8e2ff] text-[#004494]">{data.profiles.length}</span>
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
						<span class="text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-[#e8e2db] text-[#424753]">{data.profiles.length}</span>
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
						<span class="text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-amber-100 text-amber-900">{data.cycles.length}</span>
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
						<span class="text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-[#e8e2db] text-[#424753]">{data.cycles.length}</span>
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

			<!-- 4. MAIN FOLDER BODY -->
			<div class="relative z-10 bg-white border border-[#d5cebe] rounded-2xl rounded-tl-none p-6 sm:p-7 shadow-[0_4px_16px_rgba(36,34,30,0.06)] flex flex-col gap-6">
				<!-- ═══════════════════════════════════════════════════════════ -->
				<!-- TAB 1: EQUIPES & DIRETORIAS -->
				<!-- ═══════════════════════════════════════════════════════════ -->
				{#if activeTab === 'teams'}
					<!-- Folder Subheader -->
					<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-5 border-b border-[#f3ede6]">
						<div class="flex items-center gap-3.5">
							<div class="w-11 h-11 rounded-xl bg-[#004190]/10 text-[#004190] flex items-center justify-center shrink-0">
								<span class="material-symbols-outlined text-[24px]">apartment</span>
							</div>
							<div>
								<div class="flex items-center gap-2.5">
									<h2 class="text-lg font-bold text-[#1d1b17] font-display tracking-tight">Equipes &amp; Departamentos</h2>
									<span class="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-[#004190] text-white font-mono">
										{data.teams.length} cadastradas
									</span>
								</div>
								<p class="text-[12.5px] text-[#727784] font-sans mt-0.5">
									Controle de unidades organizacionais, responsáveis por objetivos estratégicos e KRs.
								</p>
							</div>
						</div>
						{#if isAdmin}
							<button
								type="button"
								onclick={openCreateTeamModal}
								class="flex items-center gap-2 px-4 py-2 rounded-lg bg-[#004190] text-white text-[12.5px] font-bold hover:bg-[#003375] shadow-[0_2px_0_#002b66] active:translate-y-0.5 transition-all w-fit font-sans shrink-0 cursor-pointer"
							>
								<span class="material-symbols-outlined text-[18px]">add</span>
								<span>Nova Equipe</span>
							</button>
						{/if}
					</div>

					<!-- Grid of Tactical Directory Cards -->
					<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
						{#each departmentalTeams as team (team.id)}
							{@const members = getTeamMembers(team.id)}
							{@const visual = getTeamVisual(team.name, team.color)}
							<div
								class="p-4 rounded-xl border transition-all flex flex-col justify-between group shadow-sm hover:shadow-md"
								style="{visual.bgStyle}"
							>
								<div>
									<div class="flex items-center justify-between mb-2">
										<div class="flex items-center gap-2 min-w-0">
											<span class="material-symbols-outlined text-[20px] shrink-0" style="color: {visual.iconColor};">{visual.icon}</span>
											<h3
												class="font-bold text-[14px] font-display truncate"
												style="color: {visual.theme.accentShadow};"
											>
												{team.name}
											</h3>
										</div>
										{#if isAdmin}
											<div class="flex items-center gap-1 opacity-75 group-hover:opacity-100 transition-opacity shrink-0">
												<button
													type="button"
													onclick={() => openEditTeamModal(team)}
													class="w-6 h-6 flex items-center justify-center rounded bg-white/75 hover:bg-white shadow-xs transition-colors cursor-pointer"
													style="color: {visual.theme.accentDark};"
													title="Editar Equipe"
												>
													<span class="material-symbols-outlined text-[15px]">edit</span>
												</button>
												<button
													type="button"
													onclick={() => (teamToDelete = team)}
													class="w-6 h-6 flex items-center justify-center rounded bg-white/75 hover:bg-red-50 hover:text-red-600 shadow-xs transition-colors cursor-pointer"
													style="color: {visual.theme.accentDark};"
													title="Excluir Equipe"
												>
													<span class="material-symbols-outlined text-[15px]">delete</span>
												</button>
											</div>
										{/if}
									</div>
									<p
										class="text-[12px] leading-relaxed mb-4 font-sans line-clamp-2 font-medium"
										style="color: {visual.theme.accentDark};"
									>
										{team.description || 'Unidade tática de execução e acompanhamento de OKRs.'}
									</p>
								</div>
								<div
									class="flex items-center justify-between pt-2 border-t border-dashed"
									style="border-color: {visual.theme.cardBorder};"
								>
									<div class="flex -space-x-1.5 overflow-hidden">
										{#each members.slice(0, 3) as mem (mem.id)}
											<div
												class="w-6 h-6 rounded-full text-white text-[10px] font-bold flex items-center justify-center ring-2 ring-white shrink-0 shadow-xs"
												style="background-color: {mem.color || visual.dotColor}"
												title="{mem.name}"
											>
												{getInitials(mem.name)}
											</div>
										{/each}
										{#if members.length > 3}
											<div
												class="w-6 h-6 rounded-full text-white text-[9px] font-bold flex items-center justify-center ring-2 ring-white shrink-0 shadow-xs"
												style="background-color: {visual.theme.accentDark};"
												title="{members.length - 3} outros membros"
											>
												+{members.length - 3}
											</div>
										{/if}
										{#if members.length === 0}
											<span class="text-[10px] italic" style="color: {visual.theme.accentDark};">Nenhum membro</span>
										{/if}
									</div>
									<span
										class="text-[11px] font-bold font-sans px-2 py-0.5 rounded-full border"
										style="{visual.pillStyle}"
									>
										{members.length} {members.length === 1 ? 'membro' : 'membros'}
									</span>
								</div>
							</div>
						{/each}
					</div>

					<!-- Wide Transversal Card at bottom: Todas as Diretorias (Geral) -->
					{@const transVisual = getTeamVisual(transversalTeam?.name || 'Todas as Diretorias (Geral)', transversalTeam?.color || '#ca8a04')}
					<div
						class="p-4 sm:p-5 rounded-xl border transition-all flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm hover:shadow-md"
						style="{transVisual.bgStyle}"
					>
						<div class="flex items-start md:items-center gap-3.5">
							<div
								class="w-10 h-10 rounded-lg bg-white border flex items-center justify-center shadow-xs shrink-0"
								style="border-color: {transVisual.theme.cardBorder}; color: {transVisual.iconColor};"
							>
								<span class="material-symbols-outlined text-[22px]">hub</span>
							</div>
							<div>
								<div class="flex flex-wrap items-center gap-2 mb-0.5">
									<span class="material-symbols-outlined text-[19px] shrink-0" style="color: {transVisual.iconColor};">lan</span>
									<h3
										class="font-bold text-[14px] font-display"
										style="color: {transVisual.theme.accentShadow};"
									>
										{transversalTeam?.name || 'Todas as Diretorias (Geral)'}
									</h3>
									<span
										class="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded border font-mono"
										style="{transVisual.pillStyle}"
									>
										EMPRESA INTEIRA
									</span>
								</div>
								<p
									class="text-[12px] font-sans font-medium"
									style="color: {transVisual.theme.accentDark};"
								>
									{transversalTeam?.description || 'Iniciativas transversais, metas de cultura macro, conselho e governança geral do ciclo.'}
								</p>
							</div>
						</div>
						<div class="flex items-center justify-between md:justify-end gap-4 shrink-0">
							<div class="flex items-center gap-2">
								<div class="flex -space-x-1.5 overflow-hidden">
									{#each data.profiles.slice(0, 4) as p (p.id)}
										<div
											class="w-6 h-6 rounded-full text-white text-[10px] font-bold flex items-center justify-center ring-2 ring-white shrink-0 shadow-xs"
											style="background-color: {p.color || '#004190'}"
											title="{p.name}"
										>
											{getInitials(p.name)}
										</div>
									{/each}
									{#if data.profiles.length > 4}
										<div class="w-6 h-6 rounded-full bg-[#0058bd] text-white text-[9px] font-bold flex items-center justify-center ring-2 ring-white shrink-0 shadow-xs">
											+{data.profiles.length - 4}
										</div>
									{/if}
								</div>
								<span class="text-[11px] font-semibold text-[#727784] font-sans">
									{data.profiles.length} membros totais
								</span>
							</div>
							<div class="flex items-center gap-1.5">
								{#if transversalTeam && isAdmin}
									<button
										type="button"
										onclick={() => openEditTeamModal(transversalTeam)}
										class="w-8 h-8 flex items-center justify-center rounded-lg bg-white border border-[#e8e2db] text-[#424753] hover:text-[#1d1b17] shadow-xs transition-colors cursor-pointer"
										title="Configurar Regras Transversais"
									>
										<span class="material-symbols-outlined text-[16px]">tune</span>
									</button>
								{:else}
									<div
										class="w-8 h-8 flex items-center justify-center rounded-lg bg-white border border-[#e8e2db] text-[#424753] shadow-xs"
										title="Regras Transversais"
									>
										<span class="material-symbols-outlined text-[16px]">tune</span>
									</div>
								{/if}
								<div
									class="w-8 h-8 flex items-center justify-center rounded-lg bg-white border border-[#e8e2db] text-[#727784] shadow-xs select-none"
									title="Colegiado Fixo com governança transversal do ciclo"
								>
									<span class="material-symbols-outlined text-[16px]">lock</span>
								</div>
							</div>
						</div>
					</div>
				{/if}

				<!-- ═══════════════════════════════════════════════════════════ -->
				<!-- TAB 2: MEMBROS & PERMISSÕES -->
				<!-- ═══════════════════════════════════════════════════════════ -->
				{#if activeTab === 'members'}
					<!-- Folder Subheader -->
					<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-5 border-b border-[#f3ede6]">
						<div>
							<div class="flex items-center gap-2.5">
								<div class="w-8 h-8 rounded-lg bg-[#d8e2ff] text-[#004190] flex items-center justify-center shrink-0">
									<span class="material-symbols-outlined text-[20px]" style="font-variation-settings: 'FILL' 1;">badge</span>
								</div>
								<h2 class="text-lg font-bold text-[#1d1b17] font-display">Membros Cadastrados &amp; Matriz de Permissões</h2>
							</div>
							<p class="text-[13px] text-[#727784] mt-1 pl-10">
								Controle de acessos operacionais por usuário: Administrador (acesso total), Membro (edição de KRs da equipe) e Visualizador.
							</p>
						</div>
						<div class="self-start sm:self-auto shrink-0">
							<span class="px-3 py-1.5 rounded-lg bg-[#f3ede6] border border-[#e8e2db] text-[12px] font-bold text-[#1d1b17] font-mono">
								Total de Membros: {data.profiles.length}
							</span>
						</div>
					</div>

					<!-- Members Table -->
					<div class="overflow-x-auto rounded-xl border border-[#e8e2d8]">
						<table class="w-full text-left border-collapse text-[13px]">
							<thead>
								<tr class="bg-[#fcfaf7] text-[#727784] text-[11px] font-bold uppercase tracking-wider border-b border-[#e8e2d8] font-mono">
									<th class="py-3 px-5">MEMBRO &amp; IDENTIFICAÇÃO</th>
									<th class="py-3 px-5">EQUIPE VINCULADA</th>
									<th class="py-3 px-5">NÍVEL DE ACESSO</th>
									<th class="py-3 px-5 text-right">AÇÕES</th>
								</tr>
							</thead>
							<tbody class="divide-y divide-[#f3ede6]">
								{#each data.profiles as prof (prof.id)}
									{@const userTeams = getUserTeams(prof.id)}
									{@const isCurrentUser = prof.id === data.user?.id || prof.email === data.user?.email}
									<tr class="hover:bg-[#fffbf7] transition-colors">
										<!-- Column 1: Member Identification -->
										<td class="py-4 px-5">
											<div class="flex items-center gap-3">
												<div
													class="w-9 h-9 rounded-full text-white font-bold text-sm flex items-center justify-center shrink-0 shadow-xs"
													style="background-color: {prof.color || '#004190'}"
												>
													{getInitials(prof.name)}
												</div>
												<div>
													<div class="flex items-center gap-2">
														<span class="font-bold text-[14px] text-[#1d1b17]">{prof.name}</span>
														{#if isCurrentUser}
															<span class="text-[10px] font-bold px-1.5 py-0.5 rounded bg-[#d8e2ff] text-[#004494]">você</span>
														{/if}
													</div>
													<span class="text-[12px] text-[#727784]">{prof.email || prof.id}</span>
												</div>
											</div>
										</td>

										<!-- Column 2: Linked Teams -->
										<td class="py-4 px-5">
											{#if userTeams.length > 0}
												<div class="flex flex-wrap items-center gap-1.5">
													{#each userTeams as uTeam (uTeam.id)}
														{@const visual = getTeamVisual(uTeam.name, uTeam.color)}
														<button
															type="button"
															onclick={() => openUserTeamsModal(prof)}
															class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full border text-[12px] font-semibold hover:opacity-85 transition-opacity cursor-pointer"
															style="{visual.pillStyle}"
															title="Clique para gerenciar equipes"
														>
															<span class="material-symbols-outlined text-[14px]" style="color: {visual.iconColor};">{visual.icon}</span>
															<span>{uTeam.name}</span>
														</button>
													{/each}
													<span class="text-[11px] text-[#727784] font-medium ml-0.5 font-sans">
														({userTeams.length} {userTeams.length === 1 ? 'equipe' : 'equipes'})
													</span>
												</div>
											{:else}
												<button
													type="button"
													onclick={() => openUserTeamsModal(prof)}
													class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#f9f3ec] border border-[#d5cebe] text-[#727784] hover:text-[#1d1b17] text-[12px] font-medium transition-colors cursor-pointer"
													title="Clique para vincular equipe"
												>
													<span>Sem equipe vinculada</span>
													<span class="material-symbols-outlined text-[14px]">add</span>
												</button>
											{/if}
										</td>

										<!-- Column 3: Role & Access Level -->
										<td class="py-4 px-5">
											<form method="POST" action="?/updateUserRole" class="inline-flex items-center gap-2">
												<input type="hidden" name="id" value={prof.id} />
												<input type="hidden" name="name" value={prof.name} />
												<select
													name="role"
													disabled={!isAdmin}
													class="px-2.5 py-1 rounded-lg bg-[#f9f3ec] border border-[#e8e2db] text-[12px] font-medium text-[#1d1b17] focus:outline-none focus:ring-1 focus:ring-[#004190] disabled:opacity-75 disabled:cursor-not-allowed cursor-pointer"
												>
													<option value="admin" selected={prof.role === 'admin'}>Administrador</option>
													<option value="member" selected={prof.role === 'member'}>Membro</option>
													<option value="viewer" selected={prof.role === 'viewer'}>Visualizador</option>
												</select>
												{#if isAdmin}
													<button
														type="submit"
														class="px-3.5 py-1.5 rounded-lg bg-white border border-[#d5cebe] text-[#1d1b17] text-[12px] font-bold hover:bg-[#004190] hover:text-white hover:border-[#004190] shadow-xs transition-all cursor-pointer"
													>
														Salvar Cargo
													</button>
												{/if}
											</form>
										</td>

										<!-- Column 4: Actions -->
										<td class="py-4 px-5 text-right">
											{#if isAdmin}
												<button
													type="button"
													onclick={() => openUserTeamsModal(prof)}
													class="w-8 h-8 rounded-lg hover:bg-[#f3ede6] text-[#727784] hover:text-[#1d1b17] inline-flex items-center justify-center transition-colors cursor-pointer"
													title="Gerenciar equipes de {prof.name}"
												>
													<span class="material-symbols-outlined text-[18px]">more_vert</span>
												</button>
											{/if}
										</td>
									</tr>
								{/each}
							</tbody>
						</table>
					</div>

					<!-- Bottom Card: + CONVIDAR NOVO MEMBRO DA EJ -->
					<div class="p-5 rounded-2xl bg-[#fcfaf7] border border-[#e8e2d8] shadow-[inset_0_1px_3px_rgba(0,0,0,0.02)]">
						<div class="flex items-center gap-2 mb-4">
							<span class="material-symbols-outlined text-[#004190] text-[20px]">person_add</span>
							<span class="font-extrabold text-[12px] tracking-wider text-[#1d1b17] uppercase font-mono">+ CONVIDAR NOVO MEMBRO DA EJ</span>
						</div>
						<form action="?/createUser" method="POST" use:enhanceFormValidation class="grid grid-cols-1 md:grid-cols-12 gap-3 items-end">
							<!-- Field 1: Name -->
							<div class="md:col-span-4">
								<label for="inv-name" class="block text-[10px] font-bold uppercase tracking-wider text-[#727784] mb-1 font-mono">
									NOME COMPLETO &amp; CARGO *
								</label>
								<input
									id="inv-name"
									name="name"
									type="text"
									required
									placeholder="Ex.: Marina Silva (Dir. Marketing)"
									class="w-full px-3.5 py-2 rounded-xl bg-white border border-[#d5cebe] text-[13px] text-[#1d1b17] placeholder-[#a09b92] focus:outline-none focus:ring-2 focus:ring-[#004190]/20 focus:border-[#004190] transition-all"
								/>
							</div>
							<!-- Field 2: Email -->
							<div class="md:col-span-4">
								<label for="inv-email" class="block text-[10px] font-bold uppercase tracking-wider text-[#727784] mb-1 font-mono">
									E-MAIL INSTITUCIONAL *
								</label>
								<input
									id="inv-email"
									name="email"
									type="email"
									required
									placeholder="marketing@nuvemjr.com.br"
									class="w-full px-3.5 py-2 rounded-xl bg-white border border-[#d5cebe] text-[13px] text-[#1d1b17] placeholder-[#a09b92] focus:outline-none focus:ring-2 focus:ring-[#004190]/20 focus:border-[#004190] transition-all"
								/>
							</div>
							<!-- Field 3: Role -->
							<div class="md:col-span-2">
								<label for="inv-role" class="block text-[10px] font-bold uppercase tracking-wider text-[#727784] mb-1 font-mono">
									CARGO / FUNÇÃO
								</label>
								<select
									id="inv-role"
									name="role"
									class="w-full px-3 py-2 rounded-xl bg-white border border-[#d5cebe] text-[13px] text-[#1d1b17] focus:outline-none focus:ring-2 focus:ring-[#004190]/20 focus:border-[#004190] cursor-pointer"
								>
									<option value="member">Membro</option>
									<option value="admin">Administrador</option>
									<option value="viewer">Visualizador</option>
								</select>
							</div>
							<!-- Field 4: Submit Button -->
							<div class="md:col-span-2">
								<button
									type="submit"
									disabled={!isAdmin}
									class="w-full h-[41px] flex items-center justify-center gap-2 px-4 py-2 rounded-xl bg-[#004190] hover:bg-[#003375] text-white font-bold text-[13px] shadow-[0_2px_6px_rgba(0,65,144,0.25)] active:translate-y-0.5 transition-all disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
								>
									<span class="material-symbols-outlined text-[17px]">send</span>
									<span>Convidar</span>
								</button>
							</div>
						</form>
					</div>
				{/if}

				<!-- ═══════════════════════════════════════════════════════════ -->
				<!-- TAB 3: CICLOS SEMESTRAIS -->
				<!-- ═══════════════════════════════════════════════════════════ -->
				{#if activeTab === 'cycles'}
					<!-- Folder Subheader -->
					<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-5 border-b border-[#f3ede6]">
						<div class="flex items-center gap-3">
							<div class="w-10 h-10 rounded-xl bg-[#ffe327]/30 text-[#78350f] flex items-center justify-center shrink-0">
								<span class="material-symbols-outlined text-[22px]">calendar_month</span>
							</div>
							<div>
								<div class="flex items-center gap-2.5">
									<h2 class="text-lg font-bold text-[#1d1b17] font-display tracking-tight">Ciclos Semestrais &amp; Vigência</h2>
									<span class="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-[#78350f] text-white font-mono">
										{data.cycles.length} cadastrados
									</span>
								</div>
								<p class="text-[12.5px] text-[#727784] font-sans mt-0.5">
									Planejamento temporal das OKRs da Nuvem Jr., períodos de início/término e ciclo ativo.
								</p>
							</div>
						</div>
					</div>

					<!-- Grid of Semester Cycles -->
					<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
						{#each data.cycles as cyc (cyc.id)}
							{@const isActive = activeCycle?.id === cyc.id}
							<div class="p-4 rounded-xl border border-[#e8e2d8] bg-[#f9f3ec]/60 hover:bg-[#f9f3ec] transition-all flex flex-col justify-between shadow-sm">
								<div>
									<div class="flex items-center justify-between mb-2">
										<div class="flex items-center gap-2">
											<span class="material-symbols-outlined text-[20px] text-amber-600">calendar_month</span>
											<span class="font-bold text-[16px] text-[#1d1b17] font-display">{cyc.code}</span>
										</div>
										{#if isActive}
											<span class="text-[9px] font-bold uppercase px-2 py-0.5 rounded bg-[#fef9c3] text-[#78350f] border border-[#fef08a] font-mono">
												ATIVO
											</span>
										{/if}
									</div>
									<div class="text-[12px] font-mono text-[#727784] mt-1">
										{formatDate(cyc.start_date)} → {formatDate(cyc.end_date)}
									</div>
									<span class="inline-block mt-2 text-[11px] font-medium px-2 py-0.5 rounded bg-[#ede7e1] text-[#424753]">
										Ano {cyc.year} • {cyc.semester}º Semestre
									</span>
								</div>
								{#if isAdmin}
									<div class="flex justify-end pt-3 mt-3 border-t border-[#e8e2db]/70">
										<button
											type="button"
											onclick={() => (cycleToDelete = cyc)}
											class="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-red-50 text-[#727784] hover:text-red-600 transition-colors cursor-pointer"
											title="Excluir Ciclo"
										>
											<span class="material-symbols-outlined text-[16px]">delete</span>
										</button>
									</div>
								{/if}
							</div>
						{/each}
					</div>

					<!-- Bottom Form: + ADICIONAR NOVO CICLO SEMESTRAL -->
					{#if isAdmin}
						<div class="p-5 rounded-2xl bg-[#fcfaf7] border border-[#e8e2d8] shadow-[inset_0_1px_3px_rgba(0,0,0,0.02)]">
							<div class="flex items-center gap-2 mb-4">
								<span class="material-symbols-outlined text-[#78350f] text-[20px]">calendar_add_on</span>
								<span class="font-extrabold text-[12px] tracking-wider text-[#1d1b17] uppercase font-mono">+ ADICIONAR NOVO CICLO SEMESTRAL</span>
							</div>
							<form action="?/createCycle" method="POST" use:enhanceFormValidation class="grid grid-cols-1 md:grid-cols-12 gap-3 items-end">
								<div class="md:col-span-2">
									<label for="cyc-year" class="block text-[10px] font-bold uppercase tracking-wider text-[#727784] mb-1 font-mono">ANO *</label>
									<input
										id="cyc-year"
										name="year"
										type="number"
										required
										value={new Date().getFullYear() + 1}
										class="w-full px-3 py-2 rounded-xl bg-white border border-[#d5cebe] text-[13px] text-[#1d1b17] focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-600 transition-all font-mono"
									/>
								</div>
								<div class="md:col-span-2">
									<label for="cyc-sem" class="block text-[10px] font-bold uppercase tracking-wider text-[#727784] mb-1 font-mono">SEMESTRE</label>
									<select
										id="cyc-sem"
										name="semester"
										class="w-full px-3 py-2 rounded-xl bg-white border border-[#d5cebe] text-[13px] text-[#1d1b17] focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-600 cursor-pointer font-mono"
									>
										<option value="1">1º Semestre (S1)</option>
										<option value="2">2º Semestre (S2)</option>
									</select>
								</div>
								<div class="md:col-span-3">
									<label for="cyc-start" class="block text-[10px] font-bold uppercase tracking-wider text-[#727784] mb-1 font-mono">DATA DE INÍCIO *</label>
									<input
										id="cyc-start"
										name="start_date"
										type="date"
										required
										value={`${new Date().getFullYear() + 1}-01-01`}
										class="w-full px-3 py-2 rounded-xl bg-white border border-[#d5cebe] text-[13px] text-[#1d1b17] focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-600 transition-all font-mono"
									/>
								</div>
								<div class="md:col-span-3">
									<label for="cyc-end" class="block text-[10px] font-bold uppercase tracking-wider text-[#727784] mb-1 font-mono">DATA DE TÉRMINO *</label>
									<input
										id="cyc-end"
										name="end_date"
										type="date"
										required
										value={`${new Date().getFullYear() + 1}-06-30`}
										class="w-full px-3 py-2 rounded-xl bg-white border border-[#d5cebe] text-[13px] text-[#1d1b17] focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-600 transition-all font-mono"
									/>
								</div>
								<div class="md:col-span-2">
									<button
										type="submit"
										class="w-full h-[41px] flex items-center justify-center gap-2 px-4 py-2 rounded-xl bg-amber-600 hover:bg-amber-700 text-white font-bold text-[13px] shadow-[0_2px_6px_rgba(217,119,6,0.25)] active:translate-y-0.5 transition-all cursor-pointer"
									>
										<span class="material-symbols-outlined text-[17px]">add</span>
										<span>Adicionar</span>
									</button>
								</div>
							</form>
						</div>
					{/if}
				{/if}

				<!-- ═══════════════════════════════════════════════════════════ -->
				<!-- TAB 4: GESTÃO DE SNAPSHOT & BACKUP EJ -->
				<!-- ═══════════════════════════════════════════════════════════ -->
				{#if activeTab === 'backup'}
					<!-- Folder Subheader -->
					<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-5 border-b border-[#f3ede6]">
						<div class="flex items-center gap-3">
							<div class="w-10 h-10 rounded-xl bg-[#ffd9e4]/60 text-[#b7076c] flex items-center justify-center shrink-0">
								<span class="material-symbols-outlined text-[22px]">folder_zip</span>
							</div>
							<div>
								<h2 class="text-lg font-bold text-[#1d1b17] font-display tracking-tight">Gestão de Snapshot &amp; Backup EJ</h2>
								<p class="text-[12.5px] text-[#727784] font-sans mt-0.5">
									Exportação completa em formato JSON, restauração para o modelo canônico de EJ e importação para passagem de gestão semestral.
								</p>
							</div>
						</div>
					</div>

					<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
						<!-- Card 1: Export -->
						<div class="p-5 rounded-xl border border-[#e8e2d8] bg-[#f9f3ec]/60 flex flex-col justify-between shadow-sm">
							<div>
								<div class="flex items-center gap-2 mb-2">
									<span class="material-symbols-outlined text-[22px] text-[#004190]">cloud_download</span>
									<h3 class="font-bold text-[15px] text-[#1d1b17]">Exportar Backup Portátil JSON</h3>
								</div>
								<p class="text-[12.5px] text-[#727784] leading-relaxed">
									Gere um arquivo JSON contendo todos os nós estratégicos, metas, métricas, equipes e membros para custódia segura ou auditoria semestral.
								</p>
							</div>
							<div class="pt-4 mt-4 border-t border-[#e8e2db]/70">
								<button
									type="button"
									onclick={downloadSnapshot}
									class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#004190] hover:bg-[#003375] text-white font-bold text-[13px] shadow-[0_2px_4px_rgba(0,65,144,0.2)] active:translate-y-0.5 transition-all cursor-pointer"
								>
									<span class="material-symbols-outlined text-[18px]">download</span>
									<span>Baixar Arquivo JSON</span>
								</button>
							</div>
						</div>

						<!-- Card 2: Reset Template -->
						<div class="p-5 rounded-xl border border-[#e8e2d8] bg-[#f9f3ec]/60 flex flex-col justify-between shadow-sm">
							<div>
								<div class="flex items-center gap-2 mb-2">
									<span class="material-symbols-outlined text-[22px] text-[#b7076c]">restart_alt</span>
									<h3 class="font-bold text-[15px] text-[#1d1b17]">Restaurar Modelo Canônico de EJ</h3>
								</div>
								<p class="text-[12.5px] text-[#727784] leading-relaxed">
									Recarregue o padrão oficial do JE Strategy OS com as 6 diretorias estruturadas, objetivos estratégicos recomendados e indicadores essenciais.
								</p>
							</div>
							<div class="pt-4 mt-4 border-t border-[#e8e2db]/70">
								<button
									type="button"
									disabled={!isAdmin}
									onclick={() => (showResetModal = true)}
									class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#ffd9e4] hover:bg-[#fcc8d7] text-[#8d0051] font-bold text-[13px] border border-[#f472b6]/40 shadow-sm active:translate-y-0.5 transition-all disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
								>
									<span class="material-symbols-outlined text-[18px]">restore</span>
									<span>Restaurar Modelo Padrão</span>
								</button>
							</div>
						</div>
					</div>

					<!-- Card 3: Import JSON -->
					{#if isAdmin}
						<div class="p-5 rounded-2xl bg-[#fcfaf7] border border-[#e8e2d8] shadow-[inset_0_1px_3px_rgba(0,0,0,0.02)]">
							<div class="flex items-center gap-2 mb-2">
								<span class="material-symbols-outlined text-[#004190] text-[20px]">upload_file</span>
								<span class="font-extrabold text-[12px] tracking-wider text-[#1d1b17] uppercase font-mono">IMPORTAR SNAPSHOT JSON</span>
							</div>
							<p class="text-[12.5px] text-[#727784] mb-3">
								Cole o conteúdo do backup exportado para restaurar ou transferir a base do planejamento estratégico.
							</p>
							<form action="?/importJson" method="POST" use:enhanceFormValidation class="space-y-3">
								<textarea
									name="jsonText"
									rows="5"
									required
									placeholder="Cole aqui o JSON exportado (contendo nodes, cycles, teams, etc.)..."
									class="w-full p-3.5 rounded-xl bg-white border border-[#d5cebe] text-[12px] font-mono text-[#1d1b17] placeholder-[#a09b92] focus:outline-none focus:ring-2 focus:ring-[#004190]/20 focus:border-[#004190] transition-all"
								></textarea>
								<div class="flex justify-end">
									<button
										type="submit"
										class="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#004190] hover:bg-[#003375] text-white font-bold text-[13px] shadow-[0_2px_6px_rgba(0,65,144,0.25)] active:translate-y-0.5 transition-all cursor-pointer"
									>
										<span class="material-symbols-outlined text-[18px]">upload</span>
										<span>Importar Snapshot</span>
									</button>
								</div>
							</form>
						</div>
					{/if}
				{/if}
			</div>
		</div>
	</div>
</div>

<!-- ═══════════════════════════════════════════════════════════════ -->
<!-- MODAL: PASTA ARQUIVO SUSPENSA DE CRIAÇÃO E EDIÇÃO DE EQUIPE     -->
<!-- (Variação 3: Pasta de Arquivo Clássica Split 2 Colunas)         -->
<!-- ═══════════════════════════════════════════════════════════════ -->
{#if activeTeamModal}
	<div
		role="presentation"
		onclick={() => (activeTeamModal = null)}
		class="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-[#181613]/60 backdrop-blur-[5px]"
	>
		<!-- WRAPPER: SUSPENSION FOLDER RAIL & CONTAINER -->
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			onclick={(e) => e.stopPropagation()}
			class="relative w-full max-w-4xl flex flex-col items-stretch animate-in fade-in zoom-in-95 duration-200"
		>
			<!-- 1. TOPO DA PASTA: ABA CLÁSSICA COM VISOR TRANSPARENTE E ETIQUETA ENCAIXADA -->
			<div class="flex items-end justify-between px-2 sm:px-4 -mb-[1px] relative z-20">
				<!-- Tab com Visor de Acetato / Etiqueta Manilha Recortada -->
				<div
					class="relative flex items-center gap-3 px-5 sm:px-7 py-2.5 border-t-2 border-l-2 border-r-2 rounded-t-xl transition-colors duration-200"
					style="background-color: {modalTheme.folderBg}; border-color: {modalTheme.folderBorder}; box-shadow: 0 -3px 10px rgba(0,0,0,0.06), inset 0 1px 0 rgba(255,255,255,0.9);"
				>
					<!-- Visor Plástico Transparente com Cartão Interno -->
					<div
						class="flex items-center gap-2 px-2.5 py-1 rounded bg-white/95 border shadow-[inset_0_1px_2px_rgba(0,0,0,0.06)]"
						style="border-color: {modalTheme.badgeBorder};"
					>
						<span
							class="w-2.5 h-2.5 rounded-full shadow-sm animate-pulse"
							style="background-color: {activeTeamModal.color};"
						></span>
						<span
							class="font-mono text-[11.5px] font-bold tracking-wider uppercase"
							style="color: {modalTheme.accentDark};"
						>
							{activeTeamModal.mode === 'create'
								? 'NOVA EQUIPE • NÍVEL 01'
								: `DIR-${teamIndex} • ${activeTeamModal.name.toUpperCase() || 'EQUIPE'}`}
						</span>
					</div>
					<!-- Indicador de KRs Ativos acoplado à aba -->
					<div
						class="flex items-center gap-1.5 px-2 py-0.5 rounded-md font-mono text-[11px] font-bold border transition-colors"
						style="background-color: {modalTheme.badgeBg}; border-color: {modalTheme.badgeBorder}; color: {modalTheme.badgeText};"
					>
						<span class="material-symbols-outlined text-[14px]" style="color: {modalTheme.accent};">flag</span>
						<span>{modalTeamKRs.length} KRs ATIVOS</span>
					</div>
					<!-- Seamless connector to folder body -->
					<span
						class="absolute -bottom-1 left-0 right-0 h-2 transition-colors duration-200"
						style="background-color: {modalTheme.folderBg};"
					></span>
				</div>

				<!-- Canto Superior Direito: Seletor de Cor & Botão Fechar -->
				<div class="flex items-center gap-2 pb-1.5 pr-1 relative z-40">
					<PaperColorPicker bind:value={activeTeamModal.color} align="right" />
					<button
						type="button"
						onclick={() => (activeTeamModal = null)}
						class="w-8 h-8 rounded-full bg-white/95 hover:bg-white text-[#524d45] hover:text-[#1d1b17] border border-[#cfc5b4] shadow-sm flex items-center justify-center transition-all hover:scale-105 active:scale-95 cursor-pointer"
						title="Fechar Pasta"
					>
						<span class="material-symbols-outlined text-[18px]">close</span>
					</button>
				</div>
			</div>

			<!-- 2. CORPO DA PASTA FÍSICA: Manilha Elegante com tom suave da cor da equipe -->
			<form
				method="POST"
				action={activeTeamModal.mode === 'create' ? '?/createTeam' : '?/updateTeam'}
				use:enhanceFormValidation
				onsubmit={() => {
					setTimeout(() => (activeTeamModal = null), 80);
				}}
				class="w-full border-2 rounded-2xl rounded-tl-none hanging-folder-shadow flex flex-col relative overflow-hidden transition-colors duration-200"
				style="background-color: {modalTheme.folderBg}; border-color: {modalTheme.folderBorder};"
			>
				{#if activeTeamModal.mode === 'edit'}
					<input type="hidden" name="teamId" value={activeTeamModal.id} />
				{/if}
				<input type="hidden" name="color" value={activeTeamModal.color} />
				<input type="hidden" name="hasMemberIds" value="true" />
				{#each activeTeamModal.memberIds as mid}
					<input type="hidden" name="memberIds" value={mid} />
				{/each}

				<!-- Textura de papel / Linha de reforço estrutural -->
				<div
					class="h-1.5 w-full relative z-10 border-b transition-colors duration-200"
					style="background: linear-gradient(to right, color-mix(in srgb, {activeTeamModal.color} 25%, transparent), color-mix(in srgb, {activeTeamModal.color} 45%, transparent), color-mix(in srgb, {activeTeamModal.color} 20%, transparent)); border-color: {modalTheme.folderBorder};"
				></div>

				<!-- ÁREA INTERNA DA PASTA (2 Colunas + Seção inferior de KRs) -->
				<div class="p-4 sm:p-6 lg:p-7 max-h-[calc(88vh-135px)] overflow-y-auto custom-scroll relative z-10 space-y-6">
					<!-- GRID PRINCIPAL DE 2 COLUNAS -->
					<div class="grid grid-cols-1 lg:grid-cols-12 gap-5 lg:gap-6 items-start">
						<!-- COLUNA DA ESQUERDA: IDENTIFICAÇÃO & ÍCONE (7/12 ~ 58%) -->
						<div class="lg:col-span-7 space-y-4">
							<div
								class="p-5 rounded-2xl border shadow-xs space-y-4 transition-colors"
								style="background-color: {modalTheme.cardBg}; border-color: {modalTheme.cardBorder};"
							>
								<!-- Nome da Equipe -->
								<div class="space-y-1.5">
									<div class="flex items-center justify-between">
										<label
											for="team-name-input"
											class="flex items-center gap-1.5 font-mono text-[11px] uppercase tracking-wider font-bold transition-colors"
											style="color: {modalTheme.accentDark};"
										>
											<span class="material-symbols-outlined text-[16px]" style="color: {modalTheme.accent};">
												drive_file_rename_outline
											</span>
											Nome da Equipe / Diretoria
										</label>
										<span
											class="text-[11px] font-mono font-semibold px-2 py-0.5 rounded border transition-colors"
											style="background-color: {modalTheme.badgeBg}; border-color: {modalTheme.badgeBorder}; color: {modalTheme.badgeText};"
										>
											Nível 01
										</span>
									</div>
									<div
										class="relative flex items-center rounded-xl px-3.5 py-2.5 shadow-inner transition-all border"
										style="background-color: {modalTheme.inputBg}; border-color: {modalTheme.inputBorder};"
									>
										<input
											id="team-name-input"
											name="name"
											type="text"
											required
											bind:value={activeTeamModal.name}
											placeholder="Ex.: Comercial"
											class="w-full bg-transparent border-0 p-0 text-[#1d1b17] font-display text-[20px] font-bold tracking-tight focus:ring-0 focus:outline-none"
										/>
										<span class="material-symbols-outlined text-[20px] ml-2 shrink-0" style="color: {modalTheme.accent};">
											edit
										</span>
									</div>
								</div>

								<!-- Seletor de Ícone & Cor da Equipe (Grid 2 colunas internas) -->
								<div class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-1 border-t border-[#edf4ee] items-start">
									<!-- Seletor de Ícone -->
									<div class="space-y-2">
										<div class="flex items-center justify-between">
											<span class="font-mono text-[10.5px] uppercase tracking-wider font-bold text-[#424753]">
												Ícone da Equipe
											</span>
											<span class="text-[11px] font-sans font-medium" style="color: {modalTheme.accent};">
												{teamIcons.find((i) => i.name === activeTeamModal!.icon)?.label || 'Storefront'}
											</span>
										</div>
										<div class="grid grid-cols-3 gap-1.5 pt-0.5">
											{#each teamIcons as ic}
												{@const isSelected = activeTeamModal.icon === ic.name}
												<button
													type="button"
													onclick={() => (activeTeamModal!.icon = ic.name)}
													class="h-10 rounded-xl flex items-center justify-center transition-all cursor-pointer {isSelected
														? 'text-white shadow-md ring-2 ring-offset-2 scale-105'
														: 'bg-[#f8fbf8] hover:bg-[#eef5ef] text-[#424753] border hover:scale-105 active:scale-95'}"
													style={isSelected
														? `background-color: ${activeTeamModal.color}; ring-color: ${activeTeamModal.color};`
														: `border-color: ${modalTheme.inputBorder};`}
													title="{ic.label} ({ic.desc})"
												>
													<span class="material-symbols-outlined text-[19px]">{ic.name}</span>
												</button>
											{/each}
										</div>
									</div>

									<!-- Seletor de Cor da Equipe & Pastas -->
									<div class="space-y-2.5 sm:border-l sm:border-[#edf4ee] sm:pl-4">
										<div class="flex items-center justify-between">
											<span class="font-mono text-[10.5px] uppercase tracking-wider font-bold text-[#424753]">
												Cor da Equipe &amp; Pastas
											</span>
										</div>
										<div class="pt-0.5">
											<PaperColorPicker bind:value={activeTeamModal.color} label="Alterar Cor" align="left" />
										</div>
									</div>
								</div>

								<!-- Descrição & Missão da Diretoria -->
								<div class="space-y-1.5 pt-1 border-t border-[#edf4ee]">
									<div class="flex items-center justify-between">
										<label
											for="team-desc-input"
											class="flex items-center gap-1.5 font-mono text-[11px] uppercase tracking-wider font-bold"
											style="color: {modalTheme.accentDark};"
										>
											<span class="material-symbols-outlined text-[16px]" style="color: {modalTheme.accent};">
												description
											</span>
											Descrição &amp; Missão da Diretoria
										</label>
										<span class="font-mono text-[10px] text-[#727784]">PROPÓSITO 2026</span>
									</div>
									<div
										class="rounded-xl p-3 shadow-inner transition-all border"
										style="background-color: {modalTheme.inputBg}; border-color: {modalTheme.inputBorder};"
									>
										<textarea
											id="team-desc-input"
											name="description"
											rows="3"
											bind:value={activeTeamModal.description}
											placeholder="Prospecção ativa, estruturação de parcerias B2B estratégicas e alcance das metas..."
											class="w-full bg-transparent border-0 p-0 text-[#1d1b17] font-sans text-[13px] leading-relaxed focus:ring-0 focus:outline-none resize-none font-medium"
										></textarea>
									</div>
								</div>
							</div>
						</div>

						<!-- COLUNA DA DIREITA: MEMBROS DA EQUIPE (5/12 ~ 42%) -->
						<div class="lg:col-span-5 space-y-4">
							<div
								class="p-4 rounded-2xl border shadow-xs space-y-3 transition-colors"
								style="background-color: {modalTheme.cardBg}; border-color: {modalTheme.cardBorder};"
							>
								<div class="flex items-center justify-between pb-1 border-b border-[#edf4ee]">
									<div class="flex items-center gap-2">
										<span class="material-symbols-outlined text-[17px]" style="color: {modalTheme.accent};">
											groups
										</span>
										<h4
											class="font-mono text-[11px] uppercase tracking-wider font-bold"
											style="color: {modalTheme.accentDark};"
										>
											Membros da Equipe ({activeTeamModal.memberIds.length})
										</h4>
									</div>
									<!-- Botão '+ Adicionar Membro' -->
									<div class="relative">
										<button
											type="button"
											onclick={() => (showAddMemberDropdown = !showAddMemberDropdown)}
											class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg font-mono text-[10.5px] font-bold border transition-colors cursor-pointer hover:brightness-95"
											style="background-color: {modalTheme.badgeBg}; border-color: {modalTheme.badgeBorder}; color: {modalTheme.accentDark};"
										>
											<span class="material-symbols-outlined text-[14px]">person_add</span>
											<span>+ Adicionar Membro</span>
										</button>

										<!-- Dropdown para adicionar membros não vinculados -->
										{#if showAddMemberDropdown}
											{@const availableProfiles = data.profiles.filter(
												(p: Profile) => !activeTeamModal!.memberIds.includes(p.id)
											)}
											<!-- svelte-ignore a11y_click_events_have_key_events -->
											<!-- svelte-ignore a11y_no_static_element_interactions -->
											<div
												class="fixed inset-0 z-30"
												onclick={() => (showAddMemberDropdown = false)}
											></div>
											<div
												class="absolute right-0 top-full mt-1.5 w-64 rounded-xl bg-white border border-[#d5cebe] shadow-xl p-2 z-40 space-y-1 max-h-56 overflow-y-auto custom-scroll"
											>
												<span class="block px-2 py-1 font-mono text-[10px] uppercase font-bold text-[#727784]">
													Vincular à Equipe:
												</span>
												{#if availableProfiles.length === 0}
													<span class="block px-2 py-2 text-[11.5px] text-[#727784] italic">
														Todos os membros já estão nesta equipe.
													</span>
												{:else}
													{#each availableProfiles as p (p.id)}
														<button
															type="button"
															onclick={() => addMemberToModal(p.id)}
															class="w-full flex items-center justify-between gap-2 p-1.5 rounded-lg hover:bg-[#f3ede6] text-left transition-colors cursor-pointer"
														>
															<div class="flex items-center gap-2 min-w-0">
																<div
																	class="w-6 h-6 rounded-full text-white text-[9px] font-bold flex items-center justify-center shrink-0"
																	style="background-color: {p.color || '#004190'}"
																>
																	{getInitials(p.name)}
																</div>
																<span class="text-[12px] font-semibold text-[#1d1b17] truncate">{p.name}</span>
															</div>
															<span class="material-symbols-outlined text-[15px] text-[#059669]">add</span>
														</button>
													{/each}
												{/if}
											</div>
										{/if}
									</div>
								</div>

								<!-- Lista Vertical de Membros Alocados -->
								<div class="space-y-2 max-h-64 overflow-y-auto custom-scroll p-0.5">
									{#if activeTeamModal.memberIds.length === 0}
										<div class="p-4 rounded-xl bg-[#f8fbf8] border border-dashed border-[#cbe0ce] text-center">
											<p class="text-[12px] text-[#727784] font-medium">Nenhum membro vinculado ainda.</p>
											<p class="text-[11px] text-[#727784]/80 mt-0.5">Clique em "+ Adicionar Membro" para associar pessoas.</p>
										</div>
									{:else}
										{#each activeTeamModal.memberIds as mid, idx (mid)}
											{@const mem = data.profiles.find((p: Profile) => p.id === mid)}
											{#if mem}
												{@const isLeader = mem.role === 'admin' || idx === 0}
												<div
													class="flex items-center justify-between p-2.5 rounded-xl bg-[#f8fbf8] border transition-all"
													style="border-color: {modalTheme.inputBorder};"
												>
													<div class="flex items-center gap-2.5 min-w-0">
														<div
															class="w-8 h-8 rounded-full text-white font-bold text-[11.5px] flex items-center justify-center shrink-0 ring-2 ring-white shadow-xs"
															style="background-color: {mem.color || activeTeamModal.color}"
														>
															{getInitials(mem.name)}
														</div>
														<div class="min-w-0">
															<div class="flex items-center gap-1.5">
																<p class="font-sans text-[12.5px] font-bold text-[#1d1b17] truncate leading-tight">
																	{mem.name}
																</p>
																{#if isLeader}
																	<span
																		class="px-1.5 py-0.2 rounded text-[9px] font-bold uppercase tracking-wider font-mono border"
																		style="background-color: {modalTheme.badgeBg}; color: {modalTheme.badgeText}; border-color: {modalTheme.badgeBorder};"
																	>
																		Líder
																	</span>
																{/if}
															</div>
															<p class="font-sans text-[11px] text-[#524d45] truncate">
																{mem.email || mem.id}
															</p>
														</div>
													</div>
													<div class="flex items-center gap-1 shrink-0">
														{#if isLeader}
															<span class="material-symbols-outlined text-[16px]" style="color: {modalTheme.accent};">
																stars
															</span>
														{/if}
														<button
															type="button"
															onclick={() => removeMemberFromModal(mem.id)}
															class="p-1 rounded text-[#727784] hover:text-[#ba1a1a] hover:bg-[#ffdad6]/40 transition-colors cursor-pointer"
															title="Remover da equipe"
														>
															<span class="material-symbols-outlined text-[15px]">close</span>
														</button>
													</div>
												</div>
											{/if}
										{/each}
									{/if}
								</div>
							</div>
						</div>

						<!-- SEÇÃO INFERIOR: KRS ASSOCIADOS (12/12) -->
						<div
							class="lg:col-span-12 p-4 sm:p-5 rounded-2xl border shadow-xs space-y-3 transition-colors"
							style="background-color: {modalTheme.cardBg}; border-color: {modalTheme.folderBorder};"
						>
							<div class="flex items-center justify-between">
								<div class="flex items-center gap-2">
									<div
										class="w-7 h-7 rounded-lg text-white flex items-center justify-center shrink-0 shadow-xs"
										style="background-color: {modalTheme.accent};"
									>
										<span class="material-symbols-outlined text-[16px]">flag</span>
									</div>
									<div class="flex items-center gap-2">
										<span class="font-mono text-[11px] font-bold uppercase tracking-wider" style="color: {modalTheme.accentDark};">
											KRs Associados ({modalTeamKRs.length})
										</span>
										<span
											class="text-[10px] font-mono font-bold px-2 py-0.5 rounded border"
											style="background-color: {modalTheme.badgeBg}; border-color: {modalTheme.badgeBorder}; color: {modalTheme.badgeText};"
										>
											100% Vinculados
										</span>
									</div>
								</div>
								<div class="flex items-center gap-2">
									<a
										href="/strategy"
										class="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-white hover:brightness-95 font-mono text-[10.5px] font-bold border transition-colors shadow-xs"
										style="border-color: {modalTheme.badgeBorder}; color: {modalTheme.accentDark};"
									>
										<span class="material-symbols-outlined text-[14px]">add</span>
										<span>Vincular KR</span>
									</a>
								</div>
							</div>

							<!-- Lista de KRs Associados -->
							<div class="space-y-1.5 pt-0.5">
								{#if modalTeamKRs.length === 0}
									<div
										class="p-3.5 rounded-xl bg-white border text-center text-[12px]"
										style="border-color: {modalTheme.cardBorder}; color: {modalTheme.badgeText};"
									>
										Nenhum KR vinculado a esta equipe ainda. Você pode associar KRs diretamente no Mapa Estratégico.
									</div>
								{:else}
									{#each modalTeamKRs.slice(0, 4) as kr (kr.id)}
										{@const pct = getKRProgress(kr)}
										{@const krTheme = getDossierTheme(kr.color || activeTeamModal.color)}
										<div
											class="flex items-center justify-between p-2.5 rounded-xl border text-[12.5px] transition-colors"
											style="background-color: {krTheme.folderBg}; border-color: {krTheme.folderBorder};"
										>
											<div class="flex items-center gap-2.5 min-w-0">
												<span
													class="w-2 h-2 rounded-full shrink-0"
													style="background-color: {krTheme.accent};"
												></span>
												<span class="font-medium text-[#1d1b17] truncate">{kr.title}</span>
											</div>
											<div class="flex items-center gap-2 shrink-0">
												<span
													class="font-mono font-bold text-[11px] px-2 py-0.5 rounded border"
													style="background-color: {krTheme.badgeBg}; border-color: {krTheme.badgeBorder}; color: {krTheme.accentDark};"
												>
													{pct}%
												</span>
												<div class="flex items-center gap-0.5 ml-1">
													<a
														href="/strategy?q={encodeURIComponent(kr.title)}"
														class="p-1 rounded text-[#727784] hover:text-[#0058bd] hover:bg-white transition-colors"
														title="Ver no Mapa Estratégico"
													>
														<span class="material-symbols-outlined text-[16px]">open_in_new</span>
													</a>
												</div>
											</div>
										</div>
									{/each}
								{/if}
							</div>

							{#if modalTeamKRs.length > 4}
								<div class="flex items-center justify-between pt-1 text-[11px] text-[#854d0e] font-sans">
									<span>+{modalTeamKRs.length - 4} KRs adicionais</span>
									<a class="font-semibold underline hover:text-[#713f12]" href="/strategy">
										Ver todos os {modalTeamKRs.length} KRs no Mapa Estratégico
									</a>
								</div>
							{/if}
						</div>
					</div>
				</div>

				<!-- 3. RODAPÉ DA PASTA: LINHA DE COSTURA/PICOTE SUTIL E BOTÕES DE AÇÃO -->
				<div
					class="relative z-10 border-t px-5 sm:px-7 py-3.5 transition-colors duration-200"
					style="background-color: {modalTheme.footerBg}; border-color: {modalTheme.folderBorder};"
				>
					<!-- Linha de Costura / Picote Sutil de Papel Manilha -->
					<div
						class="h-[1.5px] w-full mb-3 opacity-75"
						style="background-image: repeating-linear-gradient(to right, {modalTheme.stitchedColor} 0px, {modalTheme.stitchedColor} 6px, transparent 6px, transparent 11px);"
					></div>

					<div class="flex flex-col sm:flex-row items-center justify-between gap-3">
						<!-- Botão 'Excluir Equipe' (apenas em modo de edição) -->
						{#if activeTeamModal.mode === 'edit'}
							<button
								type="button"
								onclick={() => {
									const targetTeam = data.teams.find((t: Team) => t.id === activeTeamModal!.id);
									if (targetTeam) teamToDelete = targetTeam;
									activeTeamModal = null;
								}}
								class="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-[#ba1a1a] hover:bg-[#ffdad6]/60 font-sans text-[12.5px] font-semibold transition-colors self-start sm:self-auto cursor-pointer"
							>
								<span class="material-symbols-outlined text-[16px]">delete</span>
								<span>Excluir Equipe</span>
							</button>
						{:else}
							<div></div>
						{/if}

						<!-- Ações Principais -->
						<div class="flex items-center gap-2.5 w-full sm:w-auto justify-end">
							<button
								type="button"
								onclick={() => (activeTeamModal = null)}
								class="px-4 py-2 rounded-xl bg-white hover:bg-slate-50 text-[#1d1b17] border font-sans text-[12.5px] font-semibold shadow-xs active:translate-y-0.5 transition-all cursor-pointer"
								style="border-color: {modalTheme.inputBorder};"
							>
								Cancelar
							</button>
							<button
								type="submit"
								class="inline-flex items-center gap-2 px-5 py-2 rounded-xl text-white font-sans text-[12.5px] font-bold active:translate-y-0.5 transition-all cursor-pointer hover:brightness-105"
								style="background-color: {modalTheme.accent}; box-shadow: 0 2.5px 0 {modalTheme.accentShadow};"
							>
								<span class="material-symbols-outlined text-[17px]">check</span>
								<span>{activeTeamModal.mode === 'create' ? 'Criar Equipe' : 'Salvar Alterações'}</span>
							</button>
						</div>
					</div>
				</div>
			</form>
		</div>
	</div>
{/if}

<!-- ═══════════════════════════════════════════════════════════════ -->
<!-- MODAL: GERENCIAR EQUIPES DO MEMBRO                            -->
<!-- ═══════════════════════════════════════════════════════════════ -->
{#if editingUserTeams}
	{@const currentTeamIds = (data.teamMembers ?? []).filter((tm: any) => tm.user_id === editingUserTeams!.id).map((tm: any) => tm.team_id)}
	<div
		role="presentation"
		onclick={() => (editingUserTeams = null)}
		class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-xs p-4"
	>
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			aria-labelledby="user-teams-title"
			onclick={(e) => e.stopPropagation()}
			class="w-full max-w-lg rounded-2xl border border-[#d5cebe] bg-white p-6 shadow-2xl space-y-4"
		>
			<div class="flex items-center justify-between pb-3 border-b border-[#f3ede6]">
				<div class="flex items-center gap-3">
					<div
						class="w-10 h-10 rounded-full text-white font-bold text-sm flex items-center justify-center shadow-xs"
						style="background-color: {editingUserTeams.color || '#004190'}"
					>
						{getInitials(editingUserTeams.name)}
					</div>
					<div>
						<h3 id="user-teams-title" class="font-bold text-[15px] text-[#1d1b17]">{editingUserTeams.name}</h3>
						<p class="text-[12px] text-[#727784]">{editingUserTeams.email || editingUserTeams.id}</p>
					</div>
				</div>
				<button
					type="button"
					onclick={() => (editingUserTeams = null)}
					class="w-8 h-8 rounded-lg hover:bg-[#f3ede6] text-[#727784] hover:text-[#1d1b17] flex items-center justify-center transition-colors cursor-pointer"
				>
					<span class="material-symbols-outlined text-[20px]">close</span>
				</button>
			</div>

			<p class="text-[12.5px] text-[#424753]">
				Selecione as diretorias e equipes às quais este membro pertence:
			</p>

			<form
				method="POST"
				action="?/updateUserTeams"
				onsubmit={() => {
					setTimeout(() => (editingUserTeams = null), 50);
				}}
				class="space-y-4"
			>
				<input type="hidden" name="userId" value={editingUserTeams.id} />

				<div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5 max-h-72 overflow-y-auto p-1">
					{#each data.teams as team (team.id)}
						{@const isChecked = currentTeamIds.includes(team.id)}
						{@const visual = getTeamVisual(team.name, team.color)}
						<label
							class="flex items-center gap-2.5 p-2.5 rounded-xl border cursor-pointer transition-all {isChecked ? 'shadow-xs' : 'border-[#e8e2d8] hover:bg-[#f9f3ec]'}"
							style={isChecked ? visual.pillStyle : ''}
						>
							<input
								type="checkbox"
								name="teamIds"
								value={team.id}
								checked={isChecked}
								class="rounded border-[#d5cebe] text-[#004190] focus:ring-[#004190]"
							/>
							<span class="material-symbols-outlined text-[17px]" style="color: {visual.iconColor};">{visual.icon}</span>
							<span class="text-[12.5px] font-semibold text-[#1d1b17] truncate">{team.name}</span>
						</label>
					{/each}
				</div>

				<div class="flex items-center justify-end gap-2 pt-3 border-t border-[#f3ede6]">
					<button
						type="button"
						onclick={() => (editingUserTeams = null)}
						class="px-4 py-2 rounded-xl border border-[#d5cebe] text-[12.5px] font-bold text-[#727784] hover:text-[#1d1b17] hover:bg-[#f3ede6] transition-colors cursor-pointer"
					>
						Cancelar
					</button>
					<button
						type="submit"
						class="px-5 py-2 rounded-xl bg-[#004190] hover:bg-[#003375] text-white font-bold text-[12.5px] shadow-[0_2px_4px_rgba(0,65,144,0.2)] transition-all cursor-pointer"
					>
						Salvar Vínculos
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}

<!-- ═══════════════════════════════════════════════════════════ -->
<!-- MODAL: CONFIRMAR EXCLUSÃO DE EQUIPE                         -->
<!-- ═══════════════════════════════════════════════════════════ -->
{#if teamToDelete}
	<div
		role="presentation"
		onclick={() => (teamToDelete = null)}
		class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-xs p-4"
	>
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			onclick={(e) => e.stopPropagation()}
			class="w-full max-w-md rounded-2xl border border-[#d5cebe] bg-white p-6 shadow-2xl space-y-4"
		>
			<div class="flex items-center gap-3 text-red-600">
				<span class="material-symbols-outlined text-[28px]">warning</span>
				<h3 class="text-base font-bold text-[#1d1b17]">Excluir Equipe</h3>
			</div>
			<p class="text-[13px] text-[#424753] leading-relaxed">
				Tem certeza que deseja excluir a equipe <strong>"{teamToDelete.name}"</strong>? Os membros serão desvinculados desta equipe, mas seus perfis permanecerão intactos.
			</p>
			<form
				method="POST"
				action="?/deleteTeam"
				onsubmit={() => {
					setTimeout(() => (teamToDelete = null), 50);
				}}
				class="flex items-center justify-end gap-2 pt-2 border-t border-[#f3ede6]"
			>
				<input type="hidden" name="teamId" value={teamToDelete.id} />
				<button
					type="button"
					onclick={() => (teamToDelete = null)}
					class="px-4 py-2 rounded-xl border border-[#d5cebe] text-[12.5px] font-bold text-[#727784] hover:text-[#1d1b17] hover:bg-[#f3ede6] transition-colors cursor-pointer"
				>
					Cancelar
				</button>
				<button
					type="submit"
					class="px-5 py-2 rounded-xl bg-red-600 hover:bg-red-700 text-white font-bold text-[12.5px] shadow-[0_2px_4px_rgba(220,38,38,0.2)] transition-all cursor-pointer"
				>
					Excluir Equipe
				</button>
			</form>
		</div>
	</div>
{/if}

<!-- ═══════════════════════════════════════════════════════════ -->
<!-- MODAL: CONFIRMAR EXCLUSÃO DE CICLO                          -->
<!-- ═══════════════════════════════════════════════════════════ -->
{#if cycleToDelete}
	<div
		role="presentation"
		onclick={() => (cycleToDelete = null)}
		class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-xs p-4"
	>
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			onclick={(e) => e.stopPropagation()}
			class="w-full max-w-md rounded-2xl border border-[#d5cebe] bg-white p-6 shadow-2xl space-y-4"
		>
			<div class="flex items-center gap-3 text-red-600">
				<span class="material-symbols-outlined text-[28px]">warning</span>
				<h3 class="text-base font-bold text-[#1d1b17]">Excluir Ciclo</h3>
			</div>
			<p class="text-[13px] text-[#424753] leading-relaxed">
				Tem certeza que deseja excluir o ciclo <strong>"{cycleToDelete.code}"</strong>? Certifique-se de que não há nós estratégicos exclusivamente atribuídos a este ciclo.
			</p>
			<form
				method="POST"
				action="?/deleteCycle"
				onsubmit={() => {
					setTimeout(() => (cycleToDelete = null), 50);
				}}
				class="flex items-center justify-end gap-2 pt-2 border-t border-[#f3ede6]"
			>
				<input type="hidden" name="cycleId" value={cycleToDelete.id} />
				<button
					type="button"
					onclick={() => (cycleToDelete = null)}
					class="px-4 py-2 rounded-xl border border-[#d5cebe] text-[12.5px] font-bold text-[#727784] hover:text-[#1d1b17] hover:bg-[#f3ede6] transition-colors cursor-pointer"
				>
					Cancelar
				</button>
				<button
					type="submit"
					class="px-5 py-2 rounded-xl bg-red-600 hover:bg-red-700 text-white font-bold text-[12.5px] shadow-[0_2px_4px_rgba(220,38,38,0.2)] transition-all cursor-pointer"
				>
					Excluir Ciclo
				</button>
			</form>
		</div>
	</div>
{/if}

<!-- ═══════════════════════════════════════════════════════════ -->
<!-- MODAL: CONFIRMAR RESTAURAÇÃO DO MODELO PADRÃO               -->
<!-- ═══════════════════════════════════════════════════════════ -->
{#if showResetModal}
	<div
		role="presentation"
		onclick={() => (showResetModal = false)}
		class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-xs p-4"
	>
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			onclick={(e) => e.stopPropagation()}
			class="w-full max-w-md rounded-2xl border border-[#d5cebe] bg-white p-6 shadow-2xl space-y-4"
		>
			<div class="flex items-center gap-3 text-amber-600">
				<span class="material-symbols-outlined text-[28px]">restart_alt</span>
				<h3 class="text-base font-bold text-[#1d1b17]">Restaurar Modelo Padrão</h3>
			</div>
			<p class="text-[13px] text-[#424753] leading-relaxed">
				Esta ação carregará o modelo oficial de OKRs do JE Strategy OS, restaurando as 6 diretorias padrão e objetivos canônicos recomendados. Deseja prosseguir?
			</p>
			<form
				method="POST"
				action="?/resetTemplate"
				onsubmit={() => {
					setTimeout(() => (showResetModal = false), 50);
				}}
				class="flex items-center justify-end gap-2 pt-2 border-t border-[#f3ede6]"
			>
				<button
					type="button"
					onclick={() => (showResetModal = false)}
					class="px-4 py-2 rounded-xl border border-[#d5cebe] text-[12.5px] font-bold text-[#727784] hover:text-[#1d1b17] hover:bg-[#f3ede6] transition-colors cursor-pointer"
				>
					Cancelar
				</button>
				<button
					type="submit"
					class="px-5 py-2 rounded-xl bg-[#b7076c] hover:bg-[#960457] text-white font-bold text-[12.5px] shadow-[0_2px_4px_rgba(183,7,108,0.2)] transition-all cursor-pointer"
				>
					Confirmar e Restaurar
				</button>
			</form>
		</div>
	</div>
{/if}

<style>
	.hanging-folder-shadow {
		box-shadow: 
			0 2px 8px rgba(29, 27, 23, 0.08),
			0 18px 45px -8px rgba(20, 83, 45, 0.16),
			0 30px 70px -15px rgba(29, 27, 23, 0.35),
			inset 0 1px 0 rgba(255, 255, 255, 0.95);
	}
	.custom-scroll::-webkit-scrollbar {
		width: 6px;
	}
	.custom-scroll::-webkit-scrollbar-track {
		background: #f1ede4;
		border-radius: 4px;
	}
	.custom-scroll::-webkit-scrollbar-thumb {
		background: #c7beaf;
		border-radius: 4px;
	}
	.custom-scroll::-webkit-scrollbar-thumb:hover {
		background: #a89d8d;
	}
</style>
