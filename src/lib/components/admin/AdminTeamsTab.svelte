<script lang="ts">
	import type { Team } from '$lib/types';
	import { getInitials } from '$lib/utils';
	import { getTeamMembers, getTeamVisual } from './admin-utils';

	interface Props {
		data: any;
		isAdmin: boolean;
		activeTeamModal: {
			mode: 'create' | 'edit';
			id: string;
			name: string;
			description: string;
			color: string;
			icon: string;
			memberIds: string[];
		} | null;
		teamToDelete: Team | null;
	}

	let {
		data,
		isAdmin,
		activeTeamModal = $bindable(),
		teamToDelete = $bindable()
	}: Props = $props();

	// Separate departmental teams from cross-cutting / transversal team
	const transversalTeam = $derived(
		data.teams?.find((t: Team) =>
			t.name.toLowerCase().includes('todas') || t.name.toLowerCase().includes('geral')
		)
	);
	const departmentalTeams = $derived(
		data.teams?.filter((t: Team) => t.id !== transversalTeam?.id) ?? []
	);

	const transVisual = $derived(
		getTeamVisual(
			transversalTeam?.name || 'Todas as Diretorias (Geral)',
			transversalTeam?.color || '#ca8a04',
			transversalTeam?.icon
		)
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
	}

	function openEditTeamModal(team: Team) {
		const visual = getTeamVisual(team.name, team.color, team.icon);
		const currentMemberIds = getTeamMembers(data, team.id).map((m) => m.id);
		activeTeamModal = {
			mode: 'edit',
			id: team.id,
			name: team.name,
			description: team.description ?? '',
			color: team.color || visual.dotColor,
			icon: team.icon || visual.icon,
			memberIds: currentMemberIds
		};
	}
</script>

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
		{@const members = getTeamMembers(data, team.id)}
		{@const visual = getTeamVisual(team.name, team.color, team.icon)}
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
				<div class="flex -space-x-1.5 items-center">
					{#each members.slice(0, 3) as mem (mem.id)}
						<div
							class="w-6 h-6 rounded-full text-white text-[10px] font-bold flex items-center justify-center shrink-0 shadow-xs overflow-hidden"
							style="background-color: {mem.color || visual.dotColor}"
							title="{mem.name}"
						>
							{#if mem.avatar_url || (mem as any).image}
								<img src={mem.avatar_url || (mem as any).image} alt={mem.name} class="w-full h-full object-cover" />
							{:else}
								{getInitials(mem.name)}
							{/if}
						</div>
					{/each}
					{#if members.length > 3}
						<div
							class="w-6 h-6 rounded-full text-white text-[9px] font-bold flex items-center justify-center shrink-0 shadow-xs overflow-hidden"
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
			<div class="flex -space-x-1.5 items-center">
				{#each data.profiles.slice(0, 4) as p (p.id)}
					<div
						class="w-6 h-6 rounded-full text-white text-[10px] font-bold flex items-center justify-center shrink-0 shadow-xs overflow-hidden"
						style="background-color: {p.color || '#004190'}"
						title="{p.name}"
					>
						{#if p.avatar_url || (p as any).image}
							<img src={p.avatar_url || (p as any).image} alt={p.name} class="w-full h-full object-cover" />
						{:else}
							{getInitials(p.name)}
						{/if}
					</div>
				{/each}
				{#if data.profiles.length > 4}
					<div class="w-6 h-6 rounded-full bg-[#0058bd] text-white text-[9px] font-bold flex items-center justify-center shrink-0 shadow-xs overflow-hidden">
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
