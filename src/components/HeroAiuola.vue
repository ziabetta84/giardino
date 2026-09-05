<template>
            <svg
    ref="scenaEl"
    class="zc-scene"
    :class="{ play: animare }"
    :data-light="luce"
    :data-season="stagione"
    viewBox="0 0 400 250"
    preserveAspectRatio="xMidYMax slice"
    aria-hidden="true"
  >
              <defs>
                <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0" style="stop-color:var(--scn-sky-a)"/>
                  <stop offset="1" style="stop-color:var(--scn-sky-b)"/>
                </linearGradient>
                <radialGradient id="wash">
                  <stop offset="0" style="stop-color:var(--scn-wash)"/>
                  <stop offset="100%" style="stop-color:var(--scn-wash)" stop-opacity="0"/>
                </radialGradient>
                <!-- grana di carta: lega il gradiente piatto del cielo alla texture a china del resto della scena -->
                <filter id="grain" x="0%" y="0%" width="100%" height="100%">
                  <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="2" result="n"/>
                  <feColorMatrix in="n" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0.9 0 0 0 0"/>
                </filter>
                <path id="stemShape"
                      d="M150,428 C138,392 143,352 152,318 C162,278 172,232 180,196
                         C183,183 186,171 189,159 L200,159
                         C196,172 191,184 187,197
                         C177,233 165,278 158,318 C151,352 149,392 162,428 Z"/>
                <path id="flowerShape"
                      d="M241,150 C241,133 233,119 220,115 C212,100 198,92 184,92 C168,92 155,100 148,115
                         C133,119 126,135 126,150 C126,167 136,179 148,185 C157,195 171,200 184,200
                         C201,200 213,195 221,184 C232,178 241,166 241,150 Z"/>
                <path id="flowerShape2"
                      d="M232,146 C230,120 222,102 213,96 C195,84 178,86 162,108
                         C148,122 134,130 124,146 C130,168 142,182 159,189
                         C178,200 198,200 212,195 C226,188 234,168 232,146 Z"/>
                <path id="bushShape"
                      d="M246,150 C244,128 230,116 214,113 C200,100 186,94 172,96
                         C152,99 138,108 132,125 C126,145 130,160 139,172
                         C148,186 162,192 174,194 C192,198 210,198 222,197
                         C238,190 248,172 246,150 Z"/>
                <path id="leafShape"
                      d="M0,0 C8,-6 9,-18 0,-26 C-9,-18 -8,-6 0,0 Z"/>
              </defs>
              <rect width="400" height="250" fill="url(#sky)"/>
              <circle class="zc-wash" cx="172" cy="118" r="140" fill="url(#wash)"/>

              <!-- sole/luna disegnati a china, coerenti con il resto della scena -->
              <g class="scn-day">
                <circle cx="340" cy="46" r="14" fill="none" stroke="var(--scn-ink)" stroke-width="1.6" opacity=".7"/>
                <g stroke="var(--scn-ink)" stroke-width="1.6" stroke-linecap="round" opacity=".7">
                  <line x1="340" y1="24" x2="340" y2="18"/><line x1="340" y1="74" x2="340" y2="68"/>
                  <line x1="312" y1="46" x2="306" y2="46"/><line x1="374" y1="46" x2="368" y2="46"/>
                  <line x1="319" y1="25" x2="315" y2="21"/><line x1="361" y1="67" x2="365" y2="71"/>
                  <line x1="361" y1="25" x2="365" y2="21"/><line x1="319" y1="67" x2="315" y2="71"/>
                </g>
              </g>
              <g class="scn-night">
                <path d="M330 30 A18 18 0 1 0 330 66 A13 13 0 1 1 330 30 Z" style="fill:var(--scn-ink)" opacity=".8"/>
                <circle class="zc-twinkle" cx="70" cy="30" r="1.6" style="fill:var(--scn-ink); animation-duration:2.4s"/>
                <circle class="zc-twinkle" cx="120" cy="55" r="1.3" style="fill:var(--scn-ink); animation-duration:3.1s"/>
                <circle class="zc-twinkle" cx="270" cy="24" r="1.5" style="fill:var(--scn-ink); animation-duration:2.8s"/>
                <circle class="zc-twinkle" cx="230" cy="70" r="1.2" style="fill:var(--scn-ink); animation-duration:3.6s"/>
                <circle class="zc-twinkle" cx="40" cy="90" r="1.4" style="fill:var(--scn-ink); animation-duration:2.2s"/>
              </g>

              <!-- aiuola per stagione: due specie di fiore ciascuna + due cespugli, sulla stessa fascia di terreno -->
              <g class="szn szn-primavera">
                <rect x="0" y="208" width="400" height="42" style="fill:var(--sage-dark)" opacity=".38"/>
                <g transform="translate(29,65) scale(.42)">
            <g transform="translate(110,406) scale(0.62) translate(-108,-406)">
              <use href="#bushShape" fill="#eef7ec" transform="translate(108,320) scale(1.6) translate(-184,-146)"/>
              <use href="#bushShape" style="fill:var(--sage)" opacity=".5" transform="translate(90,350) scale(.85) translate(-184,-146)"/>
            </g>

            <g transform="translate(470,406) scale(1.4) translate(-108,-406)">
              <use href="#bushShape" style="fill:var(--sage)" transform="translate(108,320) scale(1.6) translate(-184,-146)"/>
              <use href="#bushShape" fill="#2a3d33" opacity=".5" transform="translate(90,350) scale(.85) translate(-184,-146)"/>
            </g>

            <g transform="translate(39.2,401.6) rotate(5.9) scale(0.63) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M230,146 C227,123 217,109 207,105 C187,94 181,96 160,107 C149,113 140,129 138,146 C142,165 150,181 161,187 C182,198 187,197 208,185 C217,181 227,167 230,146 Z" style="fill:var(--gold)"/>
              <path d="M230,146 C227,123 217,109 207,105 C187,94 181,96 160,107 C149,113 140,129 138,146 C142,165 150,181 161,187 C182,198 187,197 208,185 C217,181 227,167 230,146 Z" style="fill:var(--gold-dark)" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <g transform="translate(109.5,402.3) rotate(-9.2) scale(0.94) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(-55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M184,85 C201,89 213,99 211,106 C222,119 224,136 219,146 C222,161 213,173 204,181 C197,191 189,196 183,195 C177,196 169,190 162,181 C153,173 144,161 147,146 C143,136 145,119 156,106 C153,98 167,88 184,85 Z" style="fill:var(--rose)"/>
              <path d="M184,85 C201,89 213,99 211,106 C222,119 224,136 219,146 C222,161 213,173 204,181 C197,191 189,196 183,195 C177,196 169,190 162,181 C153,173 144,161 147,146 C143,136 145,119 156,106 C153,98 167,88 184,85 Z" style="fill:var(--rose-dark)" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <g transform="translate(314.4,400.0) rotate(3.2) scale(0.76) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M230,146 C227,123 217,109 207,105 C187,94 181,96 160,107 C149,113 140,129 138,146 C142,165 150,181 161,187 C182,198 187,197 208,185 C217,181 227,167 230,146 Z" style="fill:var(--gold)"/>
              <path d="M230,146 C227,123 217,109 207,105 C187,94 181,96 160,107 C149,113 140,129 138,146 C142,165 150,181 161,187 C182,198 187,197 208,185 C217,181 227,167 230,146 Z" style="fill:var(--gold-dark)" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <g transform="translate(520.2,394.0) rotate(-5.8) scale(0.92) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(-55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M184,85 C201,89 213,99 211,106 C222,119 224,136 219,146 C222,161 213,173 204,181 C197,191 189,196 183,195 C177,196 169,190 162,181 C153,173 144,161 147,146 C143,136 145,119 156,106 C153,98 167,88 184,85 Z" style="fill:var(--rose)"/>
              <path d="M184,85 C201,89 213,99 211,106 C222,119 224,136 219,146 C222,161 213,173 204,181 C197,191 189,196 183,195 C177,196 169,190 162,181 C153,173 144,161 147,146 C143,136 145,119 156,106 C153,98 167,88 184,85 Z" style="fill:var(--rose-dark)" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <path class="ink-trace" pathLength="1" style="animation-delay:0.35s;animation-duration:.22s" d="M585,400 Q552.6,414.0 520.2,394.0"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:0.57s" transform="translate(520.2,394.0) rotate(-5.8) scale(0.92) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:0.97s" transform="translate(520.2,394.0) rotate(-5.8) scale(0.92) translate(-155,-428)" d="M184,85 C201,89 213,99 211,106 C222,119 224,136 219,146 C222,161 213,173 204,181 C197,191 189,196 183,195 C177,196 169,190 162,181 C153,173 144,161 147,146 C143,136 145,119 156,106 C153,98 167,88 184,85 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:1.37s;animation-duration:.22s" d="M520.2,394.0 Q495.1,420.0 470,406"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:1.59s" transform="translate(470,406) scale(1.4) translate(-108,-406) translate(108,320) scale(1.6) translate(-184,-146)" d="M246,150 C245,127 229,117 213,112 C201,99 187,93 171,97 C151,98 137,109 131,126 C125,144 131,161 138,171 C147,187 163,191 173,195 C193,197 211,197 223,196 C237,191 249,171 246,150 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:1.99s;animation-duration:.22s" d="M470,406 Q392.2,420.0 314.4,400.0"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:2.21s" transform="translate(314.4,400.0) rotate(3.2) scale(0.76) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:2.61s" transform="translate(314.4,400.0) rotate(3.2) scale(0.76) translate(-155,-428)" d="M230,146 C227,123 217,109 207,105 C187,94 181,96 160,107 C149,113 140,129 138,146 C142,165 150,181 161,187 C182,198 187,197 208,185 C217,181 227,167 230,146 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.01s;animation-duration:.22s" d="M314.4,400.0 Q212.2,420.0 110,406"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.23s" transform="translate(110,406) scale(0.62) translate(-108,-406) translate(108,320) scale(1.6) translate(-184,-146)" d="M246,150 C245,127 229,117 213,112 C201,99 187,93 171,97 C151,98 137,109 131,126 C125,144 131,161 138,171 C147,187 163,191 173,195 C193,197 211,197 223,196 C237,191 249,171 246,150 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.63s;animation-duration:.22s" d="M110,406 Q109.8,420.0 109.5,402.3"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.85s" transform="translate(109.5,402.3) rotate(-9.2) scale(0.94) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:4.25s" transform="translate(109.5,402.3) rotate(-9.2) scale(0.94) translate(-155,-428)" d="M184,85 C201,89 213,99 211,106 C222,119 224,136 219,146 C222,161 213,173 204,181 C197,191 189,196 183,195 C177,196 169,190 162,181 C153,173 144,161 147,146 C143,136 145,119 156,106 C153,98 167,88 184,85 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:4.65s;animation-duration:.22s" d="M109.5,402.3 Q74.3,416.3 39.2,401.6"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:4.87s" transform="translate(39.2,401.6) rotate(5.9) scale(0.63) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:5.27s" transform="translate(39.2,401.6) rotate(5.9) scale(0.63) translate(-155,-428)" d="M230,146 C227,123 217,109 207,105 C187,94 181,96 160,107 C149,113 140,129 138,146 C142,165 150,181 161,187 C182,198 187,197 208,185 C217,181 227,167 230,146 Z"/>
                </g>
              </g>

              <g class="szn szn-estate">
                <rect x="0" y="208" width="400" height="42" fill="#3a4a1f" opacity=".38"/>
                <g transform="translate(29,65) scale(.42)">
            <g transform="translate(110,406) scale(0.62) translate(-108,-406)">
              <use href="#bushShape" style="fill:var(--sage)" transform="translate(108,320) scale(1.6) translate(-184,-146)"/>
              <use href="#bushShape" fill="#3a4a1f" opacity=".5" transform="translate(90,350) scale(.85) translate(-184,-146)"/>
            </g>

            <g transform="translate(470,406) scale(1.4) translate(-108,-406)">
              <use href="#bushShape" fill="#3a4a1f" transform="translate(108,320) scale(1.6) translate(-184,-146)"/>
              <use href="#bushShape" fill="#2a3d33" opacity=".5" transform="translate(90,350) scale(.85) translate(-184,-146)"/>
            </g>

            <g transform="translate(39.2,401.6) rotate(5.9) scale(0.63) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M184,88 C191,88 193,99 187,113 C205,101 219,103 224,113 C231,123 224,133 209,136 C227,141 234,151 230,161 C226,171 211,169 199,158 C204,175 199,187 189,189 C179,191 173,178 176,161 C165,174 153,177 145,168 C137,160 143,148 158,142 C143,138 133,127 137,115 C142,103 156,103 168,113 C167,97 173,88 184,88 Z" style="fill:var(--gold)"/>
              <path d="M184,88 C191,88 193,99 187,113 C205,101 219,103 224,113 C231,123 224,133 209,136 C227,141 234,151 230,161 C226,171 211,169 199,158 C204,175 199,187 189,189 C179,191 173,178 176,161 C165,174 153,177 145,168 C137,160 143,148 158,142 C143,138 133,127 137,115 C142,103 156,103 168,113 C167,97 173,88 184,88 Z" style="fill:var(--gold-dark)" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <g transform="translate(109.5,402.3) rotate(-9.2) scale(0.94) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(-55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M236,146 C231,129 220,122 211,117 C199,103 190,95 184,93 C177,95 169,103 155,118 C143,124 136,133 132,146 C136,157 145,169 156,175 C169,187 177,195 184,199 C193,194 200,186 213,173 C225,168 233,158 236,146 Z" style="fill:var(--rose)"/>
              <path d="M236,146 C231,129 220,122 211,117 C199,103 190,95 184,93 C177,95 169,103 155,118 C143,124 136,133 132,146 C136,157 145,169 156,175 C169,187 177,195 184,199 C193,194 200,186 213,173 C225,168 233,158 236,146 Z" style="fill:var(--rose-dark)" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <g transform="translate(314.4,400.0) rotate(3.2) scale(0.76) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M184,88 C191,88 193,99 187,113 C205,101 219,103 224,113 C231,123 224,133 209,136 C227,141 234,151 230,161 C226,171 211,169 199,158 C204,175 199,187 189,189 C179,191 173,178 176,161 C165,174 153,177 145,168 C137,160 143,148 158,142 C143,138 133,127 137,115 C142,103 156,103 168,113 C167,97 173,88 184,88 Z" style="fill:var(--gold)"/>
              <path d="M184,88 C191,88 193,99 187,113 C205,101 219,103 224,113 C231,123 224,133 209,136 C227,141 234,151 230,161 C226,171 211,169 199,158 C204,175 199,187 189,189 C179,191 173,178 176,161 C165,174 153,177 145,168 C137,160 143,148 158,142 C143,138 133,127 137,115 C142,103 156,103 168,113 C167,97 173,88 184,88 Z" style="fill:var(--gold-dark)" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <g transform="translate(520.2,394.0) rotate(-5.8) scale(0.92) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(-55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M236,146 C231,129 220,122 211,117 C199,103 190,95 184,93 C177,95 169,103 155,118 C143,124 136,133 132,146 C136,157 145,169 156,175 C169,187 177,195 184,199 C193,194 200,186 213,173 C225,168 233,158 236,146 Z" style="fill:var(--rose)"/>
              <path d="M236,146 C231,129 220,122 211,117 C199,103 190,95 184,93 C177,95 169,103 155,118 C143,124 136,133 132,146 C136,157 145,169 156,175 C169,187 177,195 184,199 C193,194 200,186 213,173 C225,168 233,158 236,146 Z" style="fill:var(--rose-dark)" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <path class="ink-trace" pathLength="1" style="animation-delay:0.35s;animation-duration:.22s" d="M585,400 Q552.6,414.0 520.2,394.0"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:0.57s" transform="translate(520.2,394.0) rotate(-5.8) scale(0.92) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:0.97s" transform="translate(520.2,394.0) rotate(-5.8) scale(0.92) translate(-155,-428)" d="M236,146 C231,129 220,122 211,117 C199,103 190,95 184,93 C177,95 169,103 155,118 C143,124 136,133 132,146 C136,157 145,169 156,175 C169,187 177,195 184,199 C193,194 200,186 213,173 C225,168 233,158 236,146 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:1.37s;animation-duration:.22s" d="M520.2,394.0 Q495.1,420.0 470,406"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:1.59s" transform="translate(470,406) scale(1.4) translate(-108,-406) translate(108,320) scale(1.6) translate(-184,-146)" d="M246,150 C245,127 229,117 213,112 C201,99 187,93 171,97 C151,98 137,109 131,126 C125,144 131,161 138,171 C147,187 163,191 173,195 C193,197 211,197 223,196 C237,191 249,171 246,150 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:1.99s;animation-duration:.22s" d="M470,406 Q392.2,420.0 314.4,400.0"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:2.21s" transform="translate(314.4,400.0) rotate(3.2) scale(0.76) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:2.61s" transform="translate(314.4,400.0) rotate(3.2) scale(0.76) translate(-155,-428)" d="M184,88 C191,88 193,99 187,113 C205,101 219,103 224,113 C231,123 224,133 209,136 C227,141 234,151 230,161 C226,171 211,169 199,158 C204,175 199,187 189,189 C179,191 173,178 176,161 C165,174 153,177 145,168 C137,160 143,148 158,142 C143,138 133,127 137,115 C142,103 156,103 168,113 C167,97 173,88 184,88 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.01s;animation-duration:.22s" d="M314.4,400.0 Q212.2,420.0 110,406"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.23s" transform="translate(110,406) scale(0.62) translate(-108,-406) translate(108,320) scale(1.6) translate(-184,-146)" d="M246,150 C245,127 229,117 213,112 C201,99 187,93 171,97 C151,98 137,109 131,126 C125,144 131,161 138,171 C147,187 163,191 173,195 C193,197 211,197 223,196 C237,191 249,171 246,150 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.63s;animation-duration:.22s" d="M110,406 Q109.8,420.0 109.5,402.3"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.85s" transform="translate(109.5,402.3) rotate(-9.2) scale(0.94) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:4.25s" transform="translate(109.5,402.3) rotate(-9.2) scale(0.94) translate(-155,-428)" d="M236,146 C231,129 220,122 211,117 C199,103 190,95 184,93 C177,95 169,103 155,118 C143,124 136,133 132,146 C136,157 145,169 156,175 C169,187 177,195 184,199 C193,194 200,186 213,173 C225,168 233,158 236,146 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:4.65s;animation-duration:.22s" d="M109.5,402.3 Q74.3,416.3 39.2,401.6"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:4.87s" transform="translate(39.2,401.6) rotate(5.9) scale(0.63) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:5.27s" transform="translate(39.2,401.6) rotate(5.9) scale(0.63) translate(-155,-428)" d="M184,88 C191,88 193,99 187,113 C205,101 219,103 224,113 C231,123 224,133 209,136 C227,141 234,151 230,161 C226,171 211,169 199,158 C204,175 199,187 189,189 C179,191 173,178 176,161 C165,174 153,177 145,168 C137,160 143,148 158,142 C143,138 133,127 137,115 C142,103 156,103 168,113 C167,97 173,88 184,88 Z"/>
                </g>
              </g>

              <g class="szn szn-autunno">
                <rect x="0" y="208" width="400" height="42" fill="#3f5a46" opacity=".38"/>
                <g transform="translate(29,65) scale(.42)">
            <g transform="translate(110,406) scale(0.62) translate(-108,-406)">
              <use href="#bushShape" fill="#eef3ea" transform="translate(108,320) scale(1.6) translate(-184,-146)"/>
              <use href="#bushShape" fill="#3f5a46" opacity=".5" transform="translate(90,350) scale(.85) translate(-184,-146)"/>
            </g>

            <g transform="translate(470,406) scale(1.4) translate(-108,-406)">
              <use href="#bushShape" fill="#3f5a46" transform="translate(108,320) scale(1.6) translate(-184,-146)"/>
              <use href="#bushShape" fill="#2a3d33" opacity=".5" transform="translate(90,350) scale(.85) translate(-184,-146)"/>
            </g>

            <g transform="translate(39.2,401.6) rotate(5.9) scale(0.63) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M184,86 C196,86 195,105 186,120 C207,110 224,114 227,127 C230,140 213,146 195,144 C211,155 220,171 212,181 C204,191 190,178 182,161 C179,181 168,196 155,192 C143,188 147,169 159,155 C141,161 122,159 120,146 C118,133 137,130 155,135 C142,122 135,105 145,94 C155,84 168,101 174,120 C176,102 178,86 184,86 Z" fill="#a34848"/>
              <path d="M184,86 C196,86 195,105 186,120 C207,110 224,114 227,127 C230,140 213,146 195,144 C211,155 220,171 212,181 C204,191 190,178 182,161 C179,181 168,196 155,192 C143,188 147,169 159,155 C141,161 122,159 120,146 C118,133 137,130 155,135 C142,122 135,105 145,94 C155,84 168,101 174,120 C176,102 178,86 184,86 Z" fill="#7a3230" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <g transform="translate(109.5,402.3) rotate(-9.2) scale(0.94) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(-55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M232,146 C228,132 224,124 220,120 C212,106 204,101 198,101 C184,95 184,95 170,101 C164,101 156,106 148,120 C144,124 140,132 140,146 C140,160 144,168 148,172 C156,186 164,191 170,191 C184,197 184,197 198,191 C204,191 212,186 220,172 C224,168 228,160 232,146 Z" style="fill:var(--gold-dark)"/>
              <path d="M232,146 C228,132 224,124 220,120 C212,106 204,101 198,101 C184,95 184,95 170,101 C164,101 156,106 148,120 C144,124 140,132 140,146 C140,160 144,168 148,172 C156,186 164,191 170,191 C184,197 184,197 198,191 C204,191 212,186 220,172 C224,168 228,160 232,146 Z" fill="#8a6a1f" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <g transform="translate(314.4,400.0) rotate(3.2) scale(0.76) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M184,86 C196,86 195,105 186,120 C207,110 224,114 227,127 C230,140 213,146 195,144 C211,155 220,171 212,181 C204,191 190,178 182,161 C179,181 168,196 155,192 C143,188 147,169 159,155 C141,161 122,159 120,146 C118,133 137,130 155,135 C142,122 135,105 145,94 C155,84 168,101 174,120 C176,102 178,86 184,86 Z" fill="#a34848"/>
              <path d="M184,86 C196,86 195,105 186,120 C207,110 224,114 227,127 C230,140 213,146 195,144 C211,155 220,171 212,181 C204,191 190,178 182,161 C179,181 168,196 155,192 C143,188 147,169 159,155 C141,161 122,159 120,146 C118,133 137,130 155,135 C142,122 135,105 145,94 C155,84 168,101 174,120 C176,102 178,86 184,86 Z" fill="#7a3230" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <g transform="translate(520.2,394.0) rotate(-5.8) scale(0.92) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(-55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M232,146 C228,132 224,124 220,120 C212,106 204,101 198,101 C184,95 184,95 170,101 C164,101 156,106 148,120 C144,124 140,132 140,146 C140,160 144,168 148,172 C156,186 164,191 170,191 C184,197 184,197 198,191 C204,191 212,186 220,172 C224,168 228,160 232,146 Z" style="fill:var(--gold-dark)"/>
              <path d="M232,146 C228,132 224,124 220,120 C212,106 204,101 198,101 C184,95 184,95 170,101 C164,101 156,106 148,120 C144,124 140,132 140,146 C140,160 144,168 148,172 C156,186 164,191 170,191 C184,197 184,197 198,191 C204,191 212,186 220,172 C224,168 228,160 232,146 Z" fill="#8a6a1f" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <path class="ink-trace" pathLength="1" style="animation-delay:0.35s;animation-duration:.22s" d="M585,400 Q552.6,414.0 520.2,394.0"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:0.57s" transform="translate(520.2,394.0) rotate(-5.8) scale(0.92) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:0.97s" transform="translate(520.2,394.0) rotate(-5.8) scale(0.92) translate(-155,-428)" d="M232,146 C228,132 224,124 220,120 C212,106 204,101 198,101 C184,95 184,95 170,101 C164,101 156,106 148,120 C144,124 140,132 140,146 C140,160 144,168 148,172 C156,186 164,191 170,191 C184,197 184,197 198,191 C204,191 212,186 220,172 C224,168 228,160 232,146 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:1.37s;animation-duration:.22s" d="M520.2,394.0 Q495.1,420.0 470,406"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:1.59s" transform="translate(470,406) scale(1.4) translate(-108,-406) translate(108,320) scale(1.6) translate(-184,-146)" d="M246,150 C245,127 229,117 213,112 C201,99 187,93 171,97 C151,98 137,109 131,126 C125,144 131,161 138,171 C147,187 163,191 173,195 C193,197 211,197 223,196 C237,191 249,171 246,150 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:1.99s;animation-duration:.22s" d="M470,406 Q392.2,420.0 314.4,400.0"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:2.21s" transform="translate(314.4,400.0) rotate(3.2) scale(0.76) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:2.61s" transform="translate(314.4,400.0) rotate(3.2) scale(0.76) translate(-155,-428)" d="M184,86 C196,86 195,105 186,120 C207,110 224,114 227,127 C230,140 213,146 195,144 C211,155 220,171 212,181 C204,191 190,178 182,161 C179,181 168,196 155,192 C143,188 147,169 159,155 C141,161 122,159 120,146 C118,133 137,130 155,135 C142,122 135,105 145,94 C155,84 168,101 174,120 C176,102 178,86 184,86 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.01s;animation-duration:.22s" d="M314.4,400.0 Q212.2,420.0 110,406"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.23s" transform="translate(110,406) scale(0.62) translate(-108,-406) translate(108,320) scale(1.6) translate(-184,-146)" d="M246,150 C245,127 229,117 213,112 C201,99 187,93 171,97 C151,98 137,109 131,126 C125,144 131,161 138,171 C147,187 163,191 173,195 C193,197 211,197 223,196 C237,191 249,171 246,150 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.63s;animation-duration:.22s" d="M110,406 Q109.8,420.0 109.5,402.3"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.85s" transform="translate(109.5,402.3) rotate(-9.2) scale(0.94) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:4.25s" transform="translate(109.5,402.3) rotate(-9.2) scale(0.94) translate(-155,-428)" d="M232,146 C228,132 224,124 220,120 C212,106 204,101 198,101 C184,95 184,95 170,101 C164,101 156,106 148,120 C144,124 140,132 140,146 C140,160 144,168 148,172 C156,186 164,191 170,191 C184,197 184,197 198,191 C204,191 212,186 220,172 C224,168 228,160 232,146 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:4.65s;animation-duration:.22s" d="M109.5,402.3 Q74.3,416.3 39.2,401.6"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:4.87s" transform="translate(39.2,401.6) rotate(5.9) scale(0.63) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:5.27s" transform="translate(39.2,401.6) rotate(5.9) scale(0.63) translate(-155,-428)" d="M184,86 C196,86 195,105 186,120 C207,110 224,114 227,127 C230,140 213,146 195,144 C211,155 220,171 212,181 C204,191 190,178 182,161 C179,181 168,196 155,192 C143,188 147,169 159,155 C141,161 122,159 120,146 C118,133 137,130 155,135 C142,122 135,105 145,94 C155,84 168,101 174,120 C176,102 178,86 184,86 Z"/>
                </g>
              </g>

              <g class="szn szn-inverno">
                <rect x="0" y="208" width="400" height="42" fill="#3a4540" opacity=".38"/>
                <g transform="translate(29,65) scale(.42)">
            <g transform="translate(110,406) scale(0.62) translate(-108,-406)">
              <use href="#bushShape" fill="#eef2f0" transform="translate(108,320) scale(1.6) translate(-184,-146)"/>
              <use href="#bushShape" fill="#3a4540" opacity=".5" transform="translate(90,350) scale(.85) translate(-184,-146)"/>
            </g>

            <g transform="translate(470,406) scale(1.4) translate(-108,-406)">
              <use href="#bushShape" fill="#3a4540" transform="translate(108,320) scale(1.6) translate(-184,-146)"/>
              <use href="#bushShape" fill="#2a3d33" opacity=".5" transform="translate(90,350) scale(.85) translate(-184,-146)"/>
            </g>

            <g transform="translate(39.2,401.6) rotate(5.9) scale(0.63) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M236,146 C232,168 217,186 200,195 C176,204 164,196 152,178 C142,162 142,130 152,114 C164,96 176,88 200,97 C216,106 232,124 236,146 Z" fill="#efe9d6"/>
              <path d="M236,146 C232,168 217,186 200,195 C176,204 164,196 152,178 C142,162 142,130 152,114 C164,96 176,88 200,97 C216,106 232,124 236,146 Z" fill="#c7bd98" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <g transform="translate(109.5,402.3) rotate(-9.2) scale(0.94) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(-55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M184,195 C169,181 159,161 161,139 C163,117 177,98 184,88 C190,98 179,116 182,132 C187,116 201,100 211,95 C217,110 201,128 195,140 C211,130 225,120 233,110 C237,124 221,140 207,148 C219,150 229,156 233,166 C223,172 207,168 195,158 C197,172 191,186 184,195 Z" style="fill:var(--rose)"/>
              <path d="M184,195 C169,181 159,161 161,139 C163,117 177,98 184,88 C190,98 179,116 182,132 C187,116 201,100 211,95 C217,110 201,128 195,140 C211,130 225,120 233,110 C237,124 221,140 207,148 C219,150 229,156 233,166 C223,172 207,168 195,158 C197,172 191,186 184,195 Z" style="fill:var(--rose-dark)" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <g transform="translate(314.4,400.0) rotate(3.2) scale(0.76) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M236,146 C232,168 217,186 200,195 C176,204 164,196 152,178 C142,162 142,130 152,114 C164,96 176,88 200,97 C216,106 232,124 236,146 Z" fill="#efe9d6"/>
              <path d="M236,146 C232,168 217,186 200,195 C176,204 164,196 152,178 C142,162 142,130 152,114 C164,96 176,88 200,97 C216,106 232,124 236,146 Z" fill="#c7bd98" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <g transform="translate(520.2,394.0) rotate(-5.8) scale(0.92) translate(-155,-428)">
              <use href="#stemShape" style="fill:var(--olive)"/>
              <use href="#stemShape" style="fill:var(--olive-dark)" opacity=".55" transform="translate(168,300) scale(.34,.86) translate(-262,-300)"/>
              <g transform="translate(162,278) rotate(-55) scale(1.3)"><use href="#leafShape" style="fill:var(--sage)"/></g>
              <path d="M184,195 C169,181 159,161 161,139 C163,117 177,98 184,88 C190,98 179,116 182,132 C187,116 201,100 211,95 C217,110 201,128 195,140 C211,130 225,120 233,110 C237,124 221,140 207,148 C219,150 229,156 233,166 C223,172 207,168 195,158 C197,172 191,186 184,195 Z" style="fill:var(--rose)"/>
              <path d="M184,195 C169,181 159,161 161,139 C163,117 177,98 184,88 C190,98 179,116 182,132 C187,116 201,100 211,95 C217,110 201,128 195,140 C211,130 225,120 233,110 C237,124 221,140 207,148 C219,150 229,156 233,166 C223,172 207,168 195,158 C197,172 191,186 184,195 Z" style="fill:var(--rose-dark)" opacity=".5" transform="translate(184,146) scale(.55) translate(-140,-100)"/>
            </g>

            <path class="ink-trace" pathLength="1" style="animation-delay:0.35s;animation-duration:.22s" d="M585,400 Q552.6,414.0 520.2,394.0"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:0.57s" transform="translate(520.2,394.0) rotate(-5.8) scale(0.92) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:0.97s" transform="translate(520.2,394.0) rotate(-5.8) scale(0.92) translate(-155,-428)" d="M184,195 C169,181 159,161 161,139 C163,117 177,98 184,88 C190,98 179,116 182,132 C187,116 201,100 211,95 C217,110 201,128 195,140 C211,130 225,120 233,110 C237,124 221,140 207,148 C219,150 229,156 233,166 C223,172 207,168 195,158 C197,172 191,186 184,195 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:1.37s;animation-duration:.22s" d="M520.2,394.0 Q495.1,420.0 470,406"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:1.59s" transform="translate(470,406) scale(1.4) translate(-108,-406) translate(108,320) scale(1.6) translate(-184,-146)" d="M246,150 C245,127 229,117 213,112 C201,99 187,93 171,97 C151,98 137,109 131,126 C125,144 131,161 138,171 C147,187 163,191 173,195 C193,197 211,197 223,196 C237,191 249,171 246,150 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:1.99s;animation-duration:.22s" d="M470,406 Q392.2,420.0 314.4,400.0"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:2.21s" transform="translate(314.4,400.0) rotate(3.2) scale(0.76) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:2.61s" transform="translate(314.4,400.0) rotate(3.2) scale(0.76) translate(-155,-428)" d="M236,146 C232,168 217,186 200,195 C176,204 164,196 152,178 C142,162 142,130 152,114 C164,96 176,88 200,97 C216,106 232,124 236,146 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.01s;animation-duration:.22s" d="M314.4,400.0 Q212.2,420.0 110,406"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.23s" transform="translate(110,406) scale(0.62) translate(-108,-406) translate(108,320) scale(1.6) translate(-184,-146)" d="M246,150 C245,127 229,117 213,112 C201,99 187,93 171,97 C151,98 137,109 131,126 C125,144 131,161 138,171 C147,187 163,191 173,195 C193,197 211,197 223,196 C237,191 249,171 246,150 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.63s;animation-duration:.22s" d="M110,406 Q109.8,420.0 109.5,402.3"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:3.85s" transform="translate(109.5,402.3) rotate(-9.2) scale(0.94) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:4.25s" transform="translate(109.5,402.3) rotate(-9.2) scale(0.94) translate(-155,-428)" d="M184,195 C169,181 159,161 161,139 C163,117 177,98 184,88 C190,98 179,116 182,132 C187,116 201,100 211,95 C217,110 201,128 195,140 C211,130 225,120 233,110 C237,124 221,140 207,148 C219,150 229,156 233,166 C223,172 207,168 195,158 C197,172 191,186 184,195 Z"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:4.65s;animation-duration:.22s" d="M109.5,402.3 Q74.3,416.3 39.2,401.6"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:4.87s" transform="translate(39.2,401.6) rotate(5.9) scale(0.63) translate(-155,-428)" d="M150,428 C137,390 145,354 151,317 C163,277 170,234 181,195 C182,184 187,170 189,159"/>

            <path class="ink-trace" pathLength="1" style="animation-delay:5.27s" transform="translate(39.2,401.6) rotate(5.9) scale(0.63) translate(-155,-428)" d="M236,146 C232,168 217,186 200,195 C176,204 164,196 152,178 C142,162 142,130 152,114 C164,96 176,88 200,97 C216,106 232,124 236,146 Z"/>
                </g>
              </g>

              <rect width="400" height="250" filter="url(#grain)" opacity=".05" style="mix-blend-mode:overlay" pointer-events="none"/>
            </svg>
