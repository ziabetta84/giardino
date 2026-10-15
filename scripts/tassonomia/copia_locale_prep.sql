-- Oggetti di Supabase richiesti dalle tabelle ripristinate nella copia locale (copia_locale.sh):
-- ruoli dei permessi, schema extensions con pg_trgm (indici trigram) e moddatetime (trigger di data).
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create schema extensions;
create extension pg_trgm schema extensions;
create extension moddatetime schema extensions;
alter database giardino set search_path = "$user", public, extensions;
