# Nomi italiani delle specie Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sostituire `specie.nome` con il nome comune italiano (da Wikidata) dove esiste una fonte affidabile, mostrando lo scientifico come sottotitolo.

**Architecture:** Script Python in `scripts/nomi-italiani/` (logica pura testata con `unittest`) che scarica i nomi da Wikidata, sceglie un nome per taxon con regole deterministiche e produce una migration SQL reversibile keyed per slug. L'app cambia poco: `nome` è già solo display; due viste ricevono il sottotitolo scientifico.

**Tech Stack:** Python 3 (stdlib), Wikidata SPARQL, Supabase (MCP `execute_sql`/`apply_migration`), Vue 3.

**Spec:** `docs/superpowers/specs/2026-10-04-nomi-italiani-design.md`

## Global Constraints

- Nessuna colonna nuova su `specie`; `slug` e `nome_scientifico` mai modificati.
- Si aggiornano solo righe con `nome = nome_scientifico` e `specie_padre_id is null` (righe curate e cultivar intoccabili).
- Nessun nome tradotto o inventato: solo nomi presenti su Wikidata (`P1843`, lingua `it`).
- Nome importato con maiuscola iniziale; i casi ambigui sono saltati ed elencati, mai indovinati.
- Rollback = `nome = nome_scientifico` sugli slug della migration.
- Contenuti e commenti in italiano; commit solo su richiesta dell'utente, branch dedicato (non `hero-striscia-dipinti-larghi`).
- Finire un lotto prima di applicarlo: revisione a campione obbligatoria.

## Review Focus

- Apici/virgolette nei nomi (es. "Erba dell'orso"): l'SQL generato deve escapare `'`.
- Stesso nome scientifico su più righe `specie` (omonimie): saltare e elencare, non aggiornarne una a caso.
- Nome Wikidata identico (case-insensitive) al nome scientifico: non è una traduzione, scartarlo.
- Nomi con cifre o fuori misura (>60 caratteri) o con `/`: scartati.
- Endpoint SPARQL lento o in timeout: lo script deve fallire con messaggio chiaro, non scrivere un CSV parziale.

---

## File Structure

- Create: `scripts/nomi-italiani/nomi.py` — logica pura (scelta nome, normalizzazione, join con righe DB, generazione SQL).
- Create: `scripts/nomi-italiani/test_nomi.py` — test `unittest` della logica pura.
- Create: `scripts/nomi-italiani/scarica_wikidata.py` — fetch SPARQL e scrittura CSV candidati.
- Create: `supabase/migrations/<timestamp>_nomi_italiani_lotto1.sql` — generata (Task 4).
- Modify: `src/components/PiantaRiga.vue` — tooltip scientifico.
- Modify: `src/views/PiantaView.vue` — sottotitolo scientifico.
- Modify: `CLAUDE.md` — convenzione `nome`/`nome_scientifico`.

---

### Task 1: Logica pura di scelta del nome

**Files:**
- Create: `scripts/nomi-italiani/nomi.py`
- Test: `scripts/nomi-italiani/test_nomi.py`

**Interfaces:**
- Produces:
  - `normalizza_nome(nome: str) -> str | None` — strip, spazi singoli, maiuscola iniziale; `None` se contiene cifre, `/`, o è vuoto/ >60 caratteri.
  - `scegli_nome(sci: str, candidati: list[dict]) -> tuple[str | None, str]` — candidati = `{"nome": str, "rank": "preferred"|"normal"|"deprecated", "itwiki": str | None}`; ritorna `(nome, criterio)` con criterio in `unico|preferito|itwiki|ambiguo|nessuno`.

- [ ] **Step 1: Scrivere i test che falliscono**

```python
# scripts/nomi-italiani/test_nomi.py
import unittest
from nomi import normalizza_nome, scegli_nome


def c(nome, rank="normal", itwiki=None):
    return {"nome": nome, "rank": rank, "itwiki": itwiki}


