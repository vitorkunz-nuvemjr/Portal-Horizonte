<script lang="ts">
	import { enhance } from '$app/forms';
	import type { Team, Cycle } from '$lib/types';

	interface Props {
		teamToDelete?: Team | null;
		cycleToDelete?: Cycle | null;
		showResetModal?: boolean;
	}

	let {
		teamToDelete = $bindable(null),
		cycleToDelete = $bindable(null),
		showResetModal = $bindable(false)
	}: Props = $props();
</script>

<!-- MODAL: CONFIRMAR EXCLUSÃO DE EQUIPE -->
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
				use:enhance={() => {
					return async ({ result, update }) => {
						if (result.type === 'success') {
							teamToDelete = null;
						}
						await update({ reset: false });
					};
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

<!-- MODAL: CONFIRMAR EXCLUSÃO DE CICLO -->
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
				use:enhance={() => {
					return async ({ result, update }) => {
						if (result.type === 'success') {
							cycleToDelete = null;
						}
						await update({ reset: false });
					};
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

<!-- MODAL: CONFIRMAR RESTAURAÇÃO DO MODELO PADRÃO -->
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
				use:enhance={() => {
					return async ({ result, update }) => {
						if (result.type === 'success') {
							showResetModal = false;
						}
						await update({ reset: false });
					};
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
