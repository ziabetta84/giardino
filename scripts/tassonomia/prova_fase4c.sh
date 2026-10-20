#!/usr/bin/env bash
# Prove della fase 4c (nomi comuni) sulla copia locale: rifiuti, file alterato, inventario incompleto, ripresa dopo un
# lotto fallito, caricamento, rilancio, rollback della 4a rifiutato con i soli nomi comuni presenti, rollback della 4c
# rifiutato se un nome è stato aggiunto, rollback eseguito, nuovo caricamento.
# Uso: bash scripts/tassonomia/prova_fase4c.sh URL_COPIA CARTELLA_ESPORTA CARTELLA      (CARTELLA nuova a ogni giro)
#   CARTELLA_ESPORTA = cartella scritta da nomi_esporta.sh. La copia deve avere la fase 4b applicata e nomi_comuni vuota.
# Uscita 0 = tutte le prove passate; alla fine la copia contiene il caricamento completo.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; E=${2:?manca CARTELLA_ESPORTA}; OUT=${3:?manca CARTELLA}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "Le prove girano solo sulla copia locale" >&2; exit 1; }
[ ! -e "$OUT" ] || { echo "La cartella $OUT esiste già: usarne una nuova" >&2; exit 1; }
D=scripts/tassonomia
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"
fallita() { echo "PROVA $1 FALLITA: $2" >&2; exit 1; }
conta() { "${PSQL[@]}" -tAc "select count(*) || ' ' || count(*) filter (where preferito) from public.nomi_comuni"; }
NOMI=$(awk -F'\t' '$1 ~ /^nomi_/ { s += $2 } END { print s }' "$E/manifest.tsv")
LOTTI=$(wc -l < "$E/manifest.tsv" | tr -d ' ')
PREFERITI=$(awk '$1 == "preferiti" { print $2 }' "$E/inventario.txt")
VUOTO="0 0"
PIENO="$NOMI $PREFERITI"
[ "$(conta)" = "$VUOTO" ] || fallita preparazione "nomi_comuni non è vuota ($(conta)): prima rollback_fase4c.sql"
[ "$("${PSQL[@]}" -tAc 'select count(*) from public.schede')" -gt 0 ] || fallita preparazione "la fase 4b non è applicata"
carica() {  # carica CARTELLA PROVA
  bash $D/carica_nomi.sh "$URL" "$E" "$OUT/$1" > "$OUT/$1.log" 2>&1 || fallita "$2" "carica_nomi: $(tail -3 "$OUT/$1.log")"
  [ "$(tail -1 "$OUT/$1.log")" = 'CARICAMENTO NOMI OK' ] || fallita "$2" "$(tail -3 "$OUT/$1.log")"
}

# 1. Rifiuti, prima di qualsiasi connessione.
out=$(bash $D/carica_nomi.sh 'postgresql://u:p@finto.pooler.supabase.com:5432/postgres' "$E" "$OUT/r1" 2>&1) \
  && fallita rifiuti "accettato il database reale senza conferma"
grep -qF 'RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si' <<<"$out" || fallita rifiuti "$out"
out=$(CONFERMO_CARICAMENTO_REALE=si bash $D/carica_nomi.sh 'postgresql://u:p@finto.pooler.supabase.com:6543/postgres' "$E" "$OUT/r2" 2>&1) \
  && fallita rifiuti "accettata la porta 6543"
grep -qF 'RIFIUTATO: serve la porta 5432' <<<"$out" || fallita rifiuti "$out"
echo "PROVA rifiuti OK"

# 2. File alterato e inventario incompleto: rifiuto prima di scrivere.
cp -R "$E" "$OUT/esporta_alterata"
printf 'x' >> "$OUT/esporta_alterata/nomi_01.csv"
out=$(bash $D/carica_nomi.sh "$URL" "$OUT/esporta_alterata" "$OUT/r3" 2>&1) && fallita alterato "nessun errore"
grep -qF 'RIFIUTATO: nomi_01.csv diverso da quello del manifesto' <<<"$out" || fallita alterato "$out"
cp -R "$E" "$OUT/esporta_senza_inventario"
grep -v '^inglesi ' "$E/inventario.txt" > "$OUT/esporta_senza_inventario/inventario.txt"
out=$(bash $D/carica_nomi.sh "$URL" "$OUT/esporta_senza_inventario" "$OUT/r3b" 2>&1) && fallita alterato "accettato un inventario incompleto"
grep -qF 'RIFIUTATO: inventario.txt senza inglesi' <<<"$out" || fallita alterato "$out"
[ "$(conta)" = "$VUOTO" ] || fallita alterato "caricato qualcosa: $(conta)"
echo "PROVA alterato OK"

