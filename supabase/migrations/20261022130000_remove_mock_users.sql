-- ═══════════════════════════════════════════════════════════════
-- REMOVE MOCK / TEST USERS AND KEEP ONLY REAL SUPABASE ACCOUNTS
-- ═══════════════════════════════════════════════════════════════

-- 1. Remove mock users from node_assignees
delete from node_assignees where user_id in (
  '55555555-5555-4555-8555-555555555555',
  '11111111-1111-4111-8111-111111111111',
  '22222222-2222-4222-8222-222222222222',
  '33333333-3333-4333-8333-333333333333',
  '44444444-4444-4444-8444-444444444444',
  '04819e3f-8981-4bbd-b375-6df5aef74af2'
);

-- 2. Remove mock users from team_members
delete from team_members where user_id in (
  '55555555-5555-4555-8555-555555555555',
  '11111111-1111-4111-8111-111111111111',
  '22222222-2222-4222-8222-222222222222',
  '33333333-3333-4333-8333-333333333333',
  '44444444-4444-4444-8444-444444444444',
  '04819e3f-8981-4bbd-b375-6df5aef74af2'
);

-- 3. Remove mock users from profiles
delete from profiles where id in (
  '55555555-5555-4555-8555-555555555555',
  '11111111-1111-4111-8111-111111111111',
  '22222222-2222-4222-8222-222222222222',
  '33333333-3333-4333-8333-333333333333',
  '44444444-4444-4444-8444-444444444444',
  '04819e3f-8981-4bbd-b375-6df5aef74af2'
);

-- 4. Clean up auth user test if exists
delete from auth.users where id = '04819e3f-8981-4bbd-b375-6df5aef74af2';

-- 5. Ensure Vitor Kunz profile is clean and active
update profiles
set name = 'Vitor Kunz',
    email = 'vitor.kunz@nuvemjr.com.br',
    role = 'admin',
    color = '#2563eb'
where id = 'd3c82557-0573-4c97-984d-560f77f38f3e';
