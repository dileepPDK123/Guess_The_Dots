---
title: SlotButton.gd
type: script
path: scripts/SlotButton.gd
lines: 90
extends: Button
---

# SlotButton.gd

Individual guess slot (3–5 per round). Shows scanning animation when empty, filled color with glow when occupied.

## Signals
- `color_dropped(slot_index, color_index)` — drag-drop color placed here
- `slot_pressed_for_assign(slot_index)` — clicked while filled (to clear)

## Key Variables
- `slot_index: int` — position in sequence (0-indexed)
- `_is_filled: bool`
- `_filled_color: Color`
- `_scan_tween: Tween` — breathing animation handle

## Visual States
### Empty
- Faint cyan border (`#00E6FF` at 0.18 alpha)
- Breathing animation: border alpha pulses 0.18 ↔ 0.55 over 0.75s each way

### Filled
- Color border with glow matching the placed color
- Breathing animation stopped

## Drag-and-Drop Target
`_can_drop_data()` — accepts only `"palette_color"` payloads
`_drop_data()` — emits `color_dropped`

## Key Methods
- `set_empty_visual()` — reset to empty state, start scan animation
- `set_filled_visual(color, name)` — show color, stop animation
- `_apply_all(style)` — apply style to all button states (normal/hover/pressed/focus/disabled)

## Related
- [[entities/ColorDotButton]] — drag source
- [[entities/Main]] — creates these via `_build_slots()`
