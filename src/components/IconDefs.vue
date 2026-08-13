<template>
  <svg style="position:absolute;width:0;height:0;overflow:hidden" aria-hidden="true">
    <defs>
      <!-- Icone "acquerellate": silhouette piena, un colore per icona, bordo
           organico invece che geometrico, con un accento più scuro dove il
           colore "si raccoglie" (ritagliato dentro la forma via clipPath).
           Nessuna linea sottile: a 16-19px (barra del menù) resterebbe
           illeggibile — vedi issue #92. -->
      <clipPath id="clip-goccia"><path d="M12.7 2.6c3.2 4.2 7 9.1 6.5 12.2a6.6 6.6 0 0 1-13.1.1C5.6 11.5 9.4 6.8 12.7 2.6z"/></clipPath>
      <clipPath id="clip-foglia"><path d="M3.7 19.6C4.6 9.3 11 3.9 20.9 4.4c0 9.7-6.3 15.6-17.2 15.2z"/></clipPath>
      <clipPath id="clip-concimazione"><path d="M12.3 21.3a1 1 0 0 1-1.1-1v-5.5c-3.4-.2-5.9-2.6-6.3-6.8 4.2.1 6.7 1.8 7.3 5.2.4-3.3 2.8-5.1 7.2-5.4-.3 4.1-2.7 6.6-6.1 7v5.5a1 1 0 0 1-1 1z"/></clipPath>
      <clipPath id="clip-campanella"><path d="M12.2 3.3a5.7 5.7 0 0 1 5.7 5.6v2.1c0 2.5.6 3 1.5 4.3.6.9-.1 1.9-1.2 1.9H6.2c-1.1 0-1.8-1-1.2-1.9.9-1.3 1.5-1.8 1.5-4.3V8.9a5.7 5.7 0 0 1 5.7-5.6z"/></clipPath>
      <clipPath id="clip-provetta"><path d="M9.9 4.5h4.2v8.6l3.7 5.1a3 3 0 0 1-2.5 4.9H8.6a3 3 0 0 1-2.4-4.9l3.7-5.1z"/></clipPath>
      <clipPath id="clip-pin"><path d="M12.3 21.3S4.5 14 4.6 8.5a7.4 7.4 0 1 1 14.9.3c-.2 5.5-7.2 12.5-7.2 12.5z"/></clipPath>
      <clipPath id="clip-cornice"><path d="M6.4 15.6 10 11l2.6 3 2.3-2.7L17.6 15.6z"/></clipPath>
      <clipPath id="clip-lampadina"><circle cx="12" cy="9.7" r="6.3"/></clipPath>
      <clipPath id="clip-meteo"><path d="M9.6 14.8h6.6a3.9 3.9 0 0 0 .4-7.8 5.3 5.3 0 0 0-9.9-1.9 4.6 4.6 0 0 0 2.9 9.7z"/></clipPath>
      <clipPath id="clip-fotocamera"><circle cx="12" cy="14.3" r="4.3"/></clipPath>

      <symbol id="i-goccia" viewBox="0 0 24 24">
        <path fill="var(--acqua)" d="M12.7 2.6c3.2 4.2 7 9.1 6.5 12.2a6.6 6.6 0 0 1-13.1.1C5.6 11.5 9.4 6.8 12.7 2.6z"/>
        <g clip-path="url(#clip-goccia)"><ellipse cx="9.2" cy="16.6" rx="4.4" ry="3.5" fill="var(--acqua-dark)" opacity=".45"/></g>
      </symbol>
      <symbol id="i-foglia" viewBox="0 0 24 24">
        <path fill="var(--olive)" d="M3.7 19.6C4.6 9.3 11 3.9 20.9 4.4c0 9.7-6.3 15.6-17.2 15.2z"/>
        <g clip-path="url(#clip-foglia)"><ellipse cx="7.1" cy="16.9" rx="4.6" ry="3.2" fill="var(--olive-dark)" opacity=".45" transform="rotate(-24 7.1 16.9)"/></g>
      </symbol>
      <!-- Germoglio: due foglioline + stelo, per non confondersi con la
           foglia singola usata per "Piante". -->
      <symbol id="i-concimazione" viewBox="0 0 24 24">
        <path fill="var(--olive)" d="M12.3 21.3a1 1 0 0 1-1.1-1v-5.5c-3.4-.2-5.9-2.6-6.3-6.8 4.2.1 6.7 1.8 7.3 5.2.4-3.3 2.8-5.1 7.2-5.4-.3 4.1-2.7 6.6-6.1 7v5.5a1 1 0 0 1-1 1z"/>
        <g clip-path="url(#clip-concimazione)"><ellipse cx="12" cy="15.6" rx="2.7" ry="3.6" fill="var(--olive-dark)" opacity=".4"/></g>
      </symbol>
      <!-- Forbici: anelli + lame che si incrociano in un unico punto (il
           perno), non due cunei separati — resta leggibile a 16px. -->
      <symbol id="i-potatura" viewBox="0 0 24 24">
        <path stroke="var(--rose)" fill="none" stroke-width="3" stroke-linecap="round" d="M6.6 6.9 19 17.5"/>
        <path stroke="var(--rose)" fill="none" stroke-width="3" stroke-linecap="round" d="M6.6 17.1 19 6.5"/>
        <circle fill="var(--rose)" cx="6.6" cy="6.9" r="3"/>
        <circle fill="var(--rose)" cx="6.6" cy="17.1" r="3"/>
        <circle cx="12.6" cy="12" r="1.3" fill="var(--rose-dark)" opacity=".55"/>
      </symbol>
      <symbol id="i-campanella" viewBox="0 0 24 24">
        <g transform="translate(12,12) scale(1.1) translate(-12,-10.9)">
          <path fill="var(--rose)" d="M12.2 3.3a5.7 5.7 0 0 1 5.7 5.6v2.1c0 2.5.6 3 1.5 4.3.6.9-.1 1.9-1.2 1.9H6.2c-1.1 0-1.8-1-1.2-1.9.9-1.3 1.5-1.8 1.5-4.3V8.9a5.7 5.7 0 0 1 5.7-5.6z"/>
          <g clip-path="url(#clip-campanella)"><ellipse cx="12.6" cy="14.8" rx="4" ry="3" fill="var(--rose-dark)" opacity=".4"/></g>
          <circle fill="var(--rose)" cx="12" cy="19.3" r="1.5"/>
        </g>
      </symbol>
      <!-- Dimensioni normalizzate: ogni icona della barra del menù occupa lo
           stesso ingombro visivo (~16 unità su 24), non solo lo stesso
           riquadro — altrimenti forme "magre" sembrano più piccole di
           forme che riempiono l'intero canvas. -->
      <symbol id="i-provetta" viewBox="0 0 24 24">
        <g transform="translate(12,12) scale(0.87) translate(-12,-12)">
          <path fill="var(--sage)" d="M9 2.6h6v1.9H9z"/>
          <path fill="var(--sage)" d="M9.9 4.5h4.2v8.6l3.7 5.1a3 3 0 0 1-2.5 4.9H8.6a3 3 0 0 1-2.4-4.9l3.7-5.1z"/>
          <g clip-path="url(#clip-provetta)"><ellipse cx="12" cy="17.6" rx="3" ry="2.6" fill="var(--sage-dark)" opacity=".45"/></g>
        </g>
      </symbol>
      <symbol id="i-pin" viewBox="0 0 24 24">
        <g transform="translate(12,12) scale(0.8) translate(-12,-12)">
          <path fill="var(--gold)" d="M12.3 21.3S4.5 14 4.6 8.5a7.4 7.4 0 1 1 14.9.3c-.2 5.5-7.2 12.5-7.2 12.5z"/>
          <g clip-path="url(#clip-pin)"><ellipse cx="11.6" cy="16.3" rx="3.6" ry="3.8" fill="var(--gold-ink)" opacity=".35"/></g>
        </g>
      </symbol>
      <!-- Cornice: contiene una foto vera (sole + montagne), non un
           rettangolo vuoto. -->
      <symbol id="i-cornice" viewBox="0 0 24 24">
        <path fill="var(--sage)" fill-rule="evenodd" d="M3 4.6h18v14.8H3zM5.4 7v10h13.2V7z"/>
        <circle fill="var(--sage)" cx="15.3" cy="9.7" r="1.7"/>
        <path fill="var(--sage)" d="M6.4 15.6 10 11l2.6 3 2.3-2.7L17.6 15.6z"/>
        <g clip-path="url(#clip-cornice)"><ellipse cx="10.5" cy="14.6" rx="2.8" ry="1.8" fill="var(--sage-dark)" opacity=".4"/></g>
      </symbol>
      <!-- Lampadina: idea/progetto. -->
      <symbol id="i-lampadina" viewBox="0 0 24 24">
        <circle fill="var(--olive)" cx="12" cy="9.7" r="6.3"/>
        <g clip-path="url(#clip-lampadina)"><ellipse cx="12" cy="13.2" rx="3.6" ry="2.6" fill="var(--olive-dark)" opacity=".4"/></g>
        <rect fill="var(--olive)" x="9.5" y="14.6" width="5" height="2.8" rx="0.7"/>
        <rect fill="var(--olive)" x="9.9" y="17.8" width="4.2" height="1.8" rx="0.7"/>
      </symbol>
      <symbol id="i-meteo" viewBox="0 0 24 24">
        <circle fill="var(--gold)" cx="8.4" cy="8.4" r="3.6"/>
        <path fill="var(--gold)" opacity=".55" d="M9.6 14.8h6.6a3.9 3.9 0 0 0 .4-7.8 5.3 5.3 0 0 0-9.9-1.9 4.6 4.6 0 0 0 2.9 9.7z"/>
        <g clip-path="url(#clip-meteo)"><ellipse cx="13.5" cy="12.6" rx="3.6" ry="1.6" fill="var(--gold-ink)" opacity=".3"/></g>
      </symbol>
      <!-- Gatto sereno ("Zorba dice"): due occhi chiusi ad arco + un
           sorriso, un solo colore — pensato per essere rassicurante, non
           un pattern. -->
      <symbol id="i-gatto" viewBox="0 0 24 24">
        <g transform="translate(12,12) scale(1.25) translate(-12,-9.7)">
          <path fill="var(--gold)" d="M6 3.6 9 7.4a8 8 0 0 1 6 0l3-3.8.6 5A7.2 7.2 0 1 1 5.4 8.6z"/>
          <path stroke="var(--gold-ink)" fill="none" stroke-width="1.3" stroke-linecap="round" d="M8.6 12.9c.5.7 1 1 1.5.3M15.4 12.9c-.5.7-1 1-1.5.3"/>
          <path stroke="var(--gold-ink)" fill="none" stroke-width="1.2" stroke-linecap="round" d="M10.6 16.2c.5.6 1 .9 1.4.9s.9-.3 1.4-.9"/>
        </g>
      </symbol>
      <!-- Home: lo stesso profilo di Zorba, in nero pieno e senza dettagli —
           stilizzato, senza pattern oro né occhi verdi. -->
      <symbol id="i-gatto-nero" viewBox="0 0 24 24">
        <g transform="translate(12,12) scale(1.25) translate(-12,-9.7)">
          <path fill="#000" d="M6 3.6 9 7.4a8 8 0 0 1 6 0l3-3.8.6 5A7.2 7.2 0 1 1 5.4 8.6z"/>
        </g>
      </symbol>
      <!-- Fotocamera: corpo + mirino sporgente, anello chiaro e obiettivo
           scuro con un riflesso ritagliato dentro, come le altre icone. -->
      <symbol id="i-fotocamera" viewBox="0 0 24 24">
        <path fill="var(--sage)" d="M8.7 5.4a1 1 0 0 1 .9-.6h4.8a1 1 0 0 1 .9.6l.8 1.7h2.5A2.3 2.3 0 0 1 21.4 9.4v8.3A2.3 2.3 0 0 1 19.1 20H4.9a2.3 2.3 0 0 1-2.3-2.3V9.4a2.3 2.3 0 0 1 2.3-2.3h2.5z"/>
        <circle fill="var(--cream)" cx="12" cy="14.3" r="4.6"/>
        <circle fill="var(--sage)" cx="12" cy="14.3" r="3.7"/>
        <g clip-path="url(#clip-fotocamera)"><ellipse cx="10.4" cy="16.1" rx="2" ry="1.5" fill="var(--sage-dark)" opacity=".5"/></g>
      </symbol>
      <symbol id="i-back" viewBox="0 0 24 24"><path fill="currentColor" d="M14.7 4.6 7.3 12l7.4 7.4 1.4-1.4L10.1 12l5.9-5.9z"/></symbol>
      <symbol id="i-matita" viewBox="0 0 24 24"><path fill="currentColor" d="M4 20h4.4l10-10-4.4-4.4-10 10zM17.4 3.9 20.1 6.6l1.5-1.5a1.6 1.6 0 0 0 0-2.3l-.3-.3a1.6 1.6 0 0 0-2.3 0z"/></symbol>
      <symbol id="i-cerca" viewBox="0 0 24 24"><circle cx="10.2" cy="10.2" r="6.4" fill="none" stroke="currentColor" stroke-width="2.1"/><line x1="15.1" y1="15.1" x2="20.6" y2="20.6" stroke="currentColor" stroke-width="2.1" stroke-linecap="round"/></symbol>
    </defs>
  </svg>
</template>
