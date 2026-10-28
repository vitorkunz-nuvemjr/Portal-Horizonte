<script lang="ts">
	import { base } from '$app/paths';
	import { getDossierTheme } from '$lib/dossier-theme';

	let showSupportModal = $state(false);
	const supportTheme = getDossierTheme('#b00066');

	function closeSupportModal() {
		showSupportModal = false;
	}

	function handleKeydown(e: KeyboardEvent) {
		if (e.key === 'Escape' && showSupportModal) {
			closeSupportModal();
		}
	}
</script>

<svelte:window onkeydown={handleKeydown} />

<!-- BEGIN: Footer -->
<footer class="w-full bg-[#fff8f1]/95 backdrop-blur-md relative z-10 text-[#1d1b17] mt-auto border-t border-amber-900/10">
	<!-- Borda superior técnica mat-ruler -->
	<div class="w-full h-1 bg-gradient-to-r from-amber-900/10 via-amber-900/20 to-amber-900/10 relative overflow-hidden">
		<div
			class="absolute inset-0 opacity-40"
			style="background-image: repeating-linear-gradient(90deg, #727784, #727784 1px, transparent 1px, transparent 12px);"
		></div>
	</div>

	<!-- Top section: Logos & Links -->
	<div class="max-w-7xl mx-auto px-4 sm:px-6 py-5 sm:py-6">
		<div class="grid grid-cols-1 lg:grid-cols-12 gap-5 lg:gap-6 items-center">
			<!-- 1 e 2. Linha unificada no mobile (lado esquerdo / lado direito), 2 colunas separadas no desktop -->
			<div class="lg:col-span-8 flex flex-row items-center justify-between gap-3 sm:gap-4 lg:grid lg:grid-cols-2 lg:gap-6">
				<!-- 1. Lado esquerdo: Horizonte OKRs Brand, Subtítulo & Badge -->
				<div class="flex items-center gap-2 sm:gap-3 shrink-0 sm:shrink">
					<img
						alt="Logotipo Horizonte OKRs"
						class="h-7 sm:h-8 lg:h-10 w-auto object-contain shrink-0"
						src="{base}/footer-horizonte-logo.png"
						onerror={(e) => {
							const img = e.currentTarget as HTMLImageElement;
							img.src = 'https://lh3.googleusercontent.com/aida-public/AB6AXuC5Qqj47nomhU0_0484DHCQXJIiS6v5OG2B7OgsQf3B_J8Obx-tRRSkGX-bb4G5I17H7THd_tX-tkqVTFGmwWxUQBC53-Nscq1Uj1qN6RqKpxtZTLfSMXw12H5MIORawV7hqbJ6pm6fGgPfiU7CLASDpvl8D1kTyeSEc14ALklxf4TE9LwQPF6QNjAZO27SBe7yE7-r4ewB8Xds3WjeE0Eup6UXogMxkwL5-J7xIp0d_Z5tfsWVHZOPTVHYdGYpu63rSb4';
						}}
					/>
					<div class="flex flex-col">
						<div class="flex items-center gap-2">
							<span class="font-display font-bold text-xs sm:text-sm tracking-tight text-[#1d1b17]">
								Horizonte OKRs
							</span>
						</div>
						<span class="text-[9px] sm:text-[10px] lg:text-[11px] font-medium text-slate-500 tracking-wider whitespace-nowrap">
							Planejamento estratégico
						</span>
					</div>
				</div>

				<!-- 2. Lado direito (mobile) / Centro absoluto (desktop): Nuvem Consultoria Jr. + Assinatura -->
				<div class="flex flex-col items-end sm:items-center justify-center text-right sm:text-center py-0 lg:py-0 lg:border-x border-amber-900/10 lg:px-4 shrink-0 sm:shrink">
					<div class="flex items-center gap-1.5 sm:gap-2 lg:gap-2.5 mb-0.5 sm:mb-1">
						<img
							alt="Logotipo Nuvem Consultoria Jr."
							class="h-6 sm:h-7 lg:h-[34px] w-auto object-contain shrink-0"
							src="{base}/footer-nuvem-cloud.png"
							onerror={(e) => {
								const img = e.currentTarget as HTMLImageElement;
								img.src = 'https://lh3.googleusercontent.com/aida-public/AB6AXuBOF6-LATC3s4WLDhRY4TpE9-tPjF77n3RtkXloohy55ih-GL4s1kwGGzX83uPj6-a7gipSg0zZxbhjX-h3tApv7wds74oSq_r92XXVh0LZgFTFa1JE3icidtFOUHR-bl4leZmKAcUtkWJ1aGOBtOkOQUX27zaJGwuKz8x_g_RzzyMyyD8evDx9ZsNJuh0VuXbATaXKBc_0-VnwwL5v0HJywzkbjMZxassF3Pe7vz3IX8VADrS8ShLhfyO2J5NxqSkPnHw';
							}}
						/>
						<img
							alt="Nuvem Jr."
							class="h-3.5 sm:h-4.5 lg:h-6 w-auto object-contain inline-block"
							src="{base}/footer-nuvem-text.png"
							onerror={(e) => {
								const img = e.currentTarget as HTMLImageElement;
								img.src = 'https://lh3.googleusercontent.com/aida-public/AB6AXuBf57U3gHNoUNMaF34LPEERj5PaHZOACH85VFsYQx3WAS2IyuOWuF-mPk3DhlwfQekqzTGtaF1GaQzHf62N1eRkSHJXvsig_1ostXm46pxxNVEb_1iuJEzWCd7FzDcgf0qLifFrH-nQxGuoaTH6hfzzDtJ1wa6BKT8bTOo0CL5gSHte9E4beFnzkohJuSY5JrRFnOVkPbka0kvlBqKf-D2rscHs2mfzTzwMtr3Tc-NCCfm8LUG6_9wLBk6EGf3kFCzRehw';
							}}
						/>
					</div>
					<p class="text-[9px] sm:text-[10px] lg:text-[11px] text-[#727784] font-normal leading-tight max-w-[155px] sm:max-w-xs">
						Viva o novo. Experimente o inusitado!
					</p>
				</div>
			</div>

			<!-- 3. Lado direito: Governança, Suporte GP & Direitos Reservados -->
			<div class="lg:col-span-4 flex flex-col items-center sm:items-start lg:items-end justify-center gap-1.5 text-xs pt-3 lg:pt-0 border-t lg:border-t-0 border-amber-900/10">
				<div class="flex flex-wrap items-center justify-center sm:justify-start lg:justify-end gap-3">
					<a
						class="inline-flex items-center gap-1.5 text-[#0058bd] hover:text-[#004190] transition-colors py-1 px-1.5 rounded hover:bg-blue-50/60 font-medium"
						href="https://drive.google.com"
						target="_blank"
						rel="noopener noreferrer"
					>
						<svg
							xmlns="http://www.w3.org/2000/svg"
							width="14"
							height="14"
							viewBox="0 0 24 24"
							fill="none"
							stroke="currentColor"
							stroke-width="2"
							stroke-linecap="round"
							stroke-linejoin="round"
							class="w-3.5 h-3.5 text-[#0058bd] shrink-0"
						>
							<path d="M12 5v16"></path>
							<path d="M20.001 19A2 2 0 0022 17V5a2 2 0 00-1.999-2L16 3.002A5 5 0 0012 5a5 5 0 00-4-2H4a2 2 0 00-2 2v12a2 2 0 001.999 2H8a5 5 0 014 2 5 5 0 014-2z"></path>
						</svg>
						<span>Drive da Nuvem</span>
					</a>
					<button
						type="button"
						onclick={() => (showSupportModal = true)}
						class="inline-flex items-center gap-1.5 text-secondary hover:text-[#8d0051] transition-colors py-1 px-1.5 rounded hover:bg-black/[0.03] font-medium cursor-pointer"
					>
						<span class="material-symbols-outlined text-[16px]">chat</span>
						<span>Contato de Suporte</span>
					</button>
				</div>
				<span class="text-[10px] sm:text-[11px] text-[#727784] font-normal leading-tight px-1.5 text-center sm:text-left lg:text-right">
					© 2026 Nuvem Júnior. Todos os direitos reservados.
				</span>
			</div>
		</div>
	</div>
