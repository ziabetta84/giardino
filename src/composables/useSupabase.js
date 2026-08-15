import { createClient } from '@supabase/supabase-js'

// URL e chiave "anon"/"publishable" sono fatte apposta per stare nel bundle
// del browser: l'accesso reale è limitato dalle policy RLS sul database, non
// da questa chiave. Non è il posto per una service_role key.
const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

const client = createClient(url, anonKey)

export function useSupabase() {
  return client
}
