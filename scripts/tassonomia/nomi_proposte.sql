-- Fase 4c: i nomi comuni da caricare (col.nomi_proposte), con i valori definitivi, sulla copia locale (fasi 2-4b
-- applicate, stesse chiavi del reale). Regole: specifica, "Decisioni per la fase 4", punti 12 e 20-24; ricerca in
-- ricerca_fase4/nomi_comuni.md (nc_base.sql). Si lancia da nomi_proposte.sh, che carica col.nomi_provenienza (fonti di
-- ogni nome ricostruite dai lotti) e col.nomi_col_ita (nomi italiani di COL XR).
-- Righe:
-- - nomi italiani delle righe madri di specie (nome principale se diverso dal nome scientifico, nomi alternativi), ammessi
--   se non sono il nome scientifico della riga, un binomio scientifico o «x Genere», e se non sono nell'elenco di
--   esclusione rivisto dall'utente (dati/fase4_nomi_esclusi.tsv); testi corretti con dati/fase4_nomi_corretti.tsv;
-- - i nomi dei generi scelti dall'utente (generi.nome, Calendula compresa), fonte curatore;
-- - i nomi italiani di COL sui taxon di taxa (punto 24): fonte in più sui nomi uguali (confronto senza maiuscole, resta la
--   nostra grafia), righe non preferite per i nuovi (con l'iniziale maiuscola, come i nostri); un nome tolto dall'utente
--   per una pianta non rientra da COL;
-- - i nomi inglesi di PFAF degli avvisi «Nome comune (inglese, fonte PFAF): …», lingua en, mai preferiti (punto 12).
-- Uno stesso nome (senza maiuscole e spazi doppi) compare una sola volta per taxon e lingua, con le fonti unite. Un nome
-- italiano uguale al nome scientifico della sua pianta non entra (salvo generi.nome).
-- (Il DELETE in fondo lavora sulla tabella di appoggio della copia appena creata, non su dati caricati.)
-- Destinazione (punto 20): D1 l'accettato del nome trovato in mappa_specie, per un autonimo la specie; D2 una riga di specie
-- finita su un genere o più su: lì, mai preferito; D3 una riga «Genere spp.» con un vecchio binomio: i suoi nomi vanno alla
-- specie del vecchio nome se è in taxa con una sola destinazione, tranne i nomi uguali a generi.nome, che restano al genere;
-- se il vecchio binomio non è in taxa, al genere, mai preferiti.
-- Preferito (punto 21), al più uno per taxon e lingua: le scelte dell'utente (dati/fase4_nomi_preferiti.tsv: un nome, o
-- vuoto per nessun preferito), poi generi.nome, poi il nome scelto dall'utente per la riga, poi la riga del nome accettato,
-- poi la riga di un sinonimo, poi il nome trasferito (D3); spareggio: riga verificata, poi più fonti esterne. Candidati
-- solo i nomi principali delle righe e generi.nome; mai i nomi D2, D3 non risolti, di COL o inglesi.
-- Lanciare dalla radice del repository.
set statement_timeout = 0;
do $$ begin
  if to_regclass('col.nomi_provenienza') is null or to_regclass('col.nomi_col_ita') is null then
    raise exception 'mancano col.nomi_provenienza o col.nomi_col_ita: lanciare nomi_proposte.sh';
  end if;
end $$;
drop table if exists col.nomi_proposte, col.nomi_esclusi, col.nomi_corretti, col.nomi_scelte, col.nomi_righe_genere, col.nomi_candidati;
create table col.nomi_esclusi (vecchio_slug text not null, nome text not null, motivo text not null check (motivo <> ''),
                               applicata boolean not null default false);
\copy col.nomi_esclusi (vecchio_slug, nome, motivo) from 'scripts/tassonomia/dati/fase4_nomi_esclusi.tsv' with (format text, header true)
create table col.nomi_corretti (vecchio_slug text not null, da text not null, a text not null check (btrim(a) <> ''),
                                applicata boolean not null default false);
\copy col.nomi_corretti (vecchio_slug, da, a) from 'scripts/tassonomia/dati/fase4_nomi_corretti.tsv' with (format text, header true)
-- scelte dell'utente: taxon (nome scientifico della destinazione), nome preferito (vuoto = nessun preferito), motivo
create table col.nomi_scelte (taxon text not null, nome text not null, motivo text not null check (motivo <> ''),
                              applicata boolean not null default false);
\copy col.nomi_scelte (taxon, nome, motivo) from 'scripts/tassonomia/dati/fase4_nomi_preferiti.tsv' with (format text, header true)
create table col.nomi_righe_genere (slug text, sci_old text, nome text, genere text, n_specie_gbif text, decisione text,
                                    descrive_specie text, nome_genere_it text, n_cultivar text, n_piante text);
