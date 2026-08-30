"""
Recupero delle pagine scartate dal primo giro Fase 6 (17.696 su 304.006,
vedi issue #153) grazie a species_key.base_species_ext: grex di orchidee,
ibridi intergenerici (× Genere...) e identificazioni incerte (aff./cf.).
Le restanti (~8.300, cultivar Group/Series/codici di selezione da vivaio)
restano escluse -- stesso criterio delle solo-genere della Fase 6.

Fa tutto in un solo script (a differenza della pipeline Fase 6 originale,
divisa in più file per via della scala): il sottoinsieme di partenza qui è
17.696 pagine, non 304.006, quindi un solo passaggio in RAM è sufficiente.

Uso:
    python3 recupera_scartate.py            # stampa solo le statistiche
    python3 recupera_scartate.py --sql       # genera anche i file SQL in sql_recupero/
"""
import json, os, re, sys, unicodedata
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from species_key import base_species_ext
import genera_sql as gs

JSONL = os.path.join(HERE, "rhs_sitemaps_parsed.jsonl")
ESISTENTI_TSV = os.path.join(HERE, "specie_esistenti.tsv")
OUT_DIR = os.path.join(HERE, "sql_recupero")

FONTE_RHS_PREFIX = "RHS (rhs.org.uk)"

VALID_NAME_OLD = re.compile(r"^[A-Z][a-zA-Z-]+(\s×\s[a-zA-Z-]+|(\s[a-z][a-zA-Z-]+){1,2})?$")


def base_species_old(latin):
    """Stessa logica (ristretta) usata dalla Fase 6 originale, solo per
    isolare l'esatto sottoinsieme di pagine scartate la prima volta."""
    if not latin:
        return None
    s = re.sub(r"'[^']*'", "", latin)
    s = re.sub(r"\([^)]*\)", "", s)
    s = re.sub(r"\[[^\]]*\]", "", s)
    s = re.sub(r"\s+", " ", s).strip()
    if not s:
        return None
    parts = s.split(" ")
    sp = " ".join(parts[:3]) if len(parts) >= 3 and parts[1] == "×" else (" ".join(parts[:2]) if len(parts) >= 2 else s)
    return sp if VALID_NAME_OLD.match(sp) else None


def norm(name):
    if not name:
        return ""
    return re.sub(r"\s+", " ", name.replace("x ", "× ").strip().lower())


def slugify(name):
    s = name.replace("×", "x")
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s).strip("-").lower()
    return s


def has_specific_content(d):
    return any([
        d.get("descrizione_breve"), d.get("cultivation"), d.get("propagation"),
        d.get("pruning"), d.get("pests"), d.get("diseases"), d.get("position"),
        d.get("soil_types"), d.get("moisture"), d.get("altezza_max"), d.get("diffusione_max"),
    ])


def extract_numbers(s):
    if not s:
        return []
    return [float(x.replace(",", ".")) for x in re.findall(r"\d+(?:[.,]\d+)?", s)]


def load_esistenti():
    by_norm_name = {}
    by_slug = {}
    nomi = set()
    with open(ESISTENTI_TSV, encoding="utf-8") as fh:
        for line in fh:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 4:
                continue
            slug, nome_sci, fonti, nome = parts[0], parts[1], parts[2], parts[3]
            entry = {"slug": slug, "nome_scientifico": nome_sci, "gia_rhs": FONTE_RHS_PREFIX in fonti}
            by_norm_name[norm(nome_sci)] = entry
            by_slug[slug] = entry
            nomi.add(nome)
    return by_norm_name, by_slug, nomi


