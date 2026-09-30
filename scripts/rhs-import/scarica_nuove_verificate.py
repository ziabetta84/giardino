"""
Scarica le pagine candidate "nuove" (nuove_pagine_sitemap.txt, prodotto da
check_nuove_sitemap.py) e tiene solo quelle genuinamente nuove.

Perché non basta scaricare e basta: verificato il 29/09/2026 su un
campione di 40 URL che TUTTE risultavano alias legacy di contenuto già
posseduto sotto un altro ID (RHS elenca nel sitemap vecchi ID di sinonimi
poi fusi in un'unica pagina canonica, con <link rel="canonical"> diverso
ma nessun redirect HTTP). Quindi per ogni candidata si legge l'ID
canonico dal contenuto scaricato e si scarta se già presente in id_map.tsv.

Resumibile: ogni URL processato (nuovo, alias o errore) viene loggato in
progresso.log e saltato ai run successivi. id_map.tsv viene aggiornato in
tempo reale (append) man mano che si trova contenuto genuinamente nuovo,
così due candidate diverse che risultano alias della stessa pagina nuova
non vengono salvate due volte.

Uso:
    python3 scarica_nuove_verificate.py
"""
import os
import re
import time
import requests

HERE = os.path.dirname(os.path.abspath(__file__))
SRC_DIR = os.path.join(HERE, "..", "..", "fonti", "rhs_from_sitemaps")
CANDIDATE_FILE = os.path.join(HERE, "nuove_pagine_sitemap.txt")
ID_MAP_FILE = os.path.join(HERE, "id_map.tsv")
PROGRESS_FILE = os.path.join(HERE, "progresso_nuove.log")

CANON_RE = re.compile(
    r'href="https://www\.rhs\.org\.uk/plants/(\d+)/([^"]+?)/details" rel="canonical"'
)

session = requests.Session()
session.headers.update({
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
})


def carica_id_noti():
    ids = set()
    if os.path.exists(ID_MAP_FILE):
        with open(ID_MAP_FILE, encoding="utf-8") as f:
            for line in f:
                pid = line.split("\t", 1)[0].strip()
                if pid:
                    ids.add(pid)
    return ids


def carica_gia_processati():
    fatti = set()
    if os.path.exists(PROGRESS_FILE):
        with open(PROGRESS_FILE, encoding="utf-8") as f:
            for line in f:
                parts = line.rstrip("\n").split("\t")
                if parts:
                    fatti.add(parts[0])
    return fatti


def main():
    id_noti = carica_id_noti()
    print(f"ID già noti all'avvio: {len(id_noti)}")

    candidate = [l.strip() for l in open(CANDIDATE_FILE, encoding="utf-8") if l.strip()]
    gia_fatti = carica_gia_processati()
    todo = [u for u in candidate if u not in gia_fatti]
    print(f"Candidate totali: {len(candidate)}, già processate: {len(gia_fatti)}, restanti: {len(todo)}")

    id_map_out = open(ID_MAP_FILE, "a", encoding="utf-8")
    progresso_out = open(PROGRESS_FILE, "a", encoding="utf-8")

    n_nuove = 0
    n_alias = 0
    n_errori = 0

    for i, url in enumerate(todo):
        try:
            r = session.get(url, timeout=15)
            if r.status_code != 200 or "cloudflare" in r.url:
                progresso_out.write(f"{url}\terrore\tstatus={r.status_code}\n")
                progresso_out.flush()
                n_errori += 1
                time.sleep(0.5)
                continue
            body = r.text
        except Exception as e:
            progresso_out.write(f"{url}\terrore\t{e}\n")
            progresso_out.flush()
            n_errori += 1
            time.sleep(0.5)
            continue

        m = CANON_RE.search(body)
        if not m:
            progresso_out.write(f"{url}\terrore\tnessun canonical trovato\n")
            progresso_out.flush()
            n_errori += 1
            time.sleep(0.5)
            continue

        canon_id, slug = m.group(1), m.group(2)

        if canon_id in id_noti:
            progresso_out.write(f"{url}\talias\t{canon_id}\n")
            progresso_out.flush()
            n_alias += 1
        else:
            filename = slug + ".html"
            filepath = os.path.join(SRC_DIR, filename)
            if not os.path.exists(filepath):
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(body)
            id_noti.add(canon_id)
            id_map_out.write(f"{canon_id}\t{filename}\n")
            id_map_out.flush()
            progresso_out.write(f"{url}\tnuova\t{canon_id}\t{filename}\n")
            progresso_out.flush()
            n_nuove += 1

        if (i + 1) % 200 == 0:
            print(f"[{i + 1}/{len(todo)}] nuove={n_nuove} alias={n_alias} errori={n_errori}")

        time.sleep(0.5)

    id_map_out.close()
    progresso_out.close()

    print("\nCompletato.")
    print(f"Nuove pagine genuinamente aggiunte: {n_nuove}")
    print(f"Alias scartati (contenuto già noto): {n_alias}")
    print(f"Errori: {n_errori}")


if __name__ == "__main__":
    main()