class TestNormalizza(unittest.TestCase):
    def test_maiuscola_e_spazi(self):
        self.assertEqual(normalizza_nome("  pianta   di giada "), "Pianta di giada")

    def test_scarta_cifre_slash_vuoto_lungo(self):
        self.assertIsNone(normalizza_nome("rosa 2000"))
        self.assertIsNone(normalizza_nome("a/b"))
        self.assertIsNone(normalizza_nome("  "))
        self.assertIsNone(normalizza_nome("x" * 61))

    def test_mantiene_apostrofo(self):
        self.assertEqual(normalizza_nome("erba dell'orso"), "Erba dell'orso")


class TestScegli(unittest.TestCase):
    def test_nessun_candidato(self):
        self.assertEqual(scegli_nome("Aloe rauhii", []), (None, "nessuno"))

    def test_unico(self):
        self.assertEqual(scegli_nome("Tectona grandis", [c("teak")]), ("Teak", "unico"))

    def test_scarta_uguale_allo_scientifico(self):
        self.assertEqual(scegli_nome("Aloe rauhii", [c("aloe rauhii")]), (None, "nessuno"))

    def test_scarta_deprecati(self):
        self.assertEqual(scegli_nome("X y", [c("foo", "deprecated")]), (None, "nessuno"))

    def test_preferito(self):
        cand = [c("soffione"), c("tarassaco", "preferred")]
        self.assertEqual(scegli_nome("Taraxacum officinale", cand), ("Tarassaco", "preferito"))

    def test_itwiki_quando_nessun_preferito(self):
        cand = [c("soffione"), c("tarassaco", itwiki="Taraxacum officinale")]
        cand[1]["itwiki"] = "Tarassaco (pianta)"
        self.assertEqual(scegli_nome("Taraxacum officinale", cand), ("Tarassaco", "itwiki"))

    def test_ambiguo(self):
        cand = [c("soffione"), c("tarassaco")]
        self.assertEqual(scegli_nome("Taraxacum officinale", cand), (None, "ambiguo"))

    def test_due_preferiti_sono_ambigui(self):
        cand = [c("a", "preferred"), c("b", "preferred")]
        self.assertEqual(scegli_nome("X y", cand), (None, "ambiguo"))

    def test_duplicati_case_insensitive_sono_unico(self):
        self.assertEqual(scegli_nome("X y", [c("Teak"), c("teak")]), ("Teak", "unico"))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Eseguire e verificare il fallimento**

Run: `cd scripts/nomi-italiani && python3 -m unittest test_nomi -v`
Expected: FAIL con `ModuleNotFoundError: No module named 'nomi'`

- [ ] **Step 3: Implementare**

```python
# scripts/nomi-italiani/nomi.py
"""Logica pura per importare i nomi comuni italiani da Wikidata in specie.nome."""
import re

MAX_LUNGHEZZA = 60


def normalizza_nome(nome):
    n = re.sub(r"\s+", " ", (nome or "").strip())
    if not n or len(n) > MAX_LUNGHEZZA or "/" in n or re.search(r"\d", n):
        return None
    return n[0].upper() + n[1:]


def _senza_parentesi(titolo):
    return re.sub(r"\s*\(.*?\)\s*$", "", titolo or "").strip()


def scegli_nome(sci, candidati):
    """Ritorna (nome, criterio). Criteri: unico, preferito, itwiki, ambiguo, nessuno."""
    unici = {}
    for cand in candidati:
        if cand["rank"] == "deprecated":
            continue
        n = normalizza_nome(cand["nome"])
        if n is None or n.lower() == sci.strip().lower():
            continue
        e = unici.setdefault(n.lower(), {"nome": n, "preferred": False, "itwiki": False})
        e["preferred"] = e["preferred"] or cand["rank"] == "preferred"
        titolo = _senza_parentesi(cand.get("itwiki")).lower()
        e["itwiki"] = e["itwiki"] or titolo == n.lower()
    voci = list(unici.values())
    if not voci:
        return None, "nessuno"
    if len(voci) == 1:
        return voci[0]["nome"], "unico"
    for campo, criterio in (("preferred", "preferito"), ("itwiki", "itwiki")):
        scelti = [v for v in voci if v[campo]]
        if len(scelti) == 1:
            return scelti[0]["nome"], criterio
    return None, "ambiguo"
```

