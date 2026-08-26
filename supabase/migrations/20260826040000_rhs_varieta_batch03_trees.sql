-- RHS Fase 5, batch 03: alberi e arbusti (Acer, Aesculus, Corylus,
-- Crataegus, Fraxinus, Juglans, Morus, Populus, Quercus, Robinia, Salix,
-- Sophora, Cercis, Magnolia, Elaeagnus, Ilex, Prunus, Punica, Colletia,
-- Mahonia, Buxus, Nerium, Hibiscus, Ruscus, Pistacia, Chamaerops, Cocos).
-- Stessa pipeline/convenzioni dei batch precedenti (vedi
-- scripts/rhs-import/README.md). Sinonimo: Styphnolobium japonicum e' il
-- nome oggi accettato per Sophora japonica, gia' in catalogo con questo
-- nome.


update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A vigorous deciduous tree with pinnate leaves on green young shoots, male and female flowers on separate plants; yellow autumn colour". RHS elenca 15 cultivar coltivate con altezze da 4-12m e diffusione da 2.5-8m (tra cui 'Auratum', 'Aureomarginatum', 'Aureovariegatum', 'Elegans', 'Flamingo', 'Kelly'...).$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to Acer gall mite, aphids , caterpillars and horse chestnut scale"; Malattie: "May be susceptible to Verticillium wilt , acer leaf scorch and honey fungus"$t$,
    $t$Rusticità RHS: H5, H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 4-12m, diffusione 2.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or grafting"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Acer negundo$t$),
  stato_verifica = 'verificato'
