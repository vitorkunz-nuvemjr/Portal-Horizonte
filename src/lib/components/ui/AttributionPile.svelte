<script lang="ts">
	import type { Profile, Team } from '$lib/types';
	import { getDossierTheme } from '$lib/dossier-theme';
	import { getInitials, getTeamIcon } from '$lib/utils';

	interface Props {
		teams?: Team[];
		assignees?: Profile[];
		leader?: Profile | null;
		size?: 'sm' | 'md';
		maxTeams?: number;
		maxAssignees?: number;
	}

	let {
		teams = [],
		assignees = [],
		leader = null,
		size = 'md',
		maxTeams = 2,
		maxAssignees = 2
	}: Props = $props();

	// Merge leader into assignees if not present
	const effectiveAssignees = $derived.by(() => {
		const list = [...assignees];
		if (leader && !list.some((a) => a.id === leader.id)) {
			list.unshift(leader);
		}
		return list;
	});

	const visibleTeams = $derived(teams.slice(0, maxTeams));
	const hiddenTeams = $derived(teams.slice(maxTeams));
	const hiddenTeamsCount = $derived(hiddenTeams.length);
	const hasMoreThanTwoTeams = $derived(teams.length > 2);

	const visibleAssignees = $derived(effectiveAssignees.slice(0, maxAssignees));
	const hiddenAssignees = $derived(effectiveAssignees.slice(maxAssignees));
	const hiddenAssigneesCount = $derived(hiddenAssignees.length);

	const isSm = $derived(size === 'sm');
</script>

