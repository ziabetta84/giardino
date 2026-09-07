---
target: HomeView (src/views/HomeView.vue)
total_score: 34
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 0
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/HomeView.vue"
target_fingerprint: "sha256:a5cd396ce810058bae6da44e60d9e53b90fb0e44d6d15c1baa35840731be8ef5"
target_path: /Users/rob/Sites/localhost/giardino/src/views/HomeView.vue
timestamp: 2026-09-07T04-12-45Z
slug: src-views-homeview-vue
---
# Critique: `src/views/HomeView.vue` (third pass, after two rounds of fixes)

Method: dual-agent (A: general-purpose design review · B: general-purpose detector/evidence)

**Environment disclosure:** No browser automation tool is exposed in this session — confirmed independently by both assessments again. Static-analysis-only pass.

## What this run confirms

Assessment B directly verified, line by line, all six specific fixes from round two: `.greet` is a real `<h1>` (line 12); the hero `.stat` block has the loading/error/data three-way branch in order; `.stat b`/`.stat b.urg` correctly split the neutral-vs-rose color with the template applying `:class="{ urg: numUrgenti }"`; task rows use `.care__ic`/`.care__ic--${tipo}` matching `AttivitaRiga.vue` exactly, and bare `.task__ic` is gone from both files; the first-run (`numPiante === 0`) and all-clear (`numPiante > 0 && !daFareOggi.length`) empty states are distinct and mutually exclusive by their compound conditions; and `zorbaDiceSottotitolo` has its own zero-plant branch separate from the all-clear branch. **One small correction to Assessment B's own transcription**: it described the two empty-state blocks as chained with `v-else-if`, but the source actually uses two independent `v-if` conditions (the second is nested inside a `<Transition>` wrapper, so `v-else-if` couldn't reach across it anyway) — mutual exclusivity holds by the compound boolean logic itself (`numPiante === 0` vs. `numPiante > 0`), not by Vue's conditional chaining. Functionally equivalent, just worth naming correctly.

Assessment A's verdict, reached independently: the three-way empty-state split (first-run / task-list / all-clear) is **"coherent, not patched-together"** — all three share the same `.empty` shell, are tonally differentiated on purpose (first-run gets no reward transition, correctly, since an empty garden isn't an achievement), and are backed by matching narration in `zorbaDiceSottotitolo`. It also re-confirmed the rose-for-zero fix is closed everywhere it checked (`.stat b`, both `homeCards` urgency flags), and specifically praised the `daFareOggi` sort/`-1e15` sentinel again as "genuinely careful" engineering that "survived three rounds cleanly."

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|---|---|---|
| 1 | Visibility of System Status | 3 | Hero `.stat` row still renders "0 piante · 0 zone · 0 piante da curare" for a first-run user, sitting right above the correctly-built first-run card |
| 2 | Match Between System and Real World | 4 | Rain-aware irrigation logic, per-domain care language, idiomatic Italian throughout |
| 3 | User Control and Freedom | 3 | Inline "Fatto" + retry are good; no undo visible from Home itself beyond the toast |
| 4 | Consistency and Standards | 3 | `.care__ic--calcio` renders neutral gray instead of the spec'd "uovo" domain tint (no `--uovo-bg`/`--uovo-ink` tokens exist at all); `.seeall` is the one row that didn't get the `:focus-visible` pass its siblings got |
| 5 | Error Prevention | 3 | `salvando` guard still solid; a shared-store re-entrancy guard (`caricaTutto()`) is a latent, unconfirmed race — see below |
| 6 | Recognition Rather Than Recall | 4 | Icon + label + relative-time on every row |
| 7 | Flexibility and Efficiency of Use | 4 | Inline actions, escape hatch past 5 items, direct links everywhere |
| 8 | Aesthetic and Minimalist Design | 4 | Restrained, no dashboard clutter |
| 9 | Error Recovery | 3 | Store-level error has a clear retry banner; the inline per-task error has no live-region, unlike the toast's `role="status"` |
| 10 | Help and Documentation | 3 | No inline help, but the domain is simple enough that this stays a minor gap, not a real one — scored numerically rather than n/a, since Home is Operate-mode content, not a marketing surface (correcting Assessment A's n/a here for consistency with this target's own scoring history) |
| **Total** | | **34/40** | **Good** |

