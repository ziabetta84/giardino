-- Fase 5, RHS varieta, batch arbusti 02 (residuo): le 20 specie del
-- batch arbusti 01 che non avevano ricevuto il contenuto RHS reale a causa
-- dell'incidente del 2026-08-27 (query troncata durante la trascrizione
-- manuale). Stessa pipeline/convenzioni delle Fase 5 originale. Sinonimo:
-- "Vesalea floribunda" e' il nome oggi accettato da RHS per Kolkwitzia
-- amabilis (gia' in catalogo con questo nome).


update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous small tree, up to around 8m high, with a spreading habit, and oval leaves that are tinted pink and bronze when young, and turn orange and red in autumn. Pendent clusters of fragrant white flowers are produced in spring as the leaves unfurl, followed later by edible blue-black berries". RHS elenca 5 cultivar coltivate con altezze da 2.5-12m e diffusione da 2.5-8m (tra cui 'Prince Charles', 'R.J. Hilton', 'Snow Cloud', 'Snowflakes').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to fireblight"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-12m, diffusione 2.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Minimal pruning required; see pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or by semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Amelanchier laevis$t$),
  stato_verifica = 'verificato'
where slug = $t$amelanchier-laevis$t$
  and not ($t$RHS (rhs.org.uk) — Amelanchier laevis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large erect deciduous shrub or small tree of open habit, with bronze-tinged young leaves turning orange and red in autumn. White flowers appear in short, lax racemes as the leaves unfurl followed by edible red to dark purple-black berries". RHS elenca 2 cultivar coltivate con altezze da 2.5-12m e diffusione da 1.5-8m (tra cui 'Snowberry').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to fireblight and honey fungus"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-12m, diffusione 1.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed and semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Amelanchier lamarckii$t$),
  stato_verifica = 'verificato'
where slug = $t$amelanchier-lamarckii$t$
  and not ($t$RHS (rhs.org.uk) — Amelanchier lamarckii$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous, spreading shrub to around 100cm in height, producing hairy, grey-white shoots and feathery, grey-green aromatic leaves, 6-15cm long, made up of 10-20 pairs of overlapping, oval leaflets.  Tall spikes of small, dark violet-purple to purple-blue flowers with orange anthers appear from late summer through to early autumn".$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Ben drenato, umido ma ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to rust diseases and Powdery mildews"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 6"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed. Sow pre-soaked or scarified seed in autumn in containers in an open frame. Separate rooted suckers in autumn or winter"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Amorpha canescens$t$),
  stato_verifica = 'verificato'
