-- Fase 3, ventitreesimo batch da guida-completa-giardino (pp. 460-467,
-- "Piante Grasse"): Ariocarpus, Astrophytum, Cephalocereus, Cereus, Cissus.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Ariocarpus$t$,
  $t$Ariocarpus$t$,
  $t$ariocarpus$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere originario del Texas e del Messico settentrionale, piante senza fusto con bassi tubercoli privi di spine, simili a foglie, disposti a rosetta con sommità piatta. Piante piccole (diametro massimo 15 cm), crescita molto lenta. Specie nota: Ariocarpus kotschubeyanus (3-5 cm, fiori rosa-viola grandi quasi quanto la pianta).$t$,
  $t${"luce": "Molte ore di luce solare ogni giorno"}$t$::jsonb,
  ARRAY[$t$Non di facile coltivazione: teme l'umidità e marcisce facilmente$t$, $t$Cresce molto lentamente e fiorisce solo dopo molti anni$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Ariocarpus, p. 460-461$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Astrophytum$t$,
  $t$Astrophytum$t$,
  $t$astrophytum$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere originario del Messico settentrionale e Texas meridionale, forma globosa che tende a diventare cilindrica con l'età, poche coste rilevate, cosparse di macchioline bianche irregolari, areole lanose o spinose. Specie note: Astrophytum myriostigma (senza spine, colonnare, fino a 60 cm), Astrophytum asterias (aspetto a riccio di mare, 10 cm diametro, senza spine).$t$,
  $t${"luce": "Molta luce e sole, schermare dai raggi più cocenti d'estate"}$t$::jsonb,
  ARRAY[$t$Evitare i ristagni d'acqua: lasciare asciugare il terriccio tra un'annaffiatura e l'altra$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Astrophytum, p. 462-463$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Cephalocereus$t$,
  $t$Cephalocereus$t$,
  $t$cephalocereus$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Cactus colonnare dell'America centro-meridionale (soprattutto Brasile), può arrivare a 15 m in natura (40 cm in interno). 7-8 coste rilevate a margine acuto, areole lanose con ciuffi di spine giallastre o brune, peli bianchi/grigi che ricoprono la pianta. Crescita lentissima, fiorisce solo da adulto. Specie nota: Cephalocereus senilis, "testa di vecchio" per le setole biancastre.$t$,
  $t${"luce": "Pieno sole", "acqua": "Abbondanti d'estate, quasi inesistenti d'inverno"}$t$::jsonb,
  ARRAY[$t$Sopporta bene sia la calura estiva sia temperature basse invernali (anche sotto i 7°C)$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Cephalocereus, p. 463-464$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Cereus$t$,
  $t$Cereus$t$,
  $t$cereus$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere originario dell'America centro-meridionale, oggi comprende una decina di piante colonnari ramificate dalla base o a candelabro, con poche coste evidenti orlate di spine. Raggiungono 8-10 m; molto rustici, spesso usati come portainnesti. Specie nota: Cereus giganteus (Arizona/Messico, crescita lentissima: 15 cm in 10 anni, fino a 15 m, fiorisce verso i 40 anni).$t$,
  $t${"luce": "Pieno sole", "acqua": "Moderate"}$t$::jsonb,
  ARRAY[$t$Sopportano anche temperature basse$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Cereus, p. 465-466$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Cissus$t$,
  $t$Cissus$t$,
  $t$cissus$t$,
  $t$Vitaceae$t$,
  $t$perenne$t$,
  $t$Genere di piante rampicanti originarie di Asia meridionale, Africa e Madagascar; solo alcune specie sono vere succulente (accumulano acqua nel fusto). Crescita rapida, si aggrappano tramite viticci. Specie nota: Cissus quadrangularis/cactiformis (Africa orientale, fusti a 4 coste sporgenti fino a 2,5 m, foglie trilobate rade).$t$,
  $t${"luce": "Molta luce"}$t$::jsonb,
  ARRAY[$t$La temperatura non deve scendere sotto i 10°C$t$, $t$Essendo originarie dell'emisfero australe, i cicli vegetativi possono essere sfasati rispetto alle nostre stagioni: crescono meglio in interno$t$, $t$Durante il riposo vegetativo annaffiare pochissimo$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Cissus, p. 467$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
