import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'
import { calcolaCodiceZonaClimatica } from '@/composables/useZonaClimatica'

export function useSettingsApi() {
  const store = useDatiStore()
  const supabase = useSupabase()

  // zona_climatica_id: una scelta esplicita dell'utente (dropdown in
  // SettingsView) ha sempre la precedenza. In assenza di scelta esplicita,
  // calcolato solo se ancora mai impostato (null) — una volta valorizzato
  // (auto o a mano) non viene più ricalcolato automaticamente, anche se
  // location cambia, per non sovrascrivere una correzione manuale.
  async function salvaSettings(dati) {
    const riga = { location: dati.location, units: dati.units, meteo: dati.meteo, ui: dati.ui }

    if (dati.zona_climatica_id) {
      riga.zona_climatica_id = dati.zona_climatica_id
    } else if (!store.settings?.zona_climatica_id && dati.location) {
      const codice = calcolaCodiceZonaClimatica(dati.location)
      if (codice) {
        const { data: zc } = await supabase.from('zone_climatiche').select('id').eq('codice', codice).single()
        if (zc) riga.zona_climatica_id = zc.id
      }
    }

    const { data, error } = await supabase.from('settings').upsert(riga, { onConflict: 'owner_id' }).select().single()
    if (error) throw error
    store.settings = {
      location: data.location, units: data.units, meteo: data.meteo,
      ui: data.ui, zona_climatica_id: data.zona_climatica_id,
    }
  }

  return { salvaSettings }
}
