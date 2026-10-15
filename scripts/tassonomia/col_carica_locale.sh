#!/usr/bin/env bash
# Carica nello schema col della copia locale le colonne di NameUsage.tsv (COL XR, formato ColDP) che servono alla
# selezione della fase 2: ID, parentID, status, scientificName, authorship, rank, notho, code, kingdom. Sono circa
# 8,5 milioni di righe (1,2 GB): COL completo non entra mai nel database reale. Il file è un TSV senza virgolette,
# con le sole sequenze \t \n \\ (stesso formato di COPY text). I campi vuoti restano stringhe vuote.
# Uso: bash scripts/tassonomia/col_carica_locale.sh ZIP URL_COPIA
set -euo pipefail
cd "$(dirname "$0")/../.."
ZIP=${1:?manca ZIP}; URL=${2:?manca URL della copia locale}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "COL si carica solo nella copia locale" >&2; exit 1; }
[ -f "$ZIP" ] || { echo "File non trovato: $ZIP" >&2; exit 1; }
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)

# Le colonne si cercano per nome e devono comparire in quest'ordine (lo stesso della tabella col.nome_uso).
intestazione=$(unzip -p "$ZIP" NameUsage.tsv | head -1 || true)
trovate=$(tr '\t' '\n' <<<"$intestazione" | grep -nxE 'col:(ID|parentID|status|scientificName|authorship|rank|notho|code|kingdom)' || true)
[ "$(cut -d: -f3 <<<"$trovate" | paste -sd, -)" = "ID,parentID,status,scientificName,authorship,rank,notho,code,kingdom" ] \
  || { echo "Formato di NameUsage.tsv inatteso: $(cut -d: -f3 <<<"$trovate" | paste -sd, -)" >&2; exit 1; }
posizioni=$(cut -d: -f1 <<<"$trovate" | paste -sd, -)

"${PSQL[@]}" -c 'drop schema if exists col cascade' -c 'create schema col' \
  -c 'create table col.nome_uso (id text, parent_id text, status text, nome text, autore text, rango text, notho text, codice text, regno text)'
unzip -p "$ZIP" NameUsage.tsv | tail -n +2 | cut -f"$posizioni" \
  | "${PSQL[@]}" -c 'set statement_timeout = 0' -c 'copy col.nome_uso from stdin'
"${PSQL[@]}" -c 'set statement_timeout = 0' -c 'alter table col.nome_uso add primary key (id)' \
  -c 'create index nome_uso_parent_id_idx on col.nome_uso (parent_id)' -c 'analyze col.nome_uso'
"${PSQL[@]}" -tAc "select 'righe ' || count(*) from col.nome_uso"
