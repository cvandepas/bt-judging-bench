-- Raider Judging Bench · Supabase schema
-- Run this once in your Supabase project: Dashboard → SQL Editor → New query → paste → Run.
-- Before running, replace advisor@example.com (bottom of file) with the Judge Advisor's email.
-- Safe to re-run: it creates what is missing and replaces the access rules.

-- ---------- Tables ----------
create table if not exists public.panel_members (
  email     text primary key check (email = lower(email)),
  role      text not null default 'judge' check (role in ('advisor','judge')),
  name      text,
  initials  text,
  active    boolean not null default true,
  added_at  timestamptz not null default now()
);

create table if not exists public.teams (
  id         text primary key,
  number     text not null,
  name       text not null default '',
  org        text not null default '',
  notebook   boolean not null default true,
  example    boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.perf (
  team_id text primary key references public.teams(id) on delete cascade,
  qual    integer,
  skills  integer,
  auton   boolean not null default false
);

-- One scoresheet per judge. doc = {initials, joinedAt, updatedAt, example, teams:{teamId:{nb,iv,bt,flags,notes}}}
create table if not exists public.sheets (
  judge_email text primary key check (judge_email = lower(judge_email)),
  doc         jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

-- Event settings (key 'config'), award decisions ('awards'), panel settings ('panel')
create table if not exists public.meta (
  key   text primary key,
  value jsonb not null default '{}'::jsonb
);

-- ---------- Who is signed in ----------
create or replace function public.current_email() returns text
  language sql stable set search_path = public
  as $$ select lower(coalesce(auth.jwt() ->> 'email', '')) $$;

create or replace function public.is_member() returns boolean
  language sql stable security definer set search_path = public
  as $$ select exists (select 1 from public.panel_members where email = public.current_email() and active) $$;

create or replace function public.is_advisor() returns boolean
  language sql stable security definer set search_path = public
  as $$ select exists (select 1 from public.panel_members where email = public.current_email() and active and role = 'advisor') $$;

-- Lets a signed-in person learn whether they are on the panel (returns no row if not).
create or replace function public.my_membership()
  returns table (email text, role text, name text, initials text, active boolean)
  language sql stable security definer set search_path = public
  as $$ select m.email, m.role, m.name, m.initials, m.active from public.panel_members m where m.email = public.current_email() $$;

revoke all on function public.is_member(), public.is_advisor(), public.my_membership() from public, anon;
grant execute on function public.current_email(), public.is_member(), public.is_advisor(), public.my_membership() to authenticated;

-- ---------- Access rules ----------
alter table public.panel_members enable row level security;
alter table public.teams         enable row level security;
alter table public.perf          enable row level security;
alter table public.sheets        enable row level security;
alter table public.meta          enable row level security;

revoke all on public.panel_members, public.teams, public.perf, public.sheets, public.meta from anon;
grant select, insert, update, delete on public.panel_members, public.teams, public.perf, public.sheets, public.meta to authenticated;

do $$
declare t text;
begin
  foreach t in array array['panel_members','teams','perf','sheets','meta'] loop
    execute format('drop policy if exists "members read" on public.%I', t);
    execute format('drop policy if exists "advisor writes" on public.%I', t);
    -- Everyone on the panel reads everything (judges deliberate together).
    execute format('create policy "members read" on public.%I for select to authenticated using (public.is_member())', t);
    -- Only the Judge Advisor changes event data, the judge list, and can tidy any sheet.
    execute format('create policy "advisor writes" on public.%I for all to authenticated using (public.is_advisor()) with check (public.is_advisor())', t);
  end loop;
end $$;

-- Each active judge creates and edits only their own scoresheet.
drop policy if exists "judge inserts own sheet" on public.sheets;
drop policy if exists "judge updates own sheet" on public.sheets;
create policy "judge inserts own sheet" on public.sheets for insert to authenticated
  with check (public.is_member() and judge_email = public.current_email());
create policy "judge updates own sheet" on public.sheets for update to authenticated
  using (public.is_member() and judge_email = public.current_email())
  with check (public.is_member() and judge_email = public.current_email());

-- ---------- Live updates ----------
do $$
declare t text;
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    foreach t in array array['panel_members','teams','perf','sheets','meta'] loop
      if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
        execute format('alter publication supabase_realtime add table public.%I', t);
      end if;
    end loop;
  end if;
end $$;

-- ---------- First Judge Advisor ----------
-- Replace with the Judge Advisor's email (lowercase). Add judges afterwards from the app's Setup tab.
insert into public.panel_members (email, role, name)
values (lower('advisor@example.com'), 'advisor', 'Judge Advisor')
on conflict (email) do update set role = 'advisor', active = true;
