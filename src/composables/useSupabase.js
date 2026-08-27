import { createClient } from '@supabase/supabase-js'

// URL e chiave "anon"/"publishable" sono fatte apposta per stare nel bundle
// del browser: l'accesso reale è limitato dalle policy RLS sul database, non
// da questa chiave. Non è il posto per una service_role key.
const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

// flowType 'pkce': il recupero password (vedi useAuth.js) rimanda l'utente
// con un codice in query string invece che nel fragment dell'URL — con
// createWebHashHistory (vue-router) anche le route vivono nel fragment, e i
// due si pesterebbero i piedi se restassimo sul flow 'implicit' di default.
const client = createClient(url, anonKey, { auth: { flowType: 'pkce' } })

export function useSupabase() {
  return client
}
