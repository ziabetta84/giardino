"""CSV delle righe di genere usate, con la decisione proposta, da far rivedere all'utente."""
import csv
import subprocess

from genera_lotto3 import OUT
from generi_logica import genere_di, decisione, descrive_specie
from scarica_gbif_generi import db_url

Q = """
select s.slug, s.nome_scientifico, s.nome, coalesce(g.specie_gbif::text,''), coalesce(g.nome,''),
  (select count(*) from specie c where c.specie_padre_id = s.id),
  (select count(*) from piante p where p.specie = s.slug),
  regexp_replace(coalesce(left(s.descrizione, 400),''), E'[\\t\\r\\n]+', ' ', 'g')
from specie s left join generi g on g.id = s.genere_id
where s.specie_padre_id is null and s.slug !~ '-'
  and (exists (select 1 from specie c where c.specie_padre_id = s.id)
       or exists (select 1 from piante p where p.specie = s.slug))
order by s.slug
"""


def main():
    righe = subprocess.run(["psql", db_url(), "-At", "-F", "\t", "-c", Q], capture_output=True, text=True,
                           check=True).stdout.splitlines()
    out = []
    for r in righe:
        campi = r.split("\t")
        assert len(campi) == 8, f"riga con {len(campi)} campi: {campi[:2]}"
        slug, sci, nome, ngbif, nome_gen, ncult, npiante, descr = campi
        ns = int(ngbif) if ngbif else None
        out.append({"slug": slug, "nome_scientifico": sci, "nome": nome, "genere": genere_di(sci) or "",
                    "n_specie_gbif": ngbif, "decisione": decisione(ns, sci),
                    "descrive_specie": "sì" if descrive_specie(descr, sci) else "no",
                    "nome_genere_it": nome_gen if nome_gen != (genere_di(sci) or "") else "",
                    "n_cultivar": ncult, "n_piante": npiante})
    with open(OUT / "righe_genere_da_rivedere.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(out[0]))
        w.writeheader()
        w.writerows(out)
    from collections import Counter
    print(len(out), "righe;", dict(Counter(o["decisione"] for o in out)),
          "; descrivono la specie:", sum(1 for o in out if o["descrive_specie"] == "sì"))


if __name__ == "__main__":
    main()
