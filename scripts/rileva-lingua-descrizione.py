#!/usr/bin/env python3
"""Rilevatore di lingua per specie.descrizione — rapporto di function word IT vs EN.
Pure Python, nessuna dipendenza. Classi:
  it    testo in italiano
  en    testo in inglese (prosa PFAF/RHS non tradotta)
  mixed prosa italiana con blocchi inglesi non tradotti
  stub  solo prefisso label / poche parole, nessun testo descrittivo reale
  nd    segnale troppo debole per decidere

Punto 6 del piano di naturalizzazione (issue #153): popola
specie.lingua_descrizione e sostituisce lo scoping SQL a regex \\mthe\\M.
"""
import re
import sys

# SOLO function word ad alta frequenza e non ambigue. Niente parole di
# contenuto (shrub/perennial/arbusto/perenne...) che comparirebbero anche
# nelle etichette bilingui.
EN = {
    "the", "a", "an", "and", "or", "of", "to", "in", "on", "at", "by", "for",
    "with", "from", "as", "is", "are", "was", "were", "be", "been", "being",
    "it", "its", "this", "that", "these", "those", "which", "their", "there",
    "has", "have", "had", "can", "may", "will", "would", "also", "when",
    "where", "while", "into", "than", "then", "such", "not", "but", "up",
    "about", "known", "native", "commonly", "usually", "often",
}
IT = {
    "il", "lo", "la", "i", "gli", "le", "un", "uno", "una", "di", "del",
    "dello", "della", "dei", "degli", "delle", "e", "ed", "o", "con", "per",
    "in", "nel", "nello", "nella", "nei", "negli", "nelle", "che", "cui",
    "è", "sono", "ha", "hanno", "essere", "da", "dal", "dalla", "dallo",
    "dai", "dagli", "dalle", "si", "come", "anche", "più", "meno", "non",
    "al", "allo", "alla", "ai", "agli", "alle", "su", "sul", "sulla",
    "tra", "fra", "questa", "questo", "queste", "questi", "quella", "quello",
    "molto", "spesso", "generalmente", "solitamente", "fino", "dove",
    "quando", "mentre", "ma", "se", "circa", "oltre", "sia", "suoi", "sue",
    "suo", "sua", "nota", "noto", "detta", "detto",
}

TOKEN_RE = re.compile(r"[a-zà-ÿ]+", re.IGNORECASE)

# Segmenti-etichetta da rimuovere prima dell'analisi: sono label bilingui
# ("Fabaceae or Leguminosae", "Portamento: Perennial") che non sono prosa.
LABEL_RE = re.compile(
    r"Famiglia botanica:[^.]*\.|"
    r"Portamento:[^.]*\.|"
    r"Altezza massima indicativa:[^.]*\.|"
    r"Bloom Colou?r:[^.]*\.|"
    r"Main Bloom Time:[^.]*\.|"
    r"Bloom Time:[^.]*\.|"
    r"Form:[^.]*\.|"
    r"Leaf Colou?r:[^.]*\.|"
    r"Da RHS(?:, descrizione del genere)? \(testo originale in inglese\):|"
    r"</?p>",
    re.IGNORECASE,
)

MIN_TOK = 8


def rileva(testo):
    if not testo:
        return "nd", 0, 0.0, 0.0
    pulito = LABEL_RE.sub(" ", testo)
    tok = [t.lower() for t in TOKEN_RE.findall(pulito)]
    n = len(tok)
    en_h = sum(1 for t in tok if t in EN)
    it_h = sum(1 for t in tok if t in IT)
    if n < MIN_TOK:
        return "stub", n, it_h / max(n, 1), en_h / max(n, 1)
    en_r = en_h / n
    it_r = it_h / n
    if en_r < 0.02 and it_r < 0.02:
        return "nd", n, it_r, en_r
    if it_r >= en_r * 2.0 and it_r >= 0.04:
        return "it", n, it_r, en_r
    if en_r >= it_r * 2.0 and en_r >= 0.04:
        return "en", n, it_r, en_r
    # entrambe presenti in misura confrontabile
    if it_r >= 0.03 and en_r >= 0.03:
        return "mixed", n, it_r, en_r
    return "nd", n, it_r, en_r


if __name__ == "__main__":
    import json
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        o = json.loads(line)
        lang, n, it_r, en_r = rileva(o.get("descrizione") or "")
        print(json.dumps({"slug": o["slug"], "lingua": lang, "tok": n,
                          "it_r": round(it_r, 3), "en_r": round(en_r, 3)}))
