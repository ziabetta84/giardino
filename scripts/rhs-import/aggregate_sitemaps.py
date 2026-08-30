"""
Aggregazione a scala piena del JSONL prodotto da parse_rhs_sitemaps.py
(304.006 pagine, l'intero sitemap RHS) in gruppi per specie base, con
match bulk contro le specie gia' in tabella `specie` su Supabase.

A differenza di aggregate_rhs.py (che carica un array JSON piccolo in RAM
e non fa alcun match: il match veniva fatto a mano, coppia per coppia,
nei batch_*.py per le ~200 specie di rhs-varieta/), qui il volume rende
necessario:
- leggere il JSONL riga per riga (streaming), non un unico json.load
- fare il match una volta sola in blocco contro l'export locale di
  specie_esistenti.tsv (slug, nome_scientifico, fonti), non query singole

Non scrive nulla: produce solo statistiche + un JSON con i gruppi
classificati, da ispezionare prima di generare/applicare SQL (vedi
issue #153, punto 2 della pipeline).

Uso:
    python3 aggregate_sitemaps.py
"""
import json, os, re, sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
JSONL = os.path.join(HERE, "rhs_sitemaps_parsed.jsonl")
ESISTENTI_TSV = os.path.join(HERE, "specie_esistenti.tsv")
OUT_FILE = os.path.join(HERE, "rhs_sitemaps_aggregato.json")

FONTE_RHS_PREFIX = "RHS (rhs.org.uk)"


# Valida il nome estratto per scartare i frammenti di parsing (titoli con
# virgolette/parentesi non bilanciate lasciano residui tipo "Dahlia s'" o
# "Camellia )" -- scoperti a valle come slug duplicati/collidenti, vedi
# issue #153): genere maiuscolo, poi 1-2 epiteti minuscoli di almeno 2
# lettere (o un ibrido "× epiteto").
VALID_NAME = re.compile(r"^[A-Z][a-zA-Z-]+(\s×\s[a-zA-Z-]+|(\s[a-z][a-zA-Z-]+){1,2})?$")


def base_species(latin):
    if not latin:
        return None
    s = re.sub(r"'[^']*'", '', latin)
    s = re.sub(r'\([^)]*\)', '', s)
    s = re.sub(r'\[[^\]]*\]', '', s)
    s = re.sub(r'\s+', ' ', s).strip()
    if not s:
        return None
    parts = s.split(' ')
    if len(parts) >= 3 and parts[1] == '×':
        sp = ' '.join(parts[:3])
    else:
        sp = ' '.join(parts[:2]) if len(parts) >= 2 else s
    return sp if VALID_NAME.match(sp) else None


def norm(name):
    """Normalizzazione leggera per il match: lowercase, spazi singoli, × uniformata."""
    if not name:
        return ""
    return re.sub(r'\s+', ' ', name.replace('x ', '× ').strip().lower())


def slugify(name):
    import unicodedata
    s = name.replace('×', 'x')
    s = unicodedata.normalize('NFD', s)
    s = ''.join(c for c in s if not unicodedata.combining(c))
    s = re.sub(r'[^a-zA-Z0-9]+', '-', s).strip('-').lower()
    return s


def load_esistenti():
    by_norm_name = {}
    by_slug = {}
    with open(ESISTENTI_TSV, encoding="utf-8") as fh:
        for line in fh:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 2:
                continue
            slug, nome_sci = parts[0], parts[1]
            fonti = parts[2] if len(parts) > 2 else ""
            entry = {"slug": slug, "nome_scientifico": nome_sci,
                      "gia_rhs": FONTE_RHS_PREFIX in fonti}
            by_norm_name[norm(nome_sci)] = entry
            by_slug[slug] = entry
    return by_norm_name, by_slug


def has_specific_content(d):
    return any([
        d.get("descrizione_breve"), d.get("cultivation"), d.get("propagation"),
        d.get("pruning"), d.get("pests"), d.get("diseases"), d.get("position"),
        d.get("soil_types"), d.get("moisture"), d.get("altezza_max"), d.get("diffusione_max"),
    ])


def main():
    by_norm_name, by_slug = load_esistenti()
    print(f"Specie esistenti in catalogo: {len(by_slug)}")

    groups = defaultdict(list)
    n_righe = 0
    n_senza_nome = 0
    with open(JSONL, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            n_righe += 1
            d = json.loads(line)
            sp = base_species(d.get("nome_scientifico_titolo"))
            if not sp:
                n_senza_nome += 1
                continue
            groups[sp].append(d)

    print(f"Righe totali lette: {n_righe} (senza nome utilizzabile: {n_senza_nome})")
    print(f"Gruppi specie-base distinti: {len(groups)}")

    aggregated = []
    n_match_gia_rhs = 0
    n_match_da_arricchire = 0
    n_nuova_specie = 0
    n_nessun_contenuto = 0

    for sp, entries in groups.items():
        base_entry = next((e for e in entries if norm(e.get("nome_scientifico_titolo")) == norm(sp)), None)
        ref = base_entry or entries[0]

        any_specific = any(has_specific_content(e) for e in entries)
        any_genere = any(e.get("genere_descrizione") for e in entries)
        if not any_specific and not any_genere:
            n_nessun_contenuto += 1
            continue

        m = by_norm_name.get(norm(sp))
        if m is None and slugify(sp) in by_slug:
            # nessun match sul nome scientifico normalizzato, ma lo slug
            # generato collide comunque con una riga esistente (es. una
            # voce di genere gia' in catalogo con nome_scientifico diverso
            # dal titolo RHS) -- tratta come match anziche' rischiare un
            # insert con slug duplicato (violerebbe lo UNIQUE constraint).
            m = by_slug[slugify(sp)]
        if m is None:
            n_nuova_specie += 1
            stato_match = "nuova"
        elif m["gia_rhs"]:
            n_match_gia_rhs += 1
            stato_match = "gia_rhs"
        else:
            n_match_da_arricchire += 1
            stato_match = "da_arricchire"

        aggregated.append({
            "specie_base": sp,
            "stato_match": stato_match,
            "slug_esistente": m["slug"] if m else None,
            "n_pagine": len(entries),
            "ha_pagina_specie_base": base_entry is not None,
            "ha_contenuto_specifico": any_specific,
            "files": [e["file"] for e in entries],
        })

    print()
    print(f"Con contenuto utile (specifico o di genere): {len(aggregated)}")
    print(f"  - senza alcun contenuto (stub puro, scartati): {n_nessun_contenuto}")
    print(f"  - gia' presenti con fonte RHS (skip, gia' importati in Fase 5): {n_match_gia_rhs}")
    print(f"  - match su specie esistente da arricchire: {n_match_da_arricchire}")
    print(f"  - nessun match: candidate a nuova riga: {n_nuova_specie}")

    n_nuova_con_contenuto_specifico = sum(
        1 for a in aggregated if a["stato_match"] == "nuova" and a["ha_contenuto_specifico"]
    )
    print(f"    di cui con contenuto specifico (promuovibili a 'verificato'): {n_nuova_con_contenuto_specifico}")

    with open(OUT_FILE, "w", encoding="utf-8") as out:
        json.dump(aggregated, out, ensure_ascii=False, indent=1)
    print(f"\nOutput: {OUT_FILE}")


if __name__ == "__main__":
    main()
