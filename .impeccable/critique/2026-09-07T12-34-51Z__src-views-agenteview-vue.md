---
target: AgenteView
total_score: 33
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 0
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/AgenteView.vue"
target_fingerprint: "sha256:69cf39ce408927f0e3cf73af6b6fa6d725ca831479a089dc4ee5a61bb5e61ee2"
target_path: /Users/rob/Sites/localhost/giardino/src/views/AgenteView.vue
timestamp: 2026-09-07T12-34-51Z
slug: src-views-agenteview-vue
---
Method: dual-agent (A: general-purpose design review · B: general-purpose detector/browser evidence)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | `.adot` pulse, gold badges, and 30s polling are solid; no "last checked" timestamp or manual refresh |
| 2 | Match System / Real World | 4 | Solid — Italian, garden-native language, friendly type labels |
| 3 | User Control and Freedom | 4 | Change photo, change type (fields reset cleanly), delete with confirm, explicit back-link to compose |
| 4 | Consistency and Standards | 2 | Detail header inverts the "name in Fraunces" rule (category label is Fraunces, the actual species name is DM Sans); the "Altro" group contains a chip also labeled "Altro" |
| 5 | Error Prevention | 4 | `puoInviare` gating, 5MB guard, token-gated send button all hold up |
| 6 | Recognition Rather Than Recall | 4 | Per-type hint and placeholder swap remove any need to memorize |
| 7 | Flexibility and Efficiency | 2 | Auto-jumping to the new request's detail after every send costs an extra tap for anyone filing several requests back-to-back |
| 8 | Aesthetic and Minimalist Design | 3 | Clean composer; the answer header ("Risposta · Diagnosi problema · 7 set, 14:32") is a slightly cramped middle-dot run-on |
| 9 | Error Recovery | 4 | Inline error box with icon, clear token-expiry message routes to Account |
| 10 | Help and Documentation | 3 | No formal help, but hints double as adequate contextual help for an Operate-mode screen |
| **Total** | | **33/40** | **Good** |

Trend for this view: 20 → 31 → 33/40. Real, if smaller, gains again this round — the fixes from round 2 held up, and this pass caught two new, more subtle issues (see below).

## Design Specificity Verdict

**Mostly authored for this app now.** Zorba's voice, the group taxonomy, and the `.feed`/`.reqchip`/`.foglio` idiom read as specific to this product, not generic. Two concrete, verified slips remain: `.agente-dettaglio-tipo` (a category label like "Diagnosi problema") is set in Fraunces, while `.agente-dettaglio-specie` (an actual plant name) is set in DM Sans — exactly backwards from the app's own "name in Fraunces, category in DM Sans" rule, confirmed by reading the CSS directly (lines showing `font: 600 14px/1.3 var(--font-display)` on the type label vs `font: 600 13px/1.4 var(--font-sans)` on the specie name). And the "Altro" chip group literally contains a chip also labeled "Altro" (`GRUPPI_TIPO`'s third group is named `'Altro'` and its `tipi` array includes the `altro` type) — a labeling accident, not a deliberate choice.

**Deterministic scan**: exit 0, same 2 advisory findings as the last two passes (the bare "×" glyph-button font-sizes) — unchanged, still read as legitimate icon sizing rather than typographic drift. Sibling imports all scanned clean; `SelettoreSpecie.vue`'s pre-existing drift and `ZorbaLogo.vue`'s one documented palette exception are both unrelated to this file's own fix rounds.

**Visual overlays**: still unavailable — auth gate correctly blocked live rendering again, confirmed via a fresh screenshot attempt.

## Overall Impression

Score kept climbing (20 → 31 → 33) and cognitive load is now clean (0/8 failed — genuinely tight, not manufactured). What's left are two small, concrete inconsistencies worth a quick fix, plus two open trade-off questions that are really product-policy calls rather than defects: whether the "risposta entro pochi minuti" promise is honest given `/elabora` runs manually and irregularly, and whether auto-jumping to a freshly-sent request's detail is worth the reassurance it buys against the friction it costs someone sending several requests in a row.

## What's Working

- `selezionaTipo()` resetting every field on type-switch is a verified real bug fix, not cosmetic — it was independently re-confirmed this pass to prevent a stale hidden photo/message riding into an unrelated submission.
- The 3-group chip taxonomy (Specie/Cura/Altro) keeps every decision point at ≤3 options — cognitive load checklist passed cleanly across all 8 items this round.
- Reusing `.feed`/`.feed__del`/`FoglioLaterale` for history continues to hold up under fresh, independent inspection.

## Priority Issues

**[P2] Fraunces/DM-Sans inversion in the detail header**
- **Why it matters**: the app's own named rule is "every name uses Fraunces, every category/label uses DM Sans" — this view does the opposite for its two adjacent text elements, undermining the specificity that's otherwise solid here.
- **Fix**: swap the two — `.agente-dettaglio-tipo` (the category label) to `var(--font-sans)`, `.agente-dettaglio-specie` (the actual species name) to `var(--font-display)`.
- **Suggested command**: `/impeccable typeset`

**[P2] "Altro" group name collides with the "Altro" chip inside it**
- **Why it matters**: `GRUPPI_TIPO`'s third group is labeled "Altro" and contains a chip also labeled "Altro" (alongside `pianifica_progetto`) — reads as a labeling accident under the group's own header ("Altro" over "Altro"), not an intentional taxonomy.
- **Fix**: rename the group (e.g. "Varie") so the group label and the leaf chip label don't repeat.
- **Suggested command**: `/impeccable clarify`

## Persona Red Flags

**Rushed outdoor operator** (phone in hand, filing a request mid-task in the garden): auto-navigating to the new request's detail after every send adds an unwanted tap if they're firing off 2-3 requests back-to-back; if `/elabora`'s actual cadence ever exceeds "pochi minuti," this exact persona is the one most likely to feel misled by that promise while standing in the garden waiting.

**Assistive-tech user** (screen reader / keyboard-only): history rows already handle Enter/Space on their `role="button"` div, which is good; worth double-checking in a real screen reader that the "Nuovo"/"In attesa" badge text is announced together with the row's name, since it currently relies on being inside the same accessible-name subtree rather than an explicit `aria-label`.

## Minor Observations

- `.badge-gold`'s text color (`#8a6820`) is a hardcoded hex rather than a token — pre-existing, shared by every other view that uses this badge, not specific to this file.
- A long `revisione_specie`/`diagnosi` answer renders as one flat `<p>` with `pre-wrap` — fine for short replies, could read as a wall of text for a long one.
- `nuovoTipo` doesn't reset after a successful send (stays on whatever type was just submitted) — likely intentional convenience for someone filing several similar requests, but undocumented as a deliberate choice the way `selezionaTipo()`'s reset logic is.

## Questions to Consider

- Given `/elabora` is run manually and (per commit history) irregularly, is "Zorba risponde di solito entro pochi minuti" — copy that predates this critique cycle — still the promise you want to make, or should it hedge more (e.g. "Zorba controlla la coda quando può")?
- Is auto-jumping to a freshly-sent request's detail (rather than staying on the compose form) still the right trade-off, now that filing several requests in a row is a more visible use case than it was before the chat-like layout?
