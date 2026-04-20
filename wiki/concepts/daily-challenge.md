---
title: Daily Challenge
type: concept
---

# Daily Challenge

One puzzle per day, same sequence worldwide, synchronized to UTC date.

## Rules
- 4 slots, 5 colors, max 8 guesses
- One attempt per day — cannot retry after completion
- Available from Mode Select screen

## Synchronization
`DailyChallenge.get_today_sequence()` hashes today's UTC date string. All players get identical sequences without any server.

## Daily Number
`get_today_number()` counts days since epoch 2026-04-01. Shows as "Daily #42" in UI.

## Completion Tracking
`SaveData.is_daily_done_today()` prevents replaying. `record_daily(did_win, guesses_used, slots)` saves result and updates daily streak.

## Daily Streak
- Increments on consecutive days completing the daily challenge
- Tracked: `daily_streak`, `daily_max_streak`
- Achievement unlocks at 7-day and 30-day streaks

## Share Feature
`DailyChallenge.build_share_text()` generates a Wordle-style emoji grid:
```
Guess the Dots Daily #42  3/8
🟢⬛⬛⬛
🟢🟡⬛⬛
🟢🟢🟢🟢
```

## Save Structure
```gdscript
daily_last_date = "2026-04-19"
daily_streak = 5
daily_history = {
    "2026-04-19": {"won": true, "guesses_used": 3, "slots": 4},
    ...
}
```

## Related
- [[entities/DailyChallenge]] — sequence generation and share text
- [[entities/SaveData]] — `record_daily()`, `is_daily_done_today()`
- [[entities/AchievementManager]] — daily streak achievements
