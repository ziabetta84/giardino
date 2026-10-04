"""Logica pura per importare i nomi comuni italiani da Wikidata in specie.nome."""
import re
from collections import defaultdict

MAX_LUNGHEZZA = 60


def normalizza_nome(nome):
    n = re.sub(r"\s+", " ", (nome or "").strip())
    if not n or len(n) > MAX_LUNGHEZZA or "/" in n or re.search(r"\d", n):
        return None
    return n[0].upper() + n[1:]


def _senza_parentesi(titolo):
    return re.sub(r"\s*\(.*?\)\s*$", "", titolo or "").strip()


def scegli_nome(sci, candidati):
    """Ritorna (nome, criterio). Criteri: unico, preferito, itwiki, ambiguo, nessuno."""
    unici = {}
    for cand in candidati:
        if cand["rank"] == "deprecated":
            continue
        n = normalizza_nome(cand["nome"])
        if n is None or n.lower() == sci.strip().lower():
            continue
        e = unici.setdefault(n.lower(), {"nome": n, "preferred": False, "itwiki": False})
        e["preferred"] = e["preferred"] or cand["rank"] == "preferred"
        titolo = _senza_parentesi(cand.get("itwiki")).lower()
        e["itwiki"] = e["itwiki"] or titolo == n.lower()
    voci = list(unici.values())
    if not voci:
        return None, "nessuno"
    if len(voci) == 1:
        return voci[0]["nome"], "unico"
    for campo, criterio in (("preferred", "preferito"), ("itwiki", "itwiki")):
        scelti = [v for v in voci if v[campo]]
        if len(scelti) == 1:
            return scelti[0]["nome"], criterio
    return None, "ambiguo"


def nomi_plantnet(sci, nomi_comuni):
    """Nomi italiani distinti e normalizzati di una specie PlantNet (ordine di arrivo).

    Scarta i nomi non validi (vedi normalizza_nome) e quelli uguali al nome scientifico.
    """
    visti, risultato = set(), []
    for grezzo in nomi_comuni or []:
        n = normalizza_nome(grezzo)
        if n is None or n.lower() == sci.strip().lower() or n.lower() in visti:
            continue
        visti.add(n.lower())
        risultato.append(n)
    return risultato


def abbina_slug(proposte, righe_db):
    """Abbina i nomi proposti alle righe del DB per nome scientifico.

    Ritorna (coppie, omonimi_saltati):
    - coppie: list[(slug, nuovo_nome)] ordinata per slug
    - omonimi_saltati: list[nome_scientifico] per cui ci sono più righe
    """
    per_sci = defaultdict(list)
    for r in righe_db:
        per_sci[r["nome_scientifico"].strip().lower()].append(r)
    coppie, saltati = [], []
    for chiave, righe in per_sci.items():
        if chiave not in proposte:
            continue
        if len(righe) > 1:
            saltati.append(righe[0]["nome_scientifico"])
            continue
        coppie.append((righe[0]["slug"], proposte[chiave]))
    return sorted(coppie), sorted(saltati)


def sql_str(s):
    """Converte una stringa in letterale SQL con apici raddoppiati."""
    return "'" + s.replace("'", "''") + "'"


def genera_migration(coppie, lotto):
    """Genera le migration SQL (up e rollback) per applicare i nomi italiani.

    Ritorna (sql_applica, sql_rollback).
    """
    valori = ",\n  ".join(f"({sql_str(slug)}, {sql_str(nome)})" for slug, nome in coppie)
    up = (
        f"-- Nomi italiani ({lotto}): sostituisce nome con il nome comune italiano da Wikidata.\n"
        "-- Solo righe ancora senza nome italiano (nome = nome_scientifico) e non cultivar.\n"
        "update specie s set nome = v.nome\n"
        f"from (values\n  {valori}\n) as v(slug, nome)\n"
        "where s.slug = v.slug\n"
        "  and s.nome = s.nome_scientifico\n"
        "  and s.specie_padre_id is null;\n"
    )
    down = (
        f"-- Rollback {lotto}: ripristina nome = nome_scientifico solo per le righe che portano\n"
        "-- ancora esattamente il nome impostato da questa migration.\n"
        "update specie s set nome = s.nome_scientifico\n"
        f"from (values\n  {valori}\n) as v(slug, nome)\n"
        "where s.slug = v.slug\n"
        "  and s.nome = v.nome;\n"
    )
    return up, down
