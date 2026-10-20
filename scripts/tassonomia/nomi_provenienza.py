#!/usr/bin/env python3
"""Fase 4c: ricostruisce le fonti di ogni nome italiano attuale delle righe madri di `specie`, dalle migration dei lotti
1-13 (specifica, "Decisioni per la fase 4", punto 23). Stesso metodo della ricerca (ricerca_fase4/nc_provenienza.py).

Legge le migration (in git), i file di scripts/nomi-italiani/out (fuori da git, sul Mac) e dati, e due file esportati
dalla copia locale: MADRI (id, slug, nome, nome scientifico, nomi alternativi, stato di verifica, fonti) e NOMI_SCIENTIFICI
(nomi di taxa, specie e generi in minuscolo, uno per riga). Scrive su stdout: slug, ruolo (principale/alternativo), nome,
fonti, note, stato di verifica, nome scientifico, tipo, id.
Uso: python3 scripts/tassonomia/nomi_provenienza.py MADRI NOMI_SCIENTIFICI > provenienza.tsv   (dalla radice del repository)

Metodo: per ogni lotto si leggono le tuple VALUES della migration e si registra quale fonte ha prodotto quale nome
per quale riga; poi ogni nome presente oggi (specie.nome se diverso da nome_scientifico, e ogni elemento di
nomi_alternativi) prende l'unione delle fonti che lo spiegano (confronto senza maiuscole e spazi in eccesso).
"""
import csv, json, re, sys, collections

def eprint(*a):
    print(*a, file=sys.stderr)
from pathlib import Path

REPO = Path.cwd()
MIG = REPO / "supabase" / "migrations"
NI = REPO / "scripts" / "nomi-italiani"
MADRI, NOMI_SCIENTIFICI = sys.argv[1], sys.argv[2]

def k(s):
    return re.sub(r"\s+", " ", (s or "").strip()).lower()

LIT = re.compile(r"'((?:[^']|'')*)'|(null)", re.I)

def tuple_valori(path, prefisso="  ("):
    """Tuple VALUES di una migration: righe che iniziano con '  (' ; letterali SQL con '' come apice."""
    out = []
    for riga in path.read_text(encoding="utf-8").splitlines():
        if not riga.startswith(prefisso):
            continue
        campi = [(m.group(1).replace("''", "'") if m.group(1) is not None else None) for m in LIT.finditer(riga)]
        out.append(campi)
    return out

def elenco_slug(path):
    """Slug elencati uno per riga nella forma "    'slug'," (liste IN delle migration delle cultivar)."""
    return [m.group(1) for m in re.finditer(r"^    '([^']+)',?$", path.read_text(encoding="utf-8"), re.M)]

fonti = collections.defaultdict(lambda: collections.defaultdict(set))  # slug -> nome_k -> {fonti}
note = collections.defaultdict(lambda: collections.defaultdict(list))

def add(slug, nome, fonte, nota=None):
    if not nome:
        return
    fonti[slug][k(nome)].add(fonte)
    if nota:
        note[slug][k(nome)].append(nota)

# lotto 1: Wikidata P1843
for slug, nome in tuple_valori(MIG / "20261004120000_nomi_italiani_lotto1.sql"):
    add(slug, nome, "wikidata", "lotto1")
# lotto 2: PlantNet (nome principale)
lotto2 = {}
for slug, nome in tuple_valori(MIG / "20261004130000_nomi_italiani_lotto2.sql"):
    add(slug, nome, "plantnet", "lotto2")
    lotto2[slug] = nome
# nomi_alternativi: PlantNet per nome scientifico
plantnet_alt = collections.defaultdict(set)
for sci, alt in tuple_valori(MIG / "20261004150000_specie_nomi_alternativi_dati.sql"):
    for x in alt.split(" | "):
        plantnet_alt[k(sci)].add(k(x))
# lotto 3: nome iNaturalist confermato da PlantNet
for slug, nome, _av, _an in tuple_valori(MIG / "20261006120000_nomi_italiani_lotto3.sql"):
    add(slug, nome, "inaturalist", "lotto3")
    add(slug, nome, "plantnet", "lotto3")
