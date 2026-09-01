-- Svuota specie.descrizione sulle 73 righe madri "verificato" in cui lo scraping
-- RHS ha catturato il banner promozionale del sito ("The new app packed with
-- trusted gardening know-how") al posto della descrizione della pianta.
-- Punto 2 del piano di naturalizzazione (issue #153).
--
-- Non si cancellano le righe: hanno esigenze / alert / famiglia_botanica /
-- nome_scientifico validi, e 25 di esse sono madri di cultivar dietro un vincolo
-- ON DELETE CASCADE (specie_specie_padre_id_fkey) -- un DELETE porterebbe via
-- centinaia di righe figlie. Si azzera solo il campo-spazzatura.
--
-- Il testo rimosso resta in descrizione_originale (popolata dalla migration
-- 20260901010000), quindi l'operazione e' reversibile riga per riga con
--   update specie set descrizione = descrizione_originale where ...
--
-- stato_verifica resta 'verificato': i dati verificati di queste righe non sono
-- nella descrizione.

begin;

update public.specie
   set descrizione = null
 where specie_padre_id is null
   and descrizione ilike '%testo originale in inglese%'
   and (descrizione ilike '%trusted gardening know-how%'
        or descrizione ilike '%new app packed with%')
   and descrizione_originale is not null;   -- guardia: solo righe gia' snapshottate

commit;