- [ ] **Step 4: Eseguire e verificare che passi**

Run: `cd scripts/nomi-italiani && python3 -m unittest test_nomi -v`
Expected: tutti PASS. Nota: `test_itwiki_quando_nessun_preferito` assegna `itwiki` al secondo candidato ("Tarassaco (pianta)") — il confronto toglie la parentesi e coincide con "tarassaco".

---

### Task 2: Join con le righe DB e generazione SQL

**Files:**
- Modify: `scripts/nomi-italiani/nomi.py`
- Modify: `scripts/nomi-italiani/test_nomi.py`

**Interfaces:**
- Consumes: output di `scegli_nome` (Task 1).
- Produces:
  - `abbina_slug(proposte: dict[str, str], righe_db: list[dict]) -> tuple[list[tuple[str, str]], list[str]]` — `proposte` = `{nome_scientifico_lower: nuovo_nome}`; `righe_db` = `{"slug", "nome_scientifico"}` già filtrate (`nome = nome_scientifico`, non cultivar); ritorna `(coppie (slug, nuovo_nome), omonimi_saltati)`.
  - `sql_str(s: str) -> str` — letterale SQL con apici raddoppiati.
  - `genera_migration(coppie: list[tuple[str, str]], lotto: str) -> tuple[str, str]` — `(sql_applica, sql_rollback)`.

- [ ] **Step 1: Aggiungere i test che falliscono**

```python
# in test_nomi.py (aggiungere gli import: abbina_slug, sql_str, genera_migration)
class TestAbbina(unittest.TestCase):
    def test_abbina_per_scientifico_case_insensitive(self):
        righe = [{"slug": "taraxacum-officinale", "nome_scientifico": "Taraxacum officinale"}]
        coppie, saltati = abbina_slug({"taraxacum officinale": "Tarassaco"}, righe)
        self.assertEqual(coppie, [("taraxacum-officinale", "Tarassaco")])
        self.assertEqual(saltati, [])

    def test_omonimi_saltati(self):
        righe = [
            {"slug": "a-b", "nome_scientifico": "A b"},
            {"slug": "a-b-2", "nome_scientifico": "A b"},
        ]
        coppie, saltati = abbina_slug({"a b": "Nome"}, righe)
        self.assertEqual(coppie, [])
        self.assertEqual(saltati, ["A b"])

    def test_riga_senza_proposta_ignorata(self):
        coppie, saltati = abbina_slug({}, [{"slug": "x", "nome_scientifico": "X y"}])
        self.assertEqual((coppie, saltati), ([], []))


class TestSql(unittest.TestCase):
    def test_apici_raddoppiati(self):
        self.assertEqual(sql_str("Erba dell'orso"), "'Erba dell''orso'")

    def test_migration_e_rollback(self):
        up, down = genera_migration([("rosmarino-x", "Rosmarino"), ("a-b", "Erba d'a")], "lotto1")
        self.assertIn("update specie s set nome = v.nome", up)
        self.assertIn("('rosmarino-x', 'Rosmarino')", up)
        self.assertIn("('a-b', 'Erba d''a')", up)
        self.assertIn("s.nome = s.nome_scientifico", up)
        self.assertIn("s.specie_padre_id is null", up)
        self.assertIn("set nome = nome_scientifico", down)
        self.assertIn("'rosmarino-x'", down)
        self.assertNotIn("Rosmarino", down)
```

- [ ] **Step 2: Eseguire e verificare il fallimento**

Run: `cd scripts/nomi-italiani && python3 -m unittest test_nomi -v`
Expected: FAIL con `ImportError: cannot import name 'abbina_slug'`

- [ ] **Step 3: Implementare**

