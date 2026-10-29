-- Rollback di supabase/migrations/20261029140000_immagini_automatiche_2.sql: toglie le immagini automatiche (le schede erano tutte senza immagine).
-- psql "$SUPABASE_DB_URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/immagini/riempi/rollback_20261029140000_immagini_automatiche_2.sql
update public.schede set immagine = null where immagine->>'origine' = 'automatica 29/10/2026, secondo giro';
