// Stato del repository, non solo del fetch locale dei JSON: dice se una
// modifica (da Claude Code, da un altro dispositivo, o dalla web app stessa)
// è appena stata committata/pushata e sta ancora venendo pubblicata su
// GitHub Pages, così l'utente sa perché non vede ancora un cambiamento
// atteso invece di pensare che l'app sia bloccata o rotta.
import { ref, onMounted, onUnmounted } from 'vue'

const OWNER    = 'ziabetta84'
const REPO     = 'giardino'
const WORKFLOW = 'deploy.yml'

function headers() {
  const token = localStorage.getItem('github_token')
  return token ? { Authorization: `Bearer ${token}` } : {}
}

export function useRepoStatus() {
  // 'sincronizzazione' → un commit su main non è ancora stato pubblicato
  // 'nuova-versione'   → pubblicato, ma questa scheda ha ancora la build precedente
  // 'aggiornato'        → questa scheda mostra l'ultima versione pubblicata
  // 'sconosciuto'       → nessuna risposta ancora, o errore/rate-limit di rete
  const stato = ref('sconosciuto')
  let timer = null

  async function controlla() {
    try {
      const [commitRes, runRes] = await Promise.all([
        fetch(`https://api.github.com/repos/${OWNER}/${REPO}/commits/main`, { headers: headers() }),
        fetch(`https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows/${WORKFLOW}/runs?branch=main&per_page=1`, { headers: headers() }),
      ])
      if (!commitRes.ok || !runRes.ok) return  // errore temporaneo/rate-limit: mantiene l'ultimo stato noto

      const ultimoCommit = (await commitRes.json()).sha
      const ultimoRun = (await runRes.json()).workflow_runs?.[0]
      const pubblicato = ultimoRun?.head_sha === ultimoCommit && ultimoRun?.status === 'completed'

      if (!pubblicato) {
        stato.value = 'sincronizzazione'
      } else if (__APP_COMMIT__ && ultimoCommit !== __APP_COMMIT__) {
        stato.value = 'nuova-versione'
      } else {
        stato.value = 'aggiornato'
      }
    } catch {
      // Silenzioso: rete assente o irraggiungibile, riprova al giro successivo.
    }
  }

  function onVisibilita() {
    if (document.visibilityState === 'visible') controlla()
  }

  onMounted(() => {
    controlla()
    // Con token l'app ha 5000 richieste/ora (2 per controllo → ok anche
    // frequente); senza token il limite anonimo è 60/ora, quindi un
    // intervallo molto più largo per restare ampiamente sotto soglia.
    const intervallo = localStorage.getItem('github_token') ? 20_000 : 180_000
    timer = setInterval(() => {
      if (document.visibilityState === 'visible') controlla()
    }, intervallo)
    document.addEventListener('visibilitychange', onVisibilita)
  })

  onUnmounted(() => {
    if (timer) clearInterval(timer)
    document.removeEventListener('visibilitychange', onVisibilita)
  })

  return { stato }
}
