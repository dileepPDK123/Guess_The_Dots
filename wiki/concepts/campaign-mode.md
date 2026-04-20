---
title: Campaign Mode
type: concept
---

# Campaign Mode

100 hand-crafted progressive levels with star ratings. Implemented in CHG-014.

## Difficulty Tiers
| Levels | Slots | Colors | Max Guesses |
|--------|-------|--------|-------------|
| 1–20 | 3 | 3 | 8 |
| 21–50 | 4 | 4 | 8 |
| 51–80 | 4 | 5 | 8 |
| 81–100 | 5 | 6 | 8 |

## Star Ratings
| Stars | Condition |
|-------|-----------|
| ★★★ | Fewest guesses (within threshold) |
| ★★ | Moderate guesses |
| ★ | Any win |
| 0 | Loss |

Thresholds are per-level, returned by `_get_campaign_config(level)`.

## Progression
- Each level is unlocked only after the previous level earns ≥1 star
- `SaveData.campaign_max_unlocked` tracks the highest playable level
- `SaveData.record_campaign_level(level, stars)` keeps the **best** star rating per level

## Sequences
Sequences are deterministic: `_campaign_sequence(level, slots, colors)` uses the level number as a seed. Same level always produces the same hidden code.

## UI
- Campaign Screen: scrollable 5-column grid of 100 level buttons
- Each button shows: level number + star display (★★★ / ★★ / ★ / locked)
- Built by `_build_campaign_screen()` in [[entities/Main]]
- Post-win: `_show_campaign_stars_ui(stars)` overlays star animation on result popup

## Save Structure
```gdscript
campaign_progress = {
    "1": {"stars": 3},
    "2": {"stars": 2},
    ...
}
campaign_max_unlocked = 42
```

## Related
- [[entities/Main]] — `_campaign_sequence()`, `_get_campaign_config()`, `_calc_campaign_stars()`
- [[entities/SaveData]] — `record_campaign_level()`, `campaign_progress`
- [[concepts/game-modes]] — CAMPAIGN mode entry
