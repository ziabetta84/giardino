---
target: HomeView (src/views/HomeView.vue)
total_score: 28
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/HomeView.vue"
target_fingerprint: "sha256:1bb2b92eeb06060526da24c8fb59833bebadc870b9b4f3e7ac1e874eddd9e195"
target_path: /Users/rob/Sites/localhost/giardino/src/views/HomeView.vue
timestamp: 2026-09-06T23-05-11Z
slug: src-views-homeview-vue
---
# Critique: `src/views/HomeView.vue` (re-critique after fix pass)

Method: dual-agent (A: general-purpose design review · B: general-purpose detector/evidence)

**Environment disclosure:** No browser automation tool is exposed in this session — confirmed independently by both assessments, same as the first run. This is a static-analysis-only pass.

## What this re-run confirms about the prior fix pass

Assessment B directly verified all four prior source-level fixes are intact and correct: the `.dest`/`.wxrow`/`.zdice`/`.care-act` `:focus-visible` gold rules all exist in `main.css`; `.task__d--err` correctly uses `--rose-ink` (the remaining `--rose-dark` strings in `HomeView.vue` are just the explanatory comment and an unrelated pre-existing dev-only `.hero-debug__label` rule, not a regression); the local `ICONE_CURA`/`icona()` is fully gone in favor of the canonical `iconaCura` import; and the `giardino-in-ordine` transition + its reduced-motion fallback are both present. Assessment A independently confirmed the same things by reading the code and specifically praised two of them: the `rangoUrgenza()` `-1e15` sentinel (avoids a real `NaN`-in-comparator bug when two never-cared-for plants are compared) and the "Regola dei Due Battiti" wiring end-to-end, including the guard that prevents a double-blink when a save empties the list. It also confirmed the icon-glyph fix is closed **app-wide**, not just in this file — `iconaCura()` now renders identically in `HomeView.vue:91`, `ToastCura.vue`, `AttivitaRiga.vue:5`, `PiantaView.vue:76`, and `DossierPianta.vue:12`.