```python
# in nomi.py (aggiungere)
from collections import defaultdict


def abbina_slug(proposte, righe_db):
    per_sci = defaultdict(list)
    for r in righe_db:
        per_sci[r["nome_scientifico"].strip().lower()].append(r)
    coppie, saltati = [], []
    for chiave, righe in per_sci.items():
        if chiave not in proposte:
            continue
        if len(righe) > 1:
            saltati.append(righe[0]["nome_scientifico"])
            continue
        coppie.append((righe[0]["slug"], proposte[chiave]))
    return sorted(coppie), sorted(saltati)


def sql_str(s):
    return "'" + s.replace("'", "''") + "'"


def genera_migration(coppie, lotto):
    valori = ",\n  ".join(f"({sql_str(slug)}, {sql_str(nome)})" for slug, nome in coppie)
    up = (
        f"-- Nomi italiani ({lotto}): sostituisce nome con il nome comune italiano da Wikidata.\n"
        "-- Solo righe ancora senza nome italiano (nome = nome_scientifico) e non cultivar.\n"
        "update specie s set nome = v.nome\n"
        f"from (values\n  {valori}\n) as v(slug, nome)\n"
        "where s.slug = v.slug\n"
        "  and s.nome = s.nome_scientifico\n"
        "  and s.specie_padre_id is null;\n"
    )
    slugs = ", ".join(sql_str(slug) for slug, _ in coppie)
    down = (
        f"-- Rollback {lotto}: ripristina nome = nome_scientifico\n"
        f"update specie set nome = nome_scientifico where slug in ({slugs});\n"
    )
    return up, down
```

- [ ] **Step 4: Eseguire e verificare che passi**

Run: `cd scripts/nomi-italiani && python3 -m unittest test_nomi -v`
Expected: tutti PASS

---

### Task 3: Download Wikidata e CSV candidati

**Files:**
- Create: `scripts/nomi-italiani/scarica_wikidata.py`

**Interfaces:**
- Consumes: `scegli_nome` (Task 1).
- Produces: due file in `scripts/nomi-italiani/out/` (cartella già ignorata o da aggiungere a `.gitignore`): `proposte.csv` (colonne `nome_scientifico,nuovo_nome,criterio`) e `ambigui.csv` (colonne `nome_scientifico,candidati`).

- [ ] **Step 1: Scrivere lo script**

