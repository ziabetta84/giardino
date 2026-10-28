# Per ogni voce: candidati filtrati e ordinati, miniature 330px scaricate, foglio di contatto numerato
import json, sys, os, re, time, urllib.request, urllib.parse, io
sys.path.insert(0, os.path.dirname(__file__)); import wm
from punteggio import lic_ok, punteggio
from PIL import Image, ImageDraw, ImageFont
S = sys.argv[1]; solo = sys.argv[2:] 
voci = json.load(open(S + '/voci.json')); piani = json.load(open(S + '/piani.json'))
cache = json.load(open(S + '/ricerche.json')); cat = json.load(open(S + '/categorie.json'))
extra = json.load(open(S + '/extra.json')) if os.path.exists(S + '/extra.json') else {}
princ = {f['titolo']: f for f in cache['principali']}
os.makedirs(S + '/thumb', exist_ok=True); os.makedirs(S + '/fogli', exist_ok=True)
def thumb_url(url, w=330):
    p = url.split('?')[0].split('/wikipedia/commons/')[1]; nome = p.split('/')[-1]
    return f'https://upload.wikimedia.org/wikipedia/commons/thumb/{p}/{w}px-{nome}' + ('.jpg' if nome.lower().endswith(('.tif', '.tiff')) else '')
def scarica(url, dest):
    if os.path.exists(dest): return True
    for i in range(6):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': wm.UA})
            with urllib.request.urlopen(req, timeout=60) as r: open(dest, 'wb').write(r.read()); return True
        except urllib.error.HTTPError as e:
            if e.code == 429: time.sleep(int(e.headers.get('retry-after') or 10) + 1); continue
            print('  thumb', e.code, url, file=sys.stderr); return False
        except Exception as e: print('  thumb', e, file=sys.stderr); time.sleep(3)
    return False
candidati = {}
for k, v in voci.items():
    if solo and not any(k.startswith(s) for s in solo): continue
    sci = v['specie']; m = re.match(r"^(.*?) '(.+)'$", sci); base = m.group(1) if m else sci
    visti, lista = set(), []
    pr = set()
    for n in (sci, base):
        im = (cat.get(n) or {}).get('immagine')
        if im: pr.add('File:' + im.replace('_', ' '))
    fonti = [princ[t] for t in pr if t in princ]
    genere = base.split(' ')[0].lower().replace('×', '').strip()
    for q in piani[k]:
        fonti += [f for f in cache.get(q, []) if genere in (f['titolo'] + ' ' + (f.get('descrizione') or '')).lower()]
    for q in extra.get(k, []): fonti += cache.get(q, [])
    for f in fonti:
        if f['titolo'] in visti or not lic_ok(f) or f['mime'] not in ('image/jpeg', 'image/png', 'image/webp'): continue
        visti.add(f['titolo'])
        f = dict(f, url=f['url'].split('?')[0], pagina=f['pagina'].split('?')[0], punti=punteggio(f, sci, pr), principale=f['titolo'] in pr)
        lista.append(f)
    lista.sort(key=lambda f: -f['punti'])
    lista = lista[:int(os.environ.get("QUANTI", 16))]
    candidati[k] = lista
    if os.environ.get('SENZA_FOGLI'):
        print(v['nome'], len(lista), flush=True); continue
    # foglio di contatto 4x4
    W, H = 300, 225
    foglio = Image.new('RGB', (W * 4, (H + 22) * ((len(lista) + 3) // 4 or 1)), 'white')
    d = ImageDraw.Draw(foglio)
    for i, f in enumerate(lista):
        dest = S + '/thumb/' + re.sub(r'[^A-Za-z0-9._-]', '_', f['titolo'][5:])[-120:] + '.jpg'
        if scarica(thumb_url(f['url']), dest):
            try:
                im = Image.open(dest).convert('RGB'); im.thumbnail((W - 4, H - 4))
                foglio.paste(im, ((i % 4) * W + 2, (i // 4) * (H + 22) + 2))
            except Exception as e: print('  img', e, file=sys.stderr)
        d.text(((i % 4) * W + 4, (i // 4) * (H + 22) + H + 2), f"{i}  {f['punti']:+.0f} {'P ' if f['principale'] else ''}{'Q ' if f['qualita'] else ''}{f['w']}x{f['h']}", fill='black')
    foglio.save(S + f'/fogli/{k[:10].replace(":", "_")}.jpg', quality=80)
    print(v['nome'], len(lista), flush=True)
old = json.load(open(S + '/candidati.json')) if os.path.exists(S + '/candidati.json') else {}
old.update(candidati); json.dump(old, open(S + '/candidati.json', 'w'), ensure_ascii=False, indent=1)
