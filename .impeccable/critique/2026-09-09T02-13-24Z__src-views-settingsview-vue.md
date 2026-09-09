---
target: SettingsView icona irrigazione automatica non in linea
total_score: 22
max_score: 40
na_heuristics: 
p0_count: 2
p1_count: 2
target_identity: "file:/Users/rob/Sites/localhost/giardino/.claude/worktrees/irrigazione-automatica/src/views/SettingsView.vue"
target_fingerprint: "sha256:436ad38ad5ecdbf9ed61181e293962911c19d2e2e5f20a0b10b908540194bb93"
target_path: /Users/rob/Sites/localhost/giardino/.claude/worktrees/irrigazione-automatica/src/views/SettingsView.vue
timestamp: 2026-09-09T02-13-24Z
slug: src-views-settingsview-vue
---
Method: dual-agent (A: Assessment-A design review · B: Assessment-B detector/browser evidence)

### Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | "Aspetto" autosaves instantly with zero success/failure feedback, unlike the Salva flow's spinner + badge |
| 2 | Match System / Real World | 3 | Plain labels, but raw lat/lon/altitude fields with no framing for a non-technical gardener |
| 3 | User Control and Freedom | 2 | `IrrigazioneView.vue` has no way back to Impostazioni; no discard for in-progress lat/lon edits |
| 4 | Consistency and Standards | 2 | The flagged icon bug is itself a consistency failure; the two "link to another settings page" cards (Irrigazione vs. Account) use different icon vocabularies |
| 5 | Error Prevention | 2 | No bounds/format validation on lat/lon/altitude |
| 6 | Recognition Rather Than Recall | 3 | Form correctly pre-fills from `store.settings` on mount |
| 7 | Flexibility and Efficiency | 2 | Address search is Enter-only, no live typeahead |
| 8 | Aesthetic and Minimalist Design | 2 | Four visually identical cards with three different persistence models and no grouping |
| 9 | Error Recovery | 2 | Geo errors are handled well; the instant theme autosave has no error path at all |
| 10 | Help and Documentation | 2 | Nothing distinguishes "saved together," "saves itself," and "links elsewhere" cards |
| **Total** | | **22/40** | **Acceptable — significant improvements needed** |

All ten heuristics apply (Operate-mode settings page); none scored n/a.

### Design Specificity Verdict

**LLM assessment**: This page is generic settings-form boilerplate wearing the app's color tokens, not a page composed for "Il Taccuino da Giardino." Every other reviewed surface (Home's hero, the Galleria polaroid album, the project timeline) invests in the hand-drawn/watercolor identity; SettingsView is four undifferentiated white `.form-card` boxes stacked with raw `<input type="number">` fields and native `<select>`s — nothing beyond the CSS variables signals this product. One genuine specific touch: the irrigation icon correctly uses the domain color `--acqua`, per DESIGN.md's tertiary-color convention for irrigation — a real, specific application of the system, not a generic choice.

**Deterministic scan**: `impeccable detect --json src/views/SettingsView.vue` returned 2 findings, both `design-system-font-size` (advisory): inline `font-size:12px` on the two error paragraphs (line 34, `erroreGeo`; line 58, `errore`) is off the DESIGN.md type ramp — the rest of the page correctly uses 13px for equivalent inline text. Neither the detector nor its rule set covers layout/display bugs like the flagged icon issue; that class of defect is outside its scanning scope by design. No false positives.

**Visual overlays**: Browser visualization was attempted (Assessment B navigated to `http://localhost:5173/giardino/#/impostazioni` with a real Playwright/Chromium instance) but the app's router guard redirected to the login screen before the target page ever rendered — no test credentials exist in this environment, and creating one was correctly out of bounds. A screenshot of the login screen was captured as proof of the attempt, but **no reliable user-visible overlay is available**; injection of the detector script never had a page to run against. Everything below is source-verified, not visually confirmed.

### Overall Impression

The page mechanically works but doesn't know what kind of page it is: four settings that look identical actually follow three unrelated persistence models (batched-save, autosave, navigate-away), and the specific bug you flagged — the irrigation icon dropping onto its own line — is a symptom of the same underlying habit: this row was assembled by pattern-matching the nearest similar card instead of reusing the flex-icon convention every other icon+label pairing in this codebase already follows. The single biggest opportunity is making the page honest about which cards do what, starting with fixing the one that's visibly broken.

