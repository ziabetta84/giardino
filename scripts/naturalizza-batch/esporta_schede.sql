-- Esporta un lotto di schede ancora da tradurre e naturalizzare (issue #153, dopo il passaggio al modello tassonomico).
-- Uso (lo lancia esporta_schede.py): psql "$SUPABASE_DB_URL" -X -t -A -v limite=70 -f esporta_schede.sql
--
-- Una scheda è da fare se è mostrata e:
--   - la descrizione è ancora il testo RHS in inglese (coincide con l'inizio della citazione tra virgolette in
--     descrizione_originale; un corpo italiano a cui la fase 4b ha tagliato la coda inglese non conta), oppure
--   - la descrizione ha parole inglesi comuni (prosa PFAF o RHS non marcata), oppure
--   - un avviso è ancora «X (testo in inglese): …», tranne «Rischi (testo in inglese)», che resta in inglese per scelta
--     dell'utente (dati di sicurezza, traduzione rimandata a un giro dedicato).
-- Ordine: prima le schede che l'utente vede per le sue piante (a qualunque livello dell'eredità), poi quelle con una
-- foto (indizio di notorietà, come il vecchio ordine «popolarita»), poi le altre; a caso a parità di gruppo.
-- Le schede non mostrate non entrano: non arrivano mai nell'app.
with mie_livelli as materialized (
  select distinct l.tipo, l.id
    from public.piante p
   cross join lateral catalogo.livelli(case when p.cultivar_id is not null then 'c:' || p.cultivar_id else 't:' || p.taxon_id end) l
),
candidate as (
  select s.*,
         (s.descrizione_originale ilike '%testo originale in inglese%'
          and strpos(s.descrizione_originale, ': "' || left(regexp_replace(s.descrizione, '^Descrizione del genere: ', ''), 80)) > 0)
         as descrizione_rhs,
         s.descrizione ~* '\m(the|with|are|which|leaves|flowers)\M' as descrizione_parole_en,
         exists (select 1 from unnest(s.alert) a where a ~ '\(testo in inglese\)' and a !~ '^Rischi \(testo in inglese\)') as alert_en,
         exists (select 1 from mie_livelli m
                  where (m.tipo = 'taxon' and s.taxon_id = m.id) or (m.tipo = 'cultivar' and s.cultivar_id = m.id)) as mia
    from public.schede s
   where s.mostrata
),
lotto as (
  select c.* from candidate c
   where c.descrizione_rhs or c.descrizione_parole_en or c.alert_en
   order by c.mia desc, (c.immagine is not null) desc, random()
   limit :limite
)
select coalesce(json_agg(json_build_object(
         'id', l.id,
         'livello', case when l.cultivar_id is not null then 'cultivar' else t.rango end,
         'nome_scientifico', case when l.cultivar_id is not null
                                  then ct.nome_scientifico || ' ''' || cv.epiteto || '''' else t.nome_scientifico end,
         'famiglia', (select f.nome_scientifico from public.taxa f
                       where f.rango = 'family' and f.id in (select catalogo.antenati(coalesce(l.taxon_id, cv.taxon_id)))
                       limit 1),
         'mia', l.mia,
         'da_fare', json_build_object('descrizione', l.descrizione_rhs or l.descrizione_parole_en, 'alert', l.alert_en),
         'descrizione', l.descrizione,
         'descrizione_originale', l.descrizione_originale,
         'alert', l.alert,
         'esigenze', l.esigenze,
         'ciclo_vitale', l.ciclo_vitale,
         'aggiornata_il', l.aggiornata_il
       ) order by l.mia desc, l.id), '[]')
  from lotto l
  left join public.taxa t on t.id = l.taxon_id
  left join public.cultivar cv on cv.id = l.cultivar_id
  left join public.taxa ct on ct.id = cv.taxon_id;
