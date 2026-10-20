-- Fase 6 del modello tassonomico: l'app legge il nuovo catalogo. Funzioni di sola lettura, eseguite con i permessi di
-- chi chiama (security invoker): leggono solo colonne pubbliche di taxa, nomi_comuni, cultivar e schede, mai fonti,
-- note o identificatori interni. Le funzioni di servizio stanno nello schema catalogo, che PostgREST non espone.
-- piante.specie diventa facoltativa (le piante nuove si collegano solo a un taxon o a una cultivar) e il collegamento
-- diventa obbligatorio: esattamente uno tra taxon_id e cultivar_id (spec, sezione piante). Rollback:
--   psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase6.sql
-- Piano: docs/superpowers/plans/2026-10-20-modello-tassonomico-fase6-app.md
create schema catalogo;
revoke all on schema catalogo from public;
grant usage on schema catalogo to anon, authenticated;

-- Vuoto: null, testo vuoto, oppure oggetto o array fatto solo di valori vuoti (gli scheletri di PFAF)
create function catalogo.vuoto(v jsonb) returns boolean language plpgsql immutable set search_path = '' as $$
begin
  if v is null then return true; end if;
  case jsonb_typeof(v)
    when 'null' then return true;
    when 'string' then return btrim(v #>> '{}') = '';
    when 'object' then return not exists (select 1 from jsonb_each(v) e where not catalogo.vuoto(e.value));
    when 'array' then return not exists (select 1 from jsonb_array_elements(v) e(x) where not catalogo.vuoto(e.x));
    else return false;
  end case;
end $$;

-- Ranghi dal genere in giù (vocabolario di COL): quelli che la catena attraversa e che la ricerca mostra
create function catalogo.sotto_genere(rango text) returns boolean language sql immutable set search_path = '' as $$
  select rango in ('genus', 'subgenus', 'section botany', 'species aggregate', 'species', 'subspecies', 'variety',
                   'subvariety', 'form', 'subform', 'proles', 'lusus', 'infraspecific name', 'infrasubspecific name')
$$;

-- Autonimo: sottospecie, varietà o forma con l'epiteto della specie («Phedimus spurius subsp. spurius»)
create function catalogo.autonimo(rango text, nome text) returns boolean language sql immutable set search_path = '' as $$
  select rango in ('subspecies', 'variety', 'form') and split_part(nome, ' ', 2) = split_part(nome, ' ', 4)
$$;

-- Dove arriva un taxon: l'accettato; un sinonimo che porta a un autonimo arriva alla specie (ICN art. 26, decisione 1
-- della fase 4, come le schede e i nomi comuni)
create function catalogo.destinazione(t uuid) returns uuid language sql stable set search_path = '' as $$
  select case when x.id <> a.id and catalogo.autonimo(a.rango, a.nome_scientifico) and a.padre_id is not null
              then a.padre_id else a.id end
    from public.taxa x join public.taxa a on a.id = coalesce(x.accettato_id, x.id) where x.id = t
$$;