</footer>
<!-- END: Footer -->

<!-- Support Hanging-Folder Dossier Modal -->
{#if showSupportModal}
	<!-- svelte-ignore a11y_click_events_have_key_events -->
	<!-- svelte-ignore a11y_no_static_element_interactions -->
	<div
		class="fixed inset-0 z-[100] flex items-center justify-center bg-[#181613]/60 backdrop-blur-[5px] p-2.5 sm:p-6 overflow-y-auto overscroll-contain animate-fadeIn"
		onclick={(e) => {
			if (e.target === e.currentTarget) closeSupportModal();
		}}
	>
		<div class="w-full max-w-md flex flex-col my-auto relative">
			<!-- Top Protruding Folder Tab Bar -->
			<div class="flex items-end justify-between px-2 sm:px-5 -mb-[1px] relative z-20">
				<div
					class="border-t-2 border-l-2 border-r-2 rounded-t-xl px-3 sm:px-5 py-2 flex items-center gap-2 shadow-[0_-3px_10px_rgba(0,0,0,0.05)] relative transition-colors duration-300"
					style="background-color: {supportTheme.folderBg}; border-color: {supportTheme.folderBorder};"
				>
					<div
						class="flex items-center gap-2 px-2.5 py-0.5 rounded-md bg-white/95 border shadow-[inset_0_1px_2px_rgba(0,0,0,0.05)]"
						style="border-color: color-mix(in srgb, {supportTheme.accent} 32%, transparent);"
					>
						<span class="w-2 h-2 rounded-full animate-pulse" style="background-color: {supportTheme.accent};"></span>
						<span class="font-mono text-[10px] uppercase font-bold tracking-wider" style="color: {supportTheme.accent};">
							SUPORTE &amp; GOVERNANÇA
						</span>
					</div>
					<div
						class="absolute -bottom-1 left-0 right-0 h-2 transition-colors duration-300"
						style="background-color: {supportTheme.folderBg};"
					></div>
				</div>

				<!-- Close Button -->
				<div class="flex items-center gap-2 pb-2">
					<button
						type="button"
						onclick={closeSupportModal}
						class="w-8 h-8 rounded-full bg-white/95 hover:bg-white text-on-surface-variant hover:text-on-surface border border-[#cfc5b4] flex items-center justify-center shadow-[0_2px_0_#d8d2c2] active:translate-y-0.5 transition-all cursor-pointer"
						title="Fechar (Esc)"
						aria-label="Fechar diálogo"
					>
						<span class="material-symbols-outlined text-[18px]">close</span>
					</button>
				</div>
			</div>

			<!-- Main Folder Body -->
			<div
				class="border-2 rounded-2xl hanging-folder-shadow relative z-10 overflow-hidden flex flex-col transition-colors duration-300"
				style="background-color: {supportTheme.folderBg}; border-color: {supportTheme.folderBorder};"
			>
				<!-- Top 1.5px Structural Reinforcement Bar -->
				<div
					class="w-full h-1.5"
					style="background: linear-gradient(to right, color-mix(in srgb, {supportTheme.accent} 25%, transparent), color-mix(in srgb, {supportTheme.accent} 45%, transparent), color-mix(in srgb, {supportTheme.accent} 20%, transparent));"
				></div>

				<!-- Body Content -->
				<div class="p-4 sm:p-6 space-y-4">
					<div
						class="rounded-xl p-4 border shadow-[0_2px_8px_rgba(29,27,23,0.04),inset_0_1px_0_#ffffff] space-y-3"
						style="background-color: {supportTheme.cardBg}; border-color: {supportTheme.cardBorder};"
					>
						<div class="flex items-center gap-3">
							<div
								class="w-10 h-10 rounded-xl flex items-center justify-center border shrink-0 shadow-2xs"
								style="background-color: {supportTheme.badgeBg}; border-color: {supportTheme.badgeBorder}; color: {supportTheme.accent};"
							>
								<span class="material-symbols-outlined text-[22px]">contact_support</span>
							</div>
							<div>
								<h3 class="text-base font-bold text-[#1E1D1A]">Suporte &amp; Governança</h3>
								<p class="text-[11px] font-mono text-[#63625D]">Nuvem Consultoria Jr.</p>
							</div>
						</div>

						<p class="text-xs text-[#524d45] leading-relaxed">
							Para dúvidas operacionais sobre metas, credenciais corporativas ou auditoria de OKRs, contate a Governança Executiva da Nuvem Jr. pelo e-mail institucional:
						</p>

						<div
							class="p-3 rounded-xl border flex items-center justify-between"
							style="background-color: {supportTheme.inputBg}; border-color: {supportTheme.inputBorder};"
						>
							<span class="font-mono text-xs font-bold text-[#1E1D1A] select-all truncate">
								presidencia@nuvemej.com.br
							</span>
							<span class="material-symbols-outlined text-[16px]" style="color: {supportTheme.accent};">verified_user</span>
						</div>
					</div>
				</div>

				<!-- Stitched Manila Footer -->
				<div
					class="px-4 sm:px-6 py-3.5 border-t flex flex-wrap items-center justify-end gap-2.5 relative transition-colors duration-300"
					style="background-color: {supportTheme.footerBg}; border-color: {supportTheme.folderBorder};"
				>
					<div
						class="absolute top-0.5 left-0 right-0 h-[1px] opacity-60"
						style="background-image: repeating-linear-gradient(to right, {supportTheme.stitchedColor} 0px, {supportTheme.stitchedColor} 6px, transparent 6px, transparent 11px);"
					></div>

					<button
						type="button"
						onclick={closeSupportModal}
						class="px-4 py-2 rounded-xl bg-white/85 hover:bg-white border border-[#cfc5b4] font-mono text-xs font-bold text-[#1d1b17] shadow-[0_2px_0_#d8d2c2] active:translate-y-0.5 transition-all cursor-pointer"
					>
						Fechar
					</button>
					<a
						href="mailto:presidencia@nuvemej.com.br?subject=Suporte%20Horizonte%20OKRs"
						class="flex-1 sm:flex-initial px-4 py-2 rounded-xl text-white font-mono text-xs font-bold tracking-wide transition-all active:translate-y-0.5 flex items-center justify-center gap-1.5"
						style="background-color: {supportTheme.accent}; box-shadow: 0 2.5px 0 {supportTheme.accentShadow};"
					>
						<span class="material-symbols-outlined text-[16px]">mail</span>
						Enviar E-mail
					</a>
				</div>
			</div>
		</div>
	</div>
{/if}

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
