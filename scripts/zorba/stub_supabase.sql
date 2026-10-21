-- Minimo di Supabase per provare la migration di Zorba fuori dal reale. I ruoli anon/authenticated/service_role
-- esistono già nel server locale (sono globali al cluster).
create schema auth;
create table auth.users (id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;

create schema storage;
create table storage.buckets (id text primary key, name text, public boolean, file_size_limit bigint, allowed_mime_types text[]);
create table storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text, name text);
alter table storage.objects enable row level security;
create function storage.foldername(name text) returns text[] language sql immutable as $$
  select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1]
$$;
grant usage on schema storage to anon, authenticated, service_role;
grant select on storage.objects to anon, authenticated, service_role;

-- Privilegi predefiniti come su Supabase: tutto ad anon/authenticated/service_role sulle nuove tabelle e funzioni
grant usage on schema public to anon, authenticated, service_role;
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;

-- progetti e tappe come nella migration 20260830040000_fase5_completamento_schema.sql
create table public.progetti (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  titolo text not null, descrizione text, zona text,
  stato text not null default 'aperto' check (stato in ('aperto','in_corso','completato','fallito','cancellato')),
  creato date not null default current_date
);
create table public.tappe (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  progetto_id uuid not null references public.progetti(id) on delete cascade,
  data date not null, descrizione text not null,
  esito text not null default 'atteso' check (esito in ('atteso','riuscito','fallito','saltato'))
);
alter table public.progetti enable row level security;
alter table public.tappe enable row level security;
create policy "progetti: proprietario" on public.progetti for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "tappe: proprietario" on public.tappe for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
