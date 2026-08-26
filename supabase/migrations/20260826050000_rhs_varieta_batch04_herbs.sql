-- RHS Fase 5, batch 04: aromatiche/orto (Anthriscus, Atriplex, Borago,
-- Carum, Coriandrum, Foeniculum, Hyssopus, Melissa, Mentha, Origanum,
-- Satureja, Thymus, Malva), piante da appartamento/collezione (Ananas,
-- Monstera, Galanthus, Humulus, Jasminum, Lathyrus, Petunia, Cyperus,
-- Schisandra, Phalaenopsis). Stessa pipeline/convenzioni dei batch
-- precedenti (vedi scripts/rhs-import/README.md). Include anche 2 nuove
-- specie mai presenti in catalogo (Cyperus involucratus, Cheilanthes
-- maderensis), scritte a mano sotto perche' INSERT e non UPDATE.


update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An upright annual herb approximately 60cm tall, cultivated for its aromatic leaves. Aniseed-flavoured, lacy, 2- to 3-pinnate leaves. with ovate leaflets are 3-5 cm large. Umbels of small white flowers, 5-7cm across are borne in summer. Chervil is commonly used to season fish dishes and sauces".$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to slugs , snails and caterpillar damage on young growth"; Malattie: "Generally disease- free"$t$,
    $t$Rusticità RHS: H4 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Harvest leaves regularly to promote new, fresh growth."$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed sown in spring and early summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Anthriscus cerefolium$t$),
  stato_verifica = 'verificato'
