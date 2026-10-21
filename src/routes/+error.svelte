<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { base } from '$app/paths';

	let searchQuery = $state('');
	let searchInputRef = $state<HTMLInputElement | null>(null);

	const is404 = $derived($page.status === 404);
	const errorCodeText = $derived(
		is404
			? 'ERRO 404: ELEMENTO NÃO ENCONTRADO'
			: `ERRO ${$page.status}: ${$page.error?.message || 'OCORREU UM PROBLEMA'}`
	);
	const badgeTitle = $derived(
		is404
			? 'ERRO 404// DESALINHAMENTO DE ROTA (HTTP 404)'
			: `ERRO ${$page.status}// EXCEÇÃO DE EXECUÇÃO (HTTP ${$page.status})`
	);

	function handleKeydown(e: KeyboardEvent) {
		if ((e.ctrlKey || e.metaKey) && (e.key === 'k' || e.key === 'K')) {
			e.preventDefault();
			searchInputRef?.focus();
			searchInputRef?.select();
		}
	}

	function handleSearch(e: SubmitEvent | KeyboardEvent) {
		if ('key' in e && e.key !== 'Enter') return;
		e.preventDefault();
		const trimmed = searchQuery.trim();
		if (trimmed) {
			goto(`${base}/strategy?q=${encodeURIComponent(trimmed)}`);
		} else {
			goto(`${base}/strategy`);
		}
	}

	function handleGoBack() {
		if (typeof window !== 'undefined' && window.history.length > 1) {
			window.history.back();
		} else {
			goto(`${base}/strategy`);
		}
	}
</script>

<svelte:window onkeydown={handleKeydown} />

<svelte:head>
	<title>404 - Página Não Encontrada | Horizonte OKRs</title>
</svelte:head>

<!-- Ambient Cutting Mat Grid Overlay -->
<div class="fixed inset-0 pointer-events-none z-0 mat-grid-pattern opacity-40"></div>

<!-- Top Navigation Bar -->
<header
	class="w-full bg-surface/85 backdrop-blur-xl shadow-[0_1px_8px_rgba(36,34,30,0.04)] fixed top-0 left-0 right-0 z-50 border-b border-surface-variant/40"
>
	<div class="h-16 max-w-7xl mx-auto px-6 lg:px-12 flex items-center justify-between">
		<a href="{base}/strategy" class="flex items-center gap-space-sm group">
			<img
				src="{base}/favicon.png"
				alt="Horizonte OKRs"
				class="w-8 h-8 object-contain shrink-0 group-hover:scale-105 transition-transform"
			/>
			<div class="flex flex-col text-left leading-tight">
				<span class="font-headline-sm text-[16px] font-bold text-on-surface tracking-tight">
					Horizonte OKRs
				</span>
				<span class="font-headline-sm text-[11px] font-semibold text-on-surface-variant tracking-normal">
					Planejamento Estratégico
				</span>
			</div>
		</a>

		<div class="flex items-center gap-space-md">
			<div
				class="flex items-center gap-space-xs px-space-sm py-1 rounded-full bg-surface-container-high shadow-[inset_0_1px_2px_rgba(36,34,30,0.05)]"
			>
				<span class="w-2 h-2 rounded-full bg-error animate-pulse"></span>
				<span
					class="font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wider font-semibold"
				>
					{errorCodeText}
				</span>
			</div>

			<button
				type="button"
				onclick={handleGoBack}
				class="hidden sm:inline-flex items-center gap-space-xs font-label-md text-label-md text-on-surface-variant hover:text-on-surface transition-colors cursor-pointer"
			>
				<span class="material-symbols-outlined text-[16px]">west</span>
				Voltar
			</button>
		</div>
	</div>
</header>

<!-- Main Error Layout -->
<main
	class="w-full min-h-screen flex-1 flex flex-col items-center justify-between pt-24 pb-8 px-6 lg:px-12 relative z-10"