where slug = $t$acer-negundo$t$
  and not ($t$RHS (rhs.org.uk) — Acer negundo$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "Bushy, deciduous tree about 4m tall, with deeply separated 7 lobed leaves 4-6cm long and 6-9cm wide, tapered to a sharp point and with wavy margins. Young leaves open crimson then dark veined, light yellow-green, overlaid with pink and red, holding this distinctive blend of colours into summer, later turning dark green, then red in autumn. Inconspicuous red-purple flowers in spring may be followed by winged, red fruits". RHS elenca 127 cultivar coltivate con altezze da 1-12m e diffusione da 0.5-8m (tra cui 'Aka-shigitatsu-sawa', 'Amagi-shigure', 'Aoyagi', 'Ariadne', 'Asahi-zuru', 'Atropurpureum'...).$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to Acer gall mite, aphids , caterpillars and horse chestnut scale"; Malattie: "May be susceptible to Verticillium wilt , acer leaf scorch and honey fungus"$t$,
    $t$Rusticità RHS: H4, H5, H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1-12m, diffusione 0.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 from late autumn to midwinter only"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by layering in autumn, grafting in late winter or softwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Acer palmatum$t$),
  stato_verifica = 'verificato'
where slug = $t$acer-palmatum$t$
  and not ($t$RHS (rhs.org.uk) — Acer palmatum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large, broad-crowned deciduous tree. Leaves large, with 5-7 leaflets, turning red-brown early in autumn. Flowers creamy-white with a yellow spot that turns red with age. Fruit large, spiny". RHS elenca 8 cultivar coltivate con altezze da 2.5-12m e diffusione da 1.5-8m (tra cui 'Baumannii', 'Hampton Court Gold', 'Memmingeri', 'Monstrosa', 'Umbraculifera', 'Wisselink').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to horse chestnut scale and leaf-mining moth"; Malattie: "May be susceptible to coral spot , canker, leaf spot and honey fungus"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-12m, diffusione 1.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or grafting"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Aesculus hippocastanum$t$),
  stato_verifica = 'verificato'
where slug = $t$aesculus-hippocastanum$t$
  and not ($t$RHS (rhs.org.uk) — Aesculus hippocastanum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A small-medium deciduous shrub to about 3m, with beautiful colour. The slightly glossy leaves open in spring as a very dark purple, which fade slightly to purple-green for the rest of the summer. In autumn they turn dark yellow before falling. If catkins form in the spring, they are pale mauve and may develop into edible nuts". RHS elenca 18 cultivar coltivate con altezze da 1-8m e diffusione da 0.5-8m (tra cui 'Anny', 'Anny', 'Aurea', 'Contorta', 'Cosford', 'Fuscorubra'...).$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to caterpillars, gall mites , aphids and sawflies. Squirrels like to feed on the nuts"; Malattie: "May be susceptible to honey fungus , silver leaf and Powdery mildews"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1-8m, diffusione 0.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by layering or stooling or removing rooted suckers"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Corylus avellana$t$),
  stato_verifica = 'verificato'
where slug = $t$corylus-avellana$t$
  and not ($t$RHS (rhs.org.uk) — Corylus avellana$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A rounded, deciduous tree to about 10m in height, with thorny branches and glossy, deeply lobed dark green leaves, turning to gold in the autumn. Flat sprays of fragrant, creamy-white flowers with pink anthers, are produced in late spring, followed by plentiful dark red edible berries in autumn.  The fruit can be made into jellies or used for making herbal tea (see harm notes for further details)". RHS elenca 6 cultivar coltivate con altezze da 1.5-12m e diffusione da 1.5-8m (tra cui 'Biflora', 'Compacta', 'Ferox', 'Flexuosa', 'Stricta').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to caterpillars, aphids and gall mites"; Malattie: "May be susceptible to fireblight , honey fungus , crown gall , silver leaf , Powdery mildews and leaf spots"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-12m, diffusione 1.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 ; or trim hedges after flowering or in autumn"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed, or grafting in winter"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Crataegus monogyna$t$),
  stato_verifica = 'verificato'
where slug = $t$crataegus-monogyna$t$
  and not ($t$RHS (rhs.org.uk) — Crataegus monogyna$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A vigorous deciduous tree to 25m, with pale brown bark, dark green, pinnate leaves that turn yellow in autumn, and small deep purple flowers, followed by conspicuous bunches of winged fruits in late summer and autumn and black buds in winter". RHS elenca 6 cultivar coltivate con altezze da 12m e diffusione da 4-8m (tra cui 'Atlas', 'Aurea', 'Jaspidea', 'Pendula', 'Westhof').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, sabbioso, franco; pH alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "ash dieback has recently been found in the UK. Restrictions have been put in place (from 29 October 2012) regarding both the importation of ash from abroad and the movement of ash within the UK.  May also be susceptible to honey fungus"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 12m, diffusione 4-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or grafting"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Fraxinus excelsior$t$),
  stato_verifica = 'verificato'
where slug = $t$fraxinus-excelsior$t$
  and not ($t$RHS (rhs.org.uk) — Fraxinus excelsior$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An upright, relatively vigorous cultivar. It is self-fertile, starts to crop when still young, and produces a heavy crop of nuts that are particularly good for pickling". RHS elenca 6 cultivar coltivate con altezze da 4-12m e diffusione da 4-8m (tra cui 'Buccaneer', 'Laciniata', 'Lara', 'Pendula', 'Purpurea').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids and walnut blister mite"; Malattie: "May be susceptible to walnut leaf spot , walnut leaf blotch , honey fungus and coral spot"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 4-12m, diffusione 4-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 from late summer to autumn to prevent profuse bleeding"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by grafting"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Juglans regia$t$),
  stato_verifica = 'verificato'
where slug = $t$juglans-regia$t$
  and not ($t$RHS (rhs.org.uk) — Juglans regia$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A spreading, medium-sized tree, developing crooked and gnarled branches, with heart-shaped, serrated, mid-green foliage turning yellow in autumn. Small, fluffy, catkin-like, green flowers, in late spring or early summer, are followed in late summer by large, succulent, dark red to black fruit. A self-fertile variety with good flavour, cropping from a young age". RHS elenca 3 cultivar coltivate con altezze da 8-12m e diffusione da 8m (tra cui 'Chelsea', 'Jerusalem').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to mulberry leaf spot , mulberry canker, coral spot , Powdery mildews and honey fungus (rarely)"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 8-12m, diffusione 8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 , in late autumn or early winter to avoid bleeding"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi- hardwood cuttings in mid-summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Morus nigra$t$),
  stato_verifica = 'verificato'
where slug = $t$morus-nigra$t$
  and not ($t$RHS (rhs.org.uk) — Morus nigra$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A spreading, deciduous tree with a broad crown, suckering freely. Rounded leaves are deeply-lobed, dark green on top and white and downy underneath. Young shoots and leaves are completely white and hairy; yellow autumn colour. In spring, male catkins are red and female, green". RHS elenca 2 cultivar coltivate con altezze da 8-12m e diffusione da 4-8m (tra cui 'Richardii').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato, poco drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to leaf beetles, sawflies and caterpillars"; Malattie: "May be susceptible to leaf spots, poplar bacterial canker , tree rusts and honey fungus"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 8-12m, diffusione 4-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 in late summer to avoid bleeding from pruning cuts but established trees need little pruning; sucker removal in autumn or winter"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate from hardwood cuttings in winter or suckers in autumn or late winter"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Populus alba$t$),
  stato_verifica = 'verificato'
where slug = $t$populus-alba$t$
  and not ($t$RHS (rhs.org.uk) — Populus alba$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A fast-growing, spreading, deciduous, very variable tree to 30m. The narrow, dark green leaves typically have deep, pointed lobes, the acorns are up to 4cm long, and the cups covered in shaggy scales". RHS elenca 4 cultivar coltivate con altezze da 2.5-12m e diffusione da 1.5-8m (tra cui 'Argenteovariegata', 'Curly Head', 'Wodan').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to oak processionary moth , aphids , caterpillars, leaf-mining moths and oak gall wasps"; Malattie: "May be susceptible to Powdery mildews"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-12m, diffusione 1.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed, sown as soon as ripe, in a cold frame"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Quercus cerris$t$),
  stato_verifica = 'verificato'
where slug = $t$quercus-cerris$t$
  and not ($t$RHS (rhs.org.uk) — Quercus cerris$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large evergreen tree with black, finely cracked bark, developing a massive, rounded crown. Glossy dark green, ovate leaves, whitish beneath contrast with whitish young foliage and yellow catkins".$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids and leaf-mining moths"; Malattie: "May be susceptible to Powdery mildews and honey fungus"$t$,
    $t$Rusticità RHS: H4 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 12m, diffusione 8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed sown in a coldframe or seedbed as soon as ripe or by grafting in mid-autumn or late winter"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Quercus ilex$t$),
  stato_verifica = 'verificato'
where slug = $t$quercus-ilex$t$
  and not ($t$RHS (rhs.org.uk) — Quercus ilex$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large, deciduous tree potentially reaching a mature height of between 20 to 40m in height, with a magnificent broad crown and strong branches beneath.  Dark green, rounded and lobed foliage, smooth at the edges, turns reddish-brown in autumn.  Inconspicuous, long, yellow-green catkins appear in spring, followed by green acorns, ripening to brown, around 2-2.5 cm long.  Sadly the oak is in decline, but still commonly found across the United Kingdom, especially in Southern and Central areas, and an important food source and shelter for a whole range of small mammals, birds and insects". RHS elenca 6 cultivar coltivate con altezze da 8-12m e diffusione da 1.5-8m (tra cui 'Concordia', 'Irtha', 'Pectinata', 'Koster').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to oak processionary moth , aphids , caterpillars, leaf-mining moths and oak gall wasps"; Malattie: "May be susceptible to Powdery mildews and honey fungus"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 8-12m, diffusione 1.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed, sown as soon as ripe, in a cold frame"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Quercus robur$t$),
  stato_verifica = 'verificato'
where slug = $t$quercus-robur$t$
  and not ($t$RHS (rhs.org.uk) — Quercus robur$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A fast-growing large deciduous tree with an open, spreading crown and broad leaves to 22cm in length, turning red or red-brown in autumn. Flowers greenish, inconspicuous". RHS elenca 4 cultivar coltivate con altezze da 8-12m e diffusione da 2.5-8m (tra cui 'Aurea', 'Bolte', 'Magic Fire').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to oak processionary moth , aphids , caterpillars, leaf-mining moths and oak gall wasps"; Malattie: "May be susceptible to Powdery mildews and honey fungus"$t$,
    $t$Rusticità RHS: H6, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 8-12m, diffusione 2.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed, sowing as soon as ripe, in a coldframe or grafting in mid-autumn or early winter"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Quercus rubra$t$),
  stato_verifica = 'verificato'
where slug = $t$quercus-rubra$t$
  and not ($t$RHS (rhs.org.uk) — Quercus rubra$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A fast-growing, spreading tree to 25m tall with deeply furrowed rough bark and spines formed from stipules on twigs and suckers. The dark green leaves comprise 5-11 pairs of oval leaflets. Dense, drooping clusters of slightly scented white flowers, each 15-20mm long and with a yellow blotch at the base of the standard petal, are borne in late spring and summer and are followed in autumn by hairless, linear to oblong pods containing 4-10 seeds". RHS elenca 6 cultivar coltivate con altezze da 2.5-12m e diffusione da 1.5-8m (tra cui 'Frisia', 'Lace Lady', 'Myrtifolia', 'Tortuosa', 'Umbraculifera').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May  be susceptible to honey fungus"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-12m, diffusione 1.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 for maintaining a neat ball, or pruning group 7 for pollarding ; pruning should be done in late summer or early autumn to prevent bleeding. Suckers should be removed if necessary, in autumn"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or from root cuttings or from suckers"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Robinia pseudoacacia$t$),
  stato_verifica = 'verificato'
where slug = $t$robinia-pseudoacacia$t$
  and not ($t$RHS (rhs.org.uk) — Robinia pseudoacacia$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous tree, to 12m high and wide, with a spreading crown of weeping branches. Leaves are long, narrow and finely toothed, green with blue-grey undersides. Slender catkins are produced alongside the new leaves in spring". RHS elenca 3 cultivar coltivate con altezze da 8-12m e diffusione da 4-8m (tra cui 'Crispa', 'Tortuosa').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , caterpillars, willow leaf beetle , sawflies and willow scale insects"; Malattie: "May be susceptible to willow anthracnose , honey fungus and rust diseases"$t$,
    $t$Rusticità RHS: H5, H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 8-12m, diffusione 4-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by softwood cuttings in early summer or hardwood cuttings in winter"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Salix babylonica$t$),
  stato_verifica = 'verificato'
where slug = $t$salix-babylonica$t$
  and not ($t$RHS (rhs.org.uk) — Salix babylonica$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large deciduous tree to 25m tall with a rounded, low-branched habit, and rich green pinnate leaves to 30cm in length. Fragrant creamy-white, pea-shaped flowers 12mm in length, produced in terminal panicles in mature trees".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 12m, diffusione 8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed when ripe or grafting in late winter"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Styphnolobium japonicum$t$),
  stato_verifica = 'verificato'
where slug = $t$sophora-japonica$t$
  and not ($t$RHS (rhs.org.uk) — Styphnolobium japonicum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A bushy, deciduous small tree. Leaves to 10cm in width, broadly heart-shaped. Flowers rosy-pink, pea-shaped, in clusters on the older wood. Fruit a conspicuous flattened purplish pod to 12cm in length". RHS elenca 3 cultivar coltivate con altezze da 8-12m e diffusione da 8m (tra cui 'Bodnant').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to leafhoppers and scale insects"; Malattie: "May be susceptible to Verticillium wilt and coral spot"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 8-12m, diffusione 8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed and semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Cercis siliquastrum$t$),
  stato_verifica = 'verificato'
where slug = $t$cercis-siliquastrum$t$
  and not ($t$RHS (rhs.org.uk) — Cercis siliquastrum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large, rounded evergreen tree about about 12m tall or more with glossy dark green, leathery, oblong-elliptic leaves, often rusty-brown beneath, and highly fragrant, cup-shaped, cream flowers to 25cm across in late summer and autumn". RHS elenca 20 cultivar coltivate con altezze da 2.5-12m e diffusione da 1-8m (tra cui '24 Below', 'Bracken', 'Charles Dickens', 'D.D. Blanchard', 'Edith Bogue', 'Exmouth'...).$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to scale insects , horse chestnut scale and capsid bug"; Malattie: "May be susceptible to coral spot , Phytophthora , grey moulds , honey fungus , a virus or fungal leaf spot"$t$,
    $t$Rusticità RHS: H4, H5, H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-12m, diffusione 1-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 9 or pruning group 13 if wall-trained.  See magnolia pruning"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi-ripe cuttings from late summer to early autumn or layering in early spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Magnolia grandiflora$t$),
  stato_verifica = 'verificato'
where slug = $t$magnolia-grandiflora$t$
  and not ($t$RHS (rhs.org.uk) — Magnolia grandiflora$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A strong-growing, wide-spreading evergreen shrub, to 5m in height, with some spiny, but mainly spineless branches. Leaves, are green and glossy above and matt white underneath, with brown scales. Clusters of small but extremely-fragrant, silvery-cream flowers are borne in autumn, followed by oval red fruits". RHS elenca 11 cultivar coltivate con altezze da 1.5-8m e diffusione da 1-8m (tra cui 'Aurea', 'Dicksonii', 'Forest Gold', 'Frederici', 'Goldrim', 'Hosoba-fukurin'...).$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Sabbioso, franco, argilloso, calcareo; pH neutro, acido, alcalino"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free but may be susceptible to elaeagnus sucker"; Malattie: "May be susceptible to honey fungus , coral spot or leaf spot (fungal) see leaf damage on woody plants"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-8m, diffusione 1-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 9"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi-ripe cuttings in summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Elaeagnus pungens$t$),
  stato_verifica = 'verificato'
where slug = $t$elaeagnus-pungens$t$
  and not ($t$RHS (rhs.org.uk) — Elaeagnus pungens$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large evergreen tree, slow-growing when young, with dark, glossy green, usually strongly spiny leaves. Small white flowers in spring are followed by bright red berries, on pollinated female plants". RHS elenca 66 cultivar coltivate con altezze da 1-12m e diffusione da 0.5-8m (tra cui 'Alaska', 'Amber', 'Ammerland', 'Angustifolia', 'Angustifolia', 'Argentea Longifolia'...).$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to scale insects , Holly leaf miner and young shoots may be susceptible to aphids"; Malattie: "May be susceptible to holly leaf blight , Phytophthora root rot and sometimes honey fungus"$t$,
    $t$Rusticità RHS: H6, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1-12m, diffusione 0.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 ; trim hedges in early spring"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed in a coldframe in autumn, or propagate by semi-ripe cuttings in late summer or early autumn or propagate by hardwood cuttings in January with bottom heat"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Ilex aquifolium$t$),
  stato_verifica = 'verificato'
where slug = $t$ilex-aquifolium$t$
  and not ($t$RHS (rhs.org.uk) — Ilex aquifolium$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An upright, rounded, twiggy tree with very dark red-purple leaves. The pale pink flowers, soon fading to white, open in early spring with the leaves and may be followed by dark red, edible, plum-like fruit".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Can suffer from aphids , including plum aphid and caterpillars"; Malattie: "May be susceptible to peach leaf curl , silver leaf , bacterial canker , blossom wilt and honey fungus"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 8-12m, diffusione 8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 .  Prune in mid-summer if silver leaf is a problem"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by Chip budding or grafting , although softwood cuttings in early summer with bottom heat can be successful"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Prunus cerasifera$t$),
  stato_verifica = 'verificato'
where slug = $t$prunus-cerasifera$t$
  and not ($t$RHS (rhs.org.uk) — Prunus cerasifera$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A vigorous, large, spreading evergreen shrub with handsome, glossy dark green leaves to 15cm in length. Small white flowers in erect racemes to 12cm in length are followed by cherry-like glossy red fruits soon turning black". RHS elenca 17 cultivar coltivate con altezze da 0.1-8m e diffusione da 0.5-8m (tra cui 'Camelliifolia', 'Castlewellan', 'Caucasica', 'Gajo', 'Herbergii', 'Ivory'...).$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Leaves may be damaged by vine weevil and leaf-mining moths"; Malattie: "May be susceptible to Powdery mildews and other laurel leaf diseases. high risk host for xylella fastidiosa"$t$,
    $t$Rusticità RHS: H5, H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-8m, diffusione 0.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 8 including hedges in late spring or early summer"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi-ripe cuttings from late summer to autumn or hardwood cuttings from late autumn to late winter; propagate by seed in autumn"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Prunus laurocerasus$t$),
  stato_verifica = 'verificato'
where slug = $t$prunus-laurocerasus$t$
  and not ($t$RHS (rhs.org.uk) — Prunus laurocerasus$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A rounded shrub with glossy, narrowly oblong leaves, bronze in spring, and funnel-shaped bright scarlet flowers 3-4cm across in summer, sometimes followed by spherical, reddish-brown fruits up to 12cm across". RHS elenca 6 cultivar coltivate con altezze da 0.5-8m e diffusione da 0.5-8m (tra cui 'Forbidden City', 'Legrelleae', 'Wonderful', 'Flore Pleno Luteo').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to honey fungus (rarely)"$t$,
    $t$Rusticità RHS: H3 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-8m, diffusione 0.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 from spring to summer. pruning group 13 if wall trained"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed sown at 13-18°C in spring or root semi- hardwood cuttings with bottom heat in summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Punica granatum$t$),
  stato_verifica = 'verificato'
where slug = $t$punica-granatum$t$
  and not ($t$RHS (rhs.org.uk) — Punica granatum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A rounded deciduous shrub to 3m, with stems bearing many blue-green, flattened, triangular spines and small clusters of fragrant white flowers in autumn".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H4 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-4m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 : tip prune young plants to promote bushiness. Tolerates moderately hard pruning"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi-ripe cuttings of short sideshoots in late summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Colletia paradoxa$t$),
  stato_verifica = 'verificato'
where slug = $t$colletia-paradoxa$t$
  and not ($t$RHS (rhs.org.uk) — Colletia paradoxa$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A vigorous, low-spreading, evergreen shrub with glossy green, slightly prickly leaves becoming purplish in winter. Large clusters of yellow flowers appear in spring, followed by black berries".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to a rust and Powdery mildews"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 1-1.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 8"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed and semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Mahonia aquifolium$t$),
  stato_verifica = 'verificato'
where slug = $t$mahonia-aquifolium$t$
  and not ($t$RHS (rhs.org.uk) — Mahonia aquifolium$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large, evergreen shrub or small tree to 5m tall, with glossy, dark green leaves to 3cm long, and small, yellowish flowers in clusters, produced in the leaf axils during spring". RHS elenca 15 cultivar coltivate con altezze da 0.1-8m e diffusione da 0.1-8m (tra cui 'Aureovariegata', 'Blauer Heinz', 'Bowles', 'Elegans', 'Elegantissima', 'Graham Blandy'...).$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to box tree caterpillar , box sucker , mussel scale and red spider mite"; Malattie: "May be susceptible to a leaf spot, box blight and, rarely, honey fungus"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-8m, diffusione 0.1-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 8 in summer, renovation pruning can be carried out in late spring. Use mulch and a general fertiliser after hard pruning, ideal for topiary clipping"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate from semi-ripe cuttings in summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Buxus sempervirens$t$),
  stato_verifica = 'verificato'
where slug = $t$buxus-sempervirens$t$
  and not ($t$RHS (rhs.org.uk) — Buxus sempervirens$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen, erect to spreading shrub to 4m, with lance-shaped, grey-green leaves to 20cm long. From late spring to autumn it produces open, branched clusters of white, 5-petalled flowers to 5cm across". RHS elenca 6 cultivar coltivate con altezze da 1.5-8m e diffusione da 1-4m (tra cui 'Album', 'Sealy Pink', 'Variegatum').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to scale insects , mealybugs and glasshouse red spider mite under glass"; Malattie: "May be susceptible to honey fungus (rarely)"$t$,
    $t$Rusticità RHS: H2, H3 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-8m, diffusione 1-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "See pruning group 9"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi-ripe cuttings in summer; sow seed at 16°C in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Nerium oleander$t$),
  stato_verifica = 'verificato'
where slug = $t$nerium-oleander$t$
  and not ($t$RHS (rhs.org.uk) — Nerium oleander$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A medium to large, deciduous shrub up to 4m tall with an upright habit. Lobed leaves appear in late spring and large, trumpet-shaped flowers in shades of pink, red, blue and white with conspicuous protruding tubes of stamens open in succession from midsummer into autumn". RHS elenca 61 cultivar coltivate con altezze da 0.1-8m e diffusione da 0.1-4m (tra cui 'Admiral Dewey', 'Aphrodite', 'Ardens', 'Bredon Springs', 'Cicola', 'Coelestis'...).$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , scale insects , mealybugs and glasshouse whitefly when grown under glass"; Malattie: "May be susceptible to honey fungus (rarely) and Powdery mildews"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-8m, diffusione 0.1-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Hibiscus syriacus$t$),
  stato_verifica = 'verificato'
where slug = $t$hibiscus-syriacus$t$
  and not ($t$RHS (rhs.org.uk) — Hibiscus syriacus$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A bushy sub-shrub to 75cm, with glossy lance-shaped cladophylls 2.5cm in length, flowering in spring, with glossy red berries on female plants in summer and autumn". RHS elenca 5 cultivar coltivate con altezze da 0.1-1m e diffusione da 0.5-1m (tra cui 'John Redmond', 'Lanceolatus').$t$,
  esigenze = ($t${"luce": "Ombra piena, pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to honey fungus in gardens where it is present but insufficient data to determine degree of susceptibility"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Cut out dead stems to the base in spring"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or division"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Ruscus aculeatus$t$),
  stato_verifica = 'verificato'
where slug = $t$ruscus-aculeatus$t$
  and not ($t$RHS (rhs.org.uk) — Ruscus aculeatus$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A tender evergreen shrub or small tree, up to 3m high, with pinnate, aromatic, leathery green leaves divided into up to 7 pairs of leaflets. Small flowers are produced in late spring and early summer; on male plants these are reddish and held in small dense clusters, female plants have looser clusters of brownish green flowers. If pollinated, these are followed on by small round reddish fruits that ripen to black".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to fungal root rot"$t$,
    $t$Rusticità RHS: H2 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-4m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 ; restrictive pruning may be required if grown under glass"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or by softwood cuttings in late spring or early summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pistacia lentiscus$t$),
  stato_verifica = 'verificato'
where slug = $t$pistacia-lentiscus$t$
  and not ($t$RHS (rhs.org.uk) — Pistacia lentiscus$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A bushy evergreen palm making a medium-sized shrub, often stemless or multi-stemmed, with a rounded mass of fan-shaped leaves to 45cm in length. Short rigid panicles of small yellow flowers are borne on mature plants only". RHS elenca 4 cultivar coltivate con altezze da 1.5-2.5m e diffusione da 1-2.5m (tra cui 'Compacta', 'Vulcano').$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Ben drenato", "terreno": "Franco; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to glasshouse red spider mite , Thrips and scale insects"; Malattie: "May be susceptible to honey fungus (rarely)"$t$,
    $t$Rusticità RHS: H3, H4 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-2.5m, diffusione 1-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or suckers"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Chamaerops humilis$t$),
  stato_verifica = 'verificato'
where slug = $t$chamaerops-humilis$t$
  and not ($t$RHS (rhs.org.uk) — Chamaerops humilis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A single-stemmed palm, forming a tree to 25m in the tropics, prized for its elegant form and edible seeds (coconuts). In frost-prone areas, young specimens can be grown as short-lived foliage plants in a warm conservatory, or as houseplants".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to glasshouse red spider mite , scale insects and mealybugs"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1A (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1-1.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by soaking a fresh coconut (with husk still on) in warm water for 3 days. Then half bury the coconut, pointed end down, in a pot of peat-free, loam-based compost with additional sharp sand and fibrous organic matter. Water well and seal the whole lot up in a large plastic bag, putting it in a warm place and checking frequently for signs of germination; this may take 3-6 months"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Cocos nucifera$t$),
  stato_verifica = 'verificato'
where slug = $t$cocos-nucifera$t$
  and not ($t$RHS (rhs.org.uk) — Cocos nucifera$t$ = any(fonti));

