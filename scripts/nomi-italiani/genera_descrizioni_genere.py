"""One-shot: 16 righe "Genere spp." che descrivevano una sola specie.

- descrizione del genere (solo famiglia e caratteri del genere già presenti nel testo vecchio, nessun dato nuovo);
- pianta del Carex ('oshimensis ‘Evergold’') ripuntata alla riga della specie.
Legge il testo vecchio dal database: non si può rieseguire dopo l'applicazione.
"""
import os
import subprocess
from pathlib import Path

from nomi import sql_str

QUI = Path(__file__).parent
MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261011100000_descrizioni_genere.sql"
ROLLBACK = QUI / "rollback_descrizioni_genere.sql"

# slug -> (specie di riferimento, frase sul genere)
GENERI = {
    "anthurium": ("Anthurium andraeanum", "Anthurium è un genere della famiglia delle Araceae, per lo più epifita, a volte rampicante."),
    "aquilegia": ("Aquilegia vulgaris", "Aquilegia è un genere della famiglia delle Ranunculaceae."),
    "carex": ("Carex oshimensis", "Carex è un genere della famiglia delle Cyperaceae, con specie decidue o sempreverdi, cespitose o rizomatose, con fusti a sezione triangolare."),
    "ceropegia": ("Ceropegia woodii", "Ceropegia è un genere della famiglia delle Apocynaceae."),
    "coreopsis": ("Coreopsis grandiflora", "Coreopsis è un genere della famiglia delle Asteraceae."),
    "cuphea": ("Cuphea hyssopifolia", "Cuphea è un genere della famiglia delle Lythraceae, che comprende arbusti, annuali e perenni."),
    "delosperma": ("Delosperma cooperi", "Delosperma è un genere della famiglia delle Aizoaceae."),
    "echinacea": ("Echinacea purpurea", "Echinacea è un genere della famiglia delle Asteraceae."),
    "erica": ("Erica carnea", "Erica è un genere della famiglia delle Ericaceae."),
    "gerbera": ("Gerbera jamesonii", "Gerbera è un genere della famiglia delle Asteraceae."),
    "gloriosa": ("Gloriosa superba", "Gloriosa è un genere di perenni rampicanti a radice tuberosa, con foglie munite di viticcio all'apice e vistosi fiori simili a gigli."),
    "plumbago": ("Plumbago auriculata", "Plumbago è un genere della famiglia delle Plumbaginaceae."),
    "sansevieria": ("Sansevieria trifasciata", "Sansevieria è un genere della famiglia delle Asparagaceae."),
    "saponaria": ("Saponaria ocymoides", "Saponaria è un genere di specie annuali o perenni, con foglie opposte e intere e piccoli gruppi di fiori rosa o violacei che sbocciano in estate."),
    "tradescantia": ("Tradescantia zebrina", "Tradescantia è un genere della famiglia delle Commelinaceae."),
    "zinnia": ("Zinnia elegans", "Zinnia è un genere della famiglia delle Asteraceae."),
}
CODA = " Questa scheda vale per le piante del genere quando la specie non è nota; per una specie precisa c'è la sua scheda, ad esempio {sp}."
PIANTA_CAREX = ("carex-1777371678589", "carex", "carex-oshimensis")


def psql(q):
    url = os.environ.get("DATABASE_URL") or [l.split("=", 1)[1].strip().strip('"')
        for l in open(QUI.parent.parent / ".env.local") if l.startswith("DATABASE_URL=")][0]
    return subprocess.run(["psql", url, "-At", "-F", "\x1f", "-R", "\x1e", "-c", q], capture_output=True, text=True,
                          check=True).stdout


def main():
    slugs = ",".join(sql_str(s) for s in GENERI)
    righe = [r.split("\x1f") for r in psql(
        f"select slug, nome_scientifico, descrizione from specie where slug in ({slugs})").split("\x1e") if r.strip()]
    vecchi = {r[0]: r[2].rstrip("\n") for r in righe}
    assert len(vecchi) == len(GENERI) and all(r[1].endswith(" spp.") for r in righe)
    assert psql("select count(*) from specie where slug='carex-oshimensis'").strip() == "1"

    v_nuovi, v_vecchi = [], []
    for slug, (sp, frase) in GENERI.items():
        nuovo = frase + CODA.format(sp=sp)
        v_nuovi.append(f"({sql_str(slug)}, {sql_str(vecchi[slug])}, {sql_str(nuovo)})")
        v_vecchi.append(f"({sql_str(slug)}, {sql_str(nuovo)}, {sql_str(vecchi[slug])})")
    pid, da, a = PIANTA_CAREX

    MIGRATION.write_text(
        "-- 16 righe 'Genere spp.' descrivevano una sola specie: la descrizione passa al genere (la specie ha già la sua riga).\n"
        "-- La pianta Carex oshimensis 'Evergold' passa alla riga della specie. Si applica solo se il testo è ancora quello di prima.\n"
        "-- Rollback: scripts/nomi-italiani/rollback_descrizioni_genere.sql\n"
        "with v(slug, vecchio, nuovo) as (values\n  " + ",\n  ".join(v_nuovi) + "\n)\n"
        "update specie s set descrizione = v.nuovo from v where s.slug = v.slug and s.descrizione = v.vecchio;\n\n"
        f"update piante set specie = {sql_str(a)} where id = {sql_str(pid)} and specie = {sql_str(da)};\n",
        encoding="utf-8")
    ROLLBACK.write_text(
        "-- Rollback descrizioni genere: ripristina le descrizioni di specie e la pianta del Carex.\n"
        f"update piante set specie = {sql_str(da)} where id = {sql_str(pid)} and specie = {sql_str(a)};\n\n"
        "with v(slug, nuovo, vecchio) as (values\n  " + ",\n  ".join(v_vecchi) + "\n)\n"
        "update specie s set descrizione = v.vecchio from v where s.slug = v.slug and s.descrizione = v.nuovo;\n",
        encoding="utf-8")
    print(len(GENERI), "descrizioni;", MIGRATION.name)


if __name__ == "__main__":
    main()
