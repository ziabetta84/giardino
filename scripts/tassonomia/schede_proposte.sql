-- Fase 4b: le schede da caricare (col.schede_proposte), con i valori definitivi, sulla copia locale (fase 4a applicata,
-- stesse chiavi del reale). Regole: specifica, "Decisioni per la fase 4", punti 1-14.
-- - righe: le 15.723 righe madri di specie (15.678 non cultivar e 45 cultivar orfane), le 12 cultivar con una
--   descrizione propria e le 35 madri cancellate, lette dai file di rollback (schede_rollback_madri.py);
-- - aggancio (punto 1): grex, Gruppo Dunedin e righe cultivar sulla loro cultivar (per una cultivar fusa nella fase 4a,
--   quella in cui è stata fusa); le altre sull'accettato del nome trovato in mappa_specie, e per un sinonimo di specie
--   che porta a un autonimo sulla specie;
-- - idonea (punto 2): una scheda di specie finita su un genere o più in alto non è idonea: non è mai mostrata. Sono
--   idonee sul genere le righe con un nome di genere ("Genere spp." comprese, punto 6), i contenuti di gruppo del
--   genere e agapanthus (descrizione del genere sotto un nome di specie);
-- - mostrata (punto 3): per ogni aggancio la prima per idonea, verificata, usata dalle piante dell'utente, genere
--   accettato prima di un genere sinonimo, completezza sui valori utili (i jsonb tutti a null non contano), qualità
--   della descrizione, nome accettato esatto, lunghezza della descrizione, slug;
-- - testi (punti 9-14): funzioni di schede_testi.sql, poi le correzioni a mano di dati/fase4_schede_a_mano.tsv; le
--   note di lavorazione e la nota «Correzione…» delle fonti vanno nella colonna interna nota. I jsonb di coltivazione
--   si copiano così come sono (punto 7).
-- Standard input: piante_specie.tsv (slug, nome_scientifico, cultivar, piante: le righe di specie usate dalle piante
-- dell'utente). Lanciare dalla radice del repository, dopo schede_testi.sql.
set statement_timeout = 0;
do $$ begin
  if to_regproc('col.alert_pulito') is null then raise exception 'manca schede_testi.sql'; end if;
end $$;
drop table if exists col.schede_proposte, col.schede_a_mano, col.schede_piante, col.schede_rollback;
create table col.schede_piante (slug text primary key, nome_scientifico text, cultivar boolean, piante int);
\copy col.schede_piante from pstdin with (format csv, delimiter E'\t', header)
create table col.schede_a_mano (vecchio_slug text not null, campo text not null check (campo in ('descrizione', 'alert')),
                                da text not null check (da <> ''), a text not null, applicata boolean not null default false);
\copy col.schede_a_mano (vecchio_slug, campo, da, a) from 'scripts/tassonomia/dati/fase4_schede_a_mano.tsv' with (format text, header true)
create table col.schede_rollback (r jsonb not null);
\copy col.schede_rollback from program 'python3 scripts/tassonomia/schede_rollback_madri.py' with (format csv, quote e'\x01', delimiter e'\x02')

-- valori utili: almeno un valore foglia non nullo e non vuoto (gli scheletri jsonb di PFAF hanno tutto a null)
create or replace function col.utile(j jsonb) returns boolean language sql immutable parallel safe as $$
  select j is not null and jsonb_path_exists(j, '$.** ? ((@.type() == "string" && @ != "") || @.type() == "number" || @.type() == "boolean")')
$$;
create or replace function col.pieno(t text) returns boolean language sql immutable parallel safe as $$ select t is not null and btrim(t) <> '' $$;
create or replace function col.applica_a_mano(t text, slug text, campo text) returns text language plpgsql stable as $$
declare r record;
begin
  if t is null then return null; end if;
  for r in select x.da, x.a from col.schede_a_mano x where x.vecchio_slug = slug and x.campo = applica_a_mano.campo order by x.da loop
    t := replace(t, r.da, r.a);
  end loop;
  return t;
end $$;

create temp table m as
select s.*, 'specie'::text as origine_riga from public.specie s where s.specie_padre_id is null or s.descrizione is not null
union all
select (jsonb_populate_record(null::public.specie, r)).*, 'rollback' from col.schede_rollback;
create index on m (id);

create temp table d as
select m.id, m.slug, m.nome_scientifico, m.origine_riga, coalesce(cv.id, mc.cultivar_id) as cultivar_id,
       mp.taxon_id as trovato, mp.esito, mp.nota as nota_mappa, t.rango as t_rango, t.stato as t_stato,
       case when coalesce(cv.id, mc.cultivar_id) is not null then null
            when t.stato in ('accepted', 'provisionally accepted') then t.id
            when t.rango = 'species' and a.rango in ('subspecies', 'variety', 'form', 'subvariety', 'subform', 'infraspecific name')
                 and split_part(a.nome_scientifico, ' ', 2) = regexp_replace(a.nome_scientifico, '^.* ', '') then a.padre_id
            else coalesce(t.accettato_id, t.id) end as dest
  from m
  left join public.cultivar cv on cv.vecchia_specie_id = m.id
  left join public.mappa_specie mc on mc.vecchia_specie_id = m.id and mc.cultivar_id is not null
  left join public.mappa_specie mp on mp.vecchia_specie_id = m.id and mp.taxon_id is not null
  left join public.taxa t on t.id = mp.taxon_id
  left join public.taxa a on a.id = t.accettato_id;
alter table d add column dest_rango text, add column idonea boolean, add column usata_piante boolean;
update d set dest_rango = x.rango from public.taxa x where x.id = d.dest;
update d set idonea = case
  when cultivar_id is not null then true
  when dest_rango in ('species', 'subspecies', 'variety', 'form') then true
  when dest_rango = 'genus' then nome_scientifico ~ '^(× ?|x )?[A-Z][a-z-]+(\s+spp?\.?)?$'
                                 or coalesce(nota_mappa, '') like 'ibridi o gruppo del genere%' or slug = 'agapanthus'
  else false end;
update d set usata_piante = exists (
  select 1 from col.schede_piante p join public.specie s on s.slug = p.slug
   where coalesce(s.specie_padre_id, s.id) = d.id and d.origine_riga = 'specie');

create temp table k as
select d.*, m.stato_verifica,
       case when d.cultivar_id is not null then 'cv:' || d.cultivar_id else 'tx:' || d.dest end as chiave,
       col.pieno(m.descrizione)::int + col.pieno(m.descrizione_originale)::int + col.utile(m.esigenze)::int
       + (col.utile(m.manutenzione -> 'irrigazione') or col.utile(m.manutenzione -> 'concimazione') or col.utile(m.manutenzione -> 'potatura')
          or col.utile(m.manutenzione -> 'calcio') or col.utile(m.manutenzione -> 'cambio_acqua'))::int
       + (col.utile(m.ciclo_colturale - 'famiglia_botanica' - 'resistenza_gelo')
          or coalesce(m.ciclo_colturale ->> 'resistenza_gelo', '') not in ('', 'non specificata'))::int
       + col.pieno(m.ciclo_vitale)::int + col.utile(m.vaso)::int + (m.immagine is not null and m.immagine <> '{}'::jsonb)::int as n_utili,
       case when not col.pieno(m.descrizione) then 0
            when m.descrizione ~ '^Famiglia botanica:' or m.lingua_descrizione = 'stub' then 1
            when m.descrizione ~* 'testo originale in inglese' then 2 else 3 end as q_descr,
       (d.esito = 'esatto' and d.t_stato in ('accepted', 'provisionally accepted'))::int as nome_accettato,
       length(coalesce(m.descrizione, '')) as ld
  from d join m on m.id = d.id;
create temp table rk as
select k.*, row_number() over (partition by chiave order by idonea desc, (stato_verifica = 'verificato') desc, usata_piante desc,
          (dest_rango = 'genus' and t_rango = 'genus' and t_stato not in ('accepted', 'provisionally accepted')) asc,
          n_utili desc, q_descr desc, nome_accettato desc, ld desc, slug) as pos
  from k;

-- testi puliti, poi le correzioni a mano (segnate come applicate solo se il testo da sostituire c'è)
create temp table t as
select m.id, m.slug, col.descrizione_pulita(m.descrizione) as descrizione, col.alert_pulito(m.alert) as alert,
       concat_ws(' | ', col.alert_nota(m.alert), col.descrizione_nota(m.descrizione),
                 (select string_agg(f, ' | ') from unnest(m.fonti) f where f ~ '^Correzione')) as nota,
       m.descrizione ~ '.Da RHS(, descrizione del genere)? \(testo originale in inglese\): ' as coda_inglese
  from m;
update col.schede_a_mano x set applicata = true
 where exists (select 1 from t where t.slug = x.vecchio_slug
                  and ((x.campo = 'descrizione' and strpos(t.descrizione, x.da) > 0)
                       or (x.campo = 'alert' and exists (select 1 from unnest(t.alert) e where strpos(e, x.da) > 0))));

create table col.schede_proposte as
select gen_random_uuid() as id,
       case when rk.cultivar_id is null then rk.dest end as taxon_id, rk.cultivar_id,
       coalesce((select array_agg(f order by o) from unnest(m.fonti) with ordinality u(f, o) where f !~ '^Correzione'), m.fonti) as fonti,
       col.applica_a_mano(t.descrizione, m.slug, 'descrizione') as descrizione,
       m.descrizione_originale,
       case when t.coda_inglese and m.lingua_descrizione = 'mixed' then 'it' else m.lingua_descrizione end as lingua_descrizione,
       col.esigenze_pulite(m.esigenze) as esigenze, m.manutenzione, m.ciclo_colturale, m.ciclo_vitale, m.vaso,
       case when t.alert is null then null
            else coalesce((select array_agg(col.applica_a_mano(e, m.slug, 'alert') order by o) from unnest(t.alert) with ordinality u(e, o)), '{}') end as alert,
       col.immagine_pulita(m.immagine) as immagine,
       m.stato_verifica, m.verificata_il, m.verificata_da,
       (rk.pos = 1 and rk.idonea) as mostrata,
       m.id as vecchia_specie_id,
       nullif(t.nota, '') as nota,
       m.slug as vecchio_slug, m.origine_riga, rk.idonea, rk.usata_piante, rk.chiave
  from rk join m on m.id = rk.id join t on t.id = rk.id;
alter table col.schede_proposte add primary key (id);

\pset tuples_only on
\pset format unaligned
select 'schede ' || count(*) || ' (mostrate ' || count(*) filter (where mostrata) || ', su cultivar ' || count(cultivar_id)
       || ', non idonee ' || count(*) filter (where not idonea) || ', delle piante dell''utente ' || count(*) filter (where usata_piante) || ')'
  from col.schede_proposte;
select 'agganci ' || count(distinct chiave) || ', con più schede ' || count(distinct chiave) filter (where n > 1)
  from (select chiave, count(*) over (partition by chiave) as n from col.schede_proposte) x;
select 'con nota ' || count(nota) || ', correzioni a mano applicate ' || (select count(*) filter (where applicata) || ' su ' || count(*) from col.schede_a_mano)
  from col.schede_proposte;
