#!/usr/bin/env python3
"""Copia le foto della galleria da docs/gallery/piante/ al bucket `galleria` di Supabase Storage e crea le righe di
`public.foto` (migration 20261028120000_galleria_foto.sql), tutte a nome di un utente.

Per ogni foto riparte dall'originale e rigenera le tre versioni come fa l'app, in WebP: originale al più LATO px
(qualità 80), media 640px (75), miniatura 120px (70). Le derivate già nel repository non si usano.
Le cartelle di piante che non esistono più (o di un altro utente) si saltano, a meno di --orfane generale, che le
carica come foto generiche.

Si può rilanciare: percorsi deterministici, i file si sovrascrivono e le righe già presenti si saltano.

Uso:
  SUPABASE_URL=https://ncuhhsvtjwcolhpdxbkt.supabase.co SUPABASE_SERVICE_ROLE_KEY=… \\
    python3 scripts/galleria/migra_foto.py --owner UUID [--prova] [--lato 1600] [--orfane salta|generale]
La chiave service_role non va mai nel repository.
"""
import argparse
import io
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

from PIL import Image, ImageOps

CARTELLA = os.path.join(os.path.dirname(__file__), '..', '..', 'docs', 'gallery', 'piante')
RE_DERIVATA = re.compile(r'_(thumb|medium)\.(jpe?g|png|webp)$', re.I)
RE_IMG = re.compile(r'\.(jpe?g|png|gif|webp)$', re.I)


def richiesta(metodo, url, chiave, corpo=None, tipo='application/json', extra=None):
    intestazioni = {'Authorization': f'Bearer {chiave}', 'apikey': chiave, 'Content-Type': tipo, **(extra or {})}
    dati = corpo if isinstance(corpo, (bytes, type(None))) else json.dumps(corpo).encode()
    req = urllib.request.Request(url, data=dati, method=metodo, headers=intestazioni)
    try:
        with urllib.request.urlopen(req) as r:
            testo = r.read()
            return json.loads(testo) if testo else None
    except urllib.error.HTTPError as e:
        sys.exit(f'{metodo} {url}: {e.code} {e.read().decode(errors="replace")}')


def webp(img, lato, qualita):
    c = img.copy()
    if lato:
        c.thumbnail((lato, lato), Image.LANCZOS)
    b = io.BytesIO()
    c.save(b, 'WEBP', quality=qualita, method=6)
    return b.getvalue()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--owner', required=True, help="uuid dell'utente a cui vanno le foto")
    ap.add_argument('--prova', action='store_true', help='mostra cosa farebbe, senza caricare niente')
    ap.add_argument('--lato', type=int, default=1600, help='lato lungo massimo degli originali (0 = invariato)')
    ap.add_argument('--orfane', choices=['salta', 'generale'], default='salta')
    a = ap.parse_args()

    url = os.environ.get('SUPABASE_URL', 'https://ncuhhsvtjwcolhpdxbkt.supabase.co').rstrip('/')
    chiave = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')
    if not chiave:
        sys.exit('Manca SUPABASE_SERVICE_ROLE_KEY')

    owner = urllib.parse.quote(a.owner)
    piante = {r['id'] for r in richiesta('GET', f'{url}/rest/v1/piante?select=id&owner_id=eq.{owner}', chiave)}
    esistenti = {r['percorso'] for r in richiesta('GET', f'{url}/rest/v1/foto?select=percorso&owner_id=eq.{owner}', chiave)}

    prima = dopo = caricate = saltate = 0
    for cartella in sorted(os.listdir(CARTELLA)):
        dir_ = os.path.join(CARTELLA, cartella)
        if not os.path.isdir(dir_):
            continue
        if cartella in piante:
            pianta_id, dest = cartella, cartella
        elif a.orfane == 'generale':
            pianta_id, dest = None, 'generale'
        else:
            print(f'salto {cartella}: la pianta non esiste più')
            continue
        for nome in sorted(os.listdir(dir_)):
            if not RE_IMG.search(nome) or RE_DERIVATA.search(nome):
                continue
            ts = int(nome.split('_')[0])
            radice = os.path.splitext(nome)[0]
            base = f'{a.owner}/{dest}/{radice}'
            percorso = f'{base}.webp'
            sorgente = os.path.join(dir_, nome)
            img = ImageOps.exif_transpose(Image.open(sorgente)).convert('RGB')
            originale = webp(img, a.lato, 80)
            # Una foto già ben compressa e non più grande di LATO può pesare di più in WebP: si tiene il file com'è.
            con_jpeg = (len(originale) >= os.path.getsize(sorgente) and max(img.size) <= (a.lato or max(img.size))
                        and nome.lower().endswith(('.jpg', '.jpeg')))
            if con_jpeg:
                percorso = f'{base}.jpg'
                with open(sorgente, 'rb') as f:
                    originale = f.read()
            versioni = {
                percorso: originale,
                f'{base}_medium.webp': webp(img, 640, 75),
                f'{base}_thumb.webp': webp(img, 120, 70),
            }
            if percorso in esistenti:
                saltate += 1
                continue
            prima += os.path.getsize(sorgente)
            dopo += sum(len(v) for v in versioni.values())
            print(f'{cartella}/{nome} → {percorso} ({os.path.getsize(sorgente) // 1024} → {len(versioni[percorso]) // 1024} KB)')
            if a.prova:
                continue
            for p, dati in versioni.items():
                richiesta('POST', f'{url}/storage/v1/object/galleria/{urllib.parse.quote(p)}', chiave, dati,
                          'image/jpeg' if p.endswith('.jpg') else 'image/webp', {'x-upsert': 'true', 'cache-control': 'max-age=31536000'})
            richiesta('POST', f'{url}/rest/v1/foto', chiave, {
                'owner_id': a.owner, 'pianta_id': pianta_id,
                'scattata_il': datetime.fromtimestamp(ts / 1000, timezone.utc).isoformat(),
                'percorso': percorso, 'percorso_media': f'{base}_medium.webp', 'percorso_miniatura': f'{base}_thumb.webp',
            }, extra={'Prefer': 'return=minimal'})
            caricate += 1

    azione = 'da caricare' if a.prova else 'caricate'
    print(f'\nfoto {azione}: {caricate if not a.prova else "vedi sopra"}, già presenti: {saltate}')
    print(f'originali {prima / 1e6:.1f} MB → tre versioni {dopo / 1e6:.1f} MB')


if __name__ == '__main__':
    main()