\copy col.nomi_righe_genere from 'scripts/nomi-italiani/dati/righe_genere_da_rivedere.csv' with (format csv, header true)

-- un nome si scrive senza spazi ai bordi né doppi; due nomi sono uguali a meno delle maiuscole e degli spazi
create or replace function col.pulisci_nome(t text) returns text language sql immutable parallel safe as $$
  select regexp_replace(btrim(t, E' \t\n\u00a0'), '[[:space:]\u00a0]+', ' ', 'g')
$$;
create or replace function col.chiave_nome(t text) returns text language sql immutable parallel safe as $$
  select lower(col.pulisci_nome(t))
$$;

-- destinazione di ogni taxon: l'accettato; per un autonimo infraspecifico, la specie
create temp table dest as
select t.id as t_id, case when a.rango in ('subspecies', 'variety', 'form', 'subvariety')
                           and split_part(a.nome_scientifico, ' ', 2) = regexp_replace(a.nome_scientifico, '^.* ', '')
                          then a.padre_id else a.id end as d
  from public.taxa t join public.taxa a on a.id = coalesce(t.accettato_id, t.id);
create index on dest (t_id);
analyze dest;

-- vecchi binomi delle righe «Genere spp.» e loro destinazione (se unica)
create temp table old_bin as
select slug, sci_old from col.nomi_righe_genere
 where decisione in ('spp', 'rivedere', 'gia_spp') and btrim(sci_old) ~ '^[A-Z][a-z-]+ (× )?[a-z-]+$';
-- un accettato vince sugli omonimi di altri autori (come nella fase 3): se c'è, conta solo lui
create temp table old_res as
select g.slug, min(d.d::text)::uuid as d_old, count(distinct d.d) as n
  from old_bin g join public.taxa t on t.nome_scientifico = regexp_replace(btrim(g.sci_old), ' x ', ' × ')
  join dest d on d.t_id = t.id
 where t.stato in ('accepted', 'provisionally accepted')
    or not exists (select 1 from public.taxa a where a.nome_scientifico = t.nome_scientifico and a.stato in ('accepted', 'provisionally accepted'))
 group by 1;

create temp table gnome as
select g.nome_scientifico, col.pulisci_nome(g.nome) as nome, col.chiave_nome(g.nome) as k, t.id as t_genus
  from public.generi g join public.taxa t on t.nome_scientifico = g.nome_scientifico and t.rango = 'genus' and t.stato = 'accepted'
 where g.nome <> g.nome_scientifico or g.nome_scientifico = 'Calendula';

-- destinazione di ogni riga madre
create temp table riga as
select s.id, s.slug, s.nome_scientifico, s.stato_verifica, m.taxon_id as t_riga,
       (tr.stato in ('accepted', 'provisionally accepted')) as riga_su_accettato, d.d as d_riga, x.rango as rango_d_riga,
       (s.nome_scientifico ~ '^[A-Za-z×x -]+ [a-z×-]+' and s.nome_scientifico !~ ' spp?\.$') as riga_di_specie,
       (ob.slug is not null) as ha_vecchio_binomio, case when o.n = 1 then o.d_old end as d_old
  from public.specie s
  join public.mappa_specie m on m.vecchia_specie_id = s.id and m.taxon_id is not null
  join public.taxa tr on tr.id = m.taxon_id
  join dest d on d.t_id = m.taxon_id
  join public.taxa x on x.id = d.d
  left join old_bin ob on ob.slug = s.slug
  left join old_res o on o.slug = s.slug
 where s.specie_padre_id is null;

-- nomi italiani delle righe, corretti, con la regola di destinazione
update col.nomi_corretti c set applicata = true
 where exists (select 1 from col.nomi_provenienza p where p.slug = c.vecchio_slug and p.nome = c.da);
create temp table nd as
select p.slug, p.ruolo, col.pulisci_nome(coalesce(c.a, p.nome)) as nome, col.chiave_nome(coalesce(c.a, p.nome)) as k, p.fonti, p.note, p.tipo,
       r.stato_verifica, r.riga_su_accettato,
       case when r.ha_vecchio_binomio and exists (select 1 from gnome g where g.t_genus = r.d_riga and g.k = col.chiave_nome(coalesce(c.a, p.nome)))
              then 'D3 nome di genere approvato, resta al genere'
            when r.d_old is not null then 'D3 trasferito alla specie del vecchio nome'
            when r.ha_vecchio_binomio then 'D3 vecchio binomio non in taxa: al genere, mai preferito'
            when r.riga_di_specie and r.rango_d_riga not in ('species', 'subspecies', 'variety', 'form', 'subvariety')
              then 'D2 riga di specie salita di rango: mai preferito'
            else 'D1 accettato' end as regola,
       r.d_riga, r.d_old
  from col.nomi_provenienza p
  join riga r on r.id = p.id
  left join col.nomi_corretti c on c.vecchio_slug = p.slug and c.da = p.nome;