where slug = $t$amorpha-canescens$t$
  and not ($t$RHS (rhs.org.uk) — Amorpha canescens$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A vigorous deciduous shrub of spreading habit, with leaves composed of up to 30 oval leaflets, and slender racemes to 15cm in length, of deep purple flowers with orange anthers".$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Ben drenato", "terreno": "Franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "a rust may occur (N. America only)"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-4m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 6"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed in autumn. Seed must be scarified as they have hard seed coats. Use sandpaper or a file to scarify (abrade) the seed coat. Chit the seed either by using a knife to nick the seed coat or by soaking the seed in warm water for 24 hours. Care should be taken when soaking seed, as too much can cause rotting. Sow at any time of year 2mm deep in moist, free-draining, quality seed compost. Propagate at 10-15C in a greenhouse, on a windowsill or in a coldframe outdoors in spring. Germination should take place in 30-120 days"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Amorpha fruticosa$t$),
  stato_verifica = 'verificato'
where slug = $t$amorpha-fruticosa$t$
  and not ($t$RHS (rhs.org.uk) — Amorpha fruticosa$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A branching deciduous shrub reaching 3m tall and 2.5m wide if left unpruned. It has dark green leaves, downy on the under side, which become scarlet in autumn. In spring, white flowers in clusters, develop into downy red berries". RHS elenca 2 cultivar coltivate con altezze da 1.5-4m e diffusione da 1-2.5m (tra cui 'Erecta').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-4m, diffusione 1-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 or pruning group 2"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate from softwood cuttings or from seed - for more advice see Propagate from seed (tree/shrub"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Aronia arbutifolia$t$),
  stato_verifica = 'verificato'
where slug = $t$aronia-arbutifolia$t$
  and not ($t$RHS (rhs.org.uk) — Aronia arbutifolia$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A compact, deciduous shrub to around 2m tall with dark green leaves that turn orange and red in autumn. Small clusters of white flowers borne in late spring and early summer are followed by shiny black fruits in autumn". RHS elenca 2 cultivar coltivate con altezze da 1.5-2.5m e diffusione da 2.5-4m (tra cui 'Hugin').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-2.5m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 or pruning group 2"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by softwood cuttings in early summer, or propagate from suckers when plants are dormant"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Aronia melanocarpa$t$),
  stato_verifica = 'verificato'
where slug = $t$aronia-melanocarpa$t$
  and not ($t$RHS (rhs.org.uk) — Aronia melanocarpa$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A compact, deciduous shrub about 1.5m tall, with olive green leaves to 3cm long, blue-green beneath, with toothed margins, and turning red in autumn. Small, pale yellow flowers in dense panicles to 4cm long in late spring and early summer are followed in autumn by spherical red fruit to 7mm long, tinged grey".$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids and berberis sawfly"; Malattie: "May be susceptible to Powdery mildews and sometimes by honey fungus"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1-1.5m, diffusione 1.5-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 2 ; trim hedges after flowering"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed in early spring; by semi-ripe cuttings in summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Berberis aggregata$t$),
  stato_verifica = 'verificato'
where slug = $t$berberis-aggregata$t$
  and not ($t$RHS (rhs.org.uk) — Berberis aggregata$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An upright, semi-evergreen to evergreen shrub with arching branches of oval-shaped, leathery mid to dark green foliage.  Yellow-orange flowers appear in the spring, followed by blue-black fruit in autumn.  Known as 'The calafate', it is a symbol of Patagonia.  Fruits are edible and can be used for making jams, beer or for eating fresh but care must be taken to esure that you are consuming berries from this variety and not other Berberis which may be toxic".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids and berberis sawfly"; Malattie: "May be susceptible to Powdery mildews"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-2.5m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 8"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Berberis buxifolia$t$),
  stato_verifica = 'verificato'
where slug = $t$berberis-buxifolia$t$
  and not ($t$RHS (rhs.org.uk) — Berberis buxifolia$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A dense, evergreen shrub to about 3m in height if left unchecked, with dark glossy green, broadly oblong, sparsely-spined leaves.  Drooping racemes of rich orange flowers, tinged red in bud, are produced in mid and late spring, and sometimes again in autumn.  These are followed by blue-black berries in autumn". RHS elenca 2 cultivar coltivate con altezze da 0.5-4m e diffusione da 0.5-4m (tra cui 'Compacta').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids and berberis sawfly"; Malattie: "May be susceptible to Powdery mildews and sometimes by honey fungus"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-4m, diffusione 0.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 8 ; trim hedges after flowering"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or from semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Berberis darwinii$t$),
  stato_verifica = 'verificato'
where slug = $t$berberis-darwinii$t$
  and not ($t$RHS (rhs.org.uk) — Berberis darwinii$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A compact evergreen shrub to 3m, with rigid, glossy elliptic leaves and racemes of yellow flowers, tinged with red, in late spring. Bloomy black berries in autumn".$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids and berberis sawfly"; Malattie: "May be susceptible to Powdery mildews and sometimes by honey fungus"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-4m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 8"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or from semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Berberis julianae$t$),
  stato_verifica = 'verificato'
where slug = $t$berberis-julianae$t$
  and not ($t$RHS (rhs.org.uk) — Berberis julianae$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A very hardy, spiny, multi-stemmed semi-evergreen shrub with a rounded habit and oval-shaped green foliage in summer which turns dark red to dark purple in the autumn.  Clusters of drooping, golden-yellow flowers appear in spring, followed by bright red berries in autumn".$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids and berberis sawfly"; Malattie: "May be susceptible to Powdery mildews"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-2.5m, diffusione 1.5-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 8"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Berberis koreana$t$),
  stato_verifica = 'verificato'
where slug = $t$berberis-koreana$t$
  and not ($t$RHS (rhs.org.uk) — Berberis koreana$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A vigorous, deciduous, evergreen shrub about 2.5m tall, arching stems and small, glossy, spine-tipped, dark green leaves. Clusters of large, rich orange flowers in late spring are followed by blue-black berries".$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids and berberis sawfly"; Malattie: "May be susceptible to Powdery mildews and sometimes by honey fungus"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-2.5m, diffusione 1.5-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 or pruning group 8"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi-ripe cuttings in summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Berberis linearifolia$t$),
  stato_verifica = 'verificato'
where slug = $t$berberis-linearifolia$t$
  and not ($t$RHS (rhs.org.uk) — Berberis linearifolia$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "Dense, rounded deciduous shrub about 1m tall, with spiny fresh green leaves, bluish-green beneath, to 3cm long, turning red and orange in autumn. Racemes of small yellow flowers, flushed red on sepals, are produced along the branches in mid spring, glossy bright scarlet berries follow". RHS elenca 56 cultivar coltivate con altezze da 0.1-2.5m e diffusione da 0.1-2.5m (tra cui 'Aurea', 'Boum', 'Coronita', 'Desperados', 'Diabolic', 'Erecta'...).$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids and berberis sawfly"; Malattie: "May be susceptible to Powdery mildews and sometimes by honey fungus"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-2.5m, diffusione 0.1-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 2 ; trim hedges after flowering"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or propagate from softwood or semi-ripe cuttings in summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Berberis thunbergii$t$),
  stato_verifica = 'verificato'
where slug = $t$berberis-thunbergii$t$
  and not ($t$RHS (rhs.org.uk) — Berberis thunbergii$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous, prickly shrub reaching 2-3m in height. Clusters of hanging orange-yellow flowers are borne in late spring to early summer, followed by red, ovoid fruits. Twigs are grooved and prickles usually 3-forked. Leaves are green, entire, small-toothed and occur in groups".$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids and berberis sawfly"; Malattie: "May be susceptible to Powdery mildews and sometimes by honey fungus"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-4m, diffusione 1.5-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "If plants outgrow their space, prune after flowering, pruning group 1 or pruning group 2"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or by semi-ripe cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Berberis vulgaris$t$),
  stato_verifica = 'verificato'
where slug = $t$berberis-vulgaris$t$
  and not ($t$RHS (rhs.org.uk) — Berberis vulgaris$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large, strong-growing, spreading, evergreen shrub with arching shoots and small, spiny, glossy, dark green leaves. Clusters of small, rich orange flowers are produced in late spring, and often again in summer and autumn, followed by blue-black berries". RHS elenca 4 cultivar coltivate con altezze da 1.5-4m e diffusione da 1.5-4m (tra cui 'Mystery Fire', 'Stapehill', 'Apricot Queen').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids and berberis sawfly"; Malattie: "May be susceptible to Powdery mildews and sometimes by honey fungus"$t$,
    $t$Rusticità RHS: H5, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-4m, diffusione 1.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 8 ; trim hedges after flowering"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed in early spring; by semi-ripe cuttings in summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Berberis × lologensis$t$),
  stato_verifica = 'verificato'
where slug = $t$berberis-x-lologensis$t$
  and not ($t$RHS (rhs.org.uk) — Berberis × lologensis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A medium-sized, spiny evergreen shrub to 3m, compact in habit, with narrow rigid leaves and clusters of rich yellow/orange scented flowers along the arching branches. Berries blue-black. The new shoots are a striking deep red". RHS elenca 6 cultivar coltivate con altezze da 0.1-4m e diffusione da 0.1-4m (tra cui 'Claret Cascade', 'Corallina Compacta', 'Etna', 'Irwinii', 'Nana').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids and berberis sawfly"; Malattie: "May be susceptible to Powdery mildews"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-4m, diffusione 0.1-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 8 ; trim hedges after flowering"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi- hardwood cuttings in summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Berberis × stenophylla$t$),
  stato_verifica = 'verificato'
where slug = $t$berberis-x-stenophylla$t$
  and not ($t$RHS (rhs.org.uk) — Berberis × stenophylla$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A vigorous large deciduous shrub which can be trained into a small tree, with arching branches bearing narrow, grey-green leaves and sweetly scented lilac-purple flowers, borne in clusters along the previous year's shoots". RHS elenca 2 cultivar coltivate con altezze da 2.5-4m e diffusione da 2.5-4m (tra cui 'Argentea').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , capsid bugs, caterpillars, earwigs , figwort weevils, glasshouse red spider mite , leaf and bud eelworm , and mullein moth"; Malattie: "May be susceptible to honey fungus , fungal leaf spot, and virus diseases"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-4m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 2"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Buddleja alternifolia$t$),
  stato_verifica = 'verificato'
where slug = $t$buddleja-alternifolia$t$
  and not ($t$RHS (rhs.org.uk) — Buddleja alternifolia$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large, fast-growing, deciduous shrub, to 3m tall, with long, arching shoots and lance-shaped, pointed, green or grey-green leaves up to 25cm long. From summer to autumn it bears dense sprays, 30cm or more long, of small, fragrant flowers in various shades of purple". RHS elenca 80 cultivar coltivate con altezze da 0.1-8m e diffusione da 0.1-8m (tra cui 'Autumn Beauty', 'Black Knight', 'Blue Horizon', 'Border Beauty', 'Castle Blue', 'Corinne Tremaine'...).$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , capsid bugs, caterpillars, earwigs , figwort weevils, glasshouse red spider mite , leaf and bud eelworm , and mullein moth"; Malattie: "May be susceptible to honey fungus , fungal leaf spot, and virus diseases"$t$,
    $t$Rusticità RHS: H5, H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-8m, diffusione 0.1-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 6"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate semi-ripe cuttings in summer or hardwood cuttings in autumn"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Buddleja davidii$t$),
  stato_verifica = 'verificato'
where slug = $t$buddleja-davidii$t$
  and not ($t$RHS (rhs.org.uk) — Buddleja davidii$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "Spreading, deciduous shrub to 4m tall, with long arching stems bearing mid-green, lance-shaped leaves to 20cm long, grey-green when young. Rounded clusters of fragrant, pale orange flowers tinged pale purple, with an orange eye, produced in open terminal panicles, in summer and autumn". RHS elenca 8 cultivar coltivate con altezze da 1.5-4m e diffusione da 1-4m (tra cui 'Bicolor', 'Boy Blue', 'Golden Glow', 'Honeycomb', 'Moonlight', 'Pink Pagoda'...).$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , capsid bugs, caterpillars, earwigs , figwort weevils, glasshouse red spider mite , leaf and bud eelworm , and mullein moth"; Malattie: "May be susceptible to honey fungus , fungal leaf spot, and virus diseases"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-4m, diffusione 1-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 6 in spring"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Take softwood cuttings in spring and summer, semi-ripe cuttings from midsummer or root hardwood cuttings from autumn to midwinter and keep frost free"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Buddleja × weyeriana$t$),
  stato_verifica = 'verificato'
where slug = $t$buddleja-x-weyeriana$t$
  and not ($t$RHS (rhs.org.uk) — Buddleja × weyeriana$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "a semi-evergreen or evergreen medium shrub with shiny ovate leaves and clusters of tubular cerise flowers to 5cm long in early summer".$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H4 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-4m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 8"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by greenwood cuttings in early summer or by semi-ripe cuttings in late summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Vesalea floribunda$t$),
  stato_verifica = 'verificato'
where slug = $t$kolkwitzia-amabilis$t$
  and not ($t$RHS (rhs.org.uk) — Vesalea floribunda$t$ = any(fonti));

