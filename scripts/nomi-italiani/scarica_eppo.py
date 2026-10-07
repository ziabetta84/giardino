"""Nomi comuni italiani da EPPO Global Database (gd.eppo.int; robots.txt consente le pagine, ~1 req/s).

Uso: python3 scarica_eppo.py out/madri_lotto2_da_rivedere.csv out/eppo_lotto2.jsonl [limite]
Per ogni riga (colonna nome_scientifico) cerca il nome esatto su /ajax/search, apre /taxon/<codice> e salva i
nomi comuni con lingua Italian. Riprende da dove era arrivato (salta gli slug già nel file di uscita).
"""
import csv
import html
import json
import re
import sys
import time
import urllib.parse
import urllib.request

UA = "Mozilla/5.0 (giardino-nomi-italiani; uso personale, 1 richiesta al secondo)"


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8", "replace")


def codice(sci):
    d = json.loads(get("https://gd.eppo.int/ajax/search?" + urllib.parse.urlencode({"k": sci, "s": 1, "m": 1, "t": 1})))
    esatti = [x for x in d if x.get("f", "").lower() == sci.lower() and x.get("l") == "Scientific"]
    return esatti[0]["e"] if esatti else None


def nomi_comuni(pagina):
    m = re.search(r"Common names(.*?)(?:</table>)", pagina, re.S)
    if not m:
        return []
    celle = [html.unescape(re.sub(r"<[^>]*>", "", c)).strip() for c in re.findall(r"<td[^>]*>(.*?)</td>", m.group(1), re.S)]
    return list(zip(celle[0::2], celle[1::2]))


def cerca(sci):
    cod = codice(sci)
    if not cod:
        return {"trovato": False, "codice": None, "nomi_it": [], "lingue": 0}
    time.sleep(1)
    nomi = nomi_comuni(get("https://gd.eppo.int/taxon/" + cod))
    return {"trovato": True, "codice": cod, "nomi_it": [n for n, l in nomi if l.strip() == "Italian"],
            "lingue": len({l for _, l in nomi})}


def main():
    src, dst = sys.argv[1], sys.argv[2]
    limite = int(sys.argv[3]) if len(sys.argv) > 3 else None
    fatti = set()
    try:
        fatti = {json.loads(l)["slug"] for l in open(dst, encoding="utf-8")}
    except FileNotFoundError:
        pass
    righe = [r for r in csv.DictReader(open(src, encoding="utf-8")) if r["slug"] not in fatti][:limite]
    with open(dst, "a", encoding="utf-8") as f:
        for r in righe:
            try:
                rec = cerca(r["nome_scientifico"])
            except Exception as e:  # rete o formato: si registra e si va avanti
                rec = {"trovato": None, "errore": str(e), "nomi_it": []}
            rec.update(slug=r["slug"], sci=r["nome_scientifico"])
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")
            f.flush()
            time.sleep(1)


if __name__ == "__main__":
    main()
