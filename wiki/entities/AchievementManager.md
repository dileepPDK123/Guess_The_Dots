---
title: AchievementManager.gd
type: autoload
path: scripts/AchievementManager.gd
lines: 157
extends: Node
singleton: true
---

# AchievementManager.gd

Autoload singleton. Listens for `SaveData.achievement_unlocked` and shows animated toast popups. Awards bonus coins.

## Achievement List (18 total)
| ID | Name | Coins |
|----|------|-------|
| first_win | First Transmission | 50 |
| wins_10 | Signal Detected (10 wins) | 100 |
| wins_50 | Pattern Analyst (50 wins) | 250 |
| wins_100 | Neural Architect (100 wins) | 500 |
| perfect_1 | Precise Strike (1 perfect win) | 100 |
| perfect_5 | Ghost Protocol (5 perfect wins) | 300 |
| daily_7_played | Weekly Operative (7 dailies) | 150 |
| daily_7_streak | Streak Initiate (7-day streak) | 200 |
| daily_30_streak | Grid Master (30-day streak) | 1000 |
| no_hint_win | Unaided (win without hints) | 75 |
| playtime_50 | Veteran Agent (50 games) | 200 |
| login_7 | Loyal Operative (7 login streak) | 150 |
| blitz_win | Speed Runner (Blitz win) | 150 |
| speed_3 | Cracked It (win in ≤3 guesses) | 200 |
| shared | Signal Broadcast (shared result) | 50 |
| watched_ad_5 | Supporter (5 rewarded ads) | 100 |
| all_achievements | Neural Grid Complete | 1000 |

## Popup Behavior
1. Slide down from top (0.35s)
2. Hold 2.8s
3. Slide up + fade out (0.28s)

Popups are queued; if multiple unlock simultaneously, they display sequentially.

## Meta Achievement
`all_achievements` unlocks automatically when all 17 others are unlocked.

## Related
- [[concepts/reward-system]] — coins from achievements
- [[entities/SaveData]] — `unlock_achievement()` and signal source