**None of the fixes regressed.** What the fresh review found instead is two new, independently-verified P1s that neither the original critique nor this session's fix passes caught — one pre-existing (the rose-on-zero stat color, which the very first critique flagged only as a Minor Observation) and one a side-effect of the delight pass itself (Home is now the only route in the app without an `<h1>`... actually verified this was always missing, not introduced by this session — see below).

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | Hero stat row (`HomeView.vue:13-24`) has no `store.errore` branch — on load failure it silently renders blank counts instead of an error state, directly above a correct error alertbox |
| 2 | Match Between System and Real World | 4 | Seasonal hero, time-of-day greeting, Italian garden vocabulary throughout — genuinely fluent |
| 3 | User Control and Freedom | 3 | Good undo (`ToastCura`) and retry; no visible cancel during a slow save (minor) |
| 4 | Consistency and Standards | 2 | Icon *glyph* mapping now consistent app-wide (verified), but icon *presentation* (`.task__ic`) still diverges from the shared `.care__ic--${tipo}` tile pattern used by Attività/PiantaView/DossierPianta; two urgency metrics still coexist unlabeled |
| 5 | Error Prevention | 3 | `salvando` guard blocks double-submit |
| 6 | Recognition Rather Than Recall | 3 | Counts and labels reduce recall burden well |
| 7 | Flexibility and Efficiency of Use | 3 | One-tap "Fatto" fits the one-handed-in-the-garden use case; no tap-through from a task row to the plant's fuller record, unlike Attività's equivalent row |
| 8 | Aesthetic and Minimalist Design | 3 | Calm relative to a dashboard; "Il giardino" (6 destinations) is the one dense spot |
| 9 | Error Recovery | 2 | "Da fare oggi"'s own error path is well done; the hero stat row's silent-blank failure (see #1) makes error visibility inconsistent within the same screen |
| 10 | Help and Documentation | 3 | No inline help, but the domain is simple enough that this isn't a real gap here |
| **Total** | | **28/40** | **Good** |

*Score moved 29 → 28.* This is not the fix pass failing — every targeted fix from the last critique verifiably landed and held. It's a fresh independent reviewer surfacing two real defects the first pass didn't catch (one pre-existing, one a genuine gap in the new delight work), which outweigh the heuristic gains from the fixes on a strict re-score.

## Design Specificity Verdict

**LLM assessment:** Still genuinely specific, not swappable. The hand-timed ink-trace choreography in `HeroAiuola.vue`, the two-battito Zorba vocabulary, and — new since last time — the `zorbaDiceSottotitolo` computed that names the actual most-overdue plant instead of a static prompt are all real connective tissue to this product's stated positioning ("the assistant should always feel connected to real data"). Specificity cracks in two places: the task-row icons render as bare silhouettes instead of the app's own "pigment tile" language used everywhere else care icons appear, and the hero stat pill's unconditional rose "0" is a literal violation of the product's own documented color grammar, not a generic-app smell.

**Deterministic scan:** `impeccable detect --json` on `HomeView.vue` alone: **0 findings, exit 0** — clean, same as after the last fix pass. Scanning the imported components found the same 2 pre-existing advisory `design-system-color` findings as before (`ZorbaLogo.vue:248`, `ToastCura.vue:79`) — unchanged, unrelated to this session's edits, still just advisory.

**Visual overlays:** Not available — no browser automation tool in this session.

## Overall Impression

The fix pass held up under independent re-review — nothing regressed, and two of the fixes (the `Infinity`-sentinel sort guard and the Due Battiti wiring) drew specific praise for handling edge cases most quick patches skip. But this is also proof that a single fix pass doesn't exhaust a screen's defects: a fresh pair of eyes found the rose-on-zero color bug (which the *very first* critique actually noticed and correctly filed as a Minor Observation, not a priority — in hindsight it deserved more weight, since it directly undercuts the new "Tutto in ordine!" reward moment sitting right below it) and a missing `<h1>` that turns out to be a real, pre-existing gap on the one screen every login lands on.

## What's Working

- **The "mai registrata" sort fix is genuinely careful** (`useCure.js` + `HomeView.vue:244-246,268`): mapping `Infinity` to `-1e15` instead of leaving it as `-Infinity` avoids a real `NaN`-in-comparator bug when two never-cared-for plants are compared — exactly the kind of edge case most "fixed the sort" patches miss, and it's documented inline.
- **"Regola dei Due Battiti" threaded through correctly end-to-end** (`ZorbaLogo.vue` + `HomeView.vue:150-154,318-330`): the slow "notices" blink and normal "confirms" blink are never confused, and the mount-time all-clear blink is explicitly guarded against double-firing when a save is what emptied the list.
- **The icon-glyph fix is closed app-wide, not just locally**: `iconaCura()` now renders identically across `HomeView.vue`, `ToastCura.vue`, `AttivitaRiga.vue`, `PiantaView.vue`, and `DossierPianta.vue` — verified by directly reading all five call sites.

## Priority Issues

**[P1] Rose color misapplied to a non-urgent (zero) value — undercuts the app's own color grammar and the all-clear moment it sits above**
- **Why it matters**: `.stat b { color:var(--rose-ink); }` (`main.css:543`) applies unconditionally to `HomeView.vue:22`'s `<b>{{ numUrgenti }} piante da curare</b>` — there's no check for `numUrgenti > 0`. DESIGN.md reserves rose strictly for urgent/destructive meaning. A user who just cleared their backlog sees "0 piante da curare" in alarm-red in the hero, then scrolls to a calm "Tutto in ordine!" reward a few hundred pixels later — the page visually contradicts itself in the same visit, and it's the exact scenario the new delight work was built to celebrate.
- **Fix**: apply `--rose-ink` only when `numUrgenti > 0` (e.g. `:class="{ 'stat-urg': numUrgenti > 0 }"`), falling back to `--ink-mid` otherwise.
- **Suggested command**: `/impeccable clarify`

**[P1] Home is the only route in the app without an `<h1>`**
- **Why it matters**: verified directly — `ZoneView.vue:4`, `PianteView.vue:4`, `AttivitaView.vue:3`, `ConcimiView.vue:4`, `ProgettiView.vue:4`, `MeteoView.vue:3`, `GalleryView.vue:4` all have `<h1 class="page-title">`; `HomeView.vue` has only a plain `<div class="greet">` (line 12). A screen-reader user navigating by heading landmarks — a standard assistive-technology pattern — finds no level-1 heading at all on the one screen every login redirects to.
- **Fix**: change `.greet` to a real `<h1>` (it doesn't need to look different, `.greet`'s existing styling can stay): `<h1 class="greet">{{ saluto }}</h1>`.
- **Suggested command**: `/impeccable audit`

**[P1] Hero stat row has no error-state branch — silently shows blank counts on load failure**
- **Why it matters**: `HomeView.vue:14-23` only branches on `store.loading` / else. When `store.errore` is set, `store.loading` is already `false`, so the `v-else` branch renders — but `numPiante`/`numZone`/`numUrgenti` are all `null` in that state (guarded on `store.piante`, lines 217-237), rendering as blank text. The header silently shows "piante", "zone", "piante da curare" with no numbers, directly above a correctly-implemented error alertbox with a "Riprova" button for the identical failure — one part of the page handles the error state correctly, the header doesn't.
- **Fix**: add a third branch (or a placeholder like "—") for `store.errore` so the header doesn't visually contradict the error message beneath it.
- **Suggested command**: `/impeccable harden`

**[P2] Icon presentation inconsistency between Home's task rows and every other care-row in the app**
- **Why it matters**: verified — `AttivitaRiga.vue:5`, `PiantaView.vue:76`, `DossierPianta.vue:12` all wrap `iconaCura()` in `.care__ic--${tipo}` (`main.css:792-802`), a domain-tinted rounded tile (`.care__ic--irrigazione { background: var(--acqua-bg); color: var(--acqua-ink) }`, etc.) matching DESIGN.md's "pigment chip" icon language. `HomeView.vue:91`'s `.task__ic` renders the same `iconaCura()` glyph as a bare, untiled silhouette. Home — the screen the app opens on — is the one place that doesn't wear the app's own icon vocabulary for this exact row type.
- **Fix**: swap `.task__ic` to the shared `.care__ic--${tipo}` tile pattern.
- **Suggested command**: `/impeccable polish`

**[P3] Zero-plant first-run state reuses the "all clear" achievement copy verbatim**
- **Why it matters**: verified — neither the "Tutto in ordine!" empty-state `v-if` (`HomeView.vue:113`) nor `zorbaDiceSottotitolo`'s `n === 0` branch (line 280) checks `numPiante`. A brand-new user with zero plants ever added sees the exact same "Tutto in ordine!" reward framing as an established user who just cleared a real backlog — hollow for a first-timer, and a missed chance to point them at `/zone` or `/piante`.
- **Fix**: branch on `numPiante === 0` specifically with a distinct first-run message/CTA, separate from the all-clear copy.
- **Suggested command**: `/impeccable onboard`

## Persona Red Flags

**Sam (accessibility)**: the missing `<h1>` (P1 above) is the concrete hit — Home is the one screen in the whole app without a heading landmark. Secondary, smaller: `ZorbaLogo.vue`'s root `<svg>` has no `aria-hidden`, unlike `HeroAiuola.vue`'s scene SVG and every `Icon.vue` glyph, which do.

**Jordan (first-timer)**: gets the same "all caught up" reward messaging on an empty garden as a returning user gets after real progress (P3 above) — no onboarding nudge on the very first screen after login.

**The one-handed garden persona**: most exposed to the rose-on-zero bug (P1) — a fast garden-side glance sees red before parsing that the number is actually 0. Also has no tap-through from a `.task` row to the plant's fuller record if they want to double-check before marking "Fatto", unlike Attività's equivalent row (`AttivitaRiga.vue`'s dossier-open).

## Minor Observations

- `zorbaDiceSottotitolo` interpolates a plant name inline inside a DM Sans sentence — arguably in tension with the strict reading of "Regola del Nome in Fraunces," though font-switching mid-sentence for one word would look odd. Flagging for awareness, not as a hard defect.
- No `<TransitionGroup>` around `.task` rows — a completed row disappears abruptly while the empty state that follows gets a bespoke 600ms entrance. A small polish gap between "row leaves" and "section arrives."
- `oggi` (`HomeView.vue`) and `AttivitaView.vue`'s own "today" string are computed independently via separate `toLocaleDateString` calls — harmless duplication.

## Questions to Consider

- What if the hero's ink-draw and the "Tutto in ordine!" 600ms entrance were budgeted per session (play once, then settle to a cheaper static state on later Home visits) — would that preserve the "rare, noticed" character-animation intent better than replaying the full choreography every time a user bounces back to Home, given the stated one-handed-in-the-garden usage pattern could mean many visits an hour?
- What if the Home stat pill simply defaulted to a neutral ink tone and only escalated to rose past a real threshold (`numUrgenti > 0`) — would a single mostly-neutral, occasionally-escalating pill communicate urgency more honestly than a permanently alarm-colored one?
