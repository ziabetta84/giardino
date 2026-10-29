# Riempimento automatico delle schede senza immagine: per ogni taxon l'immagine principale della sua categoria
# Commons («Category:<nome scientifico>», pageprops page_image_free, la stessa di Wikidata P18), tenuta solo se
# ha una licenza libera (CC0, pubblico dominio, CC BY, CC BY-SA: niente NC/ND), è una foto di almeno 500 px e il
# titolo non indica un dettaglio o altro (semi, erbario, foglia, insetti, cibo…: MALE[5] di punteggio.py) né una tavola
# botanica o un disegno.
# Nessuna immagine è meglio di una sbagliata: chi non passa resta senza.
#   python3 scripts/immagini/riempi/riempi.py raccogli lavoro/riempi_elenco.tsv   (elenco da elenco.sql; riprende da dove era)
#   python3 scripts/immagini/riempi/riempi.py campione 48                          (foglio lavoro/riempi_campione.jpg)
#   python3 scripts/immagini/riempi/riempi.py migrazione                           (migration e rollback)
# Secondo giro, per le schede rimaste senza (elenco2.sql): cerca anche con i sinonimi dello stesso rango e, quando
# l'immagine principale manca o non va, sceglie la foto migliore della categoria con il punteggio di punteggio.py
# (al più 3 categorie per scheda; autore = chi ha caricato il file se manca l'Artist).
#   python3 scripts/immagini/riempi/riempi.py secondo lavoro/riempi_elenco2.tsv
#   python3 scripts/immagini/riempi/riempi.py campione 48 2
#   python3 scripts/immagini/riempi/riempi.py migrazione 2
import html, json, os, re, sys, random, urllib.parse
QUI = os.path.dirname(os.path.abspath(__file__))
sys.path[:0] = [os.path.join(QUI, '..'), os.path.join(QUI, '..', 'raccolta')]
import wm
from punteggio import lic_ok, punteggio, MALE
from miniature import LAVORO, scarica

RADICE = os.path.dirname(os.path.dirname(os.path.dirname(QUI)))
CACHE = os.path.join(LAVORO, 'riempi_cache.json')
GIRI = {'1': ('riempimento.json', '20261029130000_immagini_automatiche', 'automatica 29/10/2026'),
        '2': ('riempimento2.json', '20261029140000_immagini_automatiche_2', 'automatica 29/10/2026, secondo giro')}
USCITA = os.path.join(QUI, '..', 'dati', GIRI['1'][0])
NOME, ORIGINE = GIRI['1'][1:]
MIME = ('image/jpeg', 'image/png', 'image/webp')
# tavole botaniche, stampe e disegni: belle ma non sono una foto della pianta
TAVOLE = r'bot\.? ?rep|bot\.? ?mag|curtis|flora|tab\.|\bpl\.|\bt\. ?\d|plate|tafel|illustr|drawing|disegno|lithograph|engraving|print\b|scan|book|page|sketch|watercolou?r|aquarel|\bbhl\b|biodiversity heritage|_pvd\b|\bpvd\b|\bbb-\d|floret|spikelet|spighett|\bdiptera\d|bot\.? ?reg'


def testo(h):
    return re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', '', h or ''))).strip()


def carica_cache():
    c = json.load(open(CACHE)) if os.path.exists(CACHE) else {}
    for k in ('categorie', 'file', 'esiste', 'membri'):
        c.setdefault(k, {})
    return c


def salva_cache(c):
    os.makedirs(LAVORO, exist_ok=True)
    json.dump(c, open(CACHE + '.tmp', 'w'), ensure_ascii=False)
    os.replace(CACHE + '.tmp', CACHE)


def a_blocchi(lista, n=50):
    for i in range(0, len(lista), n):
        yield lista[i:i + n]