# lotto 3b: iNaturalist da solo
for slug, nome in tuple_valori(MIG / "20261006130000_nomi_italiani_lotto3b.sql"):
    add(slug, nome, "inaturalist", "lotto3b")
# lotto 4
lotto4_vecchi = {}
for t in tuple_valori(MIG / "20261006140000_nomi_italiani_lotto4.sql"):
    if len(t) == 5:
        slug, vecchio, av, nome, an = t
        add(slug, nome, "inaturalist", "lotto4 sostituito")
        lotto4_vecchi[slug] = vecchio
    elif len(t) == 3:
        slug, av, an = t
        vecchi = {k(x) for x in av.split(" | ")} if av else set()
        for x in an.split(" | "):
            if k(x) not in vecchi:
                add(slug, x, "inaturalist", "lotto4 aggiunto")
# lotto 8: 5 nomi iNaturalist diversi; il vecchio (PlantNet) resta alternativo
for slug, vecchio, nuovo, av, an in tuple_valori(MIG / "20261006180000_nomi_italiani_lotto8.sql"):
    add(slug, nuovo, "inaturalist", "lotto8 sostituito")
    add(slug, vecchio, "plantnet", "lotto8 vecchio")
l8 = set(elenco_slug(MIG / "20261006180000_nomi_italiani_lotto8.sql"))
l9 = set(elenco_slug(MIG / "20261006190000_nomi_italiani_lotto9.sql"))
l10 = set(elenco_slug(MIG / "20261006200000_nomi_italiani_lotto10.sql"))
l12 = set(elenco_slug(MIG / "20261011110000_nomi_italiani_lotto12.sql"))
l12_nuovi = {}
for slug, vecchio, nuovo in tuple_valori(MIG / "20261011110000_nomi_italiani_lotto12.sql"):
    add(slug, nuovo, "curatore", "lotto12 rinominato dall'utente")
    l12_nuovi[slug] = nuovo
# iNaturalist sulle 438 madri del lotto 2 (out/inat_lotto2.jsonl) e gruppo B (out/inat_gruppoB.json)
inat_l2 = {}
p = NI / "out" / "inat_lotto2.jsonl"
if p.exists():
    for r in map(json.loads, open(p, encoding="utf-8")):
        if r.get("nome_it"):
            add(r["slug"], r["nome_it"], "inaturalist", "inat_lotto2")
        inat_l2[r["slug"]] = r
p = NI / "out" / "inat_gruppoB.json"
if p.exists():
    for r in json.load(open(p, encoding="utf-8")):
        if r.get("nome_it"):
            add(r["slug"], r["nome_it"], "inaturalist", "inat_gruppoB")
# EPPO (out/eppo_lotto2.jsonl): tutti i nomi italiani trovati per le 278 madri
p = NI / "out" / "eppo_lotto2.jsonl"
if p.exists():
    for r in map(json.loads, open(p, encoding="utf-8")):
        for n in r.get("nomi_it") or []:
            add(r["slug"], n, "eppo", "eppo_lotto2")
# righe di genere: Elleboro (generi_risolti) e Edera (hedera): nome iNaturalist del genere approvato dall'utente
add("helleborus", "Elleboro", "inaturalist", "nome del genere (inat_generi)")
add("helleborus", "Elleboro", "curatore", "generi_risolti: Elleboro nero -> Elleboro")
add("hedera", "Edera", "inaturalist", "nome del genere (inat_generi)")
add("hedera", "Edera", "curatore", "hedera_e_cultivar_residue")

# vecchi nomi scientifici delle righe di genere (prima di "Genere spp."): servono ad abbinare i nomi PlantNet
vecchio_sci = {}
for f in ["20261008120000_righe_genere_spp.sql", "20261011130000_generi_risolti_gbif.sql"]:
    for t in tuple_valori(MIG / f):
        if len(t) == 3 and t[0] and re.fullmatch(r"[a-z0-9-]+", t[0]) and t[1] and t[2] and not t[1].isdigit():
            vecchio_sci[t[0]] = t[1]
SCI = {l.rstrip("\n") for l in open(NOMI_SCIENTIFICI, encoding="utf-8")}

