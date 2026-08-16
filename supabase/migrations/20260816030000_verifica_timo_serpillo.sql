-- Verifica reale (#120, secondo task), terza e ultima specie del pilota:
-- timo-serpillo (Thymus serpyllum), fonte RHS Plants (rhs.org.uk), letta da
-- Roberta e relayata. Come salcerella, la bozza risulta già accurata su
-- tutti i campi verificabili: nessuna correzione necessaria.
--
-- Conferme: esigenze.luce "Pieno sole" = RHS "Full sun"; esigenze.terreno
-- "Drenato" = RHS "Well-drained" (Chalk/Loam/Sand, "Suitable for a rock
-- garden or paving crevices"); esigenze.acqua "Scarsa" coerente con RHS
-- Drought Resistance "Yes"; resistenza_gelo "alta" = RHS H5, stessa fascia
-- già usata per marsilea-quadrifolia; spaziatura_cm 25 rientra nel Max
-- Spread RHS (0.1-0.5m); finestra_semina primavera = RHS "Propagate by seed
-- or division, in spring" — qui, a differenza di salcerella, la semina è
-- esplicitamente documentata dalla fonte, non solo la divisione.
--
-- giorni_germinazione/giorni_trapianto (day-count esatti) restano stime di
-- bozza: la fonte conferma il metodo e la stagione ma non fornisce cifre.

update specie set
  fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Thymus serpyllum$t$],
  stato_verifica = $t$verificato$t$,
  verificata_il = now(),
  verificata_da = $t$Roberta (fonte RHS) + Claude Code (compilazione)$t$
where slug = $t$timo-serpillo$t$;
