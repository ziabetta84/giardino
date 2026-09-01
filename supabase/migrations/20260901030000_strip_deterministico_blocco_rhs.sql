-- Strip deterministico del blocco RHS marcato (punto 3 del piano, issue #153).
-- Rimuove per via puramente testuale (nessun LLM) le due parti che le regole di
-- stile della naturalizzazione impongono comunque di togliere, cosi' il batch di
-- traduzione successivo riceve un input piu' corto e pulito:
--
--   1. Prefisso label a inizio stringa:
--        "Famiglia botanica: X. [Portamento: Y. ][Altezza massima indicativa: Z m. ]"
--      -- solo la tripletta, ancorata a ^. famiglia_botanica / ciclo_vitale sono
--      gia' colonne proprie, quindi ripeterle in descrizione e' ridondanza.
--
--   2. Coda citazione-cultivar in fondo:
--        ". RHS elenca N (pagine/)cultivar coltivate [con altezze ...] (tra cui '...')."
--      -- SOLO quando arriva a fine stringa senza virgolette dopo (\. RHS elenca [^"]*$).
--      Questo garantisce che il regex non possa mai intaccare il blocco inglese
--      tra virgolette. I nomi cultivar esistono gia' come righe figlie
--      (specie_padre_id), quindi ometterli non e' perdita.
--
-- NON tocca: il marcatore "Da RHS[, descrizione del genere] (testo originale in
-- inglese): "..."" (resta, serve allo scoping self-consuming del batch); la prosa
-- italiana iniziale delle ~432 righe "mixed"; i label-dump secondari (Bloom
-- Color:, Main Bloom Time:, Form:) e ~52 righe di genere con ordine invertito
-- (citazione-cultivar prima del blocco inglese) -- li ripulisce l'LLM nel batch.
--
-- Simulazione pre-applicazione (11.593 righe marcate): 8.726 modificate,
-- marcatore mai perso, 0 residui "Famiglia botanica:", nessuna riga svuotata,
-- nessun troncamento (tutte chiudono con " oppure ".").
--
-- Reversibile: descrizione_originale (migration 20260901010000) conserva il testo
-- pre-strip di tutte le righe toccate.

begin;

with stripped as (
  select id,
         regexp_replace(
           regexp_replace(
             descrizione,
             '^Famiglia botanica: [^.]+\. (Portamento: [^.]+\. )?(Altezza massima indicativa: [-0-9.]+ m\. )?',
             ''),
           '\.\s+RHS elenca [^"]*$',
           '') as nuova
  from public.specie
  where descrizione ilike '%testo originale in inglese%'
    and descrizione_originale is not null
)
update public.specie s
   set descrizione = st.nuova
  from stripped st
 where s.id = st.id
   and s.descrizione is distinct from st.nuova;

commit;
