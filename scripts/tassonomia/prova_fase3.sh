#!/usr/bin/env bash
# Prove della fase 3 (taxon in più e mappa_specie) sulla copia locale: rifiuti, file alterato, ordine sbagliato,
# caricamento, rilancio, rollback rifiutato ed eseguito, nuovo caricamento.
# Uso: bash scripts/tassonomia/prova_fase3.sh URL_COPIA CARTELLA_ESPORTA CARTELLA      (CARTELLA nuova a ogni giro)
#   CARTELLA_ESPORTA = cartella scritta da mappa_esporta.sh (sottocartelle taxa e mappa).
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
conta() { "${PSQL[@]}" -tAc "select (select count(*) from public.mappa_specie) || ' ' || count(*) filter (where origine = 'col') || ' ' || count(*) filter (where origine = 'locale') from public.taxa"; }
BASE=$(cat "$E/taxa/base.txt")
NUOVI=$(awk -F'\t' '{ s += $2 } END { print s }' "$E/taxa/manifest.tsv")
RIGHE=$(awk -F'\t' '$1 == "mappa.csv" { print $2 }' "$E/mappa/manifest.tsv")
LOCALI=$(awk -F'\t' '$1 == "locali.csv" { print $2 }' "$E/mappa/manifest.tsv")
VUOTO="0 $BASE 0"
PIENO="$RIGHE $((BASE + NUOVI)) $LOCALI"
[ "$(conta)" = "$VUOTO" ] || fallita preparazione "la copia non è nello stato della fase 2 ($(conta)): prima rollback_fase3.sql"
carica() {  # carica CARTELLA PROVA: taxon in più e poi mappa, con log in OUT
  bash $D/carica_taxa.sh "$URL" "$E/taxa" "$OUT/$1_taxa" > "$OUT/$1_taxa.log" 2>&1 || fallita "$2" "carica_taxa: $(tail -3 "$OUT/$1_taxa.log")"
  bash $D/carica_mappa.sh "$URL" "$E/mappa" "$OUT/$1_mappa" > "$OUT/$1_mappa.log" 2>&1 || fallita "$2" "carica_mappa: $(tail -3 "$OUT/$1_mappa.log")"
  [ "$(tail -1 "$OUT/$1_mappa.log")" = 'CARICAMENTO MAPPA OK' ] || fallita "$2" "$(tail -3 "$OUT/$1_mappa.log")"
}

# 1. Rifiuti, prima di qualsiasi connessione.
out=$(bash $D/carica_mappa.sh 'postgresql://u:p@finto.pooler.supabase.com:5432/postgres' "$E/mappa" "$OUT/r1" 2>&1) \
  && fallita rifiuti "accettato il database reale senza conferma"
grep -qF 'RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si' <<<"$out" || fallita rifiuti "$out"
out=$(CONFERMO_CARICAMENTO_REALE=si bash $D/carica_mappa.sh 'postgresql://u:p@finto.pooler.supabase.com:6543/postgres' "$E/mappa" "$OUT/r2" 2>&1) \
  && fallita rifiuti "accettata la porta 6543"
grep -qF 'RIFIUTATO: serve la porta 5432' <<<"$out" || fallita rifiuti "$out"
echo "PROVA rifiuti OK"

# 2. File alterato: rifiuto prima di scrivere.
cp -R "$E/mappa" "$OUT/mappa_alterata"
printf 'x' >> "$OUT/mappa_alterata/mappa.csv"
out=$(bash $D/carica_mappa.sh "$URL" "$OUT/mappa_alterata" "$OUT/r3" 2>&1) && fallita alterato "nessun errore"
grep -qF 'RIFIUTATO: mappa.csv diverso da quello del manifesto' <<<"$out" || fallita alterato "$out"
[ "$(conta)" = "$VUOTO" ] || fallita alterato "caricato qualcosa: $(conta)"
echo "PROVA alterato OK"

# 3. Ordine sbagliato (mappa prima dei taxon nuovi): la mappa non entra (chiave esterna), i taxon locali sì.
out=$(bash $D/carica_mappa.sh "$URL" "$E/mappa" "$OUT/r4" 2>&1) && fallita ordine "nessun errore"
grep -qF 'violates foreign key constraint' <<<"$out" || fallita ordine "$out"
[ "$(conta)" = "0 $BASE $LOCALI" ] || fallita ordine "stato inatteso: $(conta)"
echo "PROVA ordine OK"

# 4. Caricamento completo (i taxon locali già presenti vengono saltati).
carica r5 caricamento
grep -qF 'taxon locali già caricati' "$OUT/r5_mappa/tempi.txt" || fallita caricamento "taxon locali ricaricati"
[ "$(conta)" = "$PIENO" ] || fallita caricamento "stato inatteso: $(conta) invece di $PIENO"
echo "PROVA caricamento OK"

# 5. Rilancio: tutto saltato, stato invariato.
carica r6 rilancio
grep -qF 'lotto_01.csv già caricato' "$OUT/r6_taxa/tempi.txt" || fallita rilancio "lotto dei taxon ricaricato"
grep -qF 'mappa_specie già caricata' "$OUT/r6_mappa/tempi.txt" || fallita rilancio "mappa ricaricata"
[ "$(conta)" = "$PIENO" ] || fallita rilancio "stato cambiato: $(conta)"
echo "PROVA rilancio OK"

# 6. Rollback: rifiutato se la fase 4 ha già dati (una cultivar in una transazione mai confermata), poi eseguito e
#    seguito da un nuovo caricamento completo.
out=$("${PSQL[@]}" -c 'begin' \
        -c "insert into public.cultivar (slug, taxon_id, epiteto, fonti) select 'prova', id, 'Prova', '{prova}' from public.taxa limit 1" \
        -f $D/rollback_fase3.sql 2>&1) && fallita rollback "rollback accettato con la fase 4 iniziata"
grep -qF 'Rollback fase 3 rifiutato' <<<"$out" || fallita rollback "$out"
[ "$(conta)" = "$PIENO" ] || fallita rollback "un rollback rifiutato ha tolto righe: $(conta)"
"${PSQL[@]}" -1 -f $D/rollback_fase3.sql
"${PSQL[@]}" -c 'vacuum full public.mappa_specie' -c 'vacuum full public.taxa'
[ "$(conta)" = "$VUOTO" ] || fallita rollback "stato dopo il rollback: $(conta) invece di $VUOTO"
carica r7 rollback
[ "$(conta)" = "$PIENO" ] || fallita rollback "stato dopo il nuovo caricamento: $(conta)"
echo "PROVA rollback OK"
echo "PROVE FASE 3 OK"
