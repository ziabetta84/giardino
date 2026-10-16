#!/usr/bin/env bash
# Fase 3: carica nello schema col della copia locale il basionimo di ogni nome di COL (colonna basionymID di
# NameUsage.tsv), per la regola del sinonimo omotipico (ICN art. 49: due nomi sono omotipici se hanno lo stesso tipo,
# cioè lo stesso basionimo, o se uno è il basionimo dell'altro). Tabella col.basionimi (id, basionimo), solo le righe
# con il basionimo. Si aggiunge a col_carica_locale.sh, che non va rilanciato: ricrea lo schema col.
# Uso: bash scripts/tassonomia/col_carica_basionimi.sh ZIP URL_COPIA
set -euo pipefail
cd "$(dirname "$0")/../.."
ZIP=${1:?manca ZIP}; URL=${2:?manca URL della copia locale}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "COL si carica solo nella copia locale" >&2; exit 1; }
[ -f "$ZIP" ] || { echo "File non trovato: $ZIP" >&2; exit 1; }
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)

intestazione=$(unzip -p "$ZIP" NameUsage.tsv | head -1 || true)
trovate=$(tr '\t' '\n' <<<"$intestazione" | grep -nxE 'col:(ID|basionymID)' || true)
[ "$(cut -d: -f3 <<<"$trovate" | paste -sd, -)" = "ID,basionymID" ] \
  || { echo "Formato di NameUsage.tsv inatteso: $(cut -d: -f3 <<<"$trovate" | paste -sd, -)" >&2; exit 1; }
posizioni=$(cut -d: -f1 <<<"$trovate" | paste -sd, -)

"${PSQL[@]}" -c 'drop table if exists col.basionimi' -c 'create table col.basionimi (id text, basionimo text)'
unzip -p "$ZIP" NameUsage.tsv | tail -n +2 | cut -f"$posizioni" | awk -F'\t' '$2 != ""' \
  | "${PSQL[@]}" -c 'set statement_timeout = 0' -c 'copy col.basionimi from stdin'
"${PSQL[@]}" -c 'set statement_timeout = 0' -c 'alter table col.basionimi add primary key (id)' \
  -c 'create index basionimi_basionimo_idx on col.basionimi (basionimo)' -c 'analyze col.basionimi'
"${PSQL[@]}" -tAc "select 'basionimi ' || count(*) || ', senza nome in col.nome_uso '
                   || count(*) filter (where not exists (select 1 from col.nome_uso u where u.id = b.basionimo)) from col.basionimi b"