where slug = $t$anthriscus-cerefolium$t$
  and not ($t$RHS (rhs.org.uk) — Anthriscus cerefolium$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A compact semi-evergreen shrub to 2m, with striking, silvery-grey ovate leaves to 5cm long; occasionally bears insignificant greenish flowers in loose sprays in summer".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H4 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-2.5m, diffusione 1-1.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Root softwood cuttings in summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Atriplex halimus$t$),
  stato_verifica = 'verificato'
where slug = $t$atriplex-halimus$t$
  and not ($t$RHS (rhs.org.uk) — Atriplex halimus$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large, branched annual with coarsely hairy, ovate leaves and branched cymes of starry, bright blue flowers 2cm across over a long period in summer". RHS elenca 2 cultivar coltivate con altezze da 0.5-1m e diffusione da 0.1-0.5m (tra cui 'Alba').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Foliage may be damaged by slugs and leaf-mining flies"; Malattie: "May be susceptible to Powdery mildews"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Leave to self-seed after flowering"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Borago officinalis$t$),
  stato_verifica = 'verificato'
where slug = $t$borago-officinalis$t$
  and not ($t$RHS (rhs.org.uk) — Borago officinalis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An upright biennial with aromatic, 2- to 3-pinnate leaves divided into linear segments, and umbels of small white flowers in summer, followed by strongly aromatic fruits".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Argilloso, franco; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Leave to set seed"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed, transplant seedlings when small to avoid bolting"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Carum carvi$t$),
  stato_verifica = 'verificato'
where slug = $t$carum-carvi$t$
  and not ($t$RHS (rhs.org.uk) — Carum carvi$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An annual with aromatic, pinnate to 3-pinnate leaves, the upper ones with linear segments, and compound umbels of small white or purplish flowers, followed by aromatic fruits used in cooking". RHS elenca 10 cultivar coltivate con altezze da 0.1-0.5m e diffusione da 0.1-0.5m (tra cui 'Calypso', 'Commander', 'Confetti', 'Cruiser', 'Filtro', 'Leisure'...).$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids"; Malattie: "May be susceptible to Powdery mildews"$t$,
    $t$Rusticità RHS: H2, H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed sown in modules or open ground.  Self-seeding is common.  See sowing seeds indoors for further advice"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Coriandrum sativum$t$),
  stato_verifica = 'verificato'
where slug = $t$coriandrum-sativum$t$
  and not ($t$RHS (rhs.org.uk) — Coriandrum sativum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A hardy, upright, aromatic perennial, or an annual if grown as an edible, to around 180cm in height, with feathery foliage which can be green or tinted bronze or purple, depending on the cultivar.  The foliage has a sweet aniseed fragrance and taste.  Branching stems of flat-topped, sulphur-yellow flowers appear in summer, followed by oval-shaped, bright green seed/fruit pods which turn yellowish-brown when dried.  These can be used to flavour dished with a warm, sweet, aromatic taste". RHS elenca 10 cultivar coltivate con altezze da 0.5-2.5m e diffusione da 0.1-1m (tra cui 'Giant Bronze', 'Purpureum', 'Sweet Florence', 'Dragon', 'Orion', 'Romanesco'...).$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids and slugs"; Malattie: "May be susceptible to root rots and Powdery mildews"$t$,
    $t$Rusticità RHS: H3, H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-2.5m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Cut back dead stems in autumn or winter. Remove faded flowers to prevent self-seeding"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed.  See sowing vegetable seeds"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Foeniculum vulgare$t$),
  stato_verifica = 'verificato'
where slug = $t$foeniculum-vulgare$t$
  and not ($t$RHS (rhs.org.uk) — Foeniculum vulgare$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A compact, spreading, semi-evergreen sub-shrub with erect shoots bearing aromatic, linear leaves and terminal spikes of whorled, 2-lipped, tubular blue flowers in summer and early autumn". RHS elenca 4 cultivar coltivate con altezze da 0.1-1m e diffusione da 0.5-1m (tra cui 'Roseus').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, franco; pH alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to leafhoppers"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 10 in mid-spring"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or softwood cuttings in summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Hyssopus officinalis$t$),
  stato_verifica = 'verificato'
where slug = $t$hyssopus-officinalis$t$
  and not ($t$RHS (rhs.org.uk) — Hyssopus officinalis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An aromatic, bushy perennial up to 1m tall and wide. Heart-shaped leaves are lemon-scented with scalloped edges are 2-8 cm long. Leafy spikes of creamy-white or pale purple flowers are full of nectar, attracting bees and other pollinators in summer. The leaves are often used as a culinary herb". RHS elenca 4 cultivar coltivate con altezze da 0.1-1m e diffusione da 0.1-0.5m (tra cui 'All Gold', 'Aurea', 'Lime Balm').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to sage leafhopper"; Malattie: "Generally disease-free. Verticillium wilt may rarely occur"$t$,
    $t$Rusticità RHS: H5, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-1m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Cut back hard after flowering to promote fresh leaf growth and to prevent self-seeding. See lemon-balm cultivation for more advice"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed or by division in spring or autumn"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Melissa officinalis$t$),
  stato_verifica = 'verificato'
where slug = $t$melissa-officinalis$t$
  and not ($t$RHS (rhs.org.uk) — Melissa officinalis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A strongly aromatic, herbaceous perennial with stems and leaves flushed with purple. It produces terminal spikes of tiny, pale purple flowers in late summer". RHS elenca 17 cultivar coltivate con altezze da 0.1-1m e diffusione da 0.1-1.5m (tra cui 'After Eight', 'Black Mitcham', 'Logee', 'Strawberry', 'Swiss', 'Basil'...).$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to leafhoppers and caterpillars"; Malattie: "May be susceptible to Powdery mildews and mint rust"$t$,
    $t$Rusticità RHS: H4, H5, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-1m, diffusione 0.1-1.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Cut back after flowering"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division in spring or autumn"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Mentha × piperita$t$),
  stato_verifica = 'verificato'
where slug = $t$mentha-piperita$t$
  and not ($t$RHS (rhs.org.uk) — Mentha × piperita$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An upright, tender perennial sub-shrub, 30-50cm tall, often grown as an annual or biennial; with aromatic, oval, softly hairy, edible grey-green leaves 1.5cm long and 1cm wide. Small, tubular, white flowers are held on wiry, somewhat feather-like stems in summer.  Recommended in culinary circles for its flavour".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, franco; pH neutro, alcalino"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids and red spider mite"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H2 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Cut back old flower stems in early spring"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed, or by division or basal softwood cuttings in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Origanum majorana$t$),
  stato_verifica = 'verificato'
where slug = $t$origanum-majorana$t$
  and not ($t$RHS (rhs.org.uk) — Origanum majorana$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A bushy annual plant to 25cm tall, with narrowly lance-shaped, aromatic, 3cm long leaves and spikes carrying up to five, whorled white flowers in summer".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, franco, sabbioso; pH alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H4 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Satureja hortensis$t$),
  stato_verifica = 'verificato'
where slug = $t$satureja-hortensis$t$
  and not ($t$RHS (rhs.org.uk) — Satureja hortensis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A bushy, dwarf, evergreen shrub up to 30cm tall and 40cm wide; with small, linear to ovate, aromatic, dark grey-green leaves, and terminal spikes of small, whorled, white or pink flowers in early summer. Thyme is a popular culinary herb, with various cultivars available. The flowers are favoured by bees and other pollinators". RHS elenca 2 cultivar coltivate con altezze da 0.1-0.5m e diffusione da 0.1-0.5m (tra cui 'Compactus').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Calcareo, franco, sabbioso; pH alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Cut back in spring"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed, by division or plant rooted basal stem cuttings in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Thymus vulgaris$t$),
  stato_verifica = 'verificato'
where slug = $t$thymus-vulgaris$t$
  and not ($t$RHS (rhs.org.uk) — Thymus vulgaris$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An erect perennial that throws up flowering spikes up to 1.5m in height in summer and autumn. Flowers are grouped in the leaf axils and are five-petalled, notched and pink. Leaves are rounded at the base of the plant, but five-lobed on the stems". RHS elenca 6 cultivar coltivate con altezze da 0.1-2.5m e diffusione da 0.1-1m (tra cui 'Blue Fountain', 'Dema', 'Mystic Merlin', 'Primley Blue', 'Zebrina').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to hollyhock rust and in turn infect cultivated hollyhocks"$t$,
    $t$Rusticità RHS: H4, H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-2.5m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Malva sylvestris$t$),
  stato_verifica = 'verificato'
where slug = $t$malva-sylvestris$t$
  and not ($t$RHS (rhs.org.uk) — Malva sylvestris$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen perennial forming rosettes of deep green, spiny, lance-shaped leaves. Dense spikes of tubular purple flowers with reddish bracts in summer are followed by edible pineapples". RHS elenca 3 cultivar coltivate con altezze da 0.1-1m e diffusione da 0.1-1m (tra cui 'Champaca').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Franco; pH acido"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to scale insects"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1A (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-1m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Root basal offsets in early summer, or sever the leafy rosette at the top of the fruit, allow it a day or two to callus then root it in a barely-moist mix of peat substitute and sand in indirect light at 21°C"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Ananas comosus$t$),
  stato_verifica = 'verificato'
where slug = $t$ananas-comosus$t$
  and not ($t$RHS (rhs.org.uk) — Ananas comosus$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A tropical evergreen climber, with heart-shaped, pinnatisect and often perforated, glossy deep green leaves. This cultivar is more compact than the species, growing to around 2.5m high". RHS elenca 4 cultivar coltivate con altezze da 1.5-8m e diffusione da 1-2.5m (tra cui 'Tauerii', 'Thai Constellation', 'Variegata').$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to scale insects and glasshouse red spider mite"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1B (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-8m, diffusione 1-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 11"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed, root tip or stem cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Monstera deliciosa$t$),
  stato_verifica = 'verificato'
where slug = $t$monstera-deliciosa$t$
  and not ($t$RHS (rhs.org.uk) — Monstera deliciosa$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A perennial to 15cm, with narrow, grey-green leaves and solitary, nodding, fragrant white flowers 2.5cm in length, the inner segments marked with green at the tip". RHS elenca 18 cultivar coltivate con altezze da 0.1-10m e diffusione da 0-0.5m (tra cui 'Alan', 'Anglesey Abbey', 'Pewsey Vale', 'Tiny', 'Virescens', 'Viridapice'...).$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to narcissus bulb fly"; Malattie: "May be susceptible to snowdrop grey mould"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-10m, diffusione 0-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed, sown in containers in an open frame when ripe or division when foliage dies back. Seed may not come true"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Galanthus nivalis$t$),
  stato_verifica = 'verificato'
where slug = $t$galanthus-nivalis$t$
  and not ($t$RHS (rhs.org.uk) — Galanthus nivalis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A vigorous, twining, herbaceous climber to 6m tall with hairy, rough stems and toothed, three or five-lobed, yellowish-green leaves that turn golden-yellow in autumn. Greenish-yellow aromatic flower spikes become pendent clusters of papery, cone-shaped hops in autumn". RHS elenca 6 cultivar coltivate con altezze da 1.5-12m e diffusione da 0.5-2.5m (tra cui 'Aureus', 'Aureus', 'Golden Tassels', 'Prima Donna').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids and glasshouse red spider mite"; Malattie: "May be susceptible to downy mildews"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-12m, diffusione 0.5-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Remove excess shoots if necessary; the hops can be harvested, or the bines can be cut for decorations, in early autumn; cut to ground level in autumn"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by softwood cuttings, root cuttings, or division"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Humulus lupulus$t$),
  stato_verifica = 'verificato'
where slug = $t$humulus-lupulus$t$
  and not ($t$RHS (rhs.org.uk) — Humulus lupulus$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A large, usually deciduous, climber reaching up to 12m in height, with green branches bearing mid-green leaves with 7-9 leaflets. Very fragrant, white flowers 2cm in width open in terminal clusters of 3 to 10 in summer and early autumn, sometimes followed by blackish-purple fruits". RHS elenca 8 cultivar coltivate con altezze da 2.5-12m e diffusione da 0.5-8m (tra cui 'Argenteovariegatum', 'Aureum', 'Devon Cream', 'Inverleith', 'Frojas', 'Lowbeam').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , scale insects and mealybugs and glasshouse red spider mite under glass"; Malattie: "May be susceptible to honey fungus (rarely)"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-12m, diffusione 0.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Prune out thin, old shoots after flowering"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by layering , hardwood cuttings or semi- hardwood cuttings"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Jasminum officinale$t$),
  stato_verifica = 'verificato'
where slug = $t$jasminum-officinale$t$
  and not ($t$RHS (rhs.org.uk) — Jasminum officinale$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An annual that climbs to about 2m using tendrils. The flowers, produced in summer and early autumn, are 3.5cm across, strongly-scented, with wine-red standard petals and purple wings and keels. Hundreds of cultivars have been raised, a few of which can be seen here". RHS elenca 86 cultivar coltivate con altezze da 0.1-2.5m e diffusione da 0.1-1m (tra cui 'Alisa', 'Almost Black', 'America', 'Aphrodite', 'Ballerina Blue', 'Bobby'...).$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , slugs and snails"; Malattie: "May be susceptible to Powdery mildews , Fusarium wilt and sweet pea viruses"$t$,
    $t$Rusticità RHS: H2, H3, H4 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-2.5m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "deadhead regularly and cut back after flowering"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed. Sow in a cold frame in early autumn, early spring or in-situ in mid-spring.  See sowing seeds indoors for further advice"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Lathyrus odoratus$t$),
  stato_verifica = 'verificato'
where slug = $t$lathyrus-odoratus$t$
  and not ($t$RHS (rhs.org.uk) — Lathyrus odoratus$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A bushy annual to 30cm, with trumpet-shaped, single, lavender-purple flowers to 7cm diameter, the throat yellow". RHS elenca 13 cultivar coltivate con altezze da 0.1-2.5m e diffusione da 0.1-1m (tra cui 'Storm Lavender', 'Storm Pink', 'Storm Salmon', 'Pas1085269').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , slugs and snails"; Malattie: "May be susceptible to grey moulds , foot rot and a virus"$t$,
    $t$Rusticità RHS: H2 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-2.5m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Petunia × atkinsiana$t$),
  stato_verifica = 'verificato'
where slug = $t$petunia-hybrida$t$
  and not ($t$RHS (rhs.org.uk) — Petunia × atkinsiana$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A tender aquatic perennial forming a clump of erect stems with rounded umbels to 30cm wide, composed of many slender stalks each bearing a small light brown flower-head". RHS elenca 3 cultivar coltivate con altezze da 1-4m e diffusione da 0.1-1m (tra cui 'Nanus').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Poco drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1C (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1-4m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Cut back dead material in autumn"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed at 18 to 21°C in spring in constantly moist seed compost"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Cyperus papyrus$t$),
  stato_verifica = 'verificato'
where slug = $t$cyperus-papyrus$t$
  and not ($t$RHS (rhs.org.uk) — Cyperus papyrus$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A twining, deciduous climber. Flowers are typically white and with male and female flowers being borne on separate plants, in late spring and into summer, both sexes are required to produce the hanging red fruit in autumn".$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, franco; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H4 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 8-12m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 12 in early spring"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by seed sown in containers in a cold frame as soon as ripe. Propagate by softwood cuttings ( greenwood ) in early or mid-summer or semi-ripe cuttings in summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Schisandra grandiflora$t$),
  stato_verifica = 'verificato'
where slug = $t$schisandra-grandiflora$t$
  and not ($t$RHS (rhs.org.uk) — Schisandra grandiflora$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An upright orchid with between 3 and 5 broadly oval, fleshy leaves which grow to 50cm long. Numerous, scented, long-lasting white flowers, up to 10cm across, with a white and yellow lip and red throat are borne from autumn to early spring on branched racemes up to 1m tall".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Ben drenato", "terreno": "Franco; pH neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to aphids , glasshouse red spider mite , and mealybugs"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1A (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Cut back flowered stems to a lower node to encourage the production of further flowers"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Cuttings or offshoots (keikis) may root successfully when roots are 2cm long"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Phalaenopsis amabilis$t$),
  stato_verifica = 'verificato'
where slug = $t$phalaenopsis-amabilis$t$
  and not ($t$RHS (rhs.org.uk) — Phalaenopsis amabilis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Phalaenopsis are a large genus of species and hybrid mainly epiphytic orchids. Short, upward growing, stem-like rhizomes with no pseudobulbs produce oval, fleshy mid to dark green leaves and flowers in branched racemes from the base of the leaves".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Phalaenopsis amboinensis$t$)
where slug = $t$phalaenopsis-amboinensis$t$
  and not ($t$RHS (rhs.org.uk) — Phalaenopsis amboinensis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Phalaenopsis are a large genus of species and hybrid mainly epiphytic orchids. Short, upward growing, stem-like rhizomes with no pseudobulbs produce oval, fleshy mid to dark green leaves and flowers in branched racemes from the base of the leaves".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Phalaenopsis aphrodite$t$)
where slug = $t$phalaenopsis-aphrodite$t$
  and not ($t$RHS (rhs.org.uk) — Phalaenopsis aphrodite$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A small, epiphytic, evergreen orchid with broadly-oval, fleshy leaves up to 20cm long and 3-4cm wide. From spring to winter, bears simple or branched, upright or arching racemes, up to 35cm long. Small flowers up to 2cm across are pale pink with deep pink or purple lip, streaked with dark red".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Ben drenato", "terreno": "pH neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to mealybugs , aphids and scale insects"; Malattie: "Generally disease-free. Avoid watering centre of the leaf crown, to prevent bacterial rots"$t$,
    $t$Rusticità RHS: H1A (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required. Cut back green flowered stem to lower node to encourage further flowering. Remove the flowered stems once yellow and dry"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagation by seed is only possible in controlled laboratory environment. Mature plants may produce sideshoots (keiki) which may be removed and potted separately into sphagnum moss when the new roots are at least 2cm long"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Phalaenopsis equestris$t$),
  stato_verifica = 'verificato'
where slug = $t$phalaenopsis-equestris$t$
  and not ($t$RHS (rhs.org.uk) — Phalaenopsis equestris$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen, epiphytic orchid with semi-pendent, broadly-elliptic, fleshy leaves. The leaves are up to 45cm long and 5-7cm wide, dark green with silver-grey spotted marbling on the top and purple overlay underneath. Rose-pink flowers, 5-9cm across, with purple or yellow lip appear in branching racemes in winter and spring. Plants grown in optimal conditions are able to produce large number of flowers (up to 250) on stems 90-100cm long. Mounted plants will develop more pendulous habit".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Ben drenato", "terreno": "pH neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to mealybugs , aphids and scale insects"; Malattie: "Generally disease-free. Avoid watering centre of the leaf crown, to prevent bacterial rots"$t$,
    $t$Rusticità RHS: H1A (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required. Cut back green flowered stem to lower node to encourage further flowering. Remove the flowered stems once yellow and dry"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagation by seed is only possible in controlled laboratory environment. Mature plants may produce sideshoots (keiki) which may be removed and potted separately into sphagnum moss when the new roots are at least 2cm long"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Phalaenopsis schilleriana$t$),
  stato_verifica = 'verificato'
where slug = $t$phalaenopsis-schilleriana$t$
  and not ($t$RHS (rhs.org.uk) — Phalaenopsis schilleriana$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A medium-sized, evergreen, epiphytic orchid with semi-pendant, broadly-oval, mid-green fleshy leaves up to 35cm long and 5-9cm wide. The leaves are mottled grey-green above and purple underneath. In winter and spring, it bears branching racemes up to 1m long, carrying many white, 8cm large flowers with yellow marks and brown-red spots on the lower sepals and lip. In optimal conditions, plants are able to produce as many as a hundred, long-lasting flowers. Mounted plants will develop a more pendulous habit".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Ben drenato", "terreno": "pH neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to mealybugs , aphids and scale insects"; Malattie: "Generally disease-free; avoid watering centre of the leaf crown, to prevent bacterial rots"$t$,
    $t$Rusticità RHS: H1A (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required. Cut back green flowered stem to lower node to encourage further flowering. Remove the flowered stems once yellow and dry"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagation by seed is only possible in controlled laboratory environment. Mature plants may produce sideshoots (keiki) which may be removed and potted separately into orchid propagation mix when the new roots are at least 2cm long"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Phalaenopsis stuartiana$t$),
  stato_verifica = 'verificato'
where slug = $t$phalaenopsis-stuartiana$t$
  and not ($t$RHS (rhs.org.uk) — Phalaenopsis stuartiana$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A small-sized, evergreen, epiphytic orchid with three to four, elliptic leaves, 20-25cm long and 4cm wide. In spring and summer, up to 7 flowers are borne in succession on 15cm short, pendent or arching racemes. 3-4cm large, star-shaped flowers fragrant, waxy, rich-violet, purple, yellow and white flowers with purple-red lip. If mounted on bark, plant will develop more pendulous habit".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Ben drenato", "terreno": "pH neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to mealybugs , aphids and scale insects"; Malattie: "Generally disease-free. Avoid watering centre of the leaf crown, to prevent bacterial rots"$t$,
    $t$Rusticità RHS: H1A (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required. Cut back green flowered stem to lower node to encourage further flowering. Remove the flowered stems once yellow and dry"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagation by seed is only possible in controlled laboratory environment. Mature plants may produce sideshoots (keiki) which may be removed and potted separately into sphagnum moss when the new roots are at least 2cm long"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Phalaenopsis violacea$t$),
  stato_verifica = 'verificato'
where slug = $t$phalaenopsis-violacea$t$
  and not ($t$RHS (rhs.org.uk) — Phalaenopsis violacea$t$ = any(fonti));


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

