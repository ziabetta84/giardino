-- Prove delle proposte delle cultivar della fase 4a (cultivar_proposte.sql), sulla copia locale. Errore al primo
-- controllo che fallisce. Numeri e casi valgono per specie del 16/10/2026 (dopo la fase 3) e COL26.9 XR.
do $$
declare
  n bigint;
  atteso record;
begin
  -- 196.388 righe con apici - 163 fuse o illeggibili (solo mappa) + 220 grex + 1 Gruppo (Dunedin)
  select count(*) into n from col.cultivar_proposte;
  if n <> 196446 then raise exception 'cultivar proposte: % (attese 196446)', n; end if;
  select count(*) into n from col.cultivar_mappa;
  if n <> 167 then raise exception 'righe di mappa delle cultivar: % (attese 167: 163 fuse o illeggibili + 4 doppie)', n; end if;
  select count(*) into n from col.cultivar_proposte where taxon_id is null and taxon_col_id is null;
  if n > 0 then raise exception 'cultivar senza taxon: %', n; end if;
  select count(*) into n from col.cultivar_proposte p
    left join public.taxa t on t.id = p.taxon_id left join col.nome_uso u on u.id = p.taxon_col_id
   where coalesce(t.rango, u.rango) not in ('genus', 'species', 'subspecies', 'variety', 'form');
  if n > 0 then raise exception 'cultivar su un taxon sopra il genere o di rango inatteso (ICNCP art. 21.2): %', n; end if;
  select count(*) into n from col.cultivar_proposte
   where btrim(epiteto) = '' or left(epiteto, 1) = '''' or right(epiteto, 1) = '''' or epiteto ~ '[\[\]]';
  if n > 0 then raise exception 'epiteti non validi: %', n; end if;
  select count(*) into n from (select vecchia_specie_id from col.cultivar_proposte group by 1 having count(*) > 1) x;
  if n > 0 then raise exception 'vecchie righe con più cultivar: %', n; end if;
  select count(*) into n from (select slug from col.cultivar_proposte group by 1 having count(*) > 1) x;
  if n > 0 then raise exception 'slug doppi: %', n; end if;
  -- categorie: 220 grex; i Gruppi sono Dunedin e i 2 epiteti che finiscono con Group
  select count(*) into n from col.cultivar_proposte where categoria = 'grex';
  if n <> 220 then raise exception 'grex: % (attesi 220)', n; end if;
  select count(*) into n from col.cultivar_proposte where categoria = 'gruppo';
  if n <> 3 then raise exception 'gruppi: % (attesi 3)', n; end if;
  -- cultivar di orchidea legate al loro grex (ICNCP art. 6.5)
  select count(*) into n from col.cultivar_proposte c join col.cultivar_proposte g on g.id = c.grex_id where g.categoria = 'grex';
  if n <> 295 then raise exception 'cultivar legate a un grex: % (attese 295)', n; end if;
  select count(*) into n from col.cultivar_proposte c where c.grex_id is not null
     and not exists (select 1 from col.cultivar_proposte g where g.id = c.grex_id and g.categoria = 'grex');
  if n > 0 then raise exception 'grex_id che non punta a un grex: %', n; end if;
  -- casi verificati nella ricerca (slug, epiteto, gruppo o nome commerciale, nome del taxon)
  for atteso in select * from (values
      ('symphyotrichum-novi-belgii-king', 'King''s College', null, 'Symphyotrichum novi-belgii'),
      ('alcea-rosea-s-double-group', 'Icicle', 'Chater''s Double Group', 'Alcea rosea'),
      ('brassia-rex', 'Rex', null, 'Brassia'),
      ('brachyglottis-dunedin-hybrids', 'Dunedin Group', null, 'Brachyglottis'),
      -- le cultivar delle piante dell'utente restano sulla loro specie o sul loro genere
      ('ficus-elastica-belize', 'Belize', null, 'Ficus elastica'),
      ('geranium-gerwat', 'Gerwat', 'Rozanne', 'Geranium'),
      ('mammillaria-elongata-d-one', 'D One', null, 'Mammillaria elongata'),
      ('muscari-armeniacum-manon', 'Manon', null, 'Muscari armeniacum'),
      ('narcissus-poeticus-recurvus', 'Recurvus', null, 'Narcissus poeticus'),
      ('tulipa-happy-generation', 'Happy Generation', null, 'Tulipa')
    ) v(slug, epiteto, altro, taxon) loop
    select count(*) into n from col.cultivar_proposte p
      left join public.taxa t on t.id = p.taxon_id left join col.nome_uso u on u.id = p.taxon_col_id
     where p.slug = atteso.slug and p.epiteto = atteso.epiteto
       and (atteso.altro is null or atteso.altro in (p.gruppo, p.nome_commerciale))
       and coalesce(t.nome_scientifico, u.nome) = atteso.taxon;
    if n <> 1 then raise exception 'caso %: atteso % su %', atteso.slug, atteso.epiteto, atteso.taxon; end if;
  end loop;
  -- cultivar di specie agganciate per errore al genere: passano alla specie del nome (ortensie, impatiens)
  select count(*) into n from col.cultivar_proposte p join public.specie s on s.id = p.vecchia_specie_id
    left join public.taxa t on t.id = p.taxon_id left join col.nome_uso u on u.id = p.taxon_col_id
   where s.nome_scientifico like 'Hydrangea macrophylla ''%' and coalesce(t.nome_scientifico, u.nome) <> 'Hydrangea macrophylla';
  if n > 0 then raise exception 'ortensie non su Hydrangea macrophylla: %', n; end if;
  select count(*) into n from col.cultivar_proposte p join public.specie s on s.id = p.vecchia_specie_id
   where s.nome_scientifico like 'Impatiens walleriana ''%' and p.taxon_col_id is null;
  if n > 0 then raise exception 'Impatiens walleriana non è tra i taxon da importare: %', n; end if;
  select count(distinct taxon_col_id) into n from col.cultivar_proposte where taxon_col_id is not null;
  if n <> 23 then raise exception 'specie da importare da COL: % (attese 23)', n; end if;
  -- righe fuse o illeggibili: solo mappa, esito ambiguo; doppie: mappa verso la gemella
  perform 1 from col.cultivar_mappa m join public.specie s on s.id = m.vecchia_specie_id
   where s.nome_scientifico = 'Calluna vulgaris ''Dart''' and m.esito = 'ambiguo' and m.cultivar_id is null;
  if not found then raise exception 'Calluna vulgaris ''Dart'' non è una riga di mappa ambigua'; end if;
  select count(*) into n from col.cultivar_mappa m join col.cultivar_proposte c on c.id = m.cultivar_id
   where m.origine = 'rollback' and m.esito = 'deciso dall''utente';
  if n <> 4 then raise exception 'cultivar doppie collegate alla gemella: % (attese 4)', n; end if;
  raise notice 'CULTIVAR CORRETTE: % cultivar, % righe di mappa, % specie da importare',
    (select count(*) from col.cultivar_proposte), (select count(*) from col.cultivar_mappa),
    (select count(distinct taxon_col_id) from col.cultivar_proposte where taxon_col_id is not null);
end $$;
