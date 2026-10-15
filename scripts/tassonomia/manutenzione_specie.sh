#!/usr/bin/env bash
# Fase 1b del modello tassonomico: compatta public.specie (VACUUM FULL) senza cambiare i dati.
# Controlla lo spazio, calcola l'impronta, toglie i 4 indici trigram, compatta, li ricrea, ricalcola l'impronta
# e la confronta. Dal passo 1 in poi gli indici vengono ricreati in ogni caso: se la compattazione fallisce, se un
# comando fallisce o se lo script viene interrotto (TERM, INT, HUP, anche ripetuti); non con kill -9.
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
# Ripristino all'uscita: deve arrivare in fondo anche con il terminale chiuso (scrivere su stderr fallisce, quindi niente
# set -e) e con altri segnali in arrivo (ignorati; il psql del passo 3 gira in un gruppo di processi suo, così un secondo
# Ctrl-C o TERM al gruppo dello script non lo raggiunge). Lo stato finale va anche in tempi.txt.
ripristina() {
  local n=
  [ "$indici_ok" = 1 ] && return
  set +e
  trap '' HUP INT TERM PIPE
  avvisa "ATTENZIONE: manutenzione interrotta: controllo e ricreo gli indici trigram (passo 3)"
  set -m
  "${PSQL[@]}" -1 -f $D/manutenzione_specie_3_ricrea_indici.sql >&2 &
  wait $!
  set +m
  "${PSQL[@]}" -tA -o "$OUT/indici_trgm.txt" -c "select count(*) from pg_index i join pg_class c on c.oid = i.indexrelid
                                                 where i.indrelid = 'public.specie'::regclass and c.relname like '%trgm%' and i.indisvalid"
  read -r n < "$OUT/indici_trgm.txt"
  if [ "$n" = 4 ]; then
    avvisa "indici trigram ricreati: 4 su 4"
  else
    avvisa "ATTENZIONE: indici trigram ${n:-?} su 4. Rieseguire: psql URL -X -1 -v ON_ERROR_STOP=1 -f $D/manutenzione_specie_3_ricrea_indici.sql"
  fi
}
# Messaggi del ripristino, in tempi.txt e su stderr. Su stderr con un comando esterno: se stderr non è scrivibile
# (terminale chiuso), l'echo interno di bash 3.2 (quello di macOS) tiene il testo in memoria e lo riversa nella
# scrittura successiva, anche dentro tempi.txt o nell'uscita catturata di un comando.
avvisa() { tempo "$1"; /bin/echo "$1" >&2; }

"${PSQL[@]}" -v soglia_mb=400 -v soglia_wal_mb=$SOGLIA_WAL_MB -f $D/manutenzione_specie_controlli.sql | tee "$OUT/controlli_prima.txt"
tempo "impronta prima"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_prima.txt"
if [ -n "$IMPRONTA_BACKUP" ] && ! diff -q "$IMPRONTA_BACKUP" "$OUT/impronta_prima.txt" > /dev/null; then
  echo "FERMATA: specie è cambiata dopo il backup; rifare il backup prima della manutenzione" >&2; exit 1
fi

# Il ripristino si arma prima del passo 1: se il COMMIT del passo 1 è in volo quando arriva un segnale, gli indici
# possono essere già tolti sul server senza che lo script lo sappia. Il passo 3 non fa danni se gli indici ci sono.
trap ripristina EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
tempo "passo 1: togli indici trigram"
"${PSQL[@]}" -1 -f $D/manutenzione_specie_1_togli_indici.sql
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
