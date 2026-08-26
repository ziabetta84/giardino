-- RHS Fase 5, batch 01: felci (Adiantum, Asplenium, Athyrium, Blechnum,
-- Cheilanthes, Cibotium, Cyathea, Cyrtomium, Cystopteris, Davallia,
-- Dennstaedtia, Dicksonia, Didymochlaena, Doryopteris, Dryopteris,
-- Gymnocarpium, Humata, Matteuccia, Microlepia, Nephrolepis, Onoclea,
-- Osmunda, Pellaea, Phlebodium, Pilularia, Platycerium, Polypodium,
-- Polystichum, Pteridium, Pteris, Salvinia, Thelypteris, Woodsia,
-- Woodwardia). Fonte: RHS (rhs.org.uk), 1211 pagine scaricate localmente
-- dall'utente in fonti/rhs-varieta/ (specie + tutte le cultivar reperibili),
-- poi estratte con script Python (parse_rhs.py + aggregate_rhs.py) che
-- isola i campi strutturati (Position/Soil/Moisture/pH/Hardiness/Max
-- Height/Spread) e le sezioni di testo libero (Cultivation, Propagation,
-- Pruning, Pests, Diseases) di ogni pagina RHS.
--
-- Decisioni applicate (concordate con l'utente):
-- - Granularita' riga: SOLO la specie base riceve/arricchisce una riga;
--   le cultivar (fino a 127 per una singola specie, es. Acer palmatum in
--   batch successivi) sono riassunte in descrizione (conteggio, range di
--   altezza/diffusione, nomi di esempio), non una riga per cultivar.
-- - Testo libero RHS (descrizione, parassiti, malattie, potatura,
--   propagazione) tenuto in inglese originale e marcato come tale in
--   alert/descrizione, stessa convenzione gia' usata per i rischi PFAF:
--   evita il rischio di traduzione errata su migliaia di frasi.
-- - Campi strutturati (posizione/luce, suolo, pH, umidita') tradotti in
--   italiano e scritti in esigenze (merge non distruttivo: i valori PFAF
--   gia' presenti vincono in caso di conflitto di chiave).
-- - RHS e' fonte primaria (regola 3 del criterio di importazione): ogni
--   riga arricchita in questo batch passa a stato_verifica='verificato'.
-- - Sinonimi RHS diversi dal nome gia' in catalogo (es. Alsophila
--   australis = Cyathea australis, Sphaeropteris cooperi = Cyathea
--   cooperi, Goniophlebium/Niphidium = Polypodium, Phegopteris/
--   Parathelypteris/Oreopteris = Thelypteris, Humata tyermanii = tyermannii)
--   mappati manualmente verificando la corrispondenza in query preliminari.


update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A low-growing spreading fern with gently arching, twice divided elegant fronds supported on wiry black stems. Semi-evergreen in warm sheltered gardens or if grown as a houseplant".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, calcareo, sabbioso; pH neutro, alcalino"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H3 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Can trim back any faded growth in winter if required or wait for new growth to start emerging in spring."$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division or spores"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Adiantum capillus-veneris$t$),
  stato_verifica = 'verificato'
where slug = $t$adiantum-capillus-veneris$t$
  and not ($t$RHS (rhs.org.uk) — Adiantum capillus-veneris$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A fern with a slowly creeping rootstock producing clumps of arching foliage to about 40cm. Each frond has five to seven branches with leathery segments tightly packed along black midribs. Fronds open rosy pink, maturing to bronzy dark green, and are normally deciduous, but remain evergreen in warm areas or if grown as a houseplant". RHS elenca 2 cultivar coltivate con altezze da 0.1-0.5m e diffusione da 0.1-0.5m (tra cui 'Bronze Venus').$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors; may be susceptible to scale insects under glass"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H3, H4 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Remove damaged fronds in spring"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by spores or division"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Adiantum hispidulum$t$),
  stato_verifica = 'verificato'
where slug = $t$adiantum-hispidulum$t$
  and not ($t$RHS (rhs.org.uk) — Adiantum hispidulum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous fern with a shortly creeping rhizome, forming a clump to 45cm tall. Wiry black stems bear branched, spreading fronds, sometimes deep pink when young".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to scale insects under glass"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by spores"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Adiantum pedatum$t$),
  stato_verifica = 'verificato'
where slug = $t$adiantum-pedatum$t$
  and not ($t$RHS (rhs.org.uk) — Adiantum pedatum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Adiantum can be deciduous or evergreen ferns with shiny black stalks bearing simple or more usually pinnately divided fronds, the segments fan-shaped, oblong or rounded, carrying spores under reflexed marginal flaps".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Adiantum peruvianum$t$)
where slug = $t$adiantum-peruvianum$t$
  and not ($t$RHS (rhs.org.uk) — Adiantum peruvianum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A tender evergreen fern about 60cm tall, the black-stalked, triangular fronds with rounded to triangular, variably lobed segments, the colouring a pale green initially, but darkening with age". RHS elenca 6 cultivar coltivate con altezze da 0.1-1m e diffusione da 0.1-1m (tra cui 'Brilliantelse', 'Fragrantissimum', 'Fritz Lüthi', 'Kensington Gem', 'Monocolor').$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco; pH alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to scale insects"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1C (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-1m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Plant requires little pruning other than the removal of dead leaves"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe at a minimum of 21°C, or propagate by division of the rhizomes in early spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Adiantum raddianum$t$),
  stato_verifica = 'verificato'
where slug = $t$adiantum-raddianum$t$
  and not ($t$RHS (rhs.org.uk) — Adiantum raddianum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Adiantum can be deciduous or evergreen ferns with shiny black stalks bearing simple or more usually pinnately divided fronds, the segments fan-shaped, oblong or rounded, carrying spores under reflexed marginal flaps". RHS elenca 2 cultivar coltivate (tra cui 'Farleyense').$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Adiantum tenerum$t$)
where slug = $t$adiantum-tenerum$t$
  and not ($t$RHS (rhs.org.uk) — Adiantum tenerum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous fern, almost evergreen in mild areas, with a thin, creeping rhizome, forming a mat to 25cm in height, with ovate fronds composed of many small fan-shaped segments, often turning an attractive rusty-brown in autumn and winter".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to scale insects under glass"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by spores"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Adiantum venustum$t$),
  stato_verifica = 'verificato'
where slug = $t$adiantum-venustum$t$
  and not ($t$RHS (rhs.org.uk) — Adiantum venustum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Asplenium are evergreen ferns with short, usually erect rhizomes bearing a rosette of slightly leathery fronds which may be simple, pinnate to 3-pinnate".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Asplenium adiantum-nigrum$t$)
where slug = $t$asplenium-adiantum-nigrum$t$
  and not ($t$RHS (rhs.org.uk) — Asplenium adiantum-nigrum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A tender evergreen fern about 60-90cm tall, forming rosettes or 'nests' of upright, glossy, fresh green fronds that are are long and flat with a wavy edge and pointed tips, the mature fronds develop a distinctive brown midrib". RHS elenca 5 cultivar coltivate con altezze da 0.5-1m e diffusione da 0.5-1m (tra cui 'Crissie', 'Leslie', 'Osaka', 'Vitasphur').$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to scale insects"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1B (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division , or propagate by sowing spores as soon as ripe at 21°C"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Asplenium antiquum$t$),
  stato_verifica = 'verificato'
where slug = $t$asplenium-antiquum$t$
  and not ($t$RHS (rhs.org.uk) — Asplenium antiquum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A terrestrial, evergreen fern about 15cm tall, with short, upright rhizomes and tufts of narrow, lance-shaped fronds to 20cm long, dark green above with rusty brown scales beneath".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco, sabbioso, calcareo; pH alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division , or propagate by sowing spores as soon as ripe at 15°C"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Asplenium ceterach$t$),
  stato_verifica = 'verificato'
where slug = $t$asplenium-ceterach$t$
  and not ($t$RHS (rhs.org.uk) — Asplenium ceterach$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Asplenium are evergreen ferns with short, usually erect rhizomes bearing a rosette of slightly leathery fronds which may be simple, pinnate to 3-pinnate".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Asplenium daucifolium$t$)
where slug = $t$asplenium-daucifolium$t$
  and not ($t$RHS (rhs.org.uk) — Asplenium daucifolium$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Asplenium are evergreen ferns with short, usually erect rhizomes bearing a rosette of slightly leathery fronds which may be simple, pinnate to 3-pinnate".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Asplenium marinum$t$)
where slug = $t$asplenium-marinum$t$
  and not ($t$RHS (rhs.org.uk) — Asplenium marinum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A small, evergreen perennial fern that grows up to 15cm in height, often found in rocky crevices and old walls.  It has delicate, green fronds that emerge in a loose rosette pattern from the base.  Each leaflet is rounded and slightly lobed, almost fan-shaped, resembling the leaves of rue (Ruta graveolens), from which the plant gets its name. The edges of the leaflets may be gently scalloped or notched, whilst the undersides often bear clusters of spores arranged in elongated, curved lines".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Ben drenato", "terreno": "Calcareo, franco; pH alcalino"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division , or propagate by sowing spores as soon as ripe at 15°C"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Asplenium ruta-muraria$t$),
  stato_verifica = 'verificato'
where slug = $t$asplenium-ruta-muraria$t$
  and not ($t$RHS (rhs.org.uk) — Asplenium ruta-muraria$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen fern forming a rosette of arching, rich green, strap-shaped fronds 30-75cm in length, the margins often undulate. Spores appear in conspicuous transverse stripes beneath the fronds". RHS elenca 9 cultivar coltivate con altezze da 0.1-1m e diffusione da 0.1-1m (tra cui 'Angustatum', 'Kaye', 'Crispum Bolton', 'Golden Queen').$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "May be susceptible to a rust in mild, damp winters"$t$,
    $t$Rusticità RHS: H5, H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-1m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division , or propagate by sowing spores as soon as ripe at 15°C"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Asplenium scolopendrium$t$),
  stato_verifica = 'verificato'
where slug = $t$asplenium-scolopendrium$t$
  and not ($t$RHS (rhs.org.uk) — Asplenium scolopendrium$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A small, evergreen fern with a tufted, clump-forming habit. Its thin, wiry fronds, 5–20cm long, 2–4 mm wide, are deep green to bluish-green, leathery, and often forked at the tips, resembling grass.  Slow-growing but long-lived, it thrives in rocky, dry habitats".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Franco, sabbioso; pH alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division , or propagate by sowing spores as soon as ripe at 15°C"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Asplenium septentrionale$t$),
  stato_verifica = 'verificato'
where slug = $t$asplenium-septentrionale$t$
  and not ($t$RHS (rhs.org.uk) — Asplenium septentrionale$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A compact, evergreen terrestrial fern to about 15cm tall,  with creeping rhizomes and forming a rosette of blackish-stemmed, pinnate, dark green fronds with small, rounded or oblong segments; well-suited to planting in a dry wall". RHS elenca 3 cultivar coltivate con altezze da 0.1-0.5m e diffusione da 0.1-0.5m.$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division , or propagate by sowing spores as soon as ripe at 15°C"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Asplenium trichomanes$t$),
  stato_verifica = 'verificato'
where slug = $t$asplenium-trichomanes$t$
  and not ($t$RHS (rhs.org.uk) — Asplenium trichomanes$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen, clump-forming fern with 10-25cm long and 2-3cm wide bright yellow-green to deep green, linear, tapered fronds divided into oblong leaflets with smooth to gently toothed edges. The fronds have slightly wavy margins and a feathery, maidenhair-like appearance. The leaflets are arranged alternately along the fronds. Its green or reddish stipe (stalk) sets it apart from other spleenworts.  Brown spore clusters (sori) line the underside along the midrib from late summer to early autumn".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco, sabbioso; pH alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0-0.1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division , or propagate by sowing spores as soon as ripe at 15°C"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Asplenium viride$t$),
  stato_verifica = 'verificato'
where slug = $t$asplenium-viride$t$
  and not ($t$RHS (rhs.org.uk) — Asplenium viride$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Athyrium are deciduous ferns with erect or creeping rhizomes bearing usually pinnate to tripinnate fronds, often of thin texture, and they are especially shade-tolerant".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Athyrium distentifolium$t$)
where slug = $t$athyrium-distentifolium$t$
  and not ($t$RHS (rhs.org.uk) — Athyrium distentifolium$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A vigorous, deciduous fern to 80cm or more, forming a clump of fresh-green, lacy, bipinnate, lance-shaped fronds, the segments with toothed margins. In some plants the midrib is red, in others green". RHS elenca 14 cultivar coltivate con altezze da 0.1-1.5m e diffusione da 0.1-1m (tra cui 'Dre', 'Frizelliae', 'Lady-in-Lace', 'Minutissimum', 'Plumosum Axminster', 'Rotstiel Grandiceps'...).$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free out of doors"; Malattie: "Generally disease-free outdoors"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-1.5m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores in mid to late summer or by division in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Athyrium filix-femina$t$),
  stato_verifica = 'verificato'
where slug = $t$athyrium-filix-femina$t$
  and not ($t$RHS (rhs.org.uk) — Athyrium filix-femina$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen, frost-tender fern reaching a height and spread of 1.5m by 1m. The erect to arching fronds are slightly crinkled; new fronds emerge an intense pinkish-red colour before maturing to a glossy green. Over time, the erect rhizome will form a thin trunk around 30cm high". RHS elenca 3 cultivar coltivate con altezze da 0.1-1.5m e diffusione da 0.1-1m (tra cui 'Volcano', 'Alceru').$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1A, H1B, H3 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-1.5m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Tidy if necessary, removing older fronds"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by spores in summer or propagate by division but may take some time to re-establish"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Blechnum brasiliense$t$),
  stato_verifica = 'verificato'
where slug = $t$blechnum-brasiliense$t$
  and not ($t$RHS (rhs.org.uk) — Blechnum brasiliense$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen fern with upright, trunk-like rhizomes and deeply-lobed, bright green fronds usually to about 1m but can reach 2m". RHS elenca 2 cultivar coltivate con altezze da 0.5-1m e diffusione da 0.5-1m (tra cui 'Silver Lady').$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco; pH acido"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1A, H1B (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Tidy if necessary, removing older fronds"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by spores in summer or propagate by division but may take some time to re-establish"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Blechnum gibbum$t$),
  stato_verifica = 'verificato'
where slug = $t$blechnum-gibbum$t$
  and not ($t$RHS (rhs.org.uk) — Blechnum gibbum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen fern forming a mat of spreading, simply pinnate, dark green sterile fronds to 15cm in length, with narrower, erect fertile fronds, the young fronds often reddish".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato, poco drenato", "terreno": "Franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free outdoors"$t$,
    $t$Rusticità RHS: H4 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores (may not come true) in mid to late summer or by division in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Blechnum penna-marina$t$),
  stato_verifica = 'verificato'
where slug = $t$blechnum-penna-marina$t$
  and not ($t$RHS (rhs.org.uk) — Blechnum penna-marina$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A neat, tufted evergreen fern to 50cm, with spreading, narrow, dark green, simply pinnate sterile fronds and upright, fertile fronds with linear pinnae".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato, poco drenato", "terreno": "Argilloso, franco; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free outdoors"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores (may not come true) in mid to late summer or by division in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Blechnum spicant$t$),
  stato_verifica = 'verificato'
where slug = $t$blechnum-spicant$t$
  and not ($t$RHS (rhs.org.uk) — Blechnum spicant$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen fern with upright, mid-green leaves, 15-50cm long, with a wrinkled surface, silvery, hair-like scales on both sides and brown stems".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Ben drenato", "terreno": "Franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Fungal root rot may be a problem under glass"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Sow spores at 16°C as soon as ripe. division in spring is possible, but rhizomes resent disturbance"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Cheilanthes lanosa$t$),
  stato_verifica = 'verificato'
where slug = $t$cheilanthes-lanosa$t$
  and not ($t$RHS (rhs.org.uk) — Cheilanthes lanosa$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A tree fern with a terminal cluster of spreading fronds on a stem clothed with persistent frond bases that are covered with brown scales".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H2 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-4m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Alsophila australis$t$),
  stato_verifica = 'verificato'
where slug = $t$cyathea-australis$t$
  and not ($t$RHS (rhs.org.uk) — Alsophila australis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A frost-tender, evergreen tree fern eventually reaching up to 10m tall with a slender, dark brown stem bearing terminal clusters of arching, divided, mid- to dark green fronds up to 3m long which, when mature, are coloured underneath silvery-grey".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H3 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 8-12m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Alsophila tricolor$t$),
  stato_verifica = 'verificato'
where slug = $t$cyathea-dealbata$t$
  and not ($t$RHS (rhs.org.uk) — Alsophila tricolor$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A fast-growing tree fern reaching 5m in ideal conditions, with a slender stem and mid-green fronds up to 4m long".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H3 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-4m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Sphaeropteris cooperi$t$),
  stato_verifica = 'verificato'
where slug = $t$cyathea-cooperi$t$
  and not ($t$RHS (rhs.org.uk) — Sphaeropteris cooperi$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen, upright tree fern eventually reaching heights of 7-16m. Its slender black trunk bears fronds to 5m long arching up from the crown and made up of small, oblong, glossy leaflets with scaly undersides and spines along the margins".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H3 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 12m, diffusione 8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Sphaeropteris medullaris$t$),
  stato_verifica = 'verificato'
where slug = $t$cyathea-medullaris$t$
  and not ($t$RHS (rhs.org.uk) — Sphaeropteris medullaris$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen fern, deciduous in cold areas, forming a tuft of leathery, pinnate fronds to 70cm long, composed of dark glossy green, broadly sickle-shaped leaflets".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H3 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required but frost-damaged fronds can be removed in spring"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by spores sown at 16°C in late summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Cyrtomium falcatum$t$),
  stato_verifica = 'verificato'
where slug = $t$cyrtomium-falcatum$t$
  and not ($t$RHS (rhs.org.uk) — Cyrtomium falcatum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen fern with erect 'shuttlecocks' of pinnate fronds to 1.2m tall, with about 20 pairs of narrowly sickle-shaped, dull green leaflets". RHS elenca 2 cultivar coltivate con altezze da 0.1-1.5m e diffusione da 0.1-1m.$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H3 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-1.5m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required but frost-damaged fronds can be removed in spring"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by spores sown at 16°C in late summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Cyrtomium fortunei$t$),
  stato_verifica = 'verificato'
where slug = $t$cyrtomium-fortunei$t$
  and not ($t$RHS (rhs.org.uk) — Cyrtomium fortunei$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous, perennial fern that typically grows to a height and spread of between 10 and 45cm.  It has pale green fronds that are delicate and feathery, with small, closely spaced leaflets that have finely toothed edges".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Tidy spent leaves in autumn"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division or spring or from spores when ripe"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Cystopteris dickieana$t$),
  stato_verifica = 'verificato'
where slug = $t$cystopteris-dickiana$t$
  and not ($t$RHS (rhs.org.uk) — Cystopteris dickieana$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "Clump-forming, deciduous fern about 20cm tall, with upright rhizomes and tufts of lance-shaped pale, grey-green fronds to 45cm long, with segments sharply pointed at the tips".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Tidy spent leaves in autumn"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division in spring or plant bulbils in late summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Cystopteris fragilis$t$),
  stato_verifica = 'verificato'
where slug = $t$cystopteris-fragilis$t$
  and not ($t$RHS (rhs.org.uk) — Cystopteris fragilis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A spreading, deciduous fern with thick, scaly rhizomes and broad, finely-divided fronds 20cm to 50cm long".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1C (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Divide rhizomes in spring, ensuring each division has roots"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Davallia canariensis$t$),
  stato_verifica = 'verificato'
where slug = $t$davallia-canariensis$t$
  and not ($t$RHS (rhs.org.uk) — Davallia canariensis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous fern with creeping rhizomes covered with brown scales; fronds to 25cm, triangular-ovate, finely dissected".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H2 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required but tidy any winter damaged fronds in early spring"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Divide rhizomes in spring, ensuring each division has roots"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Davallia mariesii$t$),
  stato_verifica = 'verificato'
where slug = $t$davallia-mariesii$t$
  and not ($t$RHS (rhs.org.uk) — Davallia mariesii$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen tree fern, but deciduous in colder areas, growing slowly to 4m in height, with a stout reddish-brown stem and a terminal rosette of arching, deeply divided, glossy dark green fronds to 3m in length".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free outdoors"$t$,
    $t$Rusticità RHS: H3 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-4m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Dicksonia antarctica$t$),
  stato_verifica = 'verificato'
where slug = $t$dicksonia-antarctica$t$
  and not ($t$RHS (rhs.org.uk) — Dicksonia antarctica$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen tree fern to 6m tall, with a stout rhizome and dark green, 2 to 3-pinnate fronds to 2m long, their stalks brown scaly towards the base".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free outdoors"$t$,
    $t$Rusticità RHS: H3 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 4-8m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Dicksonia fibrosa$t$),
  stato_verifica = 'verificato'
where slug = $t$dicksonia-fibrosa$t$
  and not ($t$RHS (rhs.org.uk) — Dicksonia fibrosa$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A tree fern with slender, erect, trunk-like rhizome to 6m tall, bearing a rosette of broadly deltoid, 2- to 3-pinnate fronds to 1.2m long, their stalks with blackish scales".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free outdoors"$t$,
    $t$Rusticità RHS: H3 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 4-8m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Dicksonia squarrosa$t$),
  stato_verifica = 'verificato'
where slug = $t$dicksonia-squarrosa$t$
  and not ($t$RHS (rhs.org.uk) — Dicksonia squarrosa$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen fern that can reach 1m or more, with long, mid-green fronds divided into wedge-shaped leaflets, and tinged red when young".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1B (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by spores or by division"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Didymochlaena truncatula$t$),
  stato_verifica = 'verificato'
where slug = $t$didymochlaena-truncatula$t$
  and not ($t$RHS (rhs.org.uk) — Didymochlaena truncatula$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A compact, clumping, evergreen fern to 60cm tall bearing deeply-lobed fronds with dark veins on wiry black stems; the shorter, sterile fronds are palmate-shaped whilst the fertile fronds are borne on taller stems and have narrower lobes".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1B (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Remove dead or damaged fronds as required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate from spores, or by division in late spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Doryopteris pedata$t$),
  stato_verifica = 'verificato'
where slug = $t$doryopteris-pedata$t$
  and not ($t$RHS (rhs.org.uk) — Doryopteris pedata$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A semi-evergreen clump-forming fern with highly dissected and finely toothed foliage creating a lacy appearance.".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, calcareo; pH neutro, acido, alcalino"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Remove any dead or damaged fronds in late autumn or early spring before new growth emerges."$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division or spores"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Dryopteris carthusiana$t$),
  stato_verifica = 'verificato'
where slug = $t$dryopteris-carthusiana$t$
  and not ($t$RHS (rhs.org.uk) — Dryopteris carthusiana$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A clump-forming fern consisting of semi-evergreen errect fertile fronds with widely spaced leaflets and shorter, arching sterile fronds which are evergreen".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato, poco drenato", "terreno": "Franco, argilloso; pH neutro, acido"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division or spores"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Dryopteris cristata$t$),
  stato_verifica = 'verificato'
where slug = $t$dryopteris-cristata$t$
  and not ($t$RHS (rhs.org.uk) — Dryopteris cristata$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A robust semi-evergreen perennial forming a rosette of erect or arching, broadly triangular-ovate, dark green, tripinnate fronds, the segments strongly toothed". RHS elenca 5 cultivar coltivate con altezze da 0.5-1.5m e diffusione da 0.1-1m (tra cui 'Crispa Whiteside', 'Cristata', 'Jimmy Dyce', 'Lepidota Cristata').$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato, poco drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free outdoors"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1.5m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe or by division in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Dryopteris dilatata$t$),
  stato_verifica = 'verificato'
where slug = $t$dryopteris-dilatata$t$
  and not ($t$RHS (rhs.org.uk) — Dryopteris dilatata$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A robust deciduous fern forming a shuttlecock-like tuft of lance-shaped, bipinnatifid fronds to 1.2m in height". RHS elenca 9 cultivar coltivate con altezze da 0.1-1.5m e diffusione da 0.1-1.5m (tra cui 'Barnesii', 'Crispa Cristata', 'Crispa', 'Cristata', 'Decomposita', 'Furcans'...).$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato, poco drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free outdoors"$t$,
    $t$Rusticità RHS: H5, H6, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-1.5m, diffusione 0.1-1.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe or by division in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Dryopteris filix-mas$t$),
  stato_verifica = 'verificato'
where slug = $t$dryopteris-filix-mas$t$
  and not ($t$RHS (rhs.org.uk) — Dryopteris filix-mas$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A robust semi-evergreen fern forming a rosette of erect, bipinnatifid fronds to 1.2m in length, bright yellow-green when young, later rich green, with dense, persistent golden scales on the stems".$t$,
  esigenze = ($t${"luce": "Ombra piena, pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free outdoors"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1-1.5m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe or by division in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Dryopteris pseudomas$t$),
  stato_verifica = 'verificato'
where slug = $t$dryopteris-pseudomas$t$
  and not ($t$RHS (rhs.org.uk) — Dryopteris pseudomas$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous fern to 30cm tall, forming extensive colonies of bright green, triangular, 2 to 3-pinnate fronds 10-20cm long and wide". RHS elenca 2 cultivar coltivate con altezze da 0.1-0.5m e diffusione da 0.5-1m (tra cui 'Plumosum').$t$,
  esigenze = ($t${"luce": "Ombra piena", "acqua": "Umido ma ben drenato", "terreno": "Franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Cut back in autumn as fronds fade"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Sow spores at 15°C (59°F) when ripe or Divide in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Gymnocarpium dryopteris$t$),
  stato_verifica = 'verificato'
where slug = $t$gymnocarpium-dryopteris$t$
  and not ($t$RHS (rhs.org.uk) — Gymnocarpium dryopteris$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A low-growing, deciduous fern that forms a delicate green carpet between 10-40cm in height.  Finely divided, soft fronds, up to 14cm long, emerge from a creeping underground network of rhizomes".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco; pH alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required, but can remove and dead or damaged fronds as required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe, or by division in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Gymnocarpium robertianum$t$),
  stato_verifica = 'verificato'
where slug = $t$gymnocarpium-robertianum$t$
  and not ($t$RHS (rhs.org.uk) — Gymnocarpium robertianum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A tender fern usually grown as a houseplant. The fronds are triangular in outline, dark green and very finely divided. Furry, silvery rhizomes creep across the surface then dangle over the sides of the container".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Franco; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to scale insects"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1B (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Remove dead or damaged fronds as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate from spores or by division"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Humata tyermanii$t$),
  stato_verifica = 'verificato'
where slug = $t$humata-tyermannii$t$
  and not ($t$RHS (rhs.org.uk) — Humata tyermanii$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous fern with widely ovate, pinnate, bright green sterile fronds surrounding long, narrower, fertile fronds that emerge near black and turn reddish-brown in autumn. The stems are long helping to give a spreading, almost pendulous habit.".$t$,
  esigenze = ($t${"luce": "Ombra piena, pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, poco drenato", "terreno": "Argilloso, franco; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds can be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division in spring or from spores"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Matteuccia orientalis$t$),
  stato_verifica = 'verificato'
where slug = $t$matteuccia-orientalis$t$
  and not ($t$RHS (rhs.org.uk) — Matteuccia orientalis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Matteuccia are rhizomatous deciduous ferns, sometimes with stolons, forming shuttlecock-like rosettes of erect or spreading, pinnately divided fronds, with smaller, erect, bead-like fertile fronds".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Matteuccia pensylvanica$t$)
where slug = $t$matteuccia-pensylvanica$t$
  and not ($t$RHS (rhs.org.uk) — Matteuccia pensylvanica$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous, stoloniferous fern forming colonies of upright rosettes to 1.5m in height, with lance-shaped, bright green, divided, feathery sterile fronds surrounding shorter, brownish fertile fronds". RHS elenca 2 cultivar coltivate con altezze da 1-2.5m e diffusione da 1-2.5m (tra cui 'Jumbo').$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free outdoors"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1-2.5m, diffusione 1-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe or by division in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Matteuccia struthiopteris$t$),
  stato_verifica = 'verificato'
where slug = $t$matteuccia-struthiopteris$t$
  and not ($t$RHS (rhs.org.uk) — Matteuccia struthiopteris$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An upright, rhizomatous, evergreen fern with masses of dark green, dense, sword-shaped, tripinnate fronds which are ruffled around the edges.  These ferns are capable of growing as an epiphyte on trees near to water, or in the ground.  A good air-purifying plant and ideal for terrariums and bottle gardens".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to scale insects"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1B (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Remove any dead fronds"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Sow spores are 21°C (70°F) as soon as ripe, but resulting plants are unlikely to come true. Separate rooted runners in late winter or early spring or propagate by runners"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Nephrolepis cordifolia$t$),
  stato_verifica = 'verificato'
where slug = $t$nephrolepis-cordifolia$t$
  and not ($t$RHS (rhs.org.uk) — Nephrolepis cordifolia$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A compact, clump-forming, evergreen fern with masses of dark green, dense, sword-shaped, tripinnate fronds which are ruffled around the edges.  The fronds have a mild lemony fragrance during the growing season.  A good air-purifying plant and ideal for terrariums and bottle gardens".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "May be susceptible to scale insects"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1B (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Remove any dead fronds"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Sow spores are 21°C (70°F) as soon as ripe, but resulting plants are unlikely to come true. Separate rooted runners in late winter or early spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Nephrolepis duffii$t$),
  stato_verifica = 'verificato'
where slug = $t$nephrolepis-duffii$t$
  and not ($t$RHS (rhs.org.uk) — Nephrolepis duffii$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous, rhizomatous fern forming extensive colonies of broad, light green, pinnate fronds to 60cm in length, the pinnae deeply lobed. Shorter, narrow fertile fronds have much reduced, blackish lobes".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato, poco drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free outdoors"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 1.5-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe or by division in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Onoclea sensibilis$t$),
  stato_verifica = 'verificato'
where slug = $t$onoclea-sensibilis$t$
  and not ($t$RHS (rhs.org.uk) — Onoclea sensibilis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous fern forming rosettes of erect, light blue-green, lance-shaped, bipinnate sterile fronds surrounding shorter, cinnamon-brown fertile fronds".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato, poco drenato", "terreno": "Argilloso, franco, sabbioso; pH acido"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1-1.5m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores at 15-16°C (59-61°F). These need to be sown with in three days of ripening as they loose their viability very quickly. Alternatively, Divide well established colonies into clumps in either autumn or early spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Osmunda cinnamomea$t$),
  stato_verifica = 'verificato'
where slug = $t$osmunda-cinnamomea$t$
  and not ($t$RHS (rhs.org.uk) — Osmunda cinnamomea$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous fern with lance-shaped, bipinnate fronds surrounding erect, central fronds, on which the fertile middle pinnae are contracted and rusty-brown".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato, poco drenato", "terreno": "Argilloso, franco, sabbioso; pH acido"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free outdoors"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe or by division in early spring or autumn"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Osmunda claytoniana$t$),
  stato_verifica = 'verificato'
where slug = $t$osmunda-claytoniana$t$
  and not ($t$RHS (rhs.org.uk) — Osmunda claytoniana$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A robust, deciduous fern forming a large clump of bipinnate fronds to 2.5m in height, bearing rusty-brown spore-bearing pinnae at the tips; foliage turns attractive red-brown in autumn". RHS elenca 3 cultivar coltivate con altezze da 1-2.5m e diffusione da 0.5-1.5m (tra cui 'Cristata', 'Purpurascens').$t$,
  esigenze = ($t${"luce": "Ombra piena, pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, poco drenato", "terreno": "Calcareo, argilloso, franco; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free outdoors"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1-2.5m, diffusione 0.5-1.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe or by division in early spring or autumn"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Osmunda regalis$t$),
  stato_verifica = 'verificato'
where slug = $t$osmunda-regalis$t$
  and not ($t$RHS (rhs.org.uk) — Osmunda regalis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Pellaea can be evergreen or deciduous, tufted ferns with pinnate to tripinnate fronds".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pellaea atropurpurea$t$)
where slug = $t$pellaea-atropurpurea$t$
  and not ($t$RHS (rhs.org.uk) — Pellaea atropurpurea$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen, tufted fern with erect, dark green, glossy fronds up to 75cm long. Fronds are divided into short, oblong to curved leaflets with margins that are sometimes wavy".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco, sabbioso, argilloso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H4 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Remove dead or damaged fronds"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by spores"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pellaea falcata$t$),
  stato_verifica = 'verificato'
where slug = $t$pellaea-falcata$t$
  and not ($t$RHS (rhs.org.uk) — Pellaea falcata$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A compact, evergreen fern forming a nearly flat rosette of pinnate fronds to 25cm long, composed of rounded, deep green leaflets borne on dark brown, pink-scaled stems.  An ideal plant for terrariums and bottle gardens".$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco, sabbioso; pH acido"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H2 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required.  Remove old leaves as they die down for the winter"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by spores sown at 13-18°C when ripe"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pellaea rotundifolia$t$),
  stato_verifica = 'verificato'
where slug = $t$pellaea-rotundifolia$t$
  and not ($t$RHS (rhs.org.uk) — Pellaea rotundifolia$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Pellaea can be evergreen or deciduous, tufted ferns with pinnate to tripinnate fronds".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pellaea viridis$t$)
where slug = $t$pellaea-viridis$t$
  and not ($t$RHS (rhs.org.uk) — Pellaea viridis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A tender fern grown as a houseplant with wavy blue-green fronds appearing from creeping, hairy rhizomes (modified stems). The fronds are lobed and can grow up to 40cm". RHS elenca 4 cultivar coltivate con altezze da 0.1-1m e diffusione da 0.1-1m (tra cui 'Blue Star', 'Raadphle01').$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco; pH neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H1B, H2 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-1m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Phlebodium aureum$t$),
  stato_verifica = 'verificato'
where slug = $t$phlebodium-aureum$t$
  and not ($t$RHS (rhs.org.uk) — Phlebodium aureum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A small, wetland fern, with creeping rhizomes producing slender, thread-like cylindrical fronds to 8cm high, giving it a grass-like appearance. Small round spore-bearing structures are formed at the base of the fronds in summer".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Poco drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 10m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by spores or by division"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pilularia globulifera$t$),
  stato_verifica = 'verificato'
where slug = $t$pilularia-globulifera$t$
  and not ($t$RHS (rhs.org.uk) — Pilularia globulifera$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Platycerium are evergreen, epiphytic ferns with short rhizomes, and a tuft of rounded or heart-shaped sterile fronds, sometimes lobed on the upper margin,  and erect or pendent, grey-green fertile fronds which are usually repeatedly forked".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Platycerium grande$t$)
where slug = $t$platycerium-grande$t$
  and not ($t$RHS (rhs.org.uk) — Platycerium grande$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Polypodium can be evergreen or deciduous ferns, with creeping rhizomes bearing simple or pinnate fronds at intervals".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Polypodium interjectum$t$)
where slug = $t$polypodium-interjectum$t$
  and not ($t$RHS (rhs.org.uk) — Polypodium interjectum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen terrestrial or epiphytic  fern, to 30cm tall, with creeping rhizomes and lance-shaped to oblong, pinnate or very deeply pinnatifid dark green fronds".$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, franco, sabbioso; pH alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free outdoors"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division in spring or early summer. Sow spores at 15-16°C when ripe"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Polypodium vulgare$t$),
  stato_verifica = 'verificato'
where slug = $t$polypodium-vulgare$t$
  and not ($t$RHS (rhs.org.uk) — Polypodium vulgare$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen fern with a branching rhizome producing clumps of leathery, narrowly-oblong fronds divided into pairs of narrow, mid to dark green leaflets".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Remove dead or damaged fronds in early spring"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division or from spores"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Polystichum acrostichoides$t$),
  stato_verifica = 'verificato'
where slug = $t$polystichum-acrostichoides$t$
  and not ($t$RHS (rhs.org.uk) — Polystichum acrostichoides$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen fern forming a neat rosette of bipinnate, erect or arching, leathery dark green, narrowly lanceolate fronds to 90cm long, with slightly prickly pinnules".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Dense plantings may be susceptible to grey moulds (botrytis) or the fungal disease Taphrina wettsteiniana"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Remove dead fronds before new ones unfurl"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by spores, sow spores at 15-16°C (59-61°F) when ripe. Divide rhizomes in spring or detach fronds bearing bulbils in autumn"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Polystichum aculeatum$t$),
  stato_verifica = 'verificato'
where slug = $t$polystichum-aculeatum$t$
  and not ($t$RHS (rhs.org.uk) — Polystichum aculeatum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Polystichum are mostly evergreen or semi-evergreen ferns, with short stout rhizomes and pinnately divided fronds in neat shuttlecock-like rosettes".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Polystichum lonchitis$t$)
where slug = $t$polystichum-lonchitis$t$
  and not ($t$RHS (rhs.org.uk) — Polystichum lonchitis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An evergreen fern to around 60cm tall and wide with arching, triangular, glossy, deep green fronds".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Cut back in late winter or early spring before new fronds emerge"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division or from spores"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Polystichum makinoi$t$),
  stato_verifica = 'verificato'
where slug = $t$polystichum-makinoi$t$
  and not ($t$RHS (rhs.org.uk) — Polystichum makinoi$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A robust, evergreen fern forming a large clump of erect, narrowly lance-shaped, dark green, pinnate fronds, the narrow pinnae finely spine-toothed".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1-1.5m, diffusione 1-1.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe or propagate by division of rhizomes in spring or by bulbils in autumn"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Polystichum munitum$t$),
  stato_verifica = 'verificato'
where slug = $t$polystichum-munitum$t$
  and not ($t$RHS (rhs.org.uk) — Polystichum munitum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A tufted, evergreen fern to 1.2m in height, with rosettes of soft textured, lance-shaped mid-green fronds, the stalks with prominent orange-brown scales". RHS elenca 13 cultivar coltivate con altezze da 0.1-1.5m e diffusione da 0.1-1m (tra cui 'Pulcherrimum Bevis', 'Congestum Cristatum', 'Congestum', 'Dahlem', 'Divisilobum Densum', 'Divisilobum Iveryanum'...).$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H6, H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-1.5m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe, division of rhizomes in spring or by bulbils in autumn"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Polystichum setiferum$t$),
  stato_verifica = 'verificato'
where slug = $t$polystichum-setiferum$t$
  and not ($t$RHS (rhs.org.uk) — Polystichum setiferum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A small, tufted evergreen fern to 45cm, with erect, narrowly lance-shaped, bipinnate fronds, with slender-pointed apex and pinnae".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, argilloso, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H6 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe, division of rhizomes in spring or by bulbils in autumn"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Polystichum tsussimense$t$),
  stato_verifica = 'verificato'
where slug = $t$polystichum-tsus-sinense$t$
  and not ($t$RHS (rhs.org.uk) — Polystichum tsussimense$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "Britain's largest and most widespread native fern, with huge, finely divided leaves 1-2m tall and 1m across. Spreading by rhizomes, with roots up to a metre deep, it forms dense thickets, smothering most other vegetation, and can also spread by spores. Young shoots emerge curled at the tip and are known as croziers or fiddleheads, and in autumn the deciduous fronds turn a rich russet-brown".$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest- free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1-1.5m, diffusione 8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required, though dead fronds can be cut back and composted or used as mulch"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pteridium aquilinum$t$),
  stato_verifica = 'verificato'
where slug = $t$pteridium-aquilinum$t$
  and not ($t$RHS (rhs.org.uk) — Pteridium aquilinum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A tufted evergreen fern to 60cm in height, with long-stalked erect fronds pinnately divided into 3-5 pairs of linear, dark green leaflets which are narrower on the fertile fronds". RHS elenca 4 cultivar coltivate con altezze da 0.1-1m e diffusione da 0.1-0.5m (tra cui 'Mayi', 'Parkeri', 'Wimsettii').$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, franco, sabbioso; pH alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors but under glass may be susceptible to scale insects and eelworms"; Malattie: "sooty mould may be a problem"$t$,
    $t$Rusticità RHS: H1C, H4 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-1m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe or division of rhizomes in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pteris cretica$t$),
  stato_verifica = 'verificato'
where slug = $t$pteris-cretica$t$
  and not ($t$RHS (rhs.org.uk) — Pteris cretica$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A tufted, evergreen variegated fern with feathery silvery-white fronds edged with green.  An ideal fern to add to a Terrarium". RHS elenca 2 cultivar coltivate con altezze da 0.1-0.5m e diffusione da 0.1-1m (tra cui 'Evergemiensis', 'Victoriae').$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Franco, calcareo, sabbioso; pH alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free outdoors but under glass may be susceptible to scale insects and eelworms"; Malattie: "May be susceptible to sooty mould"$t$,
    $t$Rusticità RHS: H1C (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Dead or damaged fronds may be removed as necessary"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe or division of rhizomes in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pteris ensiformis$t$),
  stato_verifica = 'verificato'
where slug = $t$pteris-ensiformis$t$
  and not ($t$RHS (rhs.org.uk) — Pteris ensiformis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Pteris can be evergreen, semi-evergreen or deciduous ferns, with short or long rhizomes and fronds that may be pinnate to 4-pinnate".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pteris multifida$t$)
where slug = $t$pteris-multifida$t$
  and not ($t$RHS (rhs.org.uk) — Pteris multifida$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Pteris can be evergreen, semi-evergreen or deciduous ferns, with short or long rhizomes and fronds that may be pinnate to 4-pinnate".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pteris quadriaurita$t$)
where slug = $t$pteris-quadriaurita$t$
  and not ($t$RHS (rhs.org.uk) — Pteris quadriaurita$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Pteris can be evergreen, semi-evergreen or deciduous ferns, with short or long rhizomes and fronds that may be pinnate to 4-pinnate".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Pteris tremula$t$)
where slug = $t$pteris-tremula$t$
  and not ($t$RHS (rhs.org.uk) — Pteris tremula$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "A genus of small to medium-sized, rhizomatous ferns with delicate, pale green, triangular-shaped and finely divided fronds which thrive in damp, shady locations".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Phegopteris hexagonoptera$t$)
where slug = $t$thelypteris-hexagonoptera$t$
  and not ($t$RHS (rhs.org.uk) — Phegopteris hexagonoptera$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous fern with light green upright fronds reaching around 50cm. Fronds are finely divided and are often slightly curved or twisted.".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato, poco drenato", "terreno": "Argilloso, franco; pH neutro, acido"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division or spores"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Thelypteris palustris$t$),
  stato_verifica = 'verificato'
where slug = $t$thelypteris-palustris$t$
  and not ($t$RHS (rhs.org.uk) — Thelypteris palustris$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous fern with an initially upright, then arching habit, growing 20–50cm tall with a spread up to 90cm.  Its pale to bright green, finely divided triangular fronds are distinctive, with the lowest pair of leaflets angling downward in an arrow-like shape, set apart from the rest".$t$,
  esigenze = ($t${"luce": "Ombra piena, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Remove dead or damaged fronds as required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by sowing spores as soon as ripe, or by division in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Phegopteris connectilis$t$),
  stato_verifica = 'verificato'
where slug = $t$thelypteris-phegopteris$t$
  and not ($t$RHS (rhs.org.uk) — Phegopteris connectilis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Woodsia are small, tufted deciduous ferns with pinnate or 2-pinnate fronds, and are well-suited to a rock garden".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Woodsia alpina$t$)
where slug = $t$woodsia-alpina$t$
  and not ($t$RHS (rhs.org.uk) — Woodsia alpina$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Woodsia are small, tufted deciduous ferns with pinnate or 2-pinnate fronds, and are well-suited to a rock garden".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Woodsia ilvensis$t$)
where slug = $t$woodsia-ilvensis$t$
  and not ($t$RHS (rhs.org.uk) — Woodsia ilvensis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A clump-forming, deciduous fern with erect and arching pale green fronds divided into numerous, paired leaflets (pinnae)".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Ben drenato, umido ma ben drenato", "terreno": "Franco, calcareo, sabbioso; pH neutro, alcalino"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.1-0.5m, diffusione 0.1-0.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "No pruning required"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division or spores"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Woodsia obtusa$t$),
  stato_verifica = 'verificato'
where slug = $t$woodsia-obtusa$t$
  and not ($t$RHS (rhs.org.uk) — Woodsia obtusa$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Woodsia are small, tufted deciduous ferns with pinnate or 2-pinnate fronds, and are well-suited to a rock garden".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Woodsia scopulina$t$)
where slug = $t$woodsia-scopulina$t$
  and not ($t$RHS (rhs.org.uk) — Woodsia scopulina$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Woodwardia are robust rhizomatous ferns with deciduous or evergreen, pinnate to bipinnate fronds, bearing spores in chain-like lines on the undersides".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Woodwardia areolata$t$)
where slug = $t$woodwardia-areolata$t$
  and not ($t$RHS (rhs.org.uk) — Woodwardia areolata$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "an evergreen fern reaching up to 1.5m tall with erect, dark green,lance-shaped, twice-divided fronds".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato, poco drenato", "terreno": "Argilloso, franco; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H3 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1-1.5m, diffusione 0.5-1m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Remove dead or damaged fronds"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by division or from spores"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Woodwardia fimbriata$t$),
  stato_verifica = 'verificato'
where slug = $t$woodwardia-fimbriata$t$
  and not ($t$RHS (rhs.org.uk) — Woodwardia fimbriata$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "a robust evergreen fern with arching, ovate, bipinnately divided fronds to 1.5m long, bearing bulbils on the underside towards the tips".$t$,
  esigenze = ($t${"luce": "Mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco; pH neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H3 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1-1.5m, diffusione 1.5-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "Cut down old fronds when they deteriorate"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by spores, sow spores at 16°C (61°F) in late summer or early autumn; remove bulbils in autumn or Divide in spring"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Woodwardia radicans$t$),
  stato_verifica = 'verificato'
where slug = $t$woodwardia-radicans$t$
  and not ($t$RHS (rhs.org.uk) — Woodwardia radicans$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS, descrizione del genere (testo originale in inglese): "Woodwardia are robust rhizomatous ferns with deciduous or evergreen, pinnate to bipinnate fronds, bearing spores in chain-like lines on the undersides".$t$,
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Woodwardia virginica$t$)
where slug = $t$woodwardia-virginica$t$
  and not ($t$RHS (rhs.org.uk) — Woodwardia virginica$t$ = any(fonti));

