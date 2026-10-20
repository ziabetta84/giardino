#!/usr/bin/env bash
# Fase 4c: prepara gli ingressi dei nomi comuni sulla copia locale e lancia nomi_proposte.sql.
# 1. esporta dalla copia le righe madri di specie e i nomi scientifici (taxa, specie, generi) in CARTELLA;
# 2. ricostruisce le fonti di ogni nome con nomi_provenienza.py (CARTELLA/provenienza.tsv);
# 3. estrae da COL XR i nomi italiani (VernacularName.tsv, lingua ita) in CARTELLA/col_ita.tsv;
# 4. li carica in col.nomi_provenienza e col.nomi_col_ita e lancia nomi_proposte.sql (che scrive col.nomi_proposte).
# Uso: bash scripts/tassonomia/nomi_proposte.sh URL_COPIA CARTELLA   (dalla radice del repository; COLZIP facoltativo)
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; OUT=${2:?manca CARTELLA}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "I nomi proposti si calcolano solo sulla copia locale" >&2; exit 1; }
COLZIP=${COLZIP:-$HOME/giardino-dati/col/xr_latest_coldp.zip}
[ -f "$COLZIP" ] || { echo "Manca $COLZIP (COL XR, fase 2)" >&2; exit 1; }
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"
"${PSQL[@]}" -c "\copy (select id, slug, nome, nome_scientifico, nomi_alternativi, stato_verifica, array_to_string(fonti, ' | ') from public.specie where specie_padre_id is null order by slug) to '$OUT/madri.tsv' with (format csv, delimiter E'\t', quote E'\x01')"
"${PSQL[@]}" -c "\copy (select distinct lower(regexp_replace(btrim(n), '\s+', ' ', 'g')) from (select nome_scientifico from public.taxa union select nome_scientifico from public.specie where specie_padre_id is null union select nome_scientifico from public.generi) x(n) order by 1) to '$OUT/nomi_scientifici.txt'"
python3 scripts/tassonomia/nomi_provenienza.py "$OUT/madri.tsv" "$OUT/nomi_scientifici.txt" > "$OUT/provenienza.tsv" 2> "$OUT/provenienza_riepilogo.txt"
unzip -p "$COLZIP" VernacularName.tsv | awk -F'\t' 'NR == 1 || $5 == "ita"' > "$OUT/col_ita.tsv"
echo "nomi ricostruiti: $(($(wc -l < "$OUT/provenienza.tsv") - 1)); nomi italiani di COL: $(($(wc -l < "$OUT/col_ita.tsv") - 1))"
"${PSQL[@]}" -c 'drop table if exists col.nomi_provenienza, col.nomi_col_ita' \
  -c 'create table col.nomi_provenienza (slug text, ruolo text, nome text, fonti text, note text, stato_verifica text, nome_scientifico text, tipo text, id uuid)' \
  -c "\copy col.nomi_provenienza from '$OUT/provenienza.tsv' with (format csv, delimiter E'\t', header true, quote E'\x01')" \
  -c 'create table col.nomi_col_ita (taxon_col text, source_id text, nome text, translit text, lingua text, preferito text, paese text, area text, sesso text, ref text, note text, modificato text, modificato_da text, fuso text)' \
  -c "\copy col.nomi_col_ita from '$OUT/col_ita.tsv' with (format csv, delimiter E'\t', header true, quote E'\x01')"
"${PSQL[@]}" -f scripts/tassonomia/nomi_proposte.sql
