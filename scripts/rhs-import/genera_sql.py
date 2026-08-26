import json, os, re, sys

SCRATCH = os.path.dirname(os.path.abspath(__file__))

data = json.load(open(f"{SCRATCH}/rhs_varieta_aggregato.json", encoding="utf-8"))
by_species = {d["specie_base"]: d for d in data}

POSITION_IT = {
    "Full sun": "pieno sole", "Partial shade": "mezz'ombra", "Full shade": "ombra piena",
}
SOIL_IT = {
    "Clay": "argilloso", "Loam": "franco", "Chalk": "calcareo", "Sand": "sabbioso",
}
MOISTURE_IT = {
    "Moist but well-drained": "umido ma ben drenato", "Well-drained": "ben drenato",
    "Poorly-drained": "poco drenato", "Wet": "umido/paludoso",
}
PH_IT = {"Acid": "acido", "Alkaline": "alcalino", "Neutral": "neutro"}

def translate_csv(value, table):
    if not value:
        return None
    value = value.replace("–", "-").replace("—", "-")
    parts = [p.strip() for p in re.split(r",| or ", value) if p.strip()]
    seen = []
    for p in parts:
        it = table.get(p, p)
        if it not in seen:
            seen.append(it)
    return ", ".join(seen)

def fmt_range(minmax, unit="m"):
    if not minmax:
        return None
    lo, hi = minmax
    if lo == hi:
        return f"{lo:g}{unit}"
    return f"{lo:g}-{hi:g}{unit}"

def esc(s):
    return s.replace("\n", " ").strip() if s else s

