#!/usr/bin/env python3
"""Fase 4b: le 35 righe madri cancellate, per intero, dai file di rollback (le stesse di mappa_rollback_madri.py), una
per riga in JSON, per diventare schede (specifica, "Migrazione dei contenuti": le 35 madri entrano come schede).
Uso: python3 scripts/tassonomia/schede_rollback_madri.py > madri.jsonl   (dalla radice del repository)
"""
import json
import re
import sys
from pathlib import Path

FILE = ['scripts/nomi-italiani/rollback_doppioni_slug.sql', 'scripts/nomi-italiani/rollback_tre_casi_doppioni.sql']
n = 0
for nome in FILE:
    blocco = re.search(r'\$json\$(.*?)\$json\$', Path(nome).read_text(encoding='utf-8'), re.S)
    if not blocco:
        sys.exit(f'JSON non trovato in {nome}')
    for r in json.loads(blocco.group(1)):
        if "'" in r['nome_scientifico'] or r.get('specie_padre_id'):
            continue
        print(json.dumps(r, ensure_ascii=False))
        n += 1
print(f'madri estratte: {n}', file=sys.stderr)
