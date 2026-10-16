#!/usr/bin/env python3
"""Fase 4a: epiteto, categoria, Gruppo, nome commerciale e grex di ogni riga cultivar di specie, riletti dai titoli
delle pagine RHS già scaricate (vedi cultivar_titoli.py e la specifica, "Decisioni per la fase 4", punti 15 e 19).
Uso: python3 scripts/tassonomia/cultivar_estrai.py RHS_JSONL < cultivar_righe.tsv > cultivar_estratte.tsv
  RHS_JSONL: scripts/rhs-import/rhs_sitemaps_parsed.jsonl (git-ignorato, un oggetto JSON per pagina con
             nome_scientifico_titolo);
  standard input: TSV con intestazione id, nome_scientifico (le righe di specie con l'epiteto tra apici);
  standard output: TSV con intestazione id, caso, epiteto, categoria, gruppo, nome_commerciale, grex, segnalazioni,
             titoli. Il riepilogo dei casi va sullo standard error.
"""
import collections
import csv
import json
import os
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cultivar_titoli import estrai, indice_titoli  # noqa: E402

COLONNE = ['id', 'caso', 'epiteto', 'categoria', 'gruppo', 'nome_commerciale', 'grex', 'segnalazioni', 'titoli']


def titoli_rhs(percorso):
    with open(percorso, encoding='utf-8') as f:
        for riga in f:
            if riga.strip():
                t = (json.loads(riga).get('nome_scientifico_titolo') or '').replace('\t', ' ').replace('\n', ' ')
                if "'" in t:
                    yield t


def main():
    indice = indice_titoli(titoli_rhs(sys.argv[1]))
    righe = csv.DictReader(sys.stdin, delimiter='\t')
    out = csv.writer(sys.stdout, delimiter='\t', lineterminator='\n')
    out.writerow(COLONNE)
    conteggi = collections.Counter()
    for r in righe:
        e = estrai(r['nome_scientifico'], indice)
        conteggi[e['caso']] += 1
        for k in ('gruppo', 'nome_commerciale', 'grex'):
            conteggi['con ' + k] += bool(e[k])
        out.writerow([r['id']] + [e[k] for k in COLONNE[1:]])
    for k, v in sorted(conteggi.items()):
        print(f'{k}: {v}', file=sys.stderr)


if __name__ == '__main__':
    main()