<div class="flex items-center min-w-0 select-none">
	<!-- 1. TEAMS: SQUIRCLES FIRST -->
	{#each visibleTeams as tm, idx (tm.id)}
		{@const tmTheme = getDossierTheme(tm.color || '#0284c7')}
		{@const icon = getTeamIcon(tm)}
		<div
			class="group/item relative shrink-0 transition-all duration-200 ease-out hover:scale-115 hover:-translate-y-1 hover:z-30 cursor-pointer {idx > 0 ? '-ml-2.5' : ''}"
		>
			<div
				class="{isSm ? 'w-6 h-6 rounded-[7px]' : 'w-8 h-8 rounded-[10px]'} aspect-square shrink-0 flex items-center justify-center shadow-xs border transition-shadow hover:shadow-md"
				style="background-color: {tmTheme.badgeBg}; border-color: {tmTheme.badgeBorder}; color: {tmTheme.accentDark};"
			>
				<span
					class="material-symbols-outlined {isSm ? 'text-[13px]' : 'text-[18px]'}"
					style="color: {tmTheme.accentDark};"
				>
					{icon}
				</span>
			</div>

			<!-- Hover Tooltip Floating Above -->
			<div
				class="pointer-events-none absolute bottom-full left-1/2 -translate-x-1/2 mb-2 hidden group-hover/item:flex flex-col items-center z-50 transition-all duration-150 animate-in fade-in zoom-in-95"
			>
				<div
					class="bg-slate-900/95 text-white text-[10.5px] font-semibold px-2.5 py-1 rounded-md shadow-xl whitespace-nowrap flex items-center gap-1.5 backdrop-blur-xs ring-1 ring-white/10"
				>
					<span class="material-symbols-outlined text-[13px] text-sky-300">{icon}</span>
					<span>Equipe: {tm.name}</span>
				</div>
				<div class="w-0 h-0 border-x-4 border-x-transparent border-t-4 border-t-slate-900/95"></div>
			</div>
		</div>
	{/each}

	{#if hiddenTeamsCount > 0}
		<div
			class="group/item relative shrink-0 -ml-2.5 transition-all duration-200 ease-out hover:scale-115 hover:-translate-y-1 hover:z-30 cursor-pointer"
		>
			<div
				class="{isSm ? 'w-6 h-6 rounded-[7px] text-[9.5px]' : 'w-8 h-8 rounded-[10px] text-[11px]'} aspect-square shrink-0 flex items-center justify-center bg-slate-100 hover:bg-slate-200 border border-slate-300 font-bold text-slate-700 shadow-xs"
			>
				+{hiddenTeamsCount}
			</div>
			<!-- Tooltip -->
			<div
				class="pointer-events-none absolute bottom-full left-1/2 -translate-x-1/2 mb-2 hidden group-hover/item:flex flex-col items-center z-50 transition-all duration-150 animate-in fade-in zoom-in-95"
			>
				<div
					class="bg-slate-900/95 text-white text-[10.5px] font-semibold px-2.5 py-1 rounded-md shadow-xl whitespace-nowrap flex items-center gap-1.5 backdrop-blur-xs ring-1 ring-white/10"
				>
					<span class="material-symbols-outlined text-[13px] text-sky-300">hub</span>
					<span>+{hiddenTeamsCount} {hiddenTeamsCount === 1 ? 'outra equipe' : 'outras equipes'}{hiddenTeams.length > 0 ? `: ${hiddenTeams.map((t) => t.name).join(', ')}` : ''}</span>
				</div>
				<div class="w-0 h-0 border-x-4 border-x-transparent border-t-4 border-t-slate-900/95"></div>
			</div>
		</div>
	{/if}

	<!-- 2. MEMBERS / ASSIGNEES: CIRCLES STACKED NEXT TO OR ON TOP OF TEAMS -->
	{#each visibleAssignees as person, pIdx (person.id)}
		{@const personColor = person.color || '#0058bd'}
		{@const spacingClass = pIdx === 0
			? (hasMoreThanTwoTeams ? 'ml-2' : (visibleTeams.length > 0 ? '-ml-2.5' : ''))
			: '-ml-2.5'}
		<div
			class="group/item relative shrink-0 transition-all duration-200 ease-out hover:scale-115 hover:-translate-y-1 hover:z-30 cursor-pointer {spacingClass}"
		>
			<div
				class="{isSm ? 'w-6 h-6 text-[9.5px]' : 'w-8 h-8 text-[11px]'} aspect-square shrink-0 rounded-full flex items-center justify-center text-white font-bold shadow-xs ring-2 ring-white overflow-hidden transition-shadow hover:shadow-md"
				style="background-color: {personColor};"
			>
				{#if person.avatar_url || person.image}
					<img
						src={person.avatar_url || person.image}
						alt={person.name}
						class="w-full h-full object-cover"
					/>
				{:else}
					<span class="tracking-wider leading-none">
						{getInitials(person.name)}
					</span>
				{/if}
			</div>

			<!-- Attributed member dot at bottom right (matches Figma mockup) -->
			<span
				class="absolute -bottom-0.5 -right-0.5 {isSm ? 'w-2 h-2' : 'w-2.5 h-2.5'} aspect-square rounded-full bg-primary ring-2 ring-white shadow-xs pointer-events-none"
			></span>

			<!-- Hover Tooltip Floating Above -->
			<div
				class="pointer-events-none absolute bottom-full left-1/2 -translate-x-1/2 mb-2 hidden group-hover/item:flex flex-col items-center z-50 transition-all duration-150 animate-in fade-in zoom-in-95"
			>
				<div
					class="bg-slate-900/95 text-white text-[10.5px] font-semibold px-2.5 py-1 rounded-md shadow-xl whitespace-nowrap flex items-center gap-1.5 backdrop-blur-xs ring-1 ring-white/10"
				>
					<span class="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
					<span>{person.name}</span>
				</div>
				<div class="w-0 h-0 border-x-4 border-x-transparent border-t-4 border-t-slate-900/95"></div>
			</div>
		</div>
	{/each}

	<!-- Plus icon circle for more than 2 associated users -->
	{#if hiddenAssigneesCount > 0}
		<div
			class="group/item relative shrink-0 -ml-2.5 transition-all duration-200 ease-out hover:scale-115 hover:-translate-y-1 hover:z-30 cursor-pointer"
		>
			<div
				class="{isSm ? 'w-6 h-6 text-[9.5px]' : 'w-8 h-8 text-[11px]'} aspect-square shrink-0 rounded-full flex items-center justify-center bg-slate-700 hover:bg-slate-800 text-white font-bold ring-2 ring-white shadow-xs"
			>
				+{hiddenAssigneesCount}
			</div>
			<!-- Tooltip -->
			<div
				class="pointer-events-none absolute bottom-full left-1/2 -translate-x-1/2 mb-2 hidden group-hover/item:flex flex-col items-center z-50 transition-all duration-150 animate-in fade-in zoom-in-95"
			>
				<div
					class="bg-slate-900/95 text-white text-[10.5px] font-semibold px-2.5 py-1 rounded-md shadow-xl whitespace-nowrap flex items-center gap-1.5 backdrop-blur-xs ring-1 ring-white/10"
				>
					<span class="material-symbols-outlined text-[13px] text-amber-300">group</span>
					<span>+{hiddenAssigneesCount} {hiddenAssigneesCount === 1 ? 'outro membro' : 'outros membros'}{hiddenAssignees.length > 0 ? `: ${hiddenAssignees.map((u) => u.name).join(', ')}` : ''}</span>
				</div>
				<div class="w-0 h-0 border-x-4 border-x-transparent border-t-4 border-t-slate-900/95"></div>
			</div>
		</div>
	{/if}

	<!-- 3. UNASSIGNED PLACEHOLDER IF NEITHER IS PRESENT -->
	{#if visibleTeams.length === 0 && visibleAssignees.length === 0}
		<div
			class="group/item relative shrink-0 transition-all duration-200 hover:scale-110 cursor-pointer"
		>
			<div
				class="{isSm ? 'w-6 h-6 rounded-[7px]' : 'w-8 h-8 rounded-[10px]'} aspect-square shrink-0 flex items-center justify-center border border-dashed border-slate-300 bg-white/50 text-slate-400"
			>
				<span class="material-symbols-outlined {isSm ? 'text-[13px]' : 'text-[16px]'}">person_outline</span>
			</div>
			<!-- Tooltip -->
			<div
				class="pointer-events-none absolute bottom-full left-1/2 -translate-x-1/2 mb-2 hidden group-hover/item:flex flex-col items-center z-50 transition-all duration-150 animate-in fade-in zoom-in-95"
			>
				<div
					class="bg-slate-900/95 text-white text-[10px] font-medium px-2 py-1 rounded shadow-xl whitespace-nowrap"
				>
					Não atribuído
				</div>
				<div class="w-0 h-0 border-x-4 border-x-transparent border-t-4 border-t-slate-900/95"></div>
			</div>
		</div>
	{/if}
</div>
