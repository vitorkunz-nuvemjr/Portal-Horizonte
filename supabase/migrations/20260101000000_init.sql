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
