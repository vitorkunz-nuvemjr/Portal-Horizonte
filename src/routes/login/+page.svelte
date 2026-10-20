<script lang="ts">
	import { base } from '$app/paths';
	import { enhance } from '$app/forms';
	import { ShieldCheck, X, AlertCircle } from 'lucide-svelte';

	let { data, form } = $props();

	let email = $state('');
	let password = $state('');
	let name = $state('');
	let isSignUp = $state(false);
	let keepSession = $state(true);
	let showPassword = $state(false);
	let isSubmitting = $state(false);
	let socialMockNotice = $state(false);
	let infoModal = $state<{ title: string; message: string } | null>(null);

	function handleSocialMockClick() {
		socialMockNotice = true;
	}

	function openInfo(title: string, message: string) {
		infoModal = { title, message };
	}

	function closeInfo() {
		infoModal = null;
	}
</script>

<svelte:head>
	<title>Nuvem Jr. - Horizonte OKRs e Planejamento</title>
</svelte:head>

<div class="min-h-screen bg-[#fff8f2] text-[#1E1D1A] antialiased flex flex-col font-sans selection:bg-[#3080F9] selection:text-white">
	<!-- Top Navigation Header -->
	<header class="w-full h-16 border-b border-[#E8E2D8]/70 bg-[#FDFBF7]/95 backdrop-blur-md px-6 lg:px-12 flex items-center justify-between z-30 shrink-0">
		<div class="flex items-center gap-3">
			<div class="w-9 h-9 rounded-lg bg-white border border-[#E8E2D8] shadow-sm flex items-center justify-center p-1 overflow-hidden">
				<img src="{base}/logo-nuvem.png" alt="Nuvem Jr." class="w-full h-full object-contain" />
			</div>
			<div class="flex items-center gap-2">
				<span class="font-bold text-lg tracking-tight text-[#1E1D1A]">Nuvem Jr.</span>
				<span class="text-[11px] px-2 py-0.5 rounded-full bg-[#E8E2D8]/80 text-[#63625D] font-semibold uppercase tracking-wider">
					OKRs &amp; Strat
				</span>
			</div>
		</div>
		<div class="flex items-center gap-6">
			<div class="inline-flex items-center gap-1.5 text-xs text-[#63625D] font-medium">
				<span class="material-symbols-outlined text-[16px] text-emerald-600">verified</span>
				<span>Ambiente Seguro</span>
			</div>
			<button
				type="button"
				onclick={() => openInfo(
					'Suporte Executivo & Governança',
					'Para dúvidas operacionais sobre metas, credenciais corporativas ou auditoria de OKRs, contate a Governança Executiva da Nuvem Jr. pelo e-mail presidencia@nuvemej.com.br.'
				)}
				class="inline-flex items-center gap-1.5 text-xs text-[#63625D] hover:text-[#1E1D1A] transition-colors font-medium"
			>
				<span class="material-symbols-outlined text-[16px]">help</span>
				<span>Suporte Executivo</span>
			</button>
		</div>
	</header>

	<!-- Two-Column Executive Dossier Split Layout -->
	<div class="flex-1 flex flex-col lg:flex-row w-full">
		<!-- Left Column (45% Editorial / Brand Value Synthesis) -->
		<aside class="w-full lg:w-[45%] border-b lg:border-b-0 lg:border-r border-[#E8E2D8]/70 p-8 sm:p-10 lg:p-14 xl:p-16 flex flex-col justify-between relative bg-[#f9f3ec]">
			<div class="relative z-10 max-w-xl mx-auto lg:mx-0 w-full">
				<!-- Badge -->
				<div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/90 border border-[#E8E2D8] text-[#63625D] text-xs font-semibold uppercase tracking-wider shadow-sm mb-8">
					<span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
					Sistema de Acompanhamento de Estratégia
				</div>

				<!-- Headline & Manifesto -->
				<h1 class="text-2xl sm:text-3xl lg:text-[34px] font-semibold text-[#1E1D1A] tracking-tight leading-snug mb-4">
					Alinhamento em cascata do Conselho aos KRs de ponta.
				</h1>
				<p class="text-[#63625D] text-sm sm:text-base leading-relaxed mb-10">
					Transforme visões de longo prazo em cadência operacional transparente. A plataforma unificada para execução estratégica e gestão de metas da sua organização.
				</p>

				<!-- 3 Pillars Cards -->
				<div class="grid grid-cols-1 gap-3.5 mb-10">
					<!-- Pillar 1 -->
					<div class="p-4 rounded-xl bg-white/80 border border-[#E8E2D8] shadow-[0_1px_3px_rgba(30,29,26,0.04)] flex items-start gap-3.5 hover:border-[#0058bd]/40 transition-colors">
						<div class="w-9 h-9 rounded-lg bg-blue-50 text-[#0058bd] flex items-center justify-center shrink-0 mt-0.5">
							<span class="material-symbols-outlined text-[20px]">account_tree</span>
						</div>
						<div>
							<h3 class="text-sm font-semibold text-[#1E1D1A]">Árvore de KRs Hierárquica</h3>
							<p class="text-xs text-[#63625D] mt-0.5">Visão transparente de desdobramento de objetivos estratégicos e táticos.</p>
						</div>
					</div>

					<!-- Pillar 2 -->
					<div class="p-4 rounded-xl bg-white/80 border border-[#E8E2D8] shadow-[0_1px_3px_rgba(30,29,26,0.04)] flex items-start gap-3.5 hover:border-[#0058bd]/40 transition-colors">
						<div class="w-9 h-9 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center shrink-0 mt-0.5">
							<span class="material-symbols-outlined text-[20px]">published_with_changes</span>
						</div>
						<div>
							<h3 class="text-sm font-semibold text-[#1E1D1A]">Check-in Contínuo &amp; Confiança</h3>
							<p class="text-xs text-[#63625D] mt-0.5">Rituais quinzenais leves, com índices de confiança e projeções preditivas.</p>
						</div>
					</div>

					<!-- Pillar 3 -->
					<div class="p-4 rounded-xl bg-white/80 border border-[#E8E2D8] shadow-[0_1px_3px_rgba(30,29,26,0.04)] flex items-start gap-3.5 hover:border-[#0058bd]/40 transition-colors">
						<div class="w-9 h-9 rounded-lg bg-purple-50 text-purple-600 flex items-center justify-center shrink-0 mt-0.5">
							<span class="material-symbols-outlined text-[20px]">history_edu</span>
						</div>
						<div>
							<h3 class="text-sm font-semibold text-[#1E1D1A]">Rastreabilidade &amp; Governança</h3>
							<p class="text-xs text-[#63625D] mt-0.5">Dossiê e trilha de auditoria contínua para comitês e liderança executiva.</p>
						</div>
					</div>
				</div>
			</div>
		</aside>

		<!-- Right Column (55% Authentication Workspace) -->
		<main
			class="w-full lg:w-[55%] flex flex-col items-center justify-center p-6 sm:p-10 lg:p-12 xl:p-16 relative"
			style="background-color: rgb(255, 248, 242); background-image: radial-gradient(rgb(213, 205, 195) 1px, transparent 1px); background-size: 24px 24px;"
		>
			<div class="w-full max-w-[440px]">
				<!-- Archival Clipboard Login Card -->
				<div class="relative bg-[#fffdf9] rounded-2xl border border-[#e5ded4] shadow-[0_20px_45px_-10px_rgba(40,30,20,0.12),0_4px_12px_rgba(40,30,20,0.06),inset_0_1px_0_rgba(255,255,255,0.9)] p-8 sm:p-9 pt-10 transition-all">
					<!-- Paper Layer Backing Effect -->
					<div class="absolute -inset-1 bg-[#f4ece1] rounded-2xl -z-10 transform rotate-[0.6deg] shadow-sm border border-[#e8dfd5]"></div>

					<!-- Diagonal Folded Corner Accent (Top Right) -->
					<div class="absolute top-0 right-0 w-12 h-12 overflow-hidden pointer-events-none z-20">
						<div class="absolute top-0 right-0 w-12 h-12 bg-gradient-to-bl from-[#e6dcce] via-[#f0e8dc] to-transparent transform rotate-45 translate-x-6 -translate-y-6 shadow-sm border-b border-l border-[#d8cdbf]/70"></div>
					</div>

					<!-- Metallic Clipboard Clamp / Binder Clip -->
					<div class="absolute -top-5 left-1/2 -translate-x-1/2 flex flex-col items-center z-30 pointer-events-none">
						<div class="w-24 h-7 rounded-t-lg bg-gradient-to-b from-[#d8dbdf] via-[#bcc1c8] to-[#9fa5ae] border border-[#8a919a] shadow-[0_4px_8px_rgba(0,0,0,0.15),inset_0_1px_1px_rgba(255,255,255,0.8)] flex items-center justify-center gap-4">
							<div class="w-7 h-2 rounded-full bg-[#717781] shadow-[inset_0_1px_2px_rgba(0,0,0,0.6)]"></div>
							<div class="w-2 h-2 rounded-full bg-[#525861] shadow-[inset_0_1px_1px_rgba(0,0,0,0.8)]"></div>
						</div>
						<div class="w-28 h-2 bg-gradient-to-r from-[#949aa3] via-[#c6cbd2] to-[#8d939c] rounded-b shadow-[0_2px_4px_rgba(0,0,0,0.2)] border-b border-[#6c727a]"></div>
					</div>

					<!-- Header Brand Section: Overlapping Lenses Logo & Title -->
					<div class="flex flex-col items-center text-center mt-3 mb-6">
						<!-- Official ALIGNA Overlapping Lenses Geometric Icon -->
						<div class="w-16 h-14 flex items-center justify-center mb-1">
							<svg class="w-full h-full drop-shadow-sm" height="100%" viewBox="0 0 284 275" width="100%" xmlns="http://www.w3.org/2000/svg">
								<defs>
									<filter height="130%" id="drop-shadow" width="130%" x="-15%" y="-15%">
										<feDropShadow dx="-2" dy="6" flood-color="#000000" flood-opacity="0.12" stdDeviation="8"></feDropShadow>
									</filter>
									<rect height="116" id="shape-blue" rx="28" transform="rotate(6.5 116 109)" width="116" x="58" y="51"></rect>
									<rect height="90" id="shape-yellow" rx="22" transform="rotate(-44.5 150 154)" width="90" x="105" y="109"></rect>
									<rect height="116" id="shape-pink" rx="28" transform="rotate(-6 182 144)" width="116" x="124" y="86"></rect>
									<clipPath id="clip-blue"><use href="#shape-blue"></use></clipPath>
									<clipPath id="clip-yellow"><use href="#shape-yellow"></use></clipPath>
									<clipPath id="clip-pink"><use href="#shape-pink"></use></clipPath>
								</defs>
								<g filter="url(#drop-shadow)">
									<use fill="#F2DA24" href="#shape-yellow"></use>
									<use fill="#FA228E" href="#shape-pink"></use>
									<use fill="#2176F5" href="#shape-blue"></use>
									<g clip-path="url(#clip-blue)"><use fill="#275D2B" href="#shape-yellow"></use></g>
									<g clip-path="url(#clip-pink)"><use fill="#EA2317" href="#shape-yellow"></use></g>
									<g clip-path="url(#clip-blue)"><use fill="#240E8B" href="#shape-pink"></use></g>
									<g clip-path="url(#clip-blue)"><g clip-path="url(#clip-pink)"><use fill="#261015" href="#shape-yellow"></use></g></g>
								</g>
							</svg>
						</div>
						<div class="flex items-center justify-center gap-2">
							<h2 class="text-2xl font-extrabold text-[#0f172a] tracking-tight">Horizonte</h2>
							<span class="px-2 py-0.5 rounded-md bg-[#f1f5f9] border border-[#cbd5e1] text-[10px] font-bold text-[#475569] tracking-wider">
								OKRs
							</span>
						</div>
						<h3 class="text-[15px] font-bold text-[#0058bd] mt-1 tracking-tight">Acompanhamento e métricas da Nuvem Jr.</h3>
						<p class="text-xs text-[#64748b] mt-1 max-w-xs leading-relaxed">Acesse seu dossiê e árvore de metas estratégicas da nossa EJ.</p>
					</div>

					<!-- Quick SSO Mockup Button -->
					<div class="mb-5">
						<button
							class="w-full h-11 px-4 rounded-xl border border-[#e2e8f0] hover:border-[#cbd5e1] bg-white hover:bg-[#f8fafc] text-[#1e293b] text-xs font-semibold flex items-center justify-center gap-2.5 transition-all shadow-[0_1px_2px_rgba(0,0,0,0.04)] active:translate-y-px"
							type="button"
							onclick={handleSocialMockClick}
						>
							<svg class="w-4 h-4 shrink-0" viewBox="0 0 24 24">
								<path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"></path>
								<path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"></path>
								<path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z" fill="#FBBC05"></path>
								<path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" fill="#EA4335"></path>
							</svg>
							<span>Continuar com Google Workspace</span>
						</button>

						<!-- Social Mockup Notice Alert -->
						{#if socialMockNotice}
							<div class="mt-2.5 p-3 rounded-lg bg-amber-50/90 border border-amber-200 text-[11px] text-amber-900 flex items-start gap-2 animate-fadeIn">
								<span class="material-symbols-outlined text-[16px] text-amber-600 shrink-0 mt-0.5">info</span>
								<div class="flex-1">
									<strong class="font-semibold">Modo Mockup:</strong> A autenticação federada com Google Workspace está em homologação. Insira suas credenciais corporativas no formulário abaixo para acessar a plataforma.
								</div>
								<button
									type="button"
									onclick={() => (socialMockNotice = false)}
									class="text-amber-700 hover:text-amber-950 p-0.5"
									aria-label="Fechar aviso"
								>
									<X class="w-3.5 h-3.5" />
								</button>
							</div>
						{/if}
					</div>

					<!-- Divider -->
					<div class="relative flex items-center justify-center mb-5">
						<div class="w-full border-t border-dashed border-[#cbd5e1]"></div>
						<span class="absolute px-3 bg-[#fffdf9] text-[10px] font-bold text-[#94a3b8] uppercase tracking-wider">
							OU CREDENCIAIS CORPORATIVAS
						</span>
					</div>

					<!-- Server Feedback Message -->
					{#if form?.message}
						<div class="mb-4 flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 p-3 text-xs font-semibold text-red-700">
							<AlertCircle class="h-4 w-4 shrink-0 text-red-600" />
							<span>{form.message}</span>
						</div>
					{/if}

					{#if form?.notice}
						<div class="mb-4 flex items-center gap-2 rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-xs font-semibold text-emerald-800">
							<span class="material-symbols-outlined text-[16px] text-emerald-600">check_circle</span>
							<span>{form.notice}</span>
						</div>
					{/if}

					<!-- Form -->
					<form
						method="POST"
						action={isSignUp ? '?/signup' : '?/login'}
						class="space-y-4"
						id="loginForm"
						use:enhance={() => {
							isSubmitting = true;
							return async ({ update }) => {
								isSubmitting = false;
								await update();
							};
						}}
					>
						{#if isSignUp}
							<!-- User Full Name (Signup only) -->
							<div class="space-y-1.5 animate-fadeIn">
								<label class="block text-xs font-semibold text-[#1e293b]" for="user-name">
									Nome Completo
								</label>
								<div class="relative flex items-center">
									<span class="material-symbols-outlined text-[18px] text-[#94a3b8] absolute left-3.5 pointer-events-none">
										person
									</span>
									<input
										class="w-full h-11 pl-10 pr-3.5 rounded-xl bg-[#fdfbf7] border border-[#e2d9cd] text-sm text-[#1e293b] placeholder:text-[#94a3b8] shadow-[inset_0_1px_2px_rgba(0,0,0,0.03)] focus:bg-white focus:outline-none focus:border-[#0058bd] focus:ring-2 focus:ring-[#0058bd]/20 transition-all font-sans"
										id="user-name"
										name="name"
										bind:value={name}
										placeholder="Vitor Kunz"
										required
										type="text"
										autocomplete="name"
									/>
								</div>
							</div>
						{/if}

						<!-- Corporate Email -->
						<div class="space-y-1.5">
							<div class="flex items-center justify-between">
								<label class="block text-xs font-semibold text-[#1e293b]" for="corporate-email">
									E-mail corporativo
								</label>
								<span class="text-[11px] text-[#94a3b8]">Domínio verificado</span>
							</div>
							<div class="relative flex items-center">
								<span class="material-symbols-outlined text-[18px] text-[#94a3b8] absolute left-3.5 pointer-events-none">
									alternate_email
								</span>
								<input
									class="w-full h-11 pl-10 pr-3.5 rounded-xl bg-[#fdfbf7] border border-[#e2d9cd] text-sm text-[#1e293b] placeholder:text-[#94a3b8] shadow-[inset_0_1px_2px_rgba(0,0,0,0.03)] focus:bg-white focus:outline-none focus:border-[#0058bd] focus:ring-2 focus:ring-[#0058bd]/20 transition-all font-sans"
									id="corporate-email"
									name="email"
									bind:value={email}
									placeholder="seu.email@nuvemjr.com.br"
									required
									type="email"
									autocomplete="username"
								/>
							</div>
						</div>

						<!-- Access Password -->
						<div class="space-y-1.5">
							<div class="flex items-center justify-between">
								<label class="block text-xs font-semibold text-[#1e293b]" for="corporate-password">
									Senha de acesso
								</label>
								{#if !isSignUp}
									<button
										type="button"
										onclick={() => openInfo(
											'Redefinição de Senha',
											'Para redefinir sua senha corporativa, solicite à Governança Institucional da Nuvem Jr. através do e-mail presidencia@nuvemej.com.br ou pelo canal interno de TI.'
										)}
										class="text-xs font-medium text-[#0058bd] hover:underline"
									>
										Esqueceu a senha?
									</button>
								{/if}
							</div>
							<div class="relative flex items-center">
								<span class="material-symbols-outlined text-[18px] text-[#94a3b8] absolute left-3.5 pointer-events-none">
									lock
								</span>
								<input
									class="w-full h-11 pl-10 pr-10 rounded-xl bg-[#fdfbf7] border border-[#e2d9cd] text-sm text-[#1e293b] placeholder:text-[#94a3b8] shadow-[inset_0_1px_2px_rgba(0,0,0,0.03)] focus:bg-white focus:outline-none focus:border-[#0058bd] focus:ring-2 focus:ring-[#0058bd]/20 transition-all font-sans"
									id="corporate-password"
									name="password"
									bind:value={password}
									placeholder="••••••••••••"
									required
									type={showPassword ? 'text' : 'password'}
									autocomplete={isSignUp ? 'new-password' : 'current-password'}
								/>
								<button
									aria-label="Alternar exibição da senha"
									class="absolute right-3 p-1 text-[#94a3b8] hover:text-[#1e293b] transition-colors"
									id="togglePassword"
									type="button"
									onclick={() => (showPassword = !showPassword)}
								>
									<span class="material-symbols-outlined text-[18px] block" id="passwordEyeIcon">
										{showPassword ? 'visibility_off' : 'visibility'}
									</span>
								</button>
							</div>
						</div>

						{#if !isSignUp}
							<!-- Keep Session -->
							<div class="flex items-center pt-0.5">
								<label class="flex items-center gap-2.5 cursor-pointer select-none">
									<input
										class="w-4 h-4 rounded border-[#cbd5e1] text-[#0058bd] focus:ring-[#0058bd]/30 cursor-pointer"
										id="keepSession"
										name="keepSession"
										type="checkbox"
										bind:checked={keepSession}
									/>
									<span class="text-xs text-[#475569] font-normal">Manter sessão ativa neste dispositivo</span>
								</label>
							</div>
						{/if}

						<!-- Submit Button -->
						<button
							class="w-full h-12 mt-2 rounded-xl bg-[#0058bd] hover:bg-[#00479b] text-white text-sm font-semibold tracking-wide flex items-center justify-center gap-2 shadow-md shadow-[#0058bd]/25 transition-all duration-150 active:translate-y-0.5 disabled:opacity-75 disabled:cursor-not-allowed"
							id="submitButton"
							type="submit"
							disabled={isSubmitting}
						>
							{#if isSubmitting}
								<span class="material-symbols-outlined text-[18px] animate-spin">sync</span>
								<span>{isSignUp ? 'Criando conta...' : 'Autenticando...'}</span>
							{:else}
								<span>{isSignUp ? 'Criar Conta no Supabase' : 'Entrar na Plataforma'}</span>
								<span class="material-symbols-outlined text-[18px]">arrow_forward</span>
							{/if}
						</button>
					</form>

					<!-- Footer Links inside card -->
					<div class="mt-6 pt-5 border-t border-[#f1ece4] flex flex-col items-center gap-2 text-center text-xs">
						{#if isSignUp}
							<div class="text-[#64748b]">Já possui uma conta cadastrada?</div>
							<button
								type="button"
								onclick={() => (isSignUp = false)}
								class="text-[#0058bd] font-semibold hover:underline"
							>
								Fazer Login com sua conta existente
							</button>
						{:else}
							<div class="text-[#64748b]">Não tem credenciais de acesso?</div>
							<div class="font-semibold text-xs flex items-center justify-center gap-1.5">
								<button
									type="button"
									onclick={() => (isSignUp = true)}
									class="text-[#0058bd] hover:underline"
								>
									Criar Conta
								</button>
								<span class="text-[#94a3b8]">•</span>
								<button
									type="button"
									onclick={() => openInfo(
										'Solicitar Acesso à Governança',
										'O acesso ao Horizonte OKRs é restrito a membros e conselheiros autorizados da Nuvem Jr. Entre em contato com a Diretoria Executiva ou envie solicitação para adm.fin@nuvemjr.com.br.'
									)}
									class="text-pink-600 hover:text-pink-700 hover:underline"
								>
									Solicitar Acesso
								</button>
							</div>
						{/if}
					</div>


				</div>
			</div>
		</main>
	</div>

	<!-- Bottom Page Footer -->
	<footer class="w-full border-t border-[#E8E2D8]/70 bg-white/70 px-6 lg:px-12 py-3 flex flex-col sm:flex-row items-center justify-between gap-2 text-xs text-[#63625D] shrink-0">
		<div class="flex items-center gap-2">
			<span class="font-medium text-[#1E1D1A]">NUVEM HORIZONTE OKRs</span>
			<span>•</span>
			<span>Arquitetura de Gestão Estratégica</span>
		</div>
		<div class="text-[11px]">
			© 2026 Nuvem Júnior. Todos os direitos reservados.
		</div>
	</footer>

	<!-- Informational Modal / Dialog -->
	{#if infoModal}
		<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-xs p-4 animate-fadeIn">
			<div class="w-full max-w-md bg-white rounded-2xl border border-[#E8E2D8] shadow-2xl p-6 relative">
				<button
					type="button"
					onclick={closeInfo}
					class="absolute top-4 right-4 text-[#8C8A83] hover:text-[#1E1D1A] p-1 rounded-lg hover:bg-black/5 transition"
					aria-label="Fechar diálogo"
				>
					<X class="w-5 h-5" />
				</button>
				<div class="flex items-center gap-3 mb-3">
					<div class="w-10 h-10 rounded-xl bg-blue-50 text-[#0058bd] flex items-center justify-center">
						<span class="material-symbols-outlined text-[22px]">info</span>
					</div>
					<h3 class="text-base font-bold text-[#1E1D1A]">{infoModal.title}</h3>
				</div>
				<p class="text-xs text-[#63625D] leading-relaxed mb-6">
					{infoModal.message}
				</p>
				<button
					type="button"
					onclick={closeInfo}
					class="w-full h-10 rounded-xl bg-[#0058bd] hover:bg-[#00479b] text-white text-xs font-semibold tracking-wide transition shadow-sm"
				>
					Entendido
				</button>
			</div>
		</div>
	{/if}
</div>

<style>
	@keyframes fadeIn {
		from {
			opacity: 0;
			transform: scale(0.98);
		}
		to {
			opacity: 1;
			transform: scale(1);
		}
	}

	.animate-fadeIn {
		animation: fadeIn 0.15s ease-out forwards;
	}
</style>
