---
target: /impostazioni/irrigazione
total_score: 22
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:/Users/rob/Sites/localhost/giardino/.claude/worktrees/irrigazione-automatica/src/views/IrrigazioneView.vue"
target_fingerprint: "sha256:a096e1fd575ba5c009b8317ff1de1548d9cba3cf6db8ff9fc5fbcf5033c316ca"
target_path: /Users/rob/Sites/localhost/giardino/.claude/worktrees/irrigazione-automatica/src/views/IrrigazioneView.vue
timestamp: 2026-09-09T02-23-47Z
slug: src-views-irrigazioneview-vue
---
Method: dual-agent (A: Assessment-A design review · B: Assessment-B detector/browser evidence)

### Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Save has spinner + optimistic badge update; delete has no loading/disabled state at all |
| 2 | Match System / Real World | 3 | "ogni N giorni"/"eredita" language is natural; icon disappearing at the sottozona tier breaks the "real hierarchy" metaphor |
| 3 | User Control and Freedom | 2 | No confirm dialog on any "×" — a giardino-level removal instantly affects every uncovered plant, no undo |
| 4 | Consistency and Standards | 1 | No Fraunces on names, no `.empty` component, no confirm-modal for delete — three concrete deviations from this app's own closest precedent (ZoneView/SottozoneView) |
| 5 | Error Prevention | 2 | `min="1"` guards the number input; nothing guards the destructive "×" |
| 6 | Recognition Rather Than Recall | 3 | Badge vs. "eredita" text makes effective state visible without memorization |
| 7 | Flexibility and Efficiency | 1 | No bulk-apply, no expand-all/collapse-all, no shortcut to a specific plant |
| 8 | Aesthetic and Minimalist Design | 2 | Inconsistent icon presence across tiers reads as unfinished rather than minimal |
| 9 | Error Recovery | 2 | Generic error strings shown in one shared page-top banner — doesn't say which row failed |
| 10 | Help and Documentation | 3 | The intro paragraph genuinely explains the cascade and rain-suspension caveat up front |
| **Total** | | **22/40** | **Acceptable — significant improvements needed** |

All ten heuristics apply (Operate-mode configuration page); none scored n/a.

### Design Specificity Verdict

**LLM assessment**: This page borrows the right classes (`.dest`, `.pill-mini`, `.badge-ok`, `.foglio-form`) but not the identity those classes exist to carry. The clearest tell: DESIGN.md's named rule — every *name* the interface shows uses Fraunces, whatever the size — is followed by both of this page's closest siblings (`ZoneView.vue`'s `.zname`, `SottozoneView.vue`'s `.szname`, each adding a local `font-family:var(--font-display)` override) but is not applied anywhere in `IrrigazioneView.vue`: "Tutto il giardino," every zona, sottozona, and pianta name renders in plain DM Sans, because this file's `<style scoped>` block never adds the override its two siblings both add. Combined with an icon that exists at the zona tier and vanishes at the sottozona and pianta tiers, and plain `<p>` empty-states instead of the shared `.empty` component both siblings use, the page reads as a settings/tree-list bolted onto the notebook, not a page of the notebook.

**Deterministic scan**: `impeccable detect --json src/views/IrrigazioneView.vue` returned 4 findings, all `design-system-font-size` (advisory) on lines 9, 82, 96, 100 — inline `font-size:12px` on the error banner and three empty-state paragraphs. Assessment B's own read: this is likely a systemic gap rather than an issue specific to this page — `12px` is already used identically elsewhere for the same "secondary caption" role (`main.css`'s `.dest__c`, `ZoneView.vue`/`SottozoneView.vue`'s own description text), so DESIGN.md's ramp may simply not document a step that's already in de facto pervasive use. Worth a note to whoever owns DESIGN.md, not a fix specific to this file.

**Visual overlays**: Browser visualization was attempted (Assessment B navigated to `http://localhost:5173/giardino/#/impostazioni/irrigazione` with a real Playwright/Chromium instance) but the router's auth guard redirected to the login screen before the page ever rendered — no test credentials exist in this environment. A screenshot of the login screen was captured as proof of the attempt. **No reliable user-visible overlay is available**; everything below is verified from source, not confirmed visually.

