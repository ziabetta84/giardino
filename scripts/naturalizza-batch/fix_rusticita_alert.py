#!/usr/bin/env python3
"""Ripara il bug: l'alert 'Rusticità RHS: ...' era stato tradotto in temperatura
testuale durante la naturalizzazione, invece di restare col codice H grezzo (regola
8c: quella voce va restituita ESATTAMENTE come nell'originale). Ricostruisce il
codice H a partire dalla temperatura tramite la tabella ufficiale RHS (mapping
deterministico, gli intervalli non si sovrappongono)."""
import json
import re
from pathlib import Path

# Ordine dal più specifico/stretto, per evitare match parziali errati.
RANGE_TO_CODE = [
    (re.compile(r"sotto\s*(?:i\s*)?-?20\s*°?c|<\s*-20\s*°?c", re.I), "H7"),
    (re.compile(r"-20\s*(?:°c)?\s*(?:a|/|,)\s*-15\s*°?c", re.I), "H6"),
    (re.compile(r"-15\s*(?:°c)?\s*(?:a|/|,)\s*-10\s*°?c", re.I), "H5"),
    (re.compile(r"-10\s*(?:°c)?\s*(?:a|/|,)\s*-5\s*°?c", re.I), "H4"),
    (re.compile(r"-5\s*(?:°c)?\s*(?:a|/|,)\s*1\s*°?c", re.I), "H3"),
    (re.compile(r"\b1\s*-\s*5\s*°?c|1\s*(?:°c)?\s*a\s*5\s*°?c", re.I), "H2"),
    (re.compile(r"\b10\s*-\s*15\s*°?c|10\s*(?:°c)?\s*a\s*15\s*°?c", re.I), "H1B"),
    (re.compile(r"\b5\s*-\s*10\s*°?c|5\s*(?:°c)?\s*a\s*10\s*°?c", re.I), "H1C"),
    (re.compile(r"oltre\s*15\s*°?c|>\s*15\s*°?c", re.I), "H1A"),
]


def codes_from_text(text: str):
    found = []
    for pattern, code in RANGE_TO_CODE:
        if pattern.search(text) and code not in found:
            found.append(code)
    # Ordine canonico H1A..H7
    order = ["H1A", "H1B", "H1C", "H2", "H3", "H4", "H5", "H6", "H7"]
    return [c for c in order if c in found]


def fix_voce(voce: str):
    if not (voce.lower().startswith("rusticità") and "°c" in voce.lower()):
        return None
    if re.search(r"H[1-7][a-c]?", voce, re.I):
        return None  # ha gia' un codice da qualche parte, non e' il bug
    codes = codes_from_text(voce)
    if not codes:
        return "AMBIGUO"
    return f"Rusticità RHS: {', '.join(codes)} (scala UK, vedi H1-H7 nella documentazione RHS)"


def main():
    rows = json.loads(Path("rusticita_bug_148.json").read_text())
    fixed = []
    ambigui = []
    for row in rows:
        alert = row["alert"]
        new_alert = list(alert)
        changed = False
        for i, voce in enumerate(alert):
            fix = fix_voce(voce)
            if fix == "AMBIGUO":
                ambigui.append({"id": row["id"], "slug": row["slug"], "voce": voce})
                changed = None
                break
            if fix:
                new_alert[i] = fix
                changed = True
        if changed:
            fixed.append({"id": row["id"], "slug": row["slug"], "alert": new_alert})
    print(f"Risolte automaticamente: {len(fixed)}")
    print(f"Ambigue (da rivedere a mano): {len(ambigui)}")
    for a in ambigui:
        print(" -", a["slug"], "|", a["voce"])
    Path("rusticita_fixed.json").write_text(json.dumps(fixed, ensure_ascii=False, indent=1))
    Path("rusticita_ambigue.json").write_text(json.dumps(ambigui, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
