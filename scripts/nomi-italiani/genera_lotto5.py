"""Lotto 5: nomi scientifici finiti per errore in `nomi_alternativi`.

Se un elemento di `nomi_alternativi` è un sinonimo botanico della stessa specie secondo GBIF (out/gbif.jsonl,
sinonimi + nome accettato), esce da `nomi_alternativi` e va in `sinonimi_botanici` (se non c'è già e non è il
nome scientifico stesso). Gli elementi che solo sembrano binomi ma non risultano in GBIF non si toccano.
"""
import json
import os
import subprocess

from genera_lotto3 import QUI, OUT, SEP, n
from nomi import sql_str

MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261006150000_nomi_alternativi_scientifici.sql"
ROLLBACK = QUI / "rollback_lotto5.sql"


def sposta(alt, sinonimi, sci, gbif):
    """(alt_nuovi, sinonimi_nuovi) o None se non c'è nulla da spostare. Funzione pura, testata."""
    gb = {n(x) for x in gbif}
    elenco = [a for a in alt.split(SEP) if a]
    mossi = [a for a in elenco if n(a) in gb]
    if not mossi:
        return None
    restanti = [a for a in elenco if n(a) not in gb]
    sin = [s for s in (sinonimi or "").split(SEP) if s]
    for m in mossi:
        if n(m) != n(sci) and n(m) not in [n(s) for s in sin]:
            sin.append(m)
    return (SEP.join(restanti) or None), (SEP.join(sin) or None)


def carica_db():
    url = os.environ.get("DATABASE_URL") or [l.split("=", 1)[1].strip().strip('"')
        for l in open(QUI.parent.parent / ".env.local") if l.startswith("DATABASE_URL=")][0]
    q = ("select slug, nome_scientifico, nomi_alternativi, coalesce(sinonimi_botanici,'') from specie "
         "where specie_padre_id is null and nomi_alternativi is not null")
    return [r.split("\t") for r in subprocess.run(["psql", url, "-At", "-F", "\t", "-c", q], capture_output=True,
                                                   text=True, check=True).stdout.splitlines()]


def main():
    gbif = {}
    for l in open(OUT / "gbif.jsonl", encoding="utf-8"):
        r = json.loads(l)
        gbif[r["slug"]] = list(r["sinonimi"]) + ([r["accettato"]] if r.get("accettato") else [])
    scelte = []
    for slug, sci, alt, sin in carica_db():
        s = sposta(alt, sin, sci, gbif.get(slug, []))
        if s:
            scelte.append((slug, alt, sin, s[0], s[1]))
    nul = lambda x: sql_str(x) if x else "null"
    v = ",\n  ".join(f"({sql_str(s)}, {sql_str(av)}, {sql_str(sv)}, {nul(an)}, {nul(sn)})" for s, av, sv, an, sn in scelte)
    MIGRATION.write_text(
        f"-- {len(scelte)} specie: sinonimi botanici GBIF finiti in nomi_alternativi passano a sinonimi_botanici.\n"
        "-- Si applica solo se la riga è ancora com'era. Rollback: scripts/nomi-italiani/rollback_lotto5.sql\n"
        "with v(slug, alt_vecchi, sin_vecchi, alt_nuovi, sin_nuovi) as (values\n  " + v + "\n)\n"
        "update specie s set nomi_alternativi = v.alt_nuovi, sinonimi_botanici = v.sin_nuovi from v\n"
        "where s.slug = v.slug and s.specie_padre_id is null and s.nomi_alternativi = v.alt_vecchi\n"
        "  and coalesce(s.sinonimi_botanici,'') = v.sin_vecchi;\n", encoding="utf-8")
    ROLLBACK.write_text(
        "-- Rollback lotto 5: ripristina nomi_alternativi e sinonimi_botanici di prima.\n"
        "with v(slug, alt_vecchi, sin_vecchi, alt_nuovi, sin_nuovi) as (values\n  " + v + "\n)\n"
        "update specie s set nomi_alternativi = v.alt_vecchi, sinonimi_botanici = nullif(v.sin_vecchi,'') from v\n"
        "where s.slug = v.slug and coalesce(s.nomi_alternativi,'') = coalesce(v.alt_nuovi,'');\n", encoding="utf-8")
    print(len(scelte), "specie")


if __name__ == "__main__":
    main()
