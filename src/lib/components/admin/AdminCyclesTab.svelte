<script lang="ts">
	import type { Cycle } from '$lib/types';
	import { enhanceFormValidation } from '$lib/utils';
	import { formatDate } from './admin-utils';

	interface Props {
		data: any;
		isAdmin: boolean;
		cycleToDelete: Cycle | null;
	}

	let {
		data,
		isAdmin,
		cycleToDelete = $bindable()
	}: Props = $props();

	// Active cycle calculation
	const activeCycle = $derived.by(() => {
		if (!data.cycles || data.cycles.length === 0) return null;
		const now = new Date().toISOString().slice(0, 10);
		const current = data.cycles.find((c: Cycle) => c.start_date <= now && c.end_date >= now);
		return current || data.cycles.find((c: Cycle) => c.code.includes('2026')) || data.cycles[data.cycles.length - 1];
	});
</script>

<!-- Folder Subheader -->
<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-5 border-b border-[#f3ede6]">
	<div class="flex items-center gap-3">
		<div class="w-10 h-10 rounded-xl bg-[#ffe327]/30 text-[#78350f] flex items-center justify-center shrink-0">
			<span class="material-symbols-outlined text-[22px]">calendar_month</span>
		</div>
		<div>
			<div class="flex items-center gap-2.5">
				<h2 class="text-lg font-bold text-[#1d1b17] font-display tracking-tight">Ciclos Semestrais &amp; Vigência</h2>
				<span class="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-[#78350f] text-white font-mono">
					{data.cycles.length} cadastrados
				</span>
			</div>
			<p class="text-[12.5px] text-[#727784] font-sans mt-0.5">
				Planejamento temporal das OKRs da Nuvem Jr., períodos de início/término e ciclo ativo.
			</p>
		</div>
	</div>
</div>

<!-- Grid of Semester Cycles -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
	{#each data.cycles as cyc (cyc.id)}
		{@const isActive = activeCycle?.id === cyc.id}
		<div class="p-4 rounded-xl border border-[#e8e2d8] bg-[#f9f3ec]/60 hover:bg-[#f9f3ec] transition-all flex flex-col justify-between shadow-sm">
			<div>
				<div class="flex items-center justify-between mb-2">
					<div class="flex items-center gap-2">
						<span class="material-symbols-outlined text-[20px] text-amber-600">calendar_month</span>
						<span class="font-bold text-[16px] text-[#1d1b17] font-display">{cyc.code}</span>
					</div>
					{#if isActive}
						<span class="text-[9px] font-bold uppercase px-2 py-0.5 rounded bg-[#fef9c3] text-[#78350f] border border-[#fef08a] font-mono">
							ATIVO
						</span>
					{/if}
				</div>
				<div class="text-[12px] font-mono text-[#727784] mt-1">
					{formatDate(cyc.start_date)} → {formatDate(cyc.end_date)}
				</div>
				<span class="inline-block mt-2 text-[11px] font-medium px-2 py-0.5 rounded bg-[#ede7e1] text-[#424753]">
					Ano {cyc.year} • {cyc.semester}º Semestre
				</span>
			</div>
			{#if isAdmin}
				<div class="flex justify-end pt-3 mt-3 border-t border-[#e8e2db]/70">
					<button
						type="button"
						onclick={() => (cycleToDelete = cyc)}
						class="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-red-50 text-[#727784] hover:text-red-600 transition-colors cursor-pointer"
						title="Excluir Ciclo"
					>
						<span class="material-symbols-outlined text-[16px]">delete</span>
					</button>
				</div>
			{/if}
		</div>
	{/each}
</div>

<!-- Bottom Form: + ADICIONAR NOVO CICLO SEMESTRAL -->
{#if isAdmin}
	<div class="p-5 rounded-2xl bg-[#fcfaf7] border border-[#e8e2d8] shadow-[inset_0_1px_3px_rgba(0,0,0,0.02)]">
		<div class="flex items-center gap-2 mb-4">
			<span class="material-symbols-outlined text-[#78350f] text-[20px]">calendar_add_on</span>
			<span class="font-extrabold text-[12px] tracking-wider text-[#1d1b17] uppercase font-mono">+ ADICIONAR NOVO CICLO SEMESTRAL</span>
		</div>
		<form action="?/createCycle" method="POST" use:enhanceFormValidation class="grid grid-cols-1 md:grid-cols-12 gap-3 items-end">
			<div class="md:col-span-2">
				<label for="cyc-year" class="block text-[10px] font-bold uppercase tracking-wider text-[#727784] mb-1 font-mono">ANO *</label>
				<input
					id="cyc-year"
					name="year"
					type="number"
					required
					value={new Date().getFullYear() + 1}
					class="w-full px-3 py-2 rounded-xl bg-white border border-[#d5cebe] text-[13px] text-[#1d1b17] focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-600 transition-all font-mono"
				/>
			</div>
			<div class="md:col-span-2">
				<label for="cyc-sem" class="block text-[10px] font-bold uppercase tracking-wider text-[#727784] mb-1 font-mono">SEMESTRE</label>
				<select
					id="cyc-sem"
					name="semester"
					class="w-full px-3 py-2 rounded-xl bg-white border border-[#d5cebe] text-[13px] text-[#1d1b17] focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-600 cursor-pointer font-mono"
				>
					<option value="1">1º Semestre (S1)</option>
					<option value="2">2º Semestre (S2)</option>
				</select>
			</div>
			<div class="md:col-span-3">
				<label for="cyc-start" class="block text-[10px] font-bold uppercase tracking-wider text-[#727784] mb-1 font-mono">DATA DE INÍCIO *</label>
				<input
					id="cyc-start"
					name="start_date"
					type="date"
					required
					value={`${new Date().getFullYear() + 1}-01-01`}
					class="w-full px-3 py-2 rounded-xl bg-white border border-[#d5cebe] text-[13px] text-[#1d1b17] focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-600 transition-all font-mono"
				/>
			</div>
			<div class="md:col-span-3">
				<label for="cyc-end" class="block text-[10px] font-bold uppercase tracking-wider text-[#727784] mb-1 font-mono">DATA DE TÉRMINO *</label>
				<input
					id="cyc-end"
					name="end_date"
					type="date"
					required
					value={`${new Date().getFullYear() + 1}-06-30`}
					class="w-full px-3 py-2 rounded-xl bg-white border border-[#d5cebe] text-[13px] text-[#1d1b17] focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-600 transition-all font-mono"
				/>
			</div>
			<div class="md:col-span-2">
				<button
					type="submit"
					class="w-full h-[41px] flex items-center justify-center gap-2 px-4 py-2 rounded-xl bg-amber-600 hover:bg-amber-700 text-white font-bold text-[13px] shadow-[0_2px_6px_rgba(217,119,6,0.25)] active:translate-y-0.5 transition-all cursor-pointer"
				>
					<span class="material-symbols-outlined text-[17px]">add</span>
					<span>Adicionar</span>
				</button>
			</div>
		</form>
	</div>
{/if}
