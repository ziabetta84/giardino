-- Prove dei nomi comuni proposti della fase 4c (nomi_proposte.sql), sulla copia locale. Errore al primo controllo che
-- fallisce. Numeri e casi valgono per specie del 16/10/2026, COL26.9 XR, le fasi 2-4b applicate e le decisioni
-- dell'utente del 20/10/2026 (dati/fase4_nomi_esclusi.tsv, fase4_nomi_corretti.tsv, fase4_nomi_preferiti.tsv).
do $$
declare
  n bigint;
  c record;
begin
  -- righe per lingua e origine, preferiti
  for c in select * from (values
      ('tutte', (select count(*) from col.nomi_proposte), 18595::bigint),
      ('italiane dei nostri dati', (select count(*) from col.nomi_proposte where lingua = 'it' and origine = 'nostri'), 9600),
      ('italiane solo di COL', (select count(*) from col.nomi_proposte where lingua = 'it' and origine = 'col'), 953),
      ('inglesi', (select count(*) from col.nomi_proposte where lingua = 'en'), 8042),
      ('preferiti', (select count(*) from col.nomi_proposte where preferito), 2777)
    ) v(voce, trovate, attese) loop
    if c.trovate <> c.attese then raise exception 'nomi proposti, %: % invece di %', c.voce, c.trovate, c.attese; end if;
  end loop;
  -- le decisioni dell'utente sono tutte applicate
  select (select count(*) from col.nomi_esclusi where not applicata) + (select count(*) from col.nomi_corretti where not applicata)
       + (select count(*) from col.nomi_scelte where not applicata) into n;
  if n > 0 then raise exception 'decisioni dell''utente non applicate (testo o taxon non trovato): %', n; end if;
  select count(*) into n from col.nomi_esclusi;
  if n <> 913 then raise exception 'esclusioni: % invece di 913', n; end if;
  -- un nome tolto non c'è più su quella pianta, nemmeno da COL
  select count(*) into n from col.nomi_esclusi e
    join col.nomi_provenienza v on v.slug = e.vecchio_slug and v.nome = e.nome
    join public.mappa_specie m on m.vecchia_specie_id = v.id and m.taxon_id is not null
    join public.taxa t on t.id = m.taxon_id
    join col.nomi_proposte p on p.k = col.chiave_nome(e.nome) and p.lingua = 'it'
   where p.taxon_id = coalesce(t.accettato_id, t.id);
  if n > 0 then raise exception 'nomi tolti dall''utente ancora presenti sulla loro pianta: %', n; end if;
  -- regole: un nome una volta sola per taxon e lingua; un preferito al più; mai preferiti inglesi o solo di COL, salvo le
  -- scelte dell'utente; nessun nome uguale al nome scientifico della riga, salvo i nomi dei generi scelti (Calendula)
  select count(*) into n from (select taxon_id, lingua, k from col.nomi_proposte group by 1, 2, 3 having count(*) > 1) x;
  if n > 0 then raise exception 'nomi ripetuti sullo stesso taxon: %', n; end if;
  select count(*) into n from (select taxon_id, lingua from col.nomi_proposte where preferito group by 1, 2 having count(*) > 1) x;
  if n > 0 then raise exception 'taxon con più preferiti: %', n; end if;
  select count(*) into n from col.nomi_proposte p
   where p.preferito and (p.lingua <> 'it' or (p.origine = 'col' and not exists (
           select 1 from col.nomi_scelte s join public.taxa t on t.nome_scientifico = s.taxon where t.id = p.taxon_id and col.chiave_nome(s.nome) = p.k)));
  if n > 0 then raise exception 'preferiti inglesi o di COL non scelti dall''utente: %', n; end if;
  select count(*) into n from col.nomi_proposte p join public.taxa t on t.id = p.taxon_id
   where p.lingua = 'it' and p.k = lower(t.nome_scientifico) and not ('curatore' = any(p.fonti));
  if n > 0 then raise exception 'nomi uguali al nome scientifico del taxon: %', n; end if;
  select count(*) into n from col.nomi_proposte where nome <> col.pulisci_nome(nome) or nome = '' or cardinality(fonti) = 0;
  if n > 0 then raise exception 'nomi vuoti, con spazi da pulire o senza fonti: %', n; end if;
  select count(*) into n from col.nomi_proposte where k in ('dio cane', 'inter merda', 'pino daniele', 'ciruzzo', 'fiore della patagonia');
  if n > 0 then raise exception 'nomi volgari o spazzatura rimasti: %', n; end if;
  -- casi (taxon, nome, preferito)
  for c in select * from (values
      ('Salvia rosmarinus', 'Rosmarino', true),          -- sinonimo verso un autonimo: sulla specie
      ('Cynara cardunculus var. hortensis', 'Carciofo', true), -- vero infraspecifico: resta sulla varietà
      ('Capsicum annuum', 'Peperone', true),            -- scelta dell'utente del 16/10
      ('Capsicum annuum', 'Peperoncino', false),
      ('Brassica oleracea', 'Cavolo', true),
      ('Musa acuminata', 'Banano', true),               -- revisione del 20/10: Platano è Platanus
      ('Musa acuminata', 'Platano', false),
      ('Platanus', 'Platano', true),
      ('Lobularia maritima', 'Alisso marittimo', true), -- nome di COL scelto dall'utente
      ('Lobularia maritima', 'Alisso', false),
      ('Phalaenopsis', 'Falenopside', true),
      ('Phalaenopsis', 'Orchidea', false),
      ('Calendula', 'Calendula', true),                 -- deroga dell'utente
      ('Calendula', 'Calendola', false),                -- nome di COL, mai preferito da solo
      ('Howea forsteriana', 'Kenzia', true),
      ('Howea forsteriana', 'Kentia', false),           -- corretto: senza la parentesi
      ('Prunus', 'Mandorlo', false),                    -- riga di specie salita al genere: mai preferito
      ('Acacia', 'Mimosa', false)                       -- riga «Genere spp.» con più destinazioni: al genere, mai preferito
    ) v(taxon, nome, preferito) loop
    select count(*) into n from col.nomi_proposte p join public.taxa t on t.id = p.taxon_id
     where t.nome_scientifico = c.taxon and p.lingua = 'it' and p.nome = c.nome and p.preferito = c.preferito;
    if n <> 1 then raise exception 'caso %: atteso «%» (preferito %)', c.taxon, c.nome, c.preferito; end if;
  end loop;
  select count(*) into n from col.nomi_proposte p join public.taxa t on t.id = p.taxon_id
   where t.nome_scientifico in ('Zamioculcas zamiifolia', 'Euphorbia trigona', 'Lampranthus') and p.preferito;
  if n > 0 then raise exception 'preferiti dove l''utente ha scelto nessun preferito: %', n; end if;
  raise notice 'NOMI CORRETTI: % nomi (% italiani, % inglesi), % preferiti',
    (select count(*) from col.nomi_proposte), (select count(*) from col.nomi_proposte where lingua = 'it'),
    (select count(*) from col.nomi_proposte where lingua = 'en'), (select count(*) from col.nomi_proposte where preferito);
end $$;