>
	<div class="w-full max-w-3xl mx-auto my-auto py-space-lg flex flex-col items-center">
		<div class="w-full flex flex-col items-center text-center space-y-space-xl">
			<!-- Optical Lens & Misaligned Plates Composition -->
			<div
				class="relative w-full max-w-lg h-64 sm:h-72 flex items-center justify-center select-none"
			>
				<!-- Ambient Glow Spot -->
				<div
					class="absolute w-72 h-72 rounded-full bg-gradient-to-tr from-primary/10 via-secondary/10 to-tertiary/10 blur-3xl pointer-events-none -z-10"
				></div>

				<!-- Cyan/Cobalt Optical Slide (Shifted Left & Tilted) -->
				<div
					class="absolute w-44 h-44 sm:w-52 sm:h-52 bg-primary/80 rounded-2xl mix-blend-multiply filter blur-[0.5px] transform -translate-x-12 -translate-y-4 -rotate-6 transition-all duration-700 ease-out hover:-translate-x-14 hover:-rotate-12 shadow-[0_8px_20px_rgba(37,99,235,0.18)]"
				>
					<div class="absolute inset-0 border-t border-l border-white/40 rounded-2xl"></div>
					<div class="absolute bottom-3 left-3 text-white/50 font-label-sm text-label-sm tracking-widest font-mono">
						LYR_01 // COBALT
					</div>
				</div>

				<!-- Magenta/Crimson Optical Slide (Shifted Right & Counter-Tilted) -->
				<div
					class="absolute w-44 h-44 sm:w-52 sm:h-52 bg-secondary/75 rounded-2xl mix-blend-multiply filter blur-[0.5px] transform translate-x-10 translate-y-3 rotate-6 transition-all duration-700 ease-out hover:translate-x-12 hover:rotate-12 shadow-[0_8px_20px_rgba(236,72,153,0.18)]"
				>
					<div class="absolute inset-0 border-t border-r border-white/40 rounded-2xl"></div>
					<div class="absolute top-3 right-3 text-white/50 font-label-sm text-label-sm tracking-widest font-mono">
						LYR_02 // MAGENTA
					</div>
				</div>

				<!-- Yellow Amber Solar Slide (Centered Shifted Up) -->
				<div
					class="absolute w-40 h-40 sm:w-48 sm:h-48 bg-tertiary-container/85 rounded-2xl mix-blend-multiply filter blur-[0.5px] transform translate-y-8 -translate-x-2 rotate-2 transition-all duration-700 ease-out hover:translate-y-10 hover:rotate-4 shadow-[0_8px_20px_rgba(250,204,21,0.2)]"
				>
					<div class="absolute inset-0 border-b border-white/60 rounded-2xl"></div>
					<div
						class="absolute bottom-3 right-3 text-on-tertiary-container/60 font-label-sm text-label-sm tracking-widest font-mono"
					>
						LYR_03 // AMBER
					</div>
				</div>

				<!-- Precision Tick Marks & Calibration Marks -->
				<div
					class="absolute -top-2 left-6 hidden sm:flex items-center gap-1.5 text-on-surface-variant/50 font-label-sm text-label-sm"
				>
					<span class="w-1.5 h-1.5 rounded-full bg-error"></span>
					<span>OFFSET X: +24.8mm</span>
				</div>
				<div
					class="absolute -bottom-2 right-6 hidden sm:flex items-center gap-1.5 text-on-surface-variant/50 font-label-sm text-label-sm"
				>
					<span>DEV Y: -12.4mm</span>
					<span class="w-1.5 h-1.5 rounded-full bg-tertiary"></span>
				</div>
			</div>

			<!-- Editorial Status Heading Block -->
			<div class="flex flex-col items-center max-w-xl mx-auto space-y-space-sm px-2">
				<!-- Chromatic Ribbon Badge -->
				<div
					class="inline-flex items-center gap-2 px-space-sm py-1 rounded-full bg-surface-container-high shadow-[inset_0_1px_2px_rgba(36,34,30,0.05)]"
				>
					<div class="flex -space-x-1 items-center">
						<span class="w-2 h-2 rounded-full bg-primary ring-2 ring-surface-container-high"></span>
						<span class="w-2 h-2 rounded-full bg-secondary ring-2 ring-surface-container-high"></span>
						<span class="w-2 h-2 rounded-full bg-tertiary-container ring-2 ring-surface-container-high"></span>
					</div>
					<span
						class="font-label-sm text-label-sm font-semibold tracking-wider text-on-surface-variant uppercase"
					>
						{badgeTitle}
					</span>
				</div>

				<h1
					class="font-headline-lg sm:font-headline-xl text-headline-lg sm:text-headline-xl font-bold text-on-surface tracking-tight"
				>
					Esta rota saiu do nosso escopo
				</h1>

				<p class="font-body-md text-body-md text-on-surface-variant max-w-lg leading-relaxed">
					O elo que você buscou não possui conexão com algum elemento dos Planejamentos Estratégicos.
					Pode ter sido arquivado, renomeado ou removido na virada de gestão ou digitado com divergência.
				</p>
			</div>

			<!-- Interactive Search / Navigation Bar -->
			<div class="w-full max-w-md mx-auto">
				<form
					onsubmit={handleSearch}
					class="relative flex items-center bg-surface-container-lowest rounded-xl shadow-[inset_0_2px_4px_rgba(36,34,30,0.06),0_1px_0_#ffffff] p-1.5 transition-all focus-within:shadow-[0_0_0_2px_#0058bd,inset_0_1px_2px_rgba(36,34,30,0.04)]"
				>
					<span class="material-symbols-outlined text-on-surface-variant/70 ml-2.5 text-[20px]">
						search
					</span>
					<input
						bind:this={searchInputRef}
						bind:value={searchQuery}
						class="w-full bg-transparent px-space-sm py-1.5 font-body-md text-body-md text-on-surface placeholder:text-on-surface-variant/50 focus:outline-none"
						id="global-command-search"
						placeholder="Buscar objetivos, times ou métricas..."
						type="text"
					/>
					<div
						class="hidden sm:inline-flex items-center gap-1 px-2 py-1 rounded bg-surface-container text-on-surface-variant font-label-sm text-[11px] shadow-[0_1px_1px_rgba(36,34,30,0.06)] shrink-0 font-semibold select-none"
					>
						<span>Ctrl</span>
						<span>K</span>
					</div>
				</form>
				<p class="font-label-sm text-label-sm text-on-surface-variant/70 mt-2 text-center">
					Pressione <kbd
						class="px-1.5 py-0.5 rounded bg-surface-container-high text-on-surface font-semibold text-[10px] shadow-[0_1px_1px_rgba(36,34,30,0.08)]"
						>Ctrl + K</kbd
					> para buscar em toda a organização
				</p>
			</div>

			<!-- Tactile Recovery Wayfinding Bento Grid -->
			<div class="w-full grid grid-cols-1 md:grid-cols-3 gap-space-md pt-space-xs text-left">
				<!-- Card 1: Árvore de OKRs -->
				<a
					class="group flex flex-col justify-between p-space-lg bg-surface-container-lowest rounded-xl shadow-[0_1px_1px_rgba(36,34,30,0.05),0_3px_6px_-1px_rgba(36,34,30,0.04),inset_0_-1px_0_rgba(255,255,255,0.8)] hover:shadow-[0_8px_16px_-2px_rgba(36,34,30,0.08),0_2px_4px_rgba(36,34,30,0.04)] hover:-translate-y-0.5 transition-all duration-200 relative overflow-hidden"
					href="{base}/strategy"
				>
					<div class="absolute top-0 left-0 w-1 h-full bg-primary rounded-l-xl"></div>
					<div class="space-y-space-sm">
						<div
							class="w-10 h-10 rounded-lg bg-primary-fixed flex items-center justify-center text-primary transition-transform group-hover:scale-105"
						>
							<span class="material-symbols-outlined text-[22px]">account_tree</span>
						</div>
						<div class="space-y-1">
							<div class="flex items-center justify-between">
								<h2 class="font-title-md text-title-md text-on-surface">Árvore de OKRs</h2>
								<span
									class="material-symbols-outlined text-on-surface-variant text-[18px] opacity-0 group-hover:opacity-100 transition-opacity transform group-hover:translate-x-0.5"
								>
									arrow_forward
								</span>
							</div>
							<p class="font-body-sm text-body-sm text-on-surface-variant leading-relaxed">
								Acesso ao painel principal de objetivos corporativos desdobrados.
							</p>
						</div>
					</div>
					<div
						class="pt-space-md flex items-center gap-1.5 font-label-sm text-label-sm text-primary uppercase font-semibold"
					>
						<span>Explorar Árvore</span>
						<span class="material-symbols-outlined text-[14px]">north_east</span>
					</div>
				</a>

				<!-- Card 2: Metas e KPIs -->
				<a
					class="group flex flex-col justify-between p-space-lg bg-surface-container-lowest rounded-xl shadow-[0_1px_1px_rgba(36,34,30,0.05),0_3px_6px_-1px_rgba(36,34,30,0.04),inset_0_-1px_0_rgba(255,255,255,0.8)] hover:shadow-[0_8px_16px_-2px_rgba(36,34,30,0.08),0_2px_4px_rgba(36,34,30,0.04)] hover:-translate-y-0.5 transition-all duration-200 relative overflow-hidden"
					href="{base}/dashboard"
				>
					<div class="absolute top-0 left-0 w-1 h-full bg-secondary rounded-l-xl"></div>
					<div class="space-y-space-sm">
						<div
							class="w-10 h-10 rounded-lg bg-secondary-fixed flex items-center justify-center text-secondary transition-transform group-hover:scale-105"
						>
							<span class="material-symbols-outlined text-[22px]">fact_check</span>
						</div>
						<div class="space-y-1">
							<div class="flex items-center justify-between">
								<h2 class="font-title-md text-title-md text-on-surface">Metas e KPIs</h2>
								<span
									class="material-symbols-outlined text-on-surface-variant text-[18px] opacity-0 group-hover:opacity-100 transition-opacity transform group-hover:translate-x-0.5"
								>
									arrow_forward
								</span>
							</div>
							<p class="font-body-sm text-body-sm text-on-surface-variant leading-relaxed">
								Métricas quinzenais, desvios e calibragens ativas da rodada.
							</p>
						</div>
					</div>
					<div
						class="pt-space-md flex items-center gap-1.5 font-label-sm text-label-sm text-secondary uppercase font-semibold"
					>
						<span>Abrir Página</span>
						<span class="material-symbols-outlined text-[14px]">north_east</span>
					</div>
				</a>

				<!-- Card 3: Diretório de Equipes -->
				<a
					class="group flex flex-col justify-between p-space-lg bg-surface-container-lowest rounded-xl shadow-[0_1px_1px_rgba(36,34,30,0.05),0_3px_6px_-1px_rgba(36,34,30,0.04),inset_0_-1px_0_rgba(255,255,255,0.8)] hover:shadow-[0_8px_16px_-2px_rgba(36,34,30,0.08),0_2px_4px_rgba(36,34,30,0.04)] hover:-translate-y-0.5 transition-all duration-200 relative overflow-hidden"
					href="{base}/admin#equipes"
				>
					<div class="absolute top-0 left-0 w-1 h-full bg-tertiary-container rounded-l-xl"></div>
					<div class="space-y-space-sm">
						<div
							class="w-10 h-10 rounded-lg bg-surface-container-high flex items-center justify-center text-on-tertiary-container transition-transform group-hover:scale-105"
						>
							<span class="material-symbols-outlined text-[22px]">diversity_3</span>
						</div>
						<div class="space-y-1">
							<div class="flex items-center justify-between">
								<h2 class="font-title-md text-title-md text-on-surface">Equipes</h2>
								<span
									class="material-symbols-outlined text-on-surface-variant text-[18px] opacity-0 group-hover:opacity-100 transition-opacity transform group-hover:translate-x-0.5"
								>
									arrow_forward
								</span>
							</div>
							<p class="font-body-sm text-body-sm text-on-surface-variant leading-relaxed">
								Estrutura hierárquica das 7 diretorias executivas da Nuvem Jr.
							</p>
						</div>
					</div>
					<div
						class="pt-space-md flex items-center gap-1.5 font-label-sm text-label-sm text-tertiary uppercase font-semibold"
					>
						<span>Ver Diretório</span>
						<span class="material-symbols-outlined text-[14px]">north_east</span>
					</div>
				</a>
			</div>

			<!-- Executive Primary CTA Action -->
			<div class="pt-space-sm flex flex-col sm:flex-row items-center gap-space-md">
				<a
					class="inline-flex items-center gap-space-sm px-space-xl py-3 rounded-lg bg-primary text-on-primary font-label-md text-label-md shadow-[0_2px_0_#004494,0_4px_8px_rgba(0,88,189,0.25)] hover:bg-primary-container active:translate-y-0.5 active:shadow-[0_0_0_#004494] transition-all duration-150 group"
					href="{base}/strategy"
				>
					<span
						class="material-symbols-outlined text-[18px] transition-transform group-hover:-translate-x-1"
					>
						home
					</span>
					<span class="tracking-wider uppercase font-semibold">Voltar ao Ponto de Partida</span>
				</a>

				<button
					class="inline-flex items-center gap-space-xs px-space-md py-3 rounded-lg bg-surface-container-lowest text-on-surface font-label-md text-label-md shadow-[0_1px_1px_rgba(36,34,30,0.05),0_2px_4px_rgba(36,34,30,0.04)] hover:bg-surface-container transition-colors tracking-wider uppercase font-semibold cursor-pointer"
					onclick={handleGoBack}
					type="button"
				>
					<span class="material-symbols-outlined text-[16px]">undo</span>
					<span>Retornar Página Anterior</span>
				</button>
			</div>
		</div>
	</div>

	<!-- Tactile Archival Footer -->
	<footer class="w-full max-w-7xl mx-auto px-6 lg:px-12 py-space-md bg-transparent">
		<div
			class="flex flex-col sm:flex-row items-center justify-between gap-space-sm text-center sm:text-left py-2 font-headline-sm text-body-sm"
		>
			<div class="flex items-center gap-2 text-on-surface">
				<span class="font-bold tracking-tight">NUVEM HORIZONTE OKRs</span>
				<span class="text-on-surface-variant">•</span>
				<span class="font-normal text-on-surface-variant">Arquitetura de Gestão Estratégica</span>
			</div>
			<div class="text-on-surface-variant font-normal">
				© 2026 Nuvem Júnior. Todos os direitos reservados.
			</div>
		</div>
	</footer>
</main>