def main():
    genera_sql_flag = "--sql" in sys.argv[1:]

    by_norm_name, by_slug, nomi_esistenti = load_esistenti()
    print(f"Specie esistenti in catalogo: {len(by_slug)}")

    groups = defaultdict(list)
    kind_of = {}
    n_letti = n_vecchie_scartate = n_ancora_scartate = 0
    with open(JSONL, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            n_letti += 1
            d = json.loads(line)
            latin = d.get("nome_scientifico_titolo")
            if base_species_old(latin) is not None:
                continue  # già processata nella Fase 6 originale
            n_vecchie_scartate += 1
            sp, kind = base_species_ext(latin)
            if sp is None:
                n_ancora_scartate += 1
                continue
            groups[sp].append(d)
            kind_of[sp] = kind

    print(f"Pagine lette: {n_letti}, già scartate al primo giro: {n_vecchie_scartate}")
    print(f"Ancora non recuperabili (Group/Series/codici di selezione): {n_ancora_scartate}")
    print(f"Nuovi gruppi recuperati: {len(groups)}")

    aggregated = []
    for sp, entries in groups.items():
        kind = kind_of[sp]
        base_entry = next((e for e in entries if norm(e.get("nome_scientifico_titolo")) == norm(sp)), None)
        ref = base_entry or entries[0]

        any_specific = any(has_specific_content(e) for e in entries)
        any_genere = any(e.get("genere_descrizione") for e in entries)
        if not any_specific and not any_genere:
            continue

        heights, spreads = [], []
        hardiness_set, foliage_set, habit_set, cultivar_names = set(), set(), set(), []
        for e in entries:
            heights += extract_numbers(e.get("altezza_max"))
            spreads += extract_numbers(e.get("diffusione_max"))
            if e.get("hardiness"):
                hardiness_set.add(e["hardiness"])
            if e.get("fogliame"):
                foliage_set.add(e["fogliame"])
            if e.get("habit"):
                habit_set.add(e["habit"])
            m = re.search(r"'([^']*)'", e.get("nome_scientifico_titolo") or "")
            if m:
                cultivar_names.append(m.group(1))

        slug_gen = slugify(sp)
        m = by_norm_name.get(norm(sp))
        if m is None and slug_gen in by_slug:
            m = by_slug[slug_gen]

        if m is None:
            stato_match, slug_finale = "nuova", slug_gen
        elif m["gia_rhs"]:
            stato_match, slug_finale = "gia_rhs", m["slug"]
        else:
            stato_match, slug_finale = "da_arricchire", m["slug"]

        aggregated.append({
            "specie_base": sp,
            "kind": kind,
            "stato_match": stato_match,
            "slug": slug_finale,
            "n_pagine": len(entries),
            "ha_contenuto_specifico": any_specific,
            "famiglia_botanica": ref.get("famiglia_botanica"),
            "descrizione_breve": ref.get("descrizione_breve"),
            "genere_descrizione": ref.get("genere_descrizione"),
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
            "cultivar_names": cultivar_names,
        })

    from collections import Counter
    print()
    print("Per kind e stato_match:")
    c = Counter((a["kind"], a["stato_match"]) for a in aggregated)
    for k, v in sorted(c.items()):
        print(f"  {v:5d}  {k}")
    n_stub = len(groups) - len(aggregated)
    print(f"Scartate per nessun contenuto utile (stub puro): {n_stub}")

    # nuove: tenute solo con contenuto specifico (stessa regola della Fase 6:
    # niente solo-genere) -- per gli 'incerto' inoltre mai stato_verifica='verificato'
    nuove = [a for a in aggregated if a["stato_match"] == "nuova" and a["ha_contenuto_specifico"]]
    arricchire = [a for a in aggregated if a["stato_match"] == "da_arricchire"]
    scartate_solo_genere = [a for a in aggregated if a["stato_match"] == "nuova" and not a["ha_contenuto_specifico"]]

    # collisioni su nome/slug tra le nuove candidate
    slugs_visti, nomi_visti = set(), set()
    nuove_pulite, scartate_collisione = [], []
    for a in nuove:
        if a["slug"] in slugs_visti or a["slug"] in by_slug or a["specie_base"] in nomi_visti or a["specie_base"] in nomi_esistenti:
            scartate_collisione.append(a)
            continue
        slugs_visti.add(a["slug"])
        nomi_visti.add(a["specie_base"])
        nuove_pulite.append(a)

    print()
    print(f"Candidate nuove con contenuto specifico: {len(nuove)}")
    print(f"  scartate per collisione nome/slug: {len(scartate_collisione)}")
    print(f"  effettivamente da inserire: {len(nuove_pulite)}")
    print(f"Candidate solo-genere escluse (stesso criterio Fase 6): {len(scartate_solo_genere)}")
    print(f"Da arricchire (righe già esistenti): {len(arricchire)}")

    if not genera_sql_flag:
        json.dump(aggregated, open(os.path.join(HERE, "rhs_recupero_aggregato.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        return

    os.makedirs(OUT_DIR, exist_ok=True)
    for f in os.listdir(OUT_DIR):
        os.remove(os.path.join(OUT_DIR, f))

    def build_fields(d):
        rhs_name = d["specie_base"]
        fonte = f"{FONTE_RHS_PREFIX} — {rhs_name}"
        desc_bits = []
        if d.get("descrizione_breve"):
            desc_bits.append(f"Da RHS (testo originale in inglese): \"{gs.esc(d['descrizione_breve'])}\".")
        elif d.get("genere_descrizione"):
            desc_bits.append(f"Da RHS, descrizione del genere (testo originale in inglese): \"{gs.esc(d['genere_descrizione'])}\".")
        if d["kind"] == "incerto":
            desc_bits.append("Identificazione RHS non confermata (\"aff./cf.\": probabilmente questa specie, corrispondenza non certa) — dato da trattare con cautela.")
        if d["n_pagine"] > 1:
            h = gs.fmt_range(d.get("altezza_min_max"))
            s = gs.fmt_range(d.get("diffusione_min_max"))
            cvs = d.get("cultivar_names") or []
            sample = ", ".join(f"'{c}'" for c in cvs[:6])
            extra = f" (tra cui {sample}{'...' if len(cvs) > 6 else ''})" if sample else ""
            size_bit = f" con altezze da {h}" if h else ""
            if s:
                size_bit += f" e diffusione da {s}" if h else f" con diffusione da {s}"
            desc_bits.append(f"RHS elenca {d['n_pagine']} pagine/cultivar coltivate{size_bit}{extra}.")
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
        rhs_name, slug = d["specie_base"], d["slug"]
        fonte, descrizione, esigenze, alert_items = build_fields(d)
        # 'incerto' resta sempre bozza, qualunque sia il contenuto: l'identificazione stessa non è confermata
        stato = "'bozza'" if d["kind"] == "incerto" else "'verificato'"
        cols = ["slug", "nome", "nome_scientifico", "famiglia_botanica", "fonti", "stato_verifica"]
        vals = [f"$t${slug}$t$", f"$t${rhs_name}$t$", f"$t${rhs_name}$t$",
                f"$t${d['famiglia_botanica']}$t$" if d.get("famiglia_botanica") else "null",
                f"ARRAY[$t${fonte}$t$]", stato]
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

    def gen_update(d):
        fonte, descrizione, esigenze, alert_items = build_fields(d)
        setters = []
        if descrizione:
            setters.append(f"  descrizione = coalesce(descrizione, '') || $t$ {descrizione}$t$")
        if esigenze:
            esigenze_json = json.dumps(esigenze, ensure_ascii=False)
            setters.append(f"  esigenze = ($t${esigenze_json}$t$::jsonb) || coalesce(esigenze, '{{}}'::jsonb)")
        if alert_items:
            arr = ",\n    ".join(f"$t${gs.esc(a)}$t$" for a in alert_items)
            setters.append(f"  alert = coalesce(alert, ARRAY[]::text[]) || ARRAY[\n    {arr}\n  ]")
        setters.append(f"  fonti = array_append(coalesce(fonti, ARRAY[]::text[]), $t${fonte}$t$)")
        if d["ha_contenuto_specifico"] and d["kind"] != "incerto":
            setters.append("  stato_verifica = 'verificato'")
        if not setters:
            return ""
        sql = ["update specie set", ",\n".join(setters), f"where slug = $t${d['slug']}$t$",
               f"  and not ($t${fonte}$t$ = any(coalesce(fonti, ARRAY[]::text[])));"]
        return "\n".join(sql) + "\n"

    with open(os.path.join(OUT_DIR, "nuove_001.sql"), "w", encoding="utf-8") as out:
        for d in nuove_pulite:
            out.write(gen_insert(d))
    with open(os.path.join(OUT_DIR, "arricchimento_001.sql"), "w", encoding="utf-8") as out:
        for d in arricchire:
            b = gen_update(d)
            if b:
                out.write(b + "\n")

    print(f"\nSQL scritto in {OUT_DIR}/")


if __name__ == "__main__":
    main()
