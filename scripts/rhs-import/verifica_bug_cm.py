"""
Verifica quante righe della Fase 6/6b (30/08/2026, issue #153) hanno preso
il bug cm/m scoperto il 30/09/2026: build_full_aggregate.py (e la sua
sorella per il recupero) leggono i numeri da altezza_max/diffusione_max
senza guardare l'unità -- per le piante piccole RHS scrive "Up to 10 cm"
invece di "0.1-0.5 metres", e il numero finiva nell'alert "Dimensioni RHS
a maturità" come se fosse già in metri (10 cm -> "10m" invece di "0.1m").

Non tocca nulla: ricalcola altezza_min_max/diffusione_min_max in modo
unit-aware per ogni gruppo di rhs_sitemaps_full_aggregato.json e
rhs_recupero_aggregato.json (leggendo i valori grezzi per pagina da
rhs_sitemaps_parsed.jsonl) e confronta col valore già usato per generare
l'SQL applicato. Scrive un report con i gruppi diversi, per decidere se e
come correggere le righe già in Supabase.

Uso:
    python3 verifica_bug_cm.py
"""
import json, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
JSONL = os.path.join(HERE, "rhs_sitemaps_parsed.jsonl")
FULL_AGG = os.path.join(HERE, "rhs_sitemaps_full_aggregato.json")
RECUPERO_AGG = os.path.join(HERE, "rhs_recupero_aggregato.json")
OUT_FILE = os.path.join(HERE, "bug_cm_report.json")


def extract_numbers_buggy(s):
    """Stessa logica (col bug) di build_full_aggregate.extract_numbers."""
    if not s:
        return []
    return [float(x.replace(',', '.')) for x in re.findall(r'\d+(?:[.,]\d+)?', s)]


def extract_numbers_fixed(s):
    if not s:
        return []
    nums = extract_numbers_buggy(s)
    if 'cm' in s.lower() and 'metres' not in s.lower():
        nums = [n / 100 for n in nums]
    return nums


def build_index():
    """file -> (altezza_max, diffusione_max) grezzi, dal JSONL completo."""
    idx = {}
    with open(JSONL, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            d = json.loads(line)
            idx[d["file"]] = (d.get("altezza_max"), d.get("diffusione_max"))
    return idx


def carica_gruppi():
    gruppi = json.load(open(FULL_AGG, encoding="utf-8"))
    if os.path.exists(RECUPERO_AGG):
        rec = json.load(open(RECUPERO_AGG, encoding="utf-8"))
        for a in rec:
            if (a["stato_match"] == "nuova" and a.get("ha_contenuto_specifico")) or a["stato_match"] == "da_arricchire":
                # rhs_recupero_aggregato.json e' l'output della prima passata
                # (come rhs_sitemaps_aggregato.json), non ha altezza_min_max/
                # files "pesanti" nello stesso formato -- se manca lo salta,
                # non e' tra i gruppi che hanno generato SQL con questo campo.
                if "altezza_min_max" in a or "diffusione_min_max" in a:
                    gruppi.append(a)
    return gruppi


def main():
    print("Indicizzo valori grezzi altezza/diffusione dal JSONL completo...")
    idx = build_index()
    print(f"  {len(idx)} pagine indicizzate")

    gruppi = carica_gruppi()
    print(f"Gruppi da ricontrollare: {len(gruppi)}")

    affetti = []
    for g in gruppi:
        files = g.get("files") or []
        heights_fixed, spreads_fixed = [], []
        for fn in files:
            am, dm = idx.get(fn, (None, None))
            heights_fixed += extract_numbers_fixed(am)
            spreads_fixed += extract_numbers_fixed(dm)

        fixed_h = [min(heights_fixed), max(heights_fixed)] if heights_fixed else None
        fixed_s = [min(spreads_fixed), max(spreads_fixed)] if spreads_fixed else None

        stored_h = g.get("altezza_min_max")
        stored_s = g.get("diffusione_min_max")

        if (fixed_h != stored_h) or (fixed_s != stored_s):
            affetti.append({
                "specie_base": g["specie_base"],
                "slug": g["slug"],
                "altezza_min_max_db": stored_h,
                "altezza_min_max_corretto": fixed_h,
                "diffusione_min_max_db": stored_s,
                "diffusione_min_max_corretto": fixed_s,
            })

    print(f"\nGruppi con discrepanza (probabile bug cm/m): {len(affetti)}")
    with open(OUT_FILE, "w", encoding="utf-8") as out:
        json.dump(affetti, out, ensure_ascii=False, indent=1)
    print(f"Report scritto in {OUT_FILE}")

    for a in affetti[:20]:
        print(" ", a["slug"], "| altezza:", a["altezza_min_max_db"], "->", a["altezza_min_max_corretto"],
              "| diffusione:", a["diffusione_min_max_db"], "->", a["diffusione_min_max_corretto"])


if __name__ == "__main__":
    main()
