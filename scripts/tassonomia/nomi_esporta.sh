#!/usr/bin/env bash
# Fase 4c: dai nomi proposti (col.nomi_proposte, copia locale) scrive i file da caricare sul database reale: lotti
# nomi_NN.csv da 50.000 righe al massimo (oggi uno solo, pochi MB di WAL), manifest.tsv con righe e sha256 e
# inventario.txt con i numeri che verifica_fase4c.sql ricontrolla sul reale (nomi di specie da cui si parte, nomi per
# origine, preferiti). Le chiavi di taxa sono quelle della copia, identica al reale.
# Uso: bash scripts/tassonomia/nomi_esporta.sh URL_COPIA CARTELLA
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; DIR=${2:?manca CARTELLA}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "I file si preparano solo dalla copia locale" >&2; exit 1; }
[ ! -e "$DIR" ] || { echo "La cartella $DIR esiste già: i file provati non si sovrascrivono" >&2; exit 1; }
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
LOTTO=50000
COLONNE='id,taxon_id,lingua,nome,preferito,fonti,nota'
mkdir -p "$DIR"
"${PSQL[@]}" -c 'set statement_timeout = 0' -c "copy (select $COLONNE from col.nomi_proposte order by lingua, taxon_id, k) to stdout with (format csv, header)" > "$DIR/tutte.csv"
python3 - "$DIR" "$LOTTO" <<'PY'
import csv, hashlib, os, sys
d, lotto = sys.argv[1], int(sys.argv[2])
righe = list(csv.reader(open(os.path.join(d, 'tutte.csv'), encoding='utf-8', newline='')))
testa, corpo = righe[0], righe[1:]
with open(os.path.join(d, 'manifest.tsv'), 'w', encoding='utf-8') as man:
    for n, i in enumerate(range(0, len(corpo), lotto), 1):
        nome = f'nomi_{n:02d}.csv'
        with open(os.path.join(d, nome), 'w', encoding='utf-8', newline='') as f:
            w = csv.writer(f, lineterminator='\n')
            w.writerow(testa)
            w.writerows(corpo[i:i + lotto])
        sha = hashlib.sha256(open(os.path.join(d, nome), 'rb').read()).hexdigest()
        man.write(f'{nome}\t{len(corpo[i:i + lotto])}\t{sha}\t{corpo[i][0]}\n')
os.remove(os.path.join(d, 'tutte.csv'))
PY
# inventario: chiave e valore, uno per riga
"${PSQL[@]}" -tA -F ' ' -c "
select 'nomi_specie_principali', count(*) from col.nomi_provenienza where ruolo = 'principale'
union all select 'nomi_specie_alternativi', count(*) from col.nomi_provenienza where ruolo = 'alternativo'
union all select 'preferiti', count(*) from col.nomi_proposte where preferito
union all select 'italiani_nostri', count(*) from col.nomi_proposte where lingua = 'it' and origine = 'nostri'
union all select 'italiani_solo_col', count(*) from col.nomi_proposte where lingua = 'it' and origine = 'col'
union all select 'inglesi', count(*) from col.nomi_proposte where lingua = 'en'" > "$DIR/inventario.txt"
cut -f1,2 "$DIR/manifest.tsv"
cat "$DIR/inventario.txt"
