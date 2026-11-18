"""
Completa luce, acqua e terreno delle schede mostrate che non li hanno, con i
dati delle pagine RHS recuperate (controllo periodico, issue #153).

Solo campi vuoti: un valore già presente non si tocca mai. Le traduzioni sono
quelle dell'import RHS (genera_sql.py), nello stile delle schede: prima
lettera maiuscola; il terreno come «Argilloso, franco; pH acido, neutro».
Se più pagine RHS portano alla stessa scheda vale la prima con il campo.

Uso:
    python3 completa_esigenze.py RECUPERATE.jsonl CONFRONTO.tsv SCHEDE.json OUT.sql ROLLBACK.sql
SCHEDE.json: schede mostrate con id, taxon_id, esigenze (esportazione pubblica).
"""
import json, re, sys

POSITION_IT = {"Full sun": "pieno sole", "Partial shade": "mezz'ombra", "Full shade": "ombra piena"}
SOIL_IT = {"Clay": "argilloso", "Loam": "franco", "Chalk": "calcareo", "Sand": "sabbioso"}
MOISTURE_IT = {"Moist but well-drained": "umido ma ben drenato", "Well-drained": "ben drenato",
               "Poorly-drained": "poco drenato", "Wet": "umido/paludoso"}
PH_IT = {"Acid": "acido", "Alkaline": "alcalino", "Neutral": "neutro"}


def traduci(valore, tabella):
    """None se manca o se una voce non è nella tabella (niente inglese nelle schede)."""
    if not valore:
        return None
    valore = valore.replace("–", "-").replace("—", "-")
    parti = [p.strip() for p in re.split(r",| or ", valore) if p.strip()]
    if not parti or any(p not in tabella for p in parti):
        return None
    visti = []
    for p in parti:
        if tabella[p] not in visti:
            visti.append(tabella[p])
    return ", ".join(visti)


def maiuscola(s):
    return s if not s or s.startswith("pH") else s[:1].upper() + s[1:]


def q(s):
    return "'" + s.replace("'", "''") + "'"


def main():
    rec, conf, sch, out, rb = sys.argv[1:6]
    schede = {s['taxon_id']: s for s in json.load(open(sch, encoding='utf-8')) if s.get('taxon_id')}
    pagine = {}
    for l in open(rec, encoding='utf-8'):
        d = json.loads(l)
        pagine[str(d['rhs_id'])] = d
    nuovi = {}
    for l in open(conf, encoding='utf-8'):
        rhs_id, _, esito, _, chiave = l.rstrip('\n').split('\t')
        if esito != 'scheda_esistente':
            continue
        s = schede[chiave[2:]]
        e = s.get('esigenze') or {}
        d = pagine[rhs_id]
        n = nuovi.setdefault(s['id'], {'vecchie': e, 'campi': {}})
        if not e.get('luce') and 'luce' not in n['campi']:
            v = traduci(d.get('position'), POSITION_IT)
            if v:
                n['campi']['luce'] = maiuscola(v)
        if not e.get('acqua') and 'acqua' not in n['campi']:
            v = traduci(d.get('moisture'), MOISTURE_IT)
            if v:
                n['campi']['acqua'] = maiuscola(v)
        if not e.get('terreno') and 'terreno' not in n['campi']:
            suolo, ph = traduci(d.get('soil_types'), SOIL_IT), traduci(d.get('ph'), PH_IT)
            v = '; '.join(x for x in (suolo, ('pH ' + ph) if ph else None) if x)
            if v:
                n['campi']['terreno'] = maiuscola(v)
    nuovi = {k: v for k, v in nuovi.items() if v['campi']}
    with open(out, 'w', encoding='utf-8') as f, open(rb, 'w', encoding='utf-8') as r:
        f.write('-- Luce, acqua e terreno mancanti completati dalle pagine RHS (controllo del 18/11/2026)\n')
        r.write('-- Rollback: rimette esigenze com\'erano, solo se nel frattempo non sono cambiate\n')
        for sid, v in sorted(nuovi.items()):
            nuove = dict(v['vecchie'])
            for k, val in v['campi'].items():
                nuove[k] = val
            vecchie_j = json.dumps(v['vecchie'], ensure_ascii=False) if v['vecchie'] else None
            nuove_j = json.dumps(nuove, ensure_ascii=False)
            cond = f"esigenze = {q(vecchie_j)}::jsonb" if vecchie_j else "esigenze is null or esigenze = '{}'::jsonb"
            f.write(f"update public.schede set esigenze = {q(nuove_j)}::jsonb, aggiornata_il = now() where id = '{sid}' and ({cond});\n")
            ritorno = f"{q(vecchie_j)}::jsonb" if vecchie_j else 'null'
            r.write(f"update public.schede set esigenze = {ritorno} where id = '{sid}' and esigenze = {q(nuove_j)}::jsonb;\n")
    print('schede', len(nuovi), 'campi', sum(len(v['campi']) for v in nuovi.values()))


if __name__ == '__main__':
    main()
