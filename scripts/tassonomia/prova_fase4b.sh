#!/usr/bin/env bash
# Prove della fase 4b (schede) sulla copia locale: rifiuti, file alterato, ripresa dopo un lotto fallito, caricamento,
# rilancio, rollback della 4a rifiutato con le schede presenti, rollback della 4b rifiutato se una scheda è stata
# modificata, rollback eseguito, nuovo caricamento.
# Uso: bash scripts/tassonomia/prova_fase4b.sh URL_COPIA CARTELLA_ESPORTA CARTELLA      (CARTELLA nuova a ogni giro)
#   CARTELLA_ESPORTA = cartella scritta da schede_esporta.sh. La copia deve avere la fase 4a applicata e schede vuota.
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
conta() { "${PSQL[@]}" -tAc "select count(*) || ' ' || count(*) filter (where mostrata) from public.schede"; }
SCHEDE=$(awk -F'\t' '$1 ~ /^schede_/ { s += $2 } END { print s }' "$E/manifest.tsv")
MOSTRATE=$(cat "$E/mostrate.txt")
VUOTO="0 0"
PIENO="$SCHEDE $MOSTRATE"
[ "$(conta)" = "$VUOTO" ] || fallita preparazione "schede non è vuota ($(conta)): prima rollback_fase4b.sql"
[ "$("${PSQL[@]}" -tAc 'select count(*) from public.cultivar')" -gt 0 ] || fallita preparazione "la fase 4a non è applicata"
carica() {  # carica CARTELLA PROVA
  bash $D/carica_schede.sh "$URL" "$E" "$OUT/$1" > "$OUT/$1.log" 2>&1 || fallita "$2" "carica_schede: $(tail -3 "$OUT/$1.log")"
  [ "$(tail -1 "$OUT/$1.log")" = 'CARICAMENTO SCHEDE OK' ] || fallita "$2" "$(tail -3 "$OUT/$1.log")"
}

# 1. Rifiuti, prima di qualsiasi connessione.
out=$(bash $D/carica_schede.sh 'postgresql://u:p@finto.pooler.supabase.com:5432/postgres' "$E" "$OUT/r1" 2>&1) \
  && fallita rifiuti "accettato il database reale senza conferma"
grep -qF 'RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si' <<<"$out" || fallita rifiuti "$out"
out=$(CONFERMO_CARICAMENTO_REALE=si bash $D/carica_schede.sh 'postgresql://u:p@finto.pooler.supabase.com:6543/postgres' "$E" "$OUT/r2" 2>&1) \
  && fallita rifiuti "accettata la porta 6543"
grep -qF 'RIFIUTATO: serve la porta 5432' <<<"$out" || fallita rifiuti "$out"
echo "PROVA rifiuti OK"

# 2. File alterato: rifiuto prima di scrivere.
cp -R "$E" "$OUT/esporta_alterata"
printf 'x' >> "$OUT/esporta_alterata/schede_01.csv"
out=$(bash $D/carica_schede.sh "$URL" "$OUT/esporta_alterata" "$OUT/r3" 2>&1) && fallita alterato "nessun errore"
grep -qF 'RIFIUTATO: schede_01.csv diverso da quello del manifesto' <<<"$out" || fallita alterato "$out"
[ "$(conta)" = "$VUOTO" ] || fallita alterato "caricato qualcosa: $(conta)"
echo "PROVA alterato OK"

# 3. Ripresa: il lotto fallisce (una scheda con la stessa vecchia riga della sua prima riga, già presente) e non entra
#    niente; tolta la riga, il rilancio carica tutto.
"${PSQL[@]}" -c "insert into public.schede (taxon_id, cultivar_id, fonti, vecchia_specie_id)
                 select taxon_id, cultivar_id, '{prova}', vecchia_specie_id from (select nullif(split_part(l, ',', 2), '')::uuid as taxon_id,
                   nullif(split_part(l, ',', 3), '')::uuid as cultivar_id, split_part(l, ',', 4)::uuid as vecchia_specie_id
                   from (select '$(python3 -c 'import csv, sys; r = next(csv.DictReader(open(sys.argv[1], encoding="utf-8"))); print(",".join([r["id"], r["taxon_id"], r["cultivar_id"], r["vecchia_specie_id"]]))' "$E/schede_01.csv")'::text as l) x) y"
out=$(bash $D/carica_schede.sh "$URL" "$E" "$OUT/r4" 2>&1) && fallita ripresa "nessun errore con il lotto in conflitto"
grep -qF 'duplicate key value' <<<"$out" || fallita ripresa "$out"
[ "$("${PSQL[@]}" -tAc "select count(*) from public.schede")" = 1 ] || fallita ripresa "dopo il lotto fallito ci sono $(conta) schede"
"${PSQL[@]}" -c "delete from public.schede where fonti = '{prova}'"
carica r5 ripresa
[ "$(conta)" = "$PIENO" ] || fallita ripresa "stato inatteso: $(conta) invece di $PIENO"
echo "PROVA ripresa OK"

# 4. Rilancio: tutto saltato, stato invariato.
carica r6 rilancio
grep -qF 'schede_01.csv già caricato' "$OUT/r6/tempi.txt" || fallita rilancio "lotto ricaricato"
[ "$(conta)" = "$PIENO" ] || fallita rilancio "stato cambiato: $(conta)"
echo "PROVA rilancio OK"

# 5. Il rollback della fase 4a si rifiuta con le schede presenti (anche quelle sui soli taxon).
out=$("${PSQL[@]}" -c 'begin' -c 'delete from public.schede where cultivar_id is not null' -f $D/rollback_fase4a.sql 2>&1) \
  && fallita rollback_4a "rollback della fase 4a accettato con le schede presenti"
grep -qF 'Rollback fase 4a rifiutato' <<<"$out" || fallita rollback_4a "$out"
[ "$(conta)" = "$PIENO" ] || fallita rollback_4a "stato cambiato: $(conta)"
echo "PROVA rollback_4a OK"

# 6. Rollback della 4b: rifiutato se una scheda è stata modificata dopo il caricamento (in una transazione mai
#    confermata), poi eseguito e seguito da un nuovo caricamento completo.
out=$("${PSQL[@]}" -c 'begin' -c "update public.schede set descrizione = descrizione || ' ' where id = (select min(id::text)::uuid from public.schede)" \
        -f $D/rollback_fase4b.sql 2>&1) && fallita rollback "rollback accettato con una scheda modificata"
grep -qF 'Rollback fase 4b rifiutato' <<<"$out" || fallita rollback "$out"
[ "$(conta)" = "$PIENO" ] || fallita rollback "un rollback rifiutato ha tolto righe: $(conta)"
"${PSQL[@]}" -1 -f $D/rollback_fase4b.sql
"${PSQL[@]}" -c 'vacuum full public.schede'
[ "$(conta)" = "$VUOTO" ] || fallita rollback "stato dopo il rollback: $(conta) invece di $VUOTO"
carica r7 rollback
[ "$(conta)" = "$PIENO" ] || fallita rollback "stato dopo il nuovo caricamento: $(conta)"
echo "PROVA rollback OK"
echo "PROVE FASE 4B OK"