def raccogli(elenco):
    righe = [r.split('\t') for r in open(elenco).read().splitlines() if r.strip()]
    nomi = sorted({n for _, n in righe})
    c = carica_cache()
    mancano = [n for n in nomi if n not in c['categorie']]
    print(f'{len(righe)} schede, {len(nomi)} nomi, {len(mancano)} categorie da chiedere', flush=True)
    for i, blocco in enumerate(a_blocchi(mancano), 1):
        r = wm.get({'action': 'query', 'prop': 'pageprops', 'ppprop': 'page_image_free',
                    'titles': '|'.join('Category:' + n for n in blocco)})
        norm = {x['to']: x['from'] for x in r['query'].get('normalized', [])}
        for p in r['query']['pages']:
            nome = norm.get(p['title'], p['title'])[len('Category:'):]
            c['categorie'][nome] = (p.get('pageprops') or {}).get('page_image_free')
        for n in blocco:
            c['categorie'].setdefault(n, None)
        salva_cache(c)
        print(f'  categorie {i}/{-(-len(mancano) // 50)}', flush=True)
    file = sorted({f for f in c['categorie'].values() if f} - set(c['file']))
    print(f'{len(file)} file da chiedere', flush=True)
    for i, blocco in enumerate(a_blocchi(file), 1):
        r = wm.get({'action': 'query', 'prop': 'imageinfo', 'iiprop': 'url|size|mime|extmetadata',
                    'iiextmetadatafilter': 'LicenseShortName|LicenseUrl|Artist|NonFree',
                    'titles': '|'.join('File:' + f for f in blocco)})
        norm = {x['to']: x['from'] for x in r['query'].get('normalized', [])}
        for p in r['query']['pages']:
            nome = norm.get(p['title'], p['title'])[len('File:'):]
            ii = (p.get('imageinfo') or [None])[0]
            if not ii:
                c['file'][nome] = None
                continue
            m = ii.get('extmetadata') or {}
            c['file'][nome] = {'titolo': p['title'], 'url': ii['url'], 'pagina': ii['descriptionurl'], 'w': ii['width'],
                               'h': ii['height'], 'mime': ii['mime'],
                               'licenza': (m.get('LicenseShortName') or {}).get('value', ''),
                               'licenza_url': (m.get('LicenseUrl') or {}).get('value', ''),
                               'autore': testo((m.get('Artist') or {}).get('value', '')),
                               'nonfree': (m.get('NonFree') or {}).get('value')}
        for f in blocco:
            c['file'].setdefault(f, None)
        salva_cache(c)
        print(f'  file {i}/{-(-len(file) // 50)}', flush=True)
    scegli(righe, c)


def info_file(p):
    ii = (p.get('imageinfo') or [None])[0]
    if not ii:
        return None
    m = ii.get('extmetadata') or {}
    v = lambda k: (m.get(k) or {}).get('value', '')
    return {'titolo': p['title'], 'url': ii['url'], 'pagina': ii['descriptionurl'], 'w': ii['width'], 'h': ii['height'],
            'mime': ii['mime'], 'licenza': v('LicenseShortName'), 'licenza_url': v('LicenseUrl'),
            'autore': testo(v('Artist')) or ii.get('user', ''), 'nonfree': v('NonFree') or None,
            'descrizione': testo(v('ImageDescription'))[:300]}


def chiedi_categorie(c, nomi):
    """Per ogni nome: se la categoria esiste e la sua immagine principale."""
    mancano = [n for n in dict.fromkeys(nomi) if n not in c['esiste']]
    for i, blocco in enumerate(a_blocchi(mancano), 1):
        r = wm.get({'action': 'query', 'prop': 'pageprops', 'ppprop': 'page_image_free',
                    'titles': '|'.join('Category:' + n for n in blocco)})
        norm = {x['to']: x['from'] for x in r['query'].get('normalized', [])}
        for p in r['query']['pages']:
            nome = norm.get(p['title'], p['title'])[len('Category:'):]
            c['esiste'][nome] = not p.get('missing') and not p.get('invalid')
            c['categorie'][nome] = (p.get('pageprops') or {}).get('page_image_free')
        for n in blocco:
            c['esiste'].setdefault(n, False)
            c['categorie'].setdefault(n, None)
        salva_cache(c)
        print(f'  categorie {i}/{-(-len(mancano) // 50)}', flush=True)


def chiedi_file(c, nomi_file):
    mancano = sorted(set(f for f in nomi_file if f) - set(c['file']))
    for i, blocco in enumerate(a_blocchi(mancano), 1):
        r = wm.get({'action': 'query', 'prop': 'imageinfo', 'iiprop': 'url|size|mime|user|extmetadata',
                    'iiextmetadatafilter': 'LicenseShortName|LicenseUrl|Artist|NonFree|ImageDescription',
                    'titles': '|'.join('File:' + f for f in blocco)})
        norm = {x['to']: x['from'] for x in r['query'].get('normalized', [])}
        for p in r['query']['pages']:
            c['file'][norm.get(p['title'], p['title'])[len('File:'):]] = info_file(p)
        for f in blocco:
            c['file'].setdefault(f, None)
        salva_cache(c)
        print(f'  file {i}/{-(-len(mancano) // 50)}', flush=True)


