-- Rollback di supabase/migrations/20261030100000_schede_forma.sql: catalogo.voce torna alla versione della fase 6, poi via la colonna.
-- psql "$SUPABASE_DB_URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/immagini/forme/rollback_20261030100000_schede_forma.sql
create or replace function catalogo.voce(chiave text) returns jsonb language plpgsql stable set search_path = '' as $$
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

alter table public.schede drop column forma;
