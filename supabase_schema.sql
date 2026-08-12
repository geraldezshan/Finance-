-- =====================================================================
--  Finance+  ·  Supabase schema
--  Run this whole file once in:  Supabase Dashboard -> SQL Editor -> New query
-- =====================================================================

-- ------------------------------------------------------------------ --
-- 1. PROFILES  (1 row per user, linked to the built-in auth.users)
-- ------------------------------------------------------------------ --
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text,
  created_at  timestamptz not null default now()
);

-- ------------------------------------------------------------------ --
-- 2. BUDGETS  (1 accumulating row per user)
-- ------------------------------------------------------------------ --
create table if not exists public.budgets (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users (id) on delete cascade,
  total_income   numeric not null default 0,
  needs_amount   numeric not null default 0,
  savings_amount numeric not null default 0,
  debt_amount    numeric not null default 0,
  tithes_amount  numeric not null default 0,
  updated_at     timestamptz not null default now(),
  unique (user_id)                       -- enables upsert on conflict (user_id)
);

-- ------------------------------------------------------------------ --
-- 3. TRANSACTIONS  (income / expense ledger)
-- ------------------------------------------------------------------ --
create table if not exists public.transactions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  type        text not null check (type in ('income', 'expense')),
  amount      numeric not null check (amount > 0),
  description text,
  category    text not null,
  created_at  timestamptz not null default now()
);
create index if not exists transactions_user_idx
  on public.transactions (user_id, created_at desc);

-- ------------------------------------------------------------------ --
-- 4. GOALS
-- ------------------------------------------------------------------ --
create table if not exists public.goals (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users (id) on delete cascade,
  name           text not null,
  target_amount  numeric not null check (target_amount > 0),
  current_amount numeric not null default 0,
  category       text,
  description    text,
  created_at     timestamptz not null default now()
);
create index if not exists goals_user_idx on public.goals (user_id);

-- =====================================================================
--  ROW LEVEL SECURITY
--  Each user can only read/write their own rows.
-- =====================================================================
alter table public.profiles     enable row level security;
alter table public.budgets      enable row level security;
alter table public.transactions enable row level security;
alter table public.goals        enable row level security;

-- profiles: key column is `id` (== auth uid)
drop policy if exists "own profile" on public.profiles;
create policy "own profile" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

-- budgets
drop policy if exists "own budget" on public.budgets;
create policy "own budget" on public.budgets
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- transactions
drop policy if exists "own transactions" on public.transactions;
create policy "own transactions" on public.transactions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- goals
drop policy if exists "own goals" on public.goals;
create policy "own goals" on public.goals
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- =====================================================================
--  AUTO-CREATE A PROFILE WHEN A USER SIGNS UP
--  Reads the `full_name` passed in signUp(..., data: {'full_name': ...}).
-- =====================================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
