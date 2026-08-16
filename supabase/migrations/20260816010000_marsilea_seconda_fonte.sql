-- Conferma indipendente della verifica di marsilea-quadrifolia (#120): Roberta
-- ha controllato un secondo sito, italiano ("Le Georgiche" / venditapianteonline.it),
-- che riporta gli stessi valori chiave della fonte RHS già registrata
-- (Esposizione: Sole; Rusticità: H5, -15/-10°C) — nessuna correzione ai dati,
-- solo aggiunta della fonte a scopo di tracciabilità/rigore.

update specie set
  fonti = array_append(fonti, $t$Le Georgiche / venditapianteonline.it — conferma esposizione e rusticità$t$)
where slug = $t$marsilea-quadrifolia$t$;
