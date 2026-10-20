# Modello tassonomico — fase 4c: nomi comuni e inventario finale — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** caricare in `nomi_comuni` i 18.595 nomi comuni (10.553 italiani, 8.042 inglesi; 2.777 preferiti) ricavati dalla vecchia `specie`, dai nomi dei generi e da Catalogue of Life, con le decisioni dell'utente del 20/10/2026, e chiudere la fase 4 con l'inventario: ogni riga di `specie` ha il suo posto nel modello nuovo.

**Architecture:** tutto si calcola sulla copia locale, che ha le fasi 2-4b con le stesse chiavi del reale.
1. `nomi_provenienza.py` ricostruisce le fonti di ogni nome dalle migration dei lotti (stesso metodo della ricerca).
2. `nomi_proposte.sh` prepara gli ingressi (righe madri, nomi scientifici, nomi italiani di COL) e `nomi_proposte.sql` calcola i nomi definitivi: destinazione, ammissione, fonti unite, preferito, decisioni dell'utente.
3. Si esporta un lotto, che `carica_nomi.sh` carica sul reale; `verifica_fase4c.sql` ricontrolla l'inventario dei nomi e quello di tutta la fase 4.

**Tech Stack:** PostgreSQL 17 (Supabase, progetto `ncuhhsvtjwcolhpdxbkt`, piano gratuito; copia locale con i binari in `/opt/homebrew/opt/postgresql@17/bin/`), bash, Python 3 (solo libreria standard), `unzip`.

**Spec:** `docs/superpowers/specs/2026-10-13-modello-tassonomico-design.md`: sezioni "Modello dati" (`nomi_comuni`), "Permessi", "Regole di presentazione", "Migrazione dei contenuti", "Decisioni sullo spazio" e "Decisioni per la fase 4 (approvate il 16/10/2026)", punti 12 e 20-24. La ricerca è in `~/giardino-dati/col/ricerca_fase4/nomi_comuni.md` (con `nc_base.sql` e `nc_provenienza.py`). Le decisioni dell'utente del 20/10/2026 sono nei tre file `scripts/tassonomia/dati/fase4_nomi_*.tsv` (commit 8d6df03), approvate dalla pagina privata https://claude.ai/artifact/Y9y9RTPGu82Epc1nC43MN4 («approvo tutte»).

## Global Constraints

- **Righe** (specifica, "Migrazione dei contenuti" e decisioni 12, 23, 24):
  - i nomi italiani delle righe madri di `specie`: il nome principale se diverso dal nome scientifico e ogni elemento di `nomi_alternativi` (3.178 e 7.845), con le fonti ricostruite dalle migration;
  - i nomi dei generi scelti dall'utente (`generi.nome`, Calendula compresa), fonte `curatore`;
  - i nomi italiani di Catalogue of Life sui taxon di `taxa`: fonte in più sui nomi uguali, righe non preferite per i nuovi;
  - i nomi inglesi di PFAF degli avvisi «Nome comune (inglese, fonte PFAF): …», lingua `en`, mai preferiti.
