---
target: HomeView (src/views/HomeView.vue)
total_score: 29
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/HomeView.vue"
target_fingerprint: "sha256:1d100396c739eb316d02c493c4fd7c7580097fff0ac6ecb43258533179d95d0f"
target_path: /Users/rob/Sites/localhost/giardino/src/views/HomeView.vue
timestamp: 2026-09-06T22-17-21Z
slug: src-views-homeview-vue
closed: true
---
# Critique: `src/views/HomeView.vue`

Method: dual-agent (A: general-purpose design review · B: general-purpose detector/evidence)

**Environment disclosure:** No browser automation tool is exposed in this session (no Playwright/Puppeteer, none installed locally, no headless binary found) — confirmed independently by both assessments. Assessment A's holistic review is therefore based on close reading of the Vue SFC, its imported components, and the global stylesheet, not a live render. Assessment B ran the CLI detector for real and confirmed the dev server (`localhost:5173`) is up but unreachable to inspect visually. The parent session additionally spot-verified the design review's highest-stakes claims against the actual source before writing this up — one of them didn't hold up and is flagged rather than passed through.

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Loading/error/toast states all present, but two different "how urgent is my garden" numbers disagree on-screen with nothing explaining why |
| 2 | Match Between System and Real World | 3 | Natural Italian throughout; "da curare" (plant count) and "urgenti" (task count) read as synonyms but aren't |
| 3 | User Control and Freedom | 3 | `ToastCura`'s "Annulla" is a good safety net; no way to snooze/dismiss a task from Home itself |
| 4 | Consistency and Standards | 2 | `HomeView.vue:209` reinvents the care-icon map instead of importing the canonical one already used one component down the tree — verified, `calcio` renders two different icons in the same flow |
| 5 | Error Prevention | 3 | `salvando` guard blocks double-submit; weather-aware irrigation suppression prevents a false "urgent" after rain |
| 6 | Recognition Rather Than Recall | 4 | Every task row states plant, care type, and reason inline |
| 7 | Flexibility and Efficiency of Use | 2 | No bulk-confirm from Home; six nav destinations always fully expanded with no memory of repeat visits |
| 8 | Aesthetic and Minimalist Design | 4 | Hairline rows, restrained palette, no stacked-card clutter — matches the notebook system closely |
| 9 | Error Recovery | 3 | Plain-language, actionable errors at both section and row level; row-level one has a verified contrast bug (see below) |
| 10 | Help and Documentation | 2 | Nothing explains why the two urgency counts differ — this is core Operate functionality, so the heuristic applies |
| **Total** | | **29/40** | **Good** |

## Design Specificity Verdict

**LLM assessment:** This is not a reskin. The hero's season/light state is driven by the real current month and today's actual Open-Meteo sunrise/sunset (`HomeView.vue:190-195`), so the ink scene is quietly tracking *this* garden's real conditions, not looping a decorative animation. The "Regola dei Due Battiti" is wired exactly as specified: `HeroAiuola`'s `cambio-scena` event triggers the slow "notices" blink (line 6), a successful care save triggers the normal "confirms" blink (line 263) — two distinct, correctly-routed signals. Fraunces is reserved for the species name, Caveat appears exactly once. This couldn't drop into a generic gardening app unchanged.

Two seams betray production-line thinking instead: the "Zorba dice" row (lines 64-71) is static marketing copy that never reflects the actual garden state — it reads identically whether 0 or 12 things are overdue, which is a quiet contradiction of the product's own principle that the AI assistant should never feel like a disconnected satellite. And the calcio icon divergence (below) shows the icon system's per-domain meaning got reinvented locally instead of reused — exactly the kind of drift a strongly-branded system exists to prevent.

