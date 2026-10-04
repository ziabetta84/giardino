"""Scarica i nomi comuni italiani da Wikidata e propone un nome per taxon."""
import csv
import json
import sys
import urllib.parse
import urllib.request
from collections import defaultdict
from pathlib import Path

from nomi import scegli_nome

ENDPOINT = "https://query.wikidata.org/sparql"
QUERY = """
SELECT ?sci ?nome ?rank ?itwiki WHERE {
  ?t wdt:P225 ?sci .
  ?t p:P1843 ?st . ?st ps:P1843 ?nome . ?st wikibase:rank ?rank .
  FILTER(LANG(?nome) = "it")
  OPTIONAL { ?w schema:about ?t ; schema:isPartOf <https://it.wikipedia.org/> ; schema:name ?itwiki . }
}
"""
OUT = Path(__file__).parent / "out"


def scarica():
    url = ENDPOINT + "?" + urllib.parse.urlencode({"query": QUERY})
    req = urllib.request.Request(url, headers={
        "User-Agent": "giardino-zorba/1.0 (nomi italiani)",
        "Accept": "application/sparql-results+json",
    })
    try:
        with urllib.request.urlopen(req, timeout=180) as r:
            return json.load(r)["results"]["bindings"]
    except Exception as e:  # nessun CSV parziale: si fallisce prima di scrivere
        sys.exit(f"Wikidata non ha risposto: {e}")


def main():
    righe = scarica()
    per_sci = defaultdict(list)
    for b in righe:
        rank = b["rank"]["value"].rsplit("#", 1)[-1].replace("Rank", "").lower()
        per_sci[b["sci"]["value"]].append({
            "nome": b["nome"]["value"],
            "rank": rank,
            "itwiki": b.get("itwiki", {}).get("value"),
        })
    OUT.mkdir(exist_ok=True)
    proposte, ambigui = [], []
    for sci, cand in sorted(per_sci.items()):
        nome, criterio = scegli_nome(sci, cand)
        if nome:
            proposte.append((sci, nome, criterio))
        elif criterio == "ambiguo":
            ambigui.append((sci, " | ".join(sorted({c["nome"] for c in cand}))))
    with open(OUT / "proposte.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f); w.writerow(["nome_scientifico", "nuovo_nome", "criterio"]); w.writerows(proposte)
    with open(OUT / "ambigui.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f); w.writerow(["nome_scientifico", "candidati"]); w.writerows(ambigui)
    print(f"{len(proposte)} proposte, {len(ambigui)} ambigui (da {len(per_sci)} taxa)")


if __name__ == "__main__":
    main()
