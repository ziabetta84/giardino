-- Impronta di public.specie: dati e struttura, in sola lettura. Due database con gli stessi dati danno la stessa
-- uscita anche se le righe sono disposte diversamente su disco (si ordina per id): serve a dimostrare che la
-- compattazione (fase 1b) e il ripristino dal backup non cambiano nulla. Le impostazioni di formato sono fissate
-- perché l'uscita non dipenda dal server (fuso orario, formato delle date, schemi visibili). Le righe si leggono come
-- JSON e non come testo (s::text): il testo mette tra virgolette i campi che contengono "spazi" secondo la libreria del
-- sistema, e su macOS il byte 0xA0 (secondo byte di "à") conta come spazio, su Linux no: "Lillà" darebbe un'impronta
-- diversa tra Supabase e la copia locale sul Mac pur con gli stessi dati.
\pset tuples_only on
\pset format unaligned
begin transaction isolation level repeatable read read only;
set local timezone = 'UTC';
set local datestyle = 'ISO, YMD';
set local intervalstyle = 'postgres';
set local extra_float_digits = 1;
set local bytea_output = 'hex';
set local search_path = public, extensions;
set local statement_timeout = '10min';
select 'righe ' || count(*) from public.specie;
select 'dati ' || md5(string_agg(md5(to_jsonb(s)::text), '' order by s.id)) from public.specie s;
select 'indici ' || string_agg(pg_get_indexdef(i.indexrelid)
                               || case when i.indisvalid and i.indisready then '' else ' NON VALIDO' end,
                               ' | ' order by c.relname)
  from pg_index i join pg_class c on c.oid = i.indexrelid
 where i.indrelid = 'public.specie'::regclass;
select 'vincoli ' || string_agg(conname || ' ' || pg_get_constraintdef(oid), ' | ' order by conname)
  from pg_constraint where conrelid = 'public.specie'::regclass;
select 'trigger ' || coalesce(string_agg(pg_get_triggerdef(oid) || ' stato ' || tgenabled::text, ' | ' order by tgname), '')
  from pg_trigger where tgrelid = 'public.specie'::regclass and not tgisinternal;
select 'policy ' || coalesce(string_agg(polname || ' ' || polcmd::text || ' ' || polroles::regrole[]::text || ' '
                                        || coalesce(pg_get_expr(polqual, polrelid), '')
                                        || ' ' || coalesce(pg_get_expr(polwithcheck, polrelid), ''),
                                        ' | ' order by polname), '')
  from pg_policy where polrelid = 'public.specie'::regclass;
select 'rls ' || relrowsecurity || ' ' || relforcerowsecurity from pg_class where oid = 'public.specie'::regclass;
select 'permessi ' || coalesce(relacl::text, '') from pg_class where oid = 'public.specie'::regclass;
select 'opzioni ' || coalesce(reloptions::text, '') from pg_class where oid = 'public.specie'::regclass;
commit;
