-- ═══════════════════════════════════════════════════════════════
-- FIX RLS RECURSION, MISSING COLUMNS, AND ENSURE TEAMS & ASSOCIATIONS
-- ═══════════════════════════════════════════════════════════════

-- 1. Ensure required columns exist
alter table teams add column if not exists icon text;
alter table nodes add column if not exists icon text;
alter table nodes add column if not exists color text;

-- 2. Fix helper functions to use SECURITY DEFINER and fixed search_path to prevent recursion
create or replace function public.current_role_() returns text
language sql stable security definer
set search_path = public as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.is_editor() returns boolean
language sql stable security definer
set search_path = public as $$
  select coalesce(public.current_role_() in ('admin','member'), false)
$$;

create or replace function public.is_admin() returns boolean
language sql stable security definer
set search_path = public as $$
  select coalesce(public.current_role_() = 'admin', false)
$$;

-- 3. Fix profiles policies (eliminate FOR ALL to prevent recursion on SELECT)
drop policy if exists "profiles: read all authenticated" on profiles;
drop policy if exists "profiles: read all" on profiles;
drop policy if exists "profiles: self update name/color" on profiles;
drop policy if exists "profiles: admin full" on profiles;
drop policy if exists "profiles: admin insert" on profiles;
drop policy if exists "profiles: admin update" on profiles;
drop policy if exists "profiles: admin delete" on profiles;

create policy "profiles: read all"
  on profiles for select using (true);

create policy "profiles: self update name/color"
  on profiles for update using (id = auth.uid())
  with check (id = auth.uid());

create policy "profiles: admin insert"
  on profiles for insert with check (is_admin());

create policy "profiles: admin update"
  on profiles for update using (is_admin()) with check (is_admin());

create policy "profiles: admin delete"
  on profiles for delete using (is_admin());

-- 4. Fix cycles policies
drop policy if exists "cycles: read all authenticated" on cycles;
drop policy if exists "cycles: read all" on cycles;
drop policy if exists "cycles: admin write" on cycles;
drop policy if exists "cycles: admin insert" on cycles;
drop policy if exists "cycles: admin update" on cycles;
drop policy if exists "cycles: admin delete" on cycles;

create policy "cycles: read all"
  on cycles for select using (true);

create policy "cycles: admin insert"
  on cycles for insert with check (is_admin());

create policy "cycles: admin update"
  on cycles for update using (is_admin()) with check (is_admin());

create policy "cycles: admin delete"
  on cycles for delete using (is_admin());

-- 5. Fix teams policies
drop policy if exists "teams: read all authenticated" on teams;
drop policy if exists "teams: read all" on teams;
drop policy if exists "teams: admin write" on teams;
drop policy if exists "teams: admin insert" on teams;
drop policy if exists "teams: admin update" on teams;
drop policy if exists "teams: admin delete" on teams;

create policy "teams: read all"
  on teams for select using (true);

create policy "teams: admin insert"
  on teams for insert with check (is_admin());

create policy "teams: admin update"
  on teams for update using (is_admin()) with check (is_admin());

create policy "teams: admin delete"
  on teams for delete using (is_admin());

-- 6. Fix team_members policies
drop policy if exists "team_members: read all authenticated" on team_members;
drop policy if exists "team_members: read all" on team_members;
drop policy if exists "team_members: admin write" on team_members;
drop policy if exists "team_members: admin insert" on team_members;
drop policy if exists "team_members: admin update" on team_members;
drop policy if exists "team_members: admin delete" on team_members;

create policy "team_members: read all"
  on team_members for select using (true);

create policy "team_members: admin insert"
  on team_members for insert with check (is_admin());

create policy "team_members: admin update"
  on team_members for update using (is_admin()) with check (is_admin());

create policy "team_members: admin delete"
  on team_members for delete using (is_admin());

-- 7. Fix nodes policies
drop policy if exists "nodes: read authenticated" on nodes;
drop policy if exists "nodes: read all" on nodes;
drop policy if exists "nodes: editors write" on nodes;
drop policy if exists "nodes: editors insert" on nodes;
drop policy if exists "nodes: editors update" on nodes;
drop policy if exists "nodes: editors delete" on nodes;

create policy "nodes: read all"
  on nodes for select using (true);

create policy "nodes: editors insert"
  on nodes for insert with check (is_editor());

create policy "nodes: editors update"
  on nodes for update using (is_editor()) with check (is_editor());

create policy "nodes: editors delete"
  on nodes for delete using (is_editor());

-- 8. Fix node_assignees policies
drop policy if exists "assignees: read authenticated" on node_assignees;
drop policy if exists "assignees: read all" on node_assignees;
drop policy if exists "assignees: editors write" on node_assignees;
drop policy if exists "assignees: editors insert" on node_assignees;
drop policy if exists "assignees: editors update" on node_assignees;
drop policy if exists "assignees: editors delete" on node_assignees;

create policy "assignees: read all"
  on node_assignees for select using (true);

create policy "assignees: editors insert"
  on node_assignees for insert with check (is_editor());

create policy "assignees: editors update"
  on node_assignees for update using (is_editor()) with check (is_editor());

create policy "assignees: editors delete"
  on node_assignees for delete using (is_editor());

-- 9. Fix node_teams policies
drop policy if exists "node_teams: read authenticated" on node_teams;
drop policy if exists "node_teams: read all" on node_teams;
drop policy if exists "node_teams: editors write" on node_teams;
drop policy if exists "node_teams: editors insert" on node_teams;
drop policy if exists "node_teams: editors update" on node_teams;
drop policy if exists "node_teams: editors delete" on node_teams;

create policy "node_teams: read all"
  on node_teams for select using (true);