```python
# scripts/nomi-italiani/scarica_wikidata.py
"""Scarica i nomi comuni italiani da Wikidata e propone un nome per taxon."""
import csv
import json
import sys
import urllib.parse
import urllib.request
from collections import defaultdict
from pathlib import Path

from nomi import scegli_nome

ENDPOINT = "https://query.wikidata.org/sparql"
QUERY = """
SELECT ?sci ?nome ?rank ?itwiki WHERE {
  ?t wdt:P225 ?sci .
  ?t p:P1843 ?st . ?st ps:P1843 ?nome . ?st wikibase:rank ?rank .
  FILTER(LANG(?nome) = "it")
  OPTIONAL { ?w schema:about ?t ; schema:isPartOf <https://it.wikipedia.org/> ; schema:name ?itwiki . }
}
"""
OUT = Path(__file__).parent / "out"


def scarica():
    url = ENDPOINT + "?" + urllib.parse.urlencode({"query": QUERY})
    req = urllib.request.Request(url, headers={
        "User-Agent": "giardino-zorba/1.0 (nomi italiani)",
        "Accept": "application/sparql-results+json",
    })
    try:
        with urllib.request.urlopen(req, timeout=180) as r:
            return json.load(r)["results"]["bindings"]
    except Exception as e:  # nessun CSV parziale: si fallisce prima di scrivere
        sys.exit(f"Wikidata non ha risposto: {e}")


def main():
    righe = scarica()
    per_sci = defaultdict(list)
    for b in righe:
        rank = b["rank"]["value"].rsplit("#", 1)[-1].replace("Rank", "").lower()
        per_sci[b["sci"]["value"]].append({
            "nome": b["nome"]["value"],
            "rank": rank,
            "itwiki": b.get("itwiki", {}).get("value"),
        })
    OUT.mkdir(exist_ok=True)
    proposte, ambigui = [], []
    for sci, cand in sorted(per_sci.items()):
        nome, criterio = scegli_nome(sci, cand)
        if nome:
            proposte.append((sci, nome, criterio))
        elif criterio == "ambiguo":
            ambigui.append((sci, " | ".join(sorted({c["nome"] for c in cand}))))
    with open(OUT / "proposte.csv", "w", newline="") as f:
        w = csv.writer(f); w.writerow(["nome_scientifico", "nuovo_nome", "criterio"]); w.writerows(proposte)
    with open(OUT / "ambigui.csv", "w", newline="") as f:
        w = csv.writer(f); w.writerow(["nome_scientifico", "candidati"]); w.writerows(ambigui)
    print(f"{len(proposte)} proposte, {len(ambigui)} ambigui (da {len(per_sci)} taxa)")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Aggiungere `scripts/nomi-italiani/out/` a `.gitignore`**

- [ ] **Step 3: Eseguire**

Run: `cd scripts/nomi-italiani && python3 scarica_wikidata.py`
Expected: stampa `N proposte, M ambigui`; se Wikidata va in timeout esce con `Wikidata non ha risposto: ...` e **non** crea i CSV. Se va in timeout, riprovare dopo qualche minuto prima di cambiare approccio.

- [ ] **Step 4: Revisione a campione**

Run: `python3 -c "import csv,random;r=list(csv.reader(open('out/proposte.csv')))[1:];[print(x) for x in random.sample(r,40)]"`
Expected: leggere i 40 casi. Segnalare all'utente nomi che riguardano un genere o un gruppo più ampio della specie, o che non sono nomi di piante. Se la quota di casi dubbi supera ~10%, fermarsi e discutere con l'utente prima del Task 4.

---

### Task 4: Abbinare agli slug e applicare il lotto

**Files:**
- Create: `supabase/migrations/<timestamp>_nomi_italiani_lotto1.sql` (+ file rollback in `scripts/nomi-italiani/out/`)

**Interfaces:**
- Consumes: `proposte.csv` (Task 3), `abbina_slug`, `genera_migration` (Task 2).

- [ ] **Step 1: Estrarre dal DB le righe candidate, a lotti**

Per ogni lotto di ~500 nomi scientifici da `proposte.csv`, eseguire con `execute_sql` (progetto `ncuhhsvtjwcolhpdxbkt`):

```sql
select slug, nome_scientifico from specie
where lower(nome_scientifico) = any(array['taraxacum officinale', ...])
  and nome = nome_scientifico and specie_padre_id is null;
```

Salvare le righe restituite in `scripts/nomi-italiani/out/righe_db.json` (lista di `{"slug","nome_scientifico"}`).

- [ ] **Step 2: Generare migration e rollback**

```python
# esecuzione ad hoc da scripts/nomi-italiani/
import csv, json
from nomi import abbina_slug, genera_migration
proposte = {r["nome_scientifico"].lower(): r["nuovo_nome"] for r in csv.DictReader(open("out/proposte.csv"))}
righe = json.load(open("out/righe_db.json"))
coppie, saltati = abbina_slug(proposte, righe)
up, down = genera_migration(coppie, "lotto1")
open("../../supabase/migrations/20261004120000_nomi_italiani_lotto1.sql", "w").write(up)
open("out/rollback_lotto1.sql", "w").write(down)
print(len(coppie), "da aggiornare;", len(saltati), "omonimi saltati:", saltati[:10])
```

Expected: `N da aggiornare`; gli omonimi saltati vanno mostrati all'utente.

- [ ] **Step 3: Dry-run — contare senza scrivere**

```sql
select count(*) from specie where nome = nome_scientifico and specie_padre_id is null
  and slug in (<slug del lotto>);
