-- Fase 3: righe senza corrispondenza esatta. Cascata di regole, dalla più sicura alla più larga:
-- forme speciali (grex, "hybrids", "aff.") -> genere; forma del nome (k1); ortografia (k2, come SciNameNormalizer di
-- GBIF); refuso di 1-2 lettere nello stesso genere (da far confermare); rango superiore (specie, poi genere);
-- genere scritto male con conferma dell'epiteto (da far confermare); famiglia; non trovato.
set statement_timeout = 0;
create extension if not exists fuzzystrmatch schema extensions;
drop table if exists col.mappa_altri, col.mappa_plantae;

-- parole del nome in forma normalizzata: senza trattino morbido, segni d'ibrido (× ovunque, x solo isolata o davanti
-- a una maiuscola: la X di Xanthoceras resta), parentesi, quello che segue una barra, marcatori di rango, " sp./spp.";
-- minuscolo
create or replace function col.parole(n text) returns text[] language sql immutable parallel safe as $$
  select regexp_split_to_array(btrim(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(
           lower(regexp_replace(replace(replace(n, chr(173), ''), '×', ' '), '(^|\s)x(\s+|(?=[A-Z]))', ' ', 'g')),
           '\([^)]*\)', ' ', 'g'),
           '/.*$', ''),
           '(^|\s)(subsp|ssp|var|f|forma|subvar|nothosubsp|nothovar|convar)\.?(?=\s)', ' ', 'g'),
           '\s+spp?\.?\s*$', ''),
           '\s+', ' ', 'g')), ' ')
$$;
-- k1: forma. Il genere resta separato, il resto si unisce (novae hiberniae = novae-hiberniae, ICN art. 23.1)
create or replace function col.k1(w text[]) returns text language sql immutable parallel safe as $$
  select w[1] || coalesce(' ' || nullif(replace(array_to_string(w[2:], ''), '-', ''), ''), '')
$$;
-- k2: ortografia sull'epiteto (regole di SciNameNormalizer di GBIF checklistbank): lettere doppie, desinenze, i/j/y, th, rh
create or replace function col.k2(k text) returns text language sql immutable parallel safe as $$
  select split_part(k, ' ', 1) || coalesce(' ' || nullif(
    regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(
      split_part(k, ' ', 2),
      '(.)\1+', '\1', 'g'), '(on|um|us|a)$', 'a'), '(?<=.)[jyi]+', 'i', 'g'), 'ei$', 'i'), 'th', 't', 'g'), 'rh', 'r', 'g'), ''), '')
$$;

create temp table nt as
select r.*, col.parole(r.nome) as parole,
  case
    when r.nome ~ '^(×\s*|x\s+)?[A-Z][a-z-]+(\s+[A-Z0-9(][^\s]*)+$' then 'grex'
    when r.nome ~* '\s(hybrids?|species|group|mix)\s*$' or r.nome ~* '\shybrids?\s' then 'ibridi o gruppo'
    when r.nome ~ '\s(aff|cf)\.\s' then 'aff.'
  end as forma,
  (r.nome ~ '×|(^|\s)x\s') as ibrido
  from col.mappa_righe r
 where not exists (select 1 from col.corrispondenze c where c.chiave = r.chiave);
alter table nt add column k1 text, add column genere text;
update nt set k1 = col.k1(parole), genere = parole[1];
create index on nt (id);

