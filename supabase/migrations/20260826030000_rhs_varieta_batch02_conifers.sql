-- RHS Fase 5, batch 02: conifere (Abies, Cedrus, Larix, Picea, Pinus,
-- Pseudotsuga, Tsuga, Ginkgo, Taxus, Chamaecyparis, Cryptomeria,
-- Cupressus, Juniperus, Thuja). Stessa pipeline/convenzioni del batch 01
-- (vedi scripts/rhs-import/README.md): testo libero RHS in inglese
-- originale marcato come tale, campi strutturati tradotti in esigenze,
-- stato_verifica='verificato' solo con contenuto specifico sulla specie.
-- Sinonimi: Platycladus orientalis e Xanthocyparis nootkatensis sono i
-- nomi oggi accettati per Thuja orientalis e Chamaecyparis nootkatensis
-- (gia' in catalogo con questi nomi) -- entrambe le pagine RHS scaricate
-- sotto i due nomi vengono quindi appese alla stessa riga, ciascuna con
-- la propria fonte.


update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An upright-growing evergreen conifer to 45m in height, with dark green needles that are silver underneath. The yellow-green cones which appear in late spring  are cylindrical in shape and ripen to brown".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to adelgids and aphids"; Malattie: "Generally disease-free, but may be susceptible to honey fungus"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 12m, diffusione 4-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Pruning not recommended"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by grafting"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Abies alba$t$),
  stato_verifica = 'verificato'
