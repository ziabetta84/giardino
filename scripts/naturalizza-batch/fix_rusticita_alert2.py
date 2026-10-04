#!/usr/bin/env python3
"""Ripara un secondo bug (diverso da fix_rusticita_alert.py) sulla stessa voce
`alert` "Rusticità RHS: ...": qui il codice H c'era ancora, ma durante la
naturalizzazione gli e' stato affiancato un commento esplicativo (temperatura
e/o aggettivo italiano, es. "H5, molto rustica, inverno freddo (da -15 a
-10°C)") invece di restare ESATTAMENTE come nell'originale (regola 8c/5: solo
il codice nudo, forma canonica "Rusticità RHS: H5 (scala UK, vedi H1-H7 nella
documentazione RHS)"). Estrae i codici H effettivamente presenti nella voce e
ricostruisce la forma canonica, senza inventare o perdere codici.
"""
import json
import re
from pathlib import Path

CODE_RE = re.compile(r"\bH([1-7])([abcABC]?)\b")
ORDER = ["H1A", "H1B", "H1C", "H2", "H3", "H4", "H5", "H6", "H7"]


def normalize_code(num: str, letter: str) -> str:
    letter = letter.upper()
    return f"H{num}{letter}"


def codes_in_voce(voce: str):
    found = []
    for m in CODE_RE.finditer(voce):
        code = normalize_code(m.group(1), m.group(2))
        if code not in found:
            found.append(code)
    return [c for c in ORDER if c in found]


def fix_voce(voce: str):
    if not voce.lower().startswith("rusticità rhs:"):
        return None
    canonical = None
    codes = codes_in_voce(voce)
    if codes:
        canonical = f"Rusticità RHS: {', '.join(codes)} (scala UK, vedi H1-H7 nella documentazione RHS)"
    if canonical is None or canonical == voce:
        return None
    return canonical


def main():
    rows = json.loads(Path("scripts/naturalizza-batch/rusticita_bug2_125.json").read_text())
    fixed = []
    invariate = []
    for row in rows:
        alert = row["alert"]
        new_alert = list(alert)
        changed = False
        for i, voce in enumerate(alert):
            fix = fix_voce(voce)
            if fix:
                new_alert[i] = fix
                changed = True
        if changed:
            fixed.append({"id": row["id"], "slug": row["slug"], "alert_vecchio": alert, "alert_nuovo": new_alert})
        else:
            invariate.append(row["slug"])
    print(f"Da correggere: {len(fixed)}")
    print(f"Nessuna modifica necessaria (gia' canoniche): {len(invariate)}")
    for s in invariate:
        print(" -", s)
    Path("scripts/naturalizza-batch/rusticita_bug2_fixed.json").write_text(
        json.dumps(fixed, ensure_ascii=False, indent=1)
    )


if __name__ == "__main__":
    main()
