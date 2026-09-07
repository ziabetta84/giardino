---
target: AgenteView
total_score: 20
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/AgenteView.vue"
target_fingerprint: "sha256:49cc91a78a92f4f04696ed314868f116515aaffc26521f0aad3ef485bf173c1a"
target_path: /Users/rob/Sites/localhost/giardino/src/views/AgenteView.vue
timestamp: 2026-09-07T10-04-04Z
slug: src-views-agenteview-vue
---
Method: dual-agent (A: general-purpose design review · B: general-purpose detector/browser evidence)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | Gold dot means only "pending" — nothing distinguishes a freshly-completed, unseen answer from one still waiting or already read |
| 2 | Match System / Real World | 3 | Honest in-voice framing ("Zorba dice", "risposta entro pochi minuti") for an async queue |
| 3 | User Control and Freedom | 3 | Can delete requests and switch to "Nuova"; no edit/cancel of a request already in flight |
| 4 | Consistency and Standards | 1 | Custom kebab-menu delete (every other list uses a direct ×); badge color set via inline `:style` instead of the app's `.badge-ok/-warn/-gold` classes; unique "✕" close glyph vs. "×" everywhere else; 7 off-token radii/font-sizes (see detector) |
| 5 | Error Prevention | 2 | 5MB photo-size check is solid; Send disables silently for some type/field combos with no visible reason |
| 6 | Recognition Rather Than Recall | 2 | 7 request-type chips with no description until after picking one — user must recall the difference from label text alone |
| 7 | Flexibility and Efficiency | 2 | No draft persistence (refresh/navigate loses typed text + photo); no way to duplicate a past request as a starting point |
| 8 | Aesthetic and Minimalist Design | 2 | Type picker + conditional selects/extras + textarea + dual photo buttons + send all visible at once, no progressive narrowing |
| 9 | Error Recovery | 2 | Token-expiry message is good; retry-exhaustion after a 409 conflict still surfaces a raw `e.message` |
| 10 | Help and Documentation | 1 | Only 2 of 7 request types get an inline hint; no explanation anywhere of what "elaborazione" actually involves or when to expect it |
| **Total** | | **20/40** | **Acceptable** |

## Design Specificity Verdict

**Partial pass, with one real gap.** Fraunces on titles, hairline-separated history rows, the gold "in-progress" dot, and Zorba's presence in the header are correctly bespoke to this product. But the request-detail view — the moment of literally reading Zorba's answer — is built as an inline content swap with a custom left-sliding drawer (`.hstore`) for history, instead of **"Il Foglio"**, the side/bottom sheet every other data-owning view in this app (Zone, Sottozone, Progetti, Attività, Gallery, Concimi, SelettoreSpecie) uses for exactly this job. The one screen that *is* the AI feature ends up feeling the most generic in the app — closer to a boilerplate support-ticket form than a page of the taccuino.

