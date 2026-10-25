<script lang="ts">
	import { enhance } from '$app/forms';
	import type { Profile } from '$lib/types';
	import { enhanceFormValidation, getInitials } from '$lib/utils';
	import { getUserTeams, getTeamVisual } from './admin-utils';

	interface Props {
		data: any;
		isAdmin: boolean;
		editingUserTeams: Profile | null;
	}

	let {
		data,
		isAdmin,
		editingUserTeams = $bindable()
	}: Props = $props();

	function openUserTeamsModal(prof: Profile) {
		editingUserTeams = prof;
	}
</script>

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
				{@const userTeams = getUserTeams(data, prof.id)}
				{@const isCurrentUser = prof.id === data.user?.id || prof.email === data.user?.email}
				<tr class="hover:bg-[#fffbf7] transition-colors">
					<!-- Column 1: Member Identification -->
					<td class="py-4 px-5">
						<div class="flex items-center gap-3">
							<div
								class="w-9 h-9 rounded-full text-white font-bold text-sm flex items-center justify-center shrink-0 shadow-xs overflow-hidden"
								style="background-color: {prof.color || '#004190'}"
							>
								{#if prof.avatar_url || (prof as any).image}
									<img src={prof.avatar_url || (prof as any).image} alt={prof.name} class="w-full h-full object-cover" />
								{:else}
									{getInitials(prof.name)}
								{/if}
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
									{@const visual = getTeamVisual(uTeam.name, uTeam.color, uTeam.icon)}
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
						<form
							method="POST"
							action="?/updateUserRole"
							use:enhance={() => {
								return async ({ update }) => {
									await update({ reset: false });
								};
							}}
							class="inline-flex items-center gap-2"
						>
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
	<form
		action="?/createUser"
		method="POST"
		use:enhance={() => {
			return async ({ update }) => {
				await update({ reset: false });
			};
		}}
		use:enhanceFormValidation
		class="grid grid-cols-1 md:grid-cols-12 gap-3 items-end"
	>
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
