#!/usr/bin/env bash
# Prepara dalla copia locale (schema col con COL26.9 XR completo, public.taxa identica al reale) la migration dei taxon
# di COL che mancano per le pagine RHS senza taxon, il suo rollback e l'elenco pagina RHS → accettato.
# Ingresso: scripts/rhs-import/dati/col_abbinamenti_rhs_assenti.tsv (esiti accettato e sinonimo con l'accettato non
# ancora in taxa). Uscita: supabase/migrations/20261123120000_rhs_taxa_nuovi_1.sql e 20261123120100_rhs_taxa_nuovi_2.sql,
# scripts/rhs-import/rollback_rhs_taxa_nuovi.sql, scripts/rhs-import/dati/rhs_taxa_nuovi_pagine.tsv.
# Ogni esecuzione assegna uuid nuovi: dopo aver applicato la migration non va rilanciato.
# Uso: bash scripts/rhs-import/rhs_taxa_nuovi.sh URL_COPIA
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "Si prepara solo dalla copia locale" >&2; exit 1; }
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
ABB=scripts/rhs-import/dati/col_abbinamenti_rhs_assenti.tsv
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# semi: rhs_id, col_id del nome trovato, col_id dell'accettato (colonne 1, 7, 12; esito in 6, già in taxa in 19)
awk -F'\t' 'NR>1 && ($6=="accettato" || $6=="sinonimo") && $19=="no" {print $1"\t"$7"\t"$12}' "$ABB" > "$TMP/semi.tsv"
"${PSQL[@]}" -c 'drop table if exists col.rhs_semi' -c 'create table col.rhs_semi (rhs_id text, col_id text, acc_col_id text)' \
  -c "\\copy col.rhs_semi from '$TMP/semi.tsv'"
"${PSQL[@]}" -f scripts/rhs-import/rhs_taxa_nuovi.sql

"${PSQL[@]}" -c 'set statement_timeout = 0' -c "
  copy (select m.id, m.col_id, m.origine, u.rango, u.nome as nome_scientifico, nullif(u.autore, '') as autore,
               nullif(split_part(lower(u.notho), ',', 1), '') as notho, u.status as stato,
               case when u.status in ('accepted', 'provisionally accepted') then nullif(u.parent_id, '') end as padre_col,
               case when u.status not in ('accepted', 'provisionally accepted') then nullif(u.parent_id, '') end as accettato_col
          from col.rhs_nuovi m join col.nome_uso u on u.id = m.col_id order by m.col_id)
  to stdout with (format csv, header)" > "$TMP/nuovi.csv"
rm -f supabase/migrations/2026112312*_rhs_taxa_nuovi*.sql
python3 -I scripts/rhs-import/rhs_taxa_nuovi_scrivi.py "$TMP/nuovi.csv" supabase/migrations/20261123120000_rhs_taxa_nuovi \
  scripts/rhs-import/rollback_rhs_taxa_nuovi.sql

# pagine RHS → accettato (per le schede): solo le pagine il cui accettato è tra i taxon nuovi
"${PSQL[@]}" -c "
  copy (select s.rhs_id, s.acc_col_id as accettato_col_id, u.nome as accettato_nome, u.rango as accettato_rango, m.id as accettato_taxon_id
          from col.rhs_semi s join col.rhs_nuovi m on m.col_id = s.acc_col_id join col.nome_uso u on u.id = s.acc_col_id
         order by s.rhs_id::bigint) to stdout with (format csv, delimiter E'\\t', header)" \
  > scripts/rhs-import/dati/rhs_taxa_nuovi_pagine.tsv
echo "pagine $(($(wc -l < scripts/rhs-import/dati/rhs_taxa_nuovi_pagine.tsv) - 1)) di $(wc -l < "$TMP/semi.tsv")"
