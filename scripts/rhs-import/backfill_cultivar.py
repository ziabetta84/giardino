"""
Backfill dei cultivar come righe `specie` figlie (specie_padre_id), a
partire dai `cultivar_names` già estratti durante il parsing RHS (Fase 6
e 6b) e finora solo riassunti nel testo di `descrizione` della specie
madre -- vedi discussione issue #153, 2026-08-30.

Un cultivar qui ha *solo il nome*: nessun dato di cura proprio (per quello
serve una pagina RHS specifica per quel singolo cultivar, non solo la sua
menzione nell'elenco della specie madre -- fuori scope di questo giro,
possibile estensione futura). Eredita tutto dalla specie madre via join
applicativa su specie_padre_id, come da design concordato.

Uso:
    python3 backfill_cultivar.py           # solo statistiche
    python3 backfill_cultivar.py --sql     # genera anche il file SQL
"""
import json, os, re, sys, unicodedata
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "sql_cultivar")

FONTE_TPL = "RHS (rhs.org.uk) — cultivar elencata nella pagina di {sp}"


def slugify(name):
    s = name.replace("×", "x")
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s).strip("-").lower()
    return s


def carica_gruppi_validi():
    """Solo i gruppi che hanno davvero ricevuto una riga specie (nuova
    inserita con contenuto specifico, o esistente arricchita) -- i
    solo-genere esclusi in Fase 6/6b non hanno uno specie_id a cui agganciare i figli."""
    gruppi = []

    d1 = json.load(open(os.path.join(HERE, "rhs_sitemaps_full_aggregato.json"), encoding="utf-8"))
    gruppi.extend(d1)  # già filtrato in build_full_aggregate.py a nuova(specifico)+da_arricchire

    d2 = json.load(open(os.path.join(HERE, "rhs_recupero_aggregato.json"), encoding="utf-8"))
    for a in d2:
        if a["stato_match"] == "nuova" and a["ha_contenuto_specifico"]:
            gruppi.append(a)
        elif a["stato_match"] == "da_arricchire":
            gruppi.append(a)  # erano 0 in Fase 6b ma per coerenza futura

    return gruppi


def main():
    genera_sql_flag = "--sql" in sys.argv[1:]

    set_a = os.environ.get("SUPABASE_DB_URL")
    esistenti_path = os.path.join(HERE, "specie_esistenti.tsv")
    by_slug_id = {}
    nomi_esistenti = set()
    slug_esistenti = set()
    with open(esistenti_path, encoding="utf-8") as fh:
        for line in fh:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 4:
                continue
            slug, _, _, nome = parts[0], parts[1], parts[2], parts[3]
            nomi_esistenti.add(nome)
            slug_esistenti.add(slug)
    print(f"Nomi/slug specie esistenti caricati: {len(nomi_esistenti)}")

    gruppi = carica_gruppi_validi()
    print(f"Gruppi genitore validi (con riga specie propria): {len(gruppi)}")

    candidati = []  # (nome_cultivar_completo, slug, specie_padre_slug)
    n_senza_cultivar = 0
    for g in gruppi:
        sp = g["specie_base"]
        slug_padre = g["slug"]
        nomi = g.get("cultivar_names") or []
        if not nomi:
            n_senza_cultivar += 1
            continue
        visti_nel_gruppo = set()
        for c in nomi:
            c = c.strip()
            if not c or c in visti_nel_gruppo:
                continue
            visti_nel_gruppo.add(c)
            nome_completo = f"{sp} '{c}'"
            candidati.append((nome_completo, slugify(nome_completo), slug_padre, sp))

    print(f"Gruppi genitore senza alcun cultivar_names: {n_senza_cultivar}")
    print(f"Candidati cultivar totali (nome, deduplicati nel gruppo): {len(candidati)}")

    # dedup globale su nome e su slug, e scarto collisioni con nomi già in specie
    visti_nome, visti_slug = set(), set()
    tenuti, scartati_dup_nome, scartati_dup_slug, scartati_collisione = [], 0, 0, 0
    for nome_completo, slug, slug_padre, sp in candidati:
        if nome_completo in nomi_esistenti or slug in slug_esistenti:
            scartati_collisione += 1
            continue
        if nome_completo in visti_nome:
            scartati_dup_nome += 1
            continue
        if slug in visti_slug:
            scartati_dup_slug += 1
            continue
        visti_nome.add(nome_completo)
        visti_slug.add(slug)
        tenuti.append((nome_completo, slug, slug_padre, sp))

    print(f"Scartati per collisione con nome specie già esistente: {scartati_collisione}")
    print(f"Scartati per nome duplicato tra gruppi diversi: {scartati_dup_nome}")
    print(f"Scartati per slug duplicato (nome diverso, slug uguale): {scartati_dup_slug}")
    print(f"Cultivar effettivi da inserire: {len(tenuti)}")

    if not genera_sql_flag:
        return

    os.makedirs(OUT_DIR, exist_ok=True)
    for f in os.listdir(OUT_DIR):
        os.remove(os.path.join(OUT_DIR, f))

    # Un'unica INSERT...SELECT multi-riga per blocco (VALUES + JOIN sullo slug
    # padre) invece di uno statement per cultivar: con ~196k righe, uno
    # statement a riga significa altrettanti round-trip di rete verso
    # Supabase -- troppo lento (un file da 4000 singole INSERT è andato in
    # timeout a 2 minuti). Raggruppando in VALUES, ogni file resta un solo
    # round-trip indipendentemente da quante righe contiene.
    RIGHE_PER_FILE = 8000
    for i in range(0, len(tenuti), RIGHE_PER_FILE):
        chunk = tenuti[i:i + RIGHE_PER_FILE]
        path = os.path.join(OUT_DIR, f"cultivar_{i // RIGHE_PER_FILE + 1:03d}.sql")
        righe_values = []
        for nome_completo, slug, slug_padre, sp in chunk:
            fonte = FONTE_TPL.format(sp=sp)
            righe_values.append(f"($t${slug}$t$, $t${nome_completo}$t$, $t${fonte}$t$, $t${slug_padre}$t$)")
        with open(path, "w", encoding="utf-8") as out:
            out.write(
                "insert into specie (slug, nome, nome_scientifico, fonti, stato_verifica, specie_padre_id)\n"
                "select v.slug, v.nome, v.nome, ARRAY[v.fonte], 'bozza', s.id\n"
                "from (values\n  " + ",\n  ".join(righe_values) + "\n"
                ") as v(slug, nome, fonte, slug_padre)\n"
                "join specie s on s.slug = v.slug_padre;\n"
            )
    print(f"\nSQL scritto in {OUT_DIR}/ ({(len(tenuti) + RIGHE_PER_FILE - 1)//RIGHE_PER_FILE} file)")


if __name__ == "__main__":
    main()
