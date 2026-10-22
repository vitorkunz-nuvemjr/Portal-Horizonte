<script lang="ts">
	import { base } from '$app/paths';
	import { X } from 'lucide-svelte';

	let showSupportModal = $state(false);

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
	<div class="max-w-7xl mx-auto px-6 py-6">
		<div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-center">
			<!-- 1. Lado esquerdo: Horizonte OKRs Brand, Subtítulo & Badge -->
			<div class="lg:col-span-4 flex items-center gap-3">
				<img
					alt="Logotipo Horizonte OKRs"
					class="h-10 w-auto object-contain shrink-0"
					src="{base}/footer-horizonte-logo.png"
					onerror={(e) => {
						const img = e.currentTarget as HTMLImageElement;
						img.src = 'https://lh3.googleusercontent.com/aida-public/AB6AXuC5Qqj47nomhU0_0484DHCQXJIiS6v5OG2B7OgsQf3B_J8Obx-tRRSkGX-bb4G5I17H7THd_tX-tkqVTFGmwWxUQBC53-Nscq1Uj1qN6RqKpxtZTLfSMXw12H5MIORawV7hqbJ6pm6fGgPfiU7CLASDpvl8D1kTyeSEc14ALklxf4TE9LwQPF6QNjAZO27SBe7yE7-r4ewB8Xds3WjeE0Eup6UXogMxkwL5-J7xIp0d_Z5tfsWVHZOPTVHYdGYpu63rSb4';
					}}
				/>
				<div class="flex flex-col">
					<div class="flex items-center gap-2">
						<span class="font-display font-bold text-sm tracking-tight text-[#1d1b17]">
							Horizonte OKRs
						</span>
					</div>
					<span class="text-[11px] font-medium text-slate-500 tracking-wider">
						Planejamento estratégico
					</span>
				</div>
			</div>

			<!-- 2. Centro absoluto: Nuvem Consultoria Jr. + Assinatura -->
			<div class="lg:col-span-4 flex flex-col items-center justify-center text-center py-2 lg:py-0 border-y lg:border-y-0 border-amber-900/10 lg:border-x lg:px-4">
				<div class="flex items-center gap-2.5 mb-1">
					<img
						alt="Logotipo Nuvem Consultoria Jr."
						class="h-[34px] w-auto object-contain shrink-0"
						src="{base}/footer-nuvem-cloud.png"
						onerror={(e) => {
							const img = e.currentTarget as HTMLImageElement;
							img.src = 'https://lh3.googleusercontent.com/aida-public/AB6AXuBOF6-LATC3s4WLDhRY4TpE9-tPjF77n3RtkXloohy55ih-GL4s1kwGGzX83uPj6-a7gipSg0zZxbhjX-h3tApv7wds74oSq_r92XXVh0LZgFTFa1JE3icidtFOUHR-bl4leZmKAcUtkWJ1aGOBtOkOQUX27zaJGwuKz8x_g_RzzyMyyD8evDx9ZsNJuh0VuXbATaXKBc_0-VnwwL5v0HJywzkbjMZxassF3Pe7vz3IX8VADrS8ShLhfyO2J5NxqSkPnHw';
						}}
					/>
					<img
						alt="Nuvem Jr."
						class="h-5 sm:h-6 w-auto object-contain inline-block"
						src="{base}/footer-nuvem-text.png"
						onerror={(e) => {
							const img = e.currentTarget as HTMLImageElement;
							img.src = 'https://lh3.googleusercontent.com/aida-public/AB6AXuBf57U3gHNoUNMaF34LPEERj5PaHZOACH85VFsYQx3WAS2IyuOWuF-mPk3DhlwfQekqzTGtaF1GaQzHf62N1eRkSHJXvsig_1ostXm46pxxNVEb_1iuJEzWCd7FzDcgf0qLifFrH-nQxGuoaTH6hfzzDtJ1wa6BKT8bTOo0CL5gSHte9E4beFnzkohJuSY5JrRFnOVkPbka0kvlBqKf-D2rscHs2mfzTzwMtr3Tc-NCCfm8LUG6_9wLBk6EGf3kFCzRehw';
						}}
					/>
				</div>
				<p class="text-[11px] text-[#727784] font-normal leading-tight max-w-xs">
					Viva o novo. Experimente o inusitado!
				</p>
			</div>

			<!-- 3. Lado direito: Governança, Suporte GP & Direitos Reservados -->
			<div class="lg:col-span-4 flex flex-col items-start lg:items-end justify-center gap-1.5 text-xs">
				<div class="flex flex-wrap items-center gap-3">
					<a
						class="inline-flex items-center gap-1.5 text-[#727784] hover:text-[#0058bd] transition-colors py-1 px-1.5 rounded hover:bg-black/[0.03] font-medium"
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
							class="w-3.5 h-3.5 text-[#727784] shrink-0"
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
				<span class="text-[11px] text-[#727784] font-normal leading-tight px-1.5">
					© 2026 Nuvem Júnior. Todos os direitos reservados.
				</span>
			</div>
		</div>
	</div>
</footer>
<!-- END: Footer -->

<!-- Support Modal / Dialog -->
{#if showSupportModal}
	<!-- svelte-ignore a11y_click_events_have_key_events -->
	<!-- svelte-ignore a11y_no_static_element_interactions -->
	<div
		class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-xs p-4 animate-fadeIn"
		onclick={(e) => {
			if (e.target === e.currentTarget) closeSupportModal();
		}}
	>
		<div class="w-full max-w-md bg-white rounded-2xl border border-[#E8E2D8] shadow-2xl p-6 relative">
			<button
				type="button"
				onclick={closeSupportModal}
				class="absolute top-4 right-4 text-[#8C8A83] hover:text-[#1E1D1A] p-1 rounded-lg hover:bg-black/5 transition cursor-pointer"
				aria-label="Fechar diálogo"
			>
				<X class="w-5 h-5" />
			</button>
			<div class="flex items-center gap-3 mb-3">
				<div class="w-10 h-10 rounded-xl bg-pink-50 text-secondary flex items-center justify-center">
					<span class="material-symbols-outlined text-[22px]">contact_support</span>
				</div>
				<div>
					<h3 class="text-base font-bold text-[#1E1D1A]">Suporte & Governança</h3>
					<p class="text-[11px] text-[#63625D]">Nuvem Consultoria Jr.</p>
				</div>
			</div>
			<p class="text-xs text-[#63625D] leading-relaxed mb-4">
				Para dúvidas operacionais sobre metas, credenciais corporativas ou auditoria de OKRs, contate a Governança Executiva da Nuvem Jr. pelo e-mail institucional:
			</p>
			<div class="p-3 bg-[#FDFBF7] border border-[#E8E2D8] rounded-xl flex items-center justify-between mb-6">
				<span class="font-mono text-xs font-semibold text-[#1E1D1A] select-all">
					presidencia@nuvemej.com.br
				</span>
			</div>
			<div class="flex gap-2">
				<a
					href="mailto:presidencia@nuvemej.com.br?subject=Suporte%20Horizonte%20OKRs"
					class="flex-1 h-10 rounded-xl bg-primary hover:bg-[#00479b] text-white text-xs font-semibold tracking-wide transition shadow-sm flex items-center justify-center gap-1.5"
				>
					<span class="material-symbols-outlined text-[16px]">mail</span>
					Enviar E-mail
				</a>
				<button
					type="button"
					onclick={closeSupportModal}
					class="px-4 h-10 rounded-xl bg-surface-container hover:bg-surface-container-high text-on-surface text-xs font-semibold tracking-wide transition cursor-pointer"
				>
					Fechar
				</button>
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
