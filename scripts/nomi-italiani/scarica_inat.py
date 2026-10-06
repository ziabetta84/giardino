"""Scarica da iNaturalist il nome italiano preferito per le specie non cultivar (solo binomi).

Due gruppi, scritti in out/inat.jsonl (riprendibile: salta gli slug già presenti):
  A  specie senza nome italiano (nome = nome_scientifico) ma con nomi_alternativi: servono a scegliere il principale
  B  specie con nome italiano già impostato: solo confronto, non si modificano
Una richiesta al secondo circa, per rispettare il limite dell'API (~60/min).
"""
import json, os, subprocess, time, urllib.parse, urllib.request

QUI = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(QUI, "out", "inat.jsonl")
UA = {"User-Agent": "giardino-nomi-italiani/0.1 (verifica nomi italiani)"}


def get(url):
    for tentativo in range(5):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            time.sleep(30 if e.code == 429 else 3)
        except Exception:
            time.sleep(3)
    return None


def cerca(sci):
    d = get("https://api.inaturalist.org/v1/taxa?" + urllib.parse.urlencode(
        {"q": sci, "rank": "species", "locale": "it", "per_page": 5, "is_active": "true"}))
    if d is None:
        return None
    for t in d.get("results", []):
        if t.get("name", "").lower() == sci.lower():
            return {"trovato": True, "id": t["id"], "nome_it": t.get("preferred_common_name"),
                    "nome_en": t.get("english_common_name")}
    return {"trovato": False, "id": None, "nome_it": None, "nome_en": None}


def righe_da_fare():
    url = os.environ.get("DATABASE_URL")
    if not url:
        url = [l.split("=", 1)[1].strip().strip('"')
               for l in open(os.path.join(QUI, "..", "..", ".env.local")) if l.startswith("DATABASE_URL=")][0]
    q = ("select slug, nome, nome_scientifico, stato_verifica, "
         "case when nome = nome_scientifico then 'A' else 'B' end as gruppo "
         "from specie where specie_padre_id is null and nome_scientifico ~ '^[A-Z][a-z-]+ [a-z-]+$' "
         "and ((nome = nome_scientifico and nomi_alternativi is not null) or nome <> nome_scientifico) "
         "order by gruppo, slug")
    out = subprocess.run(["psql", url, "-At", "-F", "\t", "-c", q], capture_output=True, text=True, check=True).stdout
    return [r.split("\t") for r in out.splitlines()]


def main():
    righe = righe_da_fare()
    fatti = set()
    if os.path.exists(OUT):
        fatti = {json.loads(l)["slug"] for l in open(OUT)}
    todo = [r for r in righe if r[0] not in fatti]
    print("da fare", len(todo), "già fatti", len(fatti), flush=True)
    with open(OUT, "a") as f:
        for i, (slug, nome, sci, stato, gruppo) in enumerate(todo):
            res = cerca(sci)
            if res is not None:
                f.write(json.dumps({"slug": slug, "sci": sci, "nome_db": nome, "stato_verifica": stato,
                                    "gruppo": gruppo, **res}, ensure_ascii=False) + "\n")
                f.flush()
            if i % 100 == 0:
                print(i, flush=True)
            time.sleep(1.0)
    print("finito", flush=True)


if __name__ == "__main__":
    main()