### Overall Impression

The logic is trustworthy — both assessments independently confirmed the cascade-display code correctly mirrors the real resolver, and the ARIA discipline on the expand/collapse rows is genuinely careful. But the page doesn't yet look or behave like it belongs to this app: it's the only page in the reviewed set with no Fraunces anywhere, the only one where deleting something has less friction than deleting a zone, and the only one where two of its four conceptual hierarchy levels are indistinguishable by icon or indentation. The biggest opportunity is closing the gap between "correctly wired" and "feels like the rest of the notebook."

### What's Working

- **ARIA discipline on the expand/collapse controls** (`IrrigazioneView.vue:32-39`): the `role="button"` div is deliberately kept as a sibling, never a parent, of the two `pill-mini` buttons, correctly avoiding this codebase's own banned nested-interactive anti-pattern (the file's comment cites the same principle already established in `AttivitaRiga.vue`). Full keyboard support (`Enter`/`Space`) and `aria-expanded`/`aria-label` are present at both expandable tiers.
- **The giardino row wears the irrigation domain color correctly** (`IrrigazioneView.vue:20`, `Icon name="goccia"` tinted `--acqua`) — a genuine, specific application of DESIGN.md's per-domain color rule, not a generic choice.
- **The cascade-display logic is honest and well-commented** (`programmaEffettivoZona`/`programmaEffettivoSottozona`/`ereditaTesto`, lines 148-173): independently confirmed by Assessment B to correctly mirror `useIrrigazioneAuto.js`'s real resolution order, with a clear comment explaining why it's re-derived here for display rather than imported.

### Priority Issues

**[P1] No Fraunces anywhere on this page's names.**
- **Why it matters**: `IrrigazioneView.vue:21,41,60,74` all use bare `.dest__n` (DM Sans). `ZoneView.vue:114` and `SottozoneView.vue:294` both add a local override class to satisfy DESIGN.md's "Regola del Nome in Fraunces" — every name in the app uses the display font regardless of size. This page is the one place that rule silently doesn't apply, and it's the single most falsifiable proof the page reads generic rather than branded.
- **Fix**: add one scoped rule (e.g. `.dest__n{font-family:var(--font-display)}` scoped to this file, or a small `.irr-nome` class applied to all four name spans) matching the sibling pattern exactly.
- **Suggested command**: `/impeccable typeset`

**[P1] No confirmation on any destructive "×", including the highest-blast-radius action on the page.**
- **Why it matters**: `IrrigazioneView.vue:27,50,69,80,93` all fire `rimuovi()` immediately on click. Both `ZoneView.vue` and `SottozoneView.vue` gate their own delete behind `ModalConferma` with an explicit consequence message. Here, removing the **giardino-level default** — the single action on this entire page with the widest blast radius, since it can silently reactivate manual watering reminders for every plant not covered by a more specific override — currently has *less* friction than deleting one zone elsewhere in the app.
- **Fix**: reuse `ModalConferma.vue` (already in the codebase) for giardino/zona/sottozona removal at minimum; a single-plant override could reasonably stay a plain click if the team wants to keep it fast at the leaf level.
- **Suggested command**: `/impeccable harden`

**[P2] Sottozona and pianta tiers carry no icon, and indentation collapses four conceptual levels into three visual ones.**
- **Why it matters**: both assessments independently converged on this. Zona rows carry `store.iconaZona(...)` (line 40); sottozona rows carry none, even though `store.iconaSottozona(...)` already exists and is used identically one file away in `SottozoneView.vue:27` — this file never calls it. Pianta rows also carry no icon or thumbnail, unlike the reusable `PiantaRiga.vue` used elsewhere in the app. Structurally, only two `padding-left:30px` declarations exist in the whole file (lines 53 and 72, the second nested inside the first): giardino and zona both sit at 0px, sottozona rows AND piante directly under a zona (no sottozona) both sit at 30px, and piante under a sottozona sit at a cumulative 60px. Two conceptually distinct level-pairs collapse to the same visual depth, and the only remaining cue to tell a "container" row from a "leaf" row is spotting a small chevron.
- **Fix**: call `store.iconaSottozona(z.nome, sz.nome)` on the sottozona row — it's already available and used elsewhere; consider a lighter visual cue (even just a smaller/dimmer icon) for piante to restore the fourth tier's legibility.
- **Suggested command**: `/impeccable layout`

