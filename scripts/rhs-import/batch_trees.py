import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from genera_sql import gen_block

PAIRS = [
    ("Acer negundo", "acer-negundo"),
    ("Acer palmatum", "acer-palmatum"),
    ("Aesculus hippocastanum", "aesculus-hippocastanum"),
    ("Corylus avellana", "corylus-avellana"),
    ("Crataegus monogyna", "crataegus-monogyna"),
    ("Fraxinus excelsior", "fraxinus-excelsior"),
    ("Juglans regia", "juglans-regia"),
    ("Morus nigra", "morus-nigra"),
    ("Populus alba", "populus-alba"),
    ("Quercus cerris", "quercus-cerris"),
    ("Quercus ilex", "quercus-ilex"),
    ("Quercus robur", "quercus-robur"),
    ("Quercus rubra", "quercus-rubra"),
    ("Robinia pseudoacacia", "robinia-pseudoacacia"),
    ("Salix babylonica", "salix-babylonica"),
    ("Styphnolobium japonicum", "sophora-japonica"),
    ("Cercis siliquastrum", "cercis-siliquastrum"),
    ("Magnolia grandiflora", "magnolia-grandiflora"),
    ("Elaeagnus pungens", "elaeagnus-pungens"),
    ("Ilex aquifolium", "ilex-aquifolium"),
    ("Prunus cerasifera", "prunus-cerasifera"),
    ("Prunus laurocerasus", "prunus-laurocerasus"),
    ("Punica granatum", "punica-granatum"),
    ("Colletia paradoxa", "colletia-paradoxa"),
    ("Mahonia aquifolium", "mahonia-aquifolium"),
    ("Buxus sempervirens", "buxus-sempervirens"),
    ("Nerium oleander", "nerium-oleander"),
    ("Hibiscus syriacus", "hibiscus-syriacus"),
    ("Ruscus aculeatus", "ruscus-aculeatus"),
    ("Pistacia lentiscus", "pistacia-lentiscus"),
    ("Chamaerops humilis", "chamaerops-humilis"),
    ("Cocos nucifera", "cocos-nucifera"),
]

header = """-- RHS Fase 5, batch 03: alberi e arbusti (Acer, Aesculus, Corylus,
-- Crataegus, Fraxinus, Juglans, Morus, Populus, Quercus, Robinia, Salix,
-- Sophora, Cercis, Magnolia, Elaeagnus, Ilex, Prunus, Punica, Colletia,
-- Mahonia, Buxus, Nerium, Hibiscus, Ruscus, Pistacia, Chamaerops, Cocos).
-- Stessa pipeline/convenzioni dei batch precedenti (vedi
-- scripts/rhs-import/README.md). Sinonimo: Styphnolobium japonicum e' il
-- nome oggi accettato per Sophora japonica, gia' in catalogo con questo
-- nome.

"""

blocks = [header]
missing = []
for rhs_name, slug in PAIRS:
    b = gen_block(rhs_name, slug)
    if not b:
        missing.append((rhs_name, slug))
        continue
    blocks.append(b)

print("\n".join(blocks))
if missing:
    print("\n\n-- MANCANTI:", missing, file=sys.stderr)