- **Esclusi:** i nomi uguali al nome scientifico della riga o della pianta di destinazione (salvo `generi.nome`), i binomi scientifici, «x Genere», e i 913 nomi tolti dall'utente; un nome tolto per una pianta non rientra da COL. I 25 testi da correggere si correggono prima di tutto il resto.
- **Destinazione** (decisione 20): D1 l'accettato del nome trovato in `mappa_specie`, per un autonimo la specie; D2 una riga di specie finita su un genere o più su: lì, mai preferita; D3 una riga «Genere spp.» con un vecchio binomio: alla specie del vecchio nome se è in `taxa` con una sola destinazione, tranne i nomi uguali a `generi.nome`; se il vecchio binomio non è in `taxa`, al genere, mai preferito.
- **Preferito** (decisione 21), al più uno per taxon e lingua: le scelte dell'utente (`dati/fase4_nomi_preferiti.tsv`, anche «nessun preferito»), poi `generi.nome`, poi il nome scelto dall'utente per la riga, poi la riga del nome accettato, poi la riga di un sinonimo, poi il nome trasferito (D3); spareggio: riga verificata, poi più fonti esterne. Mai preferiti i nomi D2, D3 non risolti, di COL (salvo scelta dell'utente) o inglesi. Nessuno spareggio deciso dall'ordine alfabetico.
- **Un nome una volta sola** per taxon e lingua, confrontato senza maiuscole e spazi doppi (decisione 24: resta la nostra grafia); i nomi si scrivono senza spazi ai bordi né doppi.
- **Fonti** (decisione 23): `wikidata`, `plantnet`, `inaturalist`, `eppo`, `gbif`, `curatore`, `catalogo` (nome del catalogo iniziale che nessun lotto ha impostato), `col:<fonte>` (`col:inaturalist`, `col:grin`, `col:flora-helvetica`…), `pfaf`. `fonti` e `nota` sono colonne interne, non leggibili dai client.
- **Nome mostrato delle cultivar** (decisione 22: nome comune preferito della specie o del genere più l'epiteto, ambiguo solo tra linee diverse): è una regola dell'app (fase 6); qui si caricano solo i nomi e i preferiti.
- **Inserimento:** valori definitivi in un solo passaggio, nessun aggiornamento di massa (specifica, "Decisioni sullo spazio", punto 5); l'indice trigram si costruisce dopo il caricamento, i due indici unici restano.
- **Solo questa tabella cambia:** `nomi_comuni`. L'impronta di `specie` resta identica prima e dopo.
- **Spazio:**
  - prima di ogni passo sul reale, somma dei database ≤ 420 MB e WAL ≤ 300 MB: la soglia degli script sale da 400 a 420 solo per questa fase (proposta all'utente il 20/10/2026 e approvata con «approvo tutte»);
  - attesi circa 7 MB in più (misurati sulla copia), cioè circa 404 MB su 500 (oggi 396,7);
  - sopra 450 MB ci si ferma (specifica, "Decisioni sullo spazio", punto 1).
- **Connessione:** sul reale solo `SUPABASE_DB_URL` (porta 5432), mai la 6543; `statement_timeout` di 2 minuti sul pooler, quindi il caricamento lo alza con `set local`.
- **Copia locale e reale:** le prove girano sulla copia locale (`127.0.0.1:55440`), che deve avere `cultivar` e `schede` identiche al reale (impronte del Task 1); sul reale, prima del Task 3, solo letture.
- **Regole di lavoro:**
  - nessuna applicazione al reale senza il via esplicito dell'utente in chat;
  - nessun push senza richiesta;
  - l'URL del database non si stampa mai, nemmeno con `ps`; della connessione si stampa al massimo la porta;
  - se il controllo dei permessi blocca un comando sul reale, lo si dà all'utente da lanciare nel suo terminale.
- **Revisione e ramo:** si lavora su `main`; revisione dei Task 1–2 da parte di un revisore nuovo prima del Task 3 (un solo revisore, scelta dell'utente per il credito), con le note scritte in un file mentre lavora.

## Review Focus

1. **Una decisione dell'utente non applicata** (testo o taxon scritto diversamente nei file): le tre tabelle di decisione segnano ogni riga applicata e `prova_nomi.sql` fallisce se una non lo è (Task 1).
2. **Un nome tolto che rientra da Catalogue of Life**: controllo in `prova_nomi.sql`, provato con una mutazione (Task 1).
3. **Un preferito sbagliato**: due preferiti sullo stesso taxon, un preferito inglese o di COL non scelto dall'utente, un preferito uguale al nome scientifico: controlli in `prova_nomi.sql` e in `verifica_fase4c.sql` (Task 1 e 2).
4. **Nomi di `specie` cambiati tra la copia e il reale**: `verifica_fase4c.sql` riconta sul reale i nomi principali e alternativi delle righe madri e li confronta con l'inventario dei file (Task 2 e 3).
5. **Rollback che cancella nomi aggiunti dopo il caricamento**: prova `rollback` di `prova_fase4c.sh` (Task 2).

## Misure del prototipo (20/10/2026, copia locale con le fasi 2-4b e le decisioni dell'utente)

| Misura | Valore |
|---|---|
| Nomi di partenza | 11.023 nomi delle righe madri (3.178 principali, 7.845 alternativi); 35.572 nomi italiani in COL XR |
| Nomi proposti | 18.595: italiani 10.553 (9.600 dei nostri dati, 953 solo di COL), inglesi 8.042; 7.366 taxon |
| Preferiti | 2.777 su 2.779 taxon con candidati; 7 taxon con più candidati; spareggi alfabetici 0 |
| Decisioni dell'utente | 913 nomi tolti, 25 correzioni, 13 scelte del preferito: tutte applicate |
| WAL | 7,2 MB per il lotto, 0,6 MB per l'indice trigram |
| Spazio | `nomi_comuni` 6,8 MB con gli indici |
| Durata sulla copia | proposte circa 6 s; prove della fase 4c circa 15 s |
| Piante dell'utente | il nome mostrato (fase 6) cambia, rispetto a `specie.nome`, per le righe delle decisioni (Alisso, Arancio Navel, Cactus Ago di Eva, Lucky Bamboo, Mandarino cinese, Mesembriantemo, Orchidea, ZZ Plant), per Peperoncino (scelta del 16/10), Gaura («Enagra di Lindheimer», conferma B), Tradescantia («Tradescanzia», `generi.nome`) e Sansevieria («Dracena», genere accettato come la sua scheda); nella fase 5 ogni pianta si ricontrolla con l'utente |

## File

- Create: `scripts/tassonomia/nomi_provenienza.py` — fonti di ogni nome dalle migration dei lotti.
- Create: `scripts/tassonomia/nomi_proposte.sh`, `nomi_proposte.sql`, `prova_nomi.sql` — i nomi proposti sulla copia.
- Create: `scripts/tassonomia/nomi_esporta.sh`, `carica_nomi.sh`, `verifica_fase4c.sql`, `rollback_fase4c.sql`, `prova_fase4c.sh`.
- Consumes (già nel repository): `scripts/tassonomia/dati/fase4_nomi_esclusi.tsv`, `fase4_nomi_corretti.tsv`, `fase4_nomi_preferiti.tsv`; `scripts/nomi-italiani/dati/righe_genere_da_rivedere.csv`; le migration dei lotti in `supabase/migrations/`.
- Consumes (fuori da git, sul Mac): `scripts/nomi-italiani/out/` (`inat_lotto2.jsonl`, `inat_gruppoB.json`, `eppo_lotto2.jsonl`), `~/giardino-dati/col/xr_latest_coldp.zip`.
- Modify: `CLAUDE.md` (Task 3).

Tutti i comandi si lanciano dalla radice del repository. In ogni shell nuova vanno impostate queste variabili:
- `PG=/opt/homebrew/opt/postgresql@17/bin`;
- `SCRATCH` = la cartella temporanea della sessione (scratchpad);
- `COLDIR=$HOME/giardino-dati/col`;
- `F4=$COLDIR/fase4`;
- `COPIA=postgresql://postgres@127.0.0.1:55440/giardino`;
- `SUPABASE_DB_URL` da `.env.local`;
- `BK` dal Task 3.

---

### Task 1: Nomi proposti sulla copia locale

**Files:**
- Create: `scripts/tassonomia/nomi_provenienza.py`
- Create: `scripts/tassonomia/prova_nomi.sql`
- Create: `scripts/tassonomia/nomi_proposte.sh`
- Create: `scripts/tassonomia/nomi_proposte.sql`

**Interfaces:**
- Consumes: la copia locale con lo schema `col` e le fasi 2-4b; i tre file `dati/fase4_nomi_*.tsv`.
- Produces:
  - `nomi_provenienza.py MADRI NOMI_SCIENTIFICI` → TSV su stdout (slug, ruolo, nome, fonti, note, stato_verifica, nome_scientifico, tipo, id);
  - `nomi_proposte.sh URL_COPIA CARTELLA` → `col.nomi_provenienza`, `col.nomi_col_ita`, e da `nomi_proposte.sql` `col.nomi_proposte` (le colonne di `public.nomi_comuni` `id`, `taxon_id`, `lingua`, `nome`, `preferito`, `fonti`, `nota`, più `k`, `origine` = `nostri`/`col`/`pfaf`), `col.nomi_candidati`, `col.nomi_esclusi`, `col.nomi_corretti`, `col.nomi_scelte` (con la colonna `applicata`), `col.nomi_righe_genere`;
  - le funzioni `col.pulisci_nome(text)` e `col.chiave_nome(text)`.

- [ ] **Step 1: Copia locale pronta**

La copia è quella della 4b, accesa su 55440; le sue chiavi devono essere identiche al reale.

```bash
Q="select count(*) || ' ' || md5(string_agg(id::text || '|' || slug || '|' || taxon_id::text || '|' || categoria || '|' || epiteto || '|' || coalesce(gruppo, '') || '|' || coalesce(nome_commerciale, '') || '|' || coalesce(grex_id::text, ''), ',' order by id)) from public.cultivar"
Q3="select count(*) || ' ' || md5(string_agg(id::text || '|' || coalesce(taxon_id::text, '') || '|' || coalesce(cultivar_id::text, '') || '|' || mostrata::text, ',' order by id)) from public.schede"
$PG/psql "$COPIA" -X -qAt -c "$Q" -c "$Q3"
set -a; source .env.local; set +a
$PG/psql "$SUPABASE_DB_URL" -X -qAt -c "$Q" -c "$Q3" -c "select 'nomi_comuni ' || count(*) from public.nomi_comuni"
```

Expected: `196303 7294967f2fd4e835c21d92073ba264f1` e `15770 08de8773c09d1496b8cc704c98fb7356` uguali sulla copia e sul reale, `nomi_comuni 0` sul reale. Se le impronte sono diverse, fermarsi: la copia non è più quella del reale.

Poi si tolgono dalla copia le tabelle e le funzioni lasciate dal prototipo e i nomi che il prototipo vi ha caricato, perché le prove devono partire da zero:

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 \
  -c 'drop table if exists col.nomi_proposte, col.nomi_esclusi, col.nomi_corretti, col.nomi_scelte, col.nomi_righe_genere, col.nomi_candidati, col.nomi_provenienza, col.nomi_col_ita, col.nomi_segnalati, col.nomi_piante' \
  -c 'drop function if exists col.pulisci_nome(text), col.chiave_nome(text)' \
  -c 'delete from public.nomi_comuni' -c 'vacuum full public.nomi_comuni' \
  -c "select 'nomi_comuni ' || count(*) from public.nomi_comuni"
```

Expected: `nomi_comuni 0`.

- [ ] **Step 2: Scrivere la ricostruzione delle fonti e confrontarla con la ricerca**

`scripts/tassonomia/nomi_provenienza.py`:

```python
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
```

Con gli stessi ingressi della ricerca deve dare la stessa uscita, byte per byte:

```bash
chmod +x scripts/tassonomia/nomi_provenienza.py
R=$COLDIR/ricerca_fase4
python3 scripts/tassonomia/nomi_provenienza.py $R/nc_madri.tsv $R/nc_nomi_scientifici.txt 2>/dev/null | cmp - $R/nc_provenienza.tsv && echo "IDENTICO ALLA RICERCA"
```

Expected: `IDENTICO ALLA RICERCA`.

- [ ] **Step 3: Scrivere le prove dei nomi proposti**

`scripts/tassonomia/prova_nomi.sql`:

```sql
-- Prove dei nomi comuni proposti della fase 4c (nomi_proposte.sql), sulla copia locale. Errore al primo controllo che
-- fallisce. Numeri e casi valgono per specie del 16/10/2026, COL26.9 XR, le fasi 2-4b applicate e le decisioni
-- dell'utente del 20/10/2026 (dati/fase4_nomi_esclusi.tsv, fase4_nomi_corretti.tsv, fase4_nomi_preferiti.tsv).
do $$
declare
  n bigint;
  c record;
begin
  -- righe per lingua e origine, preferiti
  for c in select * from (values
      ('tutte', (select count(*) from col.nomi_proposte), 18595::bigint),
      ('italiane dei nostri dati', (select count(*) from col.nomi_proposte where lingua = 'it' and origine = 'nostri'), 9600),
      ('italiane solo di COL', (select count(*) from col.nomi_proposte where lingua = 'it' and origine = 'col'), 953),
      ('inglesi', (select count(*) from col.nomi_proposte where lingua = 'en'), 8042),
      ('preferiti', (select count(*) from col.nomi_proposte where preferito), 2777)
    ) v(voce, trovate, attese) loop
    if c.trovate <> c.attese then raise exception 'nomi proposti, %: % invece di %', c.voce, c.trovate, c.attese; end if;
  end loop;
  -- le decisioni dell'utente sono tutte applicate
  select (select count(*) from col.nomi_esclusi where not applicata) + (select count(*) from col.nomi_corretti where not applicata)
       + (select count(*) from col.nomi_scelte where not applicata) into n;
  if n > 0 then raise exception 'decisioni dell''utente non applicate (testo o taxon non trovato): %', n; end if;
  select count(*) into n from col.nomi_esclusi;
  if n <> 913 then raise exception 'esclusioni: % invece di 913', n; end if;
  -- un nome tolto non c'è più su quella pianta, nemmeno da COL
  select count(*) into n from col.nomi_esclusi e
    join col.nomi_provenienza v on v.slug = e.vecchio_slug and v.nome = e.nome
    join public.mappa_specie m on m.vecchia_specie_id = v.id and m.taxon_id is not null
    join public.taxa t on t.id = m.taxon_id
    join col.nomi_proposte p on p.k = col.chiave_nome(e.nome) and p.lingua = 'it'
   where p.taxon_id = coalesce(t.accettato_id, t.id);
  if n > 0 then raise exception 'nomi tolti dall''utente ancora presenti sulla loro pianta: %', n; end if;
  -- regole: un nome una volta sola per taxon e lingua; un preferito al più; mai preferiti inglesi o solo di COL, salvo le
  -- scelte dell'utente; nessun nome uguale al nome scientifico della riga, salvo i nomi dei generi scelti (Calendula)
  select count(*) into n from (select taxon_id, lingua, k from col.nomi_proposte group by 1, 2, 3 having count(*) > 1) x;
  if n > 0 then raise exception 'nomi ripetuti sullo stesso taxon: %', n; end if;
  select count(*) into n from (select taxon_id, lingua from col.nomi_proposte where preferito group by 1, 2 having count(*) > 1) x;
  if n > 0 then raise exception 'taxon con più preferiti: %', n; end if;
  select count(*) into n from col.nomi_proposte p
   where p.preferito and (p.lingua <> 'it' or (p.origine = 'col' and not exists (
           select 1 from col.nomi_scelte s join public.taxa t on t.nome_scientifico = s.taxon where t.id = p.taxon_id and col.chiave_nome(s.nome) = p.k)));
  if n > 0 then raise exception 'preferiti inglesi o di COL non scelti dall''utente: %', n; end if;
  select count(*) into n from col.nomi_proposte p join public.taxa t on t.id = p.taxon_id
   where p.lingua = 'it' and p.k = lower(t.nome_scientifico) and not ('curatore' = any(p.fonti));
  if n > 0 then raise exception 'nomi uguali al nome scientifico del taxon: %', n; end if;
  select count(*) into n from col.nomi_proposte where nome <> col.pulisci_nome(nome) or nome = '' or cardinality(fonti) = 0;
  if n > 0 then raise exception 'nomi vuoti, con spazi da pulire o senza fonti: %', n; end if;
  select count(*) into n from col.nomi_proposte where k in ('dio cane', 'inter merda', 'pino daniele', 'ciruzzo', 'fiore della patagonia');
  if n > 0 then raise exception 'nomi volgari o spazzatura rimasti: %', n; end if;
  -- casi (taxon, nome, preferito)
  for c in select * from (values
      ('Salvia rosmarinus', 'Rosmarino', true),          -- sinonimo verso un autonimo: sulla specie
      ('Cynara cardunculus var. hortensis', 'Carciofo', true), -- vero infraspecifico: resta sulla varietà
      ('Capsicum annuum', 'Peperone', true),            -- scelta dell'utente del 16/10
      ('Capsicum annuum', 'Peperoncino', false),
      ('Brassica oleracea', 'Cavolo', true),
      ('Musa acuminata', 'Banano', true),               -- revisione del 20/10: Platano è Platanus
      ('Musa acuminata', 'Platano', false),
      ('Platanus', 'Platano', true),
      ('Lobularia maritima', 'Alisso marittimo', true), -- nome di COL scelto dall'utente
      ('Lobularia maritima', 'Alisso', false),
      ('Phalaenopsis', 'Falenopside', true),
      ('Phalaenopsis', 'Orchidea', false),
      ('Calendula', 'Calendula', true),                 -- deroga dell'utente
      ('Calendula', 'Calendola', false),                -- nome di COL, mai preferito da solo
      ('Howea forsteriana', 'Kenzia', true),
      ('Howea forsteriana', 'Kentia', false),           -- corretto: senza la parentesi
      ('Prunus', 'Mandorlo', false),                    -- riga di specie salita al genere: mai preferito
      ('Acacia', 'Mimosa', false)                       -- riga «Genere spp.» con più destinazioni: al genere, mai preferito
    ) v(taxon, nome, preferito) loop
    select count(*) into n from col.nomi_proposte p join public.taxa t on t.id = p.taxon_id
     where t.nome_scientifico = c.taxon and p.lingua = 'it' and p.nome = c.nome and p.preferito = c.preferito;
    if n <> 1 then raise exception 'caso %: atteso «%» (preferito %)', c.taxon, c.nome, c.preferito; end if;
  end loop;
  select count(*) into n from col.nomi_proposte p join public.taxa t on t.id = p.taxon_id
   where t.nome_scientifico in ('Zamioculcas zamiifolia', 'Euphorbia trigona', 'Lampranthus') and p.preferito;
  if n > 0 then raise exception 'preferiti dove l''utente ha scelto nessun preferito: %', n; end if;
  raise notice 'NOMI CORRETTI: % nomi (% italiani, % inglesi), % preferiti',
    (select count(*) from col.nomi_proposte), (select count(*) from col.nomi_proposte where lingua = 'it'),
    (select count(*) from col.nomi_proposte where lingua = 'en'), (select count(*) from col.nomi_proposte where preferito);
end $$;
```

- [ ] **Step 4: Lanciarle e vederle fallire**

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_nomi.sql 2>&1 | grep -o 'ERROR.*'
```

Expected: `ERROR:  relation "col.nomi_proposte" does not exist`.

- [ ] **Step 5: Scrivere le proposte**

`scripts/tassonomia/nomi_proposte.sh`:

```bash
#!/usr/bin/env bash
# Fase 4c: prepara gli ingressi dei nomi comuni sulla copia locale e lancia nomi_proposte.sql.
# 1. esporta dalla copia le righe madri di specie e i nomi scientifici (taxa, specie, generi) in CARTELLA;
# 2. ricostruisce le fonti di ogni nome con nomi_provenienza.py (CARTELLA/provenienza.tsv);
# 3. estrae da COL XR i nomi italiani (VernacularName.tsv, lingua ita) in CARTELLA/col_ita.tsv;
# 4. li carica in col.nomi_provenienza e col.nomi_col_ita e lancia nomi_proposte.sql (che scrive col.nomi_proposte).
# Uso: bash scripts/tassonomia/nomi_proposte.sh URL_COPIA CARTELLA   (dalla radice del repository; COLZIP facoltativo)
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; OUT=${2:?manca CARTELLA}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "I nomi proposti si calcolano solo sulla copia locale" >&2; exit 1; }
COLZIP=${COLZIP:-$HOME/giardino-dati/col/xr_latest_coldp.zip}
[ -f "$COLZIP" ] || { echo "Manca $COLZIP (COL XR, fase 2)" >&2; exit 1; }
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"
"${PSQL[@]}" -c "\copy (select id, slug, nome, nome_scientifico, nomi_alternativi, stato_verifica, array_to_string(fonti, ' | ') from public.specie where specie_padre_id is null order by slug) to '$OUT/madri.tsv' with (format csv, delimiter E'\t', quote E'\x01')"
"${PSQL[@]}" -c "\copy (select distinct lower(regexp_replace(btrim(n), '\s+', ' ', 'g')) from (select nome_scientifico from public.taxa union select nome_scientifico from public.specie where specie_padre_id is null union select nome_scientifico from public.generi) x(n) order by 1) to '$OUT/nomi_scientifici.txt'"
python3 scripts/tassonomia/nomi_provenienza.py "$OUT/madri.tsv" "$OUT/nomi_scientifici.txt" > "$OUT/provenienza.tsv" 2> "$OUT/provenienza_riepilogo.txt"
unzip -p "$COLZIP" VernacularName.tsv | awk -F'\t' 'NR == 1 || $5 == "ita"' > "$OUT/col_ita.tsv"
echo "nomi ricostruiti: $(($(wc -l < "$OUT/provenienza.tsv") - 1)); nomi italiani di COL: $(($(wc -l < "$OUT/col_ita.tsv") - 1))"
"${PSQL[@]}" -c 'drop table if exists col.nomi_provenienza, col.nomi_col_ita' \
  -c 'create table col.nomi_provenienza (slug text, ruolo text, nome text, fonti text, note text, stato_verifica text, nome_scientifico text, tipo text, id uuid)' \
  -c "\copy col.nomi_provenienza from '$OUT/provenienza.tsv' with (format csv, delimiter E'\t', header true, quote E'\x01')" \
  -c 'create table col.nomi_col_ita (taxon_col text, source_id text, nome text, translit text, lingua text, preferito text, paese text, area text, sesso text, ref text, note text, modificato text, modificato_da text, fuso text)' \
  -c "\copy col.nomi_col_ita from '$OUT/col_ita.tsv' with (format csv, delimiter E'\t', header true, quote E'\x01')"
"${PSQL[@]}" -f scripts/tassonomia/nomi_proposte.sql
```

`scripts/tassonomia/nomi_proposte.sql`:

```sql
-- Fase 4c: i nomi comuni da caricare (col.nomi_proposte), con i valori definitivi, sulla copia locale (fasi 2-4b
-- applicate, stesse chiavi del reale). Regole: specifica, "Decisioni per la fase 4", punti 12 e 20-24; ricerca in
-- ricerca_fase4/nomi_comuni.md (nc_base.sql). Si lancia da nomi_proposte.sh, che carica col.nomi_provenienza (fonti di
-- ogni nome ricostruite dai lotti) e col.nomi_col_ita (nomi italiani di COL XR).
-- Righe:
-- - nomi italiani delle righe madri di specie (nome principale se diverso dal nome scientifico, nomi alternativi), ammessi
--   se non sono il nome scientifico della riga, un binomio scientifico o «x Genere», e se non sono nell'elenco di
--   esclusione rivisto dall'utente (dati/fase4_nomi_esclusi.tsv); testi corretti con dati/fase4_nomi_corretti.tsv;
-- - i nomi dei generi scelti dall'utente (generi.nome, Calendula compresa), fonte curatore;
-- - i nomi italiani di COL sui taxon di taxa (punto 24): fonte in più sui nomi uguali (confronto senza maiuscole, resta la
--   nostra grafia), righe non preferite per i nuovi (con l'iniziale maiuscola, come i nostri); un nome tolto dall'utente
--   per una pianta non rientra da COL;
-- - i nomi inglesi di PFAF degli avvisi «Nome comune (inglese, fonte PFAF): …», lingua en, mai preferiti (punto 12).
-- Uno stesso nome (senza maiuscole e spazi doppi) compare una sola volta per taxon e lingua, con le fonti unite. Un nome
-- italiano uguale al nome scientifico della sua pianta non entra (salvo generi.nome).
-- (Il DELETE in fondo lavora sulla tabella di appoggio della copia appena creata, non su dati caricati.)
-- Destinazione (punto 20): D1 l'accettato del nome trovato in mappa_specie, per un autonimo la specie; D2 una riga di specie
-- finita su un genere o più su: lì, mai preferito; D3 una riga «Genere spp.» con un vecchio binomio: i suoi nomi vanno alla
-- specie del vecchio nome se è in taxa con una sola destinazione, tranne i nomi uguali a generi.nome, che restano al genere;
-- se il vecchio binomio non è in taxa, al genere, mai preferiti.
-- Preferito (punto 21), al più uno per taxon e lingua: le scelte dell'utente (dati/fase4_nomi_preferiti.tsv: un nome, o
-- vuoto per nessun preferito), poi generi.nome, poi il nome scelto dall'utente per la riga, poi la riga del nome accettato,
-- poi la riga di un sinonimo, poi il nome trasferito (D3); spareggio: riga verificata, poi più fonti esterne. Candidati
-- solo i nomi principali delle righe e generi.nome; mai i nomi D2, D3 non risolti, di COL o inglesi.
-- Lanciare dalla radice del repository.
set statement_timeout = 0;
do $$ begin
  if to_regclass('col.nomi_provenienza') is null or to_regclass('col.nomi_col_ita') is null then
    raise exception 'mancano col.nomi_provenienza o col.nomi_col_ita: lanciare nomi_proposte.sh';
  end if;
end $$;
drop table if exists col.nomi_proposte, col.nomi_esclusi, col.nomi_corretti, col.nomi_scelte, col.nomi_righe_genere, col.nomi_candidati;
create table col.nomi_esclusi (vecchio_slug text not null, nome text not null, motivo text not null check (motivo <> ''),
                               applicata boolean not null default false);
\copy col.nomi_esclusi (vecchio_slug, nome, motivo) from 'scripts/tassonomia/dati/fase4_nomi_esclusi.tsv' with (format text, header true)
create table col.nomi_corretti (vecchio_slug text not null, da text not null, a text not null check (btrim(a) <> ''),
                                applicata boolean not null default false);
\copy col.nomi_corretti (vecchio_slug, da, a) from 'scripts/tassonomia/dati/fase4_nomi_corretti.tsv' with (format text, header true)
-- scelte dell'utente: taxon (nome scientifico della destinazione), nome preferito (vuoto = nessun preferito), motivo
create table col.nomi_scelte (taxon text not null, nome text not null, motivo text not null check (motivo <> ''),
                              applicata boolean not null default false);
\copy col.nomi_scelte (taxon, nome, motivo) from 'scripts/tassonomia/dati/fase4_nomi_preferiti.tsv' with (format text, header true)
create table col.nomi_righe_genere (slug text, sci_old text, nome text, genere text, n_specie_gbif text, decisione text,
                                    descrive_specie text, nome_genere_it text, n_cultivar text, n_piante text);
\copy col.nomi_righe_genere from 'scripts/nomi-italiani/dati/righe_genere_da_rivedere.csv' with (format csv, header true)

-- un nome si scrive senza spazi ai bordi né doppi; due nomi sono uguali a meno delle maiuscole e degli spazi
create or replace function col.pulisci_nome(t text) returns text language sql immutable parallel safe as $$
  select regexp_replace(btrim(t, E' \t\n\u00a0'), '[[:space:]\u00a0]+', ' ', 'g')
$$;
create or replace function col.chiave_nome(t text) returns text language sql immutable parallel safe as $$
  select lower(col.pulisci_nome(t))
$$;

-- destinazione di ogni taxon: l'accettato; per un autonimo infraspecifico, la specie
create temp table dest as
select t.id as t_id, case when a.rango in ('subspecies', 'variety', 'form', 'subvariety')
                           and split_part(a.nome_scientifico, ' ', 2) = regexp_replace(a.nome_scientifico, '^.* ', '')
                          then a.padre_id else a.id end as d
  from public.taxa t join public.taxa a on a.id = coalesce(t.accettato_id, t.id);
create index on dest (t_id);
analyze dest;

-- vecchi binomi delle righe «Genere spp.» e loro destinazione (se unica)
create temp table old_bin as
select slug, sci_old from col.nomi_righe_genere
 where decisione in ('spp', 'rivedere', 'gia_spp') and btrim(sci_old) ~ '^[A-Z][a-z-]+ (× )?[a-z-]+$';
create temp table old_res as
select g.slug, min(d.d::text)::uuid as d_old, count(distinct d.d) as n
  from old_bin g join public.taxa t on t.nome_scientifico = regexp_replace(btrim(g.sci_old), ' x ', ' × ')
  join dest d on d.t_id = t.id
 group by 1;

create temp table gnome as
select g.nome_scientifico, col.pulisci_nome(g.nome) as nome, col.chiave_nome(g.nome) as k, t.id as t_genus
  from public.generi g join public.taxa t on t.nome_scientifico = g.nome_scientifico and t.rango = 'genus' and t.stato = 'accepted'
 where g.nome <> g.nome_scientifico or g.nome_scientifico = 'Calendula';

-- destinazione di ogni riga madre
create temp table riga as
select s.id, s.slug, s.nome_scientifico, s.stato_verifica, m.taxon_id as t_riga,
       (tr.stato in ('accepted', 'provisionally accepted')) as riga_su_accettato, d.d as d_riga, x.rango as rango_d_riga,
       (s.nome_scientifico ~ '^[A-Za-z×x -]+ [a-z×-]+' and s.nome_scientifico !~ ' spp?\.$') as riga_di_specie,
       (ob.slug is not null) as ha_vecchio_binomio, case when o.n = 1 then o.d_old end as d_old
  from public.specie s
  join public.mappa_specie m on m.vecchia_specie_id = s.id and m.taxon_id is not null
  join public.taxa tr on tr.id = m.taxon_id
  join dest d on d.t_id = m.taxon_id
  join public.taxa x on x.id = d.d
  left join old_bin ob on ob.slug = s.slug
  left join old_res o on o.slug = s.slug
 where s.specie_padre_id is null;

-- nomi italiani delle righe, corretti, con la regola di destinazione
update col.nomi_corretti c set applicata = true
 where exists (select 1 from col.nomi_provenienza p where p.slug = c.vecchio_slug and p.nome = c.da);
create temp table nd as
select p.slug, p.ruolo, col.pulisci_nome(coalesce(c.a, p.nome)) as nome, col.chiave_nome(coalesce(c.a, p.nome)) as k, p.fonti, p.note, p.tipo,
       r.stato_verifica, r.riga_su_accettato,
       case when r.ha_vecchio_binomio and exists (select 1 from gnome g where g.t_genus = r.d_riga and g.k = col.chiave_nome(coalesce(c.a, p.nome)))
              then 'D3 nome di genere approvato, resta al genere'
            when r.d_old is not null then 'D3 trasferito alla specie del vecchio nome'
            when r.ha_vecchio_binomio then 'D3 vecchio binomio non in taxa: al genere, mai preferito'
            when r.riga_di_specie and r.rango_d_riga not in ('species', 'subspecies', 'variety', 'form', 'subvariety')
              then 'D2 riga di specie salita di rango: mai preferito'
            else 'D1 accettato' end as regola,
       r.d_riga, r.d_old
  from col.nomi_provenienza p
  join riga r on r.id = p.id
  left join col.nomi_corretti c on c.vecchio_slug = p.slug and c.da = p.nome;
alter table nd add column taxon_id uuid;
update nd set taxon_id = case when regola like 'D3 trasferito%' then d_old else d_riga end;

update col.nomi_esclusi e set applicata = true
 where exists (select 1 from nd where nd.slug = e.vecchio_slug and nd.k = col.chiave_nome(e.nome));
create temp table amm as
select nd.* from nd
 where tipo in ('comune', 'genere_della_riga', 'parola_uguale_a_nome_scientifico') and k !~ '^(x|×) '
   and not exists (select 1 from col.nomi_esclusi e where e.vecchio_slug = nd.slug and col.chiave_nome(e.nome) = nd.k);

-- candidati al preferito, per riga
create table col.nomi_candidati as
select taxon_id, k, nome, slug as da,
       case when note like '%lotto12 rinominato%' or slug in ('helleborus', 'hedera') then 1
            when regola like 'D3 trasferito%' then 4 when riga_su_accettato then 2 else 3 end as prio,
       (stato_verifica = 'verificato') as verificata,
       cardinality(array_remove(array_remove(string_to_array(fonti, ','), 'catalogo'), 'curatore')) as n_fonti
  from amm where ruolo = 'principale' and regola not like 'D2%' and regola not like 'D3 vecchio binomio%'
union all
select t_genus, k, nome, 'generi:' || nome_scientifico, 0, true, 1 from gnome;

-- nomi italiani: dei nostri dati e dei generi, uniti per taxon e nome; poi COL
create temp table it0 as
select taxon_id, k, nome, string_to_array(fonti, ',') as fonti, slug, regola, (ruolo = 'principale') as principale from amm
union all
select t_genus, k, nome, array['curatore'], 'generi:' || nome_scientifico, 'nome del genere scelto dall''utente', true from gnome;
create temp table it1 as
select taxon_id, k, (array_agg(nome order by principale desc, nome))[1] as nome,
       array(select distinct f from unnest(array_agg(fonti)) u(f)) as fonti_raw,
       'righe: ' || string_agg(distinct slug, ', ' order by slug) || '; ' || string_agg(distinct regola, '; ' order by regola) as nota
  from (select taxon_id, k, nome, unnest(fonti) as fonti, slug, regola, principale from it0) x
 group by taxon_id, k;
alter table it1 add column fonti text[];
update it1 set fonti = array(select f from unnest(fonti_raw) f order by f);

create temp table colt as
select d.d as taxon_id, col.chiave_nome(c.nome) as k, col.pulisci_nome(c.nome) as nome,
       'col:' || case c.source_id when '139831' then 'inaturalist' when '314570' then 'wikispecies' when '53131' then 'iucn'
                                  when '2018' then 'grin' when '314569' then 'wikidata'
                                  else case when c.source_id ~ '^[0-9]+$' and c.source_id::int between 291500 and 291699 then 'flora-helvetica'
                                            when c.source_id ~ '^[0-9]+$' and c.source_id::int between 292400 and 292699 then 'info-flora'
                                            else 'altra-' || c.source_id end end as fonte
  from col.nomi_col_ita c join public.taxa x on x.col_id = c.taxon_col join dest d on d.t_id = x.id
 where col.pulisci_nome(c.nome) <> '';
-- un nome tolto dall'utente vale per quella pianta da qualunque fonte arrivi: si toglie anche il nome uguale di COL
create temp table esclusi_tk as
select distinct nd.taxon_id, nd.k from nd join col.nomi_esclusi e on e.vecchio_slug = nd.slug and col.chiave_nome(e.nome) = nd.k;
create temp table colp as
select taxon_id, k, min(nome) as nome, array_agg(distinct fonte order by fonte) as fonti from colt c
 where not exists (select 1 from esclusi_tk x where x.taxon_id = c.taxon_id and x.k = c.k)
 group by 1, 2;

-- nomi inglesi di PFAF
create temp table en0 as
select coalesce(r.d_old, r.d_riga) as taxon_id, col.pulisci_nome(btrim(n, E' \t\n\u00a0.')) as nome, s.slug
  from public.specie s join riga r on r.id = s.id
  cross join lateral unnest(s.alert) a
  cross join lateral regexp_split_to_table(substring(a from '^Nome comune \(inglese, fonte PFAF\):[[:space:] ]*(.*)$'), ',[[:space:] ]*') n
 where s.specie_padre_id is null and a ~ '^Nome comune \(inglese, fonte PFAF\):';
create temp table en1 as
select taxon_id, col.chiave_nome(nome) as k, (array_agg(nome order by nome))[1] as nome, 'righe: ' || string_agg(distinct slug, ', ' order by slug) as nota
  from en0 where btrim(nome) <> '' group by 1, 2;

-- preferito
create temp table pref0 as
select taxon_id, k, row_number() over (partition by taxon_id order by prio, verificata desc, n_fonti desc, k) as rn,
       prio, verificata, n_fonti
  from (select taxon_id, k, min(prio) as prio, bool_or(verificata) as verificata, max(n_fonti) as n_fonti
          from col.nomi_candidati group by 1, 2) x;
-- una scelta dell'utente vale se il taxon ha nomi e se il nome scelto è uno dei suoi (nostro o di COL)
create temp table tutti_it as select taxon_id, k from it1 union select taxon_id, k from colp;
update col.nomi_scelte s set applicata = true
 where exists (select 1 from public.taxa t join (select distinct taxon_id from tutti_it) c on c.taxon_id = t.id
                where t.nome_scientifico = s.taxon
                  and (s.nome = '' or exists (select 1 from tutti_it i where i.taxon_id = t.id and i.k = col.chiave_nome(s.nome))));
create temp table pref as
select p.taxon_id, p.k from pref0 p
 where p.rn = 1 and not exists (select 1 from col.nomi_scelte s join public.taxa t on t.nome_scientifico = s.taxon
                                 where s.applicata and t.id = p.taxon_id)
union all
select t.id, col.chiave_nome(s.nome) from col.nomi_scelte s
  join public.taxa t on t.nome_scientifico = s.taxon
  join (select distinct taxon_id from tutti_it) c on c.taxon_id = t.id
 where s.applicata and s.nome <> '';

create table col.nomi_proposte as
select gen_random_uuid() as id, coalesce(i.taxon_id, c.taxon_id) as taxon_id, 'it'::text as lingua,
       coalesce(i.nome, upper(left(c.nome, 1)) || substr(c.nome, 2)) as nome,
       exists (select 1 from pref where pref.taxon_id = coalesce(i.taxon_id, c.taxon_id) and pref.k = coalesce(i.k, c.k)) as preferito,
       array(select distinct f from unnest(coalesce(i.fonti, '{}') || coalesce(c.fonti, '{}')) f order by f) as fonti,
       i.nota, coalesce(i.k, c.k) as k, case when i.k is null then 'col' else 'nostri' end as origine
  from it1 i full join colp c on c.taxon_id = i.taxon_id and c.k = i.k
union all
select gen_random_uuid(), taxon_id, 'en', nome, false, array['pfaf'], nota, k, 'pfaf' from en1;
-- un nome uguale al nome scientifico della sua pianta non è un nome comune (la ricerca lo trova già da taxa), salvo i nomi
-- dei generi scelti dall'utente (Calendula)
delete from col.nomi_proposte p using public.taxa t
 where t.id = p.taxon_id and p.lingua = 'it' and p.k = col.chiave_nome(t.nome_scientifico) and not ('curatore' = any(p.fonti));
alter table col.nomi_proposte add primary key (id);

\pset tuples_only on
\pset format unaligned
select 'nomi ' || count(*) || ' (it ' || count(*) filter (where lingua = 'it') || ', di cui nostri ' || count(*) filter (where origine = 'nostri')
       || ' e solo COL ' || count(*) filter (where origine = 'col') || '; en ' || count(*) filter (where lingua = 'en') || '), preferiti '
       || count(*) filter (where preferito) || ', taxon ' || count(distinct taxon_id)
  from col.nomi_proposte;
select 'candidati al preferito su ' || count(distinct taxon_id) || ' taxon, con più candidati ' || count(distinct taxon_id) filter (where n > 1)
       || ', spareggi decisi solo dall''ordine alfabetico ' || (select count(*) from pref0 a join pref0 b on a.taxon_id = b.taxon_id and a.rn = 1 and b.rn = 2
            where a.prio = b.prio and a.verificata = b.verificata and a.n_fonti = b.n_fonti
              and not exists (select 1 from col.nomi_scelte s join public.taxa t on t.nome_scientifico = s.taxon where s.applicata and t.id = a.taxon_id))
  from (select taxon_id, count(distinct k) as n from col.nomi_candidati group by taxon_id) x;
select 'esclusioni applicate ' || (select count(*) filter (where applicata) || ' su ' || count(*) from col.nomi_esclusi)
       || ', correzioni ' || (select count(*) filter (where applicata) || ' su ' || count(*) from col.nomi_corretti)
       || ', scelte ' || (select count(*) filter (where applicata) || ' su ' || count(*) from col.nomi_scelte);
```

- [ ] **Step 6: Eseguirle e rilanciare le prove**

```bash
chmod +x scripts/tassonomia/nomi_proposte.sh
bash scripts/tassonomia/nomi_proposte.sh "$COPIA" "$F4/nomi_ingressi" 2>&1 | grep -v 'NOTICE:  table'
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_nomi.sql 2>&1 | grep -o 'ERROR.*\|NOTICE.*'
```

Expected, in meno di un minuto:
- `nomi ricostruiti: 11023; nomi italiani di COL: 35572`;
- `nomi 18595 (it 10553, di cui nostri 9600 e solo COL 953; en 8042), preferiti 2777, taxon 7366`;
- `candidati al preferito su 2779 taxon, con più candidati 7, spareggi decisi solo dall'ordine alfabetico 0`;
- `esclusioni applicate 913 su 913, correzioni 25 su 25, scelte 13 su 13`;
- infine `NOTICE:  NOMI CORRETTI: 18595 nomi (10553 italiani, 8042 inglesi), 2777 preferiti`.

- [ ] **Step 7: Prove di mutazione**

```bash
mutanomi() {  # mutanomi FILE ESPRESSIONE_SED NOME
  cp "$1" "$SCRATCH/mutazione.bak"; sed -i '' "$2" "$1"
  cmp -s "$1" "$SCRATCH/mutazione.bak" && echo "MUTAZIONE $3 NON APPLICATA"
  bash scripts/tassonomia/nomi_proposte.sh "$COPIA" "$SCRATCH/mutnomi_$3" > /dev/null 2>&1
  echo "mutazione $3: $($PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_nomi.sql 2>&1 | grep -o 'ERROR.*' | cut -c1-90)"
  cp "$SCRATCH/mutazione.bak" "$1"
}
mutanomi scripts/tassonomia/dati/fase4_nomi_preferiti.tsv '/^Musa acuminata/d' scelta_musa
mutanomi scripts/tassonomia/nomi_proposte.sql 's/^ where not exists (select 1 from esclusi_tk x where x.taxon_id = c.taxon_id and x.k = c.k)$/ where true/' esclusi_col
bash scripts/tassonomia/nomi_proposte.sh "$COPIA" "$F4/nomi_ingressi_2" 2>&1 | tail -1
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_nomi.sql 2>&1 | grep -o 'ERROR.*\|NOTICE.*'
git status --short
```

Expected:
- nessuna riga `NON APPLICATA`;
- `mutazione scelta_musa: ERROR:  caso Musa acuminata: atteso «Banano» (preferito t)`;
- `mutazione esclusi_col: ERROR:  nomi proposti, tutte: 18642 invece di 18595`;
- dopo il ripristino `esclusioni applicate 913 su 913, correzioni 25 su 25, scelte 13 su 13` e `NOTICE:  NOMI CORRETTI: …`;
- `git status` mostra solo i 4 file nuovi di questo task.

- [ ] **Step 8: Commit**

```bash
git add scripts/tassonomia/nomi_provenienza.py scripts/tassonomia/prova_nomi.sql scripts/tassonomia/nomi_proposte.sh scripts/tassonomia/nomi_proposte.sql
git commit -m "Tassonomia fase 4c: fonti dei nomi, nomi comuni proposti con le decisioni dell'utente (copia locale) e le prove"
```

---

### Task 2: Esportazione, caricamento, verifica e rollback sulla copia locale

**Files:**
- Create: `scripts/tassonomia/prova_fase4c.sh`
- Create: `scripts/tassonomia/nomi_esporta.sh`
- Create: `scripts/tassonomia/carica_nomi.sh`
- Create: `scripts/tassonomia/verifica_fase4c.sql`
- Create: `scripts/tassonomia/rollback_fase4c.sql`

**Interfaces:**
- Consumes: `col.nomi_proposte` e `col.nomi_provenienza` (Task 1); `controlli_spazio.sql`, `impronta_specie.sql` (fasi 1b-2); `rollback_fase4a.sql` (fase 4b).
- Produces:
  - `nomi_esporta.sh URL_COPIA CARTELLA` scrive `nomi_01.csv`, `manifest.tsv` e `inventario.txt`;
  - `carica_nomi.sh URL CARTELLA CARTELLA_MISURE`: ultima riga `CARICAMENTO NOMI OK`;
  - `verifica_fase4c.sql` con le variabili `righe_nomi`, `nomi_specie_principali`, `nomi_specie_alternativi`, `preferiti`, `italiani_nostri`, `italiani_solo_col`, `inglesi`;
  - `rollback_fase4c.sql` con la variabile `lotti`;
  - `prova_fase4c.sh URL_COPIA CARTELLA_ESPORTA CARTELLA`: ultima riga `PROVE FASE 4C OK`.

- [ ] **Step 1: Scrivere le prove**

`scripts/tassonomia/prova_fase4c.sh`:

```bash
#!/usr/bin/env bash
# Prove della fase 4c (nomi comuni) sulla copia locale: rifiuti, file alterato, inventario incompleto, ripresa dopo un
# lotto fallito, caricamento, rilancio, rollback della 4a rifiutato con i soli nomi comuni presenti, rollback della 4c
# rifiutato se un nome è stato aggiunto, rollback eseguito, nuovo caricamento.
# Uso: bash scripts/tassonomia/prova_fase4c.sh URL_COPIA CARTELLA_ESPORTA CARTELLA      (CARTELLA nuova a ogni giro)
#   CARTELLA_ESPORTA = cartella scritta da nomi_esporta.sh. La copia deve avere la fase 4b applicata e nomi_comuni vuota.
# Uscita 0 = tutte le prove passate; alla fine la copia contiene il caricamento completo.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; E=${2:?manca CARTELLA_ESPORTA}; OUT=${3:?manca CARTELLA}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "Le prove girano solo sulla copia locale" >&2; exit 1; }
[ ! -e "$OUT" ] || { echo "La cartella $OUT esiste già: usarne una nuova" >&2; exit 1; }
D=scripts/tassonomia
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"
fallita() { echo "PROVA $1 FALLITA: $2" >&2; exit 1; }
conta() { "${PSQL[@]}" -tAc "select count(*) || ' ' || count(*) filter (where preferito) from public.nomi_comuni"; }
NOMI=$(awk -F'\t' '$1 ~ /^nomi_/ { s += $2 } END { print s }' "$E/manifest.tsv")
LOTTI=$(wc -l < "$E/manifest.tsv" | tr -d ' ')
PREFERITI=$(awk '$1 == "preferiti" { print $2 }' "$E/inventario.txt")
VUOTO="0 0"
PIENO="$NOMI $PREFERITI"
[ "$(conta)" = "$VUOTO" ] || fallita preparazione "nomi_comuni non è vuota ($(conta)): prima rollback_fase4c.sql"
[ "$("${PSQL[@]}" -tAc 'select count(*) from public.schede')" -gt 0 ] || fallita preparazione "la fase 4b non è applicata"
carica() {  # carica CARTELLA PROVA
  bash $D/carica_nomi.sh "$URL" "$E" "$OUT/$1" > "$OUT/$1.log" 2>&1 || fallita "$2" "carica_nomi: $(tail -3 "$OUT/$1.log")"
  [ "$(tail -1 "$OUT/$1.log")" = 'CARICAMENTO NOMI OK' ] || fallita "$2" "$(tail -3 "$OUT/$1.log")"
}

# 1. Rifiuti, prima di qualsiasi connessione.
out=$(bash $D/carica_nomi.sh 'postgresql://u:p@finto.pooler.supabase.com:5432/postgres' "$E" "$OUT/r1" 2>&1) \
  && fallita rifiuti "accettato il database reale senza conferma"
grep -qF 'RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si' <<<"$out" || fallita rifiuti "$out"
out=$(CONFERMO_CARICAMENTO_REALE=si bash $D/carica_nomi.sh 'postgresql://u:p@finto.pooler.supabase.com:6543/postgres' "$E" "$OUT/r2" 2>&1) \
  && fallita rifiuti "accettata la porta 6543"
grep -qF 'RIFIUTATO: serve la porta 5432' <<<"$out" || fallita rifiuti "$out"
echo "PROVA rifiuti OK"

# 2. File alterato e inventario incompleto: rifiuto prima di scrivere.
cp -R "$E" "$OUT/esporta_alterata"
printf 'x' >> "$OUT/esporta_alterata/nomi_01.csv"
out=$(bash $D/carica_nomi.sh "$URL" "$OUT/esporta_alterata" "$OUT/r3" 2>&1) && fallita alterato "nessun errore"
grep -qF 'RIFIUTATO: nomi_01.csv diverso da quello del manifesto' <<<"$out" || fallita alterato "$out"
cp -R "$E" "$OUT/esporta_senza_inventario"
grep -v '^inglesi ' "$E/inventario.txt" > "$OUT/esporta_senza_inventario/inventario.txt"
out=$(bash $D/carica_nomi.sh "$URL" "$OUT/esporta_senza_inventario" "$OUT/r3b" 2>&1) && fallita alterato "accettato un inventario incompleto"
grep -qF 'RIFIUTATO: inventario.txt senza inglesi' <<<"$out" || fallita alterato "$out"
[ "$(conta)" = "$VUOTO" ] || fallita alterato "caricato qualcosa: $(conta)"
echo "PROVA alterato OK"

# 3. Ripresa: il lotto fallisce (un nome già presente con lo stesso taxon, lingua e nome di una sua riga, ma un altro id) e
#    non entra niente; tolta la riga, il rilancio carica tutto.
"${PSQL[@]}" -c 'create temp table x (id uuid, taxon_id uuid, lingua text, nome text, preferito boolean, fonti text[], nota text)' \
  -c "\\copy x from '$E/nomi_01.csv' with (format csv, header)" \
  -c "insert into public.nomi_comuni (taxon_id, lingua, nome, fonti) select taxon_id, lingua, nome, '{prova}' from x where not preferito limit 1"
out=$(bash $D/carica_nomi.sh "$URL" "$E" "$OUT/r4" 2>&1) && fallita ripresa "nessun errore con il lotto in conflitto"
grep -qF 'duplicate key value' <<<"$out" || fallita ripresa "$out"
[ "$("${PSQL[@]}" -tAc "select count(*) from public.nomi_comuni")" = 1 ] || fallita ripresa "dopo il lotto fallito ci sono $(conta) nomi"
"${PSQL[@]}" -c "delete from public.nomi_comuni where fonti = '{prova}'"
carica r5 ripresa
[ "$(conta)" = "$PIENO" ] || fallita ripresa "stato inatteso: $(conta) invece di $PIENO"
echo "PROVA ripresa OK"

# 4. Rilancio: tutto saltato, stato invariato.
carica r6 rilancio
grep -qF 'nomi_01.csv già caricato' "$OUT/r6/tempi.txt" || fallita rilancio "lotto ricaricato"
[ "$(conta)" = "$PIENO" ] || fallita rilancio "stato cambiato: $(conta)"
echo "PROVA rilancio OK"

# 5. Il rollback della fase 4a si rifiuta anche con i soli nomi comuni presenti (schede tolte in una transazione mai
#    confermata).
out=$("${PSQL[@]}" -c 'begin' -c 'delete from public.schede' -f $D/rollback_fase4a.sql 2>&1) \
  && fallita rollback_4a "rollback della fase 4a accettato con i nomi comuni presenti"
grep -qF 'Rollback fase 4a rifiutato' <<<"$out" || fallita rollback_4a "$out"
[ "$("${PSQL[@]}" -tAc 'select count(*) from public.schede')" -gt 0 ] || fallita rollback_4a "schede tolte"
echo "PROVA rollback_4a OK"

# 6. Rollback della 4c: rifiutato se un nome è stato aggiunto dopo il caricamento (in una transazione mai confermata),
#    poi eseguito e seguito da un nuovo caricamento completo.
out=$("${PSQL[@]}" -c 'begin' -c "insert into public.nomi_comuni (taxon_id, lingua, nome, fonti, creato_il)
                                  select taxon_id, 'it', 'nome aggiunto per la prova', '{prova}', now() + interval '1 minute' from public.nomi_comuni limit 1" \
        -v lotti="$LOTTI" -f $D/rollback_fase4c.sql 2>&1) && fallita rollback "rollback accettato con un nome aggiunto"
grep -qF 'Rollback fase 4c rifiutato' <<<"$out" || fallita rollback "$out"
[ "$(conta)" = "$PIENO" ] || fallita rollback "un rollback rifiutato ha tolto righe: $(conta)"
"${PSQL[@]}" -1 -v lotti="$LOTTI" -f $D/rollback_fase4c.sql
"${PSQL[@]}" -c 'vacuum full public.nomi_comuni'
[ "$(conta)" = "$VUOTO" ] || fallita rollback "stato dopo il rollback: $(conta) invece di $VUOTO"
carica r7 rollback
[ "$(conta)" = "$PIENO" ] || fallita rollback "stato dopo il nuovo caricamento: $(conta)"
echo "PROVA rollback OK"
echo "PROVE FASE 4C OK"
```

- [ ] **Step 2: Lanciarle e vederle fallire**

Mancano ancora l'esportazione e il caricamento:

```bash
chmod +x scripts/tassonomia/prova_fase4c.sh
mkdir -p "$SCRATCH/esporta_vuota" && printf 'preferiti 0\n' > "$SCRATCH/esporta_vuota/inventario.txt" && : > "$SCRATCH/esporta_vuota/manifest.tsv"
bash scripts/tassonomia/prova_fase4c.sh "$COPIA" "$SCRATCH/esporta_vuota" "$SCRATCH/prove_fase4c_0" 2>&1 | tail -1
```

Expected: `PROVA rifiuti FALLITA: …` con `No such file or directory` per `carica_nomi.sh`.

- [ ] **Step 3: Scrivere esportazione, caricamento, verifica e rollback, ed esportare**

`scripts/tassonomia/nomi_esporta.sh`:

```bash
#!/usr/bin/env bash
# Fase 4c: dai nomi proposti (col.nomi_proposte, copia locale) scrive i file da caricare sul database reale: lotti
# nomi_NN.csv da 50.000 righe al massimo (oggi uno solo, pochi MB di WAL), manifest.tsv con righe e sha256 e
# inventario.txt con i numeri che verifica_fase4c.sql ricontrolla sul reale (nomi di specie da cui si parte, nomi per
# origine, preferiti). Le chiavi di taxa sono quelle della copia, identica al reale.
# Uso: bash scripts/tassonomia/nomi_esporta.sh URL_COPIA CARTELLA
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; DIR=${2:?manca CARTELLA}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "I file si preparano solo dalla copia locale" >&2; exit 1; }
[ ! -e "$DIR" ] || { echo "La cartella $DIR esiste già: i file provati non si sovrascrivono" >&2; exit 1; }
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
LOTTO=50000
COLONNE='id,taxon_id,lingua,nome,preferito,fonti,nota'
mkdir -p "$DIR"
"${PSQL[@]}" -c 'set statement_timeout = 0' -c "copy (select $COLONNE from col.nomi_proposte order by lingua, taxon_id, k) to stdout with (format csv, header)" > "$DIR/tutte.csv"
python3 - "$DIR" "$LOTTO" <<'PY'
import csv, hashlib, os, sys
d, lotto = sys.argv[1], int(sys.argv[2])
righe = list(csv.reader(open(os.path.join(d, 'tutte.csv'), encoding='utf-8', newline='')))
testa, corpo = righe[0], righe[1:]
with open(os.path.join(d, 'manifest.tsv'), 'w', encoding='utf-8') as man:
    for n, i in enumerate(range(0, len(corpo), lotto), 1):
        nome = f'nomi_{n:02d}.csv'
        with open(os.path.join(d, nome), 'w', encoding='utf-8', newline='') as f:
            w = csv.writer(f, lineterminator='\n')
            w.writerow(testa)
            w.writerows(corpo[i:i + lotto])
        sha = hashlib.sha256(open(os.path.join(d, nome), 'rb').read()).hexdigest()
        man.write(f'{nome}\t{len(corpo[i:i + lotto])}\t{sha}\t{corpo[i][0]}\n')
os.remove(os.path.join(d, 'tutte.csv'))
PY
# inventario: chiave e valore, uno per riga
"${PSQL[@]}" -tA -F ' ' -c "
select 'nomi_specie_principali', count(*) from col.nomi_provenienza where ruolo = 'principale'
union all select 'nomi_specie_alternativi', count(*) from col.nomi_provenienza where ruolo = 'alternativo'
union all select 'preferiti', count(*) from col.nomi_proposte where preferito
union all select 'italiani_nostri', count(*) from col.nomi_proposte where lingua = 'it' and origine = 'nostri'
union all select 'italiani_solo_col', count(*) from col.nomi_proposte where lingua = 'it' and origine = 'col'
union all select 'inglesi', count(*) from col.nomi_proposte where lingua = 'en'" > "$DIR/inventario.txt"
cut -f1,2 "$DIR/manifest.tsv"
cat "$DIR/inventario.txt"
```

`scripts/tassonomia/carica_nomi.sh`:

```bash
#!/usr/bin/env bash
# Fase 4c del modello tassonomico: carica public.nomi_comuni dai lotti preparati da nomi_esporta.sh, uno per transazione,
# con le righe già definitive (nessun aggiornamento: specifica, "Decisioni sullo spazio", punto 5). Va lanciato dopo le
# fasi 2-4b: ogni taxon_id deve già esistere.
# Regole sullo spazio: prima di ogni passo controlla la somma dei database e il WAL; tra un lotto e l'altro e prima degli
# indici fa una pausa (10 minuti sul reale); l'indice trigram di nomi_comuni si toglie prima e si ricrea dopo (i due
# indici unici restano: un nome una volta sola per taxon e lingua, un solo preferito).
# Si può rilanciare dopo un'interruzione: ogni lotto è una transazione e quelli già caricati vengono saltati. Le altre
# tabelle non cambiano: l'impronta di specie si confronta prima e dopo.
# Uso: bash scripts/tassonomia/carica_nomi.sh URL CARTELLA_NOMI CARTELLA_MISURE
#   Sul database reale serve CONFERMO_CARICAMENTO_REALE=si; soglie fisse: 420 MB di database (deciso nel piano della
#   fase 4c; il limite di lavoro della specifica resta 450), 300 MB di WAL.
#   Sulla copia locale: PAUSA_S (secondi, predefinito 0), SOGLIA_MB e SOGLIA_WAL_MB (predefiniti 100000).
# Uscita 0 e ultima riga CARICAMENTO NOMI OK = riuscito.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL}; NC=${2:?manca CARTELLA_NOMI}; OUT=${3:?manca CARTELLA_MISURE}
D=scripts/tassonomia
if [[ $URL == *supabase* ]]; then
  [[ $URL != *:6543/* ]] || { echo "RIFIUTATO: serve la porta 5432 (modalità sessione), non la 6543" >&2; exit 1; }
  [[ ${CONFERMO_CARICAMENTO_REALE:-} == si ]] || { echo "RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si" >&2; exit 1; }
  PAUSA_S=600; SOGLIA_MB=420; SOGLIA_WAL_MB=300
else
  PAUSA_S=${PAUSA_S:-0}; SOGLIA_MB=${SOGLIA_MB:-100000}; SOGLIA_WAL_MB=${SOGLIA_WAL_MB:-100000}
fi
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"
tempo() { echo "$(date +%T) $1" >> "$OUT/tempi.txt"; }
controlla() {
  "${PSQL[@]}" -v soglia_mb="$SOGLIA_MB" -v soglia_wal_mb="$SOGLIA_WAL_MB" -f $D/controlli_spazio.sql > "$OUT/controlli_$1.txt" \
    || { cat "$OUT/controlli_$1.txt" >&2; echo "FERMATO: spazio insufficiente prima di $1; in questo passo non è stato caricato niente" >&2; exit 1; }
}
caricato() { [ "$("${PSQL[@]}" -tAc "select count(*) from public.nomi_comuni where id = '$1'")" = 1 ]; }
primo_passo=1
pausa() {
  if [ "$primo_passo" = 1 ]; then primo_passo=0
  elif [ "$PAUSA_S" -gt 0 ]; then tempo "pausa di $PAUSA_S s"; sleep "$PAUSA_S"; fi
}
UUID='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
COLONNE='id,taxon_id,lingua,nome,preferito,fonti,nota'

# 1. I file sono quelli provati (sha256 del manifesto), con le colonne attese; l'inventario è completo.
while IFS=$'\t' read -r file righe sha primo <&3; do
  [[ $file =~ ^nomi_[0-9]{2}\.csv$ && $righe =~ ^[0-9]+$ && $primo =~ $UUID ]] \
    || { echo "RIFIUTATO: riga del manifesto non valida: $file" >&2; exit 1; }
  [ "$(shasum -a 256 "$NC/$file" | cut -d' ' -f1)" = "$sha" ] || { echo "RIFIUTATO: $file diverso da quello del manifesto" >&2; exit 1; }
  [ "$(head -1 "$NC/$file")" = "$COLONNE" ] || { echo "RIFIUTATO: colonne inattese in $file" >&2; exit 1; }
done 3< "$NC/manifest.tsv"
NOMI=$(awk -F'\t' '{ s += $2 } END { print s }' "$NC/manifest.tsv")
INV=()
for chiave in nomi_specie_principali nomi_specie_alternativi preferiti italiani_nostri italiani_solo_col inglesi; do
  valore=$(awk -v k="$chiave" '$1 == k { print $2 }' "$NC/inventario.txt")
  [[ $valore =~ ^[0-9]+$ ]] || { echo "RIFIUTATO: inventario.txt senza $chiave" >&2; exit 1; }
  INV+=(-v "$chiave=$valore")
done
controlla inizio
tempo "impronta di specie prima"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_prima.txt"

# 2. Indice trigram tolto se c'è qualcosa da caricare (si ricrea al passo 4, anche dopo un'interruzione).
da_caricare=0
while IFS=$'\t' read -r file righe sha primo <&3; do
  if ! caricato "$primo"; then da_caricare=$((da_caricare + 1)); fi
done 3< "$NC/manifest.tsv"
if [ "$da_caricare" -gt 0 ]; then
  tempo "tolgo l'indice trigram di nomi_comuni ($da_caricare lotti da caricare)"
  "${PSQL[@]}" -c 'drop index if exists public.nomi_comuni_nome_trgm_idx'
fi

# 3. Un lotto per transazione; il conteggio si controlla dentro la transazione, prima del commit.
while IFS=$'\t' read -r file righe sha primo <&3; do
  if caricato "$primo"; then tempo "$file già caricato"; continue; fi
  pausa
  controlla "$file"
  prima=$("${PSQL[@]}" -tAc 'select count(*) from public.nomi_comuni')
  lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
  tempo "$file: carico $righe righe"
  "${PSQL[@]}" -1 -c "set local statement_timeout = '10min'" \
    -c "copy public.nomi_comuni ($COLONNE) from stdin with (format csv, header)" \
    -c "do \$\$ begin if (select count(*) from public.nomi_comuni) <> $((prima + righe)) then raise exception 'lotto $file incompleto'; end if; end \$\$" \
    < "$NC/$file"
  wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
  tempo "$file: caricate $righe righe, WAL $wal MB"
done 3< "$NC/manifest.tsv"

# 4. Indice trigram (identico alla migration della fase 1) e statistiche.
pausa
controlla indici
lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
tempo "ricreo l'indice trigram di nomi_comuni"
"${PSQL[@]}" -1 -c 'set local statement_timeout = 0' \
  -c 'create index if not exists nomi_comuni_nome_trgm_idx on public.nomi_comuni using gin (nome extensions.gin_trgm_ops)'
"${PSQL[@]}" -c 'analyze public.nomi_comuni'
wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
tempo "indice ricreato, WAL $wal MB"

# 5. specie invariata, nomi corretti, misure finali.
tempo "impronta di specie dopo"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_dopo.txt"
diff "$OUT/impronta_specie_prima.txt" "$OUT/impronta_specie_dopo.txt" >&2 \
  || { echo "FALLITO: specie è cambiata durante il caricamento" >&2; exit 1; }
"${PSQL[@]}" -v righe_nomi="$NOMI" "${INV[@]}" -f $D/verifica_fase4c.sql
"${PSQL[@]}" -f $D/controlli_spazio.sql | tee "$OUT/controlli_fine.txt"
tempo "fine"
echo "CARICAMENTO NOMI OK"
```

`scripts/tassonomia/verifica_fase4c.sql`:

```sql
-- Fase 4c: controllo di public.nomi_comuni dopo il caricamento e inventario finale della fase 4. Sola lettura.
-- 1. nomi_comuni ha le righe e i preferiti dei file (inventario.txt di nomi_esporta.sh), per origine: nomi dei nostri dati
--    (almeno una fonte che non è di COL), nomi solo di COL, nomi inglesi; i nomi di specie da cui si parte sono gli stessi
--    (righe madri: nome diverso dal nome scientifico e ogni elemento di nomi_alternativi, come nomi_provenienza.py);
-- 2. regole: un nome una volta sola per taxon e lingua anche senza maiuscole, nessun preferito inglese o solo PFAF, nomi
--    senza spazi ai bordi, indici, permessi (fonti e nota non leggibili dai client, nessuna scrittura);
-- 3. inventario della fase 4: ogni riga di specie ha il suo posto nel modello nuovo (mappa_specie, cultivar, schede).
-- Variabili psql: righe_nomi, nomi_specie_principali, nomi_specie_alternativi, preferiti, italiani_nostri, italiani_solo_col,
-- inglesi (le passa carica_nomi.sh da manifest.tsv e inventario.txt).
select set_config('fase4c.righe', :'righe_nomi', false), set_config('fase4c.principali', :'nomi_specie_principali', false),
       set_config('fase4c.alternativi', :'nomi_specie_alternativi', false), set_config('fase4c.preferiti', :'preferiti', false),
       set_config('fase4c.nostri', :'italiani_nostri', false), set_config('fase4c.solo_col', :'italiani_solo_col', false),
       set_config('fase4c.inglesi', :'inglesi', false) \g /dev/null
do $$
declare
  n bigint;
  atteso bigint;
  v record;
begin
  -- 1. righe, preferiti e origine
  for v in select * from (values
      ('righe', (select count(*) from public.nomi_comuni)),
      ('preferiti', (select count(*) from public.nomi_comuni where preferito)),
      ('nostri', (select count(*) from public.nomi_comuni where lingua = 'it' and exists (select 1 from unnest(fonti) f where f !~ '^col:'))),
      ('solo_col', (select count(*) from public.nomi_comuni where lingua = 'it' and not exists (select 1 from unnest(fonti) f where f !~ '^col:'))),
      ('inglesi', (select count(*) from public.nomi_comuni where lingua = 'en')),
      ('principali', (select count(*) from public.specie where specie_padre_id is null
                        and lower(regexp_replace(btrim(nome), '\s+', ' ', 'g')) <> lower(regexp_replace(btrim(nome_scientifico), '\s+', ' ', 'g')))),
      ('alternativi', (select count(*) from public.specie s, regexp_split_to_table(s.nomi_alternativi, ' \| ') x
                        where s.specie_padre_id is null and s.nomi_alternativi is not null and s.nomi_alternativi <> ''))
    ) x(voce, trovati) loop
    atteso := current_setting('fase4c.' || v.voce)::bigint;
    if v.trovati <> atteso then raise exception 'inventario dei nomi, %: % invece di %', v.voce, v.trovati, atteso; end if;
  end loop;
  -- 2. regole
  select count(*) into n from (select taxon_id, lingua, lower(regexp_replace(btrim(nome), '\s+', ' ', 'g'))
                                 from public.nomi_comuni group by 1, 2, 3 having count(*) > 1) x;
  if n > 0 then raise exception 'nomi ripetuti sullo stesso taxon a meno delle maiuscole: %', n; end if;
  select count(*) into n from public.nomi_comuni where preferito and (lingua <> 'it' or fonti = array['pfaf']);
  if n > 0 then raise exception 'preferiti inglesi o solo PFAF: %', n; end if;
  select count(*) into n from public.nomi_comuni where nome <> btrim(nome, E' \t\n ') or nome ~ '\s\s';
  if n > 0 then raise exception 'nomi con spazi ai bordi o doppi: %', n; end if;
  select count(*) into n from unnest(array['nomi_comuni_unico', 'nomi_comuni_preferito_idx', 'nomi_comuni_nome_trgm_idx']) i
   where to_regclass('public.' || i) is null;
  if n > 0 then raise exception 'indici di nomi_comuni mancanti: %', n; end if;
  if has_column_privilege('anon', 'public.nomi_comuni', 'fonti', 'select') or has_column_privilege('anon', 'public.nomi_comuni', 'nota', 'select')
     or has_column_privilege('authenticated', 'public.nomi_comuni', 'fonti', 'select') or has_column_privilege('authenticated', 'public.nomi_comuni', 'nota', 'select')
     or not has_column_privilege('anon', 'public.nomi_comuni', 'nome', 'select') or not has_column_privilege('authenticated', 'public.nomi_comuni', 'preferito', 'select')
     or has_table_privilege('anon', 'public.nomi_comuni', 'insert') or has_table_privilege('authenticated', 'public.nomi_comuni', 'update') then
    raise exception 'permessi di nomi_comuni inattesi';
  end if;
  -- 3. inventario della fase 4: nessuna riga di specie senza un posto
  select count(*) into n from public.specie s
   where s.specie_padre_id is null and s.nome_scientifico !~ ''''
     and not exists (select 1 from public.mappa_specie m where m.vecchia_specie_id = s.id);
  if n > 0 then raise exception 'inventario fase 4: righe madri senza riga di mappa: %', n; end if;
  select count(*) into n from public.specie s
   where s.nome_scientifico ~ ''''
     and not exists (select 1 from public.cultivar c where c.vecchia_specie_id = s.id)
     and not exists (select 1 from public.mappa_specie m where m.vecchia_specie_id = s.id);
  if n > 0 then raise exception 'inventario fase 4: righe di cultivar senza cultivar né riga di mappa: %', n; end if;
  select count(*) into n from public.specie s
   where (s.specie_padre_id is null or s.descrizione is not null) and not exists (select 1 from public.schede h where h.vecchia_specie_id = s.id);
  if n > 0 then raise exception 'inventario fase 4: righe con contenuto senza scheda: %', n; end if;
  raise notice 'nomi_comuni: % (preferiti %, italiani % di cui solo COL %, inglesi %); inventario dei nomi uguale ai file; fase 4: specie % righe, mappa %, cultivar %, schede % (mostrate %)',
    current_setting('fase4c.righe'), current_setting('fase4c.preferiti'),
    current_setting('fase4c.nostri')::bigint + current_setting('fase4c.solo_col')::bigint, current_setting('fase4c.solo_col'), current_setting('fase4c.inglesi'),
    (select count(*) from public.specie), (select count(*) from public.mappa_specie), (select count(*) from public.cultivar),
    (select count(*) from public.schede), (select count(*) from public.schede where mostrata);
end $$;
```

`scripts/tassonomia/rollback_fase4c.sql`:

```sql
-- Rollback della fase 4c: toglie tutti i nomi comuni. Si rifiuta se un nome è stato aggiunto dopo il caricamento (un
-- creato_il diverso da quello delle righe caricate, che entrano tutte nella stessa transazione: fasi successive, app o
-- /zorbadice), perché quel lavoro andrebbe perso. Con più lotti, i creato_il distinti sono al più uno per lotto.
-- Non TRUNCATE, per coerenza con gli altri rollback.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -v lotti=N -f scripts/tassonomia/rollback_fase4c.sql   (N = righe del manifesto)
-- Poi, per restituire lo spazio: psql "$URL" -X -c 'vacuum full public.nomi_comuni'
select set_config('fase4c.lotti', :'lotti', false) \g /dev/null
set local statement_timeout = '10min';
do $$
begin
  if (select count(distinct creato_il) from public.nomi_comuni) > current_setting('fase4c.lotti')::int then
    raise exception 'Rollback fase 4c rifiutato: alcuni nomi sono stati aggiunti dopo il caricamento';
  end if;
end $$;
delete from public.nomi_comuni;
```

```bash
chmod +x scripts/tassonomia/nomi_esporta.sh scripts/tassonomia/carica_nomi.sh
bash scripts/tassonomia/nomi_esporta.sh "$COPIA" "$F4/esporta_nomi"
```

Expected: `nomi_01.csv 18595` e l'inventario `nomi_specie_principali 3178`, `nomi_specie_alternativi 7845`, `preferiti 2777`, `inglesi 8042`, `italiani_solo_col 953`, `italiani_nostri 9600`.

- [ ] **Step 4: Lanciare le prove due volte di fila**

Prima del secondo giro i nomi vanno tolti, perché le prove partono da `nomi_comuni` vuota.

```bash
torna4c() { $PG/psql "$COPIA" -X -1 -q -v ON_ERROR_STOP=1 -v lotti=1 -f scripts/tassonomia/rollback_fase4c.sql && $PG/psql "$COPIA" -X -q -c 'vacuum full public.nomi_comuni'; }
bash scripts/tassonomia/prova_fase4c.sh "$COPIA" "$F4/esporta_nomi" "$SCRATCH/prove_fase4c_1" > "$SCRATCH/prove_fase4c_1.log" 2>&1; echo "giro 1 uscita $?"; grep -E '^PROV' "$SCRATCH/prove_fase4c_1.log"
torna4c
bash scripts/tassonomia/prova_fase4c.sh "$COPIA" "$F4/esporta_nomi" "$SCRATCH/prove_fase4c_2" > "$SCRATCH/prove_fase4c_2.log" 2>&1; echo "giro 2 uscita $?"; grep -E '^PROV' "$SCRATCH/prove_fase4c_2.log"
grep -h 'NOTICE:  nomi' "$SCRATCH/prove_fase4c_1/r7.log"; grep -h 'WAL' "$SCRATCH/prove_fase4c_1/r7/tempi.txt"
$PG/psql "$COPIA" -X -qAt -c "select 'nomi_comuni ' || round(pg_total_relation_size('public.nomi_comuni') / 1e6, 1) || ' MB'"
shasum -a 256 "$F4/esporta_nomi/manifest.tsv"
```

Expected:
- per tutti e due i giri `uscita 0`, poi `PROVA rifiuti OK`, `PROVA alterato OK`, `PROVA ripresa OK`, `PROVA rilancio OK`, `PROVA rollback_4a OK`, `PROVA rollback OK`, `PROVE FASE 4C OK`;
- la NOTICE `nomi_comuni: 18595 (preferiti 2777, italiani 10553 di cui solo COL 953, inglesi 8042); inventario dei nomi uguale ai file; fase 4: specie 212066 righe, mappa 16023, cultivar 196303, schede 15770 (mostrate 14507)`;
- WAL sotto 50 MB (sul prototipo 7,2 e 0,6 MB);
- `nomi_comuni 6.8 MB`.

Annotare nel registro lo sha256 del manifesto: il Task 3 lo confronta.

- [ ] **Step 5: Prove di mutazione**

```bash
muta() {  # muta FILE ESPRESSIONE_SED NOME
  cp "$1" "$SCRATCH/mutazione.bak"; sed -i '' "$2" "$1"
  cmp -s "$1" "$SCRATCH/mutazione.bak" && echo "MUTAZIONE $3 NON APPLICATA"
  torna4c > /dev/null 2>&1
  bash scripts/tassonomia/prova_fase4c.sh "$COPIA" "$F4/esporta_nomi" "$SCRATCH/mut4c_$3" > "$SCRATCH/mut4c_$3.log" 2>&1
  echo "mutazione $3: uscita $? — $(grep -E 'FALLITA' "$SCRATCH/mut4c_$3.log" | head -1 | cut -c1-90)"
  cp "$SCRATCH/mutazione.bak" "$1"
}
muta scripts/tassonomia/carica_nomi.sh 's/\[ "$(shasum -a 256 "$NC\/$file" | cut -d. . -f1)" = "$sha" \]/true/' sha
muta scripts/tassonomia/carica_nomi.sh 's/^  if caricato "$primo"; then tempo "$file già caricato"; continue; fi$/  :/' rilancio
muta scripts/tassonomia/rollback_fase4c.sql 's/raise exception .Rollback fase 4c rifiutato.*;/null;/' rifiuto_4c
muta scripts/tassonomia/rollback_fase4a.sql 's/ or exists (select 1 from public.nomi_comuni)$//' rifiuto_4a
torna4c > /dev/null 2>&1
bash scripts/tassonomia/prova_fase4c.sh "$COPIA" "$F4/esporta_nomi" "$SCRATCH/prove_fase4c_finale" > "$SCRATCH/prove_fase4c_finale.log" 2>&1; echo "uscita $?"; tail -1 "$SCRATCH/prove_fase4c_finale.log"
git status --short scripts/tassonomia/
```

Expected:
- nessuna riga `NON APPLICATA`;
- `mutazione sha: … PROVA alterato FALLITA`;
- `mutazione rilancio: … PROVA rilancio FALLITA`;
- `mutazione rifiuto_4c: … PROVA rollback FALLITA`;
- `mutazione rifiuto_4a: … PROVA rollback_4a FALLITA`;
- infine `uscita 0` e `PROVE FASE 4C OK` (la copia resta con i nomi caricati);
- `git status` mostra solo i 5 file nuovi di questo task (`rollback_fase4a.sql` ripristinato).

- [ ] **Step 6: Commit**

```bash
git add scripts/tassonomia/prova_fase4c.sh scripts/tassonomia/nomi_esporta.sh scripts/tassonomia/carica_nomi.sh \
        scripts/tassonomia/verifica_fase4c.sql scripts/tassonomia/rollback_fase4c.sql
git commit -m "Tassonomia fase 4c: esportazione, caricamento, verifica con l'inventario della fase 4 e rollback dei nomi comuni"
```

**Prima del Task 3:** revisione dei commit dei Task 1–2 da parte di un revisore nuovo (vedi Global Constraints), con le note scritte in un file mentre lavora. Le correzioni importanti si fanno con una prova che fallisce prima. Se cambiano i file esportati, si rigenera l'esportazione in una cartella nuova, si rilanciano le prove e si annota il nuovo sha256.

---

### Task 3: Caricamento sul database reale e documentazione

**Files:**
- Modify: `CLAUDE.md` (sezione "Modello tassonomico")

**Interfaces:**
- Consumes: `$F4/esporta_nomi` (Task 2) con lo sha256 annotato; `carica_nomi.sh`, `verifica_fase4c.sql`, `rollback_fase4c.sql`.

- [ ] **Step 1: Backup e controlli di partenza (solo letture)**

```bash
set -a; source .env.local; set +a
python3 -c 'import os, urllib.parse; print("porta", urllib.parse.urlsplit(os.environ["SUPABASE_DB_URL"]).port)'
BK=backups/completo_$(date +%Y%m%d_%H%M%S)_pre_fase4c.dump; echo "BK=$BK"
$PG/pg_dump "$SUPABASE_DB_URL" -Fc -f "$BK"
$PG/psql "$SUPABASE_DB_URL" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/impronta_specie.sql > "${BK%.dump}.impronta.txt"
$PG/pg_restore -f /dev/null "$BK" && echo BACKUP LEGGIBILE
diff backups/completo_20261020_114525_pre_fase4b.impronta.txt "${BK%.dump}.impronta.txt" && echo "SPECIE COME NELLA COPIA"
$PG/psql "$SUPABASE_DB_URL" -X -q -f scripts/tassonomia/controlli_spazio.sql
Q3="select count(*) || ' ' || md5(string_agg(id::text || '|' || coalesce(taxon_id::text, '') || '|' || coalesce(cultivar_id::text, '') || '|' || mostrata::text, ',' order by id)) from public.schede"
$PG/psql "$SUPABASE_DB_URL" -X -qAt -c "$Q3" -c "select 'nomi_comuni ' || count(*) from public.nomi_comuni"
shasum -a 256 "$F4/esporta_nomi/manifest.tsv"
```

Expected:
- `porta 5432`; se è diversa, fermarsi;
- `BACKUP LEGGIBILE` e `SPECIE COME NELLA COPIA`. Se no, fermarsi: i nomi da cui si parte sono cambiati;
- `somma_db_mb` circa 397, `wal_mb` sotto 300;
- `15770 08de8773c09d1496b8cc704c98fb7356` (come la copia) e `nomi_comuni 0`;
- lo sha256 uguale a quello annotato nel Task 2. Se no, fermarsi.

- [ ] **Step 2: Via esplicito dell'utente**

Chiedere in chat il via, dicendo:
- **cosa entra:** 18.595 nomi comuni (10.553 italiani, 8.042 inglesi), 2.777 preferiti, con le decisioni del 20/10;
- **durata:** circa 11 minuti, di cui 10 di pausa voluta prima dell'indice;
- **effetto sull'app:** nessuno, perché l'app non legge ancora queste tabelle;
- **spazio:** circa 7 MB in più, fino a circa 404 MB su 500 (soglia degli script 420, approvata);
- **dati:** non cambia niente fuori da `nomi_comuni`; l'impronta di `specie` si confronta prima e dopo;
- **ripresa:** se si interrompe basta rilanciare lo stesso comando;
- **rollback:** pronto e provato (`rollback_fase4c.sql`).

Senza un sì esplicito ci si ferma qui.

- [ ] **Step 3: Caricare**

Va lanciato dalla sessione principale in background (`run_in_background`), da uno script che imposta da sé `PG`, `F4` e `BK` (in background ogni chiamata è una shell nuova) e che prima confronta lo sha256 del manifesto con quello annotato. Se il controllo dei permessi lo blocca, dare all'utente lo stesso blocco da incollare nel suo terminale. Per sapere se è attivo usare `pgrep -f carica_`, che stampa solo il pid. Se tra lo Step 1 e lo Step 3 è passato molto tempo, prima di lanciare rifare l'impronta di `specie` e il confronto dello Step 1.

```bash
set -a; source .env.local; set +a
OUT=backups/fase4c_$(date +%Y%m%d_%H%M%S)
CONFERMO_CARICAMENTO_REALE=si bash scripts/tassonomia/carica_nomi.sh "$SUPABASE_DB_URL" "$F4/esporta_nomi" "$OUT" > "$OUT.log" 2>&1; echo "uscita $?"
diff "${BK%.dump}.impronta.txt" "$OUT/impronta_specie_prima.txt" && diff "${BK%.dump}.impronta.txt" "$OUT/impronta_specie_dopo.txt" && echo "SPECIE INVARIATA DALLO STEP 1"
```

Expected:
- `uscita 0`;
- in `$OUT.log` la NOTICE `nomi_comuni: 18595 (preferiti 2777, italiani 10553 di cui solo COL 953, inglesi 8042); inventario dei nomi uguale ai file; fase 4: …` e `CARICAMENTO NOMI OK`;
- `SPECIE INVARIATA DALLO STEP 1`;
- somma dei database circa 404 MB.

Se l'uscita non è 0, prima di tutto (sola lettura) `controlli_spazio.sql` e i conteggi dello Step 1. Poi:
- **`FERMATO: spazio insufficiente`, interruzione o connessione persa:** rilanciare lo stesso comando, che salta i passi fatti;
- **`RIFIUTATO`:** non è stato scritto niente; riferire;
- **`FALLITO: specie è cambiata` o un errore della verifica:** fermarsi e riferire. Il rollback si decide insieme: `rollback_fase4c.sql` con `psql -1 -v lotti=1`, poi `vacuum full public.nomi_comuni`.

- [ ] **Step 4: Controlli finali**

```bash
set -a; source .env; source .env.local; set +a
curl -s -o /dev/null -w 'nomi con la chiave pubblica: %{http_code}\n' "$VITE_SUPABASE_URL/rest/v1/nomi_comuni?select=nome,lingua,preferito&preferito=eq.true&limit=1" \
  -H "apikey: $VITE_SUPABASE_ANON_KEY" -H "Authorization: Bearer $VITE_SUPABASE_ANON_KEY"
curl -s -o /dev/null -w 'fonti dei nomi con la chiave pubblica: %{http_code}\n' "$VITE_SUPABASE_URL/rest/v1/nomi_comuni?select=fonti&limit=1" \
  -H "apikey: $VITE_SUPABASE_ANON_KEY" -H "Authorization: Bearer $VITE_SUPABASE_ANON_KEY"
curl -s -o /dev/null -w 'nota dei nomi con la chiave pubblica: %{http_code}\n' "$VITE_SUPABASE_URL/rest/v1/nomi_comuni?select=nota&limit=1" \
  -H "apikey: $VITE_SUPABASE_ANON_KEY" -H "Authorization: Bearer $VITE_SUPABASE_ANON_KEY"
$PG/psql "$SUPABASE_DB_URL" -X -qAt -c 'show statement_timeout' -c 'show lock_timeout'
```

Expected:
- `nomi con la chiave pubblica: 200`;
- `fonti dei nomi con la chiave pubblica: 401` e `nota dei nomi con la chiave pubblica: 401`;
- `2min` e `0`.

- [ ] **Step 5: CLAUDE.md**

1. La copia locale resta accesa: le fasi successive la usano.
2. In `CLAUDE.md`, il titolo "### Modello tassonomico (in corso, fasi 1, 1b, 2, 3, 4a e 4b di 7 applicate)" diventa "### Modello tassonomico (in corso, fasi 1-4 di 7 applicate)" e in fondo alla sezione va aggiunto questo paragrafo, con le misure reali al posto di quelle attese se diverse:

```markdown
La fase 4c (piano `docs/superpowers/plans/2026-10-20-modello-tassonomico-fase4c-nomi.md`) ha caricato `nomi_comuni` e chiuso la fase 4: 18.595 nomi comuni (10.553 italiani, 8.042 inglesi di PFAF, mai preferiti) su 7.366 taxon, 2.777 preferiti.
- **Da dove vengono:** i nomi italiani delle righe madri di `specie` (nome principale e `nomi_alternativi`), con le fonti ricostruite dalle migration dei lotti (`nomi_provenienza.py`: `wikidata`, `plantnet`, `inaturalist`, `eppo`, `gbif`, `curatore`, `catalogo`); i nomi dei generi scelti dall'utente (`curatore`); i nomi italiani di Catalogue of Life sui taxon di `taxa` (fonte `col:…` in più sui nomi uguali, 953 nomi nuovi mai preferiti salvo scelta dell'utente).
- **Regole:** destinazione all'accettato (autonimo → specie; righe salite di rango e righe «Genere spp.» con un vecchio binomio come la decisione 20), preferito come la decisione 21, un nome una volta sola per taxon e lingua a meno delle maiuscole, esclusi i nomi uguali al nome scientifico (salvo `generi.nome`).
- **Decisioni dell'utente del 20/10/2026** (pagina privata https://claude.ai/artifact/Y9y9RTPGu82Epc1nC43MN4, «approvo tutte»): 913 nomi tolti (soprattutto nomi di sola fonte PlantNet letti uno per uno: volgari, non-nomi, altre lingue, nomi di altre piante, refusi; un nome tolto per una pianta non rientra da COL), 25 correzioni del testo, 13 preferiti scelti (Banano per *Musa acuminata*, Alisso marittimo, Arancio, Fragola, Kumquat, Kenzia, Bambù della fortuna, Falenopside, Vetriola di Soleirol; nessun preferito per Zamioculcas, *Euphorbia trigona* e *Lampranthus*). I file sono in `scripts/tassonomia/dati/fase4_nomi_*.tsv`.
- **Inventario della fase 4:** `verifica_fase4c.sql` ricontrolla sul reale i nomi di partenza (3.178 principali e 7.845 alternativi), i nomi per origine e che ogni riga di `specie` abbia il suo posto (mappa, cultivar o scheda).
- **Spazio:** circa 404 MB su 500 (soglia degli script portata a 420 per questa fase, con l'approvazione dell'utente); WAL 7,2 MB per un lotto. Backup preso prima: il file `$BK` dello Step 1 (`backups/completo_…_pre_fase4c.dump`).
- **Script, tutti in `scripts/tassonomia/`:** `nomi_provenienza.py`, `nomi_proposte.sh`, `nomi_proposte.sql` e `prova_nomi.sql` (copia locale); `nomi_esporta.sh`, `carica_nomi.sh`, `verifica_fase4c.sql`, `rollback_fase4c.sql` (rifiutato se un nome è stato aggiunto dopo il caricamento; con `-v lotti=1`).
- **Prove:** `bash scripts/tassonomia/prova_fase4c.sh URL_COPIA CARTELLA_ESPORTA CARTELLA`, su una copia con la fase 4b e `nomi_comuni` vuota.
```

- [ ] **Step 6: Commit**

```bash
git add CLAUDE.md
git commit -m "Tassonomia fase 4c applicata: nomi comuni (18.595, 2.777 preferiti) e fine della fase 4, CLAUDE.md"
```

Nessun push senza richiesta dell'utente.
