"""
Schede nuove dalle pagine RHS recuperate (controllo periodico, issue #153): un lotto di specie del catalogo che
non hanno nessuna scheda, né mostrata né nascosta, su sé stesse o sui loro sinonimi.

I testi (descrizione, potatura, propagazione, parassiti e malattie) sono scritti a mano in italiano, nello stile
delle schede, in dati/schede_nuove_lottoN.json; luce, acqua, terreno, rusticità e dimensioni vengono dalla
pagina RHS con le stesse traduzioni dell'import (completa_esigenze.py, rhs_dimensioni.py).
Le schede nascono mostrate e in bozza (stato_verifica 'bozza'), con la pagina RHS in fonti e il testo inglese in
descrizione_originale. Gli id sono fissi (uuid5 sul taxon), così il rollback toglie esattamente queste righe.

Uso:
    python3 schede_nuove.py TESTI.json SCELTE.json RECUPERATE.jsonl DATA OUT.sql ROLLBACK.sql
SCELTE.json: [{taxon_id, nome, rhs_id, titolo}] (pagina RHS scelta per ogni specie).
In TESTI.json la chiave facoltativa "dimensioni" (null o un testo) sostituisce le misure della pagina, quando è
quella di una cultivar più piccola o più grande della specie.
"""
import json, sys, uuid
from completa_esigenze import traduci, maiuscola, q, POSITION_IT, MOISTURE_IT, SOIL_IT, PH_IT
from rhs_dimensioni import extract_numbers, is_open, fmt_range

NS = uuid.UUID('6b1f0c2e-3d4a-4f5b-9c8d-7e6f5a4b3c2d')
RUSTICITA = {'H1A': 'non sotto i 15 °C', 'H1B': 'non sotto i 10 °C', 'H1C': 'non sotto i 5 °C', 'H2': 'non sotto 1 °C',
             'H3': 'fino a -5 °C', 'H4': 'fino a -10 °C', 'H5': 'fino a -15 °C', 'H6': 'fino a -20 °C',
             'H7': 'anche sotto i -20 °C'}


def fascia(testo):
    if not testo:
        return None
    nums = extract_numbers(testo)
    if not nums:
        return None
    if testo.lower().startswith('up to'):
        return f"fino a {nums[0]:g}m"
    return fmt_range((min(nums), max(nums)), oltre=is_open(testo))


def avvisi(d, t):
    a = [t['parassiti']]
    h = (d.get('hardiness') or '').upper().split(',')[0].strip()
    if h in RUSTICITA:
        a.append('Rusticità: minime ' + RUSTICITA[h])
    dims = [f"{k} {v}" for k, v in (('altezza', fascia(d.get('altezza_max'))), ('diffusione', fascia(d.get('diffusione_max')))) if v]
    if 'dimensioni' in t:  # pagina di una cultivar con misure diverse dalla specie: None le toglie, un testo le sostituisce
        dims = [t['dimensioni']] if t['dimensioni'] else []
    if dims:
        a.append('Dimensioni a maturità: ' + ', '.join(dims))
    a.append('Potatura: ' + t['potatura'])
    a.append('Propagazione: ' + t['propagazione'])
    return a


def esigenze(d):
    e = {}
    for k, v in (('luce', traduci(d.get('position'), POSITION_IT)), ('acqua', traduci(d.get('moisture'), MOISTURE_IT))):
        if v:
            e[k] = maiuscola(v)
    suolo, ph = traduci(d.get('soil_types'), SOIL_IT), traduci(d.get('ph'), PH_IT)
    v = '; '.join(x for x in (suolo, ('pH ' + ph) if ph else None) if x)
    if v:
        e['terreno'] = maiuscola(v)
    return e or None


def arr(xs):
    return 'array[' + ', '.join(q(x) for x in xs) + ']::text[]'


def main():
    testi_f, scelte_f, rec_f, data, out, rb = sys.argv[1:7]
    testi = json.load(open(testi_f, encoding='utf-8'))
    scelte = {s['nome']: s for s in json.load(open(scelte_f, encoding='utf-8'))}
    pagine = {}
    for l in open(rec_f, encoding='utf-8'):
        d = json.loads(l)
        pagine[str(d['rhs_id'])] = d
    righe = []
    for nome, t in sorted(testi.items()):
        s = scelte[nome]
        d = pagine[str(s['rhs_id'])]
        sid = str(uuid.uuid5(NS, s['taxon_id']))
        e = esigenze(d)
        righe.append((sid, s['taxon_id'], nome,
            f"({q(sid)}::uuid, {q(s['taxon_id'])}::uuid, {arr(['RHS (rhs.org.uk) — ' + s['titolo']])}, {q(t['descrizione'])}, "
            f"{q(d.get('descrizione_breve') or '')}, 'it', {q(json.dumps(e, ensure_ascii=False)) + '::jsonb' if e else 'null'}, "
            f"{q(t['ciclo_vitale'])}, {arr(avvisi(d, t))}, 'bozza', true, {q(t['forma'])}, "
            f"{q('controllo periodico RHS del ' + data + ', schede nuove; pagina RHS ' + str(s['rhs_id']))})"))
    ids = ', '.join(q(r[1]) + '::uuid' for r in righe)
    with open(out, 'w', encoding='utf-8') as f:
        f.write(f"-- Schede nuove dalle pagine RHS (controllo periodico del {data}): {len(righe)} specie del catalogo senza\n"
                "-- nessuna scheda. Testi in italiano scritti a mano (scripts/rhs-import/dati/), in bozza e mostrate.\n"
                "-- Generata da scripts/rhs-import/schede_nuove.py. Rollback: scripts/rhs-import/rollback_" + out.split('/')[-1].split('_', 1)[1] + "\n")
        f.write("do $$ begin\n"
                f"  if exists (select 1 from public.schede where taxon_id in ({ids})) then\n"
                "    raise exception 'una di queste specie ha già una scheda: lotto da rigenerare';\n  end if;\nend $$;\n")
        f.write("insert into public.schede (id, taxon_id, fonti, descrizione, descrizione_originale, lingua_descrizione, esigenze,\n"
                "  ciclo_vitale, alert, stato_verifica, mostrata, forma, nota) values\n")
        f.write(',\n'.join(r[3] for r in righe) + ';\n')
        f.write(f"do $$ declare n int; begin\n  select count(*) into n from public.schede where id in ({', '.join(q(r[0]) + '::uuid' for r in righe)});\n"
                f"  if n <> {len(righe)} then raise exception 'attese {len(righe)} schede, trovate %', n; end if;\nend $$;\n")
    with open(rb, 'w', encoding='utf-8') as r:
        r.write(f"-- Rollback delle schede nuove del controllo RHS del {data}: le toglie solo se nessuna è stata modificata dopo.\n")
        lista = ', '.join(q(x[0]) + '::uuid' for x in righe)
        r.write("do $$ begin\n"
                f"  if exists (select 1 from public.schede where id in ({lista}) and aggiornata_il > creata_il) then\n"
                "    raise exception 'una scheda del lotto è stata modificata dopo il caricamento: rollback rifiutato';\n  end if;\nend $$;\n")
        r.write(f"delete from public.schede where id in ({lista});\n")
    print('schede', len(righe))


if __name__ == '__main__':
    main()
