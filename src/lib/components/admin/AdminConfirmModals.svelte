<script lang="ts">
	import { enhance } from '$app/forms';
	import type { Team, Cycle } from '$lib/types';
	import { getDossierTheme } from '$lib/dossier-theme';
	import { X, AlertTriangle, RotateCcw } from 'lucide-svelte';

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

	const dangerTheme = getDossierTheme('#dc2626');
	const warningTheme = getDossierTheme('#b7076c');
</script>

<!-- MODAL: CONFIRMAR EXCLUSÃO DE EQUIPE -->
{#if teamToDelete}
	<div
		role="presentation"
		onclick={() => (teamToDelete = null)}
		class="fixed inset-0 z-[160] flex items-center justify-center bg-[#181613]/60 backdrop-blur-[5px] p-2.5 sm:p-6 overflow-y-auto overscroll-contain animate-fadeIn"
	>
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			onclick={(e) => e.stopPropagation()}
			class="relative w-full max-w-md rounded-2xl pt-2 pb-0 flex flex-col border-2 hanging-folder-shadow transition-colors duration-200 overflow-hidden"
			style="background-color: {dangerTheme.folderBg}; border-color: {dangerTheme.folderBorder};"
		>
			<!-- Top Protruding Tab -->
			<div class="px-4 sm:px-6 pt-3 pb-2 flex items-center justify-between gap-3 border-b border-black/5">
				<div
					class="inline-flex items-center gap-2 px-3 sm:px-4 py-1.5 rounded-t-xl border-t border-x -mb-2 shadow-xs min-w-0"
					style="background-color: {dangerTheme.cardBg}; border-color: {dangerTheme.folderBorder};"
				>
					<span
						class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider shrink-0"
						style="background-color: {dangerTheme.badgeBg}; border: 1px solid {dangerTheme.badgeBorder}; color: {dangerTheme.badgeText};"
					>
						CONFIRMAR EXCLUSÃO
					</span>
				</div>
				<button
					type="button"
					onclick={() => (teamToDelete = null)}
					class="w-8 h-8 rounded-full flex items-center justify-center transition-all bg-black/5 hover:bg-black/10 text-on-surface-variant hover:text-on-surface cursor-pointer shrink-0"
					title="Fechar"
				>
					<X class="h-4 w-4" />
				</button>
			</div>

			<!-- Structural Reinforcement Bar -->
			<div
				class="h-[3px] w-full"
				style="background: linear-gradient(90deg, {dangerTheme.accent} 0%, {dangerTheme.folderBorder} 100%);"
			></div>

			<!-- Body -->
			<div class="p-5 sm:p-6">
				<div class="flex items-center gap-3 mb-3">
					<div
						class="w-10 h-10 rounded-xl flex items-center justify-center shadow-xs shrink-0"
						style="background-color: {dangerTheme.badgeBg}; border: 1px solid {dangerTheme.badgeBorder}; color: {dangerTheme.accentDark};"
					>
						<AlertTriangle class="h-5 w-5" />
					</div>
					<h3 class="text-base font-bold text-on-surface">Excluir Diretoria / Equipe</h3>
				</div>
				<p class="text-xs text-on-surface-variant leading-relaxed">
					Tem certeza que deseja excluir a equipe <strong class="text-on-surface">"{teamToDelete.name}"</strong>? Os membros serão desvinculados desta equipe, mas seus perfis permanecerão intactos.
				</p>
			</div>

			<!-- Stitched Perforation Footer -->
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
				class="p-4 border-t flex items-center justify-end gap-2"
				style="border-color: {dangerTheme.folderBorder}; background-color: {dangerTheme.footerBg};"
			>
				<input type="hidden" name="teamId" value={teamToDelete.id} />
				<button
					type="button"
					onclick={() => (teamToDelete = null)}
					class="px-4 py-2 rounded-xl border border-outline-variant/60 text-xs font-bold text-on-surface-variant hover:text-on-surface hover:bg-surface-container transition-colors cursor-pointer"
				>
					Cancelar
				</button>
				<button
					type="submit"
					class="px-5 py-2 rounded-xl text-white font-bold text-xs shadow-sm transition-all cursor-pointer"
					style="background-color: {dangerTheme.accent}; box-shadow: 0 2px 0 {dangerTheme.accentShadow};"
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
		class="fixed inset-0 z-[160] flex items-center justify-center bg-[#181613]/60 backdrop-blur-[5px] p-2.5 sm:p-6 overflow-y-auto overscroll-contain animate-fadeIn"
	>
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			onclick={(e) => e.stopPropagation()}
			class="relative w-full max-w-md rounded-2xl pt-2 pb-0 flex flex-col border-2 hanging-folder-shadow transition-colors duration-200 overflow-hidden"
			style="background-color: {dangerTheme.folderBg}; border-color: {dangerTheme.folderBorder};"
		>
			<!-- Top Protruding Tab -->
			<div class="px-4 sm:px-6 pt-3 pb-2 flex items-center justify-between gap-3 border-b border-black/5">
				<div
					class="inline-flex items-center gap-2 px-3 sm:px-4 py-1.5 rounded-t-xl border-t border-x -mb-2 shadow-xs min-w-0"
					style="background-color: {dangerTheme.cardBg}; border-color: {dangerTheme.folderBorder};"
				>
					<span
						class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider shrink-0"
						style="background-color: {dangerTheme.badgeBg}; border: 1px solid {dangerTheme.badgeBorder}; color: {dangerTheme.badgeText};"
					>
						CONFIRMAR EXCLUSÃO
					</span>
				</div>
				<button
					type="button"
					onclick={() => (cycleToDelete = null)}
					class="w-8 h-8 rounded-full flex items-center justify-center transition-all bg-black/5 hover:bg-black/10 text-on-surface-variant hover:text-on-surface cursor-pointer shrink-0"
					title="Fechar"
				>
					<X class="h-4 w-4" />
				</button>
			</div>

			<!-- Structural Reinforcement Bar -->
			<div
				class="h-[3px] w-full"
				style="background: linear-gradient(90deg, {dangerTheme.accent} 0%, {dangerTheme.folderBorder} 100%);"
			></div>

			<!-- Body -->
			<div class="p-5 sm:p-6">
				<div class="flex items-center gap-3 mb-3">
					<div
						class="w-10 h-10 rounded-xl flex items-center justify-center shadow-xs shrink-0"
						style="background-color: {dangerTheme.badgeBg}; border: 1px solid {dangerTheme.badgeBorder}; color: {dangerTheme.accentDark};"
					>
						<AlertTriangle class="h-5 w-5" />
					</div>
					<h3 class="text-base font-bold text-on-surface">Excluir Ciclo Semestral</h3>
				</div>
				<p class="text-xs text-on-surface-variant leading-relaxed">
					Tem certeza que deseja excluir o ciclo <strong class="text-on-surface">"{cycleToDelete.code}"</strong>? Certifique-se de que não há nós estratégicos exclusivamente atribuídos a este ciclo.
				</p>
			</div>

			<!-- Stitched Perforation Footer -->
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
				class="p-4 border-t flex items-center justify-end gap-2"
				style="border-color: {dangerTheme.folderBorder}; background-color: {dangerTheme.footerBg};"
			>
				<input type="hidden" name="cycleId" value={cycleToDelete.id} />
				<button
					type="button"
					onclick={() => (cycleToDelete = null)}
					class="px-4 py-2 rounded-xl border border-outline-variant/60 text-xs font-bold text-on-surface-variant hover:text-on-surface hover:bg-surface-container transition-colors cursor-pointer"
				>
					Cancelar
				</button>
				<button
					type="submit"
					class="px-5 py-2 rounded-xl text-white font-bold text-xs shadow-sm transition-all cursor-pointer"
					style="background-color: {dangerTheme.accent}; box-shadow: 0 2px 0 {dangerTheme.accentShadow};"
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
		class="fixed inset-0 z-[160] flex items-center justify-center bg-[#181613]/60 backdrop-blur-[5px] p-2.5 sm:p-6 overflow-y-auto overscroll-contain animate-fadeIn"
	>
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			onclick={(e) => e.stopPropagation()}
			class="relative w-full max-w-md rounded-2xl pt-2 pb-0 flex flex-col border-2 hanging-folder-shadow transition-colors duration-200 overflow-hidden"
			style="background-color: {warningTheme.folderBg}; border-color: {warningTheme.folderBorder};"
		>
			<!-- Top Protruding Tab -->
			<div class="px-4 sm:px-6 pt-3 pb-2 flex items-center justify-between gap-3 border-b border-black/5">
				<div
					class="inline-flex items-center gap-2 px-3 sm:px-4 py-1.5 rounded-t-xl border-t border-x -mb-2 shadow-xs min-w-0"
					style="background-color: {warningTheme.cardBg}; border-color: {warningTheme.folderBorder};"
				>
					<span
						class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider shrink-0"
						style="background-color: {warningTheme.badgeBg}; border: 1px solid {warningTheme.badgeBorder}; color: {warningTheme.badgeText};"
					>
						RESTAURAR MODELO
					</span>
				</div>
				<button
					type="button"
					onclick={() => (showResetModal = false)}
					class="w-8 h-8 rounded-full flex items-center justify-center transition-all bg-black/5 hover:bg-black/10 text-on-surface-variant hover:text-on-surface cursor-pointer shrink-0"
					title="Fechar"
				>
					<X class="h-4 w-4" />
				</button>
			</div>

			<!-- Structural Reinforcement Bar -->
			<div
				class="h-[3px] w-full"
				style="background: linear-gradient(90deg, {warningTheme.accent} 0%, {warningTheme.folderBorder} 100%);"
			></div>

			<!-- Body -->
			<div class="p-5 sm:p-6">
				<div class="flex items-center gap-3 mb-3">
					<div
						class="w-10 h-10 rounded-xl flex items-center justify-center shadow-xs shrink-0"
						style="background-color: {warningTheme.badgeBg}; border: 1px solid {warningTheme.badgeBorder}; color: {warningTheme.accentDark};"
					>
						<RotateCcw class="h-5 w-5" />
					</div>
					<h3 class="text-base font-bold text-on-surface">Restaurar Modelo Padrão</h3>
				</div>
				<p class="text-xs text-on-surface-variant leading-relaxed">
					Esta ação carregará o modelo oficial de OKRs do JE Strategy OS, restaurando as 6 diretorias padrão e objetivos canônicos recomendados. Deseja prosseguir?
				</p>
			</div>

			<!-- Stitched Perforation Footer -->
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
				class="p-4 border-t flex items-center justify-end gap-2"
				style="border-color: {warningTheme.folderBorder}; background-color: {warningTheme.footerBg};"
			>
				<button
					type="button"
					onclick={() => (showResetModal = false)}
					class="px-4 py-2 rounded-xl border border-outline-variant/60 text-xs font-bold text-on-surface-variant hover:text-on-surface hover:bg-surface-container transition-colors cursor-pointer"
				>
					Cancelar
				</button>
				<button
					type="submit"
					class="px-5 py-2 rounded-xl text-white font-bold text-xs shadow-sm transition-all cursor-pointer"
					style="background-color: {warningTheme.accent}; box-shadow: 0 2px 0 {warningTheme.accentShadow};"
				>
					Confirmar e Restaurar
				</button>
			</form>
		</div>
	</div>
{/if}
