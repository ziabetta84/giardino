"""
Genera le migration SQL per i 11.316 gruppi tenuti dopo la decisione con
l'utente (issue #153): 4.859 arricchimenti di specie esistenti (stesso
template/regole di genera_sql.py, riusato senza modifiche per l'update) +
6.457 nuovi inserimenti (stesso template ma come INSERT, tutti con
contenuto specifico quindi tutti stato_verifica='verificato' per la
regola 3).

A differenza dei batch_*.py precedenti (liste PAIRS scritte a mano da
Claude, poche decine di specie a botta) qui il volume impone generazione
automatica su tutti i gruppi di rhs_sitemaps_full_aggregato.json, in file
SQL divisi a blocchi (default 400 statement/file, restano leggibili per
una revisione a campione prima di applicarli e restano sotto ai limiti
pratici di un singolo psql -f).

Uso:
    python3 genera_sql_sitemaps.py                # tutti i blocchi
    python3 genera_sql_sitemaps.py --chunk=400     # dimensione blocco (default 400)
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import genera_sql as gs  # riusa translate_csv/fmt_range/esc/tabelle IT

IN_FILE = os.path.join(HERE, "rhs_sitemaps_full_aggregato.json")
OUT_DIR = os.path.join(HERE, "sql_sitemaps")


def build_fields(d, rhs_name):
    """Stessa logica di genera_sql.gen_block per descrizione/esigenze/alert,
    ma restituisce i pezzi separati invece di un blocco SQL gia' assemblato
    -- serve sia per l'update (append) sia per l'insert (valore diretto)."""
    fonte = f"RHS (rhs.org.uk) — {rhs_name}"

    desc_bits = []
    if d.get("descrizione_breve"):
        desc_bits.append(f"Da RHS (testo originale in inglese): \"{gs.esc(d['descrizione_breve'])}\".")
    elif d.get("genere_descrizione"):
        desc_bits.append(f"Da RHS, descrizione del genere (testo originale in inglese): \"{gs.esc(d['genere_descrizione'])}\".")
    if d["n_pagine"] > 1:
        h = gs.fmt_range(d.get("altezza_min_max"))
        s = gs.fmt_range(d.get("diffusione_min_max"))
        cvs = d.get("cultivar_names") or []
        sample = ", ".join(f"'{c}'" for c in cvs[:6])
        extra = f" (tra cui {sample}{'...' if len(cvs) > 6 else ''})" if sample else ""
        size_bit = f" con altezze da {h}" if h else ""
        if s:
            size_bit += f" e diffusione da {s}" if h else f" con diffusione da {s}"
        desc_bits.append(f"RHS elenca {d['n_pagine']} cultivar coltivate{size_bit}{extra}.")
    descrizione = " ".join(desc_bits) if desc_bits else None

    esigenze = {}
    luce = gs.translate_csv(d.get("position"), gs.POSITION_IT)
    if luce:
        esigenze["luce"] = luce.capitalize()
    moist = gs.translate_csv(d.get("moisture"), gs.MOISTURE_IT)
    if moist:
        esigenze["acqua"] = moist.capitalize()
    terreno_bits = []
    soil = gs.translate_csv(d.get("soil_types"), gs.SOIL_IT)
    if soil:
        terreno_bits.append(soil.capitalize())
    ph = gs.translate_csv(d.get("ph"), gs.PH_IT)
    if ph:
        terreno_bits.append(f"pH {ph}")
    if terreno_bits:
        esigenze["terreno"] = "; ".join(terreno_bits)

    alert_items = []
    if d.get("pests") and d.get("diseases"):
        alert_items.append(f"Da RHS (testo originale in inglese) — Parassiti: \"{gs.esc(d['pests'])}\"; Malattie: \"{gs.esc(d['diseases'])}\"")
    elif d.get("pests"):
        alert_items.append(f"Da RHS (testo originale in inglese) — Parassiti: \"{gs.esc(d['pests'])}\"")
    elif d.get("diseases"):
        alert_items.append(f"Da RHS (testo originale in inglese) — Malattie: \"{gs.esc(d['diseases'])}\"")
    hset = d.get("hardiness_set") or []
    if hset:
        alert_items.append(f"Rusticità RHS: {', '.join(hset)} (scala UK, vedi H1-H7 nella documentazione RHS)")
    if d.get("altezza_min_max") or d.get("diffusione_min_max"):
        h = gs.fmt_range(d.get("altezza_min_max"))
        s = gs.fmt_range(d.get("diffusione_min_max"))
        dims = [x for x in [f"altezza {h}" if h else None, f"diffusione {s}" if s else None] if x]
        if dims:
            alert_items.append("Dimensioni RHS a maturità: " + ", ".join(dims))
    if d.get("pruning"):
        alert_items.append(f"Potatura (RHS, testo originale in inglese): \"{gs.esc(d['pruning'])}\"")
    if d.get("propagation"):
        alert_items.append(f"Propagazione (RHS, testo originale in inglese): \"{gs.esc(d['propagation'])}\"")

    return fonte, descrizione, esigenze, alert_items


def gen_insert(d):
    rhs_name = d["specie_base"]
    slug = d["slug"]
    fonte, descrizione, esigenze, alert_items = build_fields(d, rhs_name)

    cols = ["slug", "nome", "nome_scientifico", "famiglia_botanica", "fonti", "stato_verifica"]
    vals = [f"$t${slug}$t$", f"$t${rhs_name}$t$", f"$t${rhs_name}$t$",
            f"$t${d['famiglia_botanica']}$t$" if d.get("famiglia_botanica") else "null",
            f"ARRAY[$t${fonte}$t$]", "'verificato'"]

    if descrizione:
        cols.append("descrizione")
        vals.append(f"$t${descrizione}$t$")
    if esigenze:
        cols.append("esigenze")
        vals.append(f"$t${json.dumps(esigenze, ensure_ascii=False)}$t$::jsonb")
    if alert_items:
        cols.append("alert")
        arr = ", ".join(f"$t${gs.esc(a)}$t$" for a in alert_items)
        vals.append(f"ARRAY[{arr}]")

    return f"insert into specie ({', '.join(cols)}) values ({', '.join(vals)});\n"


def main():
    chunk_size = 400
    for arg in sys.argv[1:]:
        if arg.startswith("--chunk="):
            chunk_size = int(arg.split("=", 1)[1])

    data = json.load(open(IN_FILE, encoding="utf-8"))
    # gen_block legge dal dict globale by_species di genera_sql.py, caricato
    # di default da rhs_varieta_aggregato.json (la fonte piccola precedente):
    # lo sostituiamo con i nostri 11.316 gruppi prima di chiamarlo.
    gs.by_species = {d["specie_base"]: d for d in data}
    os.makedirs(OUT_DIR, exist_ok=True)
    for f in os.listdir(OUT_DIR):
        os.remove(os.path.join(OUT_DIR, f))

    nuove = [d for d in data if d["stato_match"] == "nuova"]
    arricchire = [d for d in data if d["stato_match"] == "da_arricchire"]
    print(f"Nuove: {len(nuove)}  Da arricchire: {len(arricchire)}")

    n_file = 0
    n_vuote = 0

    def flush(blocks, prefix, idx):
        nonlocal n_file
        if not blocks:
            return
        path = os.path.join(OUT_DIR, f"{prefix}_{idx:03d}.sql")
        with open(path, "w", encoding="utf-8") as out:
            out.writelines(blocks)
        n_file += 1

    blocks, idx = [], 1
    for d in arricchire:
        b = gs.gen_block(d["specie_base"], d["slug"])
        if not b:
            n_vuote += 1
            continue
        blocks.append(b + "\n")
        if len(blocks) >= chunk_size:
            flush(blocks, "arricchimento", idx)
            idx += 1
            blocks = []
    flush(blocks, "arricchimento", idx)

    blocks, idx = [], 1
    for d in nuove:
        blocks.append(gen_insert(d))
        if len(blocks) >= chunk_size:
            flush(blocks, "nuove", idx)
            idx += 1
            blocks = []
    flush(blocks, "nuove", idx)

    print(f"File SQL generati: {n_file} in {OUT_DIR}")
    print(f"Arricchimenti saltati (nessun campo utile trovato da gen_block): {n_vuote}")


if __name__ == "__main__":
    main()
