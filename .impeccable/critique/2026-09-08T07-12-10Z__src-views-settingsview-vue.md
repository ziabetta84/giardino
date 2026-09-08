---
target: SettingsView
total_score: 28
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/SettingsView.vue"
target_fingerprint: "sha256:f659b89a7009167e782d0f9332269c0529f35bcfec1629420fdc4fefca39a7c7"
target_path: /Users/rob/Sites/localhost/giardino/src/views/SettingsView.vue
timestamp: 2026-09-08T07-12-10Z
slug: src-views-settingsview-vue
closed: true
---
**Method: dual-agent (A: design-review agent · B: detector-evidence agent)**

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | Good in-flight spinners, but zero feedback after a successful save |
| 2 | Match System / Real World | 3 | Plain Italian labels, but the emoji icon clashes with the app's crafted voice |
| 3 | User Control and Freedom | 3 | Fields always overwritable; no destructive actions on this screen |
| 4 | Consistency and Standards | 2 | Matches `AccountView.vue` locally, but breaks the token system (gray fallbacks, off-scale radius, emoji vs. Icon component) |
| 5 | Error Prevention | 2 | Lat/lon/altitude are free-typed numbers, no min/max/step, feed the climate-zone heuristic unchecked |
| 6 | Recognition Rather Than Recall | 3 | Labels sit above inputs, though placeholders redundantly repeat them |
| 7 | Flexibility and Efficiency | 4 | Three real paths to set location (GPS, address search, manual) — genuinely serves both field and desktop use |
| 8 | Aesthetic and Minimalist Design | 3 | Clean, but flat and icon-less next to the rest of the app's illustrated identity |
| 9 | Error Recovery | 4 | Plain-language errors ("Permesso di geolocalizzazione negato.") — no jargon, no codes |
| 10 | Help and Documentation | 2 | No copy explains what altitude/zona climatica feed into, despite driving meteo/cure logic elsewhere |
| **Total** | | **28/40** | **Good** |

## Design Specificity Verdict

**LLM assessment**: Mostly authored, with one hard tell that breaks the illusion. The screen reuses the app's real form vocabulary (`.form-card`, `.slabel`, `.field-label`, `.form-input`, `.btn-sage`/`.btn-ghost`) almost verbatim from `AccountView.vue` — not a generic SaaS panel structurally. But line 9 renders a raw `📍` emoji as the geolocation button's icon — the **only** emoji-as-icon anywhere in `src/views/`, in an app that otherwise draws every icon (including a 45-icon zone system) as a hand-painted ink-pooling watercolor silhouette, with `i-pin` already available in `IconDefs.vue`. That's exactly the "could be any product" signal DESIGN.md's Don'ts warn against — and it lands on the first screen a brand-new user configures right after creating their private garden.

**Deterministic scan**: 4 advisory findings, all confirmed real against DESIGN.md (no false positives):
- Line 14: `var(--border,#ddd)` — undefined token, off-palette gray
- Line 14: `border-radius: 8px` — not on the system's scale (6/11/12/14/20/22/999)
- Line 34: `font-size: 12px` — off the type ramp (11/13/19/26)
- Line 53: `font-size: 12px` — same off-ramp issue, reused pattern

