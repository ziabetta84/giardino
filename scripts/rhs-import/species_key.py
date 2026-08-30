"""
Estrazione della chiave "specie base" da un titolo di pagina RHS, condivisa
da aggregate_sitemaps.py e build_full_aggregate.py (prima duplicata in
entrambi, unificata qui dopo il recupero delle 17.696 pagine scartate al
primo giro -- vedi issue #153).

Il primo giro riconosceva solo il binomio classico "Genere epiteto" (con
"Genere × epiteto" per gli ibridi infra-generici). Restavano fuori tre
categorie non-rumore, individuate analizzando le pagine scartate:
- grex di orchidee: "Genere Nomegrex ... gx ..." (es. "Phalaenopsis Miva
  Pieta gx 'Monique'") -- ibridi orticoli reali, spesso con una propria
  scheda di coltivazione RHS.
- ibridi intergenerici: "× Genere epiteto" o "× Genere Nomegrex gx" (es.
  "× Sorbopyrus auricularis", "× Laeliocattleya Phryne gx") -- il × come
  primo carattere (nothogenere), non gestito dal parser originale che
  cercava il × solo in seconda posizione.
- identificazione incerta: "Genere aff./cf. epiteto" (es. "Puya aff.
  nitida") -- riferimento a una specie ma con match non confermato: tenuta
  come chiave *distinta* dal binomio confermato (mai unita alla riga
  verificata) e mai promuovibile a stato_verifica='verificato', qualunque
  sia il contenuto (l'identificazione stessa è incerta).

Il resto delle pagine scartate (cultivar Group/Series, codici di selezione
interni da vivaio/breeder tipo "Iris Sdg GBS 105") resta escluso: non sono
specie, e includerle sarebbe lo stesso rumore già scartato per le ~31.265
solo-genere della Fase 6 (decisione utente).

Nota sul parsing: binomio/ibrido-intergenerico/incerto pretendono che
l'epiteto segua il genere *direttamente nel testo grezzo* (senza
virgolette/parentesi in mezzo) -- un primo tentativo che ripuliva prima le
virgolette (utile per i grex, dove il cultivar tra apici segue il nome del
grex) produceva falsi epiteti dal testo dopo un cultivar tolto, es.
"Heuchera 'Emperor's Cloak' green-leaved" -> "Heuchera green-leaved"
(green-leaved è un descrittore del cultivar, non un epiteto). Per questo
i tre casi "diretti" lavorano sui token grezzi, e solo il grex (dove il
cultivar tra apici legittimamente segue il nome) ripulisce le virgolette.
"""
import re

EPITHET = re.compile(r"^[a-z][a-zA-Z-]+$")
GENUS = re.compile(r"^[A-Z][a-zA-Z-]+$")
# Nome di grex/gruppo: 1-3 parole che iniziano per maiuscola (esclude i
# codici di selezione tipo "Sdg 1"/"CC 4613", che contengono token
# puramente numerici o che non iniziano per lettera maiuscola).
GREX_NAME = re.compile(r"^[A-Z][a-zA-Z-]*(\s[A-Z][a-zA-Z-]*){0,2}$")
NON_SPECIE_TOKENS = {"Group", "Series", "hybrids", "Hybrids", "hybrid", "Hybrid"}


def base_species(latin):
    """Compatibilità con il codice esistente: solo la chiave, senza kind."""
    sp, _ = base_species_ext(latin)
    return sp


def base_species_ext(latin):
    """Ritorna (chiave_specie, kind) oppure (None, None) se non recuperabile.

    kind è uno tra: 'binomio', 'ibrido-intergenerico', 'grex', 'incerto'.
    """
    if not latin:
        return None, None
    raw = latin.strip()
    if not raw:
        return None, None
    raw_tok = raw.split(" ")

    idx = 0
    ibrido = False
    if raw_tok[idx] == "×":
        ibrido = True
        idx += 1
    if idx >= len(raw_tok) or not GENUS.match(raw_tok[idx]):
        return None, None
    genere = raw_tok[idx]
    idx += 1
    if idx >= len(raw_tok):
        return None, None
    nxt = raw_tok[idx]

    # aff./cf.: identificazione incerta -- l'epiteto deve seguire subito il marcatore
    if nxt in ("aff.", "cf.") and idx + 1 < len(raw_tok) and EPITHET.match(raw_tok[idx + 1]):
        return f"{genere} {nxt} {raw_tok[idx + 1]}", "incerto"

    # ibrido infra-generico: "Genere × epiteto"
    if not ibrido and nxt == "×" and idx + 1 < len(raw_tok) and EPITHET.match(raw_tok[idx + 1]):
        return f"{genere} × {raw_tok[idx + 1]}", "binomio"

    # binomio classico o ibrido intergenerico: l'epiteto segue subito il genere, testo grezzo
    if EPITHET.match(nxt):
        return (f"× {genere} {nxt}", "ibrido-intergenerico") if ibrido else (f"{genere} {nxt}", "binomio")

    # grex di orchidee: qui il cultivar tra apici legittimamente segue il nome del
    # grex, quindi ripuliamo virgolette/parentesi prima di validare (marcatore "gx"
    # obbligatorio per non riassorbire Group/Series/codici di selezione)
    s = re.sub(r"'.*'", "", raw)  # greedy: unisce le virgolette annidate ("Nice 'n' Nifty") in un solo blocco
    s = re.sub(r"\([^)]*\)", "", s)
    s = re.sub(r"\[[^\]]*\]", "", s)
    s = re.sub(r"\s+", " ", s).strip()
    parole = s.split(" ")
    if parole and parole[0] == "×":
        parole = parole[1:]
    resto = parole[1:] if len(parole) > 1 else []
    if "gx" not in resto:
        return None, None
    resto_grex = [t for t in resto if t != "gx"]
    if not resto_grex or any(t in NON_SPECIE_TOKENS for t in resto_grex):
        return None, None
    nome_grex = " ".join(resto_grex)
    if not GREX_NAME.match(nome_grex):
        return None, None
    prefisso = "× " if ibrido else ""
    return f"{prefisso}{genere} {nome_grex}", "grex"
