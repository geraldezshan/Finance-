-- =====================================================================
--  Finance+  ·  Username login migration
--  Run this AFTER supabase_schema.sql, in:  SQL Editor -> New query
--  Safe to run on an existing project.
-- =====================================================================

-- 1. Add a unique username column to profiles.
alter table public.profiles
  add column if not exists username text unique;

-- 2. Update the signup trigger so it also stores the username from metadata.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, username)
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'username'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- 3. Function: is a username free? (callable before login, by anyone)
create or replace function public.username_available(uname text)
returns boolean
language sql
security definer set search_path = public
as $$
  select not exists (
    select 1 from public.profiles
    where lower(username) = lower(uname)
  );
$$;
grant execute on function public.username_available(text) to anon, authenticated;

-- 4. Function: resolve a username to its account email so the app can log in.
--    SECURITY DEFINER lets it read auth.users; only the email is returned.
--    NOTE: this allows someone to test whether a username exists. That's an
--    acceptable trade-off for username login in most apps, but be aware of it.
create or replace function public.email_for_username(uname text)
returns text
language sql
security definer set search_path = public, auth
as $$
  select u.email
  from public.profiles p
  join auth.users u on u.id = p.id
  where lower(p.username) = lower(uname)
  limit 1;
$$;
grant execute on function public.email_for_username(text) to anon, authenticated;
