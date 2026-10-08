"""Nomi dei generi scelti: generi.nome diventa il nome usato per le cultivar (lotto 11).

Legge out/nomi_generi_scelti.csv e lo stato attuale di `generi`:
- generi con nome_finale: nome = nome_finale (solo se nome è ancora quello attuale);
- tutti gli altri generi con nome <> nome_scientifico: nome = nome_scientifico.
Nei VALUES restano il valore vecchio e il nuovo, così il rollback ripristina esattamente.
"""
import csv
import os
import subprocess
from pathlib import Path

from nomi import sql_str

QUI = Path(__file__).parent
CSV = QUI / "out" / "nomi_generi_scelti.csv"
MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261008125000_generi_nomi_scelti.sql"
ROLLBACK = QUI / "rollback_generi_nomi_scelti.sql"


def legge_generi():
    url = os.environ.get("DATABASE_URL")
    if not url:
        url = [l.split("=", 1)[1].strip().strip('"')
               for l in open(QUI.parent.parent / ".env.local") if l.startswith("DATABASE_URL=")][0]
    r = subprocess.run(["psql", url, "-At", "-F", "\t", "-v", "ON_ERROR_STOP=1", "-c",
                        "select nome_scientifico, nome from generi order by nome_scientifico"],
                       capture_output=True, text=True, check=True)
    return dict(l.split("\t") for l in r.stdout.splitlines())


def calcola(generi, finali):
    """Elenco (genere, vecchio, nuovo) dei cambi; verifica che i nomi finali restino unici."""
    cambi = []
    for sci, nome in generi.items():
        nuovo = finali.get(sci, sci if nome != sci else nome)
        if nuovo != nome:
            cambi.append((sci, nome, nuovo))
    finale = {sci: nuovo for sci, _, nuovo in cambi}
    tutti = [finale.get(sci, nome) for sci, nome in generi.items()]
    doppi = {x for x in tutti if tutti.count(x) > 1}
    assert not doppi, f"nomi di genere duplicati dopo la migration: {sorted(doppi)}"
    return cambi


def main():
    generi = legge_generi()
    finali = {}
    with open(CSV, encoding="utf-8", newline="") as f:
        for r in csv.DictReader(f):
            if r["nome_finale"]:
                assert r["genere"] in generi, r["genere"]
                finali[r["genere"]] = r["nome_finale"]
    cambi = calcola(generi, finali)
    righe = ",\n".join(f"  ({sql_str(s)}, {sql_str(v)}, {sql_str(n)})" for s, v, n in cambi)
    MIGRATION.write_text(
        "-- Nomi dei generi scelti: generi.nome diventa il nome usato per le cultivar (lotto 11).\n"
        "-- Colonne: nome_scientifico, nome vecchio (guardia), nome nuovo. Rollback: scripts/nomi-italiani/rollback_generi_nomi_scelti.sql\n"
        "update generi g set nome = v.nuovo\n"
        "from (values\n" + righe + "\n) as v(nome_scientifico, vecchio, nuovo)\n"
        "where g.nome_scientifico = v.nome_scientifico and g.nome = v.vecchio;\n", encoding="utf-8")
    ROLLBACK.write_text(
        "-- Rollback nomi dei generi scelti. ATTENZIONE: eseguire DOPO rollback_lotto11.sql, che per riconoscere\n"
        "-- le cultivar usa generi.nome (dopo questo rollback i nomi tornano quelli iNaturalist).\n"
        "update generi g set nome = v.vecchio\n"
        "from (values\n" + righe + "\n) as v(nome_scientifico, vecchio, nuovo)\n"
        "where g.nome_scientifico = v.nome_scientifico and g.nome = v.nuovo;\n", encoding="utf-8")
    print(len(cambi), "cambi;", len(finali), "generi con nome scelto")


if __name__ == "__main__":
    main()
