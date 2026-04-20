---
title: SeasonManager.gd
type: autoload
path: scripts/SeasonManager.gd
status: planned
extends: Node
singleton: true
spec: docs/superpowers/specs/2026-04-19-economy-features-design.md § Section 2b
---

# SeasonManager.gd

Autoload singleton. Fetches remote season config, manages season XP progress, and handles milestone claiming.

## Responsibilities
- Fetch season config JSON from GitHub Gist on launch
- Cache config in `SaveData.season_config_cache`
- Track `SaveData.season_xp` increments
- Check and apply season resets (new season number)
- Provide milestone claim API to UI

## Key Methods
- `fetch_season_config()` — HTTPRequest to Gist URL; 3s timeout; non-blocking
- `on_xp_earned(amount)` — called by Main.gd after every win; increments `season_xp`
- `get_current_season()` → Dictionary — returns active season data
- `get_milestone_status()` → Array[Dictionary] — each milestone with `{xp, reached, claimed, reward}`
- `claim_milestone(index)` — marks claimed, adds reward to inventory via ShopManager
- `check_season_reset()` — called in `_ready()`; if season_number differs from config, reset season_xp and update number

## Remote Config
```
URL: GitHub Gist (set in project settings or hardcoded constant)
Format: {"active_season": 1, "season_name": "...", "season_end": "YYYY-MM-DD", "milestones": [...]}
Fallback: SaveData.season_config_cache (last successful fetch)
First-launch fallback: Season 1 hardcoded
```

## Related
- [[concepts/season-track]] — full season design
- [[entities/SaveData]] — `season_xp`, `season_number`, `season_claimed`, `season_config_cache`
- [[entities/ShopManager]] — `add_to_inventory()` for milestone rewards
