"""Per i generi usati (righe di genere con cultivar o piante) scarica da GBIF il numero di specie accettate.
Riprendibile: salta i generi già presenti in out/gbif_generi.jsonl."""
import json
import os
import subprocess
import time
import urllib.parse
import urllib.request

from genera_lotto3 import QUI, OUT
from generi_logica import genere_di, conta_specie_gbif

UA = {"User-Agent": "giardino-generi/0.1"}
DST = OUT / "gbif_generi.jsonl"

QUERY_USATI = """
select distinct nome_scientifico from specie s
where specie_padre_id is null and slug !~ '-'
  and (exists (select 1 from specie c where c.specie_padre_id = s.id)
       or exists (select 1 from piante p where p.specie = s.slug))
"""


def get(url):
    for _ in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
                return json.load(r)
        except Exception:
            time.sleep(2)
    return None


def db_url():
    return os.environ.get("DATABASE_URL") or [l.split("=", 1)[1].strip().strip('"')
        for l in open(QUI.parent.parent / ".env.local") if l.startswith("DATABASE_URL=")][0]


def generi_usati():
    righe = subprocess.run(["psql", db_url(), "-At", "-c", QUERY_USATI], capture_output=True, text=True,
                           check=True).stdout.splitlines()
    return sorted({genere_di(r) for r in righe if genere_di(r)})


def main():
    fatti = set()
    if DST.exists():
        fatti = {json.loads(l)["genere"] for l in open(DST, encoding="utf-8")}
    todo = [g for g in generi_usati() if g not in fatti]
    print("da fare", len(todo), "già fatti", len(fatti), flush=True)
    with open(DST, "a", encoding="utf-8") as f:
        for i, g in enumerate(todo):
            m = get("https://api.gbif.org/v1/species/match?" + urllib.parse.urlencode(
                {"name": g, "rank": "GENUS", "kingdom": "Plantae"}))
            ric = None
            if m and m.get("usageKey"):
                ric = get("https://api.gbif.org/v1/species/search?" + urllib.parse.urlencode(
                    {"rank": "SPECIES", "higherTaxonKey": m["usageKey"], "status": "ACCEPTED", "limit": 0}))
            if m is None:
                continue  # errore di rete: sarà ritentato alla prossima esecuzione
            f.write(json.dumps({"genere": g, "gbif_key": m.get("usageKey"), "n_specie": conta_specie_gbif(m, ric),
                                "match": m.get("matchType"), "status": m.get("status"), "rank": m.get("rank")},
                               ensure_ascii=False) + "\n")
            f.flush()
            if i % 100 == 0:
                print(i, flush=True)
            time.sleep(0.2)
    print("finito", flush=True)


if __name__ == "__main__":
    main()
