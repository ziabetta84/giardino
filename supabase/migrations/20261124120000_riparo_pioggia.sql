-- Zone e sottozone all'aperto ma al riparo dalla pioggia (tettoia, veranda,
-- terrazzo coperto), scelta di Roberta del 24/11/2026. Per le piante che
-- contengono la pioggia, prevista o caduta, non sostituisce l'irrigazione
-- (valutaCura in supabase/functions/zorba/condivisi/cure.js). Una pianta è al
-- riparo se lo è la sua zona o la sua sottozona.
-- Rollback:
--   alter table public.zone drop column riparo_pioggia;
--   alter table public.sottozone drop column riparo_pioggia;
alter table public.zone add column riparo_pioggia boolean not null default false;
alter table public.sottozone add column riparo_pioggia boolean not null default false;
