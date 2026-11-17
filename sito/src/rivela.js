// v-rivela: una tavola sale e si posa quando entra nella vista. Il contenuto è
// visibile di suo (HTML statico, senza JavaScript, con «riduci movimento»):
// la classe che lo nasconde arriva solo nel browser, subito prima di osservarlo.
let osservatore = null

function osserva() {
  if (osservatore) return osservatore
  osservatore = new IntersectionObserver((voci) => {
    for (const v of voci) {
      if (!v.isIntersecting) continue
      v.target.classList.add('is-visto')
      osservatore.unobserve(v.target)
    }
  }, { rootMargin: '0px 0px -12% 0px', threshold: 0.08 })
  return osservatore
}

export const rivela = {
  getSSRProps: () => ({}),
  mounted(el, { value }) {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
    const r = el.getBoundingClientRect()
    if (r.top < window.innerHeight * 0.9) return
    el.classList.add('rivela')
    if (value) el.style.setProperty('--ritardo', `${value}ms`)
    osserva().observe(el)
  },
  unmounted(el) {
    osservatore?.unobserve(el)
  },
}
