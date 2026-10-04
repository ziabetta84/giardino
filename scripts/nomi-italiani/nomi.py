"""Logica pura per importare i nomi comuni italiani da Wikidata in specie.nome."""
import re

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
