---
title: Data Persistence
type: concept
---

# Data Persistence

All player data is stored in a single `ConfigFile` at `user://save_data.cfg`.

## Format
Godot's `ConfigFile` — INI-style sections with typed values. Handles Arrays, Dictionaries, ints, floats, bools, Strings natively.

## Save/Load Entry Points
- `SaveData.load_data()` — called in `_ready()`, reads all sections
- `SaveData.save()` — called after any state mutation (auto-save pattern)

## Section Map
| Section | Key data |
|---------|---------|
| `[progression]` | xp, level, coins, ads_removed |
| `[stats]` | games_played, games_won, streaks, guess_distribution |
| `[daily]` | daily_last_date, daily_streak, daily_history |
| `[login]` | last_login_date, login_streak |
| `[unlocks]` | active_theme, active_shape, unlocked arrays |
| `[achievements]` | unlocked Dictionary |
| `[campaign]` | progress Dictionary, max_unlocked |

## Default Values
All fields have sensible defaults in `load_data()`. A missing key just uses the default — safe for first-time players and version upgrades.

## Ad Economy Reset
`daily_ad_coin_count` and `daily_ad_coin_date` reset automatically on new day via `earn_coins_ads_remaining()`.

## Related
- [[entities/SaveData]] — full API reference
- [[concepts/campaign-mode]] — campaign_progress structure
- [[concepts/daily-challenge]] — daily_history structure
