-- Rifà le eliminazioni degli account dopo il ripristino di un backup (vedi riapplica_eliminazioni.sh, che carica
-- pg_temp.registro da backups/account_eliminati.tsv). Si può rilanciare: un account già eliminato non cambia nulla.
-- I file nei bucket non sono nei backup del database: quelli degli account eliminati non tornano. Possono tornare
-- le righe di storage.objects che li descrivevano: il conteggio finale le segnala, si tolgono con l'API di Storage.

insert into public.account_eliminati (id, eliminato_il)
select id, eliminato_il from pg_temp.registro on conflict (id) do nothing;

select public.account_elimina_dati(r.id) from pg_temp.registro r;
delete from auth.users u using pg_temp.registro r where u.id = r.id;

select (select count(*) from pg_temp.registro) as account_nel_registro,
       (select count(*) from storage.objects o join pg_temp.registro r on (storage.foldername(o.name))[1] = r.id::text
         where o.bucket_id in ('galleria', 'zorba-foto')) as righe_storage_da_togliere;
