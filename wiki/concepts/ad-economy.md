---
title: Ad Economy
type: concept
status: planned
spec: docs/superpowers/specs/2026-04-19-economy-features-design.md § Section 1
---

# Ad Economy

Four ad types with distinct placement rules. Strategy: keep wins clean, monetize losses naturally.

## Placement Rules
| Ad Type | Where | Trigger | Removed by $2.99 IAP |
|---------|-------|---------|----------------------|
| Banner (320×50) | Bottom of game screen | During active gameplay only | ✓ |
| Native-style card | Stats screen + Main Menu | Always visible | ✓ |
| Interstitial | Full screen | After **loss** only, every 3rd loss, skip first 3 games | ✓ |
| Rewarded | Result screen + Hint button | Player-initiated | ✗ (always stays) |

## Interstitial Logic (Updated)
```gdscript
# In AdManager — called only on loss, not win
func on_game_lost():
    _loss_count += 1
    if _loss_count >= _next_ad_after and _total_games > 3:
        _try_show_interstitial()
        _loss_count = 0
        _next_ad_after = randi_range(2, 4)
```
- `_loss_count` and `_next_ad_after` persisted in SaveData across sessions
- Never shows after a win — wins feel completely uninterrupted

## Native-Style Ad Card
- White glass panel: app icon + title + CTA button (matches pastel UI)
- Populated by AdMob Native Ads API on Android
- Desktop fallback: hidden placeholder
- Tappable — opens ad URL
- Positioned at absolute bottom of Stats screen and Main Menu

## Rewarded Ad Flows (unchanged)
| Flow | Trigger | Reward |
|------|---------|--------|
| Smart Hint | Hint button (if no token held) | One absent color revealed in tracker |
| Second Chance | After loss (if no token held) | +3 bonus guesses |
| XP Doubler | After win | ×2 XP and coins for that game |
| Earn Coins | Stats screen button | +50 coins (max 5/day) |

## Token Bypass
If player holds a **Hint Token** or **Second Chance Token** (bought via XP Shop), the rewarded ad is skipped entirely — token consumed silently. See [[concepts/xp-shop]].

## Remove Ads IAP
- Price: $2.99
- Removes: banner, native cards, interstitials
- Rewarded ads remain (player-initiated, always valuable)
- `SaveData.ads_removed: bool`

## Related
- [[entities/AdManager]] — implementation
- [[concepts/xp-shop]] — token system that bypasses rewarded ads