-- Tutti i padri di un taxon nella classificazione (per l'ambiguità dei nomi)
create function catalogo.antenati(t uuid) returns setof uuid language sql stable set search_path = '' as $$
  with recursive a(id, padre, n) as (
    select id, padre_id, 0 from public.taxa where id = t
    union all
    select p.id, p.padre_id, a.n + 1 from a join public.taxa p on p.id = a.padre where a.n < 40
  )
  select id from a where id <> t
$$;

-- Catena dell'eredità di un taxon: la sua destinazione (ord 0), poi i padri fino al genere compreso
create function catalogo.catena(t uuid) returns table (ord int, id uuid, rango text, nome_scientifico text)
language sql stable set search_path = '' as $$
  with recursive c(ord, id, rango, nome, padre) as (
    select 0, a.id, a.rango, a.nome_scientifico, a.padre_id from public.taxa a where a.id = catalogo.destinazione(t)
    union all
    select c.ord + 1, p.id, p.rango, p.nome_scientifico, p.padre_id from c join public.taxa p on p.id = c.padre
     where c.rango <> 'genus' and catalogo.sotto_genere(p.rango) and c.ord < 12
  )
  select ord, id, rango, nome from c
$$;

create function catalogo.preferito(t uuid) returns text language sql stable set search_path = '' as $$
  select nome from public.nomi_comuni where taxon_id = t and lingua = 'it' and preferito
$$;

-- Il nome è preferito anche di un taxon di un'altra linea, né antenato né discendente (decisione 22 della fase 4)
create function catalogo.ambiguo(nome text, t uuid) returns boolean language sql stable set search_path = '' as $$
  select exists (
    select 1 from public.nomi_comuni n
     where n.lingua = 'it' and n.preferito and n.nome = ambiguo.nome and n.taxon_id <> t
       and n.taxon_id not in (select catalogo.antenati(t))
       and t not in (select catalogo.antenati(n.taxon_id)))
$$;

-- Livelli dell'eredità di una voce: la cultivar (ord 0), il suo grex (ord 1), poi la catena del suo taxon
create function catalogo.livelli(chiave text) returns table (ord int, tipo text, id uuid, rango text, nome_scientifico text)
language plpgsql stable set search_path = '' as $$
declare
  i uuid; t uuid; g uuid; cat text; sci text; grex text;
begin
  begin
    i := split_part(chiave, ':', 2)::uuid;
  exception when invalid_text_representation then return;
  end;
  if split_part(chiave, ':', 1) = 't' then
    return query select c.ord, 'taxon'::text, c.id, c.rango, c.nome_scientifico from catalogo.catena(i) c;
  elsif split_part(chiave, ':', 1) = 'c' then
    select c.taxon_id, c.grex_id, c.categoria into t, g, cat from public.cultivar c where c.id = i;
    if not found then return; end if;
    select a.nome_scientifico into sci from public.taxa a where a.id = catalogo.destinazione(t);
    select c.epiteto into grex from public.cultivar c where c.id = g;
    return query select 0, 'cultivar'::text, i, cat, null::text;
    if g is not null then return query select 1, 'cultivar'::text, g, 'grex'::text, sci || ' ' || grex; end if;
    return query select c.ord + 2, 'taxon'::text, c.id, c.rango, c.nome_scientifico from catalogo.catena(t) c;
  end if;
end $$;

-- Una voce del catalogo: nome mostrato, nome scientifico, campi della scheda ereditati campo per campo
create function catalogo.voce(chiave text) returns jsonb language plpgsql stable set search_path = '' as $$
declare
  i uuid; t uuid; a uuid; a_rango text; a_sci text; noto text; nome text; base text; fornitore uuid;
  cat text; epiteto text; gruppo text; commerciale text; grex text; tipo text; altri jsonb; campi jsonb; livelli jsonb; stato text;
begin
  begin
    i := split_part(chiave, ':', 2)::uuid;
  exception when invalid_text_representation then return null;
  end;
  if split_part(chiave, ':', 1) = 't' then
    tipo := 'taxon'; t := i;
  elsif split_part(chiave, ':', 1) = 'c' then
    tipo := 'cultivar';
    select c.taxon_id, c.categoria, c.epiteto, c.gruppo, c.nome_commerciale, g.epiteto
      into t, cat, epiteto, gruppo, commerciale, grex
      from public.cultivar c left join public.cultivar g on g.id = c.grex_id where c.id = i;
    if not found then return null; end if;
  else
    return null;
  end if;
  a := catalogo.destinazione(t);
  if a is null then return null; end if;
  select x.rango, x.nome_scientifico into a_rango, a_sci from public.taxa x where x.id = a;
  select case when x.id <> a then x.nome_scientifico end into noto from public.taxa x where x.id = t;

  if tipo = 'taxon' then
    nome := catalogo.preferito(a);
    if nome is null and catalogo.autonimo(a_rango, a_sci) then        -- autonimo: il nome della specie
      nome := catalogo.preferito((select x.padre_id from public.taxa x where x.id = a));
    end if;
    nome := coalesce(nome, a_sci);
    select coalesce(jsonb_agg(n.nome order by n.nome), '[]') into altri
      from public.nomi_comuni n where n.taxon_id = a and n.lingua = 'it' and not n.preferito;
  else
    base := catalogo.preferito(a); fornitore := a;
    if base is null and a_rango <> 'genus' then
      select c.id into fornitore from catalogo.catena(a) c where c.rango = 'genus';
      base := catalogo.preferito(fornitore);
    end if;
    if base is not null and catalogo.ambiguo(base, fornitore) then base := null; end if;
    nome := case when cat = 'cultivar' then coalesce(base, a_sci) || coalesce(' ' || grex, '') || ' ''' || epiteto || ''''
                 else coalesce(base, a_sci) || ' ' || epiteto end;
    a_sci := case when cat = 'cultivar' then a_sci || coalesce(' ' || grex, '') || ' ''' || epiteto || ''''
                  else a_sci || ' ' || epiteto end;
    noto := case when cat = 'cultivar' then noto || coalesce(' ' || grex, '') || ' ''' || epiteto || '''' else noto || ' ' || epiteto end;
    altri := '[]';
  end if;

  with l as (select * from catalogo.livelli(chiave)),
  s as (
    select l.ord, l.rango, l.nome_scientifico, s.stato_verifica, s.descrizione, s.esigenze, s.manutenzione, s.ciclo_colturale,
           s.ciclo_vitale, s.vaso, s.alert, s.immagine
      from l join public.schede s on s.mostrata and l.tipo = 'taxon' and s.taxon_id = l.id
    union all
    select l.ord, l.rango, l.nome_scientifico, s.stato_verifica, s.descrizione, s.esigenze, s.manutenzione, s.ciclo_colturale,
           s.ciclo_vitale, s.vaso, s.alert, s.immagine
      from l join public.schede s on s.mostrata and l.tipo = 'cultivar' and s.cultivar_id = l.id
  ),
  e as (
    select s.ord, s.rango, s.nome_scientifico, s.stato_verifica, x.key, x.value
      from s, jsonb_each(jsonb_build_object('descrizione', s.descrizione, 'esigenze', s.esigenze, 'manutenzione', s.manutenzione,
             'coltivazione', s.ciclo_colturale, 'ciclo_vitale', s.ciclo_vitale, 'vaso', s.vaso, 'alert', to_jsonb(s.alert),
             'immagine', s.immagine)) x
     where not catalogo.vuoto(x.value)
  ),
  scelti as (select distinct on (key) * from e order by key, ord)
  select coalesce(jsonb_object_agg(key, value), '{}'),
         coalesce(jsonb_object_agg(key, jsonb_build_object('rango', rango, 'nome', nome_scientifico)) filter (where ord > 0), '{}'),
         max(stato_verifica) filter (where key = 'descrizione')
    into campi, livelli, stato from scelti;

  return campi || jsonb_strip_nulls(jsonb_build_object(
    'chiave', chiave, 'tipo', tipo, 'categoria', cat, 'rango', a_rango, 'nome', nome, 'specie', a_sci, 'nome_noto', noto,
    'gruppo', gruppo, 'nome_commerciale', commerciale, 'stato_verifica', stato))
    || jsonb_build_object('nomi_alternativi', altri, 'livelli', livelli);
end $$;

create function catalogo.voci(chiavi text[]) returns jsonb language sql stable set search_path = '' as $$
  select coalesce(jsonb_object_agg(k, v), '{}')
    from (select k, catalogo.voce(k) v from (select distinct unnest(chiavi) k) u) x where v is not null
$$;

create function public.catalogo_voci(chiavi text[]) returns jsonb language sql stable set search_path = '' as $$
  select catalogo.voci(chiavi[1:200])
$$;

-- Le voci delle piante di chi chiama: l'RLS di piante lascia vedere solo le sue
create function public.catalogo_mie_piante() returns jsonb language sql stable set search_path = '' as $$
  select catalogo.voci(array(
    select distinct case when cultivar_id is not null then 'c:' || cultivar_id else 't:' || taxon_id end
      from public.piante where num_nonnulls(taxon_id, cultivar_id) = 1))
$$;

-- Ricerca: nomi comuni italiani, nomi scientifici dal genere in giù (sinonimi verso l'accettato), epiteti e nomi
-- commerciali delle cultivar, «nome epiteto» (il primo termine trova i taxon, il resto l'epiteto delle loro cultivar).
-- Apici curvi resi dritti, tolti solo a inizio e fine parola («'Evergold'»), tenuti dentro le parole («dell'Egitto»).
-- Ogni ramo ordina prima del limite (nome uguale, poi che comincia così, poi più corto): «rosa» trova Rosa tra
-- migliaia di nomi che contengono «rosa». Meno di 2 caratteri utili: nessun risultato.
create function public.cerca_catalogo(q text) returns jsonb language plpgsql stable set search_path = '' as $$
declare
  testo text := btrim(regexp_replace(regexp_replace(regexp_replace(translate(coalesce(q, ''), '‘’‛`´', ''''''''''),
                  '["“”]', '', 'g'), '(^|\s)''+|''+(\s|$)', '\1\2', 'g'), '\s+', ' ', 'g'));
  pat text; inizio text; primo text; resto text;
