---
title: Reward System
type: concept
status: partially planned
spec: docs/superpowers/specs/2026-04-19-economy-features-design.md § Sections 2–3
---

# Reward System

XP, coins, combo multiplier, tokens, levels, and achievements.

## XP on Win (Updated)
| Condition | XP |
|-----------|-----|
| Base | +15 |
| Win bonus | +50 |
| Per remaining guess | +10 |
| Win in ≤3 guesses | +50 speed bonus |
| First win of day ☀️ | ×2 total |
| XP doubler (ad/token) | ×2 total |
| Combo multiplier | ×1.0 / ×1.5 / ×2.0 / ×2.5 |

Multipliers stack multiplicatively: first-win-of-day ×2 + combo ×2 = ×4 total.

## Combo System *(new)*
Consecutive wins **without hint use** build a combo:
| Streak | Multiplier |
|--------|-----------|
| 0–1 wins | 1.0× |
| 2 wins | 1.5× |
| 3 wins | 2.0× |
| 4+ wins | 2.5× |

- 🔥 flame icon in header shows current combo count
- Breaks on: any loss, any hint used (token or ad), mode change
- Managed by [[entities/ComboManager]]

## Coins
- Win: +10 coins
- XP doubler: ×2 coins
- Earn Coins ad: +50 coins (max 5/day)
- Achievement unlocks: 50–1000 coins
- Spent on: XP Boosts (50 coins/hr), nothing else currently

## Level System (unchanged)
- 50 levels, XP scales 200→37800 per level
- Cosmetic unlocks at specific levels (auto, no cost)
- `SaveData.add_xp()` handles leveling + returns levels gained

## XP as Spendable Currency *(new)*
XP now does double duty — progression AND purchasing power:
- Level-up auto-unlocks stay exactly as before
- Separately, accumulated XP can be spent in the [[concepts/xp-shop]]
- Spending XP does NOT reduce your level or level progress — it reduces a separate `spendable_xp` pool
- `SaveData.total_xp_earned` tracks lifetime XP; `SaveData.xp` tracks level-progression XP (unchanged)
- **Implementation note:** XP Shop deducts from `total_xp_earned` pool, not from `xp` field

## Season XP *(new)*
- Every XP earned simultaneously increments `SaveData.season_xp`
- Season XP resets to 0 each season (every 2 months)
- Does NOT affect level XP or total XP
- See [[concepts/season-track]]

## Related
- [[concepts/xp-shop]] — spending XP
- [[concepts/season-track]] — season milestones
- [[entities/ComboManager]] — combo logic
- [[entities/SaveData]] — all fields