```
Expected: uguale al numero di coppie. Se differisce, indagare prima di applicare.

- [ ] **Step 4: Applicare con approvazione dell'utente**

Mostrare all'utente il conteggio e 20 coppie a campione; **solo dopo il suo ok** applicare la migration con `apply_migration`.

- [ ] **Step 5: Verificare**

```sql
select count(*) filter (where nome <> nome_scientifico) from specie;  -- atteso: ~158 + N
select nome, nome_scientifico, slug from specie where slug in ('taraxacum-officinale','rosmarino');
```
Expected: slug invariati, righe curate invariate (stessi nomi di prima), nuove righe con nome italiano.

---

### Task 5: Sottotitolo scientifico nelle viste pianta

**Files:**
- Modify: `src/components/PiantaRiga.vue:13`
- Modify: `src/views/PiantaView.vue:46,63`

**Interfaces:**
- Consumes: `specie.specie` (nome scientifico, mappato da `mappaSpecie`) e `specie.nome`.

- [ ] **Step 1: PiantaRiga (vista densa → solo tooltip)**

Sostituire il blocco nome con:

```vue
<div class="pr__name" :title="specie && specie.specie && specie.specie !== specie.nome ? specie.specie : null">
  {{ specie?.nome ?? pianta.specie }}
</div>
```

- [ ] **Step 2: PiantaView (header)**

Aggiungere un computed accanto a quello che calcola `specie`:

```js
const nomeScientifico = computed(() => {
  const s = specie.value
  return s?.specie && s.specie !== s.nome ? s.specie : ''
})
```

e sotto entrambi gli `<h1>` (righe 46 e 63) la riga:

```vue
<p v-if="nomeScientifico" class="pname-sci">{{ nomeScientifico }}</p>
```

con stile in corsivo identico a `.dd-sci` di `SelettoreSpecie.vue` (stessi token colore/dimensione, `font-style: italic`).

- [ ] **Step 3: Verificare nel browser**

Run: `npm run dev`, aprire una pianta con nome italiano (es. Rosmarino) e una senza (nome scientifico).
Expected: la prima mostra "Rosmarino" + *Rosmarinus officinalis*; la seconda mostra solo il nome scientifico, senza sottotitolo duplicato. Controllare anche modalità scura e larghezza mobile.

---

### Task 6: Documentare la convenzione e controllare `/zorbadice`

**Files:**
- Modify: `CLAUDE.md` (sezione "Migrazione specie → Supabase")
- Verify: `.claude/commands/zorbadice.md`

- [ ] **Step 1: Aggiungere a CLAUDE.md**

Nella sezione specie, un paragrafo: `specie.nome` è il nome comune italiano quando disponibile (altrimenti coincide con `nome_scientifico`); fonte dei nomi importati: Wikidata (`P1843`), script in `scripts/nomi-italiani/`; la chiave resta lo slug; rollback per lotto in migration.

- [ ] **Step 2: Verificare `/zorbadice` → `identifica_specie` e `consiglio_*`**

Run: `grep -n "nome" .claude/commands/zorbadice.md | head -30`
Expected: nessuna istruzione che assuma `nome` = scientifico. Annotare eventuali punti da aggiornare e proporli all'utente.

---

## Self-Review

- **Copertura spec:** import da Wikidata → Task 3; regola nomi multipli → Task 1; righe curate e cultivar escluse → Task 2/4 (clausola SQL); reversibilità → Task 2/4; UI → Task 5 (il selettore mostra già lo scientifico e cerca su entrambi i campi, nessuna modifica); controllo usi di `nome` come chiave → già fatto in fase di piano: tutti gli usi (`GalleryView`, `AgenteView`, `useSuggerimentoIrrigazione`, `useRichiesteAgente`, `AttivitaView`, `IrrigazioneView`, `ConcimiView`) sono solo display via `store.specie[slug]`, nessuna modifica; `/zorbadice` → Task 6.
- **Placeholder:** nessuno; `<timestamp>` nel File Structure è risolto in Task 4 (`20261004120000`).
- **Coerenza tipi:** `scegli_nome`, `abbina_slug`, `genera_migration` usati con le stesse firme nei Task 1-4.
- **Lacune note:** nessun test automatico per le viste Vue (il progetto non ha framework JS di test): verifica manuale nel browser nel Task 5.