-- COL in Plantae, ristretto ai generi dei nostri nomi (sinonimi: il regno è quello dell'accettato; niente segnaposto spp)
create table col.mappa_plantae as
select u.id, u.nome, u.autore, u.rango, u.status, u.parent_id,
       case when u.status in ('accepted', 'provisionally accepted') then u.id else u.parent_id end as acc_id,
       col.k1(col.parole(u.nome)) as k1
  from col.nome_uso u
  left join col.nome_uso p on p.id = u.parent_id and u.status in ('synonym', 'ambiguous synonym', 'misapplied')
 where coalesce(nullif(u.regno, ''), p.regno) = 'Plantae'
   and u.nome !~ '\sspp?\.?\s*$' and coalesce(p.nome, '') !~ '\sspp?\.?\s*$'
   and lower(split_part(col.chiave(u.nome), ' ', 1)) in (select genere from nt);
alter table col.mappa_plantae add column k2 text, add column genere text, add column ibrido boolean;
update col.mappa_plantae set k2 = col.k2(k1), genere = split_part(k1, ' ', 1), ibrido = (nome ~ '×');
create index on col.mappa_plantae (k1);
create index on col.mappa_plantae (k2);
create index on col.mappa_plantae (genere);
analyze col.mappa_plantae;

-- 1-2. forma (k1) e ortografia (k2); solo nomi di almeno due parole e non delle forme speciali
create temp table candidati as
select n.id as sid, 'forma'::text as metodo, c.id, c.status, c.acc_id from nt n join col.mappa_plantae c on c.k1 = n.k1
 where n.forma is null and n.k1 ~ ' ' and c.rango <> 'genus'
union all
select n.id, 'ortografia', c.id, c.status, c.acc_id from nt n join col.mappa_plantae c on c.k2 = col.k2(n.k1)
 where n.forma is null and n.k1 ~ ' ' and c.rango <> 'genus'
   and not exists (select 1 from col.mappa_plantae x where x.k1 = n.k1 and x.rango <> 'genus');
-- 3. refuso di una lettera (due se l'epiteto supera 7 lettere) nello stesso genere, stessa natura d'ibrido; solo binomi:
--    per i nomi di tre o più parole vale la specie superiore (con il refuso Vicia faba major diventava V. faba var. minor)
insert into candidati
select n.id, 'refuso', c.id, c.status, c.acc_id
  from nt n join col.mappa_plantae c on c.genere = n.genere and c.rango <> 'genus' and c.ibrido = n.ibrido
 where n.forma is null and array_length(n.parole, 1) = 2 and n.id not in (select sid from candidati)
   and extensions.levenshtein(split_part(n.k1, ' ', 2), split_part(c.k1, ' ', 2))
       <= case when length(split_part(n.k1, ' ', 2)) > 7 then 2 else 1 end;
-- per i refusi vale solo la distanza minima
delete from candidati c using (
  select c2.sid, c2.id, extensions.levenshtein(split_part(n.k1, ' ', 2), split_part(p.k1, ' ', 2)) as d,
         min(extensions.levenshtein(split_part(n.k1, ' ', 2), split_part(p.k1, ' ', 2))) over (partition by c2.sid) as dmin
    from candidati c2 join nt n on n.id = c2.sid join col.mappa_plantae p on p.id = c2.id where c2.metodo = 'refuso') x
 where c.sid = x.sid and c.id = x.id and x.d > x.dmin;

create temp table metriche as
select sid, count(*) filter (where status in ('accepted', 'provisionally accepted')) as n_acc, count(distinct acc_id) as n_dest
  from candidati group by sid;
create temp table scelta as
select distinct on (c.sid) c.sid, c.metodo, c.id as col_id, c.status
  from candidati c join metriche m using (sid)
 where (m.n_acc = 1 and c.status in ('accepted', 'provisionally accepted')) or (m.n_acc = 0 and m.n_dest = 1)
 order by c.sid, (c.status = 'accepted') desc, (c.status = 'synonym') desc, c.id;

-- 4. rango superiore: la specie per i nomi di tre o più parole, poi il genere (accettato; preferito quello già in taxa)
create temp table specie_sup as
select distinct on (n.id) n.id as sid, c.id as col_id, c.status
  from nt n join col.mappa_plantae c on c.k1 = col.k1(n.parole[1:2]) and c.rango = 'species'
 where n.forma is null and array_length(n.parole, 1) >= 3 and n.id not in (select sid from scelta)
   and c.status in ('accepted', 'provisionally accepted')
 order by n.id, (c.status = 'accepted') desc, c.id;
create temp table genere_sup as
select distinct on (n.id) n.id as sid, c.id as col_id, c.status,
       count(*) filter (where c.status in ('accepted', 'provisionally accepted')) over (partition by n.id) as n_generi
  from nt n join col.mappa_plantae c on c.k1 = n.genere and c.rango = 'genus'
 order by n.id, (c.status in ('accepted', 'provisionally accepted')) desc,
          exists (select 1 from public.taxa t where t.col_id = c.id) desc, (c.status = 'accepted') desc, c.id;

-- 5. genere scritto male: un genere di Plantae a una o due lettere (generi lunghi) in cui esiste lo stesso epiteto, quando
--    il nostro genere non è un genere accettato (Buddleia è un sinonimo di Buddleja, Reineckia di un genere di palme).
--    Sicuro se COL registra il nostro genere come sinonimo proprio di quello trovato.
create temp table genere_refuso as
select distinct on (n.id) n.id as sid, u.id as col_id, u.status,
       exists (select 1 from col.mappa_plantae g join col.nome_uso a on a.id = g.parent_id
                where g.genere = n.genere and g.rango = 'genus' and g.status not in ('accepted', 'provisionally accepted')
                  and lower(a.nome) = lower(split_part(col.chiave(u.nome), ' ', 1))) as sicuro
  from nt n
  join col.nome_uso u on lower(split_part(col.chiave(u.nome), ' ', 2)) = n.parole[2]
  left join col.nome_uso p on p.id = u.parent_id and u.status in ('synonym', 'ambiguous synonym')
 where n.forma is null and array_length(n.parole, 1) >= 2
   and not exists (select 1 from col.mappa_plantae g where g.genere = n.genere and g.rango = 'genus'
                                                   and g.status in ('accepted', 'provisionally accepted'))
   and coalesce(nullif(u.regno, ''), p.regno) = 'Plantae'
   and u.nome !~ '\sspp?\.?\s*$'
   and extensions.levenshtein(lower(split_part(col.chiave(u.nome), ' ', 1)), n.genere)
       between 1 and case when length(n.genere) > 8 then 2 else 1 end
 order by n.id, (array_length(col.parole(u.nome), 1) = array_length(n.parole, 1)) desc, (u.status = 'accepted') desc, u.id;

-- 6. notogeneri assenti da COL (× Angulocaste, × Mahoberberis...): taxon locale sotto la famiglia della riga
--    (specifica, "taxa": i taxon locali servono per i notogeneri non riconosciuti)
create temp table notogeneri as
select n.genere, '× ' || initcap(n.genere) as nome,
       min(btrim(split_part(regexp_replace(coalesce(n.famiglia_botanica, ''), '\s+or\s+', '/', 'g'), '/', 1))) as famiglia
  from nt n
 where n.genere in (select genere from nt where nome ~ '^(×\s*|x\s+)[A-Z]')
   and not exists (select 1 from col.mappa_plantae g where g.genere = n.genere and g.rango = 'genus')
 group by n.genere;

-- 7. nomi che in COL esistono solo fuori da Plantae (Cetraria islandica, un lichene): da decidere
create temp table fuori_plantae as
select distinct on (n.id) n.id as sid, u.id as col_id, u.regno
  from nt n join col.nome_uso u on col.chiave(u.nome) = n.chiave
 where u.status in ('accepted', 'provisionally accepted') and u.regno <> 'Plantae'
 order by n.id, u.id;

-- 8. ultime proposte per chi non ne ha (da far confermare): il genere accettato di Plantae più simile per scrittura
--    (due lettere al massimo), altrimenti la famiglia scritta nella riga, portata al nome accettato di COL
create temp table genere_simile as
select distinct on (n.id) n.id as sid, u.id as col_id
  from nt n join col.nome_uso u on u.rango = 'genus' and u.status = 'accepted' and u.regno = 'Plantae'
   and extensions.levenshtein(lower(u.nome), n.genere) <= 2
 where not exists (select 1 from col.mappa_plantae g where g.genere = n.genere and g.rango = 'genus')
   and n.genere not in (select genere from notogeneri)
 order by n.id, extensions.levenshtein(lower(u.nome), n.genere), u.id;
create temp table famiglia_riga as
select distinct on (n.id) n.id as sid, coalesce(case when u.status = 'accepted' then u.id end, a.id) as col_id
  from nt n
  join col.nome_uso u on u.nome = btrim(split_part(regexp_replace(coalesce(n.famiglia_botanica, ''), '\s+or\s+', '/', 'g'), '/', 1))
   and u.rango = 'family' and u.codice in ('botanical', '')
  left join col.nome_uso a on a.id = u.parent_id and u.status <> 'accepted' and a.rango = 'family' and a.status = 'accepted'
 where coalesce(case when u.status = 'accepted' then u.id end, a.id) is not null
 order by n.id, (u.status = 'accepted') desc, u.id;

create table col.mappa_altri as
select n.id as sid, n.forma,
  case
    when s.sid is not null then s.metodo
    when ng.genere is not null then 'notogenere locale'
    when n.forma is not null and g.sid is not null then n.forma
    when gr.sid is not null then 'genere scritto male'
    when sp.sid is not null then 'specie superiore'
    when g.sid is not null then 'genere superiore'
    when fp.sid is not null then 'fuori da Plantae'
    when gs.sid is not null then 'genere simile'
    when fr.sid is not null then 'famiglia della riga'
    else 'nessuno' end as metodo,
  case when ng.genere is null then
    coalesce(s.col_id, case when n.forma is null then gr.col_id end, case when n.forma is null then sp.col_id end, g.col_id, fp.col_id,
             gs.col_id, fr.col_id)
  end as col_id,
  ng.nome as taxon_locale, ng.famiglia as famiglia_locale,
  case
    when s.sid is not null then 'variante'
    when ng.genere is not null then 'ibrido'
    when n.forma is null and gr.sid is not null then 'variante'
    when n.forma is null and sp.sid is not null then 'rango superiore'
    when g.sid is not null then 'rango superiore'
    when fp.sid is null and gs.sid is not null then 'variante'
    when fp.sid is null and fr.sid is not null then 'rango superiore'
    else 'non trovato' end as esito,
  case
    when s.metodo = 'refuso' then true
    when ng.genere is not null then false
    when n.forma is null and gr.sid is not null and s.sid is null then not gr.sicuro
    when s.sid is null and sp.sid is null and g.sid is null then true
    when s.sid is null and sp.sid is null and g.status not in ('accepted', 'provisionally accepted') then true
    when g.n_generi > 1 and s.sid is null and sp.sid is null then true
    else false end as da_rivedere,
  case
    when s.metodo = 'forma' then 'stesso nome scritto in un''altra forma (maiuscole, marcatori di rango, segni, trattini)'
    when s.metodo = 'ortografia' then 'variante ortografica (regole di normalizzazione di GBIF)'
    when s.metodo = 'refuso' then 'possibile refuso: da confermare'
    when ng.genere is not null then 'notogenere assente da COL: taxon locale sotto la famiglia ' || coalesce(ng.famiglia, '?')
    when n.forma = 'grex' then 'grex (ICNCP art. 23): collegato al genere, nella fase 4 diventa una cultivar di categoria grex'
    when n.forma = 'ibridi o gruppo' then 'ibridi o gruppo del genere: collegato al genere'
    when n.forma = 'aff.' then '"aff." indica una pianta affine, non la specie: collegato al genere'
    when gr.sid is not null and gr.sicuro then 'genere scritto in una variante registrata da COL come sinonimo'
    when gr.sid is not null then 'genere scritto male: da confermare'
    when sp.sid is not null then 'la sottospecie o varietà non è in COL: collegato alla specie'
    when g.n_generi > 1 then 'più generi omonimi in Plantae: da confermare'
    when g.sid is not null and g.status not in ('accepted', 'provisionally accepted') then 'il genere in COL è solo un sinonimo: da confermare'
    when g.sid is not null and exists (select 1 from candidati c where c.sid = n.id) then 'più candidati senza una scelta sicura: collegato al genere'
    when g.sid is not null then 'specie non trovata in COL: collegato al genere'
    when fp.sid is not null then 'in COL solo fuori da Plantae (regno ' || fp.regno || '): da decidere'
    when gs.sid is not null then 'genere non trovato in COL; proposto il genere più simile per scrittura: da confermare'
    when fr.sid is not null then 'genere non trovato in COL; proposta la famiglia scritta nella riga: da confermare'
    else 'genere non trovato in COL' end as nota
  from nt n
  left join scelta s on s.sid = n.id
  left join specie_sup sp on sp.sid = n.id
  left join genere_sup g on g.sid = n.id
  left join genere_refuso gr on gr.sid = n.id
  left join notogeneri ng on ng.genere = n.genere and s.sid is null
  left join fuori_plantae fp on fp.sid = n.id
  left join genere_simile gs on gs.sid = n.id
  left join famiglia_riga fr on fr.sid = n.id;
alter table col.mappa_altri add primary key (sid);

\pset tuples_only on
\pset format unaligned
select 'righe ' || count(*) from col.mappa_altri;
select metodo || ' | ' || esito || ' | da rivedere ' || da_rivedere || ' | ' || count(*) from col.mappa_altri group by metodo, esito, da_rivedere order by count(*) desc;