*Score moved 28 → 34.* All five targeted fixes from round two land and hold under independent re-review; what's left is real but secondary — no P0/P1 this round, per Assessment A's own explicit statement that it found no evidence to support one.

## Design Specificity Verdict

**LLM assessment:** Unchanged conclusion, reinforced: this could not be dropped into a generic gardening or to-do template without gutting the rain-suppression logic, the "mai registrata" ranking, the per-domain icon tiles, and the season-aware hero. The Italian copy stays idiomatic rather than templated even in the newest first-run string ("Il tuo giardino ti aspetta").

**Deterministic scan:** `impeccable detect --json` on `HomeView.vue`: **0 findings, exit 0** — clean, third run in a row. The same 2 pre-existing advisory `design-system-color` findings persist in `ZorbaLogo.vue`/`ToastCura.vue`, unrelated to any of this session's edits.

**Visual overlays:** Not available — no browser automation tool in this session, third time confirmed.

## Overall Impression

Three rounds in, this file is in good shape. Both assessments independently landed on the same verdict: nothing regressed, the emotional/state system reads as deliberately designed rather than accumulated patches, and the remaining issues are real but secondary — a design-system gap that predates this session (`calcio`'s missing "uovo" color), one row that missed the focus-visible pass, a first-run seam in the one place the earlier round's onboarding work didn't reach (the hero stat pills), and an unconfirmed architectural risk in a shared store method used by eight views, not just this one.

## What's Working

- **The `daFareOggi` sort/`-1e15` sentinel** — independently praised a second time as careful, well-commented engineering that has now survived three review rounds without regressing.
- **Cross-file empty-state parity** — `.giardino-in-ordine`'s timing/easing/transform/reduced-motion fallback is a byte-for-byte match of `AttivitaView.vue`'s `.tab-pulita`, both explicitly commented on why they're duplicated rather than shared. Exactly the "one true milestone moment" system DESIGN.md asks for, correctly generalized to a second view.
- **Rose-for-zero is closed everywhere, not just at the one spot originally flagged**: `.stat b.urg`, and both `homeCards` urgency flags (`!!numUrgenti.value`, `n > 0`) all gate correctly — verified as a thorough fix, not a local patch.

## Priority Issues

**[P2] `.care__ic--calcio` doesn't use the design system's "uovo" domain color — a pre-existing gap, now visible on Home's own task rows**
- **Why it matters**: `main.css:799`: `.care__ic--calcio { background: var(--carta-2); color: var(--ink-mid); }`. Verified — no `--uovo-bg`/`--uovo-ink` tokens exist anywhere in `main.css` (only bare `--uovo`/`--uovo-dark`). A calcio task in Home's "Da fare oggi" renders as flat neutral gray, indistinguishable from "no domain," contradicting "one solid domain color per icon." This predates this session (it was already true before Home's icons were switched to `.care__ic` last round) and is systemic — it also affects Attività/PianteView/DossierPianta, since they share the same class.
- **Fix**: define `--uovo-bg`/`--uovo-ink` alongside the other domain pairs and repoint `.care__ic--calcio` to them.
- **Suggested command**: `/impeccable colorize`

**[P2] `.seeall` never got the `:focus-visible` pass its sibling rows got**
- **Why it matters**: `.wxrow`, `.zdice`, `.dest`, and `.care-act` all have the inset gold-ring `:focus-visible` treatment from the prior accessibility round; `.seeall` (`HomeView.vue:105-107`, the "Vedi tutte le N attività →" link, shown once there are more than 5 urgent items) was missed. A keyboard user tabbing down the page hits consistent gold rings everywhere except the one link that only appears on a busy day — landing on the browser's native outline instead, the exact "corporate-blue" intrusion the brief forbids.
- **Fix**: `.seeall:focus-visible { outline:none; box-shadow: inset 0 0 0 3px var(--gold); }`.
- **Suggested command**: `/impeccable audit`

