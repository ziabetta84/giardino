-- Completa la scheda di Impatiens (#120) con il paragrafo di cura
-- che Roberta ha ritrascritto a mano dalla foto originale (testo
-- troppo piccolo/ruotato per essere letto con sicurezza dalle foto
-- fotografate). Sostituisce i campi di manutenzione lasciati vuoti
-- nel batch 6 con i dati completi ora disponibili dalla fonte.

update specie set
  esigenze = $j${"luce": "Molto luminosa, ma protetta dai raggi diretti del sole quando si formano i boccioli", "acqua": "Regolare, terra sempre umida in estate con nebulizzazioni (non sui fiori); diradare leggermente in inverno", "terreno": "Sostanzioso (andrà bene la terra per vasi)"}$j$::jsonb,
  alert = ARRAY[$t$il nome comune inglese "Busy Lizzie" è associato a I. walleriana, venduta in commercio anche sotto i sinonimi I. holstii e I. sultanii$t$, $t$i frutti maturi si aprono al minimo contatto, scagliando i semi a distanza$t$, $t$la fonte non riporta il simbolo di tossicità per questo genere$t$, $t$se i boccioli cadono, la luce potrebbe non essere sufficiente: nei giorni con luminosità scarsa, accendere una lampada$t$, $t$in estate la pianta può essere portata all'aperto$t$, $t$moltiplicazione per talea in qualsiasi periodo dell'anno, o per semina$t$],
  manutenzione = $j${"irrigazione": {"primavera": "regolare, terra sempre umida", "estate": "regolare, terra sempre umida, con nebulizzazioni non dirette sui fiori", "autunno": "diradare leggermente le innaffiature", "inverno": "diradare leggermente le innaffiature, locale con temperatura bassa"}, "concimazione": {"primavera": "una volta alla settimana", "estate": "una volta alla settimana", "autunno": "sospesa", "inverno": "sospesa"}, "potatura": {"primavera": "cimare regolarmente i germogli e recidere i fiori appassiti; rinvasare ogni anno", "estate": "cimare regolarmente i germogli e recidere i fiori appassiti", "autunno": "nessuna", "inverno": "nessuna"}, "npk": {"primavera": null, "estate": null, "autunno": null, "inverno": null}}$j$::jsonb
where slug = $t$impatiens$t$;
