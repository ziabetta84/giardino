#!/usr/bin/env python3
"""Esporta le righe `specie` con inglese residuo (in `descrizione` e/o `alert`) da
tradurre e naturalizzare via Anthropic Message Batches API.

Uso:
  python3 export_rows.py --source rhs --limit 25 --out prototipo.json
  python3 export_rows.py --source hidden --out lotto_hidden.json
  python3 export_rows.py --source all --out tutto.json
"""
import argparse
from pathlib import Path

from common import load_env, run_psql_json, save_json

# Stessa regex di scoping usata oggi in sessione interattiva, con l'aggiunta del
# falso positivo "International Plant Name(s) Index" già escluso a monte qui
# (non serve più segnalarlo come falso positivo a valle).
HIDDEN_ENGLISH_COND = r"""(
    (descrizione ~* '\mthe\M' or descrizione ~* '\mis a\M' or descrizione ~* '\mis an\M'
    or descrizione ~* '\mand\M' or descrizione ~* '\mwith\M' or descrizione ~* '\mfrom\M'
    or descrizione ~* '\mthis\M' or descrizione ~* '\mwhich\M' or descrizione ~* '\mits\M'
    or descrizione ~* '\mhas\M' or descrizione ~* '\mwas\M' or descrizione ~* '\mare\M'
    or descrizione ~* '\mfound\M' or descrizione ~* '\mnative\M' or descrizione ~* '\mgrowing\M'
    or descrizione ~* '\mspecies\M' or descrizione ~* '\mplant\M' or descrizione ~* '\mused\M'
    or descrizione ~* '\mcultivated\M' or descrizione ~* '\mcommonly\M')
    and descrizione not ilike '%International Plant Name%'
)"""

HIDDEN_QUERY = f"""
    specie_padre_id is null
    and descrizione is not null
    and descrizione not ilike '%testo originale in inglese%'
    and not (array_to_string(fonti,'|') ilike '%enciclopedia%' or array_to_string(fonti,'|') ilike '%edicart%'
             or array_to_string(fonti,'|') ilike '%tutto per il giardino%' or array_to_string(fonti,'|') ilike '%orchidee%')
    and {HIDDEN_ENGLISH_COND}
"""

# Il blocco RHS marcato ha inglese anche in `alert` (parassiti/malattie/potatura/
# propagazione/rischi, marcati "testo originale in inglese, non tradotto..."),
# non solo in `descrizione` — vedi common.py e le regole nel system prompt di
# submit_write_batch.py, che traduce anche quelle voci.
RHS_QUERY = """
    specie_padre_id is null
    and descrizione ilike '%testo originale in inglese%'
"""

SOURCES = {"hidden": HIDDEN_QUERY, "rhs": RHS_QUERY, "all": f"({HIDDEN_QUERY}) or ({RHS_QUERY})"}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", choices=SOURCES, default="rhs")
    parser.add_argument("--limit", type=int, default=None, help="per un prototipo su un campione casuale")
    parser.add_argument("--out", default="export.json")
    args = parser.parse_args()

    load_env()
    where = SOURCES[args.source]
    order_limit = f"order by random() limit {args.limit}" if args.limit else "order by slug"
    query = f"""
        select json_agg(row_to_json(t)) from (
          select id, slug, nome, famiglia_botanica, ciclo_vitale, esigenze, alert, descrizione, fonti
          from specie
          where {where}
          {order_limit}
        ) t;
    """
    rows = run_psql_json(query) or []
    out_path = Path(args.out)
    save_json(out_path, rows)
    print(f"Esportate {len(rows)} righe in {out_path} (source={args.source}{f', limit={args.limit}' if args.limit else ''})")


if __name__ == "__main__":
    main()
