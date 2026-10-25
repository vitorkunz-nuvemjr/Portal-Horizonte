<script lang="ts">
	import { enhance } from '$app/forms';
	import { enhanceFormValidation } from '$lib/utils';
	import { downloadSnapshot } from './admin-utils';

	interface Props {
		data: any;
		isAdmin: boolean;
		showResetModal: boolean;
	}

	let {
		data,
		isAdmin,
		showResetModal = $bindable()
	}: Props = $props();

	function handleDownload() {
		downloadSnapshot(data);
	}
</script>

<!-- Folder Subheader -->
<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-5 border-b border-[#f3ede6]">
	<div class="flex items-center gap-3">
		<div class="w-10 h-10 rounded-xl bg-[#ffd9e4]/60 text-[#b7076c] flex items-center justify-center shrink-0">
			<span class="material-symbols-outlined text-[22px]">folder_zip</span>
		</div>
		<div>
			<h2 class="text-lg font-bold text-[#1d1b17] font-display tracking-tight">Gestão de Snapshot &amp; Backup EJ</h2>
			<p class="text-[12.5px] text-[#727784] font-sans mt-0.5">
				Exportação completa em formato JSON, restauração para o modelo canônico de EJ e importação para passagem de gestão semestral.
			</p>
		</div>
	</div>
</div>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
	<!-- Card 1: Export -->
	<div class="p-5 rounded-xl border border-[#e8e2d8] bg-[#f9f3ec]/60 flex flex-col justify-between shadow-sm">
		<div>
			<div class="flex items-center gap-2 mb-2">
				<span class="material-symbols-outlined text-[22px] text-[#004190]">cloud_download</span>
				<h3 class="font-bold text-[15px] text-[#1d1b17]">Exportar Backup Portátil JSON</h3>
			</div>
			<p class="text-[12.5px] text-[#727784] leading-relaxed">
				Gere um arquivo JSON contendo todos os nós estratégicos, metas, métricas, equipes e membros para custódia segura ou auditoria semestral.
			</p>
		</div>
		<div class="pt-4 mt-4 border-t border-[#e8e2db]/70">
			<button
				type="button"
				onclick={handleDownload}
				class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#004190] hover:bg-[#003375] text-white font-bold text-[13px] shadow-[0_2px_4px_rgba(0,65,144,0.2)] active:translate-y-0.5 transition-all cursor-pointer"
			>
				<span class="material-symbols-outlined text-[18px]">download</span>
				<span>Baixar Arquivo JSON</span>
			</button>
		</div>
	</div>

	<!-- Card 2: Reset Template -->
	<div class="p-5 rounded-xl border border-[#e8e2d8] bg-[#f9f3ec]/60 flex flex-col justify-between shadow-sm">
		<div>
			<div class="flex items-center gap-2 mb-2">
				<span class="material-symbols-outlined text-[22px] text-[#b7076c]">restart_alt</span>
				<h3 class="font-bold text-[15px] text-[#1d1b17]">Restaurar Modelo Canônico de EJ</h3>
			</div>
			<p class="text-[12.5px] text-[#727784] leading-relaxed">
				Recarregue o padrão oficial do JE Strategy OS com as 6 diretorias estruturadas, objetivos estratégicos recomendados e indicadores essenciais.
			</p>
		</div>
		<div class="pt-4 mt-4 border-t border-[#e8e2db]/70">
			<button
				type="button"
				disabled={!isAdmin}
				onclick={() => (showResetModal = true)}
				class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#ffd9e4] hover:bg-[#fcc8d7] text-[#8d0051] font-bold text-[13px] border border-[#f472b6]/40 shadow-sm active:translate-y-0.5 transition-all disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
			>
				<span class="material-symbols-outlined text-[18px]">restore</span>
				<span>Restaurar Modelo Padrão</span>
			</button>
		</div>
	</div>
</div>

<!-- Card 3: Import JSON -->
{#if isAdmin}
	<div class="p-5 rounded-2xl bg-[#fcfaf7] border border-[#e8e2d8] shadow-[inset_0_1px_3px_rgba(0,0,0,0.02)]">
		<div class="flex items-center gap-2 mb-2">
			<span class="material-symbols-outlined text-[#004190] text-[20px]">upload_file</span>
			<span class="font-extrabold text-[12px] tracking-wider text-[#1d1b17] uppercase font-mono">IMPORTAR SNAPSHOT JSON</span>
		</div>
		<p class="text-[12.5px] text-[#727784] mb-3">
			Cole o conteúdo do backup exportado para restaurar ou transferir a base do planejamento estratégico.
		</p>
		<form
			action="?/importJson"
			method="POST"
			use:enhance={() => {
				return async ({ update }) => {
					await update({ reset: false });
				};
			}}
			use:enhanceFormValidation
			class="space-y-3"
		>
			<textarea
				name="jsonText"
				rows="5"
				required
				placeholder="Cole aqui o JSON exportado (contendo nodes, cycles, teams, etc.)..."
				class="w-full p-3.5 rounded-xl bg-white border border-[#d5cebe] text-[12px] font-mono text-[#1d1b17] placeholder-[#a09b92] focus:outline-none focus:ring-2 focus:ring-[#004190]/20 focus:border-[#004190] transition-all"
			></textarea>
			<div class="flex justify-end">
				<button
					type="submit"
					class="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#004190] hover:bg-[#003375] text-white font-bold text-[13px] shadow-[0_2px_6px_rgba(0,65,144,0.25)] active:translate-y-0.5 transition-all cursor-pointer"
				>
					<span class="material-symbols-outlined text-[18px]">upload</span>
					<span>Importar Snapshot</span>
				</button>
			</div>
		</form>
	</div>
{/if}
