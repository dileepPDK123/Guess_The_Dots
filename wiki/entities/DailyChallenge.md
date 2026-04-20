---
title: DailyChallenge.gd
type: autoload
path: scripts/DailyChallenge.gd
lines: 86
extends: Node
singleton: true
---

# DailyChallenge.gd

Autoload singleton. Generates a worldwide synchronized daily puzzle — same sequence for all players on the same UTC date.

## Constants
- `DAILY_SLOTS: 4`
- `DAILY_COLORS: 5`
- `DAILY_MAX_GUESSES: 8`

## Key Methods
- `get_sequence_for_date(date: String)` → `Array[int]` — deterministic RNG from "YYYY-MM-DD"
- `get_today_sequence()` → `Array[int]` — shorthand for today
- `get_today_number()` → int — days since epoch 2026-04-01 (used as "Daily #42")
- `build_share_text(guess_rows, secret, did_win, guesses_used)` → String — Wordle-style emoji grid

## Share Format
```
Guess the Dots Daily #42  3/8
🟢⬛⬛⬛
🟢🟡⬛⬛
🟢🟢🟢🟢
```
- 🟢 = exact match
- 🟡 = wrong position
- ⬛ = no match

## Seed Algorithm
`_hash_date(date)` — deterministic hash of date string (not cryptographic). Same hash always produces same sequence.

## Related
- [[concepts/daily-challenge]] — full daily challenge flow
- [[entities/SaveData]] — `record_daily()`, `is_daily_done_today()`
