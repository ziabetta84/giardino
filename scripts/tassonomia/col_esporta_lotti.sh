#!/usr/bin/env bash
# Fase 2: scrive i lotti da caricare in public.taxa a partire da col.selezione (copia locale). I CSV contengono i
# valori definitivi: chiavi uuid, padri e accettati già risolti, così il caricamento è un solo passaggio senza
# aggiornamenti (specifica, "Decisioni sullo spazio", punto 5). lotto_01.csv = gli accettati (la classificazione: i
# padri stanno tutti nello stesso lotto), poi i sinonimi in lotti da al massimo 110.000 righe, circa 40 MB di WAL
# ciascuno: i sinonimi puntano agli accettati del lotto 1. manifest.tsv (file, righe, sha256, primo col_id) fissa i
# lotti provati; non_trovati.tsv elenca le righe di specie senza corrispondenza, per la fase 3.
# Uso: bash scripts/tassonomia/col_esporta_lotti.sh URL_COPIA CARTELLA VERSIONE      (VERSIONE es. "COL26.9 XR")
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; DIR=${2:?manca CARTELLA}; VERSIONE=${3:?manca VERSIONE}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "I lotti si preparano solo dalla copia locale" >&2; exit 1; }
[[ $VERSIONE =~ ^COL[0-9.]+\ XR$ ]] || { echo "Versione non valida: $VERSIONE" >&2; exit 1; }
[ ! -e "$DIR" ] || { echo "La cartella $DIR esiste già: i lotti provati non si sovrascrivono" >&2; exit 1; }
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
MASSIMO=110000
mkdir -p "$DIR"
echo "$VERSIONE" > "$DIR/versione.txt"

"${PSQL[@]}" -c 'set statement_timeout = 0' -c 'drop table if exists col.lotti' -c "
  create table col.lotti as
  with sin as (select s.col_id from col.selezione s join col.nome_uso u on u.id = s.col_id
                where u.status not in ('accepted', 'provisionally accepted')),
       parti as (select ceil(count(*)::numeric / $MASSIMO)::int as n from sin)
  select s.col_id, 1 as lotto from col.selezione s join col.nome_uso u on u.id = s.col_id
   where u.status in ('accepted', 'provisionally accepted')
  union all
  select col_id, 1 + ntile((select n from parti)) over (order by col_id) from sin"

SELEZIONE="select s.id, 'col' as origine, s.col_id, '$VERSIONE' as versione_col, u.rango, u.nome as nome_scientifico,
                  nullif(u.autore, '') as autore, nullif(split_part(lower(u.notho), ',', 1), '') as notho, u.status as stato,
                  case when u.status in ('synonym', 'ambiguous synonym', 'misapplied') then p.id end as accettato_id,
                  case when u.status in ('accepted', 'provisionally accepted') then p.id end as padre_id
             from col.selezione s
             join col.nome_uso u on u.id = s.col_id
             join col.lotti l on l.col_id = s.col_id
             left join col.selezione p on p.col_id = nullif(u.parent_id, '')"
ultimo=$("${PSQL[@]}" -tAc 'select max(lotto) from col.lotti')
for k in $(seq 1 "$ultimo"); do
  file=$(printf 'lotto_%02d.csv' "$k")
  "${PSQL[@]}" -c 'set statement_timeout = 0' \
    -c "copy ($SELEZIONE where l.lotto = $k order by s.col_id) to stdout with (format csv, header)" > "$DIR/$file"
  righe=$(( $(wc -l < "$DIR/$file") - 1 ))
  primo=$(sed -n 2p "$DIR/$file" | cut -d, -f3)
  [[ $primo =~ ^[A-Za-z0-9]+$ ]] || { echo "col_id inatteso nel primo record di $file: $primo" >&2; exit 1; }
  printf '%s\t%s\t%s\t%s\n' "$file" "$righe" "$(shasum -a 256 "$DIR/$file" | cut -d' ' -f1)" "$primo" >> "$DIR/manifest.tsv"
done
"${PSQL[@]}" -c 'set statement_timeout = 0' -c "
  copy (select s.slug, s.nome_scientifico from public.specie s
         where s.nome_scientifico !~ ''''
           and not exists (select 1 from col.corrispondenze c where c.chiave = col.chiave(s.nome_scientifico))
         order by s.nome_scientifico, s.slug) to stdout with (format text, header)" > "$DIR/non_trovati.tsv"
cat "$DIR/manifest.tsv" | cut -f1,2,4
echo "non_trovati $(( $(wc -l < "$DIR/non_trovati.tsv") - 1 ))"
