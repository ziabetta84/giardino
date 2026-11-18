"""
Sostituisce gli avvisi «Rischi (testo in inglese): …» delle schede con il
testo riscritto in italiano («Rischi: …»), come chiesto da Roberta il 18/11/2026.

Le traduzioni sono in una cartella di file JSON {numero: testo} (numero = riga
di testi_en.json, testi distinti ordinati per frequenza). «__TOGLI__» toglie
l'avviso (testi che non parlano di rischi: descrizioni, note sugli infestanti).
Ogni update è condizionato al vecchio array alert, ogni rollback al nuovo.

Uso:
    python3 rischi_italiano.py SCHEDE.json TESTI_EN.json CARTELLA_IT OUT.sql ROLLBACK.sql
SCHEDE.json: [{id, alert}] delle schede mostrate con almeno un avviso in inglese.
"""
import glob, json, os, sys

PREF_EN = 'Rischi (testo in inglese): '


def q(s):
    return "'" + s.replace("'", "''") + "'"


def arr(a):
    return 'array[' + ', '.join(q(x) for x in a) + ']::text[]' if a else "'{}'::text[]"


def main():
    sch, ten, cart, out, rb = sys.argv[1:6]
    en = {x['en']: str(x['n']) for x in json.load(open(ten, encoding='utf-8'))}
    it = {}
    for f in sorted(glob.glob(os.path.join(cart, '*.json'))):
        it.update(json.load(open(f, encoding='utf-8')))
    n_upd = n_tolti = 0
    with open(out, 'w', encoding='utf-8') as fo, open(rb, 'w', encoding='utf-8') as fr:
        fo.write('-- Avvisi «Rischi (testo in inglese)» riscritti in italiano (18/11/2026)\n')
        fr.write('-- Rollback: rimette gli avvisi in inglese, solo se nel frattempo non sono cambiati\n')
        for s in sorted(json.load(open(sch, encoding='utf-8')), key=lambda s: s['id']):
            vecchio = s['alert']
            nuovo = []
            for a in vecchio:
                if a.startswith(PREF_EN):
                    t = it[en[a[len(PREF_EN):]]]
                    if t == '__TOGLI__':
                        n_tolti += 1
                        continue
                    a = 'Rischi: ' + t
                if a not in nuovo:
                    nuovo.append(a)
            if nuovo == vecchio:
                continue
            n_upd += 1
            fo.write(f"update public.schede set alert = {arr(nuovo)}, aggiornata_il = now() where id = '{s['id']}' and alert = {arr(vecchio)};\n")
            fr.write(f"update public.schede set alert = {arr(vecchio)} where id = '{s['id']}' and alert = {arr(nuovo)};\n")
    print('schede', n_upd, 'avvisi tolti', n_tolti)


if __name__ == '__main__':
    main()
