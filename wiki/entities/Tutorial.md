---
title: Tutorial.gd
type: script
path: scripts/Tutorial.gd
lines: 921
extends: Control
---

# Tutorial.gd

15-slide interactive onboarding. Can be skipped on first launch or replayed from the in-game hamburger menu.

## Signal
- `tutorial_finished` — emitted on complete or skip

## Slide Map
| # | Title / Theme |
|---|---------------|
| 0 | Welcome — color dots intro (5 colors animate in) |
| 1 | The encrypted sequence (mystery dots) |
| 2 | Node placement mechanics (palette → slots arrow diagram) |
| 3 | Green ◆ = LOCKED (exact position feedback) |
| 4 | Yellow ◆ = MISPLACED (wrong slot feedback) |
| 5 | NULL SIGNAL = no match |
| 6 | Intel briefing (6 gameplay tips) |
| 7 | Simulation intro (3 mystery dots) |
| 8 | Attempt 1 — placing demo |
| 9 | Attempt 1 — feedback result |
| 10 | Attempt 2 — placing demo |
| 11 | Attempt 2 — feedback result |
| 12 | Attempt 3 — placing demo (final) |
| 13 | Sequence decoded (win screen) |
| 14 | Agent initialized (final tips) |

## UI Components
- Progress bar with label "X / 15"
- Scrollable content area
- SKIP BRIEFING button (left)
- PROCEED → / INITIALIZE ▶ button (right)

## Key Methods
- `start()` — show overlay, go to slide 0
- `_show_slide(index)` — fade out → build → fade in
- `_build_page(index)` — routes to slide-specific builder
- `_add_demo_board(attempt, show_result)` — simulation board
- `_dot_panel(color, size)` / `_empty_slot_panel(size)` / `_mystery_dot(size)` — visual helpers
