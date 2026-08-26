import json, os, re
from collections import defaultdict

SCRATCH = os.path.dirname(os.path.abspath(__file__))

def base_species(latin):
    s = re.sub(r"'[^']*'", '', latin)
    s = re.sub(r'\([^)]*\)', '', s)
    s = re.sub(r'\[[^\]]*\]', '', s)
    s = re.sub(r'\s+', ' ', s).strip()
    parts = s.split(' ')
    if len(parts) >= 3 and parts[1] == '×':
        return ' '.join(parts[:3])
    return ' '.join(parts[:2]) if len(parts) >= 2 else s

def is_straight_species(latin, base):
    return latin.strip() == base.strip()

def extract_numbers(s):
    if not s:
        return []
    return [float(x.replace(',', '.')) for x in re.findall(r'\d+(?:[.,]\d+)?', s)]

data = json.load(open(f"{SCRATCH}/rhs_varieta_parsed.json", encoding="utf-8"))

groups = defaultdict(list)
for d in data:
    latin = d.get("nome_scientifico_titolo") or ""
    sp = base_species(latin)
    groups[sp].append(d)

aggregated = []
for sp, entries in sorted(groups.items()):
    base_entry = next((e for e in entries if is_straight_species(e["nome_scientifico_titolo"], sp)), None)
    ref = base_entry or entries[0]

    cultivar_names = []
    for e in entries:
        latin = e["nome_scientifico_titolo"]
        m = re.search(r"'([^']*)'", latin)
        if m:
            cultivar_names.append(m.group(1))

    heights = []
    spreads = []
    hardiness_set = set()
    foliage_set = set()
    habit_set = set()
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

with open(f"{SCRATCH}/rhs_varieta_aggregato.json", "w", encoding="utf-8") as out:
    json.dump(aggregated, out, ensure_ascii=False, indent=1)

print("Specie aggregate:", len(aggregated))
print("Senza pagina specie base (solo cultivar scaricate):", sum(1 for a in aggregated if not a["ha_pagina_specie_base"]))
