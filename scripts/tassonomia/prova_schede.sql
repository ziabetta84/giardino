-- Prove delle proposte delle schede della fase 4b (schede_proposte.sql), sulla copia locale. Errore al primo controllo
-- che fallisce. Numeri e casi valgono per specie del 16/10/2026, la fase 4a applicata e le fusioni del 20/10/2026.
do $$
declare
  n bigint;
  atteso record;
begin
  -- 15.678 righe non cultivar + 45 cultivar orfane + 12 cultivar con una descrizione propria + 35 madri dai rollback
  select count(*) into n from col.schede_proposte;
  if n <> 15770 then raise exception 'schede proposte: % (attese 15770)', n; end if;
  select count(*) into n from col.schede_proposte where num_nonnulls(taxon_id, cultivar_id) <> 1;
  if n > 0 then raise exception 'schede senza aggancio o con due agganci: %', n; end if;
  -- una sola mostrata per aggancio; mai una scheda non idonea (contenuto di specie su un taxon superiore)
  select count(*) into n from (select coalesce(taxon_id, cultivar_id) from col.schede_proposte where mostrata group by 1 having count(*) > 1) x;
  if n > 0 then raise exception 'agganci con più schede mostrate: %', n; end if;
  select count(*) into n from col.schede_proposte p join public.taxa t on t.id = p.taxon_id
   where p.mostrata and t.rango not in ('genus', 'species', 'subspecies', 'variety', 'form');
  if n > 0 then raise exception 'schede mostrate sopra il genere: %', n; end if;
  select count(*) into n from col.schede_proposte where mostrata and not idonea;
  if n > 0 then raise exception 'schede non idonee mostrate: %', n; end if;
  -- le piante dell'utente non decidono quale scheda si vede (scelta dell'utente del 20/10/2026), ma ognuna trova una
  -- scheda mostrata sul suo aggancio
  select count(*) into n from (select chiave from col.schede_proposte group by chiave
                                having bool_or(usata_piante) and not bool_or(mostrata)) x;
  if n > 0 then raise exception 'agganci delle piante dell''utente senza scheda mostrata: %', n; end if;
  -- descrizioni italiane con la coda inglese tagliata: lingua it
  select count(*) into n from col.schede_proposte p join public.specie s on s.id = p.vecchia_specie_id
   where s.descrizione ~ '.Da RHS(, descrizione del genere)? \(testo originale in inglese\): ' and p.lingua_descrizione <> 'it';
  if n > 0 then raise exception 'descrizioni con la coda inglese tagliata e lingua diversa da it: %', n; end if;
  -- una correzione a mano non lascia spazi o righe vuote ai bordi
  select count(*) into n from col.schede_proposte
   where (vecchio_slug = 'araucaria-bidwillii' and descrizione ~ '\s$') or (vecchio_slug = 'canarium-schweinfurtii' and descrizione !~ '^Albero');
  if n > 0 then raise exception 'correzioni a mano con spazi ai bordi: %', n; end if;
  -- casi (slug, nome del taxon o della cultivar, mostrata)
  for atteso in select * from (values
      ('pomodoro', 'Solanum lycopersicum', true),
      ('rosmarino', 'Salvia rosmarinus', true),           -- sinonimo verso un autonimo: sulla specie
      ('rosmarinus-officinalis', 'Salvia rosmarinus', false), -- madre dai rollback, doppione
      ('dracaena', 'Dracaena', true),                      -- genere accettato prima del genere sinonimo
      ('sansevieria', 'Dracaena', false),                  -- anche se la usa una pianta dell'utente
      ('hydrangea', 'Hydrangea', true),                    -- riga "Genere spp." sul genere
      ('brassia-rex', 'Rex', true),                        -- grex: sulla sua cultivar
      ('brachyglottis-dunedin-hybrids', 'Dunedin Group', true),
      ('physalis-alkekengi', 'Physalidinae', false)        -- specie finita su una sottotribù: non idonea
    ) v(slug, nome, mostrata) loop
    select count(*) into n from col.schede_proposte p
      left join public.taxa t on t.id = p.taxon_id left join public.cultivar c on c.id = p.cultivar_id
     where p.vecchio_slug = atteso.slug and coalesce(t.nome_scientifico, c.epiteto) = atteso.nome and p.mostrata = atteso.mostrata;
    if n <> 1 then raise exception 'caso %: atteso % (mostrata %)', atteso.slug, atteso.nome, atteso.mostrata; end if;
  end loop;
  -- nessuna fonte nominata nelle colonne leggibili dai client (descrizione, avvisi, esigenze); fanno eccezione la scala
  -- di rusticità USDA, un nome di persona e «fonte» nel senso di origine di un prodotto
  select count(*) into n from col.schede_proposte p
    cross join lateral (select regexp_replace(concat_ws(' ¦ ', p.descrizione, array_to_string(p.alert, ' ¦ '), p.esigenze::text),
             '(zone?|zona) di rusticità USDA|President of the RHS|la fonte (della|dell)|le fonti naturali', '', 'gi') as t) x
   where x.t ~ '\mRHS\M|\mPFAF\M|Plants For A Future|pfaf\.org|rhs\.org|Royal Horticultural|Wisley|\mKew\M|\mUSDA\M|Wikipedia|\mIPNI\M|\mPOWO\M|Missouri|iNaturalist|PlantNet|Pl@ntNet|Edicart|Demetra|De Vecchi|\mGiunti\M|theplantlist|\mReference:? |\mUniversity\M|J\. Food Safety'
      or x.t ~* '\m(la|le) fonti? (segnala|riporta|consiglia|sconsiglia|descrive|specifica|non)|dalla fonte|fonti consultate|testo originale|\mlibro\M|\menciclopedia\M|\[[0-9]{1,4}'
      or x.t ~* '\m(della|nella|alla|una sola) font[ei]\M|\(fonte\)|\m(nel|in the) database\M|nota aggiornata al|checklist 20[0-9]{2}|scheda in bozza';
  if n > 0 then raise exception 'schede con una fonte nominata nei testi leggibili: %', n; end if;
  select count(*) into n from col.schede_a_mano where not applicata;
  if n > 0 then raise exception 'correzioni a mano non applicate (testo non trovato): %', n; end if;
  -- avvisi, immagini, note
  select count(*) into n from col.schede_proposte, unnest(alert) a where a ~ '^Scheda in bozza|^Nome comune \(|^Rusticit. RHS';
  if n > 0 then raise exception 'avvisi di bozza, nomi comuni o rusticità RHS rimasti: %', n; end if;
  select count(*) into n from col.schede_proposte where immagine ? 'fonte' or immagine->>'url' ~ 'utm_source';
  if n > 0 then raise exception 'immagini con la chiave fonte o con utm: %', n; end if;
  select count(*) into n from col.schede_proposte where nota like '%nota tassonomica%';
  if n = 0 then raise exception 'nessuna nota tassonomica spostata nella nota interna'; end if;
  raise notice 'SCHEDE CORRETTE: % schede, % mostrate, % su cultivar, % non idonee',
    (select count(*) from col.schede_proposte), (select count(*) from col.schede_proposte where mostrata),
    (select count(*) from col.schede_proposte where cultivar_id is not null), (select count(*) from col.schede_proposte where not idonea);
end $$;
