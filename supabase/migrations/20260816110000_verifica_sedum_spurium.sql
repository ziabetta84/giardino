-- Verifica reale (#120, secondo task), terzo del secondo blocco di 5:
-- sedum-spurium, fonte RHS Plants (rhs.org.uk), letta da Roberta e
-- relayata.
--
-- esigenze.luce corretta da "Sole o mezz'ombra" a "Sole": RHS mostra solo
-- l'icona "Full sun", nessuna opzione mezz'ombra (a differenza di altre
-- specie verificate finora). Qui il giudizio di adattamento al clima
-- mediterraneo va nella direzione opposta al solito: se in UK (sole più
-- debole) serve comunque pieno sole senza alternative, in estate
-- mediterranea il pieno sole serve altrettanto o più — coerente con
-- l'alert già presente sulla maggiore intensità di colore con luce forte.
--
-- esigenze.terreno arricchito da "Drenato" a "Drenato, moderatamente
-- fertile" (RHS: "moderately fertile, well-drained... soil").
--
-- Aggiunto alert mancante su lumache/limacce/larve di oziorrinco e
-- marciume di colletto/radici fungino o batterico (RHS Pests/Diseases) —
-- #132.
--
-- Confermato: resistenza_gelo "alta" = RHS H5, coerente con la scala già
-- stabilita. spaziatura_cm 20 dentro Max Spread RHS (0.1-0.5m).
--
-- Nota: RHS descrive la propagazione solo per divisione (primavera) o
-- talea legnosa (inizio estate), non per seme — coerente con
-- finestra_semina già vuota nella bozza, nessuna modifica necessaria.

update specie set
  esigenze = $j${"luce": "Sole", "acqua": "Scarsa", "terreno": "Drenato, moderatamente fertile"}$j$::jsonb,
  alert = ARRAY[$t$pianta xerofila → evitare irrigazioni frequenti$t$, $t$ama sole pieno o mezz’ombra luminosa$t$, $t$colori più intensi con luce forte e freddo$t$, $t$perfetta come tappezzante e per bordi$t$, $t$teme ristagni idrici$t$, $t$può essere soggetta a lumache, limacce e larve di oziorrinco, oltre a marciume di colletto/radici (fungino o batterico) in caso di ristagno$t$],
  fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Sedum spurium$t$],
  stato_verifica = $t$verificato$t$,
  verificata_il = now(),
  verificata_da = $t$Roberta (fonte RHS) + Claude Code (compilazione)$t$
where slug = $t$sedum-spurium$t$;