**[P3] Hero stat row has no first-run branch**
- **Why it matters**: every other surface on this page got a first-run treatment last round (the empty-state card, `zorbaDiceSottotitolo`) except the hero `.stat` pills (`HomeView.vue:22-26`), which still render "0 piante · 0 zone · 0 piante da curare" for a brand-new user — sitting directly above the warm "Il tuo giardino ti aspetta" card. It's the first thing a new user's eye lands on, and it's the one seam left in an otherwise-coherent system.
- **Fix**: suppress or reword the stat row (or drop the "da curare" chip specifically) when `numPiante === 0`.
- **Suggested command**: `/impeccable onboard`

**[P3] Inline task-save error has no live-region — unconfirmed architectural race also flagged, out of Home's scope**
- **Why it matters**: `task__d--err` (`HomeView.vue:98`) has no `aria-live`/`role`, unlike `ToastCura`'s `role="status"`. A screen-reader user whose "Fatto" tap fails gets silence instead of an announcement. Separately (not a confirmed defect, flagging for awareness): `store.caricaTutto()`'s re-entrancy guard (`if (piante.value) return`, `stores/dati.js:255`) checks a value that isn't set until the first call's data resolves, so two callers invoked before either finishes could both pass the guard and each fire a full concurrent load — this is an app-wide pattern shared by eight views (not introduced by or specific to Home), and neither assessment could confirm from static reading alone whether it's actually exercised in practice.
- **Fix**: add `role="alert"` or `aria-live="assertive"` to `.task__d--err`. The `caricaTutto()` question needs a live network-panel check, not a code fix based on static reading alone — noting it, not prescribing a change.
- **Suggested command**: `/impeccable audit`

## Persona Red Flags

**Alex (first-time/onboarding user)**: directly hit by the hero-stat first-run gap (P3 above) — the very first screen after account creation shows three zero-badges before the warm invitation below registers.

**Riley / the one-handed garden persona**: the `.seeall` focus-visible gap (P2) matters for anyone using keyboard/switch/voice-control input outdoors — one inconsistent focus ring reads as "broken" mid-task. The inline-error live-region gap (P3) means a failed save announces nothing to a screen-reader user.

## Minor Observations

- `numUrgenti` (plant count, hero + Piante card) vs. `daFareOggi.length` (task count, Attività card + "Vedi tutte") remain two different numbers describing "how much is wrong" on one screen — disambiguated by wording now, but still worth a note for whoever next touches this area.
- Zorba's confirm blink at mount fires on every remount while all-clear, not once per day as the surrounding comment's "ricompensa quotidiana" framing implies — harmless (it's the deliberately undramatic blink, not the rare one), just a slight overstatement in the comment.
- The four "Da fare oggi" states are four independently re-derived conditions across two template blocks rather than one computed state enum. No actual gap or double-render found, but centralizing into a single `computed(() => 'loading'|'errore'|'lista'|'primo-avvio'|'tutto-ok')` would make the mutual-exclusivity guarantee structural rather than something re-verified by inspection each time a branch is added — worth doing before a fifth state gets added.
- `.task__n` has no truncation/ellipsis handling, unlike `.tappa-riga__t` elsewhere in the app — likely fine (wrapping a long name is more honest than clipping it), just inconsistent with a sibling pattern.

## Questions to Consider

- What if the hero `.stat` row *was* the first-run empty state — collapsing "0 piante · 0 zone" into the same "Il tuo giardino ti aspetta" copy, so the hero itself announces the empty garden instead of leaving that job entirely to the card below it?
- What if `numUrgenti` (plants) and `daFareOggi.length` (tasks) were reconciled into one number used everywhere on this screen — is there a real user need to distinguish "3 plants need something" from "4 things need doing"?
