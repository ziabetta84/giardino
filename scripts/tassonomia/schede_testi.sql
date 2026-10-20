-- Fase 4b: funzioni che tolgono le fonti citate dentro i testi delle schede (specifica, "Decisioni dopo la verifica",
-- punti 11-12, e "Decisioni per la fase 4", punti 9-14). Si usano nella SELECT che alimenta le schede, mai con un
-- aggiornamento dopo l'inserimento (decisione sullo spazio 5). Solo copia locale (schema col).
-- - avvisi (alert, text[]): via l'avviso di bozza PFAF e i nomi comuni inglesi (vanno in nomi_comuni nella fase 4c);
--   i rischi PFAF diventano «Rischi (testo in inglese):» senza i rimandi numerici, «None known» «Rischi: nessuno noto»;
--   i dati di coltivazione restano con prefissi fissi; la rusticità RHS diventa la frase in gradi della fascia meno
--   rustica; le note tassonomiche o sul libro vanno nella nota interna;
-- - descrizioni: via le etichette «Da RHS (testo originale in inglese):», «Descrizione del genere:» resta; la coda
--   inglese di una descrizione italiana si taglia (resta in descrizione_originale); le note di lavorazione (IPNI,
--   aggiornamenti PFAF, identificazione RHS non confermata) vanno nella nota interna;
-- - esigenze: via «Non specificato dalla fonte»; immagine: via la chiave costante «fonte», via i parametri utm
--   dall'indirizzo, l'autore «No machine-readable author provided. X assumed» diventa X.
-- Le righe che nessuna regola copre si correggono a mano (dati/fase4_schede_a_mano.tsv).

-- fasce ufficiali di rusticità RHS (minima invernale): H1a oltre 15 °C … H7 sotto -20 °C
create or replace function col.rusticita_frase(a text) returns text language sql immutable parallel safe as $$
  select 'Rusticità: minime ' || case min(o)
           when 1 then 'non sotto i 15 °C' when 2 then 'non sotto i 10 °C' when 3 then 'non sotto i 5 °C'
           when 4 then 'non sotto 1 °C' when 5 then 'fino a -5 °C' when 6 then 'fino a -10 °C' when 7 then 'fino a -15 °C'
           when 8 then 'fino a -20 °C' when 9 then 'anche sotto i -20 °C' end
    from regexp_matches(upper(substring(a from '^Rusticit. RHS: ([^(]*)')), '(H1[ABC]|H[2-7])', 'g') m
    cross join lateral (select array_position(array['H1A','H1B','H1C','H2','H3','H4','H5','H6','H7'], m[1]) as o) x
  having count(*) > 0
$$;

create or replace function col.togli_virgolette(t text) returns text language sql immutable parallel safe as $$
  select regexp_replace(t, ': "([^"]*)"', ': \1', 'g')
$$;

-- tipo di un elemento degli avvisi: N = nota interna, X = tolto, A = resta (trasformato)
create or replace function col.alert_tipo(a text) returns text language sql immutable parallel safe as $$
  select case
    when a ~ '^Scheda in bozza, importata automaticamente da Plants For A Future' then 'X'
    when a ~ '^Nome comune \(' then 'X'
    when a ~* '^la fonte non riporta il simbolo di tossicit' or a ~* 'il libro riporta' or a ~* '^nota tassonomica' then 'N'
    else 'A' end
$$;

create or replace function col.alert_elemento(a text) returns text language sql immutable parallel safe as $$
  select case
    when col.alert_tipo(a) <> 'A' then null
    when a ~ '^Rischi segnalati dalla fonte \(testo originale in inglese' and a ~* ': None known\.?\s*$' then 'Rischi: nessuno noto'
    when a ~ '^Rischi segnalati dalla fonte \(testo originale in inglese' then
      btrim(regexp_replace(regexp_replace(
        regexp_replace(a, '^Rischi segnalati dalla fonte \(testo originale in inglese, non tradotto per non alterarne il significato\): ',
                       'Rischi (testo in inglese): '),
        '\[K Plants for a Future[^]]*\]', '', 'gi'),
        '[[:space:] ]*\[[[:space:] ]*(\[?[0-9]{1,4}(-[0-9]{1,4})?|K)([[:space:] ]*,[[:space:] ]*([0-9]{1,4}|K))*[[:space:] ]*\]', '', 'g'))
    when a ~ '^Rischi segnalati dalla fonte: nessun rischio noto' or a ~ '^Nessun rischio noto segnalato dalla fonte' then 'Rischi: nessuno noto'
    when a ~ '^Rischi segnalati dalla fonte' then regexp_replace(a, '^Rischi segnalati dalla fonte: ', 'Rischi: ')
    when a ~ '^Dimensioni RHS a maturit' then regexp_replace(a, '^Dimensioni RHS a maturità: ', 'Dimensioni a maturità: ')
    when a ~ '^Rusticit. RHS' then coalesce(col.rusticita_frase(a), a)
    when a ~ '^(Propagazione|Potatura) \(RHS, testo originale in inglese\)' then
      col.togli_virgolette(regexp_replace(a, '^(Propagazione|Potatura) \(RHS, testo originale in inglese\): ', '\1 (testo in inglese): '))
    when a ~ '^(Propagazione|Potatura)' then
      col.togli_virgolette(
        regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(a,
          '^(Propagazione|Potatura) \(RHS\): ', '\1: '),
          ' \((classificazione RHS)\)', '', 'g'),
          ',? (della )?classificazione RHS', '', 'g'),
          ' \(([^()]*), classificazione RHS\)', ' (\1)', 'g'),
          'gruppo di potatura RHS ', 'gruppo di potatura ', 'gi'))
    when a ~ '^Da RHS \(testo originale in inglese\)' then
      col.togli_virgolette(regexp_replace(a, '^Da RHS \(testo originale in inglese\) — (Parassiti|Malattie): ', '\1 (testo in inglese): '))
    when a ~ '^Da RHS' or a ~ '^Parassiti \(RHS' then
      col.togli_virgolette(regexp_replace(regexp_replace(a, '^Da RHS — ', ''), '(Parassiti|Malattie) \(RHS\): ', '\1: ', 'g'))
    when a ~ '^(Parassiti|Malattie)' then col.togli_virgolette(a)
    when a ~* 'simbolo[^)]*nel libro' and a ~* 'velenos|tossic' and a !~* 'non specificamente' then regexp_replace(a, ' \(simbolo[^)]*nel libro\)', '')
    else a end