</template>

<script setup>
import { ref, onMounted } from 'vue'

// stagione: 'primavera' | 'estate' | 'autunno' | 'inverno'
// luce: 'giorno' | 'notte'
defineProps({
  stagione: { type: String, required: true },
  luce: { type: String, required: true },
})

// Colori e Zorba sono già tutti presenti al primo istante (vedi HomeView.vue);
// la matita a china parte poco dopo il mount e ripassa la scena una sola
// volta, senza loop — coerente con come si comporta il resto dell'app.
const animare = ref(false)
onMounted(() => {
  requestAnimationFrame(() => { animare.value = true })
})
</script>

<style scoped>
.zc-scene { display:block; width:100%; height:100%; }

.zc-scene {
  --scn-sky-a: var(--cream-dark); --scn-sky-b: var(--gold-tile);
  --scn-wash: var(--gold-tile); --scn-ink: var(--ink-mid);
}
.zc-scene[data-light="notte"] {
  --scn-sky-a:#16211d; --scn-sky-b:#243a37; --scn-wash:#2b423d; --scn-ink:#e9dfca;
}

.scn-day, .scn-night { display:none; }
.zc-scene[data-light="giorno"] .scn-day { display:block; }
.zc-scene[data-light="notte"] .scn-night { display:block; }

