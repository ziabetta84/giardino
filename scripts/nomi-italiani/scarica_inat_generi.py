"""Nome italiano preferito di iNaturalist per i generi usati. Riprendibile."""
import json
import time
import urllib.parse

from genera_lotto3 import OUT
from generi_logica import nome_genere_inat
from scarica_gbif_generi import generi_usati
from scarica_inat import get

DST = OUT / "inat_generi.jsonl"


def main():
    fatti = set()
    if DST.exists():
        fatti = {json.loads(l)["genere"] for l in open(DST, encoding="utf-8")}
    todo = [g for g in generi_usati() if g not in fatti]
    print("da fare", len(todo), "già fatti", len(fatti), flush=True)
    with open(DST, "a", encoding="utf-8") as f:
        for i, g in enumerate(todo):
            d = get("https://api.inaturalist.org/v1/taxa?" + urllib.parse.urlencode(
                {"q": g, "rank": "genus", "locale": "it", "per_page": 5, "is_active": "true"}))
            if d is not None:
                f.write(json.dumps({"genere": g, "nome_it": nome_genere_inat(d, g)}, ensure_ascii=False) + "\n")
                f.flush()
            if i % 100 == 0:
                print(i, flush=True)
            time.sleep(1.0)
    print("finito", flush=True)


if __name__ == "__main__":
    main()
