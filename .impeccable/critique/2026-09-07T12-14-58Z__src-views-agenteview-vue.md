---
target: AgenteView
total_score: 31
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 1
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/AgenteView.vue"
target_fingerprint: "sha256:acb20b63b473a35ef621a3b6721c98cf5bf5a4f758e6fb584870b843a2448951"
target_path: /Users/rob/Sites/localhost/giardino/src/views/AgenteView.vue
timestamp: 2026-09-07T12-14-58Z
slug: src-views-agenteview-vue
---
Method: dual-agent (A: general-purpose design review · B: general-purpose detector/browser evidence)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | The pending "in attesa" dot is static — no pulse or motion to sell "actively working" |
| 2 | Match System / Real World | 4 | Solid — Italian, garden-specific labels, honest per-type hints |
| 3 | User Control and Freedom | 3 | No edit/cancel of a pending request; a draft field can silently survive a type switch (see P1) |
| 4 | Consistency and Standards | 2 | Page header (`.agente-h1`, 23px) diverges from `.page-title` (26px) used by every other view; a request-type label renders in Fraunces though it's a category, not a name |
| 5 | Error Prevention | 3 | Real gap: switching request type doesn't clear irrelevant fields, so a hidden photo/message can ride into an unrelated submission |
| 6 | Recognition Rather Than Recall | 4 | Solid — per-type hint text and adaptive placeholder |
| 7 | Flexibility and Efficiency | 3 | No way to duplicate a past request as a starting template |
| 8 | Aesthetic and Minimalist Design | 3 | `pianifica_progetto` stacks select + input + textarea in one screenful |
| 9 | Error Recovery | 3 | Clear, distinct banners for token-missing and send errors |
| 10 | Help and Documentation | 3 | Inline hints are adequate for an Operate-mode screen |
| **Total** | | **31/40** | **Good** |

Up from 20/40 on the previous pass — the sheet migration, chip grouping, badge/delete cleanup and touch-target fixes all held up under a fresh, independent look.

## Design Specificity Verdict

**Mostly specific now, with two loose threads.** The 3-group chip restructuring, Zorba's header presence, and the history list's verbatim reuse of `FoglioLaterale`/`.feedlist`/`.feed__del` are genuinely authored for this app and were confirmed working as designed. Two details still undercut the "authored for Giardino di Rob" feeling: the page header uses a bespoke `.agente-h1` at 23px instead of the shared `.page-title` (26px) every other view uses, with no stated reason; and the subtitle plus the waiting banner both say **"Claude Code"** by name ("Elaborato da Claude Code…", "In attesa di elaborazione da Claude Code…") — breaking the "Zorba dice" fiction one line after establishing it. For a screen whose entire job is to *be* the AI-assistant voice, naming the underlying tool reads as an implementation leak, not a deliberate transparency choice.

