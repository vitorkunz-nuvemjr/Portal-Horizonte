<script lang="ts">
	import { enhanceFormValidation, getInitials } from '$lib/utils';
	import { ShieldCheck, AlertCircle, ArrowRight } from 'lucide-svelte';

	let { data, form } = $props();
</script>

<div class="relative flex min-h-screen flex-col items-center justify-center bg-surface mat-grid-pattern px-4 py-12">
	<!-- Top Drafting Ruler Strip -->
	<div class="fixed top-0 left-0 right-0 h-2 mat-ruler-h border-b border-outline-variant opacity-60"></div>

	<div class="w-full max-w-md space-y-6">
		<!-- Brand Header -->
		<div class="text-center">
			<div
				class="mx-auto flex h-12 w-12 items-center justify-center rounded-[4px] bg-primary text-lg font-bold text-on-primary shadow-[0_3px_0_#001B3E]"
			>
				<span class="material-symbols-outlined text-2xl">architecture</span>
			</div>
			<h1 class="mt-4 text-headline-lg font-bold tracking-tight text-on-surface">ALIGNA</h1>
			<p class="text-[10px] font-bold uppercase tracking-widest text-outline">
				Strategic OKR Matrix
			</p>
			<p class="mt-1.5 text-xs text-on-surface-variant">
				Planejamento Estratégico — Objetivos, Key Results, KPIs &amp; Identidade Organizacional
			</p>
		</div>

		{#if form?.message}
			<div
				class="flex items-center gap-2 rounded-[6px] border border-error/40 bg-error-container px-4 py-3 text-xs font-semibold text-on-error-container"
			>
				<AlertCircle class="h-4 w-4 shrink-0 text-error" />
				<span>{form.message}</span>
			</div>
		{/if}

		<!-- Quick Local Persona Login -->
		{#if data.mode === 'local'}
			<div class="rounded-[6px] border border-outline-variant bg-surface-container-lowest p-5 shadow-[0_2px_8px_rgba(36,34,30,0.06)]">
				<div class="flex items-center justify-between">
					<h2 class="text-label-sm font-bold tracking-wider text-on-surface uppercase">
						Acesso Rápido com 1 Clique (Ambiente Local)
					</h2>
					<span class="rounded-[2px] border border-outline-variant bg-primary-fixed px-2 py-0.5 text-[10px] font-bold text-on-primary-fixed uppercase">
						Modo Local
					</span>
				</div>
				<p class="mt-1 text-xs text-on-surface-variant">
					Escolha um perfil de equipe abaixo para navegar com diferentes permissões (Administrador,
					Membro ou Visualizador).
				</p>

				<div class="mt-3 space-y-2">
					{#each data.profiles as profile (profile.id)}
						<form method="POST" action="?/switchUser">
							<input type="hidden" name="userId" value={profile.id} />
							<button
								type="submit"
								class="flex w-full items-center justify-between rounded-[4px] border border-outline-variant bg-surface-container-low/70 px-3.5 py-2.5 text-left transition hover:border-primary hover:bg-surface-container-lowest hover:shadow-[0_2px_0_#D8D2C2]"
							>
								<div class="flex items-center gap-3">
									<div
										class="flex h-8 w-8 items-center justify-center rounded-full text-xs font-bold text-white"
										style="background-color: {profile.color || '#005AC2'}"
									>
										{getInitials(profile.name)}
									</div>
									<div>
										<div class="text-xs font-bold text-on-surface">{profile.name}</div>
										<div class="text-[11px] text-on-surface-variant">{profile.email}</div>
									</div>
								</div>
								<div class="flex items-center gap-2">
									<span
										class="inline-flex items-center gap-1 rounded-[2px] border border-outline-variant bg-surface-container-lowest px-2 py-0.5 text-[10px] font-bold uppercase text-on-surface"
									>
										<ShieldCheck class="h-3 w-3 text-primary" />
										{profile.role === 'admin'
											? 'Administrador'
											: profile.role === 'member'
												? 'Membro'
												: 'Visualizador'}
									</span>
									<ArrowRight class="h-4 w-4 text-outline" />
								</div>
							</button>
						</form>
					{/each}
				</div>
			</div>
		{/if}

		<!-- Standard Email / Password Form -->
		<form
			method="POST"
			action="?/login"
			use:enhanceFormValidation
			class="space-y-4 rounded-[6px] border border-outline-variant bg-surface-container-lowest p-6 shadow-[0_2px_8px_rgba(36,34,30,0.06)]"
		>
			<h2 class="text-label-sm font-bold tracking-wider text-on-surface uppercase">
				Entrar com E-mail e Senha
			</h2>

			<div>
				<label for="login-email" class="block text-label-sm font-bold text-on-surface-variant uppercase">
					Endereço de E-mail <span class="text-error">*</span>
				</label>
				<input
					id="login-email"
					name="email"
					type="email"
					required
					placeholder="presidencia@nuvemej.com.br"
					aria-errormessage="login-email-err"
					class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-3 py-2 text-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:border-primary focus:bg-surface-container-lowest focus:outline-none"
				/>
				<div id="login-email-err" class="error-msg">
					<AlertCircle class="h-3.5 w-3.5" />
					<span>Por favor, insira um endereço de e-mail válido.</span>
				</div>
			</div>

			<div>
				<label for="login-password" class="block text-label-sm font-bold text-on-surface-variant uppercase">
					Senha <span class="text-error">*</span>
				</label>
				<input
					id="login-password"
					name="password"
					type="password"
					required
					minlength="4"
					placeholder="••••••••"
					aria-errormessage="login-pass-err"
					class="mt-1 w-full rounded-[4px] border border-outline-variant bg-surface-container px-3 py-2 text-sm text-on-surface shadow-[inset_0_2px_4px_rgba(36,34,30,0.06)] focus:border-primary focus:bg-surface-container-lowest focus:outline-none"
				/>
				<div id="login-pass-err" class="error-msg">
					<AlertCircle class="h-3.5 w-3.5" />
					<span>A senha é obrigatória.</span>
				</div>
			</div>

			<button
				type="submit"
				class="w-full rounded-[4px] bg-primary py-2.5 text-xs font-bold text-on-primary shadow-[0_2px_0_#004494] transition hover:opacity-95"
			>
				Entrar
			</button>
		</form>
	</div>
</div>
