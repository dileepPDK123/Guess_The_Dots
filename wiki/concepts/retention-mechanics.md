---
title: Retention Mechanics
type: concept
status: planned
spec: docs/superpowers/specs/2026-04-19-economy-features-design.md § Section 3 + Section 5
---

# Retention Mechanics

Six systems designed to bring players back daily and prevent frustration quit.

## Streak Freeze
- Purchased in XP Shop (300 XP each, max 2 held)
- Auto-activates when daily streak would break (new day, daily not completed)
- Only activates if player has a streak ≥ 2
- Toast: "Streak Freeze used 🧊 Your X-day streak is safe!"
- `SaveData.streak_freezes: int`

## Auto-Save / Resume
- Game state saved after every submitted guess:
  ```gdscript
  resume_mode, resume_secret, resume_history, resume_campaign_level
  ```
- On launch: if `resume_secret` non-empty, show "Resume game?" prompt
- Board reconstructed from history — cannot be used to cheat
- Cleared on game end or New Game
- Blitz timer NOT resumed (too complex, starts fresh)

## Comeback Mechanic (Silent)
- `SaveData.consecutive_losses: int` tracks streak of losses
- After 3 consecutive losses in Classic/Easy/Hard: next round gets `max_guesses + 1` or `slots - 1` (min 3)
- Resets on any win
- **Never shown to player** — they just feel like they "got better"
- Does not apply to: Daily, Campaign, Time Trial, Sudden Death

## First Win of Day Bonus
- `SaveData.last_first_win_date: String` (YYYY-MM-DD)
- First win of each calendar day: XP ×2 + 15 coins
- Toast: "First win bonus! ×2 XP ☀️"
- Stacks with combo multiplier

## Weekly Challenge
- Seeded from ISO week number — same puzzle for all players that week
- Config: 5 slots, 6 colors, 8 guesses
- Reward: 200 XP + 50 coins, one attempt per week
- `SaveData.weekly_last_week: int` prevents replay
- Shown on Mode Select as a special card with countdown to reset

## Personal Records
- Tracked per mode: `SaveData.personal_bests: Dictionary`
  - `mode_name → {min_guesses: int, min_time_ms: int}`
- Updated in `_finish_game()` when new record achieved
- "New PB 🏅" badge with scale animation on result screen
- Displayed per-mode in Stats screen

## Combo System (see also Reward System)
- Consecutive wins without hints: 2+ wins = XP multiplier
- 🔥 flame icon in header
- See [[concepts/reward-system]] for full multiplier table
- Managed by [[entities/ComboManager]]

## Related
- [[concepts/xp-shop]] — Streak Freeze purchase
- [[concepts/reward-system]] — how bonuses stack with combo/first-win
- [[entities/SaveData]] — all tracking fields
