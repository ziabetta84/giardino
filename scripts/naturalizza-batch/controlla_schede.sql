-- Controlli automatici su un lotto di schede già scritto (issue #153). Tutti i conteggi tranne `totale` devono essere 0.
-- Uso: psql "$SUPABASE_DB_URL" -X -v ids="{id1,id2,...}" -f controlla_schede.sql
-- Gli id sono in lottoN_schede.json:  python3 -c "import json;print('{'+','.join(r['id'] for r in json.load(open('lottoN_schede.json')))+'}')"
-- I controlli a regex non bastano: dopo, leggere per intero almeno 4-5 schede (vedi .claude/commands/naturalizza-lotto.md).
with l as (select s.* from public.schede s where s.id = any(:'ids'::uuid[]))
select
  count(*) as totale,
  count(*) filter (where descrizione ~* '\m(the|with|are|which|leaves|flowers)\M') as descrizione_inglese,
  count(*) filter (where exists (select 1 from unnest(alert) a where a ~ '\(testo in inglese\)' and a !~ '^Rischi \(testo in inglese\)'))
    as avvisi_inglese,
  count(*) filter (where descrizione ~ '\m(RHS|PFAF|Le Georgiche)\M' or descrizione ~* '\m(la fonte|una fonte|secondo la|la scheda)\M')
    as fonte_citata,
  count(*) filter (where exists (select 1 from unnest(alert) a where a ~ '\m(RHS|PFAF)\M' or a ~* '\m(see|please)\M|note di coltivazione'))
    as fonte_o_rimando_negli_avvisi,
  count(*) filter (where descrizione ~* '^(Colore di fioritura|Periodi? di fioritura|Portamento|Forma|Famiglia botanica)\s*:')
    as etichette_in_prosa,
  count(*) filter (where descrizione ~ '\mH(1[abcABC]|[2-7])\M') as codice_h_in_prosa,
  count(*) filter (where descrizione ~* '\mverificat[ao]\M') as nota_editoriale,
  count(*) filter (where descrizione ~ '^Specie appartiene') as specie_appartiene,
  count(*) filter (where descrizione ~* 'non solo .* ma anche|un vero e proprio|regalando|cornice ideale|vero gioiello') as tic,
  count(*) filter (where descrizione is null or btrim(descrizione) = '') as descrizione_vuota,
  count(*) filter (where (select count(*) from unnest(alert) a where a ~ '^Rusticità:') > 1
                      or (select count(*) from unnest(alert) a where a ~ '^Dimensioni a maturità:') > 1
                      or (select count(*) from unnest(alert) a where a ~ '^Parassiti') > 1
                      or (select count(*) from unnest(alert) a where a ~ '^Potatura') > 1
                      or (select count(*) from unnest(alert) a where a ~ '^Propagazione') > 1) as voci_doppie,
  count(*) filter (where exists (select 1 from unnest(alert) a where a ~ '^Nome comune')) as nome_comune_negli_avvisi,
  count(*) filter (where exists (select 1 from unnest(alert) a where a ~* '\mgrupp[oi] (di potatura )?\d+')) as numero_gruppo_potatura
from l;
