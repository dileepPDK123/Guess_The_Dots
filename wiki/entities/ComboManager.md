---
title: ComboManager.gd
type: autoload
path: scripts/ComboManager.gd
status: planned
extends: Node
singleton: true
spec: docs/superpowers/specs/2026-04-19-economy-features-design.md § Section 5
---

# ComboManager.gd

Autoload singleton. Tracks consecutive hint-free wins and returns the current XP multiplier.

## Multiplier Table
| Combo | Multiplier |
|-------|-----------|
| 0–1 | 1.0× |
| 2 | 1.5× |
| 3 | 2.0× |
| 4+ | 2.5× |

## Key Methods
- `on_win(hint_used: bool)` — increments combo if no hint used; resets if hint was used
- `on_loss()` — resets combo to 0
- `get_multiplier()` → float — current XP multiplier
- `get_combo()` → int — current combo count

## Persistence
- `SaveData.current_combo: int` — survives between sessions
- Combo resets on mode change (called when `_show_menu()` returns to menu)

## UI Contract
- Main.gd reads `ComboManager.get_combo()` to show 🔥 flame icon in header
- Flame icon hidden when combo == 0
- On combo increase: flame bounces (scale tween) + warm haptic pulse

## Related
- [[concepts/reward-system]] — how multiplier applies to XP
- [[concepts/retention-mechanics]] — combo as a retention driver
- [[entities/Main]] — reads combo for header UI
