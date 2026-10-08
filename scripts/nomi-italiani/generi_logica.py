"""Logica pura per il lavoro sui generi: nessuna rete, nessun database."""
import re
from collections import Counter

from genera_lotto3 import n, scarto


def genere_di(nome_scientifico):
    """Il genere (primo termine) se il nome scientifico inizia con un genere, altrimenti None."""
    if not nome_scientifico:
        return None
    primo = nome_scientifico.split(" ")[0]
    return primo if re.fullmatch(r"[A-Z][a-z]+", primo) else None


def conta_specie_gbif(match, ricerca):
    """Specie accettate di un genere secondo GBIF, solo se la corrispondenza è esatta, accettata e di rango genere."""
    if not match or match.get("matchType") != "EXACT" or match.get("status") != "ACCEPTED" or match.get("rank") != "GENUS":
        return None
    if ricerca is None:
        return None
    return ricerca.get("count")


def decisione(n_specie, nome_scientifico):
    """'gia_spp' | 'spp' | 'specie' | 'rivedere' per una riga di genere."""
    if re.search(r" (spp|sp)\.$", nome_scientifico or ""):
        return "gia_spp"
    if n_specie is None:
        return "rivedere"
    return "spp" if n_specie > 1 else "specie"


def nome_genere_inat(risposta, genere):
    """Nome italiano preferito di iNaturalist per il genere, con iniziale maiuscola; None se manca o non va usato."""
    if not risposta:
        return None
    for t in risposta.get("results", []):
        if t.get("name", "").lower() == genere.lower() and t.get("rank") in ("genus", "subgenus"):
            nome = t.get("preferred_common_name")
            if not nome:
                return None
            nome = nome.strip()
            nome = nome[0].upper() + nome[1:]
            return None if scarto(nome, genere, Counter()) else nome
    return None


def descrive_specie(descrizione, nome_scientifico):
    """True se la descrizione inizia con il nome della specie (riga che descrive la specie, non il genere)."""
    return bool(descrizione) and descrizione.lstrip().lower().startswith(nome_scientifico.lower())


def slug_di(nome_scientifico):
    return re.sub(r"[^a-z0-9-]", "", nome_scientifico.lower().replace(" ", "-"))


def nome_libero(nome, in_uso):
    """True se il nome (normalizzato) non è già nell'insieme dei nomi in uso."""
    return n(nome) not in in_uso


def riga_di_genere(slug, nome_scientifico):
    """True se la riga rappresenta un genere: nome del solo genere, 'spp.'/'sp.' o slug uguale al genere."""
    if not nome_scientifico:
        return False
    if re.search(r" (spp|sp)\.$", nome_scientifico):
        return True
    genere = genere_di(nome_scientifico)
    if not genere:
        return False
    return " " not in nome_scientifico.strip() or slug == genere.lower()
