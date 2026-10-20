-- Fase 4b: controllo di public.schede dopo il caricamento, con l'inventario della specifica ("Migrazione dei
-- contenuti", Verifica): per campo e per fonte le schede hanno gli stessi numeri delle righe di specie da cui vengono.
-- Le differenze ammesse sono solo quelle decise: testi puliti (descrizione, avvisi, esigenze, immagine), la nota
-- «Correzione…» spostata da fonti a nota. Sola lettura.
-- Variabili psql: righe_schede (righe dei lotti) e righe_mostrate (schede mostrate attese).
-- Uso: psql URL -X -q -v ON_ERROR_STOP=1 -v righe_schede=N -v righe_mostrate=M -f scripts/tassonomia/verifica_fase4b.sql
select set_config('fase4b.righe', :'righe_schede', false), set_config('fase4b.mostrate', :'righe_mostrate', false) \g /dev/null
do $$
declare
  attese bigint := current_setting('fase4b.righe')::bigint;
  mostrate bigint := current_setting('fase4b.mostrate')::bigint;
  n bigint;
  campo text;
begin
  select count(*) into n from public.schede;
  if n <> attese then raise exception 'schede: % righe, attese %', n, attese; end if;
  select count(*) into n from public.schede where mostrata;
  if n <> mostrate then raise exception 'schede mostrate: %, attese %', n, mostrate; end if;
  -- ogni riga madre di specie e ogni cultivar con una descrizione ha la sua scheda; le altre schede vengono dai rollback
  select count(*) into n from public.specie s
   where (s.specie_padre_id is null or s.descrizione is not null) and not exists (select 1 from public.schede h where h.vecchia_specie_id = s.id);
  if n > 0 then raise exception 'righe di specie con contenuto senza scheda: %', n; end if;
  select count(*) into n from public.schede h
   where not exists (select 1 from public.specie s where s.id = h.vecchia_specie_id)
     and not exists (select 1 from public.mappa_specie m where m.vecchia_specie_id = h.vecchia_specie_id and m.origine = 'rollback');
  if n > 0 then raise exception 'schede che non vengono né da specie né dai rollback: %', n; end if;
  -- inventario per campo: stessi campi pieni
  foreach campo in array array['descrizione', 'descrizione_originale', 'lingua_descrizione', 'esigenze', 'manutenzione', 'ciclo_colturale',
                               'ciclo_vitale', 'vaso', 'alert', 'immagine', 'verificata_il', 'verificata_da'] loop
    execute format('select (select count(*) from public.schede h join public.specie s on s.id = h.vecchia_specie_id where h.%1$I is not null)
                         - (select count(*) from public.specie s where (s.specie_padre_id is null or s.descrizione is not null) and s.%1$I is not null)', campo)
      into n;
    if n <> 0 then raise exception 'inventario: il campo % ha % schede piene in più (o in meno se negativo) delle righe di specie', campo, n; end if;
  end loop;
  -- campi copiati così come sono: valori identici (decisione 7 della fase 4)
  select count(*) into n from public.schede h join public.specie s on s.id = h.vecchia_specie_id
   where h.descrizione_originale is distinct from s.descrizione_originale or h.manutenzione is distinct from s.manutenzione
      or h.ciclo_colturale is distinct from s.ciclo_colturale or h.vaso is distinct from s.vaso or h.ciclo_vitale is distinct from s.ciclo_vitale
      or h.stato_verifica is distinct from s.stato_verifica or h.verificata_il is distinct from s.verificata_il
      or h.verificata_da is distinct from s.verificata_da;
  if n > 0 then raise exception 'schede con un campo copiato diverso dalla riga di specie: %', n; end if;
  -- inventario per fonte: le stesse fonti, tolta solo la nota «Correzione…» (spostata in nota)
  select count(*) into n from public.schede h join public.specie s on s.id = h.vecchia_specie_id
   where h.fonti is distinct from array(select f from unnest(s.fonti) with ordinality u(f, o) where f !~ '^Correzione' order by o);
  if n > 0 then raise exception 'schede con fonti diverse dalla riga di specie: %', n; end if;
  -- una sola mostrata per aggancio, mai sopra il genere
  select count(*) into n from public.schede h join public.taxa t on t.id = h.taxon_id
   where h.mostrata and t.rango not in ('genus', 'species', 'subspecies', 'variety', 'form');
  if n > 0 then raise exception 'schede mostrate sopra il genere: %', n; end if;
  -- nessuna fonte nominata nei testi leggibili dai client (eccezioni: scala USDA, un nome di persona, «fonte» di un prodotto)
  select count(*) into n from public.schede h
    cross join lateral (select regexp_replace(concat_ws(' ¦ ', h.descrizione, array_to_string(h.alert, ' ¦ '), h.esigenze::text),
             '(zone?|zona) di rusticità USDA|President of the RHS|la fonte (della|dell)|le fonti naturali', '', 'gi') as t) x
   where x.t ~ '\mRHS\M|\mPFAF\M|Plants For A Future|pfaf\.org|rhs\.org|Royal Horticultural|Wisley|\mKew\M|\mUSDA\M|Wikipedia|\mIPNI\M|\mPOWO\M|Missouri|iNaturalist|PlantNet|Pl@ntNet|Edicart|Demetra|De Vecchi|\mGiunti\M'
      or x.t ~* '\m(la|le) fonti? (segnala|riporta|consiglia|sconsiglia|descrive|specifica|non)|dalla fonte|fonti consultate|testo originale|\mlibro\M|\menciclopedia\M|\[[0-9]{1,4}';
  if n > 0 then raise exception 'schede con una fonte nominata nei testi leggibili: %', n; end if;
  -- indici e permessi
  select count(*) into n from unnest(array['schede_taxon_id_idx', 'schede_cultivar_id_idx', 'schede_mostrata_taxon_idx', 'schede_mostrata_cultivar_idx']) i
   where to_regclass('public.' || i) is null;
  if n > 0 then raise exception 'indici di schede mancanti: %', n; end if;
  if has_column_privilege('anon', 'public.schede', 'nota', 'select') or has_column_privilege('anon', 'public.schede', 'fonti', 'select')
     or has_column_privilege('anon', 'public.schede', 'descrizione_originale', 'select') or has_column_privilege('anon', 'public.schede', 'verificata_da', 'select')
     or not has_column_privilege('anon', 'public.schede', 'descrizione', 'select') then
    raise exception 'permessi di colonna di schede inattesi';
  end if;
  raise notice 'schede: % (mostrate %, su cultivar %, con nota %); inventario per campo e per fonte uguale a specie', attese, mostrate,
    (select count(*) from public.schede where cultivar_id is not null), (select count(*) from public.schede where nota is not null);
end $$;
