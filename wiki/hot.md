---
title: Hot Cache
updated: 2026-04-20
---

# Hot Cache

Fast-load context for the most recent session.

## Current State

**UI Rework COMPLETE** — all 21 tasks done on `feature/ui-rework` branch.
- Final commit: `cf12cd5`
- Branch not yet merged to main
- Next step: merge + memory files update + begin Economy/Features implementation

## What's On The Branch

### Implemented (ready to merge)
- Pastel theme (15 color tokens)
- Wordle board (all rows pre-rendered, flip animation)
- Elimination tracker strip
- Smart Hint (absent color reveal)
- Blitz ring timer (inner class `_BlitzRingControl`)
- Dot burst win celebration
- Color-blind mode (shape overlays)
- Hard mode lock badges
- Easy mode (`GameMode.EASY`, per-dot rings, nudge at 3 wins)
- Result screen → bottom sheet
- Settings → `⋯` bottom sheet
- Mode select → bottom sheet (2×3 grid)
- Custom puzzle create + play
- DailyChallenge `build_share_text_general()`
- Splash pastel restyle (2.5s, `#FFF1F9`)
- Tutorial pastel restyle (white glass panels)
- SaveData new fields (colorblind_enabled, easy_wins, etc.)

### NOT Yet Implemented (planned in specs)
- MYSTERY, TIME_TRIAL, DUO, SUDDEN_DEATH, SANDBOX modes
- SeasonManager, ShopManager, ComboManager (wiring into Main)
- Firebase/BackendManager
- Combo UI in header
- Resume prompt
- Comeback mechanic
- Dot trail (drag smear)

## Architecture Reference

### Bottom Sheet Pattern
```gdscript
var sheet := _build_bottom_sheet("Title", func(): _on_close_callback())
var vbox := sheet.get_node("Content") as VBoxContainer
var overlay := sheet.get_meta("overlay") as Control
# close: _close_bottom_sheet(overlay, sheet)
```

### PALETTE Access
```gdscript
PALETTE[i]["color"]  # Color
PALETTE[i]["name"]   # String
```

### History Entry Format
```gdscript
{"values": Array[int], "exact": int, "misplaced": int, "per_dot": Array}
```

### Tween Pattern (Godot 4)
```gdscript
# NOT: tw.tween_callback(fn).set_delay(x)  ← broken
# YES:
tw.finished.connect(fn)
# Or for delayed action in freed-node context:
get_tree().create_timer(0.3).timeout.connect(fn, CONNECT_ONE_SHOT)
```

## Key Decisions (Locked)
- `GameMode.EASY` added; other new modes added when implementing Economy/Features spec
- `result_layer` (old popup) still exists in scene but is never made visible — kept for `@onready` ref safety
- `_result_sheet_open: bool` replaces `result_layer.visible` as double-call guard
- `haptics_toggle.toggled` wiring removed from `_ready()` (now only in settings sheet)
