"""
Genera l'INSERT SQL per le specie genuinamente nuove trovate nel controllo
periodico sitemap RHS (29-30/09/2026, follow-up issue #153): delle 108
pagine davvero nuove (su 64.740 candidate, il resto erano alias legacy di
contenuto già posseduto — vedi progresso_nuove.log), solo queste risultano
specie base con contenuto specifico di cura E assenti dalla tabella
`specie` (verificato a mano via query Supabase il 30/09/2026):

- Aeonium tabuliforme (aeonium-tabuliforme)
- Centaurea bella (psephellus-bellus — RHS ha spostato il genere)
- Centaurea simplicicaulis (psephellus-simplicicaulis)
- Leuzea centaureoides (rhaponticum-centauroides)
- Perovskia hybrida (salvia-hybrida-pe)
- Centaurea alpestris (centaurea-scabiosa-subsp-alpestris — RHS la tratta
  come nome accettato a sé, non come sottospecie nel titolo pagina)

Le altre 102 pagine sono state scartate: già presenti in catalogo sotto
lo stesso nome (Ilex myrtifolia, Hosta fortunei, Sorbus cashmiriana,
Cupressus funebris — RHS ha solo cambiato l'ID canonico), solo testo di
genere senza dati di cura, o cultivar singole di generi già ampiamente
coperti (Dahlia, Narcissus, Delphinium, Camellia, ecc. — per policy le
cultivar non ricevono una riga propria, vedi README).

Uso:
    python3 genera_sql_nuove_108.py > sql_sitemaps/nuove_verificate_post_108.sql
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import genera_sql_sitemaps as gss

SLUGS = [
    "aeonium-tabuliforme",
    "psephellus-bellus",
    "psephellus-simplicicaulis",
    "rhaponticum-centauroides",
    "salvia-hybrida-pe",
    "centaurea-scabiosa-subsp-alpestris",
]

SLUG_FINALE = {
    "aeonium-tabuliforme": "aeonium-tabuliforme",
    "psephellus-bellus": "centaurea-bella",
    "psephellus-simplicicaulis": "centaurea-simplicicaulis",
    "rhaponticum-centauroides": "leuzea-centaureoides",
    "salvia-hybrida-pe": "perovskia-hybrida",
    "centaurea-scabiosa-subsp-alpestris": "centaurea-alpestris",
}


def carica_record(slug):
    with open(os.path.join(HERE, "nuove_108_parsed.jsonl"), encoding="utf-8") as f:
        for line in f:
            d = json.loads(line)
            if d["rhs_url_slug"] == slug:
                return d
    raise KeyError(slug)


from rhs_dimensioni import extract_numbers, is_open


def main():
    for rhs_slug in SLUGS:
        r = carica_record(rhs_slug)
        heights = extract_numbers(r.get("altezza_max"))
        spreads = extract_numbers(r.get("diffusione_max"))
        d = {
            "specie_base": r["nome_scientifico_titolo"],
            "slug": SLUG_FINALE[rhs_slug],
            "n_pagine": 1,
            "famiglia_botanica": r.get("famiglia_botanica"),
            "descrizione_breve": r.get("descrizione_breve"),
            "genere_descrizione": r.get("genere_descrizione"),
            "cultivation": r.get("cultivation"),
            "propagation": r.get("propagation"),
            "pruning": r.get("pruning"),
            "pests": r.get("pests"),
            "diseases": r.get("diseases"),
            "moisture": r.get("moisture"),
            "ph": r.get("ph"),
            "position": r.get("position"),
            "soil_types": r.get("soil_types"),
            "altezza_min_max": [min(heights), max(heights)] if heights else None,
            "diffusione_min_max": [min(spreads), max(spreads)] if spreads else None,
            "altezza_oltre": is_open(r.get("altezza_max")),
            "diffusione_oltre": is_open(r.get("diffusione_max")),
            "hardiness_set": [r["hardiness"]] if r.get("hardiness") else [],
            "cultivar_names": [],
        }
        sys.stdout.write(gss.gen_insert(d))


if __name__ == "__main__":
    main()
