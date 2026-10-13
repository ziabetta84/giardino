-- Prova della fase 1: applica migration e rollback in una transazione che viene sempre annullata.
begin;

create temp table _prima as
select (select count(*) from public.specie) as specie,
       (select count(*) from public.piante) as piante,
       (select count(*) from public.generi) as generi;
select owner_id::text as proprietario from public.piante limit 1 \gset
-- piante del proprietario: serve mentre si impersona authenticated, che non può leggere _prima
select set_config('prova.piante_proprietario', (select count(*)::text from public.piante where owner_id::text = :'proprietario'), false);

\i supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql

-- ===== Sezione taxa =====
savepoint s_taxa;
do $$
declare g uuid; s uuid;
begin
  assert (select relrowsecurity from pg_class where oid = 'public.taxa'::regclass), 'taxa: RLS non attiva';
  assert exists (select 1 from pg_policies where tablename = 'taxa' and policyname = 'taxa: lettura pubblica' and cmd = 'SELECT'),
    'taxa: manca la policy di lettura';

  -- inserimenti validi (come postgres)
  insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, autore, stato)
    values ('col', 'PROVA1', '26.9 XR', 'genus', 'Hedera', 'L.', 'accepted') returning id into g;
  insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, autore, stato, padre_id)
    values ('col', 'PROVA2', '26.9 XR', 'species', 'Hedera helix', 'L.', 'accepted', g) returning id into s;
  insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, stato, accettato_id)
    values ('col', 'PROVA3', '26.9 XR', 'species', 'Hedera canariensis', 'synonym', s);
  insert into public.taxa (origine, rango, nome_scientifico, stato, nota)
    values ('locale', 'genus', 'Fatshedera', 'accepted', 'notogenere non marcato in COL');

  -- ibrido calcolato
  insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, notho, stato)
    values ('col', 'PROVA4', '26.9 XR', 'species', 'Mentha × piperita', 'specific', 'accepted');
  assert (select ibrido from public.taxa where col_id = 'PROVA4'), 'ibrido non calcolato da notho';
  insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, stato)
    values ('col', 'PROVA5', '26.9 XR', 'genus', '× Chitalpa', 'accepted');
  assert (select ibrido from public.taxa where col_id = 'PROVA5'), 'ibrido non calcolato dal segno ×';
  assert not (select ibrido from public.taxa where col_id = 'PROVA2'), 'Hedera helix risulta ibrido';

  -- ranghi presenti in COL XR nella catena dei padri (Rosa canina, Pinus mugo) e nei sinonimi (Rosa canina)
  insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, stato)
    values ('col', 'PROVA6', '26.9 XR', 'domain', 'Eukaryota', 'accepted'),
           ('col', 'PROVA7', '26.9 XR', 'subkingdom', 'Pteridobiotina', 'accepted'),
           ('col', 'PROVA8', '26.9 XR', 'subclass', 'Pinidae', 'accepted');
  insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, stato, accettato_id)
    values ('col', 'PROVA9', '26.9 XR', 'subvariety', 'Rosa canina subvar. aciphylla', 'synonym', s),
           ('col', 'PROVA10', '26.9 XR', 'proles', 'Rosa communis prol. canina', 'synonym', s),
           ('col', 'PROVA11', '26.9 XR', 'lusus', 'Rosa spuria lusus benacensis', 'synonym', s);

  -- vincoli che devono rifiutare
  begin
    insert into public.taxa (origine, rango, nome_scientifico, stato) values ('col', 'genus', 'Senza id', 'accepted');
    raise exception 'ATTESO ERRORE: taxon col senza col_id';
  exception when check_violation then null; end;
  begin
    insert into public.taxa (origine, col_id, rango, nome_scientifico, stato) values ('locale', 'X1', 'genus', 'Locale con id', 'accepted');
    raise exception 'ATTESO ERRORE: taxon locale con col_id';
  exception when check_violation then null; end;
  begin
    insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'cultivar', 'Hedera helix ''Goldchild''', 'accepted');
    raise exception 'ATTESO ERRORE: rango cultivar in taxa';
  exception when check_violation then null; end;
  begin
    insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'species', 'Stato inventato', 'dubbio');
    raise exception 'ATTESO ERRORE: stato fuori vocabolario';
  exception when check_violation then null; end;
  begin
    insert into public.taxa (origine, rango, nome_scientifico, stato, accettato_id) values ('locale', 'species', 'Accettato con rinvio', 'accepted', s);
    raise exception 'ATTESO ERRORE: accettato con accettato_id';
  exception when check_violation then null; end;
  begin
    insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, stato) values ('col', 'PROVA1', '26.9 XR', 'genus', 'Doppione', 'accepted');
    raise exception 'ATTESO ERRORE: col_id duplicato';
  exception when unique_violation then null; end;
  begin
    insert into public.taxa (origine, rango, nome_scientifico, stato, padre_id) values ('locale', 'species', 'Padre inesistente', 'accepted', gen_random_uuid());
    set constraints taxa_padre_fk immediate;
    raise exception 'ATTESO ERRORE: padre inesistente';
  exception when foreign_key_violation then null; end;