**Deterministic scan**: `impeccable detect --json` on `AgenteView.vue` → **exit 2**, 8 findings: one `warning` (a gold `border-left: 3px` side-tab accent on the pending-status card, a pattern DESIGN.md doesn't document anywhere — status is normally shown via bg/border-color swap like `.card-urgent`, not an accent strip) and 7 `advisory` design-token-drift findings — border-radii of 8px/10px (off the documented 6/11/12/14/20/22/999px scale) and font-sizes of 15/16/20px (off the documented 11/13/13/19/26px ramp) at lines 483, 493, 513, 529, 545, 560, 573. Sibling imports (`SelettoreSpecie.vue`, `Icon.vue`, `ZorbaLogo.vue`, `Spinner.vue`, `ModalConferma.vue`) scanned clean at `warning` level (exit 0), so this drift is concentrated in AgenteView's own markup, not inherited. This independently corroborates Assessment A's "reinvented primitives" finding — the 20px/15px/16px sizes correspond to unlabeled glyph buttons (×/✕/⋮) styled by hand instead of through the shared `Icon`/button system.

Two of the eight findings are arguable false positives rather than clear defects: the 20px/15px/16px font-sizes size single glyph icons, not prose or labels, so the type-ramp rule may not be the right lens for them; and the gold side-tab border sits on a status card at only 3px using a documented palette token, a fairly restrained use even though it does match the pattern the rule targets. Neither invalidates the underlying observation that this view has more one-off styling than its siblings.

**Visual overlays**: Not available this run. The live dev server (already running, left untouched) redirects any unauthenticated visit straight to `/account` — Assessment B confirmed this by reaching the login screen at `http://localhost:5173/giardino/#/agente` with no valid session, and stopped there per instructions rather than guessing credentials. No script-injected overlay exists in a browser tab; this critique rests on static source analysis plus the deterministic scan, not live rendering, animation timing, or measured contrast.

## Overall Impression

The bones are honest — the async, human-run nature of `/elabora` is narrated in the copy instead of faked with a spinner that implies real-time processing — and the engineering underneath (retry-on-conflict JSON writes, dual camera/library inputs working around an Android capture bug) is genuinely careful. But the screen was clearly built before "Il Foglio" existed as a house pattern and never migrated, so it now reads as the most template-interchangeable view in an otherwise distinctively-authored app, at exactly the screen where the product's actual differentiator (Zorba, the AI assistant woven into real garden data) should feel most alive.

## What's Working

- **`useApi.js`'s retry-on-409 write with an updater function** is solid engineering for a shared JSON file under the GitHub Contents API — it protects a user who fires off several requests in a row from silently losing one to a write conflict.
- **Immediate hand-off to the new request's waiting state on send** — the UI jumps straight to "In attesa di elaborazione…" instead of leaving the user wondering if the tap registered.
- **The dual Libreria/Fotocamera photo inputs** solve a real documented Android capture-intent quirk rather than being cargo-culted boilerplate — a small sign of attention to the actual usage scene (in the garden, on a phone).

## Priority Issues

**[P1] Request detail bypasses "Il Foglio"**
- **Why it matters**: every other data screen in the app opens detail/edit tasks in the shared side/bottom sheet; this one swaps main content and rolls its own history drawer instead, so the screen that *is* the AI feature is the one place the "open a short task without leaving the page" contract breaks. It reads as bolted-on rather than native to the taccuino.
- **Fix**: route request selection and the answer view through `FoglioLaterale.vue`, matching Zone/Sottozone/Progetti/Attività; retire the custom `.hstore` drawer.
- **Suggested command**: `/impeccable shape`

**[P1] No signal for "answered but not yet seen"**
- **Why it matters**: the only status affordance (a gold dot) means "pending." Once an answer arrives there's nothing that distinguishes it from one already read, so a user has to reopen every item to check — for a feature whose whole value is "the AI wrote back," that's a flat emotional payoff.
- **Fix**: track a `visto`/seen flag per request; badge the history toggle with an unread count and give freshly-answered items a distinct visual state until opened.
- **Suggested command**: `/impeccable polish`

**[P2] Seven flat, undifferentiated request-type chips**
- **Why it matters**: the app's own cognitive-load ceiling (≤4 visible options per decision point) is broken 7-to-4 with no grouping, and two of seven types only reveal a usage hint after being selected — a first-timer has to guess up front.
- **Fix**: cluster the 7 types into 2–3 labeled groups (e.g. identificazione/cura, pianificazione, altro) or promote a smart default plus an "altro" expansion, and surface each type's one-line hint before selection, not after.
- **Suggested command**: `/impeccable layout`

**[P2] Off-system primitives instead of shared components**
- **Why it matters**: a kebab-menu delete (unique to this view), a badge colored via inline `:style` instead of `.badge-ok/-warn/-gold`, a "✕" close glyph where the rest of the app uses "×", and 7 detector-confirmed off-scale radii/font-sizes all compound the "not authored for this app" feeling documented in the specificity verdict above.
- **Fix**: replace the kebab menu with the direct-× delete pattern used elsewhere, route the badge through existing status classes, standardize the close glyph, and pull the flagged radii/font-sizes back onto the documented scale.
- **Suggested command**: `/impeccable polish`

**[P3] Touch targets likely under the 44px minimum**
- **Why it matters**: `.reqchip` (7px/11px padding, 11px font) and `.reqsend` (8px/16px padding) read well under the app's own 44px touch-target rule for buttons/pills — a real risk on the mobile-first, in-the-garden usage scene this product is built for.
- **Fix**: raise both to the documented 44px minimum height used by every other button/pill in the system.
- **Suggested command**: `/impeccable audit`

## Persona Red Flags

**Jordan (First-Timer)**: Lands on 7 undifferentiated chips with no upfront explanation of what each does, and no framing of what "risposta entro pochi minuti" actually means in practice (it's a manually-run `/elabora` command, not a live model call — could be minutes or much longer). Picks a type, finds Send disabled, gets no reason why. Likely abandons at the first friction point rather than guessing.

**Riley (Stress Tester)**: Attaches a near-5MB photo, sends, then fires 2–3 more requests before the first resolves — each write re-serializes the entire growing JSON queue (including any still-embedded base64 from unprocessed prior requests) over the GitHub Contents API with only a spinner for feedback. Pastes a long block of text into the message field or detail view with no length cap or overflow handling to test it.

## Minor Observations

- `labelStato()` renders raw ✓/✗/○ characters instead of the app's `Icon` SVG system — reads off-brand next to the hand-drawn iconography used everywhere else.
- History rows are anchors with `role="button"` and manual keydown handling rather than native `<button>` elements — extra accessibility surface maintained for no real benefit.
- Selected-item state (`.hitem.on`) is conveyed by background tint alone, with no `aria-current` for assistive tech.
- The gold `border-left` accent on the pending-status card (detector's one `warning`) isn't necessarily wrong on its own, but it's a pattern DESIGN.md doesn't document anywhere else in the app — worth deciding once whether accent-strip status cards are in the system or not, rather than letting it stand as a one-off.

## Questions to Consider

- If every other CRUD view in this app already migrated to "Il Foglio," why is the one screen that's literally the AI feature still running a bespoke drawer — is this simply a view built before the pattern existed and never revisited?
- Given answers can take anywhere from minutes to much longer via a manually-run command, should this screen lean fully into an honest "we'll notify you" framing (unread badge, maybe a subtle browser/PWA notification) instead of implying near-live polling?
- Is the kebab-menu delete here solving a real problem the direct-× pattern doesn't (e.g. protecting against accidental deletion of an AI answer), or is it just drift?
