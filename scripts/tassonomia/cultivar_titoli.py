"""Fase 4a: lettura dei titoli delle pagine RHS delle cultivar secondo l'ICNCP (9ª ed.).

L'import delle cultivar (scripts/rhs-import/backfill_cultivar.py) ha costruito il nome di ogni riga di specie come
"<specie base> '<primo tratto tra apici del titolo RHS>'": l'epiteto si tronca al primo apostrofo ('King' per
'King's College') e Gruppo, nome commerciale e grex vanno persi. Qui si ritrovano i titoli da cui ogni riga è nata e
si rileggono:
- epiteto: tra il primo apice a inizio parola e l'ultimo apice seguito da fine o spazio, senza apici (art. 14.1);
  un apostrofo finale in più (Musa 'Iholena Ula'ula'') cade;
- nome commerciale: tra quadre, mai tra apici (art. 13.1, 17); un numero tra quadre è l'indice di omonimia di RHS;
- Gruppo: "(X Group)" o "X Group" davanti all'epiteto (art. 22.5), grex: "Genere Nome gx" (art. 23); le Serie non si
  registrano (App. X (2)); i codici di classificazione RHS tra parentesi ((v), (F)…) restano fuori.
"""
import os
import re
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'rhs-import'))
from species_key import base_species  # noqa: E402  (stessa chiave di specie usata dall'import)

CODICE = re.compile(r"^[A-Za-z0-9]{1,4}(\s?[a-z])?$|^\d+[a-z]?(-\d+)?$")
SERIE_MISCUGLIO = re.compile(r'\b(Series|Mixed|Mixture|Mix)\b')


def specie_aggregata(titolo):
    """Specie base come in build_full_aggregate.py: senza tratti tra apici, parentesi e quadre, le prime 2 parole
    (3 se la seconda è ×)."""
    s = re.sub(r"'[^']*'", '', titolo)
    s = re.sub(r'\([^)]*\)', '', s)
    s = re.sub(r'\[[^\]]*\]', '', s)
    parti = re.sub(r'\s+', ' ', s).strip().split(' ')
    if len(parti) >= 3 and parti[1] == '×':
        return ' '.join(parti[:3])
    return ' '.join(parti[:2])


def leggi_titolo(titolo):
    """Base, epiteto, gruppo, grex, nomi commerciali, serie, codici e altro di un titolo RHS."""
    r = {'commerciale': [], 'gruppo': None, 'grex': None, 'serie': None, 'codici': [], 'altro': [],
         'epiteto': None, 'base': None}
    s = titolo.strip()
    for x in re.findall(r'\[([^\]]*)\]', s):
        x = x.strip()
        if re.fullmatch(r'\d+', x):
            r['codici'].append('[%s]' % x)
        elif x.startswith("'"):
            r['altro'].append('[%s]' % x)
        else:
            r['commerciale'].append(x)
    s = re.sub(r'\s*\[[^\]]*\]', '', s)
    parentesi = []
    s = re.sub(r'\s*\(([^()]*)\)', lambda m: (parentesi.append(m.group(1).strip()), '')[1], s).strip()
    epiteto_tra_parentesi = None
    for p in parentesi:
        if len(p) >= 2 and p[0] == "'" and p[-1] == "'":
            epiteto_tra_parentesi = p[1:-1].strip()
        elif re.search(r'\bGroup$', p, re.I):
            r['gruppo'] = p
        elif re.search(r'\bSeries$', p, re.I):
            r['serie'] = p
        elif CODICE.match(p):
            r['codici'].append(p)
        else:
            r['altro'].append(p)
    m = re.search(r"(^|\s)'", s)
    if m:
        i = m.end() - 1
        chiusure = [k for k in range(i + 1, len(s)) if s[k] == "'" and (k == len(s) - 1 or s[k + 1] == ' ')]
        if chiusure:
            # l'apice di fine titolo chiude l'epiteto ('Rubens' Palette'); se il titolo continua con un descrittore,
            # chiude il primo apice seguito da uno spazio ('Berliner's Weeper' witches' broom)
            k = chiusure[-1] if chiusure[-1] == len(s) - 1 else chiusure[0]
            # un apostrofo prima dell'apice di chiusura fa parte della parola (Musa 'Iholena Ula'ula''), ma
            # l'epiteto non finisce mai con un apice
            r['epiteto'] = s[i + 1:k].strip().rstrip("'").strip()
            if s[k + 1:].strip():
                r['altro'].append(s[k + 1:].strip())
        base = s[:i].strip()
    else:
        base = s
    if r['epiteto'] is None and epiteto_tra_parentesi is not None:
        r['epiteto'] = epiteto_tra_parentesi
    elif epiteto_tra_parentesi is not None:
        r['altro'].append("('%s')" % epiteto_tra_parentesi)
    mg = re.match(r"^(×\s)?([A-Z][\w-]+)\s(.+?)\sgx$", base)
    if mg:
        r['grex'] = mg.group(3)
        base = (mg.group(1) or '') + mg.group(2)
    mgr = re.match(r"^(.+?)\s([A-Z][^']*\sGroup)$", base)
    if mgr and not r['gruppo']:
        r['gruppo'] = mgr.group(2)
        base = mgr.group(1)
    r['base'] = base
    return r