# 3. Ripresa: il lotto fallisce (un nome già presente con lo stesso taxon, lingua e nome di una sua riga, ma un altro id) e
#    non entra niente; tolta la riga, il rilancio carica tutto.
"${PSQL[@]}" -c 'create temp table x (id uuid, taxon_id uuid, lingua text, nome text, preferito boolean, fonti text[], nota text)' \
  -c "\\copy x from '$E/nomi_01.csv' with (format csv, header)" \
  -c "insert into public.nomi_comuni (taxon_id, lingua, nome, fonti) select taxon_id, lingua, nome, '{prova}' from x where not preferito limit 1"
out=$(bash $D/carica_nomi.sh "$URL" "$E" "$OUT/r4" 2>&1) && fallita ripresa "nessun errore con il lotto in conflitto"
grep -qF 'duplicate key value' <<<"$out" || fallita ripresa "$out"
[ "$("${PSQL[@]}" -tAc "select count(*) from public.nomi_comuni")" = 1 ] || fallita ripresa "dopo il lotto fallito ci sono $(conta) nomi"
"${PSQL[@]}" -c "delete from public.nomi_comuni where fonti = '{prova}'"
carica r5 ripresa
[ "$(conta)" = "$PIENO" ] || fallita ripresa "stato inatteso: $(conta) invece di $PIENO"
echo "PROVA ripresa OK"

# 4. Rilancio: tutto saltato, stato invariato.
carica r6 rilancio
grep -qF 'nomi_01.csv già caricato' "$OUT/r6/tempi.txt" || fallita rilancio "lotto ricaricato"
[ "$(conta)" = "$PIENO" ] || fallita rilancio "stato cambiato: $(conta)"
echo "PROVA rilancio OK"

# 5. Il rollback della fase 4a si rifiuta anche con i soli nomi comuni presenti (schede tolte in una transazione mai
#    confermata).
out=$("${PSQL[@]}" -c 'begin' -c 'delete from public.schede' -f $D/rollback_fase4a.sql 2>&1) \
  && fallita rollback_4a "rollback della fase 4a accettato con i nomi comuni presenti"
grep -qF 'Rollback fase 4a rifiutato' <<<"$out" || fallita rollback_4a "$out"
[ "$("${PSQL[@]}" -tAc 'select count(*) from public.schede')" -gt 0 ] || fallita rollback_4a "schede tolte"
echo "PROVA rollback_4a OK"

# 6. Rollback della 4c: rifiutato se un nome è stato aggiunto dopo il caricamento (in una transazione mai confermata),
#    poi eseguito e seguito da un nuovo caricamento completo.
out=$("${PSQL[@]}" -c 'begin' -c "insert into public.nomi_comuni (taxon_id, lingua, nome, fonti, creato_il)
                                  select taxon_id, 'it', 'nome aggiunto per la prova', '{prova}', now() + interval '1 minute' from public.nomi_comuni limit 1" \
        -v lotti="$LOTTI" -f $D/rollback_fase4c.sql 2>&1) && fallita rollback "rollback accettato con un nome aggiunto"
grep -qF 'Rollback fase 4c rifiutato' <<<"$out" || fallita rollback "$out"
[ "$(conta)" = "$PIENO" ] || fallita rollback "un rollback rifiutato ha tolto righe: $(conta)"
"${PSQL[@]}" -1 -v lotti="$LOTTI" -f $D/rollback_fase4c.sql
"${PSQL[@]}" -c 'vacuum full public.nomi_comuni'
[ "$(conta)" = "$VUOTO" ] || fallita rollback "stato dopo il rollback: $(conta) invece di $VUOTO"
carica r7 rollback
[ "$(conta)" = "$PIENO" ] || fallita rollback "stato dopo il nuovo caricamento: $(conta)"
echo "PROVA rollback OK"
echo "PROVE FASE 4C OK"
