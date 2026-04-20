---
title: ShopManager.gd
type: autoload
path: scripts/ShopManager.gd
status: planned
extends: Node
singleton: true
spec: docs/superpowers/specs/2026-04-19-economy-features-design.md § Section 2a
---

# ShopManager.gd

Autoload singleton. Owns the XP Shop catalog, purchase validation, and token consumption logic.

## Responsibilities
- Define full shop catalog (items, costs, types)
- Validate purchases (sufficient XP/coins, max held)
- Deduct XP from `SaveData.total_xp_earned` (NOT from `SaveData.xp`)
- Add items to inventory (permanent unlocks or consumable increments)
- Provide token consumption API used by Main.gd

## Key Methods
- `get_catalog()` → Array[Dictionary] — full item list with cost, type, description
- `can_purchase(item_id)` → bool — checks XP/coins balance and max-held limits
- `purchase(item_id)` — deducts cost, adds to inventory, plays sound + haptic
- `consume_hint_token()` → bool — returns true if token consumed; false if none held
- `consume_second_chance_token()` → bool — same pattern
- `consume_extra_guess_token()` → bool — same pattern
- `consume_streak_freeze()` → bool — same pattern
- `add_to_inventory(item_id, quantity)` — used by SeasonManager for milestone rewards

## Item Types
- `consumable` — increments a counter in SaveData (hint_tokens, streak_freezes, etc.)
- `permanent` — adds to an unlocked array (unlocked_themes, unlocked_sound_packs, etc.)
- `timed` — sets an end timestamp (xp_boost_end_time)

## Related
- [[concepts/xp-shop]] — full catalog and pricing
- [[entities/SaveData]] — inventory fields
- [[entities/SeasonManager]] — calls `add_to_inventory()` for milestone rewards
