#!/usr/bin/env bash
# Fase 4b del modello tassonomico: carica public.schede dai lotti preparati da schede_esporta.sh, uno per transazione,
# con le righe già definitive (nessun aggiornamento: specifica, "Decisioni sullo spazio", punto 5). Va lanciato dopo la
# fase 4a: ogni taxon_id e cultivar_id deve già esistere.
# Regole sullo spazio: prima di ogni passo controlla la somma dei database e il WAL; tra un lotto e l'altro fa una pausa
# (10 minuti sul reale); i 2 indici secondari non unici di schede si tolgono prima e si ricreano dopo (quelli unici
# sulla scheda mostrata restano, perché garantiscono una sola mostrata per aggancio).
# Si può rilanciare dopo un'interruzione: ogni lotto è una transazione e quelli già caricati vengono saltati. Le altre
# tabelle non cambiano: l'impronta di specie si confronta prima e dopo.
# Uso: bash scripts/tassonomia/carica_schede.sh URL CARTELLA_SCHEDE CARTELLA_MISURE
#   Sul database reale serve CONFERMO_CARICAMENTO_REALE=si; soglie fisse: 400 MB di database, 300 MB di WAL.
#   Sulla copia locale: PAUSA_S (secondi, predefinito 0), SOGLIA_MB e SOGLIA_WAL_MB (predefiniti 100000).
# Uscita 0 e ultima riga CARICAMENTO SCHEDE OK = riuscito.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL}; SC=${2:?manca CARTELLA_SCHEDE}; OUT=${3:?manca CARTELLA_MISURE}
D=scripts/tassonomia
if [[ $URL == *supabase* ]]; then
  [[ $URL != *:6543/* ]] || { echo "RIFIUTATO: serve la porta 5432 (modalità sessione), non la 6543" >&2; exit 1; }
  [[ ${CONFERMO_CARICAMENTO_REALE:-} == si ]] || { echo "RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si" >&2; exit 1; }
  PAUSA_S=600; SOGLIA_MB=400; SOGLIA_WAL_MB=300
else
  PAUSA_S=${PAUSA_S:-0}; SOGLIA_MB=${SOGLIA_MB:-100000}; SOGLIA_WAL_MB=${SOGLIA_WAL_MB:-100000}
fi
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"
tempo() { echo "$(date +%T) $1" >> "$OUT/tempi.txt"; }
controlla() {
  "${PSQL[@]}" -v soglia_mb="$SOGLIA_MB" -v soglia_wal_mb="$SOGLIA_WAL_MB" -f $D/controlli_spazio.sql > "$OUT/controlli_$1.txt" \
    || { cat "$OUT/controlli_$1.txt" >&2; echo "FERMATO: spazio insufficiente prima di $1; in questo passo non è stato caricato niente" >&2; exit 1; }
}
caricato() { [ "$("${PSQL[@]}" -tAc "select count(*) from public.schede where id = '$1'")" = 1 ]; }
primo_passo=1
pausa() {
  if [ "$primo_passo" = 1 ]; then primo_passo=0
  elif [ "$PAUSA_S" -gt 0 ]; then tempo "pausa di $PAUSA_S s"; sleep "$PAUSA_S"; fi
}
UUID='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
COLONNE='id,taxon_id,cultivar_id,fonti,descrizione,descrizione_originale,lingua_descrizione,esigenze,manutenzione,ciclo_colturale,ciclo_vitale,vaso,alert,immagine,stato_verifica,verificata_il,verificata_da,mostrata,vecchia_specie_id,nota'

# 1. I file sono quelli provati (sha256 del manifesto), con le colonne attese.
while IFS=$'\t' read -r file righe sha primo <&3; do
  [[ $file =~ ^schede_[0-9]{2}\.csv$ && $righe =~ ^[0-9]+$ && $primo =~ $UUID ]] \
    || { echo "RIFIUTATO: riga del manifesto non valida: $file" >&2; exit 1; }
  [ "$(shasum -a 256 "$SC/$file" | cut -d' ' -f1)" = "$sha" ] || { echo "RIFIUTATO: $file diverso da quello del manifesto" >&2; exit 1; }
  [ "$(head -1 "$SC/$file")" = "$COLONNE" ] || { echo "RIFIUTATO: colonne inattese in $file" >&2; exit 1; }
done 3< "$SC/manifest.tsv"
SCHEDE=$(awk -F'\t' '{ s += $2 } END { print s }' "$SC/manifest.tsv")
MOSTRATE=$(cat "$SC/mostrate.txt")
[[ $MOSTRATE =~ ^[0-9]+$ ]] || { echo "RIFIUTATO: mostrate.txt non valido" >&2; exit 1; }
controlla inizio
tempo "impronta di specie prima"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_prima.txt"

# 2. Indici secondari non unici tolti se c'è qualcosa da caricare (si ricreano al passo 4, anche dopo un'interruzione).
da_caricare=0
while IFS=$'\t' read -r file righe sha primo <&3; do
  if ! caricato "$primo"; then da_caricare=$((da_caricare + 1)); fi
done 3< "$SC/manifest.tsv"
if [ "$da_caricare" -gt 0 ]; then
  tempo "tolgo gli indici secondari di schede ($da_caricare lotti da caricare)"
  "${PSQL[@]}" -c 'drop index if exists public.schede_taxon_id_idx, public.schede_cultivar_id_idx'
fi

# 3. Un lotto per transazione; il conteggio si controlla dentro la transazione, prima del commit.
while IFS=$'\t' read -r file righe sha primo <&3; do
  if caricato "$primo"; then tempo "$file già caricato"; continue; fi
  pausa
  controlla "$file"
  prima=$("${PSQL[@]}" -tAc 'select count(*) from public.schede')
  lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
  tempo "$file: carico $righe righe"
  "${PSQL[@]}" -1 -c "set local statement_timeout = '10min'" \
    -c "copy public.schede ($COLONNE) from stdin with (format csv, header)" \
    -c "do \$\$ begin if (select count(*) from public.schede) <> $((prima + righe)) then raise exception 'lotto $file incompleto'; end if; end \$\$" \
    < "$SC/$file"
  wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
  tempo "$file: caricate $righe righe, WAL $wal MB"
done 3< "$SC/manifest.tsv"

# 4. Indici secondari (identici alla migration della fase 1) e statistiche.
pausa
controlla indici
lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
tempo "ricreo gli indici secondari di schede"
"${PSQL[@]}" -1 -c 'set local statement_timeout = 0' \
  -c 'create index if not exists schede_taxon_id_idx on public.schede (taxon_id)' \
  -c 'create index if not exists schede_cultivar_id_idx on public.schede (cultivar_id)'
"${PSQL[@]}" -c 'analyze public.schede'
wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
tempo "indici ricreati, WAL $wal MB"

# 5. specie invariata, schede corrette, misure finali.
tempo "impronta di specie dopo"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_dopo.txt"
diff "$OUT/impronta_specie_prima.txt" "$OUT/impronta_specie_dopo.txt" >&2 \
  || { echo "FALLITO: specie è cambiata durante il caricamento" >&2; exit 1; }
"${PSQL[@]}" -v righe_schede="$SCHEDE" -v righe_mostrate="$MOSTRATE" -f $D/verifica_fase4b.sql
"${PSQL[@]}" -f $D/controlli_spazio.sql | tee "$OUT/controlli_fine.txt"
tempo "fine"
echo "CARICAMENTO SCHEDE OK"