**Deterministic scan:** `impeccable detect --json` found **0 issues in `HomeView.vue` itself**. Scanning its imported components found 2 advisory `design-system-color` findings — undocumented colors outside `DESIGN.md`: `ZorbaLogo.vue:248` (`#d4b23c`) and `ToastCura.vue:79` (`rgba(22,16,8,0.28)`). Both are real, literal color values in `<style>` blocks, not template-syntax false positives — but they're in components HomeView imports, not in HomeView's own markup, and are advisory-severity, so they don't move the needle on this page's own health.

**Visual overlays:** Not available — no browser automation tool exists in this session, so no `[Human]`-tab overlay could be produced. This is a static-analysis-only run; treat any pixel-precise claim below with that caveat.

## Overall Impression

HomeView is the strongest kind of "on-brand" screen: the hero, Zorba's two blink states, and the icon system are all wired to real data with real restraint, not just painted on. But the actual job of this screen — telling the user what needs care today — has a correctness problem underneath the polish: the task list isn't sorted by urgency, and two different numbers on the same screen both claim to answer "how much do I need to do" but count different things. The biggest opportunity here isn't more delight, it's making the one list that matters actually trustworthy.

## What's Working

- **The hero is alive, not decorative** (`HomeView.vue:190-195` + `HeroAiuola.vue`): season/light state comes from the real month and today's real sunrise/sunset, not a static illustration or fake state cycle — rare for this category.
- **"Regola dei Due Battiti" implemented precisely** (`HomeView.vue:6,263` + `ZorbaLogo.vue`): the slow "notices" blink fires only on a genuine season/light change, the normal "confirms" blink only on a genuine successful save — correct trigger, correct restraint, no confusion between a rare and a frequent event.
- **The team already fixes its own contrast bugs elsewhere** (`main.css:814-816`): `.care-act--rose` deliberately uses `--rose-ink` instead of `--rose-dark` with a comment explaining why. That rigor exists in this codebase — which is exactly why the regression below is worth catching now, before it spreads further.

## Priority Issues

**[P1] "Da fare oggi" is not sorted by urgency**
- **Why it matters**: `daFareOggi` (`HomeView.vue:236-251`) is built by iterating `store.piante` in object-insertion order, then sliced to 5 for display (line 90) with no sort by days-overdue. On a garden with more than 5 urgent items, a plant overdue 45 days can be pushed off-screen by one overdue 1 day, purely by creation order. This directly undercuts the product's own stated success metric: "fewer neglected plants, care done at the right time."
- **Fix**: Sort by `giorni` (days overdue) descending before slicing, so the most-neglected plant always surfaces first.
- **Suggested command**: `/impeccable harden`

**[P1] Divergent care-icon mapping — verified real bug**
- **Why it matters**: `HomeView.vue:209` declares a local `ICONE_CURA = { …, calcio: 'provetta' }`. Verified against the canonical source, `useCureVisual.js:3`: `calcio: 'uovo'`. That canonical map is already imported into this exact render tree via `ToastCura.vue`. Result: the same "calcio" care shows a sage test-tube icon on Home and the purpose-built egg-ochre icon everywhere else (Attività, plant page, dossier) — directly contradicting DESIGN.md's own functional-color rule (uovo = minor treatments/calcium).
- **Fix**: Delete the local `ICONE_CURA`/`icona()` at lines 209-212 and import `iconaCura`/`ICONE_CURA` from `useCureVisual.js` instead.
- **Suggested command**: `/impeccable polish`

**[P1] Two incompatible "urgency" counts on the same screen**
- **Why it matters**: `numUrgenti` (`HomeView.vue:226-234`) counts *plants* with at least one urgent care and feeds both the hero stat (line 22, "N da curare") and the "Piante" nav row (line 278). `daFareOggi.length` (lines 236-251) counts individual *(plant, care-type)* pairs and feeds the "Attività" nav row (line 281). A plant needing both water and fertilizer counts once in one number and twice in the other — a user can see "3 da curare" at the top and "5 urgenti" near the bottom for the same instant, with no label explaining the difference, on the one screen whose entire job is answering "how much do I need to do."
- **Fix**: Either standardize on one unit (task-count is what the list actually enumerates) or label them distinctly ("3 piante" vs "5 cure").
- **Suggested command**: `/impeccable clarify`

