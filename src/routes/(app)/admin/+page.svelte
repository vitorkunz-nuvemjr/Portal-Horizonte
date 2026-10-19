<script lang="ts">
	import { enhanceFormValidation, getInitials } from '$lib/utils';
	import {
		Users,
		Shield,
		Calendar,
		Database,
		Download,
		Upload,
		RotateCcw,
		AlertCircle,
		CheckCircle2,
		Trash2,
		Plus,
		Edit3,
		X
	} from 'lucide-svelte';

	let { data, form } = $props();

	let editingTeam = $state<{ id: string; name: string; description: string; color: string } | null>(null);
	let showNewTeamModal = $state(false);
	let editingUserTeamsId = $state<string | null>(null);

	const isAdmin = $derived(data.user?.role === 'admin');

	// Group users by team for quick summary
	const teamMembersCount = $derived.by(() => {
		const counts = new Map<string, number>();
		for (const tm of data.teamMembers) {
			counts.set(tm.team_id, (counts.get(tm.team_id) ?? 0) + 1);
		}
		return counts;
	});

	function downloadSnapshot() {
		const blob = new Blob([data.snapshotJson], { type: 'application/json' });
		const url = URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = `aligna-strategy-export-${new Date().toISOString().slice(0, 10)}.json`;
		a.click();
		URL.revokeObjectURL(url);
	}
</script>

