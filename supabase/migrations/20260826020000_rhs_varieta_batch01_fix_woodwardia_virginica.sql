-- Corregge un errore di trascrizione introdotto applicando il batch
-- precedente (20260826010000): il testo del genere Woodwardia era stato
-- duplicato per errore nella riga woodwardia-virginica.
update specie set
  descrizione = replace(
    descrizione,
    $t$Da RHS, descrizione del genere (testo originale in inglese): "Da RHS, descrizione del genere (testo originale in inglese): "$t$,
    $t$Da RHS, descrizione del genere (testo originale in inglese): "$t$
  )
where slug = 'woodwardia-virginica';