righe = []
for r in csv.reader(open(MADRI, encoding="utf-8", newline=""), delimiter="\t"):
    id_, slug, nome, sci, alt, stato, fonti_riga = r
    righe.append(dict(id=id_, slug=slug, nome=nome, sci=sci, alt=alt, stato=stato, fonti_riga=fonti_riga))

out = []
for r in righe:
    slug = r["slug"]
    sci_k = k(r["sci"]); sci_k2 = re.sub(r" spp?\.$", "", sci_k)
    sci_k3 = k(vecchio_sci.get(slug, ""))
    nomi = []
    if k(r["nome"]) != k(r["sci"]):
        nomi.append(("principale", r["nome"]))
    for x in (r["alt"].split(" | ") if r["alt"] else []):
        nomi.append(("alternativo", x))
    for ruolo, nome in nomi:
        f = set(fonti[slug].get(k(nome), set()))
        nt = list(note[slug].get(k(nome), []))
        if k(nome) in plantnet_alt.get(sci_k, set()) or k(nome) in plantnet_alt.get(sci_k2, set()) or (sci_k3 and k(nome) in plantnet_alt.get(sci_k3, set())):
            f.add("plantnet"); nt.append("plantnet_alt")
        if ruolo == "principale":
            if slug in l8 and slug not in {"daphne-sericea", "euonymus-japonicus", "fragaria-moschata", "linum-grandiflorum", "panicum-virgatum"}:
                f.add("inaturalist"); nt.append("lotto8 confermato")
            if slug in l9:
                f.add("gbif"); nt.append("lotto9 confermato GBIF")
            if slug in l10:
                f.add("eppo"); nt.append("lotto10 confermato EPPO")
            if slug in l12 and slug not in l12_nuovi:
                f.add("curatore"); nt.append("lotto12 approvato dall'utente")
        LOTTI_NOME = ("lotto1", "lotto2", "lotto3", "lotto3b", "lotto4 sostituito", "lotto8 sostituito", "lotto12 rinominato dall'utente",
                      "generi_risolti: Elleboro nero -> Elleboro", "hedera_e_cultivar_residue")
        if ruolo == "principale" and not any(n in LOTTI_NOME for n in nt):
            f.add("catalogo"); nt.append("nome principale non impostato da nessun lotto: catalogo iniziale")
        if not f:
            f.add("catalogo"); nt.append("alternativo non spiegato da nessun lotto: vecchio nome del catalogo (lotto 4)")
        kn = k(nome)
        if kn in {sci_k, sci_k2, sci_k3}:
            tipo = "scientifico_della_riga"
        elif kn == sci_k2.split(" ")[0] and " " in sci_k2:
            tipo = "genere_della_riga"
        elif " " in kn and kn in SCI:
            tipo = "binomio_scientifico_altro"
        elif kn in SCI:
            tipo = "parola_uguale_a_nome_scientifico"
        else:
            tipo = "comune"
        out.append((slug, ruolo, nome, ",".join(sorted(f)), ";".join(nt), r["stato"], r["sci"], tipo, r["id"]))

w = csv.writer(sys.stdout, delimiter="\t", lineterminator="\n")
w.writerow(["slug", "ruolo", "nome", "fonti", "note", "stato_verifica", "nome_scientifico", "tipo", "id"])
w.writerows(out)

c = collections.Counter()
for slug, ruolo, nome, f, nt, st, sci, tipo, _id in out:
    c[(ruolo, f)] += 1
for (ruolo, f), n in sorted(c.items(), key=lambda x: (x[0][0], -x[1])):
    eprint(f"{ruolo}\t{f}\t{n}")
eprint("totale", len(out))
per_fonte = collections.Counter()
eprint("--- per tipo")
for (ruolo, tipo), n in sorted(collections.Counter((o[1], o[7]) for o in out).items()):
    eprint(f"{ruolo}\t{tipo}\t{n}")
for slug, ruolo, nome, f, nt, st, sci, tipo, _id in out:
    if tipo != "comune":
        continue
    for x in f.split(","):
        per_fonte[(ruolo, x)] += 1
eprint("--- per fonte, solo tipo comune (un nome con piu' fonti conta per ciascuna)")
for (ruolo, x), n in sorted(per_fonte.items()):
    eprint(f"{ruolo}\t{x}\t{n}")
