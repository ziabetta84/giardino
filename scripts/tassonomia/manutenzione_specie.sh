#!/usr/bin/env bash
# Fase 1b del modello tassonomico: compatta public.specie (VACUUM FULL) senza cambiare i dati.
# Controlla lo spazio, calcola l'impronta, toglie i 4 indici trigram, compatta, li ricrea, ricalcola l'impronta
# e la confronta. Dopo il passo 1 gli indici vengono ricreati in ogni caso: se la compattazione fallisce, se un
# comando fallisce o se lo script viene interrotto (TERM, INT, HUP); non con kill -9.
# Uso: bash scripts/tassonomia/manutenzione_specie.sh URL CARTELLA [IMPRONTA_BACKUP]
#   URL              connessione in modalità sessione: SUPABASE_DB_URL (porta 5432) o la copia locale
#   CARTELLA         dove scrivere misure, impronte e tempi
#   IMPRONTA_BACKUP  se data, l'impronta di partenza deve coincidere: il backup è ancora una copia valida
# Sul database reale serve CONFERMO_MANUTENZIONE_REALE=si. Uscita 0 e ultima riga MANUTENZIONE SPECIE OK = riuscita.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL}; OUT=${2:?manca CARTELLA}; IMPRONTA_BACKUP=${3:-}
D=scripts/tassonomia
SOGLIA_WAL_MB=100000   # copia locale: il WAL resta sul disco del Mac
if [[ $URL == *supabase* ]]; then
  [[ $URL != *:6543/* ]] || { echo "RIFIUTATA: serve la porta 5432 (modalità sessione), non la 6543" >&2; exit 1; }
  [[ ${CONFERMO_MANUTENZIONE_REALE:-} == si ]] || { echo "RIFIUTATA: database reale senza CONFERMO_MANUTENZIONE_REALE=si" >&2; exit 1; }
  SOGLIA_WAL_MB=300    # disco di Supabase da 1 GB
fi
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"
tempo() { echo "$(date +%T) $1" >> "$OUT/tempi.txt"; }
indici_ok=0
ripristina() {
  [ "$indici_ok" = 1 ] && return
  echo "ATTENZIONE: manutenzione interrotta dopo il passo 1: ricreo gli indici trigram (passo 3)" >&2
  "${PSQL[@]}" -1 -f $D/manutenzione_specie_3_ricrea_indici.sql >&2 \
    || echo "ATTENZIONE: ricreazione non riuscita. Rieseguire: psql URL -X -1 -v ON_ERROR_STOP=1 -f $D/manutenzione_specie_3_ricrea_indici.sql" >&2
}

"${PSQL[@]}" -v soglia_mb=400 -v soglia_wal_mb=$SOGLIA_WAL_MB -f $D/manutenzione_specie_controlli.sql | tee "$OUT/controlli_prima.txt"
tempo "impronta prima"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_prima.txt"
if [ -n "$IMPRONTA_BACKUP" ] && ! diff -q "$IMPRONTA_BACKUP" "$OUT/impronta_prima.txt" > /dev/null; then
  echo "FERMATA: specie è cambiata dopo il backup; rifare il backup prima della manutenzione" >&2; exit 1
fi

tempo "passo 1: togli indici trigram"
"${PSQL[@]}" -1 -f $D/manutenzione_specie_1_togli_indici.sql
trap ripristina EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
tempo "passo 2: compatta"
esito=0
"${PSQL[@]}" -f $D/manutenzione_specie_2_compatta.sql || esito=$?
tempo "passo 3: ricrea indici trigram"
"${PSQL[@]}" -1 -f $D/manutenzione_specie_3_ricrea_indici.sql
indici_ok=1
tempo "fine"

"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_dopo.txt"
diff "$OUT/impronta_prima.txt" "$OUT/impronta_dopo.txt" >&2 || { echo "FALLITA: l'impronta di specie è cambiata" >&2; exit 1; }
[ "$esito" -eq 0 ] || { echo "FALLITA: compattazione non riuscita; dati e indici come prima" >&2; exit 1; }
"${PSQL[@]}" -f $D/manutenzione_specie_controlli.sql | tee "$OUT/controlli_dopo.txt"
"${PSQL[@]}" -f $D/verifica_manutenzione_specie.sql
echo "MANUTENZIONE SPECIE OK"
