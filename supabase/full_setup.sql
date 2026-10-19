-- ═══════════════════════════════════════════════════════════════
-- JE Strategy OS v4 — Full Schema, Triggers, RLS & Seed Data
-- ═══════════════════════════════════════════════════════════════

create extension if not exists "pgcrypto";

-- ═══════════════════════════════════════════════════════════════
-- ENUMS
-- ═══════════════════════════════════════════════════════════════
do $$ begin
  if not exists (select 1 from pg_type where typname = 'node_tree') then
    create type node_tree as enum ('strategy', 'identity');
  end if;
  if not exists (select 1 from pg_type where typname = 'node_type') then
    create type node_type as enum (
      'objective', 'key_result', 'kpi',        -- strategy
      'mission', 'value'                       -- identity (no vision)
    );
  end if;
  if not exists (select 1 from pg_type where typname = 'node_status') then
    create type node_status as enum (
      'not_started', 'on_track', 'at_risk', 'off_track', 'done'
    );
  end if;
end $$;

-- ═══════════════════════════════════════════════════════════════
-- PROFILES (mirror of auth.users)
-- ═══════════════════════════════════════════════════════════════
create table if not exists profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text not null,
  email       text,
  role        text not null default 'member'
                check (role in ('admin', 'member', 'viewer')),
  color       text,
  created_at  timestamptz not null default now()
);

create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
declare
  initial_role text := 'member';
begin
  if lower(coalesce(new.email, '')) = 'vitor.kunz@nuvemjr.com.br' then
    initial_role := 'admin';
  end if;

  insert into public.profiles (id, name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email,
    initial_role
  )
  on conflict (id) do update
    set email = excluded.email,
        role = case
          when lower(excluded.email) = 'vitor.kunz@nuvemjr.com.br' then 'admin'
          else profiles.role
        end;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ═══════════════════════════════════════════════════════════════
-- CYCLES (semesters)
-- ═══════════════════════════════════════════════════════════════
create table if not exists cycles (
  id          text primary key default gen_random_uuid()::text,
  code        text unique not null,          -- '2026-S1'
  year        int  not null,
  semester    int  not null check (semester in (1, 2)),
  start_date  date not null,
  end_date    date not null,
  created_at  timestamptz not null default now(),
  unique (year, semester)
);

-- ═══════════════════════════════════════════════════════════════
-- TEAMS & MEMBERSHIPS
-- ═══════════════════════════════════════════════════════════════
create table if not exists teams (
  id          text primary key default gen_random_uuid()::text,
  name        text not null,
  description text,
  color       text default '#2563eb',
  created_at  timestamptz not null default now()
);

create table if not exists team_members (
  team_id     text not null references teams(id) on delete cascade,
  user_id     uuid not null references profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (team_id, user_id)
);
create index if not exists team_members_user_idx on team_members (user_id);

