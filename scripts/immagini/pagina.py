# Costruisce la pagina per scegliere la foto di ogni voce: per voce l'immagine attuale e le candidate indicate in
# dati/proposte.json (indici in dati/candidati.json), con le miniature incorporate (WebP 280px).
#   python3 scripts/immagini/pagina.py      →  scripts/immagini/lavoro/pagina.html
# Le scelte si salvano nel database della pagina pubblicata (collezione «scelte», un documento per voce).
import base64, io, json, os, sys, urllib.parse
from PIL import Image
from miniature import DATI, LAVORO, scarica

QUI = os.path.dirname(os.path.abspath(__file__))


def data_uri(url):
    dest = scarica(url)
    if not dest:
        return None
    im = Image.open(dest).convert('RGB')
    im.thumbnail((280, 280))
    buf = io.BytesIO()
    im.save(buf, 'WEBP', quality=62)
    return 'data:image/webp;base64,' + base64.b64encode(buf.getvalue()).decode()


def foto(f):
    return {'titolo': f['titolo'][5:] if f['titolo'].startswith('File:') else f['titolo'], 'url': f['url'].split('?')[0],
            'pagina': f['pagina'].split('?')[0], 'licenza': f['licenza'], 'licenza_url': f.get('licenza_url'),
            'autore': f['autore'], 'w': f['w'], 'h': f['h'], 'qualita': bool(f.get('qualita')), 'miniatura': data_uri(f['url'])}


def main():
    voci = json.load(open(os.path.join(DATI, 'voci.json')))
    candidati = json.load(open(os.path.join(DATI, 'candidati.json')))
    proposte = json.load(open(os.path.join(DATI, 'proposte.json')))
    righe = []
    if os.environ.get('SOLO'):
        voci = dict(list(voci.items())[:int(os.environ['SOLO'])])
    for n, (k, v) in enumerate(voci.items(), 1):
        p = proposte.get(k, {})
        att = v.get('immagine')
        attuale = None
        if att and att.get('url'):
            attuale = {'titolo': urllib.parse.unquote(att['fonte_pagina'].split('File:')[-1]).replace('_', ' ') if att.get('fonte_pagina') else '', 'url': att['url'],
                       'pagina': att.get('fonte_pagina'), 'licenza': att.get('licenza'), 'autore': att.get('attribuzione'),
                       'miniatura': data_uri(att['url'])}
        url_attuale = (att or {}).get('url', '').split('?')[0]
        lista = [foto(candidati[k][i]) for i in p.get('candidate', range(6))
                 if i < len(candidati.get(k, [])) and candidati[k][i]['url'].split('?')[0] != url_attuale]
        righe.append({'chiave': k, 'nome': v['nome'], 'specie': v['specie'], 'tipo': v['tipo'],
                      'problema': p.get('problema'), 'nota': p.get('nota'), 'attuale': attuale,
                      'candidate': [f for f in lista if f['miniatura']]})
        print(f'{n}/{len(voci)} {v["nome"]}', flush=True)
    modello = open(os.path.join(QUI, 'pagina.html')).read()
    dati = json.dumps(righe, ensure_ascii=False).replace('</', '<\\/')
    os.makedirs(LAVORO, exist_ok=True)
    out = os.path.join(LAVORO, 'pagina.html')
    open(out, 'w').write(modello.replace('/*DATI*/[]', dati))
    print(out, round(os.path.getsize(out) / 1e6, 1), 'MB')


if __name__ == '__main__':
    main()