**Deterministic scan**: `impeccable detect` on `AgenteView.vue` → exit 0, only the same 2 `advisory` findings as before (font-size 20px on the two bare "×" glyph buttons at lines 513/549) — both still read as legitimate icon-glyph sizing, not typographic drift, and are unchanged from the prior pass. Sibling imports (`Icon`, `Spinner`, `ModalConferma`, `FoglioLaterale`) scanned clean. `ZorbaLogo.vue` and `SelettoreSpecie.vue` carry their own pre-existing advisory findings (an undocumented color that's part of Zorba's intentional artwork exception, and several findings that belong to `SelettoreSpecie`'s separate, already-known redesign branch) — neither is attributable to this round's work on `AgenteView.vue`.

One disagreement worth surfacing: the design review flagged `.answer__body`'s `border-left: 2px solid var(--sage)` as matching DESIGN.md's named "side-tab" ban (the same class of pattern flattened on `.agente-attesa` earlier this session). The deterministic detector does **not** flag it, even when run directly against `main.css` — likely because it reads as a blockquote-style rule on a block of quoted answer text (no card background/padding/radius around it), not the status-card accent stripe the rule targets. I'd call this a plausible false positive rather than a repeat of the `.agente-attesa` issue, but it's close enough to the letter of the named rule to be worth your own call rather than mine.

**Visual overlays**: not available again — the dev server correctly redirected to the login screen without a session, confirming the auth gate works as intended. No live rendering or overlay exists for this pass either; everything above rests on source analysis plus the deterministic scan.

## Overall Impression

This is a real improvement over the last pass: the score moved from 20/40 (Acceptable) to 31/40 (Good), and the specific structural complaints from before — the bespoke drawer, the flat 7-chip wall, the kebab menu, the off-scale radii — are all gone and stayed fixed under independent re-inspection. What's left is smaller-grained: a genuine correctness bug in how the compose form resets between request types, and two voice/consistency details (the header scale, the "Claude Code" copy) that are quick to fix and would close the gap between "well-structured" and "fully in character."

## What's Working

- The 3-group, ≤3-chip restructuring (`GRUPPI_TIPO`) verifiably fixed the cognitive-load overload from before while keeping every chip at a 44px touch target.
- History now reuses `FoglioLaterale` and the shared `.feedlist`/`.feed__del` bare-× pattern exactly as it's used in ConcimiView/PianteView — no bespoke drawer, no redundant close control.
- Per-type adaptive hint and placeholder text give real discoverability (recognition-over-recall heuristic scored a clean 4) without adding extra chrome.

## Priority Issues

**[P1] Switching request type doesn't clear irrelevant fields**
- **Why it matters**: `fotoBase64`/`fotoPreview`/`nuovoMessaggio` aren't reset when the chip changes, and `aggiungiRichiesta` unconditionally sends `foto: fotoBase64.value ?? null` regardless of type. A photo attached while `diagnosi` was selected can silently ride along into a `revisione_specie` or `pianifica_progetto` submission the user never sees, since those types hide the photo UI entirely.
- **Fix**: reset `nuovoMessaggio`, `fotoBase64`, `fotoPreview`, `nomeFile`, `specieSelezionata`, `progettoSelezionato`, and `nuovoProgettoTitolo` whenever the type chip changes.
- **Suggested command**: `/impeccable harden`

**[P2] "Claude Code" breaks the Zorba voice**
- **Why it matters**: the subtitle and the waiting banner both name the underlying tool directly, one line under "Zorba dice" — a jarring implementation leak for what should read as a cat oracle, not a dev-tool status line, and it undermines the product's own stated principle that the AI assistant should always feel connected to the garden, not like a bolted-on satellite feature.
- **Fix**: rewrite both lines in Zorba's voice, e.g. "Zorba risponde di solito entro pochi minuti" and "In attesa che Zorba risponda…".
- **Suggested command**: `/impeccable clarify`

**[P2] Page header off the shared type scale**
- **Why it matters**: `.agente-h1` renders at 23px while every other view's `<h1>` uses `.page-title` at 26px, with no stated reason for the difference — a small but real consistency gap on the exact rule (shared type scale) the last pass was fixing elsewhere in this same file.
- **Fix**: bring `.agente-h1` to the same 26px/600/1.05 as `.page-title`, keeping its flex layout so the Zorba icon can sit inline (which `.page-title` alone doesn't support).
- **Suggested command**: `/impeccable typeset`

**[P3] Static "in attesa" indicator**
- **Why it matters**: the pending dot never moves, which undersells that something is actually happening in the background — a cheap, low-risk win given the app already has an established "character animation" budget (spinner, shimmer) outside the state-transition system.
- **Fix**: give `.adot` a subtle looping opacity/scale pulse, disabled under `prefers-reduced-motion` like the rest of the app's character animations.
- **Suggested command**: `/impeccable animate`

## Persona Red Flags

**Jordan (First-Timer)**: "Elaborato da Claude Code" reads as unexplained jargon directly under a friendly cat-mascot line. Picking between "Consiglio per cura" and "Diagnosi problema" (both in the same "Cura" group) doesn't feel reversible once sent, since answers arrive minutes later with no way to re-route a misclassified request.

**Alex (Power User)**: The history list in Il Foglio has no date grouping or filter by type/status as it grows — unlike Home's "Da fare oggi" grouping elsewhere in this same app — and there's no way to duplicate a past request (e.g. a repeated `revisione_specie` check) as a starting point instead of retyping it.

## Minor Observations

- Compose-time photo preview is 40px; the detail view caps the attached photo at 200px with no tap-to-enlarge — thin for judging a `diagnosi` photo closely.
- `richieste-agente.json` remains unscoped per-user (documented, known limitation) — this view has no author attribution should it ever go fully multi-user.
- `.agente-dettaglio-tipo` renders the request-type label ("Identifica da foto", "Diagnosi problema"…) in Fraunces; per the app's own "name in Fraunces" rule this is a category label, not an entity name, so DM Sans may be the more consistent choice — low-impact, worth a look during a typography pass.
- The detector's own exit-code convention returned `0` even with 2 advisory findings present (only `severity: warning`/error findings appear to flip it to `2`) — a tooling nuance, not a codebase issue, but worth knowing when reading future scans.

## Questions to Consider

- Is naming "Claude Code" in user-facing copy deliberate transparency (useful for a single developer-owner) or an accidental leak that should stay in-voice regardless of who's logged in?
- Should Il Foglio's history list date-group entries the way Home groups "Da fare oggi," once the queue grows past a screenful?
- Given a freshly-sent request can take longer than "pochi minuti," should composing a new request while one is still pending be blocked, or does letting both coexist (current behavior) better match how people actually use it?
