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

## Game Mode Enum (Implemented — 2026-04-20)
```gdscript
enum GameMode { CLASSIC, BLITZ, HARD, ZEN, CAMPAIGN, EASY }
```
> [!note] Planned but not yet implemented: MYSTERY, TIME_TRIAL, DUO, SUDDEN_DEATH, SANDBOX

## Key State Variables
| Variable | Type | Purpose |
|----------|------|---------|
| `secret_sequence` | `Array[int]` | Hidden code |
| `current_guess` | `Array[int]` | In-progress attempt |
| `guess_history` | `Array[Dictionary]` | All prior guesses + feedback |
| `current_mode` | `GameMode` | Active mode |
| `round_active` | `bool` | Guessing allowed |
| `haptics_enabled` | `bool` | Vibration |
| `_board_rows` | `Array` | Dicts `{container, slots, pips, index}` |
| `_active_row_index` | `int` | Current guess row |
| `_board_built` | `bool` | Guard for board rebuild |
| `_result_sheet_open` | `bool` | Double-call guard for `_finish_game` |
| `_pending_xp` | `int` | XP staged for result display |
| `_pending_coins` | `int` | Coins staged for result display |
| `_hint_used_this_round` | `bool` | Prevents double hint per round |
| `_hard_locked_slots` | `Array` | Exact slot indices locked in Hard mode |
| `_tracker_absent` | `Dictionary` | Colors confirmed absent (tracker) |
| `_tracker_present` | `Dictionary` | Colors confirmed present (tracker) |

## History Entry Format (Canonical)
```gdscript
{"values": Array[int], "exact": int, "misplaced": int, "per_dot": Array}
# per_dot entries: "exact" | "misplaced" | "absent"
```

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

## Bottom Sheet System (Implemented)
- `_build_bottom_sheet(title, on_close: Callable = Callable()) -> Control` — slide-up from bottom, overlay tap calls `on_close` then `_close_bottom_sheet`
- `_close_bottom_sheet(overlay, sheet)` — parallel 0.25s slide+fade, `tw.finished.connect` for `queue_free`
- Overlay stored as `sheet.set_meta("overlay", overlay)` — retrieve with `sheet.get_meta("overlay")`

## Sheet-Based Screens (Implemented)
- `_show_result_sheet(did_win, guesses_used)` — replaces old `result_layer` popup
- `_open_settings_sheet()` — `⋯` button; New Round + Main Menu + How to Play + toggles
- `_open_mode_select()` — 2-column card grid (CLASSIC, BLITZ, HARD, ZEN, CAMPAIGN, EASY)
- `_open_custom_puzzle_create()` — build a puzzle
- `_open_custom_puzzle_code_sheet()` — enter GTD-XXXX code

## Related
- [[entities/ComboManager]] — combo tracking
- [[entities/ShopManager]] — token consumption
- [[entities/SeasonManager]] — XP reporting
- [[concepts/game-modes]] — all mode rules
- [[concepts/pastel-theme]] — visual tokens
