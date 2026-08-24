-- Fase 3, undicesimo batch da guida-completa-giardino (pp. 352-359, "Piante
-- da Appartamento", capitolo in chiusura): Tradescantia fluminensis, Yucca
-- elephantipes. Spathiphyllum wallisii e Vriesea splendens saltate: gia'
-- possedute e verificate via RHS. Tradescantia fluminensis e' specie
-- diversa dalla posseduta Tradescantia zebrina, nessun conflitto.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Tradescantia fluminensis$t$,
  $t$Tradescantia fluminensis$t$,
  $t$tradescantia-fluminensis$t$,
  $t$Commelinaceae$t$,
  $t$perenne$t$,
  $t$Tradescanzia originaria dell'America tropicale, foglie verdi striate di bianco, si moltiplica facilmente. Varietà diffuse: Variegata e Alba Vittata (striature giallastre), Quicksilver (striature bianco-argento).$t$,
  $t${"luce": "Diffusa", "acqua": "Moderata, non tollera ambienti troppo secchi né vicinanza a termosifoni", "terreno": "Comune terriccio per piante d'appartamento"}$t$::jsonb,
  ARRAY[$t$Foglie scure: pianta troppo secca$t$, $t$Fusti con poche foglie: luogo troppo buio$t$, $t$Con l'età perde le foglie basali: meglio sostituire le piante vecchie con nuove ottenute per talea$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "almeno una volta a settimana", "autunno": null, "inverno": "due o tre volte al mese", "primavera": null}, "concimazione": {"estate": "concime liquido ogni 25-30 giorni", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Commelinaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Tradescantia fluminensis, p. 354-355$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Yucca elephantipes$t$,
  $t$Yucca elephantipes$t$,
  $t$yucca-elephantipes$t$,
  $t$Agavaceae$t$,
  $t$perenne$t$,
  $t$Yucca originaria dell'America del Sud, fusto non ramificato con foglie lanceolate a ciuffi. Varietà ornamentale: Variegata, con margini fogliari bianco-crema.$t$,
  $t${"luce": "Zone luminose, beneficia di stare all'aperto d'estate", "acqua": "Abbondante d'estate senza ristagni", "terreno": "Torboso"}$t$::jsonb,
  ARRAY[$t$Ragnetti rossi e cocciniglie nelle screpolature del tronco e ascelle fogliari$t$, $t$Marciume alla base del fusto: eccesso d'acqua$t$, $t$Sopporta bene le escursioni termiche$t$],
  $t${"npk": {"estate": "10-5-5", "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "abbondante, senza ristagni", "autunno": null, "inverno": "ogni 10 giorni", "primavera": null}, "concimazione": {"estate": "concime liquido ogni due annaffiature", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Agavaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Yucca elephantipes, p. 358-359$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;
