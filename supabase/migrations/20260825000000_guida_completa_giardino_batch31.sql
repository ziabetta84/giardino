-- Fase 3, trentunesimo batch da guida-completa-giardino (pp. 520-527,
-- "Arbusti Rampicanti"): Lonicera, Parthenocissus. Jasminum e Passiflora
-- saltate: gia' possedute e verificate via RHS.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Lonicera$t$,
  $t$Lonicera$t$,
  $t$lonicera$t$,
  $t$Caprifoliaceae$t$,
  $t$perenne$t$,
  $t$Caprifoglio, genere stimato soprattutto per gli esemplari rampicanti, ma annovera anche specie arbustive o sempreverdi, decidui o sempreverdi. Le rose bordure e specie arbustive si utilizzano per rampicanti ben adattano quelle per pergole, muri, ecc. Le foglie sono opposte o oblunghe, ovali o obovate, a volte differenziate a seconda della specie. I fiori profumati compaiono in primavera-estate, concentrandosi soprattutto all'inizio dell'autunno, i frutti in primavera e diverso colore e in estate. Specie nota: Lonicera nitida (fiori bianchi o giallini, come nel caprifoglio).$t$,
  $t${"luce": "Posizione ideale è quella a mezz'ombra, anche se la maggior parte delle specie tollera pure il sole", "acqua": "Annaffiature normali, più frequenti in presenza di stagioni siccitose", "terreno": "Gradisce quelli ricchi di sostanza organica, fertili, profondi; non richiedono ristagni d'acqua"}$t$::jsonb,
  ARRAY[$t$Foglie che tendono a ingiallire e scurire: parte delle specie tollera pure il sole$t$, $t$Vegetativi apici concentrandosi vegetativi dei nuovi getti attaccati da afidi: provvedere con annaffiature e concimazioni$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": "si eliminano i rami secchi dopo la fioritura, sopprimendo il legno vecchio", "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Lonicera, p. 522-523$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Parthenocissus$t$,
  $t$Parthenocissus$t$,
  $t$parthenocissus$t$,
  $t$Vitaceae$t$,
  $t$perenne$t$,
  $t$Vite del Canada, genere di rampicanti decidui originari dell'Asia e del Nordamerica. Specie rustiche, a eccezione della Parthenocissus henryana e della Parthenocissus himalayana che devono essere allevate in posizioni riparate. Foglie composte, alterne, lungamente picciolate, talvolta lobate. Fiori verdolini poco significativi, senza profumo. Usato per abbellire pergolati, muri, vecchi tronchi, molto suggestivo in autunno per le tonalità giallo-rossastre del fogliame. Specie più impiegate: la tricuspidata (vite americana) e la quinquefolia (vite del Canada).$t$,
  $t${"luce": "Si adatta a diverse posizioni, l'esposizione ideale è quella solare o a mezz'ombra", "acqua": "Annaffiare generosamente nei periodi climatici con andamento siccitoso e al momento dell'impianto", "terreno": "Tollerano senza difficoltà i tipi di suolo più svariati (anche sassosi), purché sufficientemente freschi nei mesi caldi"}$t$::jsonb,
  ARRAY[$t$Proteggere le specie sensibili (henryana, himalayana) dal gelo, dalle brinate e dai venti freddi, piantandole in posizione protetta$t$, $t$In caso di attacco di afidi intervenire con un prodotto specifico$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "in caso di vegetazione troppo folta si elimina la maggior parte dei rami dell'anno trascorso, potandoli corti sui tralci vecchi; si sopprime tutta la vegetazione giovane dalle pareti già densamente ricoperte"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Parthenocissus, p. 524-525$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
