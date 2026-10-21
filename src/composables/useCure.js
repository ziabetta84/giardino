// La logica delle cure vive accanto alla Edge Function `zorba`, che la usa per
// dire a Zorba se una cura è in ritardo con lo stesso criterio dell'app: un
// solo file, così app e Zorba non possono dare risposte diverse.
export * from '../../supabase/functions/zorba/condivisi/cure.js'
