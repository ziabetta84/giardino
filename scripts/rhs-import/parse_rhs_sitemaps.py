"""
Parsing incrementale delle pagine RHS scaricate in fonti/rhs_from_sitemaps/
da rhs_import_from_sitemaps.py (a differenza di fonti/rhs-varietà, qui il
sitemap copre *tutto* il catalogo RHS: centinaia di migliaia di pagine
potenziali, download ancora in corso e destinato a durare giorni).

Riusa lo stesso parser di parse_rhs.py (verificato: stesso template HTML,
stesse sezioni Position/Soil/Cultivation/Pruning/Pests/Diseases), ma con
un output adatto a questa scala:
- JSONL in streaming invece di un unico array JSON in memoria
- resumibile: ad ogni riesecuzione salta i file già presenti in output,
  quindi si puo' rilanciare periodicamente man mano che il download
  aggiunge nuove pagine, senza mai ripartire da zero
- parallelizzabile (il parsing e' CPU-bound via HTMLParser stdlib, nessuna
  richiesta di rete: niente rate limit a cui stare attenti come nel
  download)

Uso:
    python3 parse_rhs_sitemaps.py                  # tutti i file nuovi
    python3 parse_rhs_sitemaps.py --limit=500       # solo i primi 500 nuovi (test)
    python3 parse_rhs_sitemaps.py --workers=8       # default: os.cpu_count()
"""
import json, os, sys, time
from concurrent.futures import ProcessPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from parse_rhs import parse_file  # riusa lo stesso parser (stesso template RHS)

SRC_DIR = os.path.join(HERE, "..", "..", "fonti", "rhs_from_sitemaps")
OUT_FILE = os.path.join(HERE, "rhs_sitemaps_parsed.jsonl")
ERR_FILE = os.path.join(HERE, "rhs_sitemaps_errors.log")

FLUSH_EVERY = 500


def already_parsed():
    """Nomi file gia' presenti nell'output, per riprendere senza ripartire da zero."""
    done = set()
    if os.path.exists(OUT_FILE):
        with open(OUT_FILE, encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    done.add(json.loads(line)["file"])
                except (json.JSONDecodeError, KeyError):
                    continue
    return done


def parse_one(fn):
    path = os.path.join(SRC_DIR, fn)
    try:
        d = parse_file(path)
        # nome file = slug nell'URL rhs.org.uk (es. "abelia-chinensis-r-br"),
        # chiave piu' stabile del nome_scientifico_titolo per il match a valle
        d["rhs_url_slug"] = fn[:-5]
        return fn, d, None
    except Exception as e:
        return fn, None, str(e)


def main():
    limit = None
    workers = os.cpu_count() or 4
    for arg in sys.argv[1:]:
        if arg.startswith("--limit="):
            limit = int(arg.split("=", 1)[1])
        elif arg.startswith("--workers="):
            workers = int(arg.split("=", 1)[1])

    all_files = sorted(f for f in os.listdir(SRC_DIR) if f.lower().endswith(".html"))
    done = already_parsed()
    todo = [f for f in all_files if f not in done]
    if limit:
        todo = todo[:limit]

    print(f"Totale file nella sorgente: {len(all_files)}")
    print(f"Gia' parsati in precedenza: {len(done)}")
    print(f"Da parsare in questa run: {len(todo)} (workers={workers})")

    if not todo:
        return

    n_ok = 0
    n_err = 0
    t0 = time.time()
    with open(OUT_FILE, "a", encoding="utf-8") as out, \
         open(ERR_FILE, "a", encoding="utf-8") as err, \
         ProcessPoolExecutor(max_workers=workers) as pool:
        for i, (fn, d, e) in enumerate(pool.map(parse_one, todo, chunksize=50), 1):
            if e is not None:
                n_err += 1
                err.write(f"{fn}\t{e}\n")
            else:
                n_ok += 1
                out.write(json.dumps(d, ensure_ascii=False) + "\n")
            if i % FLUSH_EVERY == 0:
                out.flush()
                err.flush()
                elapsed = time.time() - t0
                rate = i / elapsed if elapsed > 0 else 0
                remaining = (len(todo) - i) / rate if rate > 0 else float("inf")
                print(f"  {i}/{len(todo)} parsati ({n_err} errori) — "
                      f"{rate:.1f} file/s, ~{remaining/60:.0f} min rimanenti")

    print(f"Fatto: {n_ok} ok, {n_err} errori in {(time.time()-t0)/60:.1f} min")
    print(f"Output: {OUT_FILE}")
    if n_err:
        print(f"Errori: {ERR_FILE}")


if __name__ == "__main__":
    main()
