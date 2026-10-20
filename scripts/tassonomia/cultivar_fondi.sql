-- Fase 4a, dopo il caricamento: fusione dei doppioni probabili delle cultivar, chiesta dall'utente il 20/10/2026
-- («fondile tutte», pagina dei 143 gruppi di cultivar_doppioni.sql). Stessi gruppi: stesso taxon, stesso grex, stesso
-- epiteto a meno di maiuscole, apici tipografici, trattini e spazi. In ogni gruppo resta una cultivar: prima quella con
-- un Gruppo o un nome commerciale, poi quella il cui nome vecchio non ha descrittori (la base è il nome del taxon:
-- Aeonium 'Firecracker' e non Aeonium variegated 'Firecracker'), poi la prima per slug (tra due grafie, 'Jet Set' e
-- 'Jetset', i dati non dicono quale sia giusta). Gruppi e nomi commerciali delle altre passano a quella che resta. Le
-- altre diventano righe di mappa_specie verso la cultivar che resta (esito «deciso dall'utente», con la grafia della
-- riga nella nota), così nessuna riga di specie si perde. Corregge anche l'epiteto di Picea omorika 'Berliner's
-- Weeper' (rilievo M1 della revisione della fase 4a). Si può rilanciare: senza gruppi non cambia niente.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/cultivar_fondi.sql   (una transazione)
-- Dopo la fusione verifica_fase4a.sql non vale più: descrive lo stato subito dopo il caricamento.
set local statement_timeout = '10min';
create temp table membri on commit drop as
with c as (
  select c.*, lower(regexp_replace(translate(c.epiteto, '’‘´`-', ''''''''), '\s+', '', 'g')) as norm
    from public.cultivar c where c.categoria = 'cultivar'),
g as (
  select taxon_id, norm, coalesce(grex_id::text, '') as grex from c group by 1, 2, 3 having count(*) > 1)
select c.id, c.slug, c.epiteto, c.gruppo, c.nome_commerciale, c.vecchia_specie_id, s.nome_scientifico as vecchio,
       row_number() over w as ordine, first_value(c.id) over w as resta
  from g
  join c on c.taxon_id = g.taxon_id and c.norm = g.norm and coalesce(c.grex_id::text, '') = g.grex
  join public.specie s on s.id = c.vecchia_specie_id
  join public.taxa t on t.id = g.taxon_id
window w as (partition by g.taxon_id, g.norm, g.grex
             order by (c.gruppo is not null or c.nome_commerciale is not null) desc,
                      (btrim(split_part(s.nome_scientifico, '''', 1)) = t.nome_scientifico) desc, c.slug
             rows between unbounded preceding and unbounded following);
select set_config('fusioni.tolte', (select count(*) from membri where ordine > 1)::text, true) \g /dev/null

-- Gruppi e nomi commerciali di tutto il gruppo sulla cultivar che resta (valori distinti uniti con " | ")
create temp table unione on commit drop as
select m.resta,
       (select string_agg(distinct x, ' | ' order by x) from membri y cross join lateral unnest(string_to_array(y.gruppo, ' | ')) x
         where y.resta = m.resta) as gruppo,
       (select string_agg(distinct x, ' | ' order by x) from membri y cross join lateral unnest(string_to_array(y.nome_commerciale, ' | ')) x
         where y.resta = m.resta) as nome_commerciale
  from membri m group by m.resta;
update public.cultivar c set gruppo = u.gruppo, nome_commerciale = u.nome_commerciale
  from unione u
 where c.id = u.resta and (c.gruppo is distinct from u.gruppo or c.nome_commerciale is distinct from u.nome_commerciale);

insert into public.mappa_specie (vecchia_specie_id, vecchio_slug, vecchio_nome_scientifico, origine, cultivar_id, esito, nota)
select m.vecchia_specie_id, m.slug, m.vecchio, 'specie', m.resta, 'deciso dall''utente',
       'doppione fuso il 20/10/2026 su richiesta dell''utente nella cultivar ' || k.slug || ' (epiteto della riga: ''' || m.epiteto || ''')'
  from membri m join membri k on k.id = m.resta
 where m.ordine > 1;
delete from public.cultivar c using membri m where c.id = m.id and m.ordine > 1;

update public.cultivar set epiteto = 'Berliner''s Weeper'
 where slug = 'picea-omorika-berliner' and epiteto = 'Berliner''s Weeper'' witches';

do $$
declare n bigint;
begin
  -- nessun gruppo resta
  select count(*) into n from (
    select taxon_id, lower(regexp_replace(translate(epiteto, '’‘´`-', ''''''''), '\s+', '', 'g')), coalesce(grex_id::text, '')
      from public.cultivar where categoria = 'cultivar' group by 1, 2, 3 having count(*) > 1) x;
  if n > 0 then raise exception 'restano % gruppi di doppioni', n; end if;
  -- ogni riga cultivar di specie è una cultivar o una riga di mappa, mai le due cose
  select count(*) into n from public.specie s where s.nome_scientifico like '%''%'
     and (select count(*) from public.cultivar c where c.vecchia_specie_id = s.id)
       + (select count(*) from public.mappa_specie m where m.vecchia_specie_id = s.id) <> 1;
  if n > 0 then raise exception 'righe cultivar di specie senza cultivar e senza mappa, o con tutte e due: %', n; end if;
  -- le righe di mappa verso una cultivar vengono dai rollback o da una fusione
  select count(*) into n from public.mappa_specie m
   where m.cultivar_id is not null and m.origine <> 'rollback' and m.nota not like 'doppione fuso il %';
  if n > 0 then raise exception 'righe di mappa verso una cultivar che non vengono da rollback o fusioni: %', n; end if;
  if exists (select 1 from public.cultivar where slug = 'picea-omorika-berliner' and epiteto <> 'Berliner''s Weeper') then
    raise exception 'epiteto di picea-omorika-berliner non corretto';
  end if;
  raise notice 'FUSIONI OK: % cultivar tolte in questo giro; cultivar %, righe di mappa delle fusioni %',
    current_setting('fusioni.tolte'), (select count(*) from public.cultivar),
    (select count(*) from public.mappa_specie where nota like 'doppione fuso il %');
end $$;
