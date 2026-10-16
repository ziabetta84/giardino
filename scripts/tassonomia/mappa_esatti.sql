-- Fase 3: classificazione delle righe con corrispondenze esatte (stessa col.chiave) già in public.taxa.
-- Regole (GBIF species match su COL XR, ICN):
-- - un accettato con il nostro nome vince sugli omonimi sinonimi di altri autori;
-- - sinonimi che portano tutti allo stesso accettato = sinonimo;
-- - generi omonimi in altri generi: decide la famiglia della riga (ICN art. 18.5 per i nomi alternativi);
-- - altrimenti ambiguo: il sinonimo omotipico (ICN art. 49) se è uno solo, se no l'antenato comune (GBIF HIGHERRANK);
-- - un nome con il segno d'ibrido preferisce i candidati ibridi; un ibrido con nome (Genere × epiteto) non va mai su un
--   sinonimo non ibrido di un accettato non ibrido (omonimo di un'altra pianta): va al genere della riga.
set statement_timeout = 0;
do $$ begin
  if to_regclass('col.basionimi') is null then raise exception 'manca col.basionimi: prima col_carica_basionimi.sh'; end if;
end $$;
drop table if exists col.mappa_esatti;
create or replace function col.segno(n text) returns text language sql immutable parallel safe as $$
  select btrim(regexp_replace(regexp_replace(regexp_replace(n, '\s+', ' ', 'g'),
           '(^|\s)[×x](\s+|(?=[A-Z]))', '\1× ', 'g'), '\s+', ' ', 'g'))
$$;
-- autore del basionimo (tra parentesi, ICN art. 49) o, senza parentesi, l'autore stesso
create or replace function col.autore_base(a text) returns text language sql immutable parallel safe as $$
  select btrim(regexp_replace(coalesce(substring(coalesce(a, '') from '^\(([^)]*)\)'), coalesce(a, '')), '\s+', ' ', 'g'))
$$;
-- tipo nominale di un nome di COL: il suo basionimo registrato (o il nome stesso), come nome e autore senza spazi e punti.
-- Confronto per testo e non per id: in COL XR lo stesso nome può comparire con id diversi.
create or replace function col.tipo(x text) returns text language sql stable parallel safe as $$
  select lower(regexp_replace(t.nome || ' ' || coalesce(t.autore, ''), '[\s.]+', '', 'g'))
    from col.nome_uso t where t.id = coalesce((select b.basionimo from col.basionimi b where b.id = x), x)
$$;
-- stessa radice dell'epiteto finale, a meno della desinenza del genere grammaticale (saxatile/saxatilis, minus/minor)
create or replace function col.stessa_radice(a text, b text) returns boolean language sql immutable parallel safe as $$
  select left(x, greatest(3, least(length(x), length(y)) - 3)) = left(y, greatest(3, least(length(x), length(y)) - 3))
    from (select lower(substring(a from '(\S+)$')) as x, lower(substring(b from '(\S+)$')) as y) e
$$;

create temp table cand as
select r.id as sid, t.id as tid, t.col_id, t.nome_scientifico as tnome, t.autore, t.rango, t.stato,
       case when t.stato in ('accepted', 'provisionally accepted') then t.id else t.accettato_id end as acc_id,
       (t.stato in ('accepted', 'provisionally accepted')) as e_acc,
       (t.nome_scientifico = r.nome) as identico,
       (col.segno(t.nome_scientifico) = col.segno(regexp_replace(r.nome, '\s+spp\.?$', ''))) as stesso_segno,
       ((t.nome_scientifico ~ '×') = (r.nome ~ '×|(^|\s)x\s')) as stesso_ibrido,
       (t.nome_scientifico ~ '×' or coalesce(t.notho, '') <> '') as ibrido_t,
       (r.nome ~ '×|(^|\s)x\s') as riga_ibrido
  from col.mappa_righe r
  join col.corrispondenze c on c.chiave = r.chiave
  join public.taxa t on t.col_id = c.id;
create index on cand (sid);
analyze cand;

-- famiglia e antenati di ogni accettato raggiunto
create temp table anc as
with recursive a(acc_id, id, rango, nome, padre_id, dist) as (
  select t.id, t.id, t.rango, t.nome_scientifico, t.padre_id, 0
    from public.taxa t where t.id in (select distinct acc_id from cand where acc_id is not null)
  union all
  select a.acc_id, p.id, p.rango, p.nome_scientifico, p.padre_id, a.dist + 1
    from a join public.taxa p on p.id = a.padre_id where a.dist < 60)
select acc_id, id, rango, nome, dist, max(dist) over (partition by acc_id) - dist as prof from a;
create index on anc (acc_id);
create temp table fam as
select acc_id, max(nome) filter (where rango = 'family') as famiglia from anc group by acc_id;
create index on fam (acc_id);

-- famiglie scritte nella riga ("X or Y", "X / Y") portate al nome accettato di COL (Compositae -> Asteraceae...)
create temp table fam_riga as
with alt as (
  select r.id as sid, btrim(x) as f
    from col.mappa_righe r, regexp_split_to_table(coalesce(r.famiglia_botanica, ''), '\s+or\s+|\s*/\s*|\s*,\s*') x
   where btrim(x) <> '' and r.id in (select sid from cand))
select distinct alt.sid,
       coalesce(case when u.status in ('accepted', 'provisionally accepted') then u.nome end, p.nome, alt.f) as famiglia_col
  from alt
  left join col.nome_uso u on u.nome = alt.f and u.rango = 'family' and u.codice in ('botanical', '')
  left join col.nome_uso p on p.id = u.parent_id and u.status in ('synonym', 'ambiguous synonym') and p.rango = 'family';
create index on fam_riga (sid);

create temp table c2 as
select c.*, r.rango_atteso,
       (r.rango_atteso = 'altro' or c.rango = r.rango_atteso
        or (r.rango_atteso = 'species' and c.rango = 'species aggregate')) as rango_ok,
       (c.rango in ('other', 'unranked', 'infraspecific name')) as rango_debole,
       exists (select 1 from fam f join fam_riga fr on fr.famiglia_col = f.famiglia
                where f.acc_id = c.acc_id and fr.sid = c.sid) as fam_ok,
       ta.rango as acc_rango, ta.autore as acc_autore, ta.padre_id as acc_padre
  from cand c
  join col.mappa_righe r on r.id = c.sid
  left join public.taxa ta on ta.id = c.acc_id;
-- livello d'uso: 1 rango giusto, 2 rango non dichiarato, 3 solo misapplied, 4 rango diverso
alter table c2 add column livello int;
update c2 set livello = case when rango_ok and stato <> 'misapplied' then 1
                             when rango_debole and stato <> 'misapplied' then 2
                             when stato = 'misapplied' then 3 else 4 end;
create temp table u as select c2.* from c2 where c2.livello = (select min(x.livello) from c2 x where x.sid = c2.sid);
create index on u (sid);
-- un nome scritto con il segno d'ibrido preferisce i candidati ibridi (Erysimum × allionii, non E. allionii (DC.) Kuntze)
delete from u where u.riga_ibrido and not u.ibrido_t and exists (select 1 from u x where x.sid = u.sid and x.ibrido_t);

create temp table m as
select u.sid, min(u.livello) as livello,
       (select count(*) from cand c where c.sid = u.sid) as n_cand,
       count(*) filter (where e_acc) as n_acc,
       count(*) filter (where stato = 'accepted') as n_acc_str,
       count(distinct acc_id) as n_dest,
       count(distinct acc_id) filter (where fam_ok) as n_dest_fam,
       bool_or(e_acc and fam_ok) as acc_fam_ok,
       bool_or(not e_acc and fam_ok) as altro_fam_ok
  from u group by u.sid;

create temp table classe as
select m.*, r.rango_atteso,
  case
    when m.livello = 3 then 'solo misapplied'
    when m.livello = 4 then 'rango diverso'
    when m.n_acc = 1 and m.n_dest = 1 then 'accettato'
    when m.n_acc = 1 and r.rango_atteso = 'genus' and m.altro_fam_ok and not m.acc_fam_ok and m.n_dest_fam = 1 then 'genere omonimo: decide la famiglia'
    when m.n_acc = 1 then 'accettato tra omonimi'
    when m.n_acc > 1 and m.n_acc_str = 1 then 'accettato e provvisorio omonimo'
    when m.n_acc > 1 then 'più accettati omonimi'
    when m.n_dest = 1 then 'sinonimo'
    when m.n_dest_fam = 1 then 'sinonimi: decide la famiglia'
    else 'sinonimi verso più accettati'
  end as classe
  from m join col.mappa_righe r on r.id = m.sid;

-- candidato scelto per le classi risolte
create temp table scelto as
select distinct on (k.sid) k.sid, u.tid, u.col_id, u.tnome, u.autore, u.stato, u.rango, u.identico, u.stesso_segno, u.stesso_ibrido
  from classe k join u on u.sid = k.sid
 where case k.classe
         when 'accettato' then u.e_acc
         when 'accettato tra omonimi' then u.e_acc
         when 'accettato e provvisorio omonimo' then u.stato = 'accepted'
         when 'genere omonimo: decide la famiglia' then u.fam_ok
         when 'sinonimo' then true
         when 'sinonimi: decide la famiglia' then u.fam_ok
         else false end
 order by k.sid, u.identico desc, (u.stato = 'synonym') desc, u.col_id;

-- ambigui: sinonimo omotipico, cioè con lo stesso tipo del suo accettato (ICN art. 49; per gli autonimi senza autore vale
-- la specie). Decide il basionimo registrato da COL. Se l'accettato non ha il basionimo registrato, lo si ricava dal nome:
-- stesso epiteto e l'autore tra parentesi di una combinazione uguale all'autore dell'altro nome. Lo stesso autore da solo
-- non basta (Rubus fruticosus L. non è il basionimo di Dasiphora fruticosa (L.) Rydb., che è Potentilla fruticosa L.).
create temp table omotipici as
select u.sid, u.tid, u.col_id, u.tnome, u.autore, u.stato, u.rango, u.acc_id
  from u
  join classe k on k.sid = u.sid
  join public.taxa ta on ta.id = u.acc_id
  left join public.taxa sp on sp.id = u.acc_padre and u.acc_rango in ('subspecies', 'variety', 'form') and coalesce(u.acc_autore, '') = ''
  cross join lateral (select coalesce(sp.col_id, ta.col_id) as col_id, coalesce(sp.nome_scientifico, ta.nome_scientifico) as nome,
                             coalesce(sp.autore, ta.autore, '') as autore) e
 where k.classe in ('sinonimi verso più accettati', 'più accettati omonimi', 'solo misapplied') and not u.e_acc
   and (col.tipo(u.col_id) = col.tipo(e.col_id)
        or (not exists (select 1 from col.basionimi b where b.id = e.col_id)
            and col.stessa_radice(u.tnome, e.nome)
            and ((e.autore ~ '^\(' and col.autore_base(e.autore) = col.autore_base(u.autore) and col.autore_base(u.autore) <> '')
                 or (coalesce(u.autore, '') ~ '^\(' and col.autore_base(u.autore) = btrim(e.autore) and btrim(e.autore) <> ''))));
create temp table omotipico as
select sid, min(tid::text)::uuid as tid from omotipici
 where sid in (select sid from omotipici group by sid having count(distinct acc_id) = 1)
 group by sid;

-- antenato comune più basso delle destinazioni (GBIF HIGHERRANK quando non sceglie)
create temp table lca as
select x.sid, x.id as tid from (
  select u.sid, a.id, count(distinct u.acc_id) as n,
         row_number() over (partition by u.sid order by count(distinct u.acc_id) desc, max(a.prof) desc) as rn
    from u join anc a on a.acc_id = u.acc_id
   group by u.sid, a.id) x
  join m on m.sid = x.sid
 where x.rn = 1 and x.n = m.n_dest;

-- genere della riga per gli ibridi con nome (Genere × epiteto): l'accettato del genere scritto
create temp table genere_riga as
select distinct on (r.id) r.id as sid,
       case when g.stato in ('accepted', 'provisionally accepted') then g.id else g.accettato_id end as tid
  from col.mappa_righe r
  join public.taxa g on g.nome_scientifico = split_part(r.nome, ' ', 1) and g.rango = 'genus'
 where r.nome ~ '^[A-Z][a-z-]+\s+(×\s*|x\s+)[a-z]'
   and (g.stato in ('accepted', 'provisionally accepted') or g.accettato_id is not null)
 order by r.id, (g.stato = 'accepted') desc, g.id;

create temp table esiti as
select k.sid, k.classe,
  case
    when k.classe in ('accettato', 'accettato tra omonimi', 'accettato e provvisorio omonimo', 'genere omonimo: decide la famiglia')
         and s.autore ~* 'orth\.\s*var' then 'variante'
    when k.classe in ('accettato', 'accettato tra omonimi', 'accettato e provvisorio omonimo', 'genere omonimo: decide la famiglia')
         and not s.stesso_ibrido then 'variante'
    when k.classe in ('accettato', 'accettato tra omonimi', 'accettato e provvisorio omonimo')
         or (k.classe = 'genere omonimo: decide la famiglia' and s.stato in ('accepted', 'provisionally accepted')) then 'esatto'
    when k.classe in ('sinonimo', 'sinonimi: decide la famiglia', 'genere omonimo: decide la famiglia') and s.autore ~* 'orth\.\s*var' then 'variante'
    when k.classe in ('sinonimo', 'sinonimi: decide la famiglia', 'genere omonimo: decide la famiglia') then 'sinonimo'
    when k.classe = 'rango diverso' then 'rango superiore'
    else 'ambiguo'
  end as esito,
  coalesce(s.tid, o.tid, l.tid) as taxon_id,
  case
    when r.nome ~ '\sspp\.?$' then 'riga di genere ("Genere spp."): collegata al genere'
    when s.tid is not null and not s.identico and s.stesso_segno then 'scritto con x invece di ×'
    when s.tid is not null and not s.stesso_ibrido then 'segno d''ibrido presente solo in uno dei due nomi'
    when k.classe like '%famiglia%' then 'omonimo risolto con la famiglia della riga'
    when k.classe = 'accettato tra omonimi' then 'esistono omonimi sinonimi di altri autori: vale l''accettato'
    when o.tid is not null then 'ambiguo: scelto il sinonimo omotipico (ICN art. 49)'
    when s.tid is null then 'ambiguo: collegato all''antenato comune delle destinazioni (come GBIF HIGHERRANK)'
  end as nota,
  k.n_cand
  from classe k
  join col.mappa_righe r on r.id = k.sid
  left join scelto s on s.sid = k.sid
  left join omotipico o on o.sid = k.sid and s.tid is null
  left join lca l on l.sid = k.sid;

-- ibridi con nome (Genere × epiteto) finiti su un sinonimo il cui accettato non è un ibrido e non è la stessa pianta (stesso
-- genere e stesso epiteto, come Dryopteris × remota -> Dryopteris remota): per COL non è l'ibrido della riga (omonimo di
-- un'altra pianta, o ibrido ricondotto a uno dei genitori). Collegati al genere della riga, antenato comune sicuro.
create table col.mappa_esatti as
select e.sid, e.classe,
       case when ib.sid is not null then 'rango superiore' else e.esito end as esito,
       case when ib.sid is not null then ib.genere else e.taxon_id end as taxon_id,
       case when ib.sid is not null then 'ibrido con nome: in COL porta a una pianta che non è un ibrido e non è la stessa '
                                         || '(omonimo di un''altra pianta o ibrido ricondotto a un genitore): collegato al genere'
            else e.nota end as nota,
       e.n_cand
  from esiti e
  left join (
    select e2.sid, g.tid as genere
      from esiti e2
      join col.mappa_righe r on r.id = e2.sid
      join genere_riga g on g.sid = e2.sid
      join public.taxa t on t.id = e2.taxon_id
      join public.taxa a on a.id = t.accettato_id
     where e2.esito in ('sinonimo', 'ambiguo') and t.rango not in ('genus', 'subtribe', 'tribe', 'subfamily', 'family')
       and a.nome_scientifico !~ '×' and coalesce(a.notho, '') = ''
       and not (split_part(a.nome_scientifico, ' ', 1) = split_part(r.nome, ' ', 1)
                and col.stessa_radice(r.nome, a.nome_scientifico))) ib on ib.sid = e.sid;
alter table col.mappa_esatti add primary key (sid);

\pset tuples_only on
\pset format unaligned
select 'righe ' || count(*) || ', senza taxon ' || count(*) filter (where taxon_id is null) from col.mappa_esatti;
select esito || ' ' || count(*) from col.mappa_esatti group by esito order by count(*) desc;
select classe || ' ' || count(*) from col.mappa_esatti group by classe order by count(*) desc;
select 'ambigui: omotipico ' || count(*) filter (where nota like '%omotipico%') || ', antenato comune ' || count(*) filter (where nota like '%antenato%') from col.mappa_esatti where esito = 'ambiguo';