def gen_block(rhs_name, slug, note=None):
    d = by_species.get(rhs_name)
    if d is None:
        print(f"!! NON TROVATO: {rhs_name}", file=sys.stderr)
        return ""

    fonte = f"RHS (rhs.org.uk) — {rhs_name}"
    parts = []

    # Some rare/wild-species RHS pages have no "How to Grow" section at all
    # (no position/soil/cultivation/pests/height data) -- genus-level text
    # alone isn't specific enough to justify stato_verifica='verificato'
    # per regola 3 (fonte primaria "specifica sulla specie"), even though
    # it's still worth capturing as descrizione/fonti.
    specific_content = any([
        d.get("descrizione_breve"), d.get("cultivation"), d.get("propagation"),
        d.get("pruning"), d.get("pests"), d.get("diseases"), d.get("position"),
        d.get("soil_types"), d.get("moisture"), d.get("altezza_min_max"),
        d.get("diffusione_min_max"),
    ])
    any_content = specific_content or d.get("genere_descrizione")
    if not any_content:
        print(f"!! NESSUN CONTENUTO UTILE: {rhs_name} ({slug})", file=sys.stderr)
        return ""

    # descrizione: keep RHS one-liner + cultivar range note, English text is
    # kept verbatim (marked as such) like the existing PFAF-risk convention.
    desc_bits = []
    if d.get("descrizione_breve"):
        desc_bits.append(f"Da RHS (testo originale in inglese): \"{esc(d['descrizione_breve'])}\".")
    elif d.get("genere_descrizione"):
        desc_bits.append(f"Da RHS, descrizione del genere (testo originale in inglese): \"{esc(d['genere_descrizione'])}\".")
    if d["n_pagine"] > 1:
        h = fmt_range(d.get("altezza_min_max"))
        s = fmt_range(d.get("diffusione_min_max"))
        cvs = d.get("cultivar_names") or []
        sample = ", ".join(f"'{c}'" for c in cvs[:6])
        extra = f" (tra cui {sample}{'...' if len(cvs) > 6 else ''})" if sample else ""
        size_bit = f" con altezze da {h}" if h else ""
        if s:
            size_bit += f" e diffusione da {s}" if h else f" con diffusione da {s}"
        desc_bits.append(f"RHS elenca {d['n_pagine']} cultivar coltivate{size_bit}{extra}.")
    if note:
        desc_bits.append(note)
    descrizione_sql = None
    if desc_bits:
        descrizione_sql = " ".join(desc_bits)

    # esigenze
    esigenze = {}
    luce = translate_csv(d.get("position"), POSITION_IT)
    if luce:
        esigenze["luce"] = luce.capitalize()
    acqua_bits = []
    moist = translate_csv(d.get("moisture"), MOISTURE_IT)
    if moist:
        acqua_bits.append(moist)
    if acqua_bits:
        esigenze["acqua"] = ", ".join(acqua_bits).capitalize()
    terreno_bits = []
    soil = translate_csv(d.get("soil_types"), SOIL_IT)
    if soil:
        terreno_bits.append(soil.capitalize())
    ph = translate_csv(d.get("ph"), PH_IT)
    if ph:
        terreno_bits.append(f"pH {ph}")
    if terreno_bits:
        esigenze["terreno"] = "; ".join(terreno_bits)

    # alert
    alert_items = []
    if d.get("pests") and d.get("diseases"):
        alert_items.append(
            f"Da RHS (testo originale in inglese) — Parassiti: \"{esc(d['pests'])}\"; Malattie: \"{esc(d['diseases'])}\""
        )
    elif d.get("pests"):
        alert_items.append(f"Da RHS (testo originale in inglese) — Parassiti: \"{esc(d['pests'])}\"")
    elif d.get("diseases"):
        alert_items.append(f"Da RHS (testo originale in inglese) — Malattie: \"{esc(d['diseases'])}\"")
    hset = d.get("hardiness_set") or []
    if hset:
        alert_items.append(f"Rusticità RHS: {', '.join(hset)} (scala UK, vedi H1-H7 nella documentazione RHS)")
    if d.get("altezza_min_max") or d.get("diffusione_min_max"):
        h = fmt_range(d.get("altezza_min_max"))
        s = fmt_range(d.get("diffusione_min_max"))
        dims = []
        if h:
            dims.append(f"altezza {h}")
        if s:
            dims.append(f"diffusione {s}")
        if dims:
            alert_items.append("Dimensioni RHS a maturità: " + ", ".join(dims))

    # Pruning/propagation are short RHS notes that don't decompose cleanly
    # into the seasonal manutenzione schema (RHS gives static advice, not
    # per-season instructions) — kept as alert text, English + marked, same
    # treatment as pests/diseases and the existing PFAF-risk convention.
    if d.get("pruning"):
        alert_items.append(f"Potatura (RHS, testo originale in inglese): \"{esc(d['pruning'])}\"")
    if d.get("propagation"):
        alert_items.append(f"Propagazione (RHS, testo originale in inglese): \"{esc(d['propagation'])}\"")

    # Build SQL
    sql = [f"update specie set"]
    setters = []
    if descrizione_sql:
        setters.append(f"  descrizione = descrizione || $t$ {descrizione_sql}$t$")
    if esigenze:
        esigenze_json = json.dumps(esigenze, ensure_ascii=False)
        setters.append(f"  esigenze = ({'$t$'}{esigenze_json}{'$t$'}::jsonb) || coalesce(esigenze, '{{}}'::jsonb)")
    if alert_items:
        arr = ",\n    ".join(f"$t${esc(a)}$t$" for a in alert_items)
        setters.append(f"  alert = alert || ARRAY[\n    {arr}\n  ]")
    setters.append(f"  fonti = array_append(fonti, $t${fonte}$t$)")
    if specific_content:
        setters.append("  stato_verifica = 'verificato'")
    sql.append(",\n".join(setters))
    sql.append(f"where slug = $t${slug}$t$")
    sql.append(f"  and not ($t${fonte}$t$ = any(fonti));")
    return "\n".join(sql) + "\n"


if __name__ == "__main__":
    print(gen_block("Adiantum capillus-veneris", "adiantum-capillus-veneris"))
