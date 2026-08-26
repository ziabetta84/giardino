import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from genera_sql import gen_block

PAIRS = [
    ("Anthriscus cerefolium", "anthriscus-cerefolium"),
    ("Atriplex halimus", "atriplex-halimus"),
    ("Borago officinalis", "borago-officinalis"),
    ("Carum carvi", "carum-carvi"),
    ("Coriandrum sativum", "coriandrum-sativum"),
    ("Foeniculum vulgare", "foeniculum-vulgare"),
    ("Hyssopus officinalis", "hyssopus-officinalis"),
    ("Melissa officinalis", "melissa-officinalis"),
    ("Mentha × piperita", "mentha-piperita"),
    ("Origanum majorana", "origanum-majorana"),
    ("Satureja hortensis", "satureja-hortensis"),
    ("Thymus vulgaris", "thymus-vulgaris"),
    ("Malva sylvestris", "malva-sylvestris"),
    ("Ananas comosus", "ananas-comosus"),
    ("Monstera deliciosa", "monstera-deliciosa"),
    ("Galanthus nivalis", "galanthus-nivalis"),
    ("Humulus lupulus", "humulus-lupulus"),
    ("Jasminum officinale", "jasminum-officinale"),
    ("Lathyrus odoratus", "lathyrus-odoratus"),
    ("Petunia × atkinsiana", "petunia-hybrida"),
    ("Cyperus papyrus", "cyperus-papyrus"),
    ("Schisandra grandiflora", "schisandra-grandiflora"),
    ("Phalaenopsis amabilis", "phalaenopsis-amabilis"),
    ("Phalaenopsis amboinensis", "phalaenopsis-amboinensis"),
    ("Phalaenopsis aphrodite", "phalaenopsis-aphrodite"),
    ("Phalaenopsis equestris", "phalaenopsis-equestris"),
    ("Phalaenopsis schilleriana", "phalaenopsis-schilleriana"),
    ("Phalaenopsis stuartiana", "phalaenopsis-stuartiana"),
    ("Phalaenopsis violacea", "phalaenopsis-violacea"),
]

header = """-- RHS Fase 5, batch 04: aromatiche/orto (Anthriscus, Atriplex, Borago,
-- Carum, Coriandrum, Foeniculum, Hyssopus, Melissa, Mentha, Origanum,
-- Satureja, Thymus, Malva), piante da appartamento/collezione (Ananas,
-- Monstera, Galanthus, Humulus, Jasminum, Lathyrus, Petunia, Cyperus,
-- Schisandra, Phalaenopsis). Stessa pipeline/convenzioni dei batch
-- precedenti (vedi scripts/rhs-import/README.md). Include anche 2 nuove
-- specie mai presenti in catalogo (Cyperus involucratus, Cheilanthes
-- maderensis), scritte a mano sotto perche' INSERT e non UPDATE.

"""

blocks = [header]
missing = []
for rhs_name, slug in PAIRS:
    b = gen_block(rhs_name, slug)
    if not b:
        missing.append((rhs_name, slug))
        continue
    blocks.append(b)

new_species_sql = """
-- CYPERUS INVOLUCRATUM -- specie nuova, nessuna riga esistente.
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Cyperus involucratus$t$,
  $t$Cyperus involucratus$t$,
  $t$cyperus-involucratus$t$,
  $t$Cyperaceae$t$,
  $t$perenne$t$,
  $t$Da RHS (testo originale in inglese): "An evergreen perennial forming a clump of erect stems to 60cm, ending in a whorl of dark green, grassy leafy bracts; flowers insignificant, yellowish-green".$t$,
  $t${"luce": "Pieno sole, mezz'ombra", "acqua": "Poco drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb,
  ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1C (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Cut back dead material in autumn"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed at 18 to 21°C in spring in constantly moist seed compost"$t$
  ],
  ARRAY[$t$RHS (rhs.org.uk) — Cyperus involucratus$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

-- CHEILANTHES MADERENSIS -- specie nuova; la pagina RHS non ha sezione
-- "How to Grow" (solo testo di genere), quindi resta bozza.
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, fonti, stato_verifica)
values (
  $t$Cheilanthes maderensis$t$,
  $t$Cheilanthes maderensis$t$,
  $t$cheilanthes-maderensis$t$,
  $t$Pteridaceae$t$,
  $t$perenne$t$,
  $t$Originaria dell'Europa meridionale. Da RHS, descrizione del genere (testo originale in inglese): "Cheilanthes are typically evergreen ferns, producing dense clumps of small fronds on shiny, often black, stalks".$t$,
  ARRAY[$t$RHS (rhs.org.uk) — Cheilanthes maderensis$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
"""

print("\n".join(blocks))
print(new_species_sql)
if missing:
    print("\n\n-- MANCANTI:", missing, file=sys.stderr)