def chiedi_membri(c, categoria):
    if categoria not in c['membri']:
        r = wm.get({'action': 'query', 'generator': 'categorymembers', 'gcmtitle': 'Category:' + categoria,
                    'gcmtype': 'file', 'gcmlimit': '50', 'prop': 'imageinfo', 'iiprop': 'url|size|mime|user|extmetadata',
                    'iiextmetadatafilter': 'LicenseShortName|LicenseUrl|Artist|NonFree|ImageDescription'})
        c['membri'][categoria] = [f for f in (info_file(p) for p in (r.get('query') or {}).get('pages', [])) if f]
        salva_cache(c)
    return c['membri'][categoria]


def secondo(elenco):
    righe = [r.split('\t') for r in open(elenco).read().splitlines() if r.strip()]
    schede = [(sid, nome, [nome] + [x for x in sin.split('|') if x]) for sid, _, nome, sin in righe]
    c = carica_cache()
    print(f'{len(schede)} schede, {sum(len(n) for _, _, n in schede)} nomi', flush=True)
    chiedi_categorie(c, [n for _, _, nomi in schede for n in nomi])
    chiedi_file(c, [c['categorie'].get(n) for _, _, nomi in schede for n in nomi])
    esito, conta = {}, {}
    da_esplorare = sum(1 for _, _, nomi in schede if not any(c['categorie'].get(n) and not motivo_scarto(c['file'].get(c['categorie'][n])) for n in nomi))
    print(f'{da_esplorare} schede da cercare dentro le categorie', flush=True)
    for j, (sid, nome, nomi) in enumerate(schede, 1):
        presa, come = None, None
        for n in nomi:
            f = c['file'].get(c['categorie'].get(n) or '')
            if c['categorie'].get(n) and not motivo_scarto(f):
                presa, come = f, 'principale' + (' (sinonimo)' if n != nome else '')
                break
        if not presa:
            principali = {'File:' + c['categorie'][n].replace('_', ' ') for n in nomi if c['categorie'].get(n)}
            migliori = []
            for n in [n for n in nomi if c['esiste'].get(n)][:3]:
                parti = n.lower().replace('×', ' ').split()
                for f in chiedi_membri(c, n):
                    # dentro una categoria ci finisce di tutto (insetti, statue, altre piante): il nome del file
                    # deve contenere il genere o l'epiteto del nome cercato; niente file «GBIF» (spesso erbari)
                    t = f['titolo'].lower().replace('_', ' ')
                    if motivo_scarto(f) or 'gbif' in t or not (parti[0] in t or (len(parti) > 1 and parti[-1] in t)):
                        continue
                    pf = punteggio(f, n, principali)
                    if pf >= 0:
                        migliori.append((pf, f, n))
            if migliori:
                _, presa, n = max(migliori, key=lambda x: x[0])
                come = 'dalla categoria' + (' (sinonimo)' if n != nome else '')
            if j % 100 == 0:
                print(f'  schede {j}/{len(schede)}', flush=True)
        conta[come or 'nessuna'] = conta.get(come or 'nessuna', 0) + 1
        if presa:
            esito[sid] = {'nome': nome, 'immagine': immagine(presa, GIRI['2'][2])}
    json.dump(esito, open(os.path.join(QUI, '..', 'dati', GIRI['2'][0]), 'w'), ensure_ascii=False, indent=0, sort_keys=True)
    for k, v in sorted(conta.items(), key=lambda x: -x[1]):
        print(f'{v:6d}  {k}')


def immagine(f, origine):
    return {'url': f['url'].split('?')[0], 'licenza': f['licenza'], 'licenza_url': f['licenza_url'] or '',
            'attribuzione': f['autore'][:300], 'fonte_pagina': urllib.parse.unquote(f['pagina'].split('?')[0]),
            'verificata': False, 'origine': origine}


def motivo_scarto(f):
    if not f:
        return 'file non trovato'
    if not lic_ok(f):
        return 'licenza'
    if f['mime'] not in MIME:
        return 'formato'
    if min(f['w'], f['h']) < 500:
        return 'piccola'
    if re.search(MALE[5], f['titolo'].lower()):
        return 'dettaglio o altro'
    if re.search(TAVOLE, f['titolo'].lower()) or re.search(r'illustrat|drawn|engrav|derivative|britton|addison brown', f['autore'].lower()):
        return 'tavola o disegno'
    if not f['autore']:
        return 'senza autore'
    return None


