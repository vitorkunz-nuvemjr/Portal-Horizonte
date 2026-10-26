<script lang="ts">
	import { enhance } from '$app/forms';
	import type { Profile, Team } from '$lib/types';
	import { getInitials } from '$lib/utils';
	import { getDossierTheme } from '$lib/dossier-theme';
	import { getTeamVisual } from './admin-utils';
	import { X } from 'lucide-svelte';

	interface Props {
		data: any;
		editingUserTeams: Profile | null;
	}

	let {
		data,
		editingUserTeams = $bindable()
	}: Props = $props();

	const theme = $derived(getDossierTheme(editingUserTeams?.color || '#004190'));

	const currentTeamIds = $derived(
		editingUserTeams
			? (data.teamMembers ?? [])
					.filter((tm: any) => tm.user_id === editingUserTeams!.id)
					.map((tm: any) => tm.team_id)
			: []
	);
</script>

{#if editingUserTeams}
	<div
		role="presentation"
		onclick={() => (editingUserTeams = null)}
		class="fixed inset-0 z-[150] flex items-center justify-center bg-[#181613]/60 backdrop-blur-[5px] p-2.5 sm:p-6 overflow-y-auto overscroll-contain"
	>
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			aria-labelledby="user-teams-title"
			onclick={(e) => e.stopPropagation()}
			class="relative w-full max-w-lg rounded-2xl pt-2 pb-0 flex flex-col border-2 hanging-folder-shadow transition-colors duration-200 overflow-hidden"
			style="background-color: {theme.folderBg}; border-color: {theme.folderBorder};"
		>
			<!-- Top Protruding Tab -->
			<div class="px-4 sm:px-6 pt-3 pb-2 flex items-center justify-between gap-3 border-b border-black/5">
				<div
					class="inline-flex items-center gap-2 px-3 sm:px-4 py-1.5 rounded-t-xl border-t border-x -mb-2 shadow-xs min-w-0"
					style="background-color: {theme.cardBg}; border-color: {theme.folderBorder};"
				>
					<span
						class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider shrink-0"
						style="background-color: {theme.badgeBg}; border: 1px solid {theme.badgeBorder}; color: {theme.badgeText};"
					>
						DIRETORIAS DO MEMBRO
					</span>
					<span class="font-label-sm text-xs text-on-surface-variant truncate">
						{editingUserTeams.name}
					</span>
				</div>
				<button
					type="button"
					onclick={() => (editingUserTeams = null)}
					class="w-8 h-8 rounded-full flex items-center justify-center transition-all bg-black/5 hover:bg-black/10 text-on-surface-variant hover:text-on-surface cursor-pointer shrink-0"
					title="Fechar"
				>
					<X class="h-4 w-4" />
				</button>
			</div>

			<!-- Structural Reinforcement Bar -->
			<div
				class="h-[3px] w-full"
				style="background: linear-gradient(90deg, {theme.accent} 0%, {theme.folderBorder} 100%);"
			></div>

			<!-- Form & Body -->
			<div class="p-4 sm:p-6 overflow-y-auto max-h-[calc(85dvh-130px)]">
				<div class="flex items-center gap-3 mb-4">
					<div
						class="w-11 h-11 rounded-xl text-white font-bold text-sm flex items-center justify-center shadow-xs shrink-0"
						style="background-color: {editingUserTeams.color || '#004190'}"
					>
						{getInitials(editingUserTeams.name)}
					</div>
					<div>
						<h3 id="user-teams-title" class="font-bold text-base text-on-surface">{editingUserTeams.name}</h3>
						<p class="text-xs text-on-surface-variant">{editingUserTeams.email || editingUserTeams.id}</p>
					</div>
				</div>

				<p class="text-xs text-on-surface-variant mb-3">
					Selecione as diretorias e equipes às quais este membro pertence:
				</p>

				<form
					method="POST"
					action="?/updateUserTeams"
					use:enhance={() => {
						return async ({ result, update }) => {
							if (result.type === 'success') {
								editingUserTeams = null;
							}
							await update({ reset: false });
						};
					}}
					class="space-y-4"
				>
					<input type="hidden" name="userId" value={editingUserTeams.id} />

					<div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5 max-h-72 overflow-y-auto p-1 custom-scroll">
						{#each data.teams as team (team.id)}
							{@const isChecked = currentTeamIds.includes(team.id)}
							{@const visual = getTeamVisual(team.name, team.color, team.icon)}
							<label
								class="flex items-center gap-2.5 p-2.5 rounded-xl border cursor-pointer transition-all {isChecked ? 'shadow-xs' : 'border-outline-variant/50 hover:bg-white/40'}"
								style={isChecked ? visual.pillStyle : ''}
							>
								<input
									type="checkbox"
									name="teamIds"
									value={team.id}
									checked={isChecked}
									class="rounded border-outline-variant text-primary focus:ring-primary"
								/>
								<span class="material-symbols-outlined text-[17px]" style="color: {visual.iconColor};">{visual.icon}</span>
								<span class="text-xs font-semibold text-on-surface truncate">{team.name}</span>
							</label>
						{/each}
					</div>

					<!-- Stitched Perforation Footer -->
					<div
						class="pt-3 border-t mt-4 -mx-4 sm:-mx-6 px-4 sm:px-6 flex items-center justify-end gap-2"
						style="border-color: {theme.folderBorder}; background-color: {theme.footerBg};"
					>
						<button
							type="button"
							onclick={() => (editingUserTeams = null)}
							class="px-4 py-2 rounded-xl border border-outline-variant/60 text-xs font-bold text-on-surface-variant hover:text-on-surface hover:bg-surface-container transition-colors cursor-pointer"
						>
							Cancelar
						</button>
						<button
							type="submit"
							class="px-5 py-2 rounded-xl text-white font-bold text-xs shadow-sm transition-all cursor-pointer"
							style="background-color: {theme.accent}; box-shadow: 0 2px 0 {theme.accentShadow};"
						>
							Salvar Vínculos
						</button>
					</div>
				</form>
			</div>
		</div>
	</div>
{/if}
