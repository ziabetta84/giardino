-- Minimo di Supabase per provare la migration del concime usato (vedi prova_db.sh).
do $$ begin create role anon; exception when duplicate_object then null; end $$;
do $$ begin create role authenticated; exception when duplicate_object then null; end $$;
do $$ begin create role service_role bypassrls; exception when duplicate_object then null; end $$;
create schema auth;
create table auth.users (id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
grant usage on schema public to anon, authenticated, service_role;
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;

-- piante e concimi come nelle migration della fase 5 (solo le colonne che servono)
create table public.piante (
  id text primary key,
  owner_id uuid not null references auth.users default auth.uid(),
  ultima_cura jsonb not null default '{}'::jsonb
);
alter table public.piante enable row level security;
create policy "piante: proprietario" on public.piante for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create table public.concimi (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  nome text not null
);
alter table public.concimi enable row level security;
create policy "concimi: proprietario" on public.concimi for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