-- ═══════════════════════════════════════════════════════════════
-- NODES
-- ═══════════════════════════════════════════════════════════════
create table if not exists nodes (
  id            text primary key default gen_random_uuid()::text,
  parent_id     text references nodes(id) on delete cascade,
  tree          node_tree not null,
  type          node_type not null,
  title         text not null,
  description   text,

  year          int,
  quarter       smallint check (quarter between 1 and 4),
  cycle_id      text references cycles(id) on delete set null,

  start_year    int,
  end_year      int,

  status        node_status not null default 'not_started',
  weight        numeric not null default 1,
  sort_order    int not null default 0,

  unit          text,
  baseline      numeric,
  target_value  numeric,
  current_value numeric,
  direction     text check (direction in ('up', 'down')),

  manual_progress numeric check (manual_progress between 0 and 1),

  created_by    uuid references profiles(id) on delete set null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists nodes_tree_parent_idx on nodes (tree, parent_id);
create index if not exists nodes_cycle_idx on nodes (cycle_id);
create index if not exists nodes_type_idx on nodes (type);
create index if not exists nodes_year_idx on nodes (year);

create unique index if not exists one_mission on nodes (tree) where type = 'mission';

create or replace function touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists nodes_touch_updated_at on nodes;
create trigger nodes_touch_updated_at
  before update on nodes
  for each row execute function touch_updated_at();

-- ═══════════════════════════════════════════════════════════════
-- PARENT-TYPE INTEGRITY
-- ═══════════════════════════════════════════════════════════════
create or replace function validate_parent()
returns trigger language plpgsql as $$
declare p_type node_type; p_tree node_tree;
begin
  if new.parent_id is null then
    if new.type not in ('objective', 'mission') then
      raise exception 'Only objective or mission can be a root (got %)', new.type;
    end if;
    if new.type = 'objective' and new.year is null then
      raise exception 'Objectives must specify a year';
    end if;
    if new.type = 'mission' then
      new.year := null; new.quarter := null; new.cycle_id := null;
    end if;
    return new;
  end if;

  select type, tree into p_type, p_tree from nodes where id = new.parent_id;
  if p_tree is null then raise exception 'Parent node % not found', new.parent_id; end if;
  if p_tree <> new.tree then
    raise exception 'Tree mismatch: parent is % child is %', p_tree, new.tree;
  end if;

  if not ((p_type, new.type) in (
      ('objective',  'key_result'),
      ('objective',  'kpi'),
      ('key_result', 'kpi'),
      ('mission',    'value')
  )) then
    raise exception 'Invalid parent % → %', p_type, new.type;
  end if;

  if new.type in ('key_result', 'kpi') then
    new.year := null;
    new.quarter := null;
  end if;

  return new;
end $$;

drop trigger if exists nodes_validate on nodes;
create trigger nodes_validate
  before insert or update of parent_id, type, year, cycle_id on nodes
  for each row execute function validate_parent();

-- ═══════════════════════════════════════════════════════════════
-- ASSIGNEES & TEAMS
-- ═══════════════════════════════════════════════════════════════
create table if not exists node_assignees (
  node_id  text not null references nodes(id) on delete cascade,
  user_id  uuid not null references profiles(id) on delete cascade,
  primary key (node_id, user_id)
);
create index if not exists node_assignees_user_idx on node_assignees (user_id);

create table if not exists node_teams (
  node_id  text not null references nodes(id) on delete cascade,
  team_id  text not null references teams(id) on delete cascade,
  primary key (node_id, team_id)
);
create index if not exists node_teams_team_idx on node_teams (team_id);

-- ═══════════════════════════════════════════════════════════════
-- VALUE ALIGNMENT (many-to-many: strategy nodes ↔ values)
-- ═══════════════════════════════════════════════════════════════
create table if not exists node_values (
  node_id   text not null references nodes(id) on delete cascade,
  value_id  text not null references nodes(id) on delete cascade,
  primary key (node_id, value_id),
  check (node_id <> value_id)
);
create index if not exists node_values_value_idx on node_values (value_id);

create or replace function validate_node_value()
returns trigger language plpgsql as $$
declare n_type node_type; v_type node_type; n_tree node_tree; v_tree node_tree;
begin
  select type, tree into n_type, n_tree from nodes where id = new.node_id;
  select type, tree into v_type, v_tree from nodes where id = new.value_id;
  if n_tree is null or v_tree is null then
    raise exception 'node_id or value_id does not exist';
  end if;
  if n_tree <> 'strategy' then
    raise exception 'node_id must reference a strategy node';
  end if;
  if v_type <> 'value' then
    raise exception 'value_id must reference a value';
  end if;
  return new;
end $$;

drop trigger if exists node_values_validate on node_values;
create trigger node_values_validate
  before insert or update on node_values
  for each row execute function validate_node_value();

-- ═══════════════════════════════════════════════════════════════
-- METRIC HISTORY
-- ═══════════════════════════════════════════════════════════════
create table if not exists metric_updates (
  id          text primary key default gen_random_uuid()::text,
  node_id     text not null references nodes(id) on delete cascade,
  value       numeric not null,
  note        text,
  user_id     uuid references profiles(id) on delete set null,
  created_at  timestamptz not null default now()
);
create index if not exists metric_updates_node_idx on metric_updates (node_id, created_at desc);

create or replace function sync_kpi_current_value()
returns trigger language plpgsql as $$
begin
  update nodes set current_value = new.value
    where id = new.node_id and type = 'kpi';
  return new;
end $$;

drop trigger if exists metric_updates_sync on metric_updates;
create trigger metric_updates_sync
  after insert on metric_updates
  for each row execute function sync_kpi_current_value();

-- ═══════════════════════════════════════════════════════════════
-- TRANSACTIONAL HELPERS (called via supabase.rpc)
-- ═══════════════════════════════════════════════════════════════
create or replace function set_assignees(p_node text, p_users uuid[])
returns void language plpgsql security invoker as $$
begin
  delete from node_assignees where node_id = p_node;
  insert into node_assignees (node_id, user_id)
    select p_node, unnest(p_users);
end $$;

create or replace function set_node_values(p_node text, p_values text[])
returns void language plpgsql security invoker as $$
begin
  delete from node_values where node_id = p_node;
  insert into node_values (node_id, value_id)
    select p_node, unnest(p_values);
end $$;

create or replace function set_node_teams(p_node text, p_teams text[])
returns void language plpgsql security invoker as $$
begin
  delete from node_teams where node_id = p_node;
  insert into node_teams (node_id, team_id)
    select p_node, unnest(p_teams);
end $$;

-- ═══════════════════════════════════════════════════════════════
-- ROW-LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════
alter table profiles        enable row level security;
alter table cycles          enable row level security;
alter table teams           enable row level security;
alter table team_members    enable row level security;
alter table nodes           enable row level security;
alter table node_assignees  enable row level security;
alter table node_teams      enable row level security;
alter table node_values     enable row level security;
alter table metric_updates  enable row level security;

create or replace function current_role_() returns text
language sql stable as $$
  select role from profiles where id = auth.uid()
$$;

create or replace function is_editor() returns boolean
language sql stable as $$
  select coalesce(current_role_() in ('admin','member'), false)
$$;

create or replace function is_admin() returns boolean
language sql stable as $$
  select coalesce(current_role_() = 'admin', false)
$$;

-- profiles
drop policy if exists "profiles: read all authenticated" on profiles;
create policy "profiles: read all authenticated"
  on profiles for select using (auth.role() = 'authenticated');

drop policy if exists "profiles: self update name/color" on profiles;
create policy "profiles: self update name/color"
  on profiles for update using (id = auth.uid())
  with check (id = auth.uid());

drop policy if exists "profiles: admin full" on profiles;
create policy "profiles: admin full"
  on profiles for all using (is_admin()) with check (is_admin());

-- cycles
drop policy if exists "cycles: read all authenticated" on cycles;
create policy "cycles: read all authenticated"
  on cycles for select using (auth.role() = 'authenticated');

drop policy if exists "cycles: admin write" on cycles;
create policy "cycles: admin write"
  on cycles for all using (is_admin()) with check (is_admin());

-- teams
drop policy if exists "teams: read all authenticated" on teams;
create policy "teams: read all authenticated"
  on teams for select using (auth.role() = 'authenticated');

drop policy if exists "teams: admin write" on teams;
create policy "teams: admin write"
  on teams for all using (is_admin()) with check (is_admin());

-- team_members
drop policy if exists "team_members: read all authenticated" on team_members;
create policy "team_members: read all authenticated"
  on team_members for select using (auth.role() = 'authenticated');

drop policy if exists "team_members: admin write" on team_members;
create policy "team_members: admin write"
  on team_members for all using (is_admin()) with check (is_admin());

-- nodes
drop policy if exists "nodes: read authenticated" on nodes;
create policy "nodes: read authenticated"
  on nodes for select using (auth.role() = 'authenticated');

drop policy if exists "nodes: editors write" on nodes;
create policy "nodes: editors write"
  on nodes for all using (is_editor()) with check (is_editor());

-- node_assignees
drop policy if exists "assignees: read authenticated" on node_assignees;
create policy "assignees: read authenticated"
  on node_assignees for select using (auth.role() = 'authenticated');

drop policy if exists "assignees: editors write" on node_assignees;
create policy "assignees: editors write"
  on node_assignees for all using (is_editor()) with check (is_editor());

-- node_teams
drop policy if exists "node_teams: read authenticated" on node_teams;
create policy "node_teams: read authenticated"
  on node_teams for select using (auth.role() = 'authenticated');

drop policy if exists "node_teams: editors write" on node_teams;
create policy "node_teams: editors write"
  on node_teams for all using (is_editor()) with check (is_editor());

-- node_values
drop policy if exists "node_values: read authenticated" on node_values;
create policy "node_values: read authenticated"
  on node_values for select using (auth.role() = 'authenticated');

drop policy if exists "node_values: editors write" on node_values;
create policy "node_values: editors write"
  on node_values for all using (is_editor()) with check (is_editor());

-- metric_updates
drop policy if exists "metrics: read authenticated" on metric_updates;
create policy "metrics: read authenticated"
  on metric_updates for select using (auth.role() = 'authenticated');

drop policy if exists "metrics: editors insert own" on metric_updates;
create policy "metrics: editors insert own"
  on metric_updates for insert with check (is_editor());


-- ═══════════════════════════════════════════════════════════════
-- JE Strategy OS - Seed Data from Local Store
-- ═══════════════════════════════════════════════════════════════

-- 1. Teams
INSERT INTO teams (id, name, description, color, created_at) VALUES ('t-presidencia', 'Presidência', 'Liderança institucional, conselho e novos parceiros seniores.', '#2563eb', '2026-10-18T12:00:00.000Z') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, color = EXCLUDED.color;
INSERT INTO teams (id, name, description, color, created_at) VALUES ('t-adm-fin', 'Administrativo-Financeiro', 'Gestão financeira, precificação, orçamento e frente de inovação.', '#0891b2', '2026-10-18T12:00:00.000Z') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, color = EXCLUDED.color;
INSERT INTO teams (id, name, description, color, created_at) VALUES ('t-comercial', 'Comercial', 'Vendas, parcerias com EJs, propostas de cultura e grupos de trabalho.', '#059669', '2026-10-18T12:00:00.000Z') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, color = EXCLUDED.color;
INSERT INTO teams (id, name, description, color, created_at) VALUES ('t-marketing', 'Marketing', 'Comunicação, campanhas de vendas, redes sociais, blog e site.', '#ea580c', '2026-10-18T12:00:00.000Z') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, color = EXCLUDED.color;
INSERT INTO teams (id, name, description, color, created_at) VALUES ('t-projetos', 'Projetos', 'Consultoria, jornada do cliente, briefing e capacitações técnicas.', '#7c3aed', '2026-10-18T12:00:00.000Z') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, color = EXCLUDED.color;
INSERT INTO teams (id, name, description, color, created_at) VALUES ('t-gp', 'Gestão de Pessoas', 'Jornada do membro, acompanhamento e desempenho, seleção e desligamento.', '#d97706', '2026-10-18T12:00:00.000Z') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, color = EXCLUDED.color;
INSERT INTO teams (id, name, description, color, created_at) VALUES ('t-todas', 'Todas as Diretorias', 'Processos e modelos transversais a todas as diretorias.', '#64748b', '2026-10-18T12:00:00.000Z') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, color = EXCLUDED.color;

-- 2. Cycles
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2024-s1', '2024-S1', 2024, 1, '2024-01-01', '2024-06-30', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2024-s2', '2024-S2', 2024, 2, '2024-07-01', '2024-12-31', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2025-s1', '2025-S1', 2025, 1, '2025-01-01', '2025-06-30', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2025-s2', '2025-S2', 2025, 2, '2025-07-01', '2025-12-31', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2026-s1', '2026-S1', 2026, 1, '2026-01-01', '2026-06-30', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2026-s2', '2026-S2', 2026, 2, '2026-07-01', '2026-12-31', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2027-s1', '2027-S1', 2027, 1, '2027-01-01', '2027-06-30', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;
INSERT INTO cycles (id, code, year, semester, start_date, end_date, created_at) VALUES ('cyc-2027-s2', '2027-S2', 2027, 2, '2027-07-01', '2027-12-31', '2026-10-18T12:00:00.000Z') ON CONFLICT (code) DO NOTHING;

-- 3. Nodes
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'id-mission', NULL, 'identity', 'mission', 'A excelência nasce de uma jornada do membro clara e potencializadora rumo ao desenvolvimento coletivo', 'Missão do Planejamento Estratégico 2026 - Nuvem',
  NULL, NULL, NULL, 2026, NULL,
  'on_track', 1, 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T09:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'val-excelencia', 'id-mission', 'identity', 'value', 'Excelência em Cada Entrega', 'Buscamos o padrão mais alto de qualidade em nossos serviços e projetos, gerando impacto tangível.',
  NULL, NULL, NULL, 2026, NULL,
  'on_track', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T09:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'val-jornada-membro', 'id-mission', 'identity', 'value', 'Jornada Potencializadora', 'Acreditamos no protagonismo e no desenvolvimento contínuo de cada membro ao longo de sua trajetória.',
  NULL, NULL, NULL, 2026, NULL,
  'on_track', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T09:10:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'val-desenvolvimento-coletivo', 'id-mission', 'identity', 'value', 'Desenvolvimento Coletivo', 'Crescemos juntos: compartilhamos conhecimento, colaboramos ativamente e fortalecemos a equipe.',
  NULL, NULL, NULL, 2026, NULL,
  'on_track', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T09:15:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'val-sentimento-dono', 'id-mission', 'identity', 'value', 'Sentimento de Dono & Inovação', 'Atitude proativa, responsabilidade pelos resultados e busca constante por soluções inovadoras.',
  NULL, NULL, NULL, 2026, NULL,
  'on_track', 1, 4, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T09:20:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'id-mission-2021', NULL, 'identity', 'mission', 'Capacitar universitários por meio de projetos de consultoria de gestão e impulsionar pequenos negócios locais.', 'Missão do triênio 2021–2023 focada na consolidação regional e estruturação inicial dos núcleos de projetos.',
  NULL, NULL, NULL, 2021, 2023,
  'done', 1, 0, NULL, NULL, NULL, NULL, NULL, NULL, '2021-01-15T10:00:00.000Z', '2023-12-31T23:59:59.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'val-foco-2021', 'id-mission-2021', 'identity', 'value', 'Foco no Resultado', 'Entregas práticas com impacto direto e ágil para o cliente atendido.',
  NULL, NULL, NULL, 2021, 2023,
  'done', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, '2021-01-15T10:05:00.000Z', '2023-12-31T23:59:59.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'val-garra-2021', 'id-mission-2021', 'identity', 'value', 'Proatividade & Garra', 'Superar desafios com postura realizadora e espírito empreendedor.',
  NULL, NULL, NULL, 2021, 2023,
  'done', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, '2021-01-15T10:10:00.000Z', '2023-12-31T23:59:59.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'obj-2026-excelencia', NULL, 'strategy', 'objective', 'Ser EJ de Excelência', 'OKR 1: Ser EJ de Excelência — Planejamento Estratégico 2026 (Nuvem)',
  2026, 4, NULL, NULL, NULL,
  'on_track', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'obj-2026-jornada-membro', NULL, 'strategy', 'objective', 'Construir uma Jornada do Membro', 'OKR 2: Construir uma Jornada do Membro — Planejamento Estratégico 2026 (Nuvem)',
  2026, 4, NULL, NULL, NULL,
  'on_track', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-1', 'obj-2026-excelencia', 'strategy', 'key_result', 'Atingir R$ 46.865,51 de faturamento', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-1', 'kr-1-1', 'strategy', 'kpi', 'Valor do Faturamento (R$)', 'Indicador de performance: Valor do Faturamento (R$)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'R$', 0, 46865.51, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-2', 'obj-2026-excelencia', 'strategy', 'key_result', 'Faturamento colaborativo - R$ 11.952,00', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-2', 'kr-1-2', 'strategy', 'kpi', 'Valor do Faturamento Colaborativo (R$)', 'Indicador de performance: Valor do Faturamento Colaborativo (R$)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'R$', 0, 11952, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-3', 'obj-2026-excelencia', 'strategy', 'key_result', 'CSAT 3.5', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-3', 'kr-1-3', 'strategy', 'kpi', 'Nota Média de CSAT', 'Indicador de performance: Nota Média de CSAT',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'pts', 0, 3.5, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-4', 'obj-2026-excelencia', 'strategy', 'key_result', 'ECM 75%', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 4, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-4', 'kr-1-4', 'strategy', 'kpi', 'Taxa Percentual de ECM (%)', 'Indicador de performance: Taxa Percentual de ECM (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 75, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-5', 'obj-2026-excelencia', 'strategy', 'key_result', 'Atingir taxa de 50% do Tempo de permanência médio', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 5, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-5', 'kr-1-5', 'strategy', 'kpi', 'Taxa Percentual de Permanência (%)', 'Indicador de performance: Taxa Percentual de Permanência (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 50, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-8', 'obj-2026-excelencia', 'strategy', 'key_result', '100% de presença em RV do conselho', 'Meta associada à diretoria presidencia',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 8, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-8', 'kr-1-8', 'strategy', 'kpi', 'Taxa de Presença em RV (%)', 'Indicador de performance: Taxa de Presença em RV (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 100, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-9', 'obj-2026-excelencia', 'strategy', 'key_result', '1 Relatório/tabela de precificação', 'Meta associada à diretoria adm-fin',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 9, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-9', 'kr-1-9', 'strategy', 'kpi', 'Relatório/Tabela Entregue (Sim/Não)', 'Indicador de performance: Relatório/Tabela Entregue (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'tabela', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-10', 'obj-2026-excelencia', 'strategy', 'key_result', 'Estruturar 1 frente de atuação de diretoria voltada para inovação', 'Meta associada à diretoria adm-fin',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 10, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-10', 'kr-1-10', 'strategy', 'kpi', 'Frente Estruturada (Sim/Não)', 'Indicador de performance: Frente Estruturada (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'frente', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-11', 'obj-2026-excelencia', 'strategy', 'key_result', '3 Capacitações externas - experiência de mercado', 'Meta associada à diretoria comercial',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 11, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-11', 'kr-1-11', 'strategy', 'kpi', 'Número de Capacitações Realizadas', 'Indicador de performance: Número de Capacitações Realizadas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'capacitações', 0, 3, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-13', 'obj-2026-excelencia', 'strategy', 'key_result', 'Execução de 100% dos passos da Proposta de Cultura', 'Meta associada à diretoria comercial',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 13, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-13', 'kr-1-13', 'strategy', 'kpi', 'Percentual de Execução da Proposta (%)', 'Indicador de performance: Percentual de Execução da Proposta (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 100, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-14', 'obj-2026-excelencia', 'strategy', 'key_result', 'Adicionar a cartela de serviços da Nuvem em outras 2 EJs', 'Meta associada à diretoria comercial',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 14, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-14', 'kr-1-14', 'strategy', 'kpi', 'Número de EJs Parceiras na Cartela', 'Indicador de performance: Número de EJs Parceiras na Cartela',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'EJs', 0, 2, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-15', 'obj-2026-excelencia', 'strategy', 'key_result', 'Fechar 1 parceria com EJ de design', 'Meta associada à diretoria comercial',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 15, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-15', 'kr-1-15', 'strategy', 'kpi', 'Parceria Fechada (Sim/Não)', 'Indicador de performance: Parceria Fechada (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'parceria', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-16', 'obj-2026-excelencia', 'strategy', 'key_result', 'Definição de 1 público alvo para cada rede social', 'Meta associada à diretoria marketing',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 16, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-16', 'kr-1-16', 'strategy', 'kpi', 'Número de Públicos Definidos e Registrados', 'Indicador de performance: Número de Públicos Definidos e Registrados',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'públicos', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-17', 'obj-2026-excelencia', 'strategy', 'key_result', 'Rodar 2 campanhas voltadas para vendas (1 no tele para colaborativo)', 'Meta associada à diretoria marketing',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 17, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-17', 'kr-1-17', 'strategy', 'kpi', 'Número de Campanhas Rodadas', 'Indicador de performance: Número de Campanhas Rodadas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'campanhas', 0, 2, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-18', 'obj-2026-excelencia', 'strategy', 'key_result', 'Fazer uma lista com 20 temas para o blog', 'Meta associada à diretoria marketing',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-18', 'kr-1-18', 'strategy', 'kpi', 'Número de Temas Listados', 'Indicador de performance: Número de Temas Listados',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'temas', 0, 20, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-19', 'obj-2026-excelencia', 'strategy', 'key_result', 'Fazer 6 capacitações para o time durante o ano', 'Meta associada à diretoria marketing',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 19, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-19', 'kr-1-19', 'strategy', 'kpi', 'Número de Capacitações Realizadas', 'Indicador de performance: Número de Capacitações Realizadas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'capacitações', 0, 6, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-20', 'obj-2026-excelencia', 'strategy', 'key_result', 'Produção de 1 manual sobre o uso do site', 'Meta associada à diretoria marketing',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 20, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-20', 'kr-1-20', 'strategy', 'kpi', 'Manual Produzido (Sim/Não)', 'Indicador de performance: Manual Produzido (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'manual', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-21', 'obj-2026-excelencia', 'strategy', 'key_result', 'Reformulação do briefing', 'Meta associada à diretoria projetos',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 21, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-21', 'kr-1-21', 'strategy', 'kpi', 'Briefing Reformulado e Aprovado (Sim/Não)', 'Indicador de performance: Briefing Reformulado e Aprovado (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'briefing', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-22', 'obj-2026-excelencia', 'strategy', 'key_result', 'Mapear e documentar 100% da jornada do cliente', 'Meta associada à diretoria projetos',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 22, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-22', 'kr-1-22', 'strategy', 'kpi', 'Percentual da Jornada Mapeada e Documentada (%)', 'Indicador de performance: Percentual da Jornada Mapeada e Documentada (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 100, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-1-23', 'obj-2026-excelencia', 'strategy', 'key_result', '6 capacitações gerais durante o ano', 'Meta associada à diretoria projetos',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 23, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-1-23', 'kr-1-23', 'strategy', 'kpi', 'Número de Capacitações Realizadas', 'Indicador de performance: Número de Capacitações Realizadas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'capacitações', 0, 6, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-1', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Mapear 100% dos processos e jornada do membro', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-1', 'kr-2-1', 'strategy', 'kpi', 'Percentual de Processos Globais Mapeados (%)', 'Indicador de performance: Percentual de Processos Globais Mapeados (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 100, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-2', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Documentar e padronizar 70% dos processos', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-2', 'kr-2-2', 'strategy', 'kpi', 'Percentual de Processos Globais Documentados (%)', 'Indicador de performance: Percentual de Processos Globais Documentados (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 70, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-3', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Investir em 3 iniciativas de desenvolvimento do membro (software, curso, palestras)', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-3', 'kr-2-3', 'strategy', 'kpi', 'Número de Iniciativas Adquiridas/Realizadas', 'Indicador de performance: Número de Iniciativas Adquiridas/Realizadas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'iniciativas', 0, 3, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-4', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Atingir CSAT 3.5 de satisfação geral dos membros', 'Meta associada à diretoria geral',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 4, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-4', 'kr-2-4', 'strategy', 'kpi', 'Nota Média de CSAT Interno', 'Indicador de performance: Nota Média de CSAT Interno',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'pts', 0, 3.5, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-5', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Mapeamento de 100% dos processos de diretoria', 'Meta associada à diretoria todas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 5, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-5', 'kr-2-5', 'strategy', 'kpi', 'Percentual de Processos Mapeados (%)', 'Indicador de performance: Percentual de Processos Mapeados (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 100, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-6', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Documentação de 70% modelos e processos da área', 'Meta associada à diretoria todas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 6, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-6', 'kr-2-6', 'strategy', 'kpi', 'Percentual de Processos Documentados (%)', 'Indicador de performance: Percentual de Processos Documentados (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 70, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-7', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Definição de 1 orçamento da jornada do membro', 'Meta associada à diretoria adm-fin',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 7, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-7', 'kr-2-7', 'strategy', 'kpi', 'Orçamento Definido (Sim/Não)', 'Indicador de performance: Orçamento Definido (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'orçamento', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-8', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Definir 1 política de identificação e auxílio para membros minoritários', 'Meta associada à diretoria adm-fin',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 8, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-8', 'kr-2-8', 'strategy', 'kpi', 'Política Definida (Sim/Não)', 'Indicador de performance: Política Definida (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'política', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-9', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Construir 1 tabela de acompanhamento, desenvolvimento e desempenho do membro', 'Meta associada à diretoria gp',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 9, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-9', 'kr-2-9', 'strategy', 'kpi', 'Tabela Construída (Sim/Não)', 'Indicador de performance: Tabela Construída (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'tabela', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-10', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Documentar todas fases do processo de jornada do membro (planejamento, execução, avaliação) - 3 etapas', 'Meta associada à diretoria gp',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 10, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-10', 'kr-2-10', 'strategy', 'kpi', 'Número de Etapas Documentadas', 'Indicador de performance: Número de Etapas Documentadas',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'etapas', 0, 3, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-11', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Atualizar manual de desligamento', 'Meta associada à diretoria gp',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 11, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-11', 'kr-2-11', 'strategy', 'kpi', 'Manual Atualizado (Sim/Não)', 'Indicador de performance: Manual Atualizado (Sim/Não)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, 'manual', 0, 1, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kr-2-12', 'obj-2026-jornada-membro', 'strategy', 'key_result', 'Alteração em 100% das etapas do processo seletivo e processo trainee', 'Meta associada à diretoria gp',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 12, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-01T10:00:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;
INSERT INTO nodes (
  id, parent_id, tree, type, title, description,
  year, quarter, cycle_id, start_year, end_year,
  status, weight, sort_order, unit, baseline, target_value, current_value, direction, manual_progress, created_at, updated_at
) VALUES (
  'kpi-2-12', 'kr-2-12', 'strategy', 'kpi', 'Percentual de Etapas Alteradas/Revisadas (%)', 'Indicador de performance: Percentual de Etapas Alteradas/Revisadas (%)',
  NULL, NULL, NULL, NULL, NULL,
  'on_track', 1, 1, '%', 0, 100, 0, 'up', NULL, '2026-01-01T10:05:00.000Z', '2026-10-18T12:00:00.000Z'
) ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, status = EXCLUDED.status, current_value = EXCLUDED.current_value;

-- 4. Node Values (Alignment)
INSERT INTO node_values (node_id, value_id) VALUES ('obj-2026-excelencia', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('obj-2026-excelencia', 'val-sentimento-dono') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('obj-2026-jornada-membro', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('obj-2026-jornada-membro', 'val-desenvolvimento-coletivo') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-1', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-2', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-3', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-4', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-5', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-8', 'val-sentimento-dono') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-9', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-10', 'val-sentimento-dono') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-11', 'val-desenvolvimento-coletivo') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-13', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-14', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-15', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-16', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-17', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-18', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-19', 'val-desenvolvimento-coletivo') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-20', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-21', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-22', 'val-excelencia') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-1-23', 'val-desenvolvimento-coletivo') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-1', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-2', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-3', 'val-desenvolvimento-coletivo') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-4', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-5', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-6', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-7', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-8', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-9', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-10', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-11', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;
INSERT INTO node_values (node_id, value_id) VALUES ('kr-2-12', 'val-jornada-membro') ON CONFLICT (node_id, value_id) DO NOTHING;

-- 5. Node Teams
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-excelencia', 't-presidencia') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-excelencia', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-excelencia', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-excelencia', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-excelencia', 't-projetos') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-jornada-membro', 't-todas') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-jornada-membro', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('obj-2026-jornada-membro', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-8', 't-presidencia') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-8', 't-presidencia') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-9', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-9', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-10', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-10', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-11', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-11', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-13', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-13', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-14', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-14', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-15', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-15', 't-comercial') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-16', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-16', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-17', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-17', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-18', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-18', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-19', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-19', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-20', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-20', 't-marketing') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-21', 't-projetos') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-21', 't-projetos') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-22', 't-projetos') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-22', 't-projetos') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-1-23', 't-projetos') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-1-23', 't-projetos') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-5', 't-todas') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-5', 't-todas') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-6', 't-todas') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-6', 't-todas') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-7', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-7', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-8', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-8', 't-adm-fin') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-9', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-9', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-10', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-10', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-11', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-11', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kr-2-12', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
INSERT INTO node_teams (node_id, team_id) VALUES ('kpi-2-12', 't-gp') ON CONFLICT (node_id, team_id) DO NOTHING;