.szn { display:none; }
.zc-scene[data-season="primavera"] .szn-primavera { display:block; }
.zc-scene[data-season="estate"] .szn-estate { display:block; }
.zc-scene[data-season="autunno"] .szn-autunno { display:block; }
.zc-scene[data-season="inverno"] .szn-inverno { display:block; }

.zc-wash { opacity:.5; }
.zc-twinkle { animation:zc-twinkle ease-in-out infinite alternate; }
@keyframes zc-twinkle { 0%{opacity:.25;} 100%{opacity:.95;} }

/* la matita che ripassa l'intera scena: colori e Zorba già presenti da
   subito, un solo tratto sottile color inchiostro (mai colorato) la
   disegna per intero, in un percorso continuo. */
.ink-trace {
  fill:none; stroke:var(--scn-ink); stroke-width:1.6;
  stroke-linecap:round; stroke-linejoin:round;
  stroke-dasharray:1; stroke-dashoffset:1;
  animation-duration:.4s; animation-timing-function:linear; animation-fill-mode:forwards;
}
.zc-scene.play .ink-trace { animation-name:ink-draw; }
@keyframes ink-draw { to { stroke-dashoffset:0; } }

@media (prefers-reduced-motion: reduce) {
  .ink-trace, .zc-twinkle { animation:none !important; }
  .ink-trace { stroke-dashoffset:0; }
}
</style>
