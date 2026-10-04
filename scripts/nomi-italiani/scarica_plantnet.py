"""Scarica da PlantNet l'elenco specie con i nomi comuni italiani -> out/plantnet.csv.

Serve PLANTNET_API_KEY nell'ambiente (.env.local). Le pagine scaricate restano in
out/plantnet_pagine/, così un'interruzione non obbliga a ricominciare da capo.
"""
import csv
import json
import os
import sys
import time
import urllib.request
from pathlib import Path

from nomi import nomi_plantnet

OUT = Path(__file__).parent / "out"
PAGINE = OUT / "plantnet_pagine"
URL = "https://my-api.plantnet.org/v2/species?lang=it&pageSize=500&page={}&api-key={}"


def pagina(n, chiave):
    f = PAGINE / f"p{n:04d}.json"
    if not f.exists():
        for tentativo in range(4):
            try:
                f.write_bytes(urllib.request.urlopen(URL.format(n, chiave), timeout=60).read())
                break
            except Exception as e:
                print("riprovo", n, e, flush=True)
                time.sleep(5 * (tentativo + 1))
        else:
            sys.exit(f"PlantNet non risponde alla pagina {n}")
    return json.loads(f.read_text())


def main():
    chiave = os.environ.get("PLANTNET_API_KEY") or sys.exit("PLANTNET_API_KEY mancante")
    PAGINE.mkdir(parents=True, exist_ok=True)
    righe, n = [], 1
    while True:
        dati = pagina(n, chiave)
        if not dati:
            break
        for s in dati:
            sci = s["scientificNameWithoutAuthor"].strip()
            nomi = nomi_plantnet(sci, s["commonNames"])
            if nomi:
                righe.append((sci, len(nomi), " | ".join(nomi)))
        n += 1
    with open(OUT / "plantnet.csv", "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["sci", "n_nomi", "nomi"])
        w.writerows(righe)
    print(f"{len(righe)} specie con almeno un nome, da {n - 1} pagine")


if __name__ == "__main__":
    main()
