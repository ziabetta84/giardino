-- Minimo di Supabase per provare la migration dell'eliminazione dell'account fuori dal reale (vedi prova_db.sh):
-- le tabelle del giardino con le sole colonne che servono e le chiavi esterne come sul reale (30/10/2026).
do $$ begin create role anon; exception when duplicate_object then null; end $$;
do $$ begin create role authenticated; exception when duplicate_object then null; end $$;
do $$ begin create role service_role bypassrls; exception when duplicate_object then null; end $$;
create schema auth;
create table auth.users (id uuid primary key);
create schema storage;
create table storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text, name text);
create function storage.foldername(name text) returns text[] language sql immutable as $$
  select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1]
$$;
grant usage on schema auth, storage, public to anon, authenticated, service_role;
grant select on storage.objects to service_role;
alter default privileges in schema public grant all on tables to service_role;

create table public.zone (id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users);
create table public.sottozone (id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users,
  zona_id uuid references public.zone on delete cascade);
create table public.piante (id text primary key, owner_id uuid not null references auth.users,
  zona_id uuid references public.zone on delete restrict, sottozona_id uuid references public.sottozone on delete set null);
create table public.piante_vecchie_specie (pianta_id text primary key references public.piante on delete cascade);
create table public.progetti (id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users);
create table public.tappe (id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users,
  progetto_id uuid references public.progetti on delete cascade);
create table public.concimi (id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users);
create table public.settings (owner_id uuid primary key references auth.users);
create table public.programmi_irrigazione (id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users,
  zona_id uuid references public.zone on delete cascade, pianta_id text references public.piante on delete cascade,
  sottozona_id uuid references public.sottozone on delete cascade);
create table public.foto (id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users on delete cascade,
  pianta_id text references public.piante on delete cascade);
create table public.zorba_fili (id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users on delete cascade,
  progetto_id uuid references public.progetti on delete set null);