alter table nd add column taxon_id uuid;
update nd set taxon_id = case when regola like 'D3 trasferito%' then d_old else d_riga end;

update col.nomi_esclusi e set applicata = true
 where exists (select 1 from nd where nd.slug = e.vecchio_slug and nd.k = col.chiave_nome(e.nome));
create temp table amm as
select nd.* from nd
 where tipo in ('comune', 'genere_della_riga', 'parola_uguale_a_nome_scientifico') and k !~ '^(x|×) '
   and not exists (select 1 from col.nomi_esclusi e where e.vecchio_slug = nd.slug and col.chiave_nome(e.nome) = nd.k);

-- candidati al preferito, per riga
create table col.nomi_candidati as
select taxon_id, k, nome, slug as da,
       case when note like '%lotto12 rinominato%' or slug in ('helleborus', 'hedera') then 1
            when regola like 'D3 trasferito%' then 4 when riga_su_accettato then 2 else 3 end as prio,
       (stato_verifica = 'verificato') as verificata,
       cardinality(array_remove(array_remove(string_to_array(fonti, ','), 'catalogo'), 'curatore')) as n_fonti
  from amm where ruolo = 'principale' and regola not like 'D2%' and regola not like 'D3 vecchio binomio%'
union all
select t_genus, k, nome, 'generi:' || nome_scientifico, 0, true, 1 from gnome;

-- nomi italiani: dei nostri dati e dei generi, uniti per taxon e nome; poi COL
create temp table it0 as
select taxon_id, k, nome, string_to_array(fonti, ',') as fonti, slug, regola, (ruolo = 'principale') as principale from amm
union all
select t_genus, k, nome, array['curatore'], 'generi:' || nome_scientifico, 'nome del genere scelto dall''utente', true from gnome;
create temp table it1 as
select taxon_id, k, (array_agg(nome order by principale desc, nome))[1] as nome,
       array(select distinct f from unnest(array_agg(fonti)) u(f)) as fonti_raw,
       'righe: ' || string_agg(distinct slug, ', ' order by slug) || '; ' || string_agg(distinct regola, '; ' order by regola) as nota
  from (select taxon_id, k, nome, unnest(fonti) as fonti, slug, regola, principale from it0) x
 group by taxon_id, k;
alter table it1 add column fonti text[];
update it1 set fonti = array(select f from unnest(fonti_raw) f order by f);

create temp table colt as
select d.d as taxon_id, col.chiave_nome(c.nome) as k, col.pulisci_nome(c.nome) as nome,
       'col:' || case c.source_id when '139831' then 'inaturalist' when '314570' then 'wikispecies' when '53131' then 'iucn'
                                  when '2018' then 'grin' when '314569' then 'wikidata'
                                  else case when c.source_id ~ '^[0-9]+$' and c.source_id::int between 291500 and 291699 then 'flora-helvetica'
                                            when c.source_id ~ '^[0-9]+$' and c.source_id::int between 292400 and 292699 then 'info-flora'
                                            else 'altra-' || c.source_id end end as fonte
  from col.nomi_col_ita c join public.taxa x on x.col_id = c.taxon_col join dest d on d.t_id = x.id
 where col.pulisci_nome(c.nome) <> '';
-- un nome tolto dall'utente vale per quella pianta da qualunque fonte arrivi: si toglie anche il nome uguale di COL
create temp table esclusi_tk as
select distinct nd.taxon_id, nd.k from nd join col.nomi_esclusi e on e.vecchio_slug = nd.slug and col.chiave_nome(e.nome) = nd.k;
create temp table colp as
select taxon_id, k, min(nome) as nome, array_agg(distinct fonte order by fonte) as fonti from colt c
 where not exists (select 1 from esclusi_tk x where x.taxon_id = c.taxon_id and x.k = c.k)
 group by 1, 2;

-- nomi inglesi di PFAF
create temp table en0 as
select coalesce(r.d_old, r.d_riga) as taxon_id, col.pulisci_nome(btrim(n, E' \t\n\u00a0.')) as nome, s.slug
  from public.specie s join riga r on r.id = s.id
  cross join lateral unnest(s.alert) a
  cross join lateral regexp_split_to_table(substring(a from '^Nome comune \(inglese, fonte PFAF\):[[:space:] ]*(.*)$'), ',[[:space:] ]*') n
 where s.specie_padre_id is null and a ~ '^Nome comune \(inglese, fonte PFAF\):';
