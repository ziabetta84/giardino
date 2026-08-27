-- Fase 5, RHS varieta, batch arbusti 01: prima parte delle pagine RHS
-- scaricate per le specie importate da "Il giardino di arbusti" (Edicart,
-- 1995) ancora in bozza. Solo queste 6 specie (su 27 previste) hanno
-- effettivamente ricevuto il contenuto RHS il 2026-08-27: un errore di
-- trascrizione manuale della query ha troncato l'invio dopo il settimo
-- statement, che per di piu' e' arrivato senza clausola WHERE e ha
-- corrotto stato_verifica/descrizione/alert/fonti su tutte le 9042 righe
-- della tabella. Vedi 20260827040000_repair_incident_stato_verifica.sql
-- per la riparazione e 20260827050000_rhs_varieta_arbusti_batch02_residuo.sql
-- per le 20 specie rimaste, rifatte correttamente in un secondo momento.

-- Sinonimo: "Vesalea floribunda" e' il nome oggi accettato da RHS per
-- Kolkwitzia amabilis (gia' in catalogo con questo nome) -- la pagina
-- viene appesa alla riga esistente kolkwitzia-amabilis.
-- Abelia floribunda: nessuna pagina RHS scaricata in questo batch, resta
-- bozza in attesa di un download futuro.


update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A deciduous shrub to a height of 1.5m, with dark green, oval to rounded leaves and clusters of small, white flushed pink funnel-shaped blooms in summer and autumn. The flowers are very fragrant and even after flowering, the remaining pink outer bracts are attractive". RHS elenca 3 cultivar coltivate con altezze da 1-1.5m e diffusione da 1-2.5m (tra cui 'China Rose', 'Minabaut01').$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to honey fungus"$t$,
    $t$Rusticità RHS: H4, H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1-1.5m, diffusione 1-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by softwood cuttings in early summer or semi- hardwood cuttings in late summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Abelia chinensis$t$),
  stato_verifica = 'verificato'
where slug = $t$abelia-chinensis$t$
  and not ($t$RHS (rhs.org.uk) — Abelia chinensis$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A semi-evergreen shrub of spreading habit, with small, ovate leaves, and funnel-shaped lilac-pink flowers, with a conspicuous persistent reddish calyx, in late summer and autumn".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to honey fungus"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 1.5-2.5m, diffusione 1.5-2.5m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 . May need hard pruning ( pruning group 6 ) every 3 to 4 years"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by softwood cuttings in early summer or semi- hardwood cuttings in late summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Abelia schumannii$t$),
  stato_verifica = 'verificato'
where slug = $t$abelia-schumannii$t$
  and not ($t$RHS (rhs.org.uk) — Abelia schumannii$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "a large, upright, deciduous shrub or small tree to about 5m. The bark is deeply ridged, and the dark green, pointed, oval leaves have a conspicuous network of veins. Clusters of small, very fragrant, pink-tinged white, tubular flowers with five petal lobes are produced in summer".$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"$t$,
    $t$Rusticità RHS: H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 4-8m, diffusione 2.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by softwood cuttings in early summer or semi- hardwood cuttings in late summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Abelia triflora$t$),
  stato_verifica = 'verificato'
where slug = $t$abelia-triflora$t$
  and not ($t$RHS (rhs.org.uk) — Abelia triflora$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A medium-sized semi-evergreen shrub to 3m, with arching branches, bearing small, glossy oval leaves and clusters of pale pink, slightly fragrant flowers over a long period from mid-summer". RHS elenca 24 cultivar coltivate con altezze da 0.5-4m e diffusione da 0.5-4m (tra cui 'Brockhill Allgold', 'Canyon Creek', 'Compacta', 'Francis Mason', 'Gold Spot', 'Hopleys'...).$t$,
  esigenze = ($t${"luce": "Pieno sole", "acqua": "Umido ma ben drenato", "terreno": "Calcareo, franco, sabbioso; pH acido, alcalino, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to honey fungus"$t$,
    $t$Rusticità RHS: H4, H5 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 0.5-4m, diffusione 0.5-4m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 8 . May need hard pruning ( pruning group 6 ) every 3 to 4 years"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by softwood cuttings in early summer or semi- hardwood cuttings in late summer"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Abelia × grandiflora$t$),
  stato_verifica = 'verificato'
where slug = $t$abelia-x-grandiflora$t$
  and not ($t$RHS (rhs.org.uk) — Abelia × grandiflora$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "A medium to large deciduous upright tree with smooth greyish bark and a tendency to sucker. The leaves when young are bronze and downy on their undersides as they first emerge in spring, and are oval in shape and approximately 4-8cm long, with pointed tips and serrated margins. Mid to dark-green in colour in summer, and then yellow, orange, red in autumn. Clusters of hanging self-fertile five-petalled white flowers on stalks emerge in spring as the young leaves unfurl and expand. The edible red-purple fruits darken as they ripen to blue-black and are enjoyed by wildlife". RHS elenca 2 cultivar coltivate con altezze da 4-12m e diffusione da 2.5-8m (tra cui 'Trazam').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato, ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to fireblight . In dry soil conditions or strong winds, may be susceptible to leaf scorch."$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 4-12m, diffusione 2.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1 ."$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by semi- hardwood cuttings or remove suckers in winter."$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Amelanchier arborea$t$),
  stato_verifica = 'verificato'
where slug = $t$amelanchier-arborea$t$
  and not ($t$RHS (rhs.org.uk) — Amelanchier arborea$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Da RHS (testo originale in inglese): "An upright, suckering shrub, up to 5m high, with oblong mid-green leaves which become multi-coloured green, yellow, orange and red in autumn. Upright sprays of small, white, star-shaped flowers in late spring are followed in summer by blue-black berries which are edible but rather tasteless; they are however eaten by birds". RHS elenca 6 cultivar coltivate con altezze da 2.5-8m e diffusione da 1.5-8m (tra cui 'Glenn Form', 'October Flame', 'Prince William', 'Sprizam').$t$,
  esigenze = ($t${"luce": "Pieno sole, mezz'ombra", "acqua": "Umido ma ben drenato", "terreno": "Argilloso, franco, sabbioso; pH acido, neutro"}$t$::jsonb) || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[
    $t$Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "May be susceptible to fireblight and honey fungus"$t$,
    $t$Rusticità RHS: H7 (scala UK, vedi H1-H7 nella documentazione RHS)$t$,
    $t$Dimensioni RHS a maturità: altezza 2.5-8m, diffusione 1.5-8m$t$,
    $t$Potatura (RHS, testo originale in inglese): "pruning group 1"$t$,
    $t$Propagazione (RHS, testo originale in inglese): "Propagate by layering , or by removing suckers in winter"$t$
  ],
  fonti = array_append(fonti, $t$RHS (rhs.org.uk) — Amelanchier canadensis$t$),
  stato_verifica = 'verificato'
where slug = $t$amelanchier-canadensis$t$
  and not ($t$RHS (rhs.org.uk) — Amelanchier canadensis$t$ = any(fonti));
