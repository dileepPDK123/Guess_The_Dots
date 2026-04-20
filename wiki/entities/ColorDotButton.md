---
title: ColorDotButton.gd
type: script
path: scripts/ColorDotButton.gd
lines: 80
extends: Button
---

# ColorDotButton.gd

Palette color button. Circular dot with neon glow ring, selection state, and drag-and-drop source support.

## Key Variables
- `color_index: int` — index in PALETTE (0–5)
- `color_name: String` — display name ("Red", "Blue", etc.)
- `dot_color: Color` — actual Color value
- `is_selected: bool` — controls glow ring visibility

## Visual Behavior
- **Normal:** 100×100 circular button, dark border
- **Selected:** scale 1.08, thick bright border, 10px shadow glow
- **Hover:** slight brightness increase

## Drag-and-Drop
`_get_drag_data()` returns `{"type": "palette_color", "color_index": N}`. [[entities/SlotButton]] accepts this payload.

## Style Method
`_build_style(fill, selected, compact)` — creates `StyleBoxFlat` with:
- 999px corner radius (fully circular)
- Dynamic border: thin dark normally → thick lightened color when selected

## Related
- [[entities/SlotButton]] — drop target
- [[entities/Main]] — creates these via `_build_palette(count)`