The detector caught two concrete instances (lines 34, 53) the design review didn't cite by number, and independently confirmed the review's line-14 finding plus a fourth off-scale value the review's line-19 (`var(--text-muted,#888)`) call-out didn't catch (detector doesn't flag color-fallback-only lines without a paired radius/font hit) — good complementary coverage between the two passes.

**Visual overlays**: Not available. No browser-automation tool is exposed in this environment, so no live rendering or on-page overlay was possible — this critique is source-only for the visual layer.

## Overall Impression

Structurally sound and functionally generous (three ways to set a location is real craft, not padding), but this is the least-finished corner of an otherwise disciplined system — its one icon is a stock emoji, its two error messages and one dropdown lean on undocumented gray tokens instead of the palette, and a save that quietly feeds meteo and cure-urgency calculations elsewhere in the app ends with nothing: no color change, no confirmation text, no Zorba beat. The biggest opportunity is closing the gap between "this looks like Giardino di Rob" (mostly, via reused `.form-card` patterns) and "this *is* Giardino di Rob" (icon system, token discipline, a save that matters visibly).

## What's Working

- **Three-tier location capture** (device GPS → address search with OSM attribution → manual numeric fallback) is genuine graceful degradation, not decoration — it respects both the "in the garden on mobile" and "desktop planning" contexts PRODUCT.md describes.
- **Auto-filled altitude that stays editable**, with an explicit non-blocking fallback if the altitude lookup fails — resilient without being precious about it.
- **Error copy** throughout is human Italian with no jargon ("Nessun indirizzo trovato.", "Permesso di geolocalizzazione negato.") — heuristic 9 territory, done well.

## Priority Issues

**[P1] Emoji icon breaks the icon system**
- **Why it matters**: DESIGN.md commits the whole app to hand-painted watercolor icons as a signature system. A raw `📍` is the single exception in the entire view tree, and it's on the first screen a new user configures.
- **Fix**: Replace with `<Icon name="pin">` — `i-pin` already exists in `IconDefs.vue`, and `AccountView.vue` already uses the `Icon` component elsewhere in the app.
- **Suggested command**: `/impeccable polish`

**[P1] Off-palette design tokens (colors, radius, font-size)**
- **Why it matters**: `var(--border,#ddd)`, `var(--text-muted,#888)`, an 8px radius, and two 12px font-sizes (lines 14, 19, 34, 53) all fall back to undefined/off-scale values instead of documented tokens — confirmed by both the design review and the detector, with zero false positives.
- **Fix**: Point the dropdown border/radius at `--cream-dark`/`{rounded.input}` (14px) or `{rounded.chip}` (11px), the muted text at `--ink-soft`, and both error-message font-sizes at the 11px label or 13px body step.
- **Suggested command**: `/impeccable polish`

**[P2] Silent save success**
- **Why it matters**: `salva()` resolves and the button just reverts to idle "Salva" with no confirmation — yet these values feed meteo, cure-urgency, and the AI agent's climate heuristic elsewhere in the app. DESIGN.md documents a dedicated "Zorba conferma" pattern for exactly this kind of consequential save, and it's absent here.
- **Fix**: Add a transient sage confirmation (text or the Zorba-confirm beat already used in `HomeView.vue → registra()`) after a successful save.
- **Suggested command**: `/impeccable delight`

**[P2] Broken label association**
- **Why it matters**: `<label class="field-label">` for Latitudine/Longitudine/Altitudine isn't wrapped around or `for`-linked to its input, so a screen reader won't reliably announce the field name on focus. (Pre-existing in `AccountView.vue` too — systemic, not unique to this screen.)
- **Fix**: Add matching `id`/`for` pairs, or wrap each input in its `<label>`.
- **Suggested command**: `/impeccable audit`

**[P3] Address results are mouse-only**
- **Why it matters**: The `<li @click>` address-suggestion list has no `role="option"` or keyboard handling, stranding keyboard users right after a successful search — and both error messages render as plain `<p>` with no `aria-live`, so screen-reader users get no notification when geolocation or save fails.
- **Fix**: Add keyboard interaction to the list items and `role="alert"`/`aria-live="polite"` to the two error paragraphs.
- **Suggested command**: `/impeccable audit`

## Persona Red Flags

**Sam (Accessibility-Dependent)**: Unlabeled-for-AT inputs (lat/lon/altitude), a keyboard-inaccessible address result list, and both error states rendered with no `aria-live` — a screen reader user gets no signal when a geolocation or save error appears.

**Jordan (First-Timer)**: No copy anywhere explains why altitude matters or what zona climatica affects, despite both driving real behavior elsewhere in the app. The emoji button reads as unfinished on a first visit, and the silent post-save state leaves no signal the action worked.

**Riley (Stress-Tester)**: Lat/lon/altitude accept any numeric value with no bounds — a typo like "451" instead of "45.1" would silently corrupt the climate-zone heuristic with zero validation feedback.

## Minor Observations

- Line 12's `position:relative` wrapper is vestigial — the `<ul>` isn't `position:absolute`, so results push content down instead of overlaying it.
- Placeholder text duplicates the adjacent `.field-label` on all three numeric fields.
- The detector's `impeccable detect` run exited 0 despite returning 4 findings — worth a look separately, since the skill's convention is exit 2 when findings are present (a tooling note, not a design finding).

## Questions to Consider

- If this screen's values quietly feed meteo, cure urgency, and the AI agent's climate heuristic, why does saving it feel exactly as consequential as toggling light/dark mode?
- The app draws a watercolor icon for everything else it owns — why does the one raw emoji in the codebase live on the page a brand-new user configures right after creating their private garden?
