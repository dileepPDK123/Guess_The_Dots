---
title: AdManager.gd
type: autoload
path: scripts/AdManager.gd
lines: 161 (will grow)
extends: Node
singleton: true
spec: docs/superpowers/specs/2026-04-19-economy-features-design.md § Section 1
---

# AdManager.gd

Autoload singleton. Google AdMob integration. Gracefully falls back on non-Android.

## Ad Unit IDs
| Type | ID |
|------|----|
| App | ca-app-pub-5115870903207025~6216914432 |
| Banner | ca-app-pub-5115870903207025/1646910779 |
| Interstitial | ca-app-pub-5115870903207025/8867128502 |
| Rewarded | ca-app-pub-5115870903207025/6025342743 |
| Native | ca-app-pub-5115870903207025/[TBD — add when created] |

## Signals
- `rewarded_earned` — user finished a rewarded ad
- `interstitial_closed` — interstitial dismissed

## Ad Placement (Reworked)
| Ad | Shown | Hidden |
|----|-------|--------|
| Banner | Active gameplay screen | Menu, result, stats, campaign, tutorial |
| Native card | Stats screen + Main Menu | Everywhere else |
| Interstitial | After LOSS (every 3rd loss) | Never after a win |
| Rewarded | Result sheet + Hint button | — |

## Interstitial Logic (Updated)
```gdscript
# Called only on loss now (not on_game_finished)
func on_game_lost():
    _loss_count += 1
    if _loss_count >= _next_ad_after and _total_games > 3:
        _try_show_interstitial()
        _loss_count = 0
        _next_ad_after = randi_range(2, 4)
```
- `_loss_count` and `_next_ad_after` persisted in SaveData across sessions

## Native Ad Card
- Rendered in Stats screen and Main Menu as a white glass card
- Populated by AdMob Native Ads API on Android
- Desktop: hidden placeholder

## Rewarded Flows
| Flow | Reward |
|------|--------|
| Smart Hint | One absent color revealed in tracker |
| Second Chance | +3 bonus guesses |
| XP Doubler | ×2 XP + coins for that game |
| Earn Coins | +50 coins (max 5/day) |

Note: If player holds a token (from XP Shop), rewarded ad is bypassed entirely.

## Desktop Fallback
`is_rewarded_ready()` returns true; `show_rewarded()` immediately emits `rewarded_earned`.

## Related
- [[concepts/ad-economy]] — full strategy and rules
- [[concepts/xp-shop]] — tokens that bypass rewarded ads
