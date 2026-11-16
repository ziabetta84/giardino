#!/usr/bin/env python3
"""Esporta il prossimo lotto di schede da tradurre e naturalizzare (issue #153) con esporta_schede.sql.

Il numero del lotto continua quello dei lotti su `specie` (lottoN_rhs.json, fino al 78): il primo lotto su `schede`
è stato il 79, il 28/10/2026.

Uso:
  python3 esporta_schede.py              # 70 schede -> lottoN_schede.json
  python3 esporta_schede.py --limite 30
  python3 esporta_schede.py --conta      # solo quante schede restano da fare
"""
import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

from common import HERE, load_env, run_psql_json, save_json

CONTA = r"""
select json_build_object(
  'da_fare', count(*) filter (where d or p or a),
  'descrizione_inglese', count(*) filter (where d or p),
  'solo_avvisi', count(*) filter (where a and not (d or p)))
from (select (s.descrizione_originale ilike '%testo originale in inglese%'
              and strpos(s.descrizione_originale, ': "' || left(regexp_replace(s.descrizione, '^Descrizione del genere: ', ''), 80)) > 0) d,
             s.descrizione ~* '\m(the|with|are|which|leaves|flowers)\M' p,
             exists (select 1 from unnest(s.alert) x where x ~ '\(testo in inglese\)' and x !~ '^Rischi \(testo in inglese\)') a
        from public.schede s where s.mostrata) t;
"""


def prossimo_lotto() -> int:
    numeri = [int(m.group(1)) for f in HERE.glob("lotto*_*.json") if (m := re.match(r"lotto(\d+)_", f.name))]
    return max(numeri, default=78) + 1


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--limite", type=int, default=70)
    p.add_argument("--conta", action="store_true")
    a = p.parse_args()
    load_env()
    if a.conta:
        print(json.dumps(run_psql_json(CONTA), ensure_ascii=False))
        return
    db_url = os.environ.get("SUPABASE_DB_URL") or sys.exit("Manca SUPABASE_DB_URL in .env.local")
    out = subprocess.run(["psql", db_url, "-X", "-t", "-A", "-v", f"limite={a.limite}", "-f", str(HERE / "esporta_schede.sql")],
                         capture_output=True, text=True, check=True).stdout.strip()
    righe = json.loads(out)
    n = prossimo_lotto()
    dest = HERE / f"lotto{n}_schede.json"
    save_json(dest, righe)
    print(f"Lotto {n}: {len(righe)} schede ({sum(r['mia'] for r in righe)} delle tue piante) in {dest.name}")


if __name__ == "__main__":
    main()
