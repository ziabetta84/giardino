# Scarica le miniature (330px) delle candidate e dell'immagine attuale di ogni voce, e prepara un foglio
# di contatto numerato per voce, da guardare per scegliere le candidate da proporre.
#   python3 scripts/immagini/miniature.py [quante per voce, predefinito 12]
# Uscita in scripts/immagini/lavoro/ (git-ignorata): miniature/ e fogli/<voce>.jpg
import json, os, re, sys, time, urllib.request, urllib.error
from PIL import Image, ImageDraw

QUI = os.path.dirname(os.path.abspath(__file__))
DATI, LAVORO = os.path.join(QUI, 'dati'), os.path.join(QUI, 'lavoro')
UA = 'GiardinoZorba/1.0 (https://zorbaingiardino.app; robertagenovese@proton.me) python-urllib'


def url_miniatura(url, larghezza=330):
    percorso = url.split('?')[0].split('/wikipedia/commons/')[1]
    nome = percorso.split('/')[-1]
    coda = '.jpg' if nome.lower().endswith(('.tif', '.tiff')) else ''
    return f'https://upload.wikimedia.org/wikipedia/commons/thumb/{percorso}/{larghezza}px-{nome}{coda}'


def file_miniatura(url):
    nome = url.split('?')[0].split('/')[-1]
    return os.path.join(LAVORO, 'miniature', re.sub(r'[^A-Za-z0-9._-]', '_', nome)[-120:] + '.jpg')


def scarica(url):
    dest = file_miniatura(url)
    if os.path.exists(dest):
        return dest
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    for _ in range(8):
        try:
            req = urllib.request.Request(url_miniatura(url), headers={'User-Agent': UA})
            with urllib.request.urlopen(req, timeout=60) as r:
                dati = r.read()
            with open(dest, 'wb') as f:
                f.write(dati)
            return dest
        except urllib.error.HTTPError as e:
            if e.code in (429, 503):
                time.sleep(int(e.headers.get('retry-after') or 5) + 1)
                continue
            print('  miniatura', e.code, url, file=sys.stderr)
            return None
        except Exception as e:
            print('  miniatura', e, file=sys.stderr)
            time.sleep(3)
    return None


def main():
    quante = int(sys.argv[1]) if len(sys.argv) > 1 else 12
    voci = json.load(open(os.path.join(DATI, 'voci.json')))
    candidati = json.load(open(os.path.join(DATI, 'candidati.json')))
    os.makedirs(os.path.join(LAVORO, 'fogli'), exist_ok=True)
    L, A = 300, 225
    for n, (k, v) in enumerate(voci.items(), 1):
        lista = candidati.get(k, [])[:quante]
        attuale = (v.get('immagine') or {}).get('url')
        caselle = ([('attuale', attuale)] if attuale else []) + [(str(i), f['url']) for i, f in enumerate(lista)]
        righe = (len(caselle) + 3) // 4 or 1
        foglio = Image.new('RGB', (L * 4, (A + 22) * righe), 'white')
        d = ImageDraw.Draw(foglio)
        for j, (etichetta, url) in enumerate(caselle):
            x, y = (j % 4) * L, (j // 4) * (A + 22)
            dest = scarica(url)
            if dest:
                try:
                    im = Image.open(dest).convert('RGB')
                    im.thumbnail((L - 4, A - 4))
                    foglio.paste(im, (x + 2, y + 2))
                except Exception as e:
                    print('  immagine', e, file=sys.stderr)
            d.text((x + 4, y + A + 4), etichetta, fill='black')
        foglio.save(os.path.join(LAVORO, 'fogli', k.replace(':', '_') + '.jpg'), quality=80)
        print(f'{n}/{len(voci)} {v["nome"]}', flush=True)


if __name__ == '__main__':
    main()
