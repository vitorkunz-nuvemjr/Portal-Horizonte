<script lang="ts">
	import type { Profile, Team } from '$lib/types';
	import { getInitials } from '$lib/utils';
	import { getTeamVisual } from './admin-utils';

	interface Props {
		data: any;
		editingUserTeams: Profile | null;
	}

	let {
		data,
		editingUserTeams = $bindable()
	}: Props = $props();

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
						{@const visual = getTeamVisual(team.name, team.color, team.icon)}
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
