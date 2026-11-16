# Una richiesta per nome (generator=search con imageinfo e categorie di qualità) + immagine principale delle categorie
import json, sys, re, os, html
sys.path.insert(0, os.path.dirname(__file__)); import wm
S = sys.argv[1]
voci = json.load(open(S + '/voci.json'))
p = S + '/ricerche.json'
cache = json.load(open(p)) if os.path.exists(p) else {}
QUAL = 'Category:Quality images|Category:Valued images|Category:Featured pictures on Wikimedia Commons'
def pulisci(s): return html.unescape(re.sub(r'<[^>]+>', '', s or '')).strip()

def file_da_pagine(pages):
    out = []
    for pg in sorted(pages, key=lambda x: x.get('index', 0)):
        ii = (pg.get('imageinfo') or [None])[0]
        if not ii: continue
        md = {k: v.get('value') for k, v in ii.get('extmetadata', {}).items()}
        out.append({'titolo': pg['title'], 'url': ii['url'], 'pagina': ii['descriptionurl'], 'w': ii['width'], 'h': ii['height'],
                    'mime': ii['mime'], 'qualita': [c['title'][9:] for c in pg.get('categories', [])],
                    'licenza': pulisci(md.get('LicenseShortName')), 'licenza_url': md.get('LicenseUrl'),
                    'autore': pulisci(md.get('Artist'))[:200], 'descrizione': pulisci(md.get('ImageDescription'))[:300],
                    'nonfree': md.get('NonFree'), 'restrizioni': md.get('Restrictions')})
    return out

def cerca(q, n=50):
    if q in cache: return
    r = wm.get({'action': 'query', 'generator': 'search', 'gsrsearch': q, 'gsrnamespace': 6, 'gsrlimit': n,
                'prop': 'imageinfo|categories', 'clcategories': QUAL, 'cllimit': 'max',
                'iiprop': 'url|size|mime|extmetadata',
                'iiextmetadatafilter': 'LicenseShortName|LicenseUrl|Artist|ImageDescription|NonFree|Restrictions'})
    cache[q] = file_da_pagine(r.get('query', {}).get('pages', []))
    json.dump(cache, open(p, 'w'), ensure_ascii=False)
    print(len(cache[q]), q, flush=True)

piani = {}
nomi_cat = set()
for k, v in voci.items():
    sci = v['specie']; m = re.match(r"^(.*?) '(.+)'$", sci)
    base = m.group(1) if m else sci
    qs = [f'filetype:bitmap deepcat:"{base.replace(" ", "_")}"']
    nomi_cat.add(base)
    if m:
        nomi_cat.add(sci)
        qs.insert(0, f'filetype:bitmap "{m.group(2)}" deepcat:"{base.split(" ")[0]}"')
    piani[k] = qs
# immagini principali delle categorie (≈ P18 di Wikidata), 50 per richiesta
cp = S + '/categorie.json'
cat = json.load(open(cp)) if os.path.exists(cp) else {}
mancanti = [n for n in sorted(nomi_cat) if n not in cat]
for i in range(0, len(mancanti), 50):
    r = wm.get({'action': 'query', 'titles': '|'.join('Category:' + n for n in mancanti[i:i+50]), 'prop': 'pageprops'})
    norm = {x['to']: x['from'] for x in r['query'].get('normalized', [])}
    for pg in r['query']['pages']:
        n = norm.get(pg['title'], pg['title'])[9:]
        pp = pg.get('pageprops', {})
        cat[n] = {'esiste': not pg.get('missing'), 'immagine': pp.get('page_image_free'), 'wikidata': pp.get('wikibase_item')}
    json.dump(cat, open(cp, 'w'), ensure_ascii=False, indent=1)
print('categorie', len(cat), flush=True)
# immagini principali: imageinfo
princ = [('File:' + c['immagine']) for c in cat.values() if c.get('immagine')]
qp = 'principali'
if qp not in cache:
    tutte = []
    for i in range(0, len(princ), 50):
        r = wm.get({'action': 'query', 'titles': '|'.join(princ[i:i+50]), 'prop': 'imageinfo|categories', 'clcategories': QUAL, 'cllimit': 'max',
                    'iiprop': 'url|size|mime|extmetadata', 'iiextmetadatafilter': 'LicenseShortName|LicenseUrl|Artist|ImageDescription|NonFree|Restrictions'})
        tutte += file_da_pagine(r['query']['pages'])
    cache[qp] = tutte; json.dump(cache, open(p, 'w'), ensure_ascii=False)
for k, qs in piani.items():
    for q in qs: cerca(q)
json.dump(piani, open(S + '/piani.json', 'w'), ensure_ascii=False, indent=1)
print('FINE', flush=True)
