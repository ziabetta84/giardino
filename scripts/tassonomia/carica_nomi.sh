#!/usr/bin/env bash
# Fase 4c del modello tassonomico: carica public.nomi_comuni dai lotti preparati da nomi_esporta.sh, uno per transazione,
# con le righe già definitive (nessun aggiornamento: specifica, "Decisioni sullo spazio", punto 5). Va lanciato dopo le
# fasi 2-4b: ogni taxon_id deve già esistere.
# Regole sullo spazio: prima di ogni passo controlla la somma dei database e il WAL; tra un lotto e l'altro e prima degli
# indici fa una pausa (10 minuti sul reale); l'indice trigram di nomi_comuni si toglie prima e si ricrea dopo (i due
# indici unici restano: un nome una volta sola per taxon e lingua, un solo preferito).
# Si può rilanciare dopo un'interruzione: ogni lotto è una transazione e quelli già caricati vengono saltati. Le altre
# tabelle non cambiano: l'impronta di specie si confronta prima e dopo.
# Uso: bash scripts/tassonomia/carica_nomi.sh URL CARTELLA_NOMI CARTELLA_MISURE
#   Sul database reale serve CONFERMO_CARICAMENTO_REALE=si; soglie fisse: 420 MB di database (deciso nel piano della
#   fase 4c; il limite di lavoro della specifica resta 450), 300 MB di WAL.
#   Sulla copia locale: PAUSA_S (secondi, predefinito 0), SOGLIA_MB e SOGLIA_WAL_MB (predefiniti 100000).
# Uscita 0 e ultima riga CARICAMENTO NOMI OK = riuscito.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL}; NC=${2:?manca CARTELLA_NOMI}; OUT=${3:?manca CARTELLA_MISURE}
D=scripts/tassonomia
if [[ $URL == *supabase* ]]; then
  [[ $URL != *:6543/* ]] || { echo "RIFIUTATO: serve la porta 5432 (modalità sessione), non la 6543" >&2; exit 1; }
  [[ ${CONFERMO_CARICAMENTO_REALE:-} == si ]] || { echo "RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si" >&2; exit 1; }
  PAUSA_S=600; SOGLIA_MB=420; SOGLIA_WAL_MB=300
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
caricato() { [ "$("${PSQL[@]}" -tAc "select count(*) from public.nomi_comuni where id = '$1'")" = 1 ]; }
primo_passo=1
pausa() {
  if [ "$primo_passo" = 1 ]; then primo_passo=0
  elif [ "$PAUSA_S" -gt 0 ]; then tempo "pausa di $PAUSA_S s"; sleep "$PAUSA_S"; fi
}
UUID='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
COLONNE='id,taxon_id,lingua,nome,preferito,fonti,nota'

# 1. I file sono quelli provati (sha256 del manifesto), con le colonne attese; l'inventario è completo.
while IFS=$'\t' read -r file righe sha primo <&3; do
  [[ $file =~ ^nomi_[0-9]{2}\.csv$ && $righe =~ ^[0-9]+$ && $primo =~ $UUID ]] \
    || { echo "RIFIUTATO: riga del manifesto non valida: $file" >&2; exit 1; }
  [ "$(shasum -a 256 "$NC/$file" | cut -d' ' -f1)" = "$sha" ] || { echo "RIFIUTATO: $file diverso da quello del manifesto" >&2; exit 1; }
  [ "$(head -1 "$NC/$file")" = "$COLONNE" ] || { echo "RIFIUTATO: colonne inattese in $file" >&2; exit 1; }
done 3< "$NC/manifest.tsv"
NOMI=$(awk -F'\t' '{ s += $2 } END { print s }' "$NC/manifest.tsv")
INV=()
for chiave in nomi_specie_principali nomi_specie_alternativi preferiti italiani_nostri italiani_solo_col inglesi; do
  valore=$(awk -v k="$chiave" '$1 == k { print $2 }' "$NC/inventario.txt")
  [[ $valore =~ ^[0-9]+$ ]] || { echo "RIFIUTATO: inventario.txt senza $chiave" >&2; exit 1; }
  INV+=(-v "$chiave=$valore")
done
controlla inizio
tempo "impronta di specie prima"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_prima.txt"

# 2. Indice trigram tolto se c'è qualcosa da caricare (si ricrea al passo 4, anche dopo un'interruzione).
da_caricare=0
while IFS=$'\t' read -r file righe sha primo <&3; do
  if ! caricato "$primo"; then da_caricare=$((da_caricare + 1)); fi
done 3< "$NC/manifest.tsv"
if [ "$da_caricare" -gt 0 ]; then
  tempo "tolgo l'indice trigram di nomi_comuni ($da_caricare lotti da caricare)"
  "${PSQL[@]}" -c 'drop index if exists public.nomi_comuni_nome_trgm_idx'
fi

# 3. Un lotto per transazione; il conteggio si controlla dentro la transazione, prima del commit.
while IFS=$'\t' read -r file righe sha primo <&3; do
  if caricato "$primo"; then tempo "$file già caricato"; continue; fi
  pausa
  controlla "$file"
  prima=$("${PSQL[@]}" -tAc 'select count(*) from public.nomi_comuni')
  lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
  tempo "$file: carico $righe righe"
  "${PSQL[@]}" -1 -c "set local statement_timeout = '10min'" \
    -c "copy public.nomi_comuni ($COLONNE) from stdin with (format csv, header)" \
    -c "do \$\$ begin if (select count(*) from public.nomi_comuni) <> $((prima + righe)) then raise exception 'lotto $file incompleto'; end if; end \$\$" \
    < "$NC/$file"
  wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
  tempo "$file: caricate $righe righe, WAL $wal MB"
done 3< "$NC/manifest.tsv"

# 4. Indice trigram (identico alla migration della fase 1) e statistiche.
pausa
controlla indici
lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
tempo "ricreo l'indice trigram di nomi_comuni"
"${PSQL[@]}" -1 -c 'set local statement_timeout = 0' \
  -c 'create index if not exists nomi_comuni_nome_trgm_idx on public.nomi_comuni using gin (nome extensions.gin_trgm_ops)'
"${PSQL[@]}" -c 'analyze public.nomi_comuni'
wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
tempo "indice ricreato, WAL $wal MB"

# 5. specie invariata, nomi corretti, misure finali.
tempo "impronta di specie dopo"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_dopo.txt"
diff "$OUT/impronta_specie_prima.txt" "$OUT/impronta_specie_dopo.txt" >&2 \
  || { echo "FALLITO: specie è cambiata durante il caricamento" >&2; exit 1; }
"${PSQL[@]}" -v righe_nomi="$NOMI" "${INV[@]}" -f $D/verifica_fase4c.sql
"${PSQL[@]}" -f $D/controlli_spazio.sql | tee "$OUT/controlli_fine.txt"
tempo "fine"
echo "CARICAMENTO NOMI OK"
