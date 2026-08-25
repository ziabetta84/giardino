-- Fase 3, trentaquattresimo batch da guida-completa-giardino (pp. 546-553,
-- "Piante Arbustacee"): Deutzia, Forsythia. Erica e Gardenia saltate: gia'
-- possedute e verificate via RHS.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Deutzia$t$,
  $t$Deutzia$t$,
  $t$deutzia$t$,
  $t$Saxifragaceae$t$,
  $t$perenne$t$,
  $t$Specie di arbusti decidui di taglia piccola o media, per lo più di origine orientale, con foglie opposte, dentate, appuntite; fiori riuniti in corimbi o pannocchie, portati sulla vegetazione dell'anno precedente. In genere cespugli espansi, op-pure per la costituzione di siepi. Specie note: la scabra con ibridi (fiori bianchi, doppi, ricordiamo la sfumati di rosa), la gracilis (molto diffusa, fiori bianchi, doppi o leggermente sfumati di rosa), l'elegantissima (con fiori rosati e porporini), la setchuenensis corymbiflora (con fiori bianchi stellati).$t$,
  $t${"luce": "Gradisce le esposizioni in pieno sole ma anche quelle leggermente ombreggiate", "acqua": "Occorre annaffiare con una certa abbondanza nei periodi di clima molto asciutto, ma mantenere il terreno leggermente umido", "terreno": "Pur dimostrandosi piante di facile adattabilità, predilige quelli freschi, umidi, ben drenati, sia quelli argillosi e calcarei sia quelli nelle aree cittadine inquinate"}$t$::jsonb,
  ARRAY[$t$Può presentare fioriture modeste per cause diverse: eccessiva carenza di luce, scarsità di irrigazione, insufficiente fertilità del terreno. La pianta è soggetta a malattie di rado agli attacchi di malattie$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": "si effettua al principiare dell'estate dopo l'appassimento dei fiori: si riducono la metà i rami che hanno fiorito fin dove sorgono le nuove cacciate. I cespugli andranno diradati là dove si presentano troppo folti", "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "concime polivalente in primavera e all'inizio dell'estate, mentre a fine estate è utile la distribuzione di terriccio organico o letame"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Deutzia, p. 546-547$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Forsythia$t$,
  $t$Forsythia$t$,
  $t$forsythia$t$,
  $t$Oleaceae$t$,
  $t$perenne$t$,
  $t$Genere originario della Cina e dell'Europa settentrionale, si tratta di un arbusto a foglia caduca d'aspetto cespuglioso, con rametti eretti. Questi arbusti sono celebri come i Forsythia, sia per la precoce fioritura primaverile sia per il colore dei fiori giallo dorati. La Forsythia allegra e precoce di questi arbusti è per lo genere di arbusti e una delle piante che emetta le foglie. Fioritura precoce prima che la pianta emetta le foglie. Specie note: la x intermedia, la viridissima, la x Beatrix Farrand, la ovata e la suspensa.$t$,
  $t${"luce": "Prospera bene in luoghi soleggiati o per lo meno luminosi; comunque essere piantata tanto in pieno sole come in posizioni ombreggiate", "acqua": "Se la piantagione avvizzisce stagionalmente o partico-larmente caldo, occorre intervenire con abbondanti annaffiature", "terreno": "Ha una buona adattabilità ai tipi più disparati, persino a quelli calcarei. Il suolo ideale, comunque, è quello umido, nei terreni urbani"}$t$::jsonb,
  ARRAY[$t$Se si eccettuano gli attratti dalle gemme che vengono fiorire, la pianta risulta generalmente esente da attacchi di parassiti preoccupanti$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "presente che fiorisce sui rami dell'anno precedente, si opera in genere dopo la fioritura, tenendo la massima parte dei rami vecchi al fine di favorire la produzione più abbondante in estate-autunno"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "pacciamatura con letame ben maturo o terriccio organico"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Forsythia, p. 550-551$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
