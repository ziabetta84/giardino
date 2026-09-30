"""
Controllo periodico: ci sono pagine nuove nel sitemap piante di RHS
rispetto a quelle già scaricate in fonti/rhs_from_sitemaps/ (import
massivo del 30/08/2026, issue #153)?

Confronta per ID numerico RHS (es. /plants/176686/...), non per slug:
il 29/09/2026 si è scoperto che RHS ha cambiato formato ad alcuni slug
tra un giro e l'altro (es. "narcissus-descanso-(1)" -> "narcissus-descanso-1",
parentesi rimosse dai codici disambiguanti) — un confronto per nome file
avrebbe prodotto decine di migliaia di falsi "nuovi". L'ID è invece stabile
e recuperabile sia dall'URL sitemap sia dal contenuto delle pagine già
scaricate (build_id_map.py).

Richiede id_map.tsv già generato (python3 build_id_map.py, una tantum/
periodico: rigenerarlo se il set di file scaricati cambia).

Uso:
    python3 check_nuove_sitemap.py
"""
import os
import re
import requests

HERE = os.path.dirname(os.path.abspath(__file__))
SITEMAP_BASE = "https://www.rhs.org.uk/sitemap-plants"
ID_MAP_FILE = os.path.join(HERE, "id_map.tsv")
OUT_FILE = os.path.join(HERE, "nuove_pagine_sitemap.txt")

session = requests.Session()
session.headers.update({
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
})


def carica_id_esistenti():
    ids = set()
    with open(ID_MAP_FILE, encoding="utf-8") as f:
        for line in f:
            pid = line.split("\t", 1)[0].strip()
            if pid:
                ids.add(pid)
    return ids


def main():
    if not os.path.exists(ID_MAP_FILE):
        print(f"Manca {ID_MAP_FILE}: lanciare prima `python3 build_id_map.py`.")
        return

    id_esistenti = carica_id_esistenti()
    print(f"ID già scaricati: {len(id_esistenti)}")

    nuovi = []
    totale_url = 0
    for i in range(1, 8):
        current_sitemap = f"{SITEMAP_BASE}-{i}.xml"
        try:
            resp = session.get(current_sitemap, timeout=20)
            if resp.status_code != 200:
                print(f" Impossibile recuperare la sitemap {i}: status {resp.status_code}")
                continue
        except Exception as e:
            print(f" Errore nel download della sitemap {i}: {e}")
            continue
        urls = re.findall(r"<loc>(https?://[^<]+)</loc>", resp.text)
        print(f"Sitemap {i}: {len(urls)} url")
        totale_url += len(urls)
        for url in urls:
            if "cloudflare" in url:
                continue
            m = re.search(r"/plants/(\d+)/", url)
            if not m:
                continue
            pid = m.group(1)
            if pid not in id_esistenti:
                nuovi.append(url)

    print(f"\nTotale url nel sitemap corrente: {totale_url}")
    print(f"Pagine nuove (per ID, non ancora scaricate): {len(nuovi)}")

    if nuovi:
        with open(OUT_FILE, "w", encoding="utf-8") as f:
            for url in nuovi:
                f.write(f"{url}\n")
        print(f"Elenco scritto in {OUT_FILE}")
    else:
        print("Nessuna pagina nuova trovata.")


if __name__ == "__main__":
    main()