def scegli(righe, c):
    esito, conta = {}, {}
    for sid, nome in righe:
        nf = c['categorie'].get(nome)
        f = c['file'].get(nf) if nf else None
        m = 'nessuna categoria o immagine' if not nf else motivo_scarto(f)
        conta[m or 'presa'] = conta.get(m or 'presa', 0) + 1
        if m:
            continue
        esito[sid] = {'nome': nome, 'immagine': {
            'url': f['url'].split('?')[0], 'licenza': f['licenza'], 'licenza_url': f['licenza_url'] or '',
            'attribuzione': f['autore'][:300], 'fonte_pagina': urllib.parse.unquote(f['pagina'].split('?')[0]),
            'verificata': False, 'origine': ORIGINE}}
    json.dump(esito, open(USCITA, 'w'), ensure_ascii=False, indent=0, sort_keys=True)
    for k, v in sorted(conta.items(), key=lambda x: -x[1]):
        print(f'{v:6d}  {k}')
    print(USCITA)


def campione(n, giro='1'):
    from PIL import Image, ImageDraw
    esito = json.load(open(os.path.join(QUI, '..', 'dati', GIRI[giro][0])))
    scelte = random.Random(29).sample(sorted(esito.items()), min(n, len(esito)))
    W, H = 300, 225
    foglio = Image.new('RGB', (W * 6, (H + 22) * (-(-len(scelte) // 6))), 'white')
    d = ImageDraw.Draw(foglio)
    for j, (_, v) in enumerate(scelte):
        x, y = (j % 6) * W, (j // 6) * (H + 22)
        dest = scarica(v['immagine']['url'])
        if dest:
            im = Image.open(dest).convert('RGB')
            im.thumbnail((W - 4, H - 4))
            foglio.paste(im, (x + 2, y + 2))
        d.text((x + 4, y + H + 4), v['nome'][:45], fill='black')
        print(f'{j + 1}/{len(scelte)}', flush=True)
    out = os.path.join(LAVORO, f'riempi_campione{giro if giro != "1" else ""}.jpg')
    foglio.save(out, quality=80)
    print(out)


def lit(x):
    return "'" + x.replace("'", "''") + "'"


def migrazione(giro='1'):
    uscita, NOME, ORIGINE = GIRI[giro]
    esito = json.load(open(os.path.join(QUI, '..', 'dati', uscita)))
    righe = ',\n'.join(f"    ({lit(sid)}::uuid, {lit(json.dumps(v['immagine'], ensure_ascii=False))}::jsonb)"
                       for sid, v in sorted(esito.items()))
    n = len(esito)
    sql = f"""-- Immagini automatiche ({ORIGINE}) per le schede mostrate di taxon che non ne avevano (approvato da Roberta).
-- Generata da scripts/immagini/riempi/riempi.py (criteri nell'intestazione dello script): non modificare a mano.
-- Ogni immagine porta "origine": "{ORIGINE}" e "verificata": false; tocca solo schede ancora senza immagine.
-- Rollback: scripts/immagini/riempi/rollback_{NOME}.sql

do $$
declare n int;
begin
  update public.schede s set immagine = v.immagine
  from (values
{righe}
  ) as v(id, immagine)
  where s.id = v.id and s.mostrata and (s.immagine is null or s.immagine->>'url' is null);
  get diagnostics n = row_count;
  if n <> {n} then
    raise exception 'schede aggiornate: % invece di {n}', n;
  end if;
end $$;
"""
    rb = f"""-- Rollback di supabase/migrations/{NOME}.sql: toglie le immagini automatiche (le schede erano tutte senza immagine).
-- psql "$SUPABASE_DB_URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/immagini/riempi/rollback_{NOME}.sql
update public.schede set immagine = null where immagine->>'origine' = {lit(ORIGINE)};
"""
    open(os.path.join(RADICE, 'supabase', 'migrations', NOME + '.sql'), 'w').write(sql)
    open(os.path.join(QUI, f'rollback_{NOME}.sql'), 'w').write(rb)
    print(n, 'schede;', round(len(sql) / 1e6, 1), 'MB')


if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'raccogli':
        raccogli(sys.argv[2])
    elif cmd == 'secondo':
        secondo(sys.argv[2])
    elif cmd == 'campione':
        campione(int(sys.argv[2]) if len(sys.argv) > 2 else 48, *sys.argv[3:4])
    elif cmd == 'migrazione':
        migrazione(*sys.argv[2:3])
