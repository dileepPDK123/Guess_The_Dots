---
title: UI Rework Implementation
source_type: implementation-session
ingested: 2026-04-20
branch: feature/ui-rework
tasks_completed: 1–21
base_commit: e098a6c
final_commit: cf12cd5
---

# Source: UI Rework Implementation (2026-04-20)

Full implementation of the UI rework plan `docs/superpowers/plans/2026-04-19-ui-rework.md` across Tasks 1–21. Branch: `feature/ui-rework`.

## What Was Built

### Visual Foundation (Tasks 1–4)
- 15 pastel color tokens defined as constants in `Main.gd` (`C_BG`, `C_SURFACE`, `C_TEXT_PRIMARY`, `C_PIP_EXACT`, etc.)
- Plain English button labels: SUBMIT, CLEAR, UNDO, HINT (no cyberpunk vocabulary)
- `SlotButton` and `ColorDotButton` updated with `set_filled_visual()`, `set_empty_visual()` methods
- `_style_panel_glass()` helper: white glass `rgba(1,1,1,0.97)` + `#FFD6E7` border + corner 16

### SaveData Additions (Task 5)
New fields added and persisted in `save_data.cfg`:
- `colorblind_enabled: bool`
- `sound_enabled: bool`
- `easy_wins: int`
- `custom_puzzles_played: int`
- `daily_best_time_ms: int`
- `guess_distribution_classic: Array` (10 slots)
- `guess_distribution_easy: Array` (10 slots)
One-time migration from old `user://settings.cfg` (haptics value).

### Wordle Board (Task 6)
- All rows pre-rendered at game start via `_build_wordle_board()`
- Row state dict: `{container, slots, pips, index}`
- State vars: `_board_rows: Array`, `_active_row_index: int`, `_board_built: bool`
- Row visual states: past (filled, pips), active (highlighted), future (faded 0.15 alpha)
- History entry format (canonical): `{"values": Array[int], "exact": int, "misplaced": int, "per_dot": Array}`

### Flip Animation (Task 7)
- `_flip_row_reveal(row, item)` — 80ms stagger per dot, left-to-right
- Scale 1→0 (face down) then 1→1 (face up with color)
- `is_instance_valid()` guards after every `await`
- `_on_submit_pressed()` awaits flip before advancing row pointer

### Elimination Tracker (Task 8)
- `_build_elimination_tracker()` — strip of color dots between board and palette
- `PanelContainer` + `StyleBoxFlat` (corner_radius 999) for circular dots
- `_update_elimination_tracker()` — marks absent (grey) / present (colored)
- State: `_tracker_absent: Dictionary`, `_tracker_present: Dictionary`

### Smart Hint (Task 9)
- `_grant_hint() -> bool` — reveals an absent color in tracker (not a slot)
- Only reveals colors not in `secret_sequence` and not already in `_tracker_absent`
- `_hint_used_this_round: bool`, `_hint_ad_pending: bool` guard double-invoke

### Blitz Ring Timer (Task 10)
- Inner class `_BlitzRingControl extends Control` — `_draw()` renders arc + countdown
- `progress: float` (1.0→0.0), `is_critical: bool` (turns red ≤15s)
- Uses `ThemeDB.fallback_font` with null guard

### Dot Burst (Task 11)
- `_trigger_dot_burst()` — 14 `PanelContainer` circle particles scatter from board center
- `tw.finished.connect(dot.queue_free)` (not `tween_callback.set_delay`)
- `board_rect.size == Vector2.ZERO` guard before reading layout

### Color-Blind Mode (Task 12)
- `ColorDotButton.apply_colorblind(enabled, shape_char)` — overlays shape label
- `COLORBLIND_SHAPES` array with bounds check

### DailyChallenge Share (Task 13)
- `build_share_text_general(mode_name, guess_history, secret, did_win, max_guesses)` added
- Uses `item["values"]` (dict access), per-dot emoji (🟢/🟡/⬛)

### Custom Puzzle (Task 14)
- `_open_custom_puzzle_create()` — bottom sheet to design puzzle
- `_open_custom_puzzle_play(code)` — GTD-XXXX decode + start
- `_build_bottom_sheet(title, on_close)` minimal version added here (enhanced in Task 16)

