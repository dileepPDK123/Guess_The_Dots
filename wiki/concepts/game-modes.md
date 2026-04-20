---
title: Game Modes
type: concept
status: partially planned (5 new modes)
spec: docs/superpowers/specs/2026-04-19-ui-rework-design.md § Section 3 + economy spec § Section 4
---

# Game Modes

11 modes total after rework. Mode Select shows all as a scrollable grid.

## Existing Modes (Reworked)

### Classic
- Slots: 3–5 (random, first game always 3) | Colors: 5 | Guesses: 10
- Feedback: count-only pips
- Combo system active

### Easy *(new mode)*
- Slots: 3–4 | Colors: 5 | Guesses: 10
- Feedback: **per-dot colored rings** (green = exact, yellow = misplaced)
- Tutorial bridge — after 3 Easy wins, gentle nudge toward Classic
- Tracked via `SaveData.easy_wins`

### Blitz
- Slots: 5 | Colors: 5 | Constraint: 90-second timer
- **Reworked timer:** circular SVG ring depleting around header, red pulse ≤15s
- Feedback: count-only pips

### Hard
- Slots: 5–6 | Colors: 6 (adds Orange) | Guesses: 10
- Locked exact slots: padlock badge + pulse animation on confirmation
- Feedback: count-only pips

### Zen
- Slots: 4 | Colors: 5 | Guesses: unlimited
- Shows completed rows + 1 active; no future-row outlines
- Feedback: count-only pips

### Campaign
- 100 levels, star ratings, progressive unlock
- See [[concepts/campaign-mode]] for full details

### Daily Challenge
- 4 slots, 5 colors, 8 guesses, one per day worldwide
- Percentile comparison shown on result: "Better than X% of players"
- See [[concepts/daily-challenge]]

## New Modes (Planned)

### Mystery *(new)*
- Slot count hidden at start (randomly 3–5)
- Board shows 1 slot initially; after each submitted guess, one more slot fades in (left-to-right, up to true count)
- Max guesses: 12 | XP reward: 1.5× Classic
- Feedback: count-only pips

### Time Trial *(new)*
- 5 Classic puzzles back-to-back (3–4 slots, 5 colors)
- Single cumulative timer counting up
- Score: `puzzles_solved × 1000 - total_seconds`
- Personal best tracked separately
- No interstitials during session

### Duo *(new)*
- Two independent 4-slot, 5-color secrets simultaneously
- Two side-by-side boards, one shared palette
- Same guess evaluates against both boards independently
- Win: both solved. Loss: either board runs out of guesses (10 each)

### Sudden Death *(new)*
- Classic rules but: any submitted guess with 0 exact matches = instant loss
- Locked until Level 10
- No hints available | XP reward: 2× Classic

### Sandbox *(new)*
- Player sets own secret sequence before playing
- No XP/coins/streak effect
- Hints always free, Reveal button always visible
- Practice mode — no pressure

## Weekly Challenge
- Not a mode — a special puzzle accessible from Mode Select
- Seeded from ISO week number, resets weekly
- Config: 5 slots, 6 colors, 8 guesses
- Reward: 200 XP + 50 coins, one attempt per week