**[P2] Contrast regression on the row-level error message**
- **Why it matters**: `HomeView.vue:295`: `.task__d--err { color: var(--rose-dark); }`. `.task` rows have no background (`main.css:408`), sitting directly on the cream page — and the project's own comment at `main.css:814-816` states plainly that `--rose-dark` on white/cream drops below 4.5:1 AA in light mode, which is why `.care-act--rose` deliberately uses `--rose-ink` instead. This scoped override reintroduces the exact bug the shared system already fixed once.
- **Fix**: Change `.task__d--err` to `var(--rose-ink)`.
- **Suggested command**: `/impeccable audit`

**[P2] No focus-visible styling on Home's interactive rows — verified**
- **Why it matters**: A full grep of the 867-line stylesheet shows only three focus rules in the entire app (`.search-input`, `.form-input`, `.gslide`), none targeting `.dest`, `.wxrow`, `.zdice`, `.care-act`, or `.task` — 12+ interactive elements on this screen alone. That leaves keyboard/switch users on whatever the browser default supplies, inconsistent with DESIGN.md's documented gold-focus-ring rule (gold border + glow is supposed to be the focus treatment app-wide).
- **Fix**: Add `:focus-visible` states to these row classes using the existing gold-glow pattern (`box-shadow: 0 0 0 3px rgba(224,184,74,.15)`).
- **Suggested command**: `/impeccable audit`

## Persona Red Flags

**Casey (distracted mobile user, checking the garden one-handed)**: Before reaching the actual task list, Casey scrolls past a full-height hero, a weather row, and an AI-assistant upsell row (`HomeView.vue:4-71`) — three ambient sections between opening the app and seeing "what do I need to do." Combined with the unsorted task list above, a quick interrupted glance is likely to surface the wrong plant first.

**Sam (accessibility, screen reader / keyboard-only)**: Hits both the contrast regression and the missing focus-visible states directly on this screen. One real win: `ToastCura`'s `role="status"` does correctly announce a completed care action to screen readers.

**Correction to a claim checked and rejected**: the design review flagged `.dest` rows as under the 44px touch target (~38px). Verified against `main.css:420-427` directly: `padding: 11px 2px` plus a 26px icon gives a row height of ~48px (row height is driven by the tallest flex child, the icon, not the 13.5px text line-height) — comfortably above the 44px minimum. Not carried forward as a finding.

## Minor Observations

- `.stat b` (line 22, "N da curare") is styled `--rose-ink` unconditionally, even at `numUrgenti === 0` — the all-clear number still renders in the "attention" tint, in tension with DESIGN.md's rule that rose signals urgency/destruction specifically.
- The "all clear" state (`Nessuna cura urgente oggi.`, line 107) renders as plain muted `.prose` text — no Zorba reaction, no distinct treatment — in contrast to how deliberately the app treats the equivalent moment in Attività (a named, 600ms "one true milestone" entrance). This is the daily reward moment for a user whose whole relationship with the app is "did I neglect anything," and it currently under-delivers relative to the app's own stated intent.
- The "Il giardino" list (`homeCards`) duplicates every destination already permanent in the desktop sidebar; its only added value there is the count badges.
- `numUrgenti` and `daFareOggi` both independently loop over every plant and re-run `valutaCura`/`cureUrgentiPianta` (lines 226-251) — redundant computation, worth a memoized single pass on gardens with many plants.

## Questions to Consider

- What if "Da fare oggi" surfaced the single most-overdue task with the same visual weight as the hero, instead of a same-weight list — would that serve "fewer neglected plants" better than a flat list ever could?
- What if the "Zorba dice" copy were generated from `daFareOggi`/`numUrgenti` instead of static boilerplate — would the assistant start feeling like it's watching the same garden the user is, closing the "never a disconnected satellite" gap the review flagged?
