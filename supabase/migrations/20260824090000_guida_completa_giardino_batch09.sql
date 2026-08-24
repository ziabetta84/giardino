-- Fase 3, nono batch da guida-completa-giardino (pp. 342-343, "Piante da
-- Appartamento"): Pilea cadierei. Chiude il capitolo "Piante da
-- Appartamento" (foto 191107-191744).

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Pilea cadierei$t$,
  $t$Pilea cadierei$t$,
  $t$pilea-cadierei$t$,
  $t$Urticaceae$t$,
  $t$perenne$t$,
  $t$Pilea originaria dell'Indocina, con foglie verde intenso screziate d'argento. Curiosità: quando il polline dei fiori è maturo, una leggera brezza fa scattare il filamento dell'antera lanciando in alto una piccola nube di polline.$t$,
  $t${"luce": "Non fortissima, tollera anche zone poco soleggiate", "acqua": "Moderata, mai ristagni nel sottovaso", "terreno": "Sabbia e torba in parti uguali"}$t$::jsonb,
  ARRAY[$t$Insetti verdi: afidi, vedi trattamento specifico$t$, $t$Foglie marce: muffa grigia, trattare con anticrittogamico$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "tagliare nella parte alta ogni tanto per favorire i getti laterali"}, "irrigazione": {"estate": "2-3 volte a settimana", "autunno": null, "inverno": "una volta a settimana", "primavera": null}, "concimazione": {"estate": "concime liquido ogni 15-20 giorni", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Urticaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Pilea cadierei, p. 342-343$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;
