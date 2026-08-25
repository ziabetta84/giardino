-- Fase 3, trentaseiesimo batch da guida-completa-giardino (pp. 562-569,
-- "Piante Arbustacee"): Lantana, Ligustrum, Pittosporum. Nerium (genere
-- monotipico in coltivazione) arricchisce la gia' presente nerium-oleander
-- (bozza PFAF + maxi-libro, manutenzione vuota) invece di creare un
-- duplicato.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Lantana$t$,
  $t$Lantana$t$,
  $t$lantana$t$,
  $t$Verbenaceae$t$,
  $t$perenne$t$,
  $t$Specie di arbusti sempreverdi d'aspetto cespuglioso, annuali o perenni, a seconda della specie, con foglie opposte, di forma ovoidale, ruvide, margine dentato; caratterizza per le foglie semplici, opposte, di forma ovoidale. I fiori sono piccoli, tubulari e riuniti in corimbo dello stesso ambito del diverso colore nell'ambito dello stesso corimbo, colore verde intenso. I fiori sono piccoli, tubulari e riuniti in corimbi terminali, di colore diverso nell'ambito dello stesso corimbo.$t$,
  $t${"luce": "Predilige i climi temperato-caldi. Nelle regioni settentrionali è bene allevarla in vaso per poterla riparare nei mesi più freddi", "acqua": "Le irrigazioni devono essere normali; in estate si consiglia di mantenere costantemente il terreno leggermente ombreggiate", "terreno": "Deve essere ben drenato e fertile, tendenzialmente acido"}$t$::jsonb,
  ARRAY[$t$Possono essere soggette a funghi di vario tipo$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "eliminare le parti danneggiate dalle gelate; si consiglia di eseguire la potatura in casa o della Lantana coltivate in vaso"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "concimazioni del concime del produttore. Durante l'estate le annaffiature abbondanti", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Lantana, p. 562-563$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Ligustrum$t$,
  $t$Ligustrum$t$,
  $t$ligustrum$t$,
  $t$Oleaceae$t$,
  $t$perenne$t$,
  $t$Ligustro, arbusti sempreverdi o decidui, originari dell'Asia Orientale e dell'Europa, molto diffusi nei giardini dove vengono utilizzati per la rapida crescita del fogliame e la bellezza del fogliame. Ramifica dalla base e assumono un aspetto cespuglioso. Le foglie sono semplici, opposte, di forma ovoidale o lanceolata, molto lucido, di colore verde intenso. Il colore dipendono dalla varietà e dalla specie. I fiori, di colore bianco e profumo intenso, sono disposti in pannocchie ovoidale o globosa. Le dimensioni e il margine intero, molto compatte, terminanti, a margine intero.$t$,
  $t${"luce": "Si adatta bene a qualsiasi tipo di temperatura; tollera molto bene il freddo invernale", "acqua": "Tollera tanto le esposizioni soleggiate, come quelle ombreggiate, riuscendo a prosperare anche in zone molto ombrose", "terreno": "Sopporta bene anche terreni aridi e calcarei"}$t$::jsonb,
  ARRAY[$t$Può essere soggetto di insetti minatori che causano macchie sul fogliame, nel caso intervenire con prodotti specifici$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": "obbligate cimandole due-tre volte l'anno, tra la primavera e l'estate", "autunno": null, "inverno": null, "primavera": "regolare le siepi e le forme obbligate all'inizio dell'autunno, tra la primavera e l'estate"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "in caso di crescita stentata, distribuire un concime complesso due volte l'anno", "autunno": null, "inverno": null, "primavera": "in caso di crescita stentata, distribuire un concime complesso due volte l'anno"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Ligustrum, p. 564-565$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Pittosporum$t$,
  $t$Pittosporum$t$,
  $t$pittosporum$t$,
  $t$Pittosporaceae$t$,
  $t$perenne$t$,
  $t$Pittosporo, originari di Giappone, Cina, Australia, Nuova Zelanda; i pittospori sono arbusti sempreverdi, alquanto diffusi per il fogliame ornamentale e il profumo intenso. Hanno foglie alterne o riunite in corimboidi, di colore verde crema o oblunghe, di colore verde brillante. I fiori, bianco crema o porporini, sono riuniti in corimbi o terminali. Si usano anche per formare siepi e per costituire piccoli alberelli. Spesso coltivati anche in vasi o contenitori.$t$,
  $t${"luce": "Predilige climi temperato-caldi, adatta all'ambiente mediterraneo", "acqua": "Annaffiature normali, non escluse quelle in riva al mare", "terreno": "Leggero, privo di ristagni d'acqua. Preferisce i terreni argillo-sabbiosi ricchi di sostanza organica e freschi; sopporta abbastanza bene i suoli calcarei"}$t$::jsonb,
  ARRAY[$t$A parte qualche danno causato dal gelo sulle specie meno rustiche, non è in genere soggetto a particolari problemi di coltivazione$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "diversificata a seconda delle zone climatiche e in base alla rusticità della specie; si interviene sugli esemplari singoli a chioma ed eliminare il legno secco, potature energiche, dopo le quali emetterà nuovi getti"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "in caso di sviluppo distributendo un concime polivalente in gene-re, in estate", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Pittosporum, p. 568-569$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

update specie set
  alert = alert || ARRAY[$t$Genere quasi monotipico in coltivazione: la specie principale è Nerium oleander$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "diversificata a seconda della pianta: si mira a compattare tutti i rami laterali, chioma e accorciando dopo la fioritura, ancor più drasticamente, si potano dopo la fioritura tutti i più deboli"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Nerium, p. 566-567$t$)
where slug = $t$nerium-oleander$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Nerium, p. 566-567$t$ = any(fonti));
