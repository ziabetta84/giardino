-- Minimo di Supabase per provare i controlli sul proprietario (vedi prova_db.sh).
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

-- tabelle come nelle migration della fase 5 (solo le colonne che servono)
create table public.zone (id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users default auth.uid(), nome text not null);
create table public.sottozone (id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users default auth.uid(),
  zona_id uuid not null references public.zone(id) on delete cascade, nome text not null);
create table public.piante (id text primary key, owner_id uuid not null references auth.users default auth.uid(),
  zona_id uuid not null references public.zone(id) on delete restrict,
  sottozona_id uuid references public.sottozone(id) on delete set null, note text);
create table public.progetti (id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users default auth.uid(), nome text not null);
create table public.tappe (id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users default auth.uid(),
  progetto_id uuid not null references public.progetti(id) on delete cascade, nome text not null);
do $$ declare t text; begin
  foreach t in array array['zone','sottozone','piante','progetti','tappe'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "%s: proprietario" on public.%I for all using (owner_id = auth.uid()) with check (owner_id = auth.uid())', t, t);
  end loop;
end $$;