$$;

create or replace function col.alert_pulito(al text[]) returns text[] language sql immutable parallel safe as $$
  select case when al is null then null
              else coalesce((select array_agg(col.alert_elemento(x) order by o) from unnest(al) with ordinality u(x, o)
                              where col.alert_elemento(x) is not null), '{}') end
$$;

create or replace function col.alert_nota(al text[]) returns text language sql immutable parallel safe as $$
  select string_agg(x, ' | ' order by o) from unnest(al) with ordinality u(x, o) where col.alert_tipo(x) = 'N'
$$;

create or replace function col.descrizione_pulita(d text) returns text language sql immutable parallel safe as $$
  with u as (
    select case
      when d ~ '^Da RHS, descrizione del genere \(testo originale in inglese\): ' then
        regexp_replace(regexp_replace(d, '^Da RHS, descrizione del genere \(testo originale in inglese\): "', 'Descrizione del genere: '), '\.?"\.?\s*$', '.')
      when d ~ '^Da RHS \(testo originale in inglese\): ' then
        regexp_replace(regexp_replace(d, '^Da RHS \(testo originale in inglese\): "', ''), '\.?"\.?\s*$', '.')
      when d ~ '.Da RHS(, descrizione del genere)? \(testo originale in inglese\): ' then
        btrim(regexp_replace(d, '\s*Da RHS(, descrizione del genere)? \(testo originale in inglese\): ".*$', ''))
      else d end as d1),
  v as (
    select regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(d1,
      '"?\.?\s*Identificazione RHS non confermata \([^)]*\)[^.]*\.', '', 'g'),
      '\s*See the RHS pages on [^".]*(for further details)?\.?', '', 'g'),
      '\s*\((le fonti|la fonte|il testo originale)\M[^)]*\)', '', 'gi'),
      '\s*(Aggiornamento: )?[^.]*(International Plant Names? Index|\mIPNI\M).*$', '', 'g'),
      '\s*\m(UPDATE|Update|Aggiornamento)\M( del)?[^:\n]{0,25}:[^\n]*', '', 'g'),
      '\s+—\s+le fonti riportano[^.;]*', '', 'gi') as d1b, d1 from u)
  select case when d is null then null when d1b = d then d else regexp_replace(btrim(d1b), '([^.])\.\.$', '\1.') end from v
$$;

create or replace function col.descrizione_nota(d text) returns text language sql immutable parallel safe as $$
  select nullif(concat_ws(' | ',
    substring(d from '(Identificazione RHS non confermata[^—]*—[^.]*\.)'),
    substring(d from '((?:Aggiornamento: )?[^.]*(?:International Plant Names? Index|\mIPNI\M).*$)'),
    substring(d from '(\m(?:UPDATE|Update|Aggiornamento)\M(?: del)?[^:\n]{0,25}:[^\n]*)')), '')
$$;

create or replace function col.esigenze_pulite(e jsonb) returns jsonb language sql immutable parallel safe as $$
  select case when e is null or jsonb_typeof(e) <> 'object' then e else
    coalesce((select jsonb_object_agg(k, case when jsonb_typeof(v) = 'string'
                                              then to_jsonb(regexp_replace(v #>> '{}', '^Non specificato dalla fonte;\s*', ''))
                                              else v end)
                from jsonb_each(e) x(k, v)
               where not (jsonb_typeof(v) = 'string' and btrim(v #>> '{}') = 'Non specificato dalla fonte')), '{}'::jsonb) end
$$;

create or replace function col.immagine_pulita(i jsonb) returns jsonb language sql immutable parallel safe as $$
  select case when i is null or jsonb_typeof(i) <> 'object' then i else
    (i - 'fonte')
    || case when i ? 'url' then jsonb_build_object('url', regexp_replace(i->>'url', '\?utm_source=[^#]*$', '')) else '{}'::jsonb end
    || case when coalesce(i->>'attribuzione', '') ~ '^No machine-readable author provided\. .+ assumed'
            then jsonb_build_object('attribuzione', substring(i->>'attribuzione' from '^No machine-readable author provided\. (.+?) assumed'))
            else '{}'::jsonb end end
$$;
