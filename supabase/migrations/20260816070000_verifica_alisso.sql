-- Verifica reale (#120, secondo task), quarto del blocco di 5: alisso,
-- fonte RHS Plants (rhs.org.uk), letta da Roberta e relayata.
--
-- Corretta un'incoerenza interna già presente nella bozza: descrizione
-- diceva "Perenne tappezzante" ma ciclo_vitale era "annuale". RHS classifica
-- Lobularia maritima come "annual or short-lived perennial" (etichetta
-- "Annual Biennial"); in clima mediterraneo mite (Fano) si comporta
-- tipicamente da perenne di breve durata, coerente con la descrizione
-- esistente. ciclo_vitale corretto a "perenne".
--
-- esigenze.terreno arricchito da "Drenato" a "Drenato, moderatamente
-- fertile" (RHS: "light, moderately fertile, well-drained soil").
--
-- Aggiunto alert mancante su parassiti/malattie reali documentati da RHS
-- (peronospora, ernia del cavolo, altica, lumache) — #132.
--
-- Confermato: esigenze.luce "Sole" = RHS Full sun; resistenza_gelo "media"
-- = RHS H3, coerente con la scala già stabilita (H2→bassa per zinnia, un
-- gradino sopra→media); spaziatura_cm 20 dentro Max Spread RHS (0.1-0.5m).
--
-- Non toccata finestra_semina (include "autunno" oltre "primavera"): RHS
-- cita solo semina primaverile (standard per clima UK), ma la semina
-- autunnale è pratica comune in clima mediterraneo mite per specie di
-- questo tipo — adattamento climatico ragionevole, non smentito da RHS.

update specie set
  esigenze = $j${"luce": "Sole", "acqua": "Moderata", "terreno": "Drenato, moderatamente fertile"}$j$::jsonb,
  ciclo_vitale = $t$perenne$t$,
  alert = ARRAY[$t$ama sole pieno o mezz’ombra luminosa$t$, $t$fioritura lunghissima$t$, $t$teme ristagni idrici$t$, $t$ottima come tappezzante da bordo$t$, $t$può essere soggetta a peronospora, ernia del cavolo (clubroot), altica e lumache$t$],
  fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Lobularia maritima$t$],
  stato_verifica = $t$verificato$t$,
  verificata_il = now(),
  verificata_da = $t$Roberta (fonte RHS) + Claude Code (compilazione)$t$
where slug = $t$alisso$t$;