create policy "node_teams: editors insert"
  on node_teams for insert with check (is_editor());

create policy "node_teams: editors update"
  on node_teams for update using (is_editor()) with check (is_editor());

create policy "node_teams: editors delete"
  on node_teams for delete using (is_editor());

-- 10. Fix node_values policies
drop policy if exists "node_values: read authenticated" on node_values;
drop policy if exists "node_values: read all" on node_values;
drop policy if exists "node_values: editors write" on node_values;
drop policy if exists "node_values: editors insert" on node_values;
drop policy if exists "node_values: editors update" on node_values;
drop policy if exists "node_values: editors delete" on node_values;

create policy "node_values: read all"
  on node_values for select using (true);

create policy "node_values: editors insert"
  on node_values for insert with check (is_editor());

create policy "node_values: editors update"
  on node_values for update using (is_editor()) with check (is_editor());

create policy "node_values: editors delete"
  on node_values for delete using (is_editor());

-- 11. Fix metric_updates policies
drop policy if exists "metrics: read authenticated" on metric_updates;
drop policy if exists "metrics: read all" on metric_updates;
drop policy if exists "metrics: editors insert own" on metric_updates;

create policy "metrics: read all"
  on metric_updates for select using (true);

create policy "metrics: editors insert own"
  on metric_updates for insert with check (is_editor());

-- 12. Ensure default teams exist
insert into teams (id, name, description, color, created_at) values
  ('t-presidencia', 'Presidência', 'Liderança institucional, conselho e novos parceiros seniores.', '#2563eb', '2026-10-18T12:00:00.000Z'),
  ('t-adm-fin', 'Administrativo-Financeiro', 'Gestão financeira, precificação, orçamento e frente de inovação.', '#0891b2', '2026-10-18T12:00:00.000Z'),
  ('t-comercial', 'Comercial', 'Vendas, parcerias com EJs, propostas de cultura e grupos de trabalho.', '#059669', '2026-10-18T12:00:00.000Z'),
  ('t-marketing', 'Marketing', 'Comunicação, campanhas de vendas, redes sociais, blog e site.', '#ea580c', '2026-10-18T12:00:00.000Z'),
  ('t-projetos', 'Projetos', 'Consultoria, jornada do cliente, briefing e capacitações técnicas.', '#7c3aed', '2026-10-18T12:00:00.000Z'),
  ('t-gp', 'Gestão de Pessoas', 'Jornada do membro, acompanhamento e desempenho, seleção e desligamento.', '#d97706', '2026-10-18T12:00:00.000Z'),
  ('t-todas', 'Todas as Diretorias', 'Processos e modelos transversais a todas as diretorias.', '#64748b', '2026-10-18T12:00:00.000Z')
on conflict (id) do update set
  name = excluded.name,
  description = excluded.description,
  color = excluded.color;

-- 13. Ensure node_teams associations exist
insert into node_teams (node_id, team_id) values
  ('obj-2026-excelencia', 't-presidencia'),
  ('obj-2026-excelencia', 't-adm-fin'),
  ('obj-2026-excelencia', 't-comercial'),
  ('obj-2026-excelencia', 't-marketing'),
  ('obj-2026-excelencia', 't-projetos'),
  ('obj-2026-jornada-membro', 't-todas'),
  ('obj-2026-jornada-membro', 't-adm-fin'),
  ('obj-2026-jornada-membro', 't-gp'),
  ('kr-1-8', 't-presidencia'),
  ('kpi-1-8', 't-presidencia'),
  ('kr-1-9', 't-adm-fin'),
  ('kpi-1-9', 't-adm-fin'),
  ('kr-1-10', 't-adm-fin'),
  ('kpi-1-10', 't-adm-fin'),
  ('kr-1-11', 't-comercial'),
  ('kpi-1-11', 't-comercial'),
  ('kr-1-13', 't-comercial'),
  ('kpi-1-13', 't-comercial'),
  ('kr-1-14', 't-comercial'),
  ('kpi-1-14', 't-comercial'),
  ('kr-1-15', 't-comercial'),
  ('kpi-1-15', 't-comercial'),
  ('kr-1-16', 't-marketing'),
  ('kpi-1-16', 't-marketing'),
  ('kr-1-17', 't-marketing'),
  ('kpi-1-17', 't-marketing'),
  ('kr-1-18', 't-marketing'),
  ('kpi-1-18', 't-marketing'),
  ('kr-1-19', 't-marketing'),
  ('kpi-1-19', 't-marketing'),
  ('kr-1-20', 't-marketing'),
  ('kpi-1-20', 't-marketing'),
  ('kr-1-21', 't-projetos'),
  ('kpi-1-21', 't-projetos'),
  ('kr-1-22', 't-projetos'),
  ('kpi-1-22', 't-projetos'),
  ('kr-1-23', 't-projetos'),
  ('kpi-1-23', 't-projetos'),
  ('kr-2-5', 't-todas'),
  ('kpi-2-5', 't-todas'),
  ('kr-2-6', 't-todas'),
  ('kpi-2-6', 't-todas'),
  ('kr-2-7', 't-adm-fin'),
  ('kpi-2-7', 't-adm-fin'),
  ('kr-2-8', 't-adm-fin'),
  ('kpi-2-8', 't-adm-fin'),
  ('kr-2-9', 't-gp'),
  ('kpi-2-9', 't-gp'),
  ('kr-2-10', 't-gp'),
  ('kpi-2-10', 't-gp'),
  ('kr-2-11', 't-gp'),
  ('kpi-2-11', 't-gp'),
  ('kr-2-12', 't-gp'),
  ('kpi-2-12', 't-gp')
on conflict (node_id, team_id) do nothing;
