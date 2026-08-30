"""
Seconda passata sul JSONL (304.006 pagine): per i soli gruppi tenuti dopo
la decisione con l'utente (vedi issue #153) -- 7.291 nuove specie con
contenuto specifico + 4.790 esistenti da arricchire, 12.081 totali,
escluse le 36.471 solo-genere-senza-dati-di-cura -- costruisce
l'aggregazione completa per specie base nello stesso formato di
rhs_varieta_aggregato.json (cosi' genera_sql.py si riusa cosi' com'e'
per l'update, con un solo campo aggiunto per l'insert delle nuove).

Fatto in due passate (aggregate_sitemaps.py prima, questo dopo) invece di
una sola per tenere il picco di RAM basso: la prima passata tiene solo
liste di nomi file per gruppo, questa costruisce i campi pesanti solo per
i 12.081 gruppi che servono davvero, non per tutti i 64.440.
"""
import json, os, re, sys, unicodedata
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
JSONL = os.path.join(HERE, "rhs_sitemaps_parsed.jsonl")
AGGREGATO_STATS = os.path.join(HERE, "rhs_sitemaps_aggregato.json")
OUT_FILE = os.path.join(HERE, "rhs_sitemaps_full_aggregato.json")


def norm(name):
    if not name:
        return ""
    return re.sub(r'\s+', ' ', name.replace('x ', '× ').strip().lower())


def slugify(name):
    s = name.replace('×', 'x')
    s = unicodedata.normalize('NFD', s)
    s = ''.join(c for c in s if not unicodedata.combining(c))
    s = re.sub(r'[^a-zA-Z0-9]+', '-', s).strip('-').lower()
    return s


def extract_numbers(s):
    if not s:
        return []
    return [float(x.replace(',', '.')) for x in re.findall(r'\d+(?:[.,]\d+)?', s)]


def main():
    stats = json.load(open(AGGREGATO_STATS, encoding="utf-8"))
    keep = {}
    for d in stats:
        if d["stato_match"] == "nuova" and d["ha_contenuto_specifico"]:
            keep[d["specie_base"]] = {"stato_match": "nuova", "slug": slugify(d["specie_base"])}
        elif d["stato_match"] == "da_arricchire":
            keep[d["specie_base"]] = {"stato_match": "da_arricchire", "slug": d["slug_esistente"]}
    print(f"Gruppi da aggregare per intero: {len(keep)}")

    groups = defaultdict(list)
    with open(JSONL, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            d = json.loads(line)
            # stessa logica di base_species() in aggregate_sitemaps.py, ma
            # qui filtriamo subito su keep per non accumulare le altre 52k
            latin = d.get("nome_scientifico_titolo")
            if not latin:
                continue
            s = re.sub(r"'[^']*'", '', latin)
            s = re.sub(r'\([^)]*\)', '', s)
            s = re.sub(r'\[[^\]]*\]', '', s)
            s = re.sub(r'\s+', ' ', s).strip()
            parts = s.split(' ')
            sp = ' '.join(parts[:3]) if len(parts) >= 3 and parts[1] == '×' else (' '.join(parts[:2]) if len(parts) >= 2 else s)
            if sp not in keep:
                continue
            groups[sp].append(d)

    print(f"Gruppi trovati nel JSONL: {len(groups)} (attesi {len(keep)})")

    aggregated = []
    for sp, entries in groups.items():
        info = keep[sp]
        base_entry = next((e for e in entries if norm(e.get("nome_scientifico_titolo")) == norm(sp)), None)
        ref = base_entry or entries[0]

        cultivar_names = []
        for e in entries:
            latin = e["nome_scientifico_titolo"]
            m = re.search(r"'([^']*)'", latin or "")
            if m:
                cultivar_names.append(m.group(1))

        heights, spreads = [], []
        hardiness_set, foliage_set, habit_set = set(), set(), set()
        for e in entries:
            heights += extract_numbers(e.get("altezza_max"))
            spreads += extract_numbers(e.get("diffusione_max"))
            if e.get("hardiness"):
                hardiness_set.add(e["hardiness"])
            if e.get("fogliame"):
                foliage_set.add(e["fogliame"])
            if e.get("habit"):
                habit_set.add(e["habit"])

        aggregated.append({
            "specie_base": sp,
            "stato_match": info["stato_match"],
            "slug": info["slug"],
            "n_pagine": len(entries),
            "ha_pagina_specie_base": base_entry is not None,
            "famiglia_botanica": ref.get("famiglia_botanica"),
            "nome_comune": ref.get("nome_comune_titolo"),
            "descrizione_breve": ref.get("descrizione_breve"),
            "genere_descrizione": ref.get("genere_descrizione"),
            "range_geografico": ref.get("range_geografico"),
            "cultivation": ref.get("cultivation"),
            "propagation": ref.get("propagation"),
            "pruning": ref.get("pruning"),
            "pests": ref.get("pests"),
            "diseases": ref.get("diseases"),
            "moisture": ref.get("moisture"),
            "ph": ref.get("ph"),
            "position": ref.get("position"),
            "soil_types": ref.get("soil_types"),
            "altezza_min_max": [min(heights), max(heights)] if heights else None,
            "diffusione_min_max": [min(spreads), max(spreads)] if spreads else None,
            "hardiness_set": sorted(hardiness_set),
            "foliage_set": sorted(foliage_set),
            "habit_set": sorted(habit_set),
            "cultivar_names": cultivar_names,
            "files": [e["file"] for e in entries],
        })

    with open(OUT_FILE, "w", encoding="utf-8") as out:
        json.dump(aggregated, out, ensure_ascii=False, indent=1)
    n_nuova = sum(1 for a in aggregated if a["stato_match"] == "nuova")
    n_arricchire = sum(1 for a in aggregated if a["stato_match"] == "da_arricchire")
    print(f"Scritto {OUT_FILE}: {n_nuova} nuove, {n_arricchire} da arricchire")


if __name__ == "__main__":
    main()
