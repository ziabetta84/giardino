"""
Costruisce una mappa ID RHS -> file scaricato per fonti/rhs_from_sitemaps/.

Scoperta (29/09/2026, issue di follow-up su #153): tra il 30/08 e oggi RHS
ha cambiato il formato di alcuni slug URL (es. "narcissus-descanso-(1)"
-> "narcissus-descanso-1", parentesi rimosse dai codici disambiguanti),
quindi un confronto per nome file tra sitemap vecchio e nuovo produce
decine di migliaia di falsi "nuovi". L'ID numerico RHS nell'URL
(es. /plants/176686/...) è invece stabile: è incorporato anche nella
pagina scaricata (<link rel="canonical" href=".../plants/<id>/...">,
entro i primi ~10KB), quindi si può usare come chiave robusta.

Uso:
    python3 build_id_map.py    # scrive id_map.tsv (id<TAB>filename), non versionato
"""
import os
import re
import sys
from concurrent.futures import ProcessPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
SRC_DIR = os.path.join(HERE, "..", "..", "fonti", "rhs_from_sitemaps")
OUT_FILE = os.path.join(HERE, "id_map.tsv")

ID_RE = re.compile(rb'href="https://www\.rhs\.org\.uk/plants/(\d+)/')
READ_BYTES = 20_000


def extract_id(fn):
    path = os.path.join(SRC_DIR, fn)
    try:
        with open(path, "rb") as f:
            chunk = f.read(READ_BYTES)
        m = ID_RE.search(chunk)
        return fn, (m.group(1).decode() if m else None)
    except Exception:
        return fn, None


def main():
    all_files = sorted(f for f in os.listdir(SRC_DIR) if f.lower().endswith(".html"))
    print(f"File da processare: {len(all_files)}")

    trovati = 0
    non_trovati = []
    with open(OUT_FILE, "w", encoding="utf-8") as out, ProcessPoolExecutor() as ex:
        for i, (fn, pid) in enumerate(ex.map(extract_id, all_files, chunksize=200)):
            if pid:
                out.write(f"{pid}\t{fn}\n")
                trovati += 1
            else:
                non_trovati.append(fn)
            if (i + 1) % 20000 == 0:
                print(f"  {i + 1}/{len(all_files)}...")

    print(f"ID trovati: {trovati}")
    print(f"Senza ID riconoscibile: {len(non_trovati)}")
    if non_trovati:
        with open(os.path.join(HERE, "id_map_senza_id.log"), "w", encoding="utf-8") as f:
            f.write("\n".join(non_trovati))
        print("Elenco in id_map_senza_id.log")


if __name__ == "__main__":
    main()