end $$;

-- permessi effettivi, colonna per colonna
do $$
begin
  assert has_column_privilege('anon', 'public.taxa', 'nome_scientifico', 'SELECT'), 'anon non legge taxa.nome_scientifico';
  assert has_column_privilege('anon', 'public.taxa', 'padre_id', 'SELECT'), 'anon non legge taxa.padre_id';
  assert not has_column_privilege('anon', 'public.taxa', 'col_id', 'SELECT'), 'anon legge taxa.col_id';
  assert not has_column_privilege('anon', 'public.taxa', 'nota', 'SELECT'), 'anon legge taxa.nota';
  assert not has_column_privilege('authenticated', 'public.taxa', 'origine', 'SELECT'), 'authenticated legge taxa.origine';
  assert not has_table_privilege('anon', 'public.taxa', 'INSERT'), 'anon può inserire in taxa';
  assert not has_table_privilege('authenticated', 'public.taxa', 'UPDATE'), 'authenticated può aggiornare taxa';
  assert not has_table_privilege('authenticated', 'public.taxa', 'DELETE'), 'authenticated può cancellare da taxa';
  assert has_table_privilege('service_role', 'public.taxa', 'INSERT'), 'service_role non può inserire in taxa';
end $$;

-- comportamento reale impersonando anon
set local role anon;
do $$
begin
  assert (select count(*) from (select id, nome_scientifico from public.taxa) t) >= 5, 'anon non vede le righe di taxa';
  begin
    perform col_id from public.taxa limit 1;
    raise exception 'ATTESO ERRORE: anon legge col_id';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'genus', 'Da anon', 'accepted');
    raise exception 'ATTESO ERRORE: anon inserisce';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback to savepoint s_taxa;