<div class="p-gutter space-y-6">
	<div class="border-b border-outline-variant pb-4">
		<div class="flex items-center gap-2 mb-1">
			<span class="px-2 py-0.5 rounded-[2px] bg-secondary-fixed text-on-secondary-fixed text-label-sm font-bold uppercase tracking-widest border border-outline-variant">
				Equipes &amp; Governança
			</span>
			<span class="text-label-sm text-outline">•</span>
			<span class="text-label-sm text-on-surface-variant font-medium">Departamentos, Permissões, Ciclos e Snapshot JSON</span>
		</div>
		<h2 class="text-headline-lg font-bold tracking-tight text-on-surface">
			Equipes &amp; Administração
		</h2>
		<p class="mt-0.5 text-body-sm text-on-surface-variant">
			Gerencie equipes e permissões, configure ciclos semestrais, restaure o modelo padrão de EJ ou exporte/importe backups em JSON.
		</p>
	</div>

	{#if !isAdmin}
		<div
			class="flex items-center gap-2 rounded-[6px] border border-outline-variant bg-secondary-fixed/60 px-4 py-3 text-xs font-semibold text-on-secondary-fixed"
		>
			<AlertCircle class="h-4 w-4 shrink-0 text-secondary" />
			<span>
				Você está visualizando como <strong>{data.user?.role === 'admin' ? 'Administrador' : data.user?.role === 'member' ? 'Membro' : 'Visualizador'}</strong>. Alterne para uma conta de <strong>Administrador</strong> no seletor lateral para modificar usuários, ciclos ou dados.
			</span>
		</div>
	{/if}

	{#if form?.message}
		<div
			class="flex items-center gap-2 rounded-[6px] border border-error/40 bg-error-container px-4 py-3 text-xs font-semibold text-on-error-container"
		>
			<AlertCircle class="h-4 w-4 shrink-0 text-error" />
			<span>{form.message}</span>
		</div>
	{/if}

	{#if form?.notice}
		<div
			class="flex items-center gap-2 rounded-[6px] border border-outline-variant bg-tertiary-fixed px-4 py-3 text-xs font-semibold text-on-tertiary-fixed"
		>
			<CheckCircle2 class="h-4 w-4 shrink-0 text-tertiary" />
			<span>{form.notice}</span>
		</div>
	{/if}

	<!-- 1. Teams & Departments Section -->
	<section class="rounded-[6px] border border-outline-variant bg-surface-container-lowest p-6 shadow-[0_2px_8px_rgba(36,34,30,0.05)]">
		<div class="flex flex-wrap items-center justify-between gap-3 border-b border-outline-variant/60 pb-4">
			<div>
				<h3 class="flex items-center gap-2 text-sm font-bold text-on-surface">
					<Shield class="h-4 w-4 text-primary" />
					Equipes &amp; Departamentos
				</h3>
				<p class="mt-0.5 text-xs text-on-surface-variant">
					Configure equipes internas e departamentos funcionais. Os membros podem pertencer a nenhuma, uma ou múltiplas equipes.
				</p>
			</div>
			{#if isAdmin}
				<button
					type="button"
					onclick={() => (showNewTeamModal = true)}
					class="inline-flex items-center gap-1.5 rounded-[4px] bg-primary px-3.5 py-1.5 text-xs font-bold text-on-primary shadow-[0_2px_0_#004494] hover:opacity-95"
				>
					<Plus class="h-3.5 w-3.5" />
					Nova Equipe
				</button>
			{/if}
		</div>

		<!-- Team Cards Grid -->
		<div class="mt-4 grid grid-cols-1 gap-3.5 sm:grid-cols-2 md:grid-cols-4">
			{#each data.teams as t (t.id)}
				{@const count = teamMembersCount.get(t.id) ?? 0}
				<div class="flex flex-col justify-between rounded-[6px] border border-outline-variant bg-surface-container-low/60 p-3.5">
					<div>
						<div class="flex items-center justify-between gap-2">
							<div class="flex items-center gap-2 min-w-0">
								<span
									class="h-2.5 w-2.5 shrink-0 rounded-full"
									style="background-color: {t.color || '#005AC2'}"
								></span>
								<span class="text-xs font-bold text-on-surface truncate">{t.name}</span>
							</div>
							{#if isAdmin}
								<div class="flex items-center gap-1 shrink-0">
									<button
										type="button"
										onclick={() => {
											editingTeam = {
												id: t.id,
												name: t.name,
												description: t.description ?? '',
												color: t.color || '#005AC2'
											};
										}}
										class="rounded-[2px] p-1 text-on-surface-variant hover:bg-surface-container hover:text-on-surface"
										title="Editar equipe"
									>
										<Edit3 class="h-3 w-3" />
									</button>
									<form method="POST" action="?/deleteTeam" class="inline">
										<input type="hidden" name="teamId" value={t.id} />
										<button
											type="submit"
											class="rounded-[2px] p-1 text-on-surface-variant hover:bg-error-container hover:text-error"
											title="Excluir equipe"
										>
											<Trash2 class="h-3 w-3" />
										</button>
									</form>
								</div>
							{/if}
						</div>
						{#if t.description}
							<p class="mt-1.5 text-[11px] text-on-surface-variant line-clamp-2">{t.description}</p>
						{/if}
					</div>

					<div class="mt-3 flex items-center justify-between border-t border-outline-variant/60 pt-2 text-[11px]">
						<span class="font-bold text-on-surface-variant">{count} {count === 1 ? 'membro' : 'membros'}</span>
						<!-- Avatars of members in this team -->
						<div class="flex -space-x-1.5">
							{#each data.teamMembers.filter((tm) => tm.team_id === t.id).slice(0, 3) as tm (tm.user_id)}
								{@const prof = data.profiles.find((p) => p.id === tm.user_id)}
								{#if prof}
									<span
										class="inline-flex h-4.5 w-4.5 items-center justify-center rounded-full text-[8px] font-bold text-white ring-1 ring-surface-container-lowest"
										style="background-color: {prof.color || '#005AC2'}"
										title={prof.name}
									>
										{getInitials(prof.name)}
									</span>
								{/if}
							{/each}
						</div>
					</div>
				</div>
			{/each}
		</div>
	</section>

	<!-- 2. Team Profiles & Role Access -->
	<section class="rounded-[6px] border border-outline-variant bg-surface-container-lowest p-6 shadow-[0_2px_8px_rgba(36,34,30,0.05)]">
		<h3 class="flex items-center gap-2 text-sm font-bold text-on-surface">
			<Users class="h-4 w-4 text-primary" />
			Membros, Vínculos com Equipes &amp; Permissões
		</h3>

		<div class="mt-4 divide-y divide-outline-variant/50">
			{#each data.profiles as prof (prof.id)}
				{@const userTeamIds = data.teamMembers.filter((tm) => tm.user_id === prof.id).map((tm) => tm.team_id)}
				{@const userTeams = data.teams.filter((t) => userTeamIds.includes(t.id))}
				<div class="flex flex-wrap items-center justify-between gap-3 py-3">
					<div class="flex items-center gap-3">
						<div
							class="flex h-8 w-8 items-center justify-center rounded-full text-xs font-bold text-white"
							style="background-color: {prof.color || '#005AC2'}"
						>
							{getInitials(prof.name)}
						</div>
						<div>
							<div class="flex items-center gap-2">
								<span class="text-xs font-bold text-on-surface">{prof.name}</span>
								<!-- Team badges -->
								{#if userTeams.length > 0}
									<div class="flex flex-wrap items-center gap-1">
										{#each userTeams as uTeam (uTeam.id)}
											<span
												class="inline-flex items-center gap-1 rounded-[2px] border border-outline-variant bg-surface-container-low px-1.5 py-0.5 text-[10px] font-bold text-on-surface"
											>
												<span
													class="h-1.5 w-1.5 rounded-full"
													style="background-color: {uTeam.color || '#005AC2'}"
												></span>
												{uTeam.name}
											</span>
										{/each}
									</div>
								{:else}
									<span class="rounded-[2px] border border-outline-variant/60 bg-surface-container-low px-1.5 py-0.5 text-[10px] font-medium text-on-surface-variant">
										Sem Equipe Atribuída
									</span>
								{/if}
							</div>
							<div class="text-[11px] text-on-surface-variant">{prof.email || prof.id}</div>
						</div>
					</div>

					<div class="flex flex-wrap items-center gap-2">
						{#if isAdmin}
							<button
								type="button"
								onclick={() => {
									editingUserTeamsId = editingUserTeamsId === prof.id ? null : prof.id;
								}}
								class="inline-flex items-center gap-1 rounded-[4px] border border-outline-variant bg-surface-container-lowest px-2.5 py-1 text-xs font-bold text-on-surface shadow-[0_1px_0_#D8D2C2] hover:bg-surface-container-low"
							>
								<Shield class="h-3 w-3 text-primary" />
								Equipes ({userTeams.length})
							</button>
						{/if}

						<form method="POST" action="?/updateUserRole" class="flex items-center gap-2">
							<input type="hidden" name="id" value={prof.id} />
							<input type="hidden" name="name" value={prof.name} />
							<select
								name="role"
								disabled={!isAdmin}
								class="rounded-[4px] border border-outline-variant bg-surface-container px-2.5 py-1 text-xs font-medium text-on-surface"
							>
								<option value="admin" selected={prof.role === 'admin'}>Administrador</option>
								<option value="member" selected={prof.role === 'member'}>Membro</option>
								<option value="viewer" selected={prof.role === 'viewer'}>Visualizador</option>
							</select>
							{#if isAdmin}
								<button
									type="submit"
									class="rounded-[4px] border border-outline-variant bg-surface-container-low px-2.5 py-1 text-xs font-bold text-on-surface hover:bg-primary hover:text-on-primary hover:border-primary"
								>
									Salvar Cargo
								</button>
							{/if}
						</form>
					</div>
				</div>

				<!-- Inline Popover/Panel for editing user's multi-team memberships -->
				{#if editingUserTeamsId === prof.id && isAdmin}
					<form
						method="POST"
						action="?/updateUserTeams"
						class="mb-3 rounded-[6px] border border-outline-variant bg-primary-fixed/30 p-4 space-y-3"
					>
						<input type="hidden" name="userId" value={prof.id} />
						<div class="flex items-center justify-between">
							<div class="text-xs font-bold text-on-primary-fixed">
								Gerenciar Equipes de <span class="underline">{prof.name}</span>
							</div>
							<button
								type="button"
								onclick={() => (editingUserTeamsId = null)}
								class="text-on-surface-variant hover:text-on-surface"
							>
								<X class="h-3.5 w-3.5" />
							</button>
						</div>
						<p class="text-[11px] text-on-surface-variant">
							Selecione as equipes às quais este membro pertence. Deixe desmarcado se não tiver equipe atribuída.
						</p>
						<div class="grid grid-cols-1 gap-2 sm:grid-cols-2 md:grid-cols-4">
							{#each data.teams as t (t.id)}
								{@const checked = userTeamIds.includes(t.id)}
								<label
									class="flex cursor-pointer items-center gap-2 rounded-[4px] border p-2 text-xs transition {checked
										? 'border-primary bg-surface-container-lowest font-bold text-on-surface'
										: 'border-outline-variant bg-surface-container-lowest/70 text-on-surface-variant hover:bg-surface-container-lowest'}"
								>
									<input
										type="checkbox"
										name="teamIds"
										value={t.id}
										checked={checked}
										class="rounded-[2px] border-outline-variant text-primary"
									/>
									<span
										class="h-2 w-2 rounded-full"
										style="background-color: {t.color || '#005AC2'}"
									></span>
									<span class="truncate">{t.name}</span>
								</label>
							{/each}
						</div>
						<div class="flex justify-end gap-2 pt-1">
							<button
								type="button"
								onclick={() => (editingUserTeamsId = null)}
								class="rounded-[4px] border border-outline-variant bg-surface-container-lowest px-3 py-1 text-xs font-bold text-on-surface-variant hover:text-on-surface"
							>
								Cancelar
							</button>
							<button
								type="submit"
								class="rounded-[4px] bg-primary px-3 py-1 text-xs font-bold text-on-primary shadow-[0_2px_0_#004494] hover:opacity-95"
							>
								Salvar Equipes
							</button>
						</div>
					</form>
				{/if}
			{/each}
		</div>

		{#if isAdmin}
			<form
				method="POST"
				action="?/createUser"
				use:enhanceFormValidation
				class="mt-4 grid grid-cols-1 gap-3 border-t border-outline-variant/60 pt-4 sm:grid-cols-12"
			>
				<div class="sm:col-span-4">
					<label for="inv-name" class="block text-[11px] font-bold text-on-surface-variant uppercase">
						Nome Completo &amp; Cargo <span class="text-error">*</span>
					</label>
					<input
						id="inv-name"
						name="name"
						type="text"
						required
						placeholder="Ex.: Marina Silva (Dir. Marketing)"
						aria-errormessage="inv-name-err"
						class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2.5 py-1.5 text-xs text-on-surface"
					/>
					<div id="inv-name-err" class="error-msg">
						<AlertCircle class="h-3 w-3" />
						<span>O nome é obrigatório</span>
					</div>
				</div>
				<div class="sm:col-span-4">
					<label for="inv-email" class="block text-[11px] font-bold text-on-surface-variant uppercase">
						E-mail <span class="text-error">*</span>
					</label>
					<input
						id="inv-email"
						name="email"
						type="email"
						required
						placeholder="marketing@nuvemej.com.br"
						aria-errormessage="inv-email-err"
						class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2.5 py-1.5 text-xs text-on-surface"
					/>
					<div id="inv-email-err" class="error-msg">
						<AlertCircle class="h-3 w-3" />
						<span>E-mail válido obrigatório</span>
					</div>
				</div>
				<div class="sm:col-span-2">
					<label for="inv-role" class="block text-[11px] font-bold text-on-surface-variant uppercase">Cargo / Função</label>
					<select
						id="inv-role"
						name="role"
						class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2.5 py-1.5 text-xs text-on-surface"
					>
						<option value="member">Membro</option>
						<option value="admin">Administrador</option>
						<option value="viewer">Visualizador</option>
					</select>
				</div>
				<div class="flex items-end sm:col-span-2">
					<button
						type="submit"
						class="inline-flex w-full items-center justify-center gap-1 rounded-[4px] bg-primary px-3 py-1.5 text-xs font-bold text-on-primary shadow-[0_2px_0_#004494] hover:opacity-95"
					>
						<Plus class="h-3.5 w-3.5" />
						Convidar
					</button>
				</div>
			</form>
		{/if}
	</section>

	<!-- 3. Semester Cycles -->
	<section class="rounded-[6px] border border-outline-variant bg-surface-container-lowest p-6 shadow-[0_2px_8px_rgba(36,34,30,0.05)]">
		<h3 class="flex items-center gap-2 text-sm font-bold text-on-surface">
			<Calendar class="h-4 w-4 text-tertiary" />
			Ciclos Semestrais
		</h3>

		<div class="mt-4 grid grid-cols-1 gap-2.5 sm:grid-cols-2 md:grid-cols-4">
			{#each data.cycles as cyc (cyc.id)}
				<div
					class="flex items-center justify-between rounded-[6px] border border-outline-variant bg-surface-container-low/60 px-3.5 py-2.5"
				>
					<div>
						<div class="text-xs font-bold text-on-surface">{cyc.code}</div>
						<div class="text-[10px] font-medium text-on-surface-variant">
							{cyc.start_date} → {cyc.end_date}
						</div>
					</div>
					{#if isAdmin}
						<form method="POST" action="?/deleteCycle">
							<input type="hidden" name="cycleId" value={cyc.id} />
							<button
								type="submit"
								class="rounded-[2px] p-1 text-on-surface-variant hover:bg-error-container hover:text-error"
								title="Excluir ciclo"
							>
								<Trash2 class="h-3.5 w-3.5" />
							</button>
						</form>
					{/if}
				</div>
			{/each}
		</div>

		{#if isAdmin}
			<form
				method="POST"
				action="?/createCycle"
				use:enhanceFormValidation
				class="mt-4 grid grid-cols-1 gap-3 border-t border-outline-variant/60 pt-4 sm:grid-cols-12"
			>
				<div class="sm:col-span-2">
					<label for="cyc-year" class="block text-[11px] font-bold text-on-surface-variant uppercase"
						>Ano *</label
					>
					<input
						id="cyc-year"
						name="year"
						type="number"
						required
						value="2028"
						class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2.5 py-1.5 text-xs text-on-surface"
					/>
				</div>
				<div class="sm:col-span-2">
					<label for="cyc-sem" class="block text-[11px] font-bold text-on-surface-variant uppercase"
						>Semestre</label
					>
					<select
						id="cyc-sem"
						name="semester"
						class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2.5 py-1.5 text-xs text-on-surface"
					>
						<option value="1">S1</option>
						<option value="2">S2</option>
					</select>
				</div>
				<div class="sm:col-span-3">
					<label for="cyc-start" class="block text-[11px] font-bold text-on-surface-variant uppercase"
						>Data de Início *</label
					>
					<input
						id="cyc-start"
						name="start_date"
						type="date"
						required
						value="2028-01-01"
						class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2.5 py-1.5 text-xs text-on-surface"
					/>
				</div>
				<div class="sm:col-span-3">
					<label for="cyc-end" class="block text-[11px] font-bold text-on-surface-variant uppercase"
						>Data de Término *</label
					>
					<input
						id="cyc-end"
						name="end_date"
						type="date"
						required
						value="2028-06-30"
						class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-2.5 py-1.5 text-xs text-on-surface"
					/>
				</div>
				<div class="flex items-end sm:col-span-2">
					<button
						type="submit"
						class="inline-flex w-full items-center justify-center gap-1 rounded-[4px] bg-primary px-3 py-1.5 text-xs font-bold text-on-primary shadow-[0_2px_0_#004494] hover:opacity-95"
					>
						<Plus class="h-3.5 w-3.5" />
						Adicionar Ciclo
					</button>
				</div>
			</form>
		{/if}
	</section>

	<!-- 4. Seed Template & JSON Snapshot Export / Import -->
	<section class="rounded-[6px] border border-outline-variant bg-surface-container-lowest p-6 shadow-[0_2px_8px_rgba(36,34,30,0.05)]">
		<div class="flex flex-wrap items-center justify-between gap-4">
			<div>
				<h3 class="flex items-center gap-2 text-sm font-bold text-on-surface">
					<Database class="h-4 w-4 text-secondary" />
					Modelo Padrão EJ &amp; Exportação / Importação JSON
				</h3>
				<p class="mt-0.5 text-xs text-on-surface-variant">
					Baixe um backup portátil em JSON para passagem de gestão semestral ou restaure a partir de um backup.
				</p>
			</div>

			<div class="flex items-center gap-2">
				<button
					type="button"
					onclick={downloadSnapshot}
					class="inline-flex items-center gap-1.5 rounded-[4px] border border-outline-variant bg-surface-container-lowest px-3.5 py-2 text-xs font-bold text-on-surface shadow-[0_2px_0_#D8D2C2] hover:bg-surface-container-low"
				>
					<Download class="h-4 w-4 text-primary" />
					Exportar Backup JSON
				</button>

				{#if isAdmin}
					<form method="POST" action="?/resetTemplate">
						<button
							type="submit"
							class="inline-flex items-center gap-1.5 rounded-[4px] border border-outline-variant bg-secondary-fixed px-3.5 py-2 text-xs font-bold text-on-secondary-fixed shadow-[0_2px_0_#D8D2C2] hover:opacity-90"
						>
							<RotateCcw class="h-4 w-4" />
							Restaurar Modelo Padrão de EJ
						</button>
					</form>
				{/if}
			</div>
		</div>

		{#if isAdmin}
			<form
				method="POST"
				action="?/importJson"
				use:enhanceFormValidation
				class="mt-5 border-t border-outline-variant/60 pt-4"
			>
				<label for="import-json-area" class="block text-label-sm font-bold text-on-surface-variant uppercase tracking-wider">
					Importar Snapshot JSON <span class="text-error">*</span>
				</label>
				<textarea
					id="import-json-area"
					name="jsonText"
					rows="4"
					required
					placeholder='Cole o snapshot JSON exportado aqui (deve incluir "nodes" e "cycles")...'
					aria-errormessage="import-json-err"
					class="mt-1.5 w-full rounded-[4px] border border-outline-variant bg-surface-container p-3 text-xs text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:border-primary focus:bg-surface-container-lowest focus:outline-none"
				></textarea>
				<div id="import-json-err" class="error-msg">
					<AlertCircle class="h-3.5 w-3.5" />
					<span>Por favor, cole um snapshot JSON válido antes de importar.</span>
				</div>
				<div class="mt-2 flex justify-end">
					<button
						type="submit"
						class="inline-flex items-center gap-1.5 rounded-[4px] bg-primary px-4 py-2 text-xs font-bold text-on-primary shadow-[0_2px_0_#004494] hover:opacity-95"
					>
						<Upload class="h-3.5 w-3.5" />
						Importar Snapshot
					</button>
				</div>
			</form>
		{/if}
	</section>
</div>

<!-- Modal: New Team -->
{#if showNewTeamModal}
	<div
		role="presentation"
		onclick={() => (showNewTeamModal = false)}
		class="fixed inset-0 z-50 flex items-center justify-center bg-on-surface/35 p-4 backdrop-blur-[2px]"
	>
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			aria-labelledby="new-team-title"
			onclick={(e) => e.stopPropagation()}
			class="w-full max-w-md rounded-[6px] border border-outline-variant bg-surface-container-lowest p-6 shadow-[0_8px_24px_rgba(36,34,30,0.14)]"
		>
			<div class="flex items-center justify-between border-b border-outline-variant pb-3">
				<h3 id="new-team-title" class="text-sm font-bold text-on-surface flex items-center gap-1.5">
					<Shield class="h-4 w-4 text-primary" />
					Criar Nova Equipe
				</h3>
				<button
					type="button"
					onclick={() => (showNewTeamModal = false)}
					class="rounded-[4px] p-1 text-on-surface-variant hover:bg-surface-container hover:text-on-surface"
				>
					<X class="h-4 w-4" />
				</button>
			</div>

			<form
				method="POST"
				action="?/createTeam"
				use:enhanceFormValidation
				onsubmit={() => {
					setTimeout(() => (showNewTeamModal = false), 50);
				}}
				class="mt-4 space-y-3.5"
			>
				<div>
					<label for="new-team-name" class="block text-label-sm font-bold text-on-surface-variant uppercase">
						Nome da Equipe <span class="text-error">*</span>
					</label>
					<input
						id="new-team-name"
						name="name"
						type="text"
						required
						placeholder="Ex.: Marketing & Vendas, Projetos, Gente & Gestão"
						aria-errormessage="new-team-name-err"
						class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-3 py-1.5 text-xs text-on-surface"
					/>
					<div id="new-team-name-err" class="error-msg">
						<AlertCircle class="h-3 w-3" />
						<span>O nome da equipe é obrigatório</span>
					</div>
				</div>

				<div>
					<label for="new-team-desc" class="block text-label-sm font-bold text-on-surface-variant uppercase">
						Descrição (Opcional)
					</label>
					<textarea
						id="new-team-desc"
						name="description"
						rows="2"
						placeholder="Principais responsabilidades e escopo desta equipe..."
						class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-3 py-1.5 text-xs text-on-surface"
					></textarea>
				</div>

				<div>
					<label for="new-team-color" class="block text-label-sm font-bold text-on-surface-variant uppercase">
						Cor de Destaque
					</label>
					<div class="mt-1.5 flex items-center gap-2">
						<input
							id="new-team-color"
							name="color"
							type="color"
							value="#005AC2"
							class="h-8 w-14 cursor-pointer rounded-[4px] border border-outline-variant p-0.5"
						/>
						<span class="text-xs text-on-surface-variant">Escolha uma cor para crachás e etiquetas</span>
					</div>
				</div>

				<div class="flex justify-end gap-2 border-t border-outline-variant pt-3">
					<button
						type="button"
						onclick={() => (showNewTeamModal = false)}
						class="rounded-[4px] border border-outline-variant bg-surface-container-low px-3 py-1.5 text-xs font-bold text-on-surface-variant hover:text-on-surface"
					>
						Cancelar
					</button>
					<button
						type="submit"
						class="rounded-[4px] bg-primary px-4 py-1.5 text-xs font-bold text-on-primary shadow-[0_2px_0_#004494] hover:opacity-95"
					>
						Criar Equipe
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}

<!-- Modal: Edit Team -->
{#if editingTeam}
	<div
		role="presentation"
		onclick={() => (editingTeam = null)}
		class="fixed inset-0 z-50 flex items-center justify-center bg-on-surface/35 p-4 backdrop-blur-[2px]"
	>
		<!-- svelte-ignore a11y_click_events_have_key_events -->
		<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
		<div
			role="dialog"
			tabindex="-1"
			aria-modal="true"
			aria-labelledby="edit-team-title"
			onclick={(e) => e.stopPropagation()}
			class="w-full max-w-md rounded-[6px] border border-outline-variant bg-surface-container-lowest p-6 shadow-[0_8px_24px_rgba(36,34,30,0.14)]"
		>
			<div class="flex items-center justify-between border-b border-outline-variant pb-3">
				<h3 id="edit-team-title" class="text-sm font-bold text-on-surface flex items-center gap-1.5">
					<Edit3 class="h-4 w-4 text-primary" />
					Editar Equipe: {editingTeam.name}
				</h3>
				<button
					type="button"
					onclick={() => (editingTeam = null)}
					class="rounded-[4px] p-1 text-on-surface-variant hover:bg-surface-container hover:text-on-surface"
				>
					<X class="h-4 w-4" />
				</button>
			</div>

			<form
				method="POST"
				action="?/updateTeam"
				use:enhanceFormValidation
				onsubmit={() => {
					setTimeout(() => (editingTeam = null), 50);
				}}
				class="mt-4 space-y-3.5"
			>
				<input type="hidden" name="teamId" value={editingTeam.id} />
				<div>
					<label for="edit-team-name" class="block text-label-sm font-bold text-on-surface-variant uppercase">
						Nome da Equipe <span class="text-error">*</span>
					</label>
					<input
						id="edit-team-name"
						name="name"
						type="text"
						required
						bind:value={editingTeam.name}
						class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-3 py-1.5 text-xs text-on-surface"
					/>
				</div>

				<div>
					<label for="edit-team-desc" class="block text-label-sm font-bold text-on-surface-variant uppercase">
						Descrição
					</label>
					<textarea
						id="edit-team-desc"
						name="description"
						rows="2"
						bind:value={editingTeam.description}
						class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-3 py-1.5 text-xs text-on-surface"
					></textarea>
				</div>

				<div>
					<label for="edit-team-color" class="block text-label-sm font-bold text-on-surface-variant uppercase">
						Cor de Destaque
					</label>
					<div class="mt-1.5 flex items-center gap-2">
						<input
							id="edit-team-color"
							name="color"
							type="color"
							bind:value={editingTeam.color}
							class="h-8 w-14 cursor-pointer rounded-[4px] border border-outline-variant p-0.5"
						/>
						<span class="text-xs text-on-surface-variant">Cor do crachá na árvore estratégica</span>
					</div>
				</div>

				<div class="flex justify-end gap-2 border-t border-outline-variant pt-3">
					<button
						type="button"
						onclick={() => (editingTeam = null)}
						class="rounded-[4px] border border-outline-variant bg-surface-container-low px-3 py-1.5 text-xs font-bold text-on-surface-variant hover:text-on-surface"
					>
						Cancelar
					</button>
					<button
						type="submit"
						class="rounded-[4px] bg-primary px-4 py-1.5 text-xs font-bold text-on-primary shadow-[0_2px_0_#004494] hover:opacity-95"
					>
						Salvar Alterações
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}
