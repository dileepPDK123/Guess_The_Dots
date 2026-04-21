---
title: Main.gd
type: script
path: scripts/Main.gd
lines: ~2600 (post ui-rework)
extends: Control
branch: feature/ui-rework
last_updated: 2026-04-20
---

# Main.gd

Core game controller. Manages all game state, UI rendering, game modes, and orchestrates all systems.

## Game Mode Enum (Updated)
```gdscript
enum GameMode {
    CLASSIC, EASY, BLITZ, HARD, ZEN, CAMPAIGN,
    MYSTERY, TIME_TRIAL, DUO, SUDDEN_DEATH, SANDBOX
}
```

## Key State Variables
| Variable | Type | Purpose |
|----------|------|---------|
| `secret_sequence` | `Array[int]` | Hidden code |
| `current_guess` | `Array[int]` | In-progress attempt |
| `guess_history` | `Array[Dictionary]` | All prior guesses + feedback |
| `current_mode` | `GameMode` | Active mode |
| `round_active` | `bool` | Guessing allowed |
| `haptics_enabled` | `bool` | Vibration |
| `_comeback_active` | `bool` | Silent difficulty reduction |
| `_hint_used_this_round` | `bool` | Breaks combo if true |

## Visual System (Reworked)
- Theme: Soft Pastel — see [[concepts/pastel-theme]]
- Slot shape: rounded squares (not circles)
- Wordle-style board: all rows static, current row highlighted
- `_apply_theme()` applies pastel tokens
- `_apply_label_vocabulary()` uses plain English (SUBMIT, CLEAR, UNDO, HINT)
- No hex shader background

## Board Architecture (New)
- All rows pre-rendered at once (past + active + future)
- Past rows: white glass, dots filled, pips visible
- Active row: `ACTIVE_ROW` fill + `ACTIVE_BORDER`
- Future rows: `opacity 0.15–0.25`, faint dashed outlines
- On submit: flip animation (80ms stagger per dot, left-to-right)

## Feedback Modes
- Classic/Hard/Blitz/Zen/Campaign/Daily/Mystery/Time Trial/Duo/Sudden Death: count-only pips
- Easy/Sandbox: per-dot colored rings (green = exact, yellow = misplaced)

## New Features Wired In
- **Flip animation** — Tween-based on submit
- **Color elimination tracker** — strip between board and palette, auto-updates after each guess
- **Smart Hint** — eliminates absent color (not slot reveal), calls `ShopManager.consume_hint_token()` first
- **Blitz ring timer** — SVG ring depleting, red pulse ≤15s
- **Hard lock badges** — padlock + pulse on confirmed exact slots in Hard mode
- **Win celebration** — dot burst particle scatter on win
- **Reaction messages** — context-aware header text after each guess
- **Dot trail** — Line2D color smear during drag
- **Combo UI** — 🔥 icon in header, reads from `ComboManager`
- **Resume prompt** — shown on launch if `SaveData.resume_secret` non-empty
- **Comeback mechanic** — silently adjusts difficulty after 3 losses

## Overlay / Screen Methods (Updated)
- `_build_mode_select()` — 2×3 grid + Weekly Challenge card + Custom Puzzle link
- `_build_stats_screen()` — Stats + Deep Dive section + Archive button
- `_build_rewards_screen()` — Shop tab + Season tab
- `_build_campaign_screen()` — unchanged logic, pastel restyle
- `_build_hamburger_menu()` — replaced by `⋯` bottom sheet with Color-Blind toggle

## Result Screen (New)
- Full bottom sheet (not popup)
- Contains: result title, secret reveal, XP/coins, dot burst, share button, combo display
- XP doubler offer shown here

## New Mode Dispatch
- Mystery: `_start_mystery_mode()`
- Time Trial: `_start_time_trial()`
- Duo: `_start_duo_mode()`
- Sudden Death: `_start_sudden_death()`
- Sandbox: `_start_sandbox()`

## Related
- [[entities/ComboManager]] — combo tracking
- [[entities/ShopManager]] — token consumption
- [[entities/SeasonManager]] — XP reporting
- [[concepts/game-modes]] — all mode rules
- [[concepts/pastel-theme]] — visual tokens
