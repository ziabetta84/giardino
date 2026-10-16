#!/usr/bin/env python3
"""Fase 3: estrae dai file di rollback le righe madri cancellate (specifica, mappa_specie: origine 'rollback').

Legge il JSON di json_populate_recordset in rollback_doppioni_slug.sql (32 righe) e rollback_tre_casi_doppioni.sql
(3 righe) e scrive su stdout un TSV id, slug, nome_scientifico, famiglia_botanica. Le cultivar (nome con apici o con
una madre) restano fuori: le 4 cultivar doppie di rollback_hedera_residue.sql sono materia della fase 4.
Uso: python3 scripts/tassonomia/mappa_rollback_madri.py > madri.tsv
"""
import csv
import json
import re
import sys
from pathlib import Path

FILE = ['scripts/nomi-italiani/rollback_doppioni_slug.sql', 'scripts/nomi-italiani/rollback_tre_casi_doppioni.sql']

righe = []
for nome in FILE:
    testo = Path(nome).read_text(encoding='utf-8')
    blocco = re.search(r'\$json\$(.*?)\$json\$', testo, re.S)
    if not blocco:
        sys.exit(f'JSON non trovato in {nome}')
    for r in json.loads(blocco.group(1)):
        if "'" in r['nome_scientifico'] or r.get('specie_padre_id'):
            continue
        righe.append((r['id'], r['slug'], r['nome_scientifico'], r.get('famiglia_botanica') or ''))
w = csv.writer(sys.stdout, delimiter='\t', lineterminator='\n')
w.writerow(['id', 'slug', 'nome_scientifico', 'famiglia_botanica'])
w.writerows(righe)
print(f'madri estratte: {len(righe)}', file=sys.stderr)
