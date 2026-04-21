---
title: Splash.gd / Splash.tscn
type: script+scene
script_path: scripts/Splash.gd
scene_path: scenes/Splash.tscn
lines: 196
extends: Control
last_updated: 2026-04-20
---

# Splash.gd

Entry point scene. ~2.5-second animated logo intro before loading `Main.tscn`. Pastel-restyled in Task 20.

## Animation Sequence (Post-Restyle)
| Phase | Timing | Action |
|-------|--------|--------|
| 1 | 0.0–0.35s | Fade in from `#FFF1F9` |
| 2 | 0.25–0.65s | Four corner dots fly in (elastic easing) |
| 3 | 0.7–0.9s | Center purple dot pops in (scale bounce) |
| 4 | 0.9–1.3s | Title slides up (cubic easing) |
| 5 | 1.2–1.6s | Tagline fades in |
| 6 | 1.6–2.4s | Center dot gentle pulse |
| 7 | 2.1–2.5s | Fade to `#FFF1F9` → load Main.tscn |

## Visual Elements (Pastel)
- Background: `#FFF1F9` (pastel pink-white)
- Fade overlay: `#FFF1F9` (white fade, not black)
- Corner dots: `#FFB3C1` (red), `#B3D4FF` (blue), `#B3F5C3` (green), `#FFF2B3` (yellow)
- Center dot: `#E0B3FF` (purple)
- Title: "Guess the Dots" (72pt, `#6B4E71`)
- Tagline: "Find the hidden pattern" (36pt, `#9B7EA6`)

## Key Methods
- `_build_and_animate()` — construct all nodes and run sequence
- `_make_dot(color, radius, with_ring)` → Panel — circular dot helper
