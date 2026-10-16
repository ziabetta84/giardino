#!/usr/bin/env bash
# Fase 3 del modello tassonomico: carica i taxon locali (locali.csv) e public.mappa_specie (mappa.csv) preparati da
# mappa_esporta.sh, ciascuno in una transazione, con le righe già definitive (nessun aggiornamento: specifica, "Decisioni
# sullo spazio", punto 5). Va lanciato dopo carica_taxa.sh sui taxon nuovi della fase 3: ogni taxon_id di mappa.csv deve
# già esistere in taxa o tra i taxon locali. Si può rilanciare: un passo già fatto viene saltato, uno fatto a metà non
# esiste (transazione). Le altre tabelle non cambiano: l'impronta di specie si confronta prima e dopo.
# Uso: bash scripts/tassonomia/carica_mappa.sh URL CARTELLA_MAPPA CARTELLA_MISURE
#   Sul database reale serve CONFERMO_CARICAMENTO_REALE=si; soglie fisse: 400 MB di database, 300 MB di WAL.
# Uscita 0 e ultima riga CARICAMENTO MAPPA OK = riuscito.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL}; MAPPA=${2:?manca CARTELLA_MAPPA}; OUT=${3:?manca CARTELLA_MISURE}
D=scripts/tassonomia
if [[ $URL == *supabase* ]]; then
  [[ $URL != *:6543/* ]] || { echo "RIFIUTATO: serve la porta 5432 (modalità sessione), non la 6543" >&2; exit 1; }
  [[ ${CONFERMO_CARICAMENTO_REALE:-} == si ]] || { echo "RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si" >&2; exit 1; }
  SOGLIA_MB=400; SOGLIA_WAL_MB=300
else
  SOGLIA_MB=${SOGLIA_MB:-100000}; SOGLIA_WAL_MB=${SOGLIA_WAL_MB:-100000}
fi
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"
tempo() { echo "$(date +%T) $1" >> "$OUT/tempi.txt"; }
controlla() {
  "${PSQL[@]}" -v soglia_mb="$SOGLIA_MB" -v soglia_wal_mb="$SOGLIA_WAL_MB" -f $D/controlli_spazio.sql > "$OUT/controlli_$1.txt" \
    || { cat "$OUT/controlli_$1.txt" >&2; echo "FERMATO: spazio insufficiente prima di $1; in questo passo non è stato caricato niente" >&2; exit 1; }
}

# 1. I file sono quelli provati (sha256 del manifesto).
for f in locali.csv mappa.csv; do
  riga=$(awk -F'\t' -v f="$f" '$1 == f' "$MAPPA/manifest.tsv")
  [ -n "$riga" ] || { echo "RIFIUTATO: $f non è nel manifesto" >&2; exit 1; }
  [ "$(shasum -a 256 "$MAPPA/$f" | cut -d' ' -f1)" = "$(cut -f3 <<<"$riga")" ] \
    || { echo "RIFIUTATO: $f diverso da quello del manifesto" >&2; exit 1; }
done
LOCALI=$(awk -F'\t' '$1 == "locali.csv" { print $2 }' "$MAPPA/manifest.tsv")
RIGHE=$(awk -F'\t' '$1 == "mappa.csv" { print $2 }' "$MAPPA/manifest.tsv")
controlla inizio
tempo "impronta di specie prima"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_prima.txt"

# 2. Taxon locali: tutti o nessuno.
presenti=$("${PSQL[@]}" -tAc "select count(*) from public.taxa where origine = 'locale' and nota = 'notogenere assente da COL (fase 3)'")
if [ "$presenti" = "$LOCALI" ]; then
  tempo "taxon locali già caricati"
elif [ "$presenti" = 0 ]; then
  tempo "carico $LOCALI taxon locali"
  "${PSQL[@]}" -1 -c "copy public.taxa ($(head -1 "$MAPPA/locali.csv")) from stdin with (format csv, header)" \
    -c "do \$\$ begin if (select count(*) from public.taxa where origine = 'locale') <> $LOCALI then raise exception 'taxon locali incompleti'; end if; end \$\$" \
    < "$MAPPA/locali.csv"
else
  echo "RIFIUTATO: in taxa ci sono $presenti taxon locali della fase 3 invece di 0 o $LOCALI" >&2; exit 1
fi

# 3. mappa_specie: vuota -> si carica; già completa -> si salta; altrimenti rifiuto.
presenti=$("${PSQL[@]}" -tAc 'select count(*) from public.mappa_specie')
if [ "$presenti" = "$RIGHE" ]; then
  tempo "mappa_specie già caricata"
elif [ "$presenti" = 0 ]; then
  controlla mappa
  lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
  tempo "carico $RIGHE righe di mappa_specie"
  "${PSQL[@]}" -1 -c "set local statement_timeout = '10min'" \
    -c "copy public.mappa_specie ($(head -1 "$MAPPA/mappa.csv")) from stdin with (format csv, header)" \
    -c "do \$\$ begin if (select count(*) from public.mappa_specie) <> $RIGHE then raise exception 'mappa_specie incompleta'; end if; end \$\$" \
    < "$MAPPA/mappa.csv"
  wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
  tempo "mappa_specie caricata, WAL $wal MB"
else
  echo "RIFIUTATO: mappa_specie contiene $presenti righe invece di 0 o $RIGHE" >&2; exit 1
fi
"${PSQL[@]}" -c 'analyze public.mappa_specie'

# 4. specie invariata, mappa corretta, misure finali.
tempo "impronta di specie dopo"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_dopo.txt"
diff "$OUT/impronta_specie_prima.txt" "$OUT/impronta_specie_dopo.txt" >&2 \
  || { echo "FALLITO: specie è cambiata durante il caricamento" >&2; exit 1; }
"${PSQL[@]}" -v righe_mappa="$RIGHE" -v righe_locali="$LOCALI" -f $D/verifica_fase3.sql
"${PSQL[@]}" -f $D/controlli_spazio.sql | tee "$OUT/controlli_fine.txt"
tempo "fine"
echo "CARICAMENTO MAPPA OK"
