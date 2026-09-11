---
target: HeroAiuola.vue
total_score: 14
max_score: 20
na_heuristics: 3,6,7,9,10
p0_count: 0
p1_count: 2
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/components/HeroAiuola.vue"
target_fingerprint: "sha256:00f2f897d24198eb968fbf3747a48aca923aa50260a66349ea3ca8ae7f749756"
target_path: /Users/rob/Sites/localhost/giardino/src/components/HeroAiuola.vue
timestamp: 2026-09-11T06-49-40Z
slug: src-components-heroaiuola-vue
---
# Critique: `src/components/HeroAiuola.vue`

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3/4 | Fade-in reveal runs on a fixed mount timer, not the image's actual `load` event. |
| 2 | Match Between System and Real World | 4/4 | Real seasons, real day/night, gate motif echoes login copy. |
| 3 | User Control and Freedom | n/a | No user-initiated action inside this component. |
| 4 | Consistency and Standards | 2/4 | One AI-raster element in an otherwise hand-authored vector system; DESIGN.md documents the previous implementation. |
| 5 | Error Prevention | 3/4 | Correct alt/aria-hidden handling; no onerror fallback for a failed WebP load. |
| 6 | Recognition Rather Than Recall | n/a | Not applicable to a decorative hero. |
| 7 | Flexibility and Efficiency of Use | n/a | No end-user interaction surface here. |
| 8 | Aesthetic and Minimalist Design | 2/4 | Paintings are attractive in isolation; greeting text has no reliable legibility protection against them. |
| 9 | Help Recognize/Diagnose/Recover from Errors | n/a | No error states in this component. |
| 10 | Help and Documentation | n/a | Not applicable to a decorative hero. |
| **Total** | | **14/20** | **Good (70%)** |

## Design Specificity Verdict

Real swap of rendering technology inside one component (line-art SVG -> 8 AI-generated paintings), not a redesign of the surface: same slot, same overlay contract, same event contract into HomeView.vue. Day/night as two distinct paintings (vs. the previously tried-and-rejected veil approach) is a genuine craft upgrade. Gate motif ties directly to login copy. Zorba stays strictly vector, never painted into the illustrations — correct per DESIGN.md's "Regola di Zorba Nero".

Deterministic scan: `impeccable detect --json` on HeroAiuola.vue itself: exit 0, zero findings. Same scan on src/assets/main.css (app-wide, not component-scoped): 11 advisory findings (off-palette colors, off-scale radii/sizes), not confirmed to touch selectors this component uses.

Visual overlays: app is auth-gated; live browser injection was skipped rather than passing credentials into a sub-agent. Five real screenshots from this session (desktop/mobile x giorno/notte, plus a clean primavera-notte reference) were used as the documented fallback.

## Overall Impression

The technique upgrade is a real win (primavera-notte proves the ceiling is high), but two convergent findings pull it back from "ready to show a sponsor": greeting text has no dependable protection against the new, busier artwork, and the two already-accepted imperfections are live on today's real season (autunno), not a future edge case.

## What's Working

1. Zorba stayed vector on purpose — no AI-generation risk on the one brand-critical element.
2. Two real paintings instead of one scene + a tint solves a documented, previously-rejected problem; primavera-notte is proof the ceiling is high.
3. Reduced-motion and decorative-alt handling are both done correctly, without exception carve-outs.

## Priority Issues

**[P1] Greeting text has no reliable legibility guarantee against the new paintings.**
Why it matters: Both assessments independently found this — the text-legibility scrim in main.css fades to transparent by 40% of the hero's width, but `.hero__txt` runs to 70% max-width; on mobile, "Buongiorno, Rob" sits directly over flower artwork with no protection, unlike the stat pills which carry their own opaque fill. A regression introduced this session when the scrim's reach was narrowed to reveal more of the painting.
Fix: Extend the scrim's reach to match `.hero__txt`'s actual max-width, or give `.greet`/`.date` their own self-contained protection (text-shadow or soft backdrop) like the pills already have.
Suggested command: /impeccable polish

**[P1] The two accepted imperfections are live for every visitor this week, not a future edge case.**
Why it matters: Today's real season is autunno, so the closed-reading gate and cropped moon are the current default state, not a hypothetical — including for the sponsorship-pitch audience CLAUDE.md names explicitly. The gate exists specifically to echo "Lascia entrare Zorba in giardino," which it currently contradicts on the live season.
Fix: Not reopening the defer decision, but re-costing it against "this is on screen this week." A targeted touch-up of just the autunno-giorno gate is far cheaper than a full regeneration round.
Suggested command: /impeccable polish

**[P2] Zorba reads as a flat sticker on top of a directionally-lit painted scene.**
Why it matters: The paintings have real implied light; the SVG cat has no shadow/rim-light response to season or time of day — most visible in giorno captures.
Fix: A light-aware treatment per variant — soft warm contact shadow for giorno, the pale-halo rule DESIGN.md already prescribes for dark mode as the notte treatment.
Suggested command: /impeccable polish

**[P2] Autunno-notte and primavera-notte read as near-duplicate compositions.**
Why it matters: Nearly identical gate placement, cat pose, and teal night palette; differentiation is mostly which flowers are painted, undercutting the premise that each season should feel distinct.
Fix: Direct any future generation budget at compositional variety (sky treatment, path angle, flower massing), not only bug fixes.
Suggested command: /impeccable polish

**[P3] Image reveal isn't synced to actual load, and the asset is heavy for a mobile-first, field-use product.**
Why it matters: Fade-in triggers on a fixed mount timer rather than the image's load event (blank-then-pop on slow connections); no onerror fallback. ~330KB average WebP at 1536x1024 for a container rarely wider than ~920px, fetchpriority="high" on the likely LCP element, for a product whose primary context is mobile-in-the-field.
Fix: Swap the timer-based reveal for the image's load event with a short fallback timeout; add a basic onerror class; reconsider source dimensions/quality against actual render size if these assets are touched again.
Suggested command: /impeccable optimize

## Persona Red Flags

**The agency sponsor evaluator**: highest-stakes viewer, will land on autunno-giorno this week — the one variant where the hero's central emotional beat visibly fails.

**Field user on a real device, mid-task**: the legibility gap is someone glancing at their phone in bright outdoor light while gardening, exactly where marginal text-over-image contrast fails first.

**A new multi-tenant user's first cold load**: no prior SW cache, full ~330KB fetch plus blank-to-pop load behavior, on a first impression meant to feel considered.

## Minor Observations

- DESIGN.md's "L'Aiuola" section still documents the old procedural ink-redraw behavior — now factually stale.
- The two breakpoint-specific min-height values (232px/544px) are empirically tuned to today's 8 paintings, not derived from anything durable; silently fragile if images are regenerated.
- A soft cloud sits immediately adjacent to the painted sun in the desktop-giorno capture — likely intentional, worth one conscious look.
- Within autunno, the gate reads closed in giorno and open in notte — an inconsistency inside one season.
- The main.css-wide detector advisories (11 findings) were not confirmed to touch selectors this component uses — a main.css housekeeping item, not a finding against HeroAiuola.vue.

## Questions to Consider

1. Is "redraws with the season" still the right story now that the scene is 8 fixed paintings instead of a procedural system?
2. Should the gate get the same protected, hand-finished treatment as Zorba, being the one other story-critical prop in the scene?
3. Does the scrim/text-legibility approach need to become per-element protection now that the backdrop is a busy painting instead of a pale flat scene?
