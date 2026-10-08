"""Migration: righe di genere con decisione 'spp' -> 'Genere spp.'; riga-specie nuova se la riga descrive una specie binomiale."""
import csv

from genera_lotto3 import QUI, OUT
from generi_logica import slug_di
from nomi import sql_str

MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261008120000_righe_genere_spp.sql"
ROLLBACK = QUI / "rollback_righe_genere.sql"
# Righe-specie già presenti prima della migration (l'insert le salta con 'not exists'): il rollback non deve cancellarle.
GIA_ESISTENTI = {"aquilegia-vulgaris", "echinacea-purpurea", "gloriosa-superba", "sansevieria-trifasciata", "saponaria-ocymoides"}


def main():
    righe = [r for r in csv.DictReader(open(OUT / "righe_genere_da_rivedere.csv", encoding="utf-8"))
             if r["decisione"] == "spp"]
    # riga-specie nuova solo se la riga descrive una specie e il nome è binomiale (non solo genere)
    nuove = [r for r in righe if r["descrive_specie"] == "sì" and " " in r["nome_scientifico"].strip()]
    val = lambda rs, f: ",\n  ".join(f(r) for r in rs)
    sql = ["-- Righe 'Genere spp.' e righe-specie nuove (copia dei campi della riga di genere).",
           "-- Rollback: scripts/nomi-italiani/rollback_righe_genere.sql"]
    if nuove:
        sql.append(
            "insert into specie (nome, slug, nome_scientifico, famiglia_botanica, descrizione, esigenze, alert, manutenzione,\n"
            "  ciclo_colturale, vaso, fonti, stato_verifica, verificata_il, verificata_da, ciclo_vitale, immagine,\n"
            "  descrizione_originale, lingua_descrizione, genere_id)\n"
            "select v.nome_scientifico, v.slug_nuovo, g.nome_scientifico, g.famiglia_botanica, g.descrizione, g.esigenze, g.alert,\n"
            "  g.manutenzione, g.ciclo_colturale, g.vaso, g.fonti, g.stato_verifica, g.verificata_il, g.verificata_da,\n"
            "  g.ciclo_vitale, g.immagine, g.descrizione_originale, g.lingua_descrizione, g.genere_id\n"
            "from (values\n  " + val(nuove, lambda r: f"({sql_str(r['slug'])}, {sql_str(r['nome_scientifico'])}, {sql_str(slug_di(r['nome_scientifico']))})")
            + "\n) as v(slug, nome_scientifico, slug_nuovo)\n"
            "join specie g on g.slug = v.slug and g.nome_scientifico = v.nome_scientifico and g.specie_padre_id is null\n"
            "where not exists (select 1 from specie o where o.slug = v.slug_nuovo or o.nome = v.nome_scientifico);\n")
    sql.append(
        "update specie s set nome_scientifico = v.genere || ' spp.'\n"
        "from (values\n  " + val(righe, lambda r: f"({sql_str(r['slug'])}, {sql_str(r['nome_scientifico'])}, {sql_str(r['genere'])})")
        + "\n) as v(slug, vecchio, genere)\n"
        "where s.slug = v.slug and s.nome_scientifico = v.vecchio and s.specie_padre_id is null;\n")
    MIGRATION.write_text("\n".join(sql), encoding="utf-8")
    rb = ["-- Rollback righe genere: ripristina il nome scientifico e toglie le righe-specie create (solo se senza piante né cultivar)."]
    rb.append(
        "update specie s set nome_scientifico = v.vecchio\n"
        "from (values\n  " + val(righe, lambda r: f"({sql_str(r['slug'])}, {sql_str(r['nome_scientifico'])}, {sql_str(r['genere'])})")
        + "\n) as v(slug, vecchio, genere)\n"
        "where s.slug = v.slug and s.nome_scientifico = v.genere || ' spp.' and s.specie_padre_id is null;\n")
    create = [r for r in nuove if slug_di(r["nome_scientifico"]) not in GIA_ESISTENTI]
    if create:
        rb.append(
            "delete from specie s using (values\n  " + val(create, lambda r: f"({sql_str(slug_di(r['nome_scientifico']))})")
            + "\n) as v(slug) where s.slug = v.slug\n"
            "  and not exists (select 1 from piante p where p.specie = s.slug)\n"
            "  and not exists (select 1 from specie c where c.specie_padre_id = s.id);\n")
    ROLLBACK.write_text("\n".join(rb), encoding="utf-8")
    print(len(righe), "righe spp,", len(nuove), "righe-specie nuove")


if __name__ == "__main__":
    main()