-- ===== Sezione nomi_comuni e cultivar =====
savepoint s_nomi_cultivar;
do $$
declare t uuid; t2 uuid;
begin
  insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'species', 'Hedera helix', 'accepted') returning id into t;
  insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'genus', 'Hedera', 'accepted') returning id into t2;

  insert into public.nomi_comuni (taxon_id, lingua, nome, preferito, fonti) values (t, 'it', 'Edera comune', true, array['iNaturalist']);
  insert into public.nomi_comuni (taxon_id, lingua, nome, fonti) values (t, 'it', 'Ellera', array['PlantNet', 'Wikidata']);
  insert into public.nomi_comuni (taxon_id, lingua, nome, preferito, fonti) values (t2, 'it', 'Edera', true, array['curatore']);
  begin
    insert into public.nomi_comuni (taxon_id, lingua, nome, preferito, fonti) values (t, 'it', 'Abbracciabosco', true, array['PlantNet']);
    raise exception 'ATTESO ERRORE: due preferiti per lo stesso taxon e lingua';
  exception when unique_violation then null; end;
  begin
    insert into public.nomi_comuni (taxon_id, lingua, nome, fonti) values (t, 'it', 'Ellera', array['EPPO']);
    raise exception 'ATTESO ERRORE: nome ripetuto per lo stesso taxon e lingua';
  exception when unique_violation then null; end;
  begin
    insert into public.nomi_comuni (taxon_id, lingua, nome, fonti) values (t, 'ita', 'Edera', array['COL']);
    raise exception 'ATTESO ERRORE: lingua a tre lettere';
  exception when check_violation then null; end;
  begin
    insert into public.nomi_comuni (taxon_id, lingua, nome, fonti) values (t, 'it', 'Senza fonte', '{}');
    raise exception 'ATTESO ERRORE: nome senza fonti';
  exception when check_violation then null; end;

  insert into public.cultivar (slug, taxon_id, epiteto, fonti) values ('prova-hedera-helix-goldchild', t, 'Goldchild', array['RHS (rhs.org.uk)']);
  insert into public.cultivar (slug, taxon_id, epiteto, categoria, fonti) values ('prova-hedera-gruppo', t2, 'Prova', 'gruppo', array['RHS (rhs.org.uk)']);
  begin
    insert into public.cultivar (slug, taxon_id, epiteto, fonti) values ('prova-apici', t, '''Goldchild''', array['RHS (rhs.org.uk)']);
    raise exception 'ATTESO ERRORE: epiteto con apici';
  exception when check_violation then null; end;
  begin
    insert into public.cultivar (slug, taxon_id, epiteto, fonti) values ('prova-hedera-helix-goldchild', t, 'Altro', array['RHS (rhs.org.uk)']);
    raise exception 'ATTESO ERRORE: slug duplicato';
  exception when unique_violation then null; end;
  begin
    insert into public.cultivar (slug, taxon_id, epiteto, categoria, fonti) values ('prova-cat', t, 'X', 'varietà', array['RHS (rhs.org.uk)']);
    raise exception 'ATTESO ERRORE: categoria fuori elenco';
  exception when check_violation then null; end;
  begin
    delete from public.taxa where id = t;
    raise exception 'ATTESO ERRORE: cancellato un taxon con nomi e cultivar';
  exception when foreign_key_violation then null; end;

  assert has_column_privilege('anon', 'public.nomi_comuni', 'nome', 'SELECT'), 'anon non legge nomi_comuni.nome';
  assert not has_column_privilege('anon', 'public.nomi_comuni', 'fonti', 'SELECT'), 'anon legge nomi_comuni.fonti';
  assert not has_column_privilege('anon', 'public.nomi_comuni', 'nota', 'SELECT'), 'anon legge nomi_comuni.nota';
  assert has_column_privilege('anon', 'public.cultivar', 'epiteto', 'SELECT'), 'anon non legge cultivar.epiteto';
  assert not has_column_privilege('anon', 'public.cultivar', 'fonti', 'SELECT'), 'anon legge cultivar.fonti';
  assert not has_column_privilege('anon', 'public.cultivar', 'vecchia_specie_id', 'SELECT'), 'anon legge cultivar.vecchia_specie_id';
  assert not has_table_privilege('authenticated', 'public.nomi_comuni', 'INSERT'), 'authenticated scrive nomi_comuni';
  assert not has_table_privilege('authenticated', 'public.cultivar', 'INSERT'), 'authenticated scrive cultivar';
  assert (select relrowsecurity from pg_class where oid = 'public.nomi_comuni'::regclass), 'nomi_comuni: RLS non attiva';
  assert (select relrowsecurity from pg_class where oid = 'public.cultivar'::regclass), 'cultivar: RLS non attiva';
end $$;

set local role anon;
do $$
begin
  assert (select count(*) from (select nome, preferito from public.nomi_comuni) n) = 3, 'anon non vede i nomi comuni';
  assert (select count(*) from (select epiteto from public.cultivar) c) = 2, 'anon non vede le cultivar';
  begin
    perform fonti from public.nomi_comuni limit 1;
    raise exception 'ATTESO ERRORE: anon legge le fonti dei nomi';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback to savepoint s_nomi_cultivar;

-- FINE SEZIONI

\i scripts/tassonomia/rollback_fase1.sql

do $$
begin
  assert to_regclass('public.taxa') is null, 'rollback: taxa esiste ancora';
  assert (select specie from _prima) = (select count(*) from public.specie), 'specie è cambiata';
  assert (select piante from _prima) = (select count(*) from public.piante), 'piante è cambiata';
  assert (select generi from _prima) = (select count(*) from public.generi), 'generi è cambiata';
end $$;

do $$
begin
  assert to_regclass('public.nomi_comuni') is null, 'rollback: nomi_comuni esiste ancora';
  assert to_regclass('public.cultivar') is null, 'rollback: cultivar esiste ancora';
end $$;

select 'PROVA PRINCIPALE OK' as esito;
rollback;
