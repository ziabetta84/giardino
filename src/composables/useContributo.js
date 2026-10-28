// Contributo volontario durante la beta: link esterno (Ko-fi) e invito
// mostrato una sola volta a chi si è appena registrato. La scelta (dona o
// "non ora") vive in user_metadata.contributo_invito di Supabase Auth, così
// segue l'account su ogni dispositivo; localStorage fa da riserva se
// updateUser non riesce (offline), per non riproporre l'invito sullo stesso
// dispositivo.

import { computed } from 'vue'
import { useAuth } from '@/composables/useAuth'
import { useSupabase } from '@/composables/useSupabase'

export const linkContributo = import.meta.env.VITE_LINK_CONTRIBUTO || ''

// Solo gli account creati da quando l'invito esiste: chi c'era già trova la
// card in Account, senza un foglio che si apre all'improvviso.
const INVITO_DAL = Date.parse('2026-10-28T00:00:00Z')
const CHIAVE_LOCALE = 'giardino_contributo_invito'

function vistoQui(id) {
  try { return localStorage.getItem(CHIAVE_LOCALE) === id }
  catch { return false }
}

export function useContributo() {
  const { utente } = useAuth()

  const invitoDaMostrare = computed(() => {
    const u = utente.value
    if (!linkContributo || !u) return false
    if (u.user_metadata?.contributo_invito) return false
    if (!(Date.parse(u.created_at) >= INVITO_DAL)) return false
    return !vistoQui(u.id)
  })

  // scelta: 'dona' | 'non_ora'. Best effort: l'invito non deve mai
  // bloccare né mostrare errori.
  async function segnaInvito(scelta) {
    const u = utente.value
    if (!u) return
    try { localStorage.setItem(CHIAVE_LOCALE, u.id) } catch { /* storage inaccessibile */ }
    try {
      await useSupabase().auth.updateUser({
        data: { contributo_invito: { scelta, il: new Date().toISOString() } },
      })
    } catch { /* resta il segno locale */ }
  }

  return { linkContributo, invitoDaMostrare, segnaInvito }
}
