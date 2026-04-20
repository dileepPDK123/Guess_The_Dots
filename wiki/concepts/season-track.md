---
title: Season Track
type: concept
status: planned
spec: docs/superpowers/specs/2026-04-19-economy-features-design.md § Section 2b
---

# Season Track

Monthly milestone progression giving XP a long-term goal and delivering exclusive cosmetics. Accessible via "Rewards" screen (tab 2).

## Structure
- Season duration: 2 months (configurable via remote config)
- 5 milestones: 500 / 1000 / 2000 / 3500 / 5000 XP
- Season XP resets to 0 at end; level XP unaffected
- XP earned counts toward both level progress AND season simultaneously

## Milestone Rewards (example — Season 1)
| Milestone | Reward |
|-----------|--------|
| 500 XP | 100 coins |
| 1000 XP | Hint Token ×5 |
| 2000 XP | Season exclusive theme ("Cherry Blossom") |
| 3500 XP | 300 coins + season emoji pack |
| 5000 XP | Season exclusive dot shape + Season Champion badge |

## Pre-Baked Seasons (6 — 1 year)
| # | Name | Palette | Exclusive |
|---|------|---------|-----------|
| 1 | Cherry Blossom 🌸 | `#FFE4F0 → #FFF0FA` | Petal gradient + sakura emoji |
| 2 | Ocean Depths 🌊 | `#E0F4FF → #F0FAFF` | Deep blue theme + wave emoji |
| 3 | Golden Harvest 🌾 | `#FFF8E0 → #FFFAF0` | Amber theme + harvest emoji |
| 4 | Northern Lights 🌌 | `#E8F0FF → #F0E8FF` | Aurora theme + star emoji |
| 5 | Ember Forest 🍂 | `#FFF0E8 → #FFF8F0` | Rust/orange theme + leaf emoji |
| 6 | Frost Crystal ❄️ | `#F0F8FF → #F8F0FF` | Ice blue theme + snowflake emoji |

## Remote Config
- Source: GitHub Gist (free, publicly readable JSON)
- Format:
  ```json
  {
    "active_season": 1,
    "season_name": "Cherry Blossom 🌸",
    "season_end": "2026-06-30",
    "milestones": [500, 1000, 2000, 3500, 5000]
  }
  ```
- Fetched on app launch (3s timeout, non-blocking)
- Cached in `SaveData.season_config_cache`
- Fallback: last cached season (or Season 1 if first launch)
- Rotate seasons by editing Gist — **no app store submission required**

## SaveData Fields
```gdscript
var season_xp: int = 0
var season_number: int = 1
var season_claimed: Array = [false, false, false, false, false]
var season_badge: String = ""
var season_config_cache: Dictionary = {}
```

## Claiming Rewards
- Season tab shows milestone nodes on a progress track (journey map visual)
- Unclaimed reached milestones pulse with glow
- Tap to claim → reward added to inventory
- Season badge expires if not claimed before season reset

## Related
- [[entities/SeasonManager]] — fetch, cache, milestone claiming
- [[concepts/xp-shop]] — season exclusives appear in shop too after unlock
- [[concepts/reward-system]] — XP earning
