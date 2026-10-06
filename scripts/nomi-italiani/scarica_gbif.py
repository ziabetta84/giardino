"""Scarica da GBIF stato e sinonimi botanici per tutte le specie non cultivar (binomi).
Riprendibile: salta gli slug già presenti in gbif.jsonl."""
import json, os, subprocess, urllib.parse, urllib.request
from concurrent.futures import ThreadPoolExecutor

QUI = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(QUI, "out", "gbif.jsonl")
UA = {"User-Agent": "giardino-sinonimi/0.1"}


def get(url):
    for _ in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
                return json.load(r)
        except Exception:
            pass
    return None


def lavora(riga):
    slug, sci = riga
    m = get("https://api.gbif.org/v1/species/match?name=" + urllib.parse.quote(sci))
    if m is None:
        return None
    key = m.get("usageKey")
    out = {"slug": slug, "sci": sci, "match": m.get("matchType"), "stato": m.get("status"),
           "accettato": m.get("species"), "key": key, "sinonimi": []}
    if key and m.get("matchType") == "EXACT":
        s = get(f"https://api.gbif.org/v1/species/{key}/synonyms?limit=100")
        if s is None:
            return None
        out["sinonimi"] = sorted({x.get("canonicalName") for x in s.get("results", []) if x.get("canonicalName")})
    return out


# DATABASE_URL dall'ambiente, oppure da .env.local nella radice del repo
url = os.environ.get("DATABASE_URL") or [
    l.split("=", 1)[1].strip().strip('"')
    for l in open(os.path.join(QUI, "..", "..", ".env.local")) if l.startswith("DATABASE_URL=")][0]
q = ("select slug, nome_scientifico from specie where specie_padre_id is null "
     "and nome_scientifico ~ '^[A-Z][a-z]+ [a-z]+$' order by slug")
righe = [r.split("\t") for r in subprocess.run(["psql", url, "-At", "-F", "\t", "-c", q], capture_output=True, text=True, check=True).stdout.splitlines()]
fatti = set()
if os.path.exists(OUT):
    fatti = {json.loads(l)["slug"] for l in open(OUT)}
todo = [r for r in righe if r[0] not in fatti]
print("da fare", len(todo), "già fatti", len(fatti), flush=True)
with open(OUT, "a") as f, ThreadPoolExecutor(8) as ex:
    for i, res in enumerate(ex.map(lavora, todo)):
        if res:
            f.write(json.dumps(res, ensure_ascii=False) + "\n")
            f.flush()
        if i % 500 == 0:
            print(i, flush=True)
print("finito", flush=True)
