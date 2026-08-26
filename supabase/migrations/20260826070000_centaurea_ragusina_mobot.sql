-- Fase 3 (issue #120): arricchimento centaurea-ragusina con fonti reali.
-- RHS ha una pagina ma solo descrizione di genere (nessun dato colturale
-- specifico) -> non basta a promuovere stato_verifica. Missouri Botanical
-- Garden Plant Finder ha dati di coltivazione reali ma per la cultivar
-- brevettata 'Balcentsirl' (Silver Swirl), non per la specie pura -> decisione
-- utente: MOBOT vale come fonte primaria (come RHS) solo quando i dati sono
-- riferiti alla specie stessa, non alla singola cultivar. Qui restano quindi
-- 'bozza', ma con fonte corretta (la vecchia nota "nessuna pagina RHS
-- disponibile" era stale, ora RHS è consultata e citata) e con i dati della
-- cultivar aggiunti in descrizione.

update specie
set
  descrizione = descrizione || $t$

La cultivar 'Balcentsirl' (Silver Swirl®, brevetto USA PP35838) ha fogliame bianco-argento più compatto e ondulato ai margini, e rusticità migliorata (zone USDA 6-9) rispetto alla specie base.$t$,
  fonti = array_append(fonti, 'Missouri Botanical Garden Plant Finder (missouribotanicalgarden.org) — scheda cultivar ''Balcentsirl'' (Silver Swirl): dati di coltivazione generali confermati per la specie (sole pieno, terreno drenante/povero, tollerante a caldo/siccità/vento/salsedine); rusticità zone 6-9 riferita alla sola cultivar, non alla specie pura, quindi non usata per promuovere lo stato_verifica'),
  verificata_il = now(),
  verificata_da = 'Claude Code (ricerca web: RHS - solo genere, nessun contenuto specifico; Missouri Botanical Garden Plant Finder - dati cultivar)'
where slug = 'centaurea-ragusina'
  and not ('Missouri Botanical Garden Plant Finder (missouribotanicalgarden.org) — scheda cultivar ''Balcentsirl'' (Silver Swirl): dati di coltivazione generali confermati per la specie (sole pieno, terreno drenante/povero, tollerante a caldo/siccità/vento/salsedine); rusticità zone 6-9 riferita alla sola cultivar, non alla specie pura, quindi non usata per promuovere lo stato_verifica' = any(fonti));

update specie
set fonti = array_replace(
  fonti,
  'Vivai Le Georgiche (legeorgiche.it) — Centaurea ragusina (fonte vivaistica italiana, usata come fallback: nessuna pagina RHS disponibile, pagina Acta Plantarum priva di dati di coltivazione)',
  'Vivai Le Georgiche (legeorgiche.it) — Centaurea ragusina (fonte vivaistica italiana, usata come fallback: la pagina RHS esiste ma contiene solo descrizione di genere senza dati colturali specifici, pagina Acta Plantarum priva di dati di coltivazione)'
)
where slug = 'centaurea-ragusina';