def indice_titoli(titoli):
    """Titoli RHS per nome di riga di specie, ricostruito come l'import: "<specie base> '<primo tratto tra apici>'"."""
    indice = {}
    for t in titoli:
        m = re.search(r"'([^']*)'", t or '')
        if not m or not m.group(1).strip():
            continue
        c = m.group(1).strip()
        for sp in {specie_aggregata(t), base_species(t)}:
            if sp:
                lista = indice.setdefault(f"{sp} '{c}'", [])
                if t not in lista:
                    lista.append(t)
    return indice


def _unisci(valori):
    v = []
    for x in valori:
        for y in (x or '').split(' | '):
            y = y.strip()
            if y and y not in v:
                v.append(y)
    return ' | '.join(v)


def _valido(ep):
    return (bool(ep) and ep == ep.strip() and ep[0] != "'" and ep[-1] != "'"
            and not re.search(r'[\[\]()]', ep) and not re.match(r'^[a-z]', ep))


def estrai(nome_scientifico, indice):
    """Epiteto, categoria, gruppo, nome commerciale e grex di una riga cultivar di specie, con il caso che li decide."""
    epiteto_specie = nome_scientifico.split("'")[1]
    titoli = indice.get(nome_scientifico, [])
    letti = [leggi_titolo(t) for t in titoli]
    epiteti = list(dict.fromkeys(x['epiteto'] for x in letti if x['epiteto']))
    gruppo = _unisci(x['gruppo'] for x in letti)
    commerciale = _unisci(' | '.join(x['commerciale']) for x in letti)
    grex = _unisci(x['grex'] for x in letti)
    segnalazioni = []
    if len(epiteti) == 1:
        epiteto = epiteti[0]
        caso = 'uguale al titolo RHS' if epiteto == epiteto_specie else 'corretto dal titolo RHS'
        if not _valido(epiteto):
            segnalazioni.append('epiteto RHS non valido')
    elif len(epiteti) > 1:
        # riga nata da più cultivar RHS: Gruppo, nomi commerciali e grex non sono di una sola cultivar
        gruppo = commerciale = grex = ''
        if epiteto_specie in epiteti:
            epiteto, caso = epiteto_specie, 'fusa: epiteto di specie presente tra i titoli'
        else:
            epiteto, caso = '', 'fusa: nessun titolo con questo epiteto'
    elif _valido(epiteto_specie) and not titoli:
        epiteto, caso = epiteto_specie, 'senza titolo RHS (altra fonte): epiteto di specie'
    else:
        epiteto, caso = '', 'senza epiteto leggibile'
    categoria = 'gruppo' if epiteto and re.search(r'\bGroup$', epiteto, re.I) else 'cultivar'
    if epiteto and SERIE_MISCUGLIO.search(epiteto):
        segnalazioni.append('serie o miscuglio di semi')
    if ' | ' in gruppo:
        segnalazioni.append('più Gruppi')
    if ' | ' in commerciale:
        segnalazioni.append('più nomi commerciali')
    return {'caso': caso, 'epiteto': epiteto, 'categoria': categoria, 'gruppo': gruppo, 'nome_commerciale': commerciale,
            'grex': grex, 'segnalazioni': '; '.join(segnalazioni), 'titoli': ' || '.join(titoli)}
