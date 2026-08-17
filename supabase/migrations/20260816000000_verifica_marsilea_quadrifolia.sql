-- Verifica reale della bozza (#120, secondo task), prima specie del
-- processo: fonte RHS Plants (rhs.org.uk), letta da Roberta e relayata.
-- Tre correzioni rispetto alla bozza: esigenze.luce era "Mezz'ombra", RHS
-- dice "Full sun"; finestra_trapianto era primavera, la divisione dei
-- rizomi si fa in estate secondo RHS; resistenza_gelo era "media", la
-- classificazione RHS è H5 (fino a -15/-10°C) quindi "alta". Confermato
-- invece l'irrigazione_fattore >1 (caso limite già segnalato in Fase 3):
-- RHS conferma "muddy pool margins", "poorly-drained".

update specie set
  esigenze = $j${"luce": "Pieno sole", "acqua": "Molto abbondante", "terreno": "Umido"}$j$::jsonb,
  ciclo_colturale = $j${"famiglia_botanica": "Marsileaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["estate"], "resistenza_gelo": "alta", "spaziatura_cm": 40, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb,
  fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Marsilea quadrifolia$t$],
  stato_verifica = $t$verificato$t$,
  verificata_il = now(),
  verificata_da = $t$Roberta (fonte RHS) + Claude Code (compilazione)$t$
where slug = $t$marsilea-quadrifolia$t$;
