---
name: Project Decisions
description: Key design and technical decisions made for the project
type: project
---

# Project Decisions

## Format

**[Date] — Decision title**
- **What:** What was decided
- **Why:** Reasoning or constraint behind it
- **Alternatives considered:** What else was weighed

---

## [2026-04-01] — Procedural SFX (no audio assets)

- **What:** SoundManager.gd generates all sounds at runtime using AudioStreamWAV with
  hand-crafted sine waves, arpeggios, and chords. No .wav/.ogg files needed.
- **Why:** Avoids licensing complexity; keeps APK small; all sounds defined in code.
- **Alternatives considered:** Importing royalty-free samples — rejected for asset overhead.

## [2026-04-01] — GameMode enum controls all per-mode configuration

- **What:** start_new_game(mode: GameMode) centralizes slot count, color count, MAX_GUESSES,
  and timer logic. Hard mode uses 6 colors (adds orange #f97316 conceptually — index 5
  wraps into existing PALETTE for now, to be extended).
- **Why:** Single entry point is cleaner than scattered per-mode booleans.
- **Alternatives considered:** Separate scene per mode — rejected as too much duplication.

## [2026-04-01] — Login streak popup uses slide-in overlay (not a separate scene)

- **What:** Login reward toast is built procedurally in Main.gd as a PanelContainer
  added to the scene tree, animated with a Tween, then freed.
- **Why:** Keeps scene count low; login toast is a one-time-per-session event.
- **Alternatives considered:** Separate tscn popup scene — overkill for a toast.

## [2026-04-01] — Visual identity: "NEURAL GRID" cyberpunk theme

- **What:** Redesign UI with cyberpunk/holographic HUD aesthetic. Deep void background,
  neon cyan borders, magenta CTA buttons, glowing dot buttons (100×100px).
- **Why:** Current dark-blue theme is functional but generic. A distinct "neural hacker"
  identity makes the game memorable and shareable. Thematic tie-in: player = hacker
  cracking a neural network color sequence.
- **Alternatives considered:** Clean minimalist (Wordle-like), retro pixel art, neon
  pastel kawaii. Cyberpunk was chosen for being both unique and timeless in mobile gaming.

## [2026-04-01] — Daily Challenge as primary retention mechanic

- **What:** Add a daily-seeded puzzle (same worldwide), with streak tracking, shareable
  emoji results, and prominence on the menu screen.
- **Why:** Proven mechanic (Wordle, NYT Games). Scarcity (once per day) drives return
  visits. Shareable results are free organic marketing.
- **Alternatives considered:** Weekly challenge, rotating modes. Daily is strongest for
  D7+ retention.

## [2026-04-01] — XP + Level + Coin economy

- **What:** Players earn XP per game → level up → unlock cosmetic themes + dot shapes.
  Coins from daily logins, wins, watching optional ads → spend on hints, themes, extra guesses.
- **Why:** Gives players a sense of progress beyond each individual game. Cosmetic-only
  unlocks avoid pay-to-win concerns.
- **Alternatives considered:** No progression (pure puzzle), lives system (like Candy
  Crush — rejected as frustrating for puzzle genre), energy system (too aggressive).

## [2026-04-01] — "Second Chance" rewarded ad on loss screen

- **What:** Show a "SECOND CHANCE [WATCH AD]" button on game-over screen that grants
  3 extra guesses.
- **Why:** "Almost!" moments are the best placement for rewarded video — highest
  emotional motivation to watch. Prevents player frustration while generating revenue.
- **Alternatives considered:** Offering hints instead (weaker emotional hook), charging
  coins (less accessible).

## [2026-04-01] — Campaign Mode replaces Daily Challenge

- **What:** 100 deterministic levels (seeded by level number), tiered difficulty
  (L1-20: 3 nodes/3 colors, L21-50: 4/4, L51-80: 4/5, L81-100: 5/6).
  Star system: 3★/2★/1★/0★ based on guesses used. Scrollable 5-column level-select
  grid with per-level star icons. Level unlock is sequential.
- **Why:** Daily Challenge lacked clear progression arc. Campaign gives players a
  defined goal (100 levels, all 3-star) that drives long-term engagement without
  the daily-timer restriction. Deterministic sequences mean any level can be
  replayed to improve star rating.
- **Alternatives considered:** Keeping Daily alongside Campaign — rejected for scope
  and UI clutter. Random levels per session — rejected for lack of progression feel.

## [2026-04-01] — No lives system, no energy system

- **What:** Players can play unlimited games freely. No artificial restrictions.
- **Why:** Puzzle games lose players fast when gated. The game's fun is in the puzzle
  itself — restricting play works against the genre. Monetize via ads + cosmetics instead.
- **Alternatives considered:** 5 lives system (common in match-3) — rejected.

## [2026-04-01] — Remove-Ads IAP at $2.99

- **What:** One-time purchase to remove banner + interstitial. Rewarded ads remain
  (opt-in) even after purchase.
- **Why:** Serves players who dislike ads but still want the hint/bonus mechanics.
  ~3–8% conversion rate on engaged users makes it worth implementing.
- **Alternatives considered:** $0.99 (too low), $4.99 (slightly high for casual), 
  subscription (too complex for this game scope).

## [2026-04-01] — Futuristic vocabulary for all UI labels

- **What:** Rename all UI strings to match the neural-hacker theme.
  e.g., "Submit" → "TRANSMIT", "Game Over" → "DECRYPTION FAILED", etc.
- **Why:** Consistency between visual theme and text creates immersion. Memorable
  phrases improve word-of-mouth and social sharing ("I got 'SEQUENCE DECODED' in 3!").
- **Alternatives considered:** Keep original friendly labels alongside new theme —
  rejected for inconsistency. Could be a setting ("Classic mode" vs "Neural mode")
  in a future version.

---
