"""
Confronto delle pagine RHS recuperate con il catalogo (controllo periodico, issue #153).

Legge le pagine recuperate (recupera_pagine.py) e un'esportazione del catalogo
(taxa, cultivar, schede: righe JSON con le sole colonne pubbliche) e assegna a
ogni pagina con indicazioni di coltivazione un esito:

  specie:   scheda_esistente   il taxon (o il suo accettato) ha già una scheda mostrata
            taxon_senza_scheda il taxon c'è ma nessuna scheda mostrata
            taxon_assente      nessun taxon con quel nome
  cultivar: cultivar_con_scheda, cultivar_senza_scheda, cultivar_assente
            (la specie c'è ma la cultivar no), taxon_assente

Uso:
    python3 confronta_catalogo.py RECUPERATE.jsonl CARTELLA_CATALOGO OUT.tsv
Stampa il riepilogo; OUT.tsv ha rhs_id, esito, titolo, chiave della voce trovata.
"""
import collections, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'tassonomia'))
from cultivar_titoli import leggi_titolo  # noqa: E402

CAMPI = ('cultivation', 'position', 'soil_types', 'pruning')


def norm_nome(s):
    s = (s or '').replace('×', 'x ').replace('  ', ' ')
    s = re.sub(r'\bx\s+', 'x ', s)
    return re.sub(r'\s+', ' ', s).strip().lower()


def norm_ep(s):
    return re.sub(r'[\s\-‘’\'"]', '', (s or '').lower())


def leggi(p):
    with open(p, encoding='utf-8') as fh:
        for riga in fh:
            yield json.loads(riga)


def main():
    rec, cat, out = sys.argv[1:4]
    taxa = {t['id']: t for t in leggi(os.path.join(cat, 'taxa.jsonl'))}
    per_nome = collections.defaultdict(set)
    for t in taxa.values():
        per_nome[norm_nome(t['nome_scientifico'])].add(t['id'])
    acc = lambda i: taxa[i]['accettato_id'] or i
    sinonimi = collections.defaultdict(set)
    for t in taxa.values():
        sinonimi[acc(t['id'])].add(t['id'])
    cult = collections.defaultdict(dict)
    for c in leggi(os.path.join(cat, 'cultivar.jsonl')):
        cult[acc(c['taxon_id']) if c['taxon_id'] in taxa else c['taxon_id']][norm_ep(c['epiteto'])] = c['id']
    sch_taxon, sch_cult = set(), set()
    for s in leggi(os.path.join(cat, 'schede.jsonl')):
        if s.get('mostrata'):
            if s.get('taxon_id'):
                sch_taxon.add(s['taxon_id'])
            if s.get('cultivar_id'):
                sch_cult.add(s['cultivar_id'])

    conta = collections.Counter()
    with open(out, 'w', encoding='utf-8') as fo:
        for d in leggi(rec):
            if not any(d.get(k) for k in CAMPI):
                continue
            titolo = d.get('nome_scientifico_titolo') or ''
            r = leggi_titolo(titolo)
            ids = per_nome.get(norm_nome(r['base']), set())
            if not ids:  # autore o rango in coda: si prova con le prime due o tre parole
                parole = norm_nome(r['base']).split(' ')
                for n in (3, 2):
                    ids = per_nome.get(' '.join(parole[:n]), set())
                    if ids:
                        break
            accettati = {acc(i) for i in ids}
            tipo = 'cultivar' if r['epiteto'] else 'specie'
            chiave = ''
            if not accettati:
                esito = 'taxon_assente'
            elif tipo == 'specie':
                if accettati & sch_taxon:
                    esito, chiave = 'scheda_esistente', 't:' + sorted(accettati & sch_taxon)[0]
                else:
                    esito, chiave = 'taxon_senza_scheda', 't:' + sorted(accettati)[0]
            else:
                trovata = None
                for a in accettati:
                    trovata = cult.get(a, {}).get(norm_ep(r['epiteto']))
                    if trovata:
                        break
                if not trovata:
                    esito, chiave = 'cultivar_assente', 't:' + sorted(accettati)[0]
                elif trovata in sch_cult:
                    esito, chiave = 'cultivar_con_scheda', 'c:' + trovata
                else:
                    esito, chiave = 'cultivar_senza_scheda', 'c:' + trovata
            conta[(tipo, esito)] += 1
            fo.write(f"{d['rhs_id']}\t{tipo}\t{esito}\t{titolo}\t{chiave}\n")
    for k, v in sorted(conta.items()):
        print(*k, v, sep='\t')


if __name__ == '__main__':
    main()
