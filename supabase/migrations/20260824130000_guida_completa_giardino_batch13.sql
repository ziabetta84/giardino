-- Fase 3, tredicesimo batch da guida-completa-giardino (pp. 370-377, "Piante
-- Ornamentali"): Centaurea (Fiordaliso), Chrysanthemum. Calceolaria,
-- Calendula officinalis, Celosia argentea, Campanula (=isophylla) saltate:
-- gia' possedute e verificate via RHS. Senecio cineraria (=Cineraria
-- maritima) e Convallaria majalis saltate: gia' presenti, bozza PFAF gia'
-- plausibile ed il libro non aggiunge contenuto reale (nessuna avversita'
-- di rilievo segnalata per la prima, solo un suggerimento generico per la
-- seconda).

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Centaurea$t$,
  $t$Centaurea$t$,
  $t$centaurea$t$,
  $t$Compositae$t$,
  $t$biennale$t$,
  $t$Fiordaliso, biennale rustica coltivata anche come annuale, indigena dei campi. Dalle ibridazioni numerose varietà orticole a fiori grandi, semidoppi, semplici o doppi. Foglie lineato-lanceolate grigio-verdi, esistono varietà nane. Colore: bianco, rosa, rosso, azzurro. Uso: fiore reciso e bordure.$t$,
  $t${"luce": "Esposizioni al sole", "acqua": "Frequenti e abbondanti dopo la semina e durante la fioritura"}$t$::jsonb,
  ARRAY[$t$Soggetta a marciumi radicali e ad attacchi di insetti nel periodo della semina$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Centaurea, p. 374$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Chrysanthemum$t$,
  $t$Chrysanthemum$t$,
  $t$chrysanthemum$t$,
  $t$Compositae$t$,
  $t$perenne$t$,
  $t$Crisantemo, perenne a coltivazione annuale, infinite specie e varietà per taglia, forma e colore, fioritura tra maggio e novembre secondo varietà. Fiori simili alle margherite, foglie verde glauco o brillante, ovali-lobate. Colore: singoli o doppi, tutte le tonalità. Uso: aiuole fiorite, bordure, vasi per terrazze e balconi.$t$,
  $t${"luce": "Mezz'ombra, fiorisce bene anche in pieno sole", "acqua": "Abbondanti durante la fioritura e nei periodi siccitosi"}$t$::jsonb,
  ARRAY[$t$Le galle possono deformare le foglie indebolendo i getti$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Chrysanthemum, p. 377$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
