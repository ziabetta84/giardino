-- Aggiunge specie.descrizione_originale e vi copia il testo pre-naturalizzazione
-- del blocco RHS marcato in inglese (11.666 righe madri), come rete di sicurezza
-- prima della riscrittura di stile prevista dalla issue #153 (skill
-- naturalizza-descrizioni). Senza questo snapshot l'unico ripristino possibile
-- sarebbe il dump completo del DB (backups/, non versionato), che riporterebbe
-- indietro l'intero database invece delle sole righe da correggere.
--
-- Ambito volutamente limitato al blocco marcato:
--   * le fasi successive (prosa PFAF inglese non marcata, stub italiani) faranno
--     il proprio snapshot nel proprio lotto, quando lo scoping sara' definito in
--     modo robusto (colonna lingua_descrizione, punto 6 del piano);
--   * i lotti italiani gia' naturalizzati il 31/08-01/09 (215 + 583 righe) NON
--     vanno snapshottati qui: la loro descrizione non e' piu' l'originale, e
--     copiarla darebbe a descrizione_originale un valore fuorviante.

begin;

alter table public.specie
  add column if not exists descrizione_originale text;

comment on column public.specie.descrizione_originale is
  'Copia della descrizione precedente alla naturalizzazione di stile (issue #153). '
  'Popolata per lotto, subito prima di riscrivere descrizione. '
  'NULL = riga mai naturalizzata oppure lotto non ancora snapshottato.';

update public.specie
   set descrizione_originale = descrizione
 where specie_padre_id is null
   and descrizione ilike '%testo originale in inglese%'
   and descrizione_originale is null;

commit;

-- Rende visibile la nuova colonna alla Data API (non e' comunque tra le
-- COLONNE_SPECIE lette dall'app, quindi non finisce nel payload del client).
notify pgrst, 'reload schema';