begin
  if length(regexp_replace(testo, '[%_\\\s'']', '', 'g')) < 2 then return '[]'; end if;
  pat := '%' || regexp_replace(testo, '([\\%_])', '\\\1', 'g') || '%';
  inizio := regexp_replace(testo, '([\\%_])', '\\\1', 'g') || '%';
  if position(' ' in testo) > 0 and length(split_part(testo, ' ', 1)) >= 2 then
    primo := regexp_replace(split_part(testo, ' ', 1), '([\\%_])', '\\\1', 'g') || '%';
    resto := '%' || regexp_replace(substr(testo, position(' ' in testo) + 1), '([\\%_])', '\\\1', 'g') || '%';
  end if;
  return (
    with
    nc as (select n.taxon_id, n.nome, n.preferito from public.nomi_comuni n where n.lingua = 'it' and n.nome ilike pat
            order by lower(n.nome) = lower(testo) desc, n.nome ilike inizio desc, n.preferito desc, length(n.nome) limit 60),
    tx as (select t.nome_scientifico, t.stato, catalogo.destinazione(t.id) acc from public.taxa t
            where t.nome_scientifico ilike pat and catalogo.sotto_genere(t.rango)
            order by lower(t.nome_scientifico) = lower(testo) desc, t.nome_scientifico ilike inizio desc, t.stato = 'accepted' desc,
                     length(t.nome_scientifico) limit 60),
    cv as (select c.id, c.epiteto testo_cv from public.cultivar c where c.epiteto ilike pat or c.nome_commerciale ilike pat
            order by lower(c.epiteto) = lower(testo) desc, c.epiteto ilike inizio desc, length(c.epiteto) limit 60),
    -- due parole: i taxon del primo termine (nome scientifico o nome italiano), i loro figli e nipoti e i sinonimi
    -- se il primo termine è il nome esatto di qualcosa («rosmarino»), solo quei taxon: i nomi che cominciano così
    -- («Rosmarino selvatico»…) porterebbero migliaia di cultivar da filtrare
    t00 as (select x.id, x.esatto from (
             (select t.id, lower(t.nome_scientifico) = lower(rtrim(primo, '%')) esatto from public.taxa t
               where primo is not null and t.nome_scientifico ilike primo and catalogo.sotto_genere(t.rango)
               order by length(t.nome_scientifico) limit 20)
             union (select n.taxon_id, lower(n.nome) = lower(rtrim(primo, '%')) from public.nomi_comuni n
               where primo is not null and n.lingua = 'it' and n.nome ilike primo order by length(n.nome) limit 20)) x),
    t0 as (select catalogo.destinazione(id) id from t00 where esatto or not exists (select 1 from t00 where esatto)),
    t1 as (select t.id from public.taxa t where t.padre_id in (select id from t0)),
    t2 as (select t.id from public.taxa t where t.padre_id in (select id from t1)),
    tutti as (select id from t0 union select id from t1 union select id from t2),
    tsin as (select id from tutti union select t.id from public.taxa t where t.accettato_id in (select id from tutti)),
    cv2 as (select c.id from public.cultivar c where c.taxon_id in (select id from tsin) and c.epiteto ilike resto
             order by c.epiteto ilike substr(resto, 2) desc, length(c.epiteto) limit 60),
    cand as (
      select 't:' || nc.taxon_id k, case when not nc.preferito then nc.nome end via, false via_botanico, 0 gruppo,
             lower(nc.nome) = lower(testo) esatto, nc.nome ilike inizio prefisso, length(nc.nome) lung from nc
      union all
      select 't:' || tx.acc, case when tx.stato <> 'accepted' then tx.nome_scientifico end, tx.stato <> 'accepted', 0,
             lower(tx.nome_scientifico) = lower(testo), tx.nome_scientifico ilike inizio, length(tx.nome_scientifico) from tx
      union all select 'c:' || cv.id, null, false, 1, false, cv.testo_cv ilike inizio, length(cv.testo_cv) from cv
      union all select 'c:' || cv2.id, null, false, 1, true, true, 0 from cv2
    ),
    uniche as (select distinct on (k) * from cand order by k, esatto desc, (via is null) desc, prefisso desc, lung),
    prime as (select * from uniche order by esatto desc, prefisso desc, gruppo, (via is null) desc, lung, k limit 30),
    voci as (select p.*, catalogo.voce(p.k) v from prime p),
    -- prima le voci con contenuto verificato, poi in bozza, poi senza nessun contenuto (scelta dell'utente del 20/10/2026)
    classi as (select voci.*, case when not (v ?| array['descrizione', 'esigenze', 'manutenzione', 'coltivazione', 'ciclo_vitale',
                                                    'vaso', 'alert', 'immagine']) then 2
                                   when v ->> 'stato_verifica' = 'verificato' then 0 else 1 end classe
                 from voci where v is not null)
    select coalesce(jsonb_agg(v || jsonb_strip_nulls(jsonb_build_object('via', via, 'via_botanico', case when via is not null then via_botanico end))
                    order by classe, esatto desc, prefisso desc, gruppo, lung, v ->> 'nome'), '[]')
      from classi
  );
end $$;

revoke all on all functions in schema catalogo from public;
grant execute on all functions in schema catalogo to anon, authenticated;
revoke all on function public.catalogo_voci(text[]), public.catalogo_mie_piante(), public.cerca_catalogo(text) from public;
grant execute on function public.catalogo_voci(text[]), public.catalogo_mie_piante(), public.cerca_catalogo(text) to anon, authenticated;

alter table public.piante alter column specie drop not null;
alter table public.piante drop constraint piante_taxon_o_cultivar;
alter table public.piante add constraint piante_taxon_o_cultivar check (num_nonnulls(taxon_id, cultivar_id) = 1);