create temp table en1 as
select taxon_id, col.chiave_nome(nome) as k, (array_agg(nome order by nome))[1] as nome, 'righe: ' || string_agg(distinct slug, ', ' order by slug) as nota
  from en0 where btrim(nome) <> '' group by 1, 2;

-- preferito
create temp table pref0 as
select taxon_id, k, row_number() over (partition by taxon_id order by prio, verificata desc, n_fonti desc, k) as rn,
       prio, verificata, n_fonti
  from (select taxon_id, k, min(prio) as prio, bool_or(verificata) as verificata, max(n_fonti) as n_fonti
          from col.nomi_candidati group by 1, 2) x;
-- una scelta dell'utente vale se il taxon ha nomi e se il nome scelto è uno dei suoi (nostro o di COL)
create temp table tutti_it as select taxon_id, k from it1 union select taxon_id, k from colp;
update col.nomi_scelte s set applicata = true
 where exists (select 1 from public.taxa t join (select distinct taxon_id from tutti_it) c on c.taxon_id = t.id
                where t.nome_scientifico = s.taxon
                  and (s.nome = '' or exists (select 1 from tutti_it i where i.taxon_id = t.id and i.k = col.chiave_nome(s.nome))));
create temp table pref as
select p.taxon_id, p.k from pref0 p
 where p.rn = 1 and not exists (select 1 from col.nomi_scelte s join public.taxa t on t.nome_scientifico = s.taxon
                                 where s.applicata and t.id = p.taxon_id)
union all
select t.id, col.chiave_nome(s.nome) from col.nomi_scelte s
  join public.taxa t on t.nome_scientifico = s.taxon
  join (select distinct taxon_id from tutti_it) c on c.taxon_id = t.id
 where s.applicata and s.nome <> '';

create table col.nomi_proposte as
select gen_random_uuid() as id, coalesce(i.taxon_id, c.taxon_id) as taxon_id, 'it'::text as lingua,
       coalesce(i.nome, upper(left(c.nome, 1)) || substr(c.nome, 2)) as nome,
       exists (select 1 from pref where pref.taxon_id = coalesce(i.taxon_id, c.taxon_id) and pref.k = coalesce(i.k, c.k)) as preferito,
       array(select distinct f from unnest(coalesce(i.fonti, '{}') || coalesce(c.fonti, '{}')) f order by f) as fonti,
       i.nota, coalesce(i.k, c.k) as k, case when i.k is null then 'col' else 'nostri' end as origine
  from it1 i full join colp c on c.taxon_id = i.taxon_id and c.k = i.k
union all
select gen_random_uuid(), taxon_id, 'en', nome, false, array['pfaf'], nota, k, 'pfaf' from en1;
-- un nome uguale al nome scientifico della sua pianta non è un nome comune (la ricerca lo trova già da taxa), salvo i nomi
-- dei generi scelti dall'utente (Calendula)
delete from col.nomi_proposte p using public.taxa t
 where t.id = p.taxon_id and p.lingua = 'it' and p.k = col.chiave_nome(t.nome_scientifico) and not ('curatore' = any(p.fonti));
alter table col.nomi_proposte add primary key (id);

\pset tuples_only on
\pset format unaligned
select 'nomi ' || count(*) || ' (it ' || count(*) filter (where lingua = 'it') || ', di cui nostri ' || count(*) filter (where origine = 'nostri')
       || ' e solo COL ' || count(*) filter (where origine = 'col') || '; en ' || count(*) filter (where lingua = 'en') || '), preferiti '
       || count(*) filter (where preferito) || ', taxon ' || count(distinct taxon_id)
  from col.nomi_proposte;
select 'candidati al preferito su ' || count(distinct taxon_id) || ' taxon, con più candidati ' || count(distinct taxon_id) filter (where n > 1)
       || ', spareggi decisi solo dall''ordine alfabetico ' || (select count(*) from pref0 a join pref0 b on a.taxon_id = b.taxon_id and a.rn = 1 and b.rn = 2
            where a.prio = b.prio and a.verificata = b.verificata and a.n_fonti = b.n_fonti
              and not exists (select 1 from col.nomi_scelte s join public.taxa t on t.nome_scientifico = s.taxon where s.applicata and t.id = a.taxon_id))
  from (select taxon_id, count(distinct k) as n from col.nomi_candidati group by taxon_id) x;
select 'esclusioni applicate ' || (select count(*) filter (where applicata) || ' su ' || count(*) from col.nomi_esclusi)
       || ', correzioni ' || (select count(*) filter (where applicata) || ' su ' || count(*) from col.nomi_corretti)
       || ', scelte ' || (select count(*) filter (where applicata) || ' su ' || count(*) from col.nomi_scelte);
