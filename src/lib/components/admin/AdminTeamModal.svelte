<script lang="ts">
	import { enhance } from '$app/forms';
	import type { Profile, Team } from '$lib/types';
	import { enhanceFormValidation, getInitials } from '$lib/utils';
	import { getDossierTheme } from '$lib/dossier-theme';
	import PaperColorPicker from '$lib/components/ui/PaperColorPicker.svelte';
	import PaperIconPicker from '$lib/components/ui/PaperIconPicker.svelte';

	interface Props {
		data: any;
		activeTeamModal: {
			mode: 'create' | 'edit';
			id: string;
			name: string;
			description: string;
			color: string;
			icon: string;
			memberIds: string[];
		} | null;
		teamToDelete?: Team | null;
	}

	let {
		data,
		activeTeamModal = $bindable(),
		teamToDelete = $bindable()
	}: Props = $props();

	let showAddMemberDropdown = $state(false);

	const modalTheme = $derived(
		activeTeamModal ? getDossierTheme(activeTeamModal.color) : getDossierTheme('#059669')
	);

	const teamIndex = $derived.by(() => {
		if (!activeTeamModal || !activeTeamModal.id) return '01';
		const idx = data.teams?.findIndex((t: Team) => t.id === activeTeamModal!.id) ?? -1;
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
							class="material-symbols-outlined text-[15px] shrink-0"
							style="color: {activeTeamModal.color};"
						>
							{activeTeamModal.icon || 'storefront'}
						</span>
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

			<!-- 2. CORPO DA PASTA FÍSICA -->
			<form
				method="POST"
				action={activeTeamModal.mode === 'create' ? '?/createTeam' : '?/updateTeam'}
				use:enhance={() => {
					return async ({ result, update }) => {
						if (result.type === 'success') {
							activeTeamModal = null;
						}
						await update({ reset: false });
					};
				}}
				use:enhanceFormValidation
				class="w-full border-2 rounded-2xl rounded-tl-none hanging-folder-shadow flex flex-col relative overflow-hidden transition-colors duration-200"
				style="background-color: {modalTheme.folderBg}; border-color: {modalTheme.folderBorder};"
			>
				{#if activeTeamModal.mode === 'edit'}
					<input type="hidden" name="teamId" value={activeTeamModal.id} />
				{/if}
				<input type="hidden" name="color" value={activeTeamModal.color} />
				<input type="hidden" name="icon" value={activeTeamModal.icon} />
				<input type="hidden" name="hasMemberIds" value="true" />
				{#each activeTeamModal.memberIds as mid}
					<input type="hidden" name="memberIds" value={mid} />
				{/each}

				<!-- Textura de papel / Linha de reforço estrutural -->
				<div
					class="h-1.5 w-full relative z-10 border-b transition-colors duration-200"
					style="background: linear-gradient(to right, color-mix(in srgb, {activeTeamModal.color} 25%, transparent), color-mix(in srgb, {activeTeamModal.color} 45%, transparent), color-mix(in srgb, {activeTeamModal.color} 20%, transparent)); border-color: {modalTheme.folderBorder};"
				></div>

				<!-- ÁREA INTERNA DA PASTA -->
				<div class="p-4 sm:p-6 lg:p-7 max-h-[calc(88vh-135px)] overflow-y-auto custom-scroll relative z-10 space-y-6">
					<div class="grid grid-cols-1 lg:grid-cols-12 gap-5 lg:gap-6 items-start">
						<!-- COLUNA DA ESQUERDA: IDENTIFICAÇÃO & ÍCONE -->
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

								<!-- Seletor de Ícone & Cor da Equipe -->
								<div class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-1 border-t border-[#edf4ee] items-start">
									<div class="space-y-2.5">
										<div class="flex items-center justify-between">
											<span class="font-mono text-[10.5px] uppercase tracking-wider font-bold text-[#424753]">
												Ícone da Equipe
											</span>
										</div>
										<div class="pt-0.5">
											<PaperIconPicker
												bind:value={activeTeamModal.icon}
												color={activeTeamModal.color}
												label="Alterar Ícone"
												align="left"
											/>
										</div>
									</div>

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

						<!-- COLUNA DA DIREITA: MEMBROS DA EQUIPE -->
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

										{#if showAddMemberDropdown}
											{@const availableProfiles = (data.profiles ?? []).filter(
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
																	class="w-6 h-6 rounded-full text-white text-[9px] font-bold flex items-center justify-center shrink-0 overflow-hidden"
																	style="background-color: {p.color || '#004190'}"
																>
																	{#if p.avatar_url || (p as any).image}
																		<img src={p.avatar_url || (p as any).image} alt={p.name} class="w-full h-full object-cover" />
																	{:else}
																		{getInitials(p.name)}
																	{/if}
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
											{@const mem = data.profiles?.find((p: Profile) => p.id === mid)}
											{#if mem}
												{@const isLeader = mem.role === 'admin' || idx === 0}
												<div
													class="flex items-center justify-between p-2.5 rounded-xl bg-[#f8fbf8] border transition-all"
													style="border-color: {modalTheme.inputBorder};"
												>
													<div class="flex items-center gap-2.5 min-w-0">
														<div
															class="w-8 h-8 rounded-full text-white font-bold text-[11.5px] flex items-center justify-center shrink-0 shadow-xs overflow-hidden"
															style="background-color: {mem.color || activeTeamModal.color}"
														>
															{#if mem.avatar_url || (mem as any).image}
																<img src={mem.avatar_url || (mem as any).image} alt={mem.name} class="w-full h-full object-cover" />
															{:else}
																{getInitials(mem.name)}
															{/if}
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

						<!-- SEÇÃO INFERIOR: KRS ASSOCIADOS -->
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

				<!-- 3. RODAPÉ DA PASTA -->
				<div
					class="relative z-10 border-t px-5 sm:px-7 py-3.5 transition-colors duration-200"
					style="background-color: {modalTheme.footerBg}; border-color: {modalTheme.folderBorder};"
				>
					<div
						class="h-[1.5px] w-full mb-3 opacity-75"
						style="background-image: repeating-linear-gradient(to right, {modalTheme.stitchedColor} 0px, {modalTheme.stitchedColor} 6px, transparent 6px, transparent 11px);"
					></div>

					<div class="flex flex-col sm:flex-row items-center justify-between gap-3">
						{#if activeTeamModal.mode === 'edit'}
							<button
								type="button"
								onclick={() => {
									const targetTeam = data.teams?.find((t: Team) => t.id === activeTeamModal!.id);
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
