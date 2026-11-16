import json, time, urllib.request, urllib.parse, urllib.error, sys
UA = 'GiardinoZorba/1.0 (https://zorbaingiardino.app; robertagenovese@proton.me) python-urllib'
API = 'https://commons.wikimedia.org/w/api.php'
def get(params, base=API, tries=8):
    params = dict(params, format='json', formatversion='2', maxlag='5')
    url = base + '?' + urllib.parse.urlencode(params)
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': UA, 'Accept-Encoding': 'identity'})
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code in (429, 503):
                wait = int(e.headers.get('retry-after') or 10) + 2
                print(f'  {e.code}, attendo {wait}s', file=sys.stderr); time.sleep(wait); continue
            raise
        except Exception as e:
            print('  errore', e, file=sys.stderr); time.sleep(5)
    raise RuntimeError('troppi tentativi: ' + url)