### What's Working

- **Geo error handling is solid**: `erroreGeo`/`errore` are styled consistently with the app's established alert pattern (`role="alert"`, `--rose-dark`), and the spinner → "Salvato" badge sequence on the main Salva button gives real, trustworthy feedback (`SettingsView.vue:34,58,60-65`).
- **The address-search-then-reverse-geocode-altitude flow** (`impostaPosizione`, `SettingsView.vue:127-136`) is a genuinely useful, non-generic convenience for a gardener setting up their plot — the kind of detail that earns its place.
- **Correct domain-color usage**: the irrigation card's icon is tinted `--acqua`, matching DESIGN.md's own rule that irrigation is always represented in China Blu Cielo — evidence the rest of the design system is being followed even where this one card's structure went wrong.

### Priority Issues

**[P0] Irrigation icon renders on its own line, not beside the text — root cause confirmed by both assessments independently.**
- **Why it matters**: This is the exact bug you reported. It's the newest, most recently-touched element on the page, and it visibly breaks the one visual convention (icon + label on one line) every other card on this page and in `AccountView.vue` follows correctly.
- **Root cause** (Assessment A via source reading, Assessment B via source + Tailwind preflight verification + an actual browser attempt — both converged independently): `SettingsView.vue:54` nests the `<Icon name="goccia">` **inside** a `<span>` alongside a text node:
  ```html
  <span style="font-size:13px;font-weight:600;"><Icon name="goccia" style="...vertical-align:-2px;margin-right:6px;..." />Irrigazione automatica</span>
  ```
  `Icon.vue` renders a bare `<svg>` with no `display` override. This project imports Tailwind v4 plainly (`main.css:1`, `@import "tailwindcss"`), whose Preflight sets `svg { display: block; vertical-align: middle; }` globally — confirmed unmodified in this codebase (no project-level `svg { display: ... }` override exists). A `vertical-align` style has no effect on a block box, so the inline `vertical-align:-2px` on this icon is dead code. Per CSS's block-in-inline fixup (implemented by every major browser), a block-level box appearing inside inline content forces a line break immediately before and after it — so the icon drops onto its own line and the label wraps below/beside it, never sharing its baseline.
  This is the **only** icon+text pairing in the reviewed files placed inside a plain inline `<span>` with no flex context — every other icon+label pairing in this codebase (`.btn` at `main.css:232-234`, `.pill-icona`, and the sibling `AccountView.vue` card) sits in a flex container that neutralizes exactly this Preflight behavior.
- **Fix**: give the span `display:inline-flex; align-items:center; gap:6px`, and drop the now-redundant/dead `margin-right`/`vertical-align` on the icon:
  ```html
  <span style="display:inline-flex;align-items:center;gap:6px;font-size:13px;font-weight:600;"><Icon name="goccia" style="width:14px;height:14px;color:var(--acqua);" />Irrigazione automatica</span>
  ```
- **Suggested command**: `/impeccable layout`

**[P0] No way back from the Irrigazione automatica page.**
- **Why it matters**: `IrrigazioneView.vue` has a page title but no `.back-link` — every other drill-down page in this app (`ProgettoView.vue` → "Progetti", `SottozoneView.vue` → "Zone", `PiantaView.vue` → "Piante") has one. A user who taps the card and doesn't realize it navigated (see next issue) lands somewhere with no visible route back except OS/browser back or the unrelated bottom nav.
- **Fix**: add `<RouterLink to="/impostazioni" class="back-link"><Icon name="back" />Impostazioni</RouterLink>` at the top of `IrrigazioneView.vue`, matching the established sibling pattern exactly.
- **Suggested command**: `/impeccable clarify`