where slug = $t$abies-alba$t$
  and not ($t$RHS (rhs.org.uk) — Abies alba$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A dwarf cultivar, making a low rounded mound with a flattish top and distinctively arranged dark green needle-like leaves, to 1.5cm long. are whiteish beneath. No cones are produced". RHS elenca 3 cultivar coltivate con altezze da 0.5-1m e diffusione da 1-1.5m (tra cui 'Hudsonia', 'Nana').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to adelgids and aphids"; Malattie: "Generally disease-free but may be susceptible to honey fungus"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 1-1.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by grafting"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Abies balsamea$t$),
  stato_verifica = 'verificato'
where slug = $t$abies-balsamea$t$
  and not ($t$RHS (rhs.org.uk) — Abies balsamea$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A low-growing evergreen conifer making a bushy medium-sized shrub with a broadly conical crown, bright blue-grey foliage and purple young cones are produced occasionally by this cultivar".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to adelgids and aphids"; Malattie: "Generally disease-free, but may be susceptible to honey fungus"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-4m, diffusione 1.5-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or grafting"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Abies lasiocarpa$t$),
  stato_verifica = 'verificato'
where slug = $t$abies-lasiocarpa$t$
  and not ($t$RHS (rhs.org.uk) — Abies lasiocarpa$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen conifer making a large tree, at first conical with a drooping leading shoot, later broad-crowned. Needles to 4cm in length, slightly glaucous, mostly whorled. Cone to 10cm in length, broadly-ovoid". RHS elenca 8 cultivar coltivate con altezze da 0.1-12m e diffusione da 1.5-8m (tra cui 'Aurea', 'Feelin', 'Karl Fuchs', 'Pendula', 'Robusta', 'Silver Mist'...).$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to conifer aphid"; Malattie: "May be susceptible to honey fungus"$t$,
    $t$Rusticità RHS: H5, H6, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-12m, diffusione 1.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Cedrus deodara$t$),
  stato_verifica = 'verificato'
where slug = $t$cedrus-deodara$t$
  and not ($t$RHS (rhs.org.uk) — Cedrus deodara$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous conifer making a large conical tree, broadening with age, with cream young shoots bearing soft, light green needle-like leaves in whorls, turning yellow in autumn. Flowers small, cones to 4cm, erect". RHS elenca 4 cultivar coltivate con altezze da 1.5-12m e diffusione da 1-8m (tra cui 'Horstmann', 'Pendula', 'Puli').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to adelgids"; Malattie: "May be susceptible to honey fungus in gardens where it is present but insufficient data to determine degree of susceptibility"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-12m, diffusione 1-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed in containers in early spring, graft in winter, or root semi-ripe cuttings in summer under mist; cuttings are difficult to root"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Larix decidua$t$),
  stato_verifica = 'verificato'
where slug = $t$larix-decidua$t$
  and not ($t$RHS (rhs.org.uk) — Larix decidua$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A fast-growing, dense conifer, to 30m tall, narrowly-conical when young becoming broader with age. Dark green, glossy, needle-like leaves, to 2.5cm long, cover the upper side of the branchlets. The light brown cones taper at the top, reaching up to 15cm long and 5cm wide". RHS elenca 20 cultivar coltivate con altezze da 0.1-12m e diffusione da 0.1-8m (tra cui 'Acrocona', 'Clanbrassiliana', 'Cupressina', 'Frohburg', 'Hystrix', 'Inversa'...).$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to adelgids , red spider mite and conifer aphid"; Malattie: "May be susceptible to honey fungus"$t$,
    $t$Rusticità RHS: H6, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-12m, diffusione 0.1-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or by semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Picea abies$t$),
  stato_verifica = 'verificato'
where slug = $t$picea-abies$t$
  and not ($t$RHS (rhs.org.uk) — Picea abies$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Picea are evergreen trees with rigid, needle-like leaves arranged singly all round the shoots, and narrow, leathery-scaled cones borne near the ends of the shoots". RHS elenca 2 cultivar coltivate con altezze da 0.1-0.5m e diffusione da 0.1-0.5m (tra cui 'Nana').$t$,
  alert = alert || ARRAY[
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Picea mariana$t$),
  stato_verifica = 'verificato'
where slug = $t$picea-mariana$t$
  and not ($t$RHS (rhs.org.uk) — Picea mariana$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A conical to columnar evergreen tree to about 15m with scaly, grey bark and orange-brown shoots. Needles are stiff, pointed, bluish grey-green, curving upwards and covered in wax. Cylindrical cones are green at first, ripening to pale brown, and up to 12cm long". RHS elenca 12 cultivar coltivate con altezze da 0.5-12m e diffusione da 0.5-8m (tra cui 'Blue Diamond', 'Edith', 'Erich Frahm', 'Fat Albert', 'Iseli Foxtail', 'Maigold'...).$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to adelgids , aphids and conifer red spider mite"; Malattie: "May be susceptible to honey fungus"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-12m, diffusione 0.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Picea pungens$t$),
  stato_verifica = 'verificato'
where slug = $t$picea-pungens$t$
  and not ($t$RHS (rhs.org.uk) — Picea pungens$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen conifer, up to 30m high at maturity, with spreading branches curving upwards at the tips, and pendent branchlets with sparse, flexible dark green needles. Produces greenish cones, to 10cm long, that mature to purple-brown".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to adelgids , red spider mite and conifer aphid"; Malattie: "May be susceptible to honey fungus"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 12m, diffusione 8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by grafting in winter"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Picea smithiana$t$),
  stato_verifica = 'verificato'
where slug = $t$picea-smithiana$t$
  and not ($t$RHS (rhs.org.uk) — Picea smithiana$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A bushy tree to 20m tall, usually narrow in habit, with dark grey-green needles borne in fives, and ovoid cones 6cm long, blue-green when young, later pale brown, and contained large, edible seeds". RHS elenca 2 cultivar coltivate con altezze da 8-12m e diffusione da 2.5-8m (tra cui 'Stricta').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to adelgids , conifer aphid , sawfly larvae, and pine shoot moth"; Malattie: "May be susceptible to honey fungus and needle cast diseases"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 8-12m, diffusione 2.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Keep pruning to a minimum but if dual leaders form on young trees, remove one to produce a single-stemmed tree. Trees may be resinous, any pruning should be carried out from late summer to midwinter"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed in containers in a cold frame in spring. semi-ripe cuttings from vigorous young growth in summer or early to mid autumn"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pinus cembra$t$),
  stato_verifica = 'verificato'
where slug = $t$pinus-cembra$t$
  and not ($t$RHS (rhs.org.uk) — Pinus cembra$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large, spreading, bushy shrub or small tree with short, dark green needles and dark brown, ovoid cones". RHS elenca 26 cultivar coltivate con altezze da 0.1-4m e diffusione da 0-8m (tra cui 'Benjamin', 'Carstens', 'Dezember Gold', 'Gnom', 'Golden Glow', 'Hana'...).$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to adelgids , conifer aphid , sawfly larvae, and pine shoot moth"; Malattie: "May be susceptible to honey fungus and needle cast diseases"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-4m, diffusione 0-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by grafting"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pinus mugo$t$),
  stato_verifica = 'verificato'
where slug = $t$pinus-mugo$t$
  and not ($t$RHS (rhs.org.uk) — Pinus mugo$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large evergreen tree developing an irregular, dense crown with age. Leaves dark green, paired, to 12cm in length. Cones ovoid, pale brown when mature". RHS elenca 10 cultivar coltivate con altezze da 0.5-12m e diffusione da 0.5-8m (tra cui 'Black Prince', 'Green Tower', 'Hornibrookiana', 'Komet', 'Moseri', 'Nana'...).$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to adelgids , conifer aphid , sawfly larvae, and pine shoot moth"; Malattie: "May be susceptible to honey fungus and needle cast diseases"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-12m, diffusione 0.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed sown in containers in a cold frame in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pinus nigra$t$),
  stato_verifica = 'verificato'
where slug = $t$pinus-nigra$t$
  and not ($t$RHS (rhs.org.uk) — Pinus nigra$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen conifer forming an open-crowned large tree with a long clear trunk. Needles paired, stiff, to 25cm long. Rich brown woody cones to 15cm long remain on the tree for many years".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to adelgids , conifer aphid , sawfly larvae, and pine shoot moth"; Malattie: "May be susceptible to honey fungus and needle cast diseases"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 12m, diffusione 8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Generally, no pruning required. Remove competing leaders and, on older trees, crown lift as necessary by removing some of the lower branches to reveal the trunk"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed sown in containers in a cold frame in late winter. Retain in pots for at least two years"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pinus pinaster$t$),
  stato_verifica = 'verificato'
where slug = $t$pinus-pinaster$t$
  and not ($t$RHS (rhs.org.uk) — Pinus pinaster$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large, evergreen tree to 25m, with the upper trunk and branches orange-brown, developing a picturesque, irregular outline with maturity. Twisted grey-green needles are borne in pairs. Cones 5cm in length". RHS elenca 17 cultivar coltivate con altezze da 0.5-12m e diffusione da 0.5-8m (tra cui 'Beuvronensis', 'Chantry Blue', 'Dereham', 'Frensham', 'Globosa', 'Gold Coin'...).$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to adelgids , conifer aphid , sawfly larvae, and pine shoot moth"; Malattie: "May be susceptible to honey fungus and needle cast diseases"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-12m, diffusione 0.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pinus sylvestris$t$),
  stato_verifica = 'verificato'
where slug = $t$pinus-sylvestris$t$
  and not ($t$RHS (rhs.org.uk) — Pinus sylvestris$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A fast-growing large evergreen tree of conical habit, the bark becoming thick and rugged; leaves linear, dark green, two-ranked. Cones to 10cm long, with conspicuous exserted bracts". RHS elenca 2 cultivar coltivate con altezze da 2.5-12m e diffusione da 1-8m (tra cui 'Glauca Pendula').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Douglas fir adelgids may occur"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-12m, diffusione 1-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Requires little pruning. Remove competing leaders on young trees"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed sown fresh in containers in a cold frame in late winter"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pseudotsuga menziesii$t$),
  stato_verifica = 'verificato'
where slug = $t$pseudotsuga-menziesii$t$
  and not ($t$RHS (rhs.org.uk) — Pseudotsuga menziesii$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A vigorous, broadly conical evergreen tree to 25m tall, with deeply furrowed, purplish-grey bark andshort, dark green, needle-like leaves, white beneath, borne in two ranks on slender shoots forming flat sprays of foliage; ovoid brown cones 2cm long ripen in autumn". RHS elenca 6 cultivar coltivate con altezze da 0.1-12m e diffusione da 0.1-8m (tra cui 'Cole', 'Everitt Golden', 'Jeddeloh', 'Minuta', 'Pendula').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to butt and root rot fungus"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-12m, diffusione 0.1-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed in containers in a cold frame in spring; root semi-ripe cuttings in late summer or early autumn"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Tsuga canadensis$t$),
  stato_verifica = 'verificato'
where slug = $t$tsuga-canadensis$t$
  and not ($t$RHS (rhs.org.uk) — Tsuga canadensis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A vigorous large evergreen tree to 30m or more, conical in habit, with elegantly spreading branches bearing short, flattened, dark green needles striped white beneath. Ovoid cones are 2.5cm in length".$t$,
  esigenze = ($t${"luce": "Ombra piena, pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 12m, diffusione 8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or semi- hardwood cutings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Tsuga heterophylla$t$),
  stato_verifica = 'verificato'
where slug = $t$tsuga-heterophylla$t$
  and not ($t$RHS (rhs.org.uk) — Tsuga heterophylla$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous tree to 25m, conical when young, becoming more irregular with age. Leaves to 12cm in width, fan-shaped and often bilobed, turning clear yellow in autumn. Unpleasantly scented dull yellow fruits in autumn on female plants". RHS elenca 26 cultivar coltivate con altezze da 0.5-12m e diffusione da 0.5-8m (tra cui 'Autumn Gold', 'Barabits', 'Barabits', 'Beijing Gold', 'California Sunset', 'Chris'...).$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to honey fungus (rarely)"$t$,
    $t$Rusticità RHS: H5, H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-12m, diffusione 0.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Ginkgo biloba$t$),
  stato_verifica = 'verificato'
where slug = $t$ginkgo-biloba$t$
  and not ($t$RHS (rhs.org.uk) — Ginkgo biloba$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A medium-sized bushy evergreen tree with narrow, leathery, very dark green leaves arranged in two rows on the shoots, and insignificant flowers followed on female plants by fleshy red fruits". RHS elenca 28 cultivar coltivate con altezze da 0.1-12m e diffusione da 0.1-8m (tra cui 'Adpressa Variegata', 'Amersfoort', 'Aureomarginata', 'Black Tower', 'Corleys Coppertip', 'David'...).$t$,
  esigenze = ($t${"luce": "Ombra piena, pieno sole, mezz'ombra", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to tortrix moth , vine weevil , gall mites and scale insects"; Malattie: "May be susceptible to Phytophthora root diseases and honey fungus (rarely)"$t$,
    $t$Rusticità RHS: H6, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-12m, diffusione 0.1-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No regular pruning necessary, but can be trimmed and shaped when required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Taxus baccata$t$),
  stato_verifica = 'verificato'
where slug = $t$taxus-baccata$t$
  and not ($t$RHS (rhs.org.uk) — Taxus baccata$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large, upright, conical tree with drooping branches, reaching up to 25m high. The aromatic, scale-like, dark green to glaucous green leaves, each 3-5mm long, are borne in flattened sprays. Small, globular male cones, 3-4mm long, are a reddish-pink in spring whilst the larger female seed cones are green maturing to brown". RHS elenca 65 cultivar coltivate con altezze da 0.1-12m e diffusione da 0.1-8m (tra cui 'Alumigold', 'Aurea Densa', 'Barabits', 'Bleu Nantais', 'Blue Surprise', 'Broomhill Gold'...).$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , juniper scale and shoot-boring moths"; Malattie: "May be susceptible to honey fungus and Phytophthora root diseases"$t$,
    $t$Rusticità RHS: H5, H6, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-12m, diffusione 0.1-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required.  If used as hedging, trim twice a year to maintain shape"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed and semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Chamaecyparis lawsoniana$t$),
  stato_verifica = 'verificato'
where slug = $t$chamaecyparis-lawsoniana$t$
  and not ($t$RHS (rhs.org.uk) — Chamaecyparis lawsoniana$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A slow-growing species of evergreen conifer with dark red-brown bark and green foliage reaching heights of up to 35m.  Also used for ornamental bonsai". RHS elenca 33 cultivar coltivate con altezze da 0.1-12m e diffusione da 0.1-8m (tra cui 'Aurora', 'Brigitt', 'Bronze Pygmy', 'Butterball', 'Cooper', 'Crippsii'...).$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , juniper scale and shoot-boring moths"; Malattie: "May be susceptible to honey fungus and Phytophthora root diseases"$t$,
    $t$Rusticità RHS: H4, H5, H6, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-12m, diffusione 0.1-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required but if used as hedging, trim twice a year to maintain shape"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed and semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Chamaecyparis obtusa$t$),
  stato_verifica = 'verificato'
where slug = $t$chamaecyparis-obtusa$t$
  and not ($t$RHS (rhs.org.uk) — Chamaecyparis obtusa$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A slow-growing species of evergreen coniferous tree varying in height from 1m for dwarf varieties to 12m plus for the larger varieties.  Bark is fissured and reddish-brown with flat branches varying in colour from shades of green to blue". RHS elenca 17 cultivar coltivate con altezze da 0.1-12m e diffusione da 0.1-8m (tra cui 'Baby Blue', 'Blue Moon', 'Boulevard', 'Compacta', 'Curly Top', 'Filifera Aurea Nana'...).$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , juniper scale and shoot-boring moths"; Malattie: "May be susceptible to honey fungus and Phytophthora root diseases"$t$,
    $t$Rusticità RHS: H5, H6, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-12m, diffusione 0.1-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required but if used as hedging, trim twice a year to maintain shape"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed and semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Chamaecyparis pisifera$t$),
  stato_verifica = 'verificato'
where slug = $t$chamaecyparis-pisifera$t$
  and not ($t$RHS (rhs.org.uk) — Chamaecyparis pisifera$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A compact evergreen conifer making a small, conical shrub, with soft, juvenile, blue-green foliage, becoming purplish in winter". RHS elenca 3 cultivar coltivate con altezze da 0.5-1.5m e diffusione da 0.1-1m (tra cui 'Ericoides', 'Rubicon', 'Top Point').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , juniper scale and shoot-boring moths"; Malattie: "May be susceptible to honey fungus and Phytophthora root diseases"$t$,
    $t$Rusticità RHS: H6, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1.5m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required, but shaped subjects, including hedges , will need trimming twice a year"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by grafting and semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Chamaecyparis thyoides$t$),
  stato_verifica = 'verificato'
where slug = $t$chamaecyparis-thyoides$t$
  and not ($t$RHS (rhs.org.uk) — Chamaecyparis thyoides$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A vigorous evergreen conifer making a large tree with conical habit and distinctive, fibrous red-brown bark. Leaves short, awl-shaped, spirally arranged. Cones 2cm, globose, green becoming brown". RHS elenca 34 cultivar coltivate con altezze da 0.1-12m e diffusione da 0.1-8m (tra cui 'Antique Gold', 'Bandai-sugi', 'Barabits Gold', 'Black Dragon', 'Compressa', 'Cristata'...).$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to Phytophthora root rot and honey fungus (rarely)"$t$,
    $t$Rusticità RHS: H5, H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-12m, diffusione 0.1-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required but is one of few conifers that is suitable for coppicing"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed in spring or semi- hardwood cuttings in late summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Cryptomeria japonica$t$),
  stato_verifica = 'verificato'
where slug = $t$cryptomeria-japonica$t$
  and not ($t$RHS (rhs.org.uk) — Cryptomeria japonica$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A medium-sized, long-lived, evergreen tree, reaching to 15m in height, with a narrow, columnar habit. The dark green, scale-like leaves, 2-5mm long, are held in dense sprays on the rounded shoots of ascending branches. Cones are globose to oblong in shape, 2-3cm across, with scales having small bosses". RHS elenca 5 cultivar coltivate con altezze da 4-12m e diffusione da 0.5-4m (tra cui 'Green Pencil', 'Swane', 'Totem Pole').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to cypress aphid"; Malattie: "May be susceptible to coryneum canker and honey fungus"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 4-12m, diffusione 0.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Cupressus sempervirens$t$),
  stato_verifica = 'verificato'
where slug = $t$cupressus-sempervirens$t$
  and not ($t$RHS (rhs.org.uk) — Cupressus sempervirens$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A variable conifer species forming either a tall, conical or columnar tree to 18m in height or a spreading shrub. Two types of aromatic leaves are usually found on the same tree; juvenile, awl-shaped leaves that are sharply and stiffly pointed and arranged either in threes or pairs and scale-like adult leaves, usually in pairs and closely flattened to the branchlet. Rounded fruits, 5-7mm across, ripen in their second year to a glaucous white". RHS elenca 10 cultivar coltivate con altezze da 0.5-12m e diffusione da 0.1-8m (tra cui 'Aurea', 'Blaauw', 'Blue Alps', 'Expansa Variegata', 'Kaizuka', 'Obelisk'...).$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , scale insects , conifer red spider mite and caterpillars"; Malattie: "May be susceptible to Phytophthora , canker and honey fungus . See also Conifers: brown patches"$t$,
    $t$Rusticità RHS: H6, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-12m, diffusione 0.1-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Juniperus chinensis$t$),
  stato_verifica = 'verificato'
where slug = $t$juniperus-chinensis$t$
  and not ($t$RHS (rhs.org.uk) — Juniperus chinensis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A low-growing, widely spreading, evergreen shrub with bright green foliage and golden-yellow branch tips. Growth rate is slow to moderate, eventually reaching 30cm in height.". RHS elenca 2 cultivar coltivate con altezze da 0.1-0.5m e diffusione da 0.5-1m (tra cui 'Kishiogima', 'Nana').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , scale insects , conifer red spider mite and caterpillars"; Malattie: "May be susceptible to Phytophthora , canker and honey fungus . See also Conifers: brown patches"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Root semi- hardwood cuttings in early autumn. May be grafted to rootstock to create a standard tree."$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Juniperus procumbens$t$),
  stato_verifica = 'verificato'
where slug = $t$juniperus-procumbens$t$
  and not ($t$RHS (rhs.org.uk) — Juniperus procumbens$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Juniperus can be prostrate or erect, evergreen shrubs or trees with aromatic, scale-like or sharply pointed awl-shaped leaves, and small globose fruits".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Juniperus recurva$t$)
where slug = $t$juniperus-recurva$t$
  and not ($t$RHS (rhs.org.uk) — Juniperus recurva$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A slow-growing, compact, dwarf, evergreen conifer with dense blue-grey needle-like foliage.  Ideal for ground cover in rockeries". RHS elenca 2 cultivar coltivate con altezze da 0.1-1.5m e diffusione da 0.5-2.5m (tra cui 'Rockery Gem', 'Tamariscifolia').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , juniper scale and caterpillars"; Malattie: "May be susceptible to Phytophthora , canker and honey fungus . See also Conifers: brown patches"$t$,
    $t$Rusticità RHS: H6, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-1.5m, diffusione 0.5-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Juniperus sabina$t$),
  stato_verifica = 'verificato'
where slug = $t$juniperus-sabina$t$
  and not ($t$RHS (rhs.org.uk) — Juniperus sabina$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A species of low-growing, evergreen conifer with flaky brown bark and glaucous blue-green needle-like foliage.  Glossy, berry-like black cones appear in winter to early spring". RHS elenca 9 cultivar coltivate con altezze da 0.1-12m e diffusione da 0.1-8m (tra cui 'Blue Carpet', 'Blue Spider', 'Blue Star', 'Holger', 'Hunnetorp', 'Little Joanna'...).$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , juniper scale and caterpillars"; Malattie: "May be susceptible to Phytophthora , canker and honey fungus . See also Conifers: brown patches"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-12m, diffusione 0.1-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Juniperus squamata$t$),
  stato_verifica = 'verificato'
where slug = $t$juniperus-squamata$t$
  and not ($t$RHS (rhs.org.uk) — Juniperus squamata$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Thuja are fast-growing evergreen trees of narrowly conical habit, with flat sprays of tiny, aromatic, scale-like leaves and small knobbly cones". RHS elenca 26 cultivar coltivate con altezze da 0.1-12m e diffusione da 0.1-4m (tra cui 'Amber Glow', 'Anniek', 'Brabant', 'Brobeck', 'Danica', 'Degroot'...).$t$,
  alert = alert || ARRAY[
    $t$Rusticità RHS: H6, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-12m, diffusione 0.1-4m$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Thuja occidentalis$t$),
  stato_verifica = 'verificato'
where slug = $t$thuja-occidentalis$t$
  and not ($t$RHS (rhs.org.uk) — Thuja occidentalis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Thuja are fast-growing evergreen trees of narrowly conical habit, with flat sprays of tiny, aromatic, scale-like leaves and small knobbly cones".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Thuja orientalis$t$)
where slug = $t$thuja-orientalis$t$
  and not ($t$RHS (rhs.org.uk) — Thuja orientalis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen dwarf conifer growing slowly to make a small ovoid shrub with dense, erect sprays of yellow-green foliage, brightest at the tips". RHS elenca 5 cultivar coltivate con altezze da 0.5-12m e diffusione da 0.5-4m (tra cui 'Aurea Nana', 'Elegantissima', 'Pyramidalis Aurea', 'Southport', 'Franky Boy').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to a canker"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-12m, diffusione 0.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Platycladus orientalis$t$),
  stato_verifica = 'verificato'
where slug = $t$thuja-orientalis$t$
  and not ($t$RHS (rhs.org.uk) — Platycladus orientalis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Xanthocyparis are evergreen trees with much-branched sprays of small scale-like leaves and roughly spherical cones that mature in two years". RHS elenca 3 cultivar coltivate con altezze da 8-12m e diffusione da 1-8m (tra cui 'Green Arrow', 'Pendula').$t$,
  alert = alert || ARRAY[
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 8-12m, diffusione 1-8m$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Xanthocyparis nootkatensis$t$),
  stato_verifica = 'verificato'
where slug = $t$chamaecyparis-nootkatensis$t$
  and not ($t$RHS (rhs.org.uk) — Xanthocyparis nootkatensis$t$ = any(fonti));

