-- aggiornata_il aveva solo un default 'now()' in inserimento: nessuna riga
-- lo aggiornava alle modifiche successive (come le UPDATE del blocco Fase 3
-- appena scritto), quindi il timestamp mentiva silenziosamente su quando una
-- scheda è stata davvero toccata l'ultima volta. Un trigger vero, non un
-- default, copre anche tutti gli aggiornamenti futuri — non solo questo blocco.

create schema if not exists extensions;
create extension if not exists moddatetime schema extensions;

create trigger specie_set_aggiornata_il
  before update on specie
  for each row
  execute procedure extensions.moddatetime(aggiornata_il);