**[P1] Three incompatible save models presented as four identical cards.**
- **Why it matters**: Posizione + Zona climatica are held in local state and persisted only by "Salva." Aspetto saves itself **instantly** the moment the select changes (`useTema.js`'s `impostaTema`) — with no `try/catch`, so a failed Supabase write is a silent, unhandled rejection: the theme flips visually but may not actually persist, and the page's own "Salvato" badge (which the user has just learned to expect) never appears for this action, teaching a wrong mental model. Irrigazione automatica isn't a setting at all — it's a link to a different table with its own save flow. All four are styled as the identical `.form-card` box, so nothing signals which bucket a given card belongs to.
- **Fix**: at minimum, give "Aspetto" its own success/error micro-feedback and stop batching a stale `store.settings?.ui` into `salva()`'s payload (`SettingsView.vue:161`, which never reflects the value the user just picked in that dropdown). Longer-term, visually separate "saved together," "saves itself," and "navigates elsewhere" so identical chrome stops implying identical behavior.
- **Suggested command**: `/impeccable clarify`

**[P1] The two "link to another settings page" cards disagree with each other.**
- **Why it matters**: `SettingsView.vue`'s Irrigazione card uses a leading water-drop icon + trailing chevron (`Icon name="back"`, rotated 180°). `AccountView.vue`'s "Impostazioni giardino" card — structurally the same pattern, in a sibling file — uses only a trailing `Icon name="pin"`, a location icon borrowed from the geolocation domain where it means something else entirely, not a directional "go to" cue. Neither card carries `.hover-card`, so on desktop there's no hover/elevation signal distinguishing these two clickable, navigating cards from the static form cards above them.
- **Fix**: standardize on one link-card pattern (icon + label + trailing chevron using `Icon name="back"` rotated, never `pin`) and apply `.hover-card` to both.
- **Suggested command**: `/impeccable polish`

**[P2] No validation on latitude/longitude/altitude.**
- **Why it matters**: `form.lat`/`form.lon`/`form.altitude` are unconstrained `<input type="number">` fields. A mistyped `lat=900` saves silently with no client-side sanity check, and this value feeds weather and climate-zone calculations downstream — a wrong coordinate degrades the app's core "cure urgenti" logic without any visible warning.
- **Fix**: add realistic `min`/`max`/`step` per field and a validation message before Salva is enabled.
- **Suggested command**: `/impeccable harden`

### Persona Red Flags

**Jordan (First-Timer)**: Sees four visually identical white cards. Taps "Irrigazione automatica" expecting it to expand inline, like the "Zona climatica" card right above it — instead gets teleported to a whole new page, then can't find a way back (P0 above) and has to guess at the bottom nav. Separately, picks a dark theme from "Aspetto," watches the page recolor, but gets no "Salvato" confirmation like the rest of the page trained them to expect — reasonably concludes something broke.

**Sam (Accessibility-Dependent)**: The address-results dropdown uses `role="listbox"`/`role="option"` on independently-tabbable `<li tabindex="0">` items rather than proper combobox semantics (`aria-activedescendant`, arrow-key navigation) — a screen-reader user tabs through results one at a time instead of arrow-keying a real listbox. The instant "Aspetto" autosave has no `role="status"` announcement at all, so a screen-reader user gets *less* confirmation than a sighted one (who at least sees the theme flip). The Irrigazione link's native `role="link"` semantics are, ironically, more honest to assistive tech than to sighted users, who can't tell it navigates until they tap it.

### Minor Observations

- Both error paragraphs (`SettingsView.vue:34,58`) use `font-size:12px`, flagged by the detector as off the DESIGN.md type ramp — the rest of this file correctly uses 13px for equivalent inline text (e.g. line 9). Cheap one-line fix, two occurrences.
- `.form-card` uses `border-radius:14px` (`main.css:728`) while DESIGN.md's documented `card` token is 20px — this is an app-wide pattern (also true in `AccountView.vue`), so likely a pre-existing, undocumented divergence rather than something specific to this page; worth reconciling in DESIGN.md at some point, not urgent.
- `--ink-faint` on white for the trailing chevron is very low-contrast — acceptable since it's decorative/`aria-hidden`, but faint enough that it barely reads as a navigation affordance, compounding the discoverability problem above.
- The "Cerca indirizzo…" placeholder implies live search, but the field only fires on Enter — a reasonable but unstated limitation.

### Questions to Consider

- If "Aspetto" already saves itself instantly and independently of every other card on this page, why does it live inside this form at all — should it move to where theme toggles usually live (nav/status bar) instead of implying it's part of the same Salva transaction?
- Should "Irrigazione automatica" — an operational, frequently-used feature — really be filed one tap away from raw lat/lon coordinates under "Impostazioni," or does that bury it from the "cure urgenti" flow that's supposed to be this app's core loop?
- Given how much of this design system is built around hand-drawn/watercolor identity, why does the page that sets *where the garden physically is* get zero illustrative treatment — isn't a hand-drawn compass or map pin exactly the moment this system exists for?