**[P2] Delete-error feedback is a single banner shared by every row at every depth.**
- **Why it matters**: `erroreRimozione` (line 9, set at line 213) is one message at the top of the page for every remove button across 4 levels and potentially dozens of rows. If a deeply-nested pianta removal fails, the message appears far from where the user is looking and never names which row failed.
- **Fix**: surface the error inline near the specific row, or at minimum interpolate the target's name into the shared banner's text.
- **Suggested command**: `/impeccable clarify`

**[P3] Every edit button at a given tier shares an identical, non-interpolated `aria-label`.**
- **Why it matters**: every zona's edit button says exactly "Modifica programma zona" (line 47), every sottozona's "Modifica programma sottozona" (line 66), every pianta's "Modifica programma pianta" (lines 77, 90) — the same pattern already exists in `ZoneView.vue`/`SottozoneView.vue` (not a new regression), but is far more damaging here, where a single page can contain dozens of identically-labeled controls across 4 tiers at once.
- **Fix**: interpolate the actual name, e.g. `` `Modifica programma di ${z.nome}` ``.
- **Suggested command**: `/impeccable clarify`

### Persona Red Flags

**Sam (Accessibility-Dependent)**: Beyond the duplicate-label issue above, the entire giardino→zona→sottozona→pianta hierarchy is conveyed only visually, through indentation and sequence — there's no `aria-level`/tree semantics anywhere. A screen-reader user gets a flat sequence of identically-structured announcements with no way to know they've just entered a deeper tier, unlike a sighted user who at least sees the indent step change.

**Casey (Distracted Mobile User)**: `padding-left:30px` is applied twice for the deepest tier (60px total) with no responsive adjustment anywhere in this file. On a narrow phone viewport that leaves well under 300px for icon + name + badge + chevron + two 44px-min-height buttons on one unwrapped flex row (`.dest` has no `flex-wrap`), and `.dest__n` has no `text-overflow:ellipsis` override here — unlike `.zname`/`.szname` in the sibling pages, which both explicitly add one — so a long species name at the deepest tier has no defined truncation behavior on a phone.

### Minor Observations

- No back-link to `/impostazioni` at the top of the page, unlike `SottozoneView.vue`'s `.back-link` pattern for a similarly nested detail view.
- `rimuovi()` has no `salvando`-style guard against a double-click firing two concurrent delete calls on the same row — harmless server-side today (the second no-ops) but produces a confusing generic error.
- Empty states use raw `<p style="...">` (lines 82, 96, 100) instead of the `.empty` component both `ZoneView.vue` and `SottozoneView.vue` use for the equivalent "nothing here yet" moment.
- The detector's 4 `font-size:12px` findings are likely a systemic DESIGN.md-ramp gap rather than an issue specific to this file — `12px` is already the de facto secondary-caption size used pervasively elsewhere in the app.

### Questions to Consider

- If "the most specific level wins" is this page's entire value proposition, why does the UI give equal visual weight to "I set this on purpose" (badge) and "I'm just seeing what I inherited" (grey text) — shouldn't an overridden row visually pop against a sea of inherited ones in a fifty-plant garden?
- Why does removing the single default that affects the whole garden currently require less confirmation than removing one zone's name elsewhere in the app?
- Given DESIGN.md treats icons as a signature identity element ("macchie di pigmento," never plain signage), does a tier with no icon at all actually save effort, or does it just move the cost onto every future user who has to learn that a name-only row means something different from an icon+name row?
