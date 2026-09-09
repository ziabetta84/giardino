-- Fusione atomica di ultima_cura lato database, invece di leggere-modificare-
-- scrivere lato client: il client può avere uno store idratato da cache
-- offline (il service worker la tiene fino a 30 giorni) leggermente
-- indietro rispetto al database — un update client-side che parte da quella
-- copia rischierebbe di sovrascrivere una cura di tipo diverso registrata nel
-- frattempo. Qui la fusione avviene sempre contro la riga reale e corrente.
-- security invoker (non definer): gira con i privilegi di chi chiama, quindi
-- la RLS di piante (owner_id = auth.uid()) si applica esattamente come per
-- un UPDATE diretto — nessuna elevazione di privilegio. Se la riga non
-- appartiene al chiamante (o non esiste più), l'update tocca zero righe e la
-- funzione ritorna null: il chiamante lo interpreta come "nessuna scrittura
-- avvenuta", invece di fidarsi ciecamente di un errore assente.
create or replace function registra_cura_pianta(pianta_id text, tipo_cura text, data_cura date)
returns piante
language plpgsql
security invoker
set search_path = public
as $$
declare
  risultato piante;
begin
  update piante
  set ultima_cura = coalesce(ultima_cura, '{}'::jsonb) || jsonb_build_object(tipo_cura, data_cura)
  where id = pianta_id
  returning * into risultato;

  return risultato;
end;
$$;
