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


extra = json.load(open(S + '/extra.json'))
for k, qs in extra.items():
    for q in qs:
        cache = json.load(open(p)); globals()['cache'] = cache
        cerca(q)
print('FINE', flush=True)
