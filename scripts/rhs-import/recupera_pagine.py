"""
Recupero delle pagine RHS mancanti, dal cloud (controllo periodico, issue #153).

Confronta per ID numerico l'indice RHS di oggi (sitemap-plants-N.xml) con
la base delle pagine già lette (id_map.tsv del download di agosto più gli
ID già recuperati), scarica solo le mancanti e tiene di ogni pagina il
risultato del parser (parse_rhs.parse_file), non l'HTML: 70.000 pagine
HTML occuperebbero circa 9 GB, i record letti circa 1 KB l'una.

Resumibile: salta gli ID già presenti in OUT. Una richiesta ogni PAUSA
secondi, come il download di agosto.

Uso:
    python3 recupera_pagine.py BASE_DIR OUT_DIR [--limit=N]
BASE_DIR contiene id_map.tsv; OUT_DIR riceve:
    indice_AAAAMMGG.tsv   id, url di tutte le pagine dell'indice di oggi
    recuperate.jsonl      un record per pagina scaricata (rhs_id, url, campi del parser)
    errori.tsv            id, url, codice HTTP o eccezione (si riprovano tutti tranne 404/410)
"""
import json, os, re, sys, tempfile, time, datetime
import requests

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from parse_rhs import parse_file

SITEMAP = "https://www.rhs.org.uk/sitemap-plants-{}.xml"
PAUSA = 0.5


def indice_oggi(session):
    pagine = {}
    i = 1
    while True:
        r = session.get(SITEMAP.format(i), timeout=60)
        if r.status_code != 200 or "<loc>" not in r.text:
            break
        for url in re.findall(r"<loc>(https?://[^<]+)</loc>", r.text):
            m = re.search(r"/plants/(\d+)/", url)
            if m:
                pagine[m.group(1)] = url
        i += 1
    return pagine


def leggi_ids(path, colonna):
    ids = set()
    if os.path.exists(path):
        with open(path, encoding="utf-8") as fh:
            for riga in fh:
                if colonna == "json":
                    try:
                        ids.add(str(json.loads(riga)["rhs_id"]))
                    except (ValueError, KeyError):
                        pass
                elif colonna == "404":
                    parti = riga.rstrip("\n").split("\t")
                    if len(parti) == 3 and parti[2] in ("404", "410"):
                        ids.add(parti[0])
                else:
                    ids.add(riga.split("\t", 1)[0].strip())
    return ids


def main():
    base_dir, out_dir = sys.argv[1], sys.argv[2]
    limite = next((int(a.split("=")[1]) for a in sys.argv[3:] if a.startswith("--limit=")), None)
    os.makedirs(out_dir, exist_ok=True)
    session = requests.Session()
    session.headers.update({"User-Agent": "Mozilla/5.0 (giardino; controllo catalogo)"})

    pagine = indice_oggi(session)
    oggi = datetime.date.today().strftime("%Y%m%d")
    with open(os.path.join(out_dir, f"indice_{oggi}.tsv"), "w", encoding="utf-8") as fh:
        for k in sorted(pagine, key=int):
            fh.write(f"{k}\t{pagine[k]}\n")

    out = os.path.join(out_dir, "recuperate.jsonl")
    err = os.path.join(out_dir, "errori.tsv")
    fatti = leggi_ids(os.path.join(base_dir, "id_map.tsv"), "tsv") | leggi_ids(out, "json") | leggi_ids(err, "404")
    da_fare = sorted((k for k in pagine if k not in fatti), key=int)
    if limite:
        da_fare = da_fare[:limite]
    print(f"indice {len(pagine)}, già lette {len(fatti)}, da scaricare {len(da_fare)}", flush=True)

    tmp = tempfile.mkdtemp()
    with open(out, "a", encoding="utf-8") as fo, open(err, "a", encoding="utf-8") as fe:
        for n, k in enumerate(da_fare, 1):
            url = pagine[k]
            try:
                r = session.get(url, timeout=30)
                if r.status_code != 200:
                    fe.write(f"{k}\t{url}\t{r.status_code}\n"); fe.flush()
                else:
                    p = os.path.join(tmp, re.search(r"/plants/\d+/([^/]+)", url).group(1)[:150] + ".html")
                    with open(p, "w", encoding="utf-8") as fh:
                        fh.write(r.text)
                    d = parse_file(p)
                    os.remove(p)
                    d["rhs_id"] = int(k)
                    d["url"] = url
                    d["scaricata_il"] = oggi
                    fo.write(json.dumps(d, ensure_ascii=False) + "\n"); fo.flush()
            except Exception as e:  # rete o parser: si annota e si va avanti
                fe.write(f"{k}\t{url}\t{type(e).__name__}\n"); fe.flush()
            if n % 500 == 0:
                print(f"{n}/{len(da_fare)}", flush=True)
            time.sleep(PAUSA)
    print("fine", flush=True)


if __name__ == "__main__":
    main()