### Hard Mode Lock Badges (Task 15)
- `_add_lock_badge(row_index, slot_index)` — 🔒 Label child on slot
- `_hard_locked_slots: Array` tracks confirmed exact positions
- `_apply_active_row()` pre-fills locked slots and marks `MOUSE_FILTER_IGNORE`

### Result Bottom Sheet (Task 16)
- `_build_bottom_sheet(title, on_close: Callable = Callable()) -> Control` — slide-up animated
- `_close_bottom_sheet(overlay, sheet)` — parallel fade + slide down, `tw.finished.connect`
- `_show_result_sheet(did_win, guesses_used)` — secret reveal row, XP/coins label, share btn, Play Again + Menu
- `_result_sheet_open: bool` guard (replaces `result_layer.visible` check)
- Overlay stored in sheet metadata: `sheet.set_meta("overlay", overlay)`

### Settings Bottom Sheet (Task 17)
- `hamburger_button.text = "⋯"` — connects to `_open_settings_sheet()`
- Sheet contains: New Round, Main Menu, How to Play buttons + Color-Blind + Haptics toggles
- Old `haptics_toggle.toggled` wiring removed to prevent double-fire

### Mode Select Bottom Sheet (Task 18)
- `_open_mode_select()` — 2-column `GridContainer` of mode cards
- Cards: CLASSIC, BLITZ, HARD, ZEN, CAMPAIGN (EASY added in Task 19)
- Card tap: `get_tree().create_timer(0.3).timeout.connect(..., CONNECT_ONE_SHOT)` — avoids `await` in freed-node lambda
- `_open_custom_puzzle_code_sheet()` — LineEdit + Play button

### Easy Mode (Task 19)
- `GameMode.EASY` added to enum (only EASY — not the other planned modes)
- `start_new_game(EASY)`: `slots_needed = randi_range(3,4)`, `MAX_GUESSES = 10`, 5 colors
- `_evaluate_guess()` now computes and returns `per_dot: Array` ("exact"/"misplaced"/"absent")
- `_apply_past_row()` calls `_apply_dot_ring(slot, state)` for Easy mode
- `SaveData.easy_wins` incremented on win; nudge toast at 3: "Ready for Classic?"

### Splash Restyle (Task 20)
- Background: `#FFF1F9` (pastel white)
- Dot colors: `#FFB3C1`, `#B3D4FF`, `#B3F5C3`, `#FFF2B3`, `#E0B3FF`
- Fade overlay: `#FFF1F9` (white, not black)
- Total animation compressed to ~2.5s (from 4.15s)
- Title text: `#6B4E71`, tagline: `#9B7EA6`

### Tutorial Restyle (Task 21)
- Background: `#FFF1F9`
- Main card: white glass `rgba(1,1,1,0.97)` + `#FFD6E7` border + radius 24
- Progress bar: track `#FFD6E7`, fill `#E0B3FF`
- Skip button: `#F5E6FA` bg, `#9B7EA6` text
- Next button: `#E0B3FF` bg, `#6B4E71` text
- `_ps()` helper border_color updated to `#FFD6E7`

## What Was NOT Implemented (Spec vs Reality)
- `GameMode` enum: only EASY added; MYSTERY, TIME_TRIAL, DUO, SUDDEN_DEATH, SANDBOX not yet implemented
- `_start_mystery_mode()`, `_start_time_trial()` etc. not added
- Simulated Daily leaderboard (plan section end note) not implemented
- Dot trail (Line2D drag smear) not implemented
- Combo UI in header not implemented
- Resume prompt not implemented
- Comeback mechanic not implemented
- `SeasonManager`, `ShopManager`, `ComboManager` not yet wired into Main

## Critical Implementation Notes
- `PALETTE[i]["color"]` — always dict access, never `.color`
- `tw.finished.connect(cb)` — not `tween_callback(...).set_delay()`
- `is_instance_valid(node)` required after every `await` in animation functions
- `sheet.get_meta("overlay")` — safe overlay retrieval (not fragile index lookup)
- `CONNECT_ONE_SHOT` timers replace `await` in lambdas on short-lived nodes

## Related
- [[entities/Main]] — primary file changed
- [[entities/SaveData]] — new fields
- [[entities/DailyChallenge]] — new share method
- [[entities/Splash]] — restyled
- [[entities/Tutorial]] — restyled
- [[concepts/game-modes]] — EASY added
- [[concepts/mastermind-algorithm]] — per-dot logic added
- [[concepts/pastel-theme]] — now implemented (was spec-only)
