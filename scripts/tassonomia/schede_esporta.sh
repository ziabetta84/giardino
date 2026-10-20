#!/usr/bin/env bash
# Fase 4b: dalle schede proposte (col.schede_proposte, copia locale) scrive i file da caricare sul database reale:
# lotti schede_NN.csv da 20.000 righe al massimo (oggi uno solo, circa 40 MB di WAL), manifest.tsv con righe e sha256,
# mostrate.txt (schede mostrate attese). Le chiavi di taxa e cultivar sono quelle della copia, identica al reale.
# Uso: bash scripts/tassonomia/schede_esporta.sh URL_COPIA CARTELLA
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; DIR=${2:?manca CARTELLA}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "I file si preparano solo dalla copia locale" >&2; exit 1; }
[ ! -e "$DIR" ] || { echo "La cartella $DIR esiste già: i file provati non si sovrascrivono" >&2; exit 1; }
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
LOTTO=20000
COLONNE='id,taxon_id,cultivar_id,fonti,descrizione,descrizione_originale,lingua_descrizione,esigenze,manutenzione,ciclo_colturale,ciclo_vitale,vaso,alert,immagine,stato_verifica,verificata_il,verificata_da,mostrata,vecchia_specie_id,nota'
mkdir -p "$DIR"
"${PSQL[@]}" -c 'set statement_timeout = 0' -c "copy (select $COLONNE from col.schede_proposte order by vecchio_slug) to stdout with (format csv, header)" > "$DIR/tutte.csv"
python3 - "$DIR" "$LOTTO" <<'PY'
import csv, hashlib, os, sys
d, lotto = sys.argv[1], int(sys.argv[2])
csv.field_size_limit(10**9)
righe = list(csv.reader(open(os.path.join(d, 'tutte.csv'), encoding='utf-8', newline='')))
testa, corpo = righe[0], righe[1:]
with open(os.path.join(d, 'manifest.tsv'), 'w', encoding='utf-8') as man:
    for n, i in enumerate(range(0, len(corpo), lotto), 1):
        nome = f'schede_{n:02d}.csv'
        with open(os.path.join(d, nome), 'w', encoding='utf-8', newline='') as f:
            w = csv.writer(f, lineterminator='\n')
            w.writerow(testa)
            w.writerows(corpo[i:i + lotto])
        sha = hashlib.sha256(open(os.path.join(d, nome), 'rb').read()).hexdigest()
        man.write(f'{nome}\t{len(corpo[i:i + lotto])}\t{sha}\t{corpo[i][0]}\n')
os.remove(os.path.join(d, 'tutte.csv'))
PY
"${PSQL[@]}" -tAc 'select count(*) from col.schede_proposte where mostrata' > "$DIR/mostrate.txt"
cut -f1,2 "$DIR/manifest.tsv"
echo "mostrate $(cat "$DIR/mostrate.txt")"
