---
title: Splash.gd / Splash.tscn
type: script+scene
script_path: scripts/Splash.gd
scene_path: scenes/Splash.tscn
lines: 197
extends: Control
---

# Splash.gd

Entry point scene. 4.15-second animated logo intro before loading `Main.tscn`.

## Animation Sequence
| Phase | Timing | Action |
|-------|--------|--------|
| 1 | 0.0–0.55s | Fade in from black |
| 2 | 0.4–1.0s | Four corner dots fly in (elastic easing) |
| 3 | 1.1–1.28s | Center purple dot pops in (scale bounce 1.0→1.3→1.0) |
| 4 | 1.35–1.75s | Title slides up (cubic easing) |
| 5 | 1.8–2.2s | Tagline fades in |
| 6 | 2.3–3.1s | Center dot gentle pulse (twice) |
| 7 | 3.6–4.15s | Fade to black → load Main.tscn |

## Visual Elements
- Background: dark void (`#051E28`)
- Four 136px corner dots: Red, Blue, Green, Yellow
- Center 116px purple dot with ring
- Title: "Guess the Dots" (72pt)
- Tagline: "Find the hidden pattern" (36pt)

## Key Methods
- `_build_and_animate()` — construct all nodes and run sequence
- `_make_dot(color, radius, with_ring)` → Panel — circular dot helper
