#!/usr/bin/env python3
"""Prepara (e con --applica scrive) le traduzioni di un lotto di schede, issue #153.

Legge l'export del lotto (esporta_schede.py) e il file delle traduzioni scritto da chi traduce:

  {"<id scheda>": {"descrizione": "...",                 # facoltativo
                   "alert": {"8": "Parassiti: ...",      # indice nell'array alert -> testo nuovo
                             "11": null},                # null = voce tolta (segnaposto, doppione)
                   "esigenze": {...},                    # facoltativo, sostituisce tutto il jsonb
                   "ciclo_vitale": "perenne"}}           # facoltativo

Le voci di `alert` che non compaiono restano identiche: le voci «Rusticità:» e «Dimensioni a maturità:»
non si possono toccare, così come «Rischi (testo in inglese)» (traduzione rimandata per scelta dell'utente).
Scrive due file SQL accanto al lotto: lottoN_schede_scrittura.sql e lottoN_schede_rollback.sql (il backup del
lotto: rimette i valori di prima). La scrittura si rifiuta, riga per riga, se la scheda è cambiata dopo l'export.

Uso:
  python3 scrivi_schede.py --lotto lotto79_schede.json --traduzioni lotto79_traduzioni.json            # solo controlli e SQL
  python3 scrivi_schede.py --lotto lotto79_schede.json --traduzioni lotto79_traduzioni.json --applica  # e scrive
"""
import argparse
import json
import re
import sys
from pathlib import Path

from common import load_env, run_psql_file

INTOCCABILI = re.compile(r"^(Rusticità:|Dimensioni a maturità:|Rischi \(testo in inglese\))")
CICLI = {"perenne", "annuale", "biennale"}
# Controlli sul testo nuovo: niente fonti, niente etichette inglesi, niente rimandi alle pagine RHS, niente codici H
VIETATI = [
    (re.compile(r"\(testo in inglese\)"), "etichetta «testo in inglese» rimasta"),
    (re.compile(r"\b(RHS|PFAF|Le Georgiche)\b"), "fonte citata"),
    (re.compile(r"\b(la fonte|una fonte|secondo la|la scheda|scheda indica)\b", re.I), "citazione della fonte"),
    (re.compile(r"\b(see|the|with|and|may be|propagate|pruning)\b", re.I), "parole inglesi"),
    (re.compile(r"\bH(1[abcABC]|[2-7])\b"), "codice di rusticità H nudo"),
    (re.compile(r"note di coltivazione|vedi (la pagina|le pagine)", re.I), "rimando a una pagina"),
    (re.compile(r"\bverificat[ao]\b", re.I), "nota editoriale"),
    (re.compile(r"^Specie appartiene"), "«Specie appartiene» senza articolo"),
    (re.compile(r"\bgrupp[oi] (di potatura )?\d+", re.I), "numero del gruppo di potatura (usare frasi_potatura.py)"),
]


def dollar(s: str) -> str:
    tag = "$t$"
    while tag in s:
        tag = tag[:-1] + "x$"
    return f"{tag}{s}{tag}"


def sql_valore(v) -> str:
    if v is None:
        return "null"
    if isinstance(v, list):
        return "array[" + ", ".join(dollar(x) for x in v) + "]::text[]" if v else "'{}'::text[]"
    if isinstance(v, dict):
        return dollar(json.dumps(v, ensure_ascii=False)) + "::jsonb"
    return dollar(str(v))


def controlla_testo(dove: str, testo: str, errori: list):
    for rx, motivo in VIETATI:
        if rx.search(testo):
            errori.append(f"{dove}: {motivo}: {testo[:120]}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--lotto", required=True)
    p.add_argument("--traduzioni", required=True)
    p.add_argument("--applica", action="store_true")
    a = p.parse_args()

    lotto = {r["id"]: r for r in json.loads(Path(a.lotto).read_text())}
    trad = json.loads(Path(a.traduzioni).read_text())
    errori, scritture, rollback = [], [], []

    for sid, t in trad.items():
        r = lotto.get(sid)
        if r is None:
            errori.append(f"{sid}: non è nel lotto")
            continue
        nome = r["nome_scientifico"]
        nome_sql = nome.replace("'", "''")
        nuovo = {}
        if "descrizione" in t:
            if not t["descrizione"]:
                errori.append(f"{nome}: descrizione vuota")
            else:
                controlla_testo(f"{nome} descrizione", t["descrizione"], errori)
                nuovo["descrizione"] = t["descrizione"]
        if "alert" in t:
            vecchi = r["alert"] or []
            cambi = {int(k): v for k, v in t["alert"].items()}
            for i, v in cambi.items():
                if i < 0 or i >= len(vecchi):
                    errori.append(f"{nome}: alert [{i}] non esiste")
                elif INTOCCABILI.match(vecchi[i]):
                    errori.append(f"{nome}: alert [{i}] non si tocca: {vecchi[i][:60]}")
                elif v is not None:
                    controlla_testo(f"{nome} alert [{i}]", v, errori)
            nuovo["alert"] = [cambi.get(i, x) for i, x in enumerate(vecchi) if cambi.get(i, x) is not None]
        if "esigenze" in t:
            nuovo["esigenze"] = t["esigenze"]
        if "ciclo_vitale" in t:
            if t["ciclo_vitale"] not in CICLI:
                errori.append(f"{nome}: ciclo_vitale «{t['ciclo_vitale']}» non ammesso")
            nuovo["ciclo_vitale"] = t["ciclo_vitale"]
        if not nuovo:
            continue
        set_nuovo = ", ".join(f"{k} = {sql_valore(v)}" for k, v in nuovo.items())
        set_vecchio = ", ".join(f"{k} = {sql_valore(r[k])}" for k in nuovo)
        scritture.append(
            f"-- {nome}\n"
            f"update public.schede set {set_nuovo}\n"
            f" where id = '{sid}' and aggiornata_il = '{r['aggiornata_il']}';\n"
            f"get diagnostics n = row_count;\n"
            f"if n <> 1 then raise exception 'scheda % ({nome_sql}) cambiata dopo l''export', '{sid}'; end if;\n")
        rollback.append(f"-- {nome}\nupdate public.schede set {set_vecchio} where id = '{sid}';\n")

    if errori:
        print("Errori, niente SQL:", *errori, sep="\n  ")
        sys.exit(1)

    base = Path(a.lotto).with_suffix("")
    f_scr = base.with_name(base.name + "_scrittura.sql")
    f_rb = base.with_name(base.name + "_rollback.sql")
    f_scr.write_text("do $lotto$\ndeclare n int;\nbegin\n" + "\n".join(scritture) + "end $lotto$;\n")
    f_rb.write_text(f"-- Rimette le {len(rollback)} schede del lotto com'erano prima della scrittura.\n"
                    f"-- psql \"$SUPABASE_DB_URL\" -X -1 -v ON_ERROR_STOP=1 -f {f_rb.name}\n" + "\n".join(rollback))
    print(f"{len(scritture)} schede da scrivere: {f_scr}\nrollback: {f_rb}")
    if a.applica:
        load_env()
        run_psql_file(f_scr)
        print("Scritto.")


if __name__ == "__main__":
    main()
