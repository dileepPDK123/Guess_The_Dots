# Changelog

All meaningful changes to the project are logged here in reverse-chronological order.
Use CHG numbers to reference or revert specific changes.

---

## [CHG-014] 2026-04-01 — Campaign Mode: 100 levels, star ratings, level-select screen

- **What changed:** Full Campaign Mode implementation.
  SaveData.gd: added `campaign_progress: Dictionary`, `campaign_max_unlocked: int`,
  save/load of campaign section, `record_campaign_level(level, stars)` helper.
  Main.gd: added `GameMode.CAMPAIGN` enum value (was already there); added
  `_current_campaign_level`, `_campaign_won`, `_campaign_layer` state vars;
  updated `start_new_game(mode, campaign_level)` signature; added CAMPAIGN match
  case using `_get_campaign_config()`, `_campaign_sequence()` (deterministic seed
  per level), `_build_palette(cfg["colors"])`; updated `_update_header_text()` to
  show level number; added campaign block at end of `_finish_game()` (records
  progress, shows stars, updates button labels); updated `_on_play_again_pressed()`
  for NEXT LEVEL vs RETRY logic; added `_show_campaign_stars_ui()`, `_get_campaign_config()`,
  `_campaign_sequence()`, `_calc_campaign_stars()`, `_open_campaign_screen()`,
  `_close_campaign_screen()`, `_build_campaign_screen()`, `_make_campaign_level_button()`.
  Tier system: L1-20 = 3 nodes/3 colors, L21-50 = 4/4, L51-80 = 4/5, L81-100 = 5/6.
  Stars: 3★ for fewest guesses, 2★ moderate, 1★ any win, 0★ loss.
- **Files affected:** `scripts/SaveData.gd`, `scripts/Main.gd`
- **Why:** Core campaign feature requested by user — 100 levels with visual star
  progression on a scrollable level-select grid.
- **Revert notes:** Remove campaign vars/save/load from SaveData.gd, remove CAMPAIGN
  match case and all campaign functions from Main.gd.

---

## [CHG-013] 2026-04-01 — Remove Daily Challenge, add Campaign to ModeSelect

- **What changed:** Removed `GameMode.DAILY` from enum in Main.gd. Removed Daily
  card from mode select list. Added CAMPAIGN card (opens campaign screen). Removed
  `MAX_GUESSES_DAILY` constant and DailyChallenge references.
- **Files affected:** `scripts/Main.gd`
- **Why:** User requested removal of Daily Challenge in favour of Campaign Mode.
- **Revert notes:** Re-add GameMode.DAILY, DailyChallenge wiring, and Daily mode card.

---

## [CHG-012] 2026-04-01 — Bug fixes: second-chance flow, color count, history row stretch

- **What changed:** Three bug fixes in Main.gd.
  (1) Second-chance timing: loss path no longer reveals answer before offering second
  chance; restructured with `_offer_second_chance_or_reveal()` and `_reveal_answer()`.
  (2) 6th color in Classic/Blitz/Zen: these modes now call `_populate_sequence(5)`
  explicitly instead of `PALETTE.size()`, so Orange never appears in non-HARD modes.
  (3) History row vertical stretch: changed feedback_col from VBoxContainer (two rows)
  to a single HBoxContainer with `SIZE_SHRINK_CENTER` and inline "·" separator;
  dots_row also gets `size_flags_vertical = SIZE_SHRINK_CENTER`.
  Also: renamed all PALETTE color names to plain English (Red/Blue/Green/Yellow/Purple/Orange).
- **Files affected:** `scripts/Main.gd`, `scripts/Tutorial.gd`
- **Why:** User-reported bugs from playtesting.
- **Revert notes:** Revert `_finish_game()`, `_populate_sequence()` calls, and
  `_build_history_row()` feedback layout in Main.gd.

---

## [CHG-011] 2026-04-01 — SoundManager.gd — procedural SFX autoload

- **What changed:** Created `scripts/SoundManager.gd`. Generates all SFX procedurally via
  AudioStreamGenerator (no audio assets needed). Sounds: tap, dot_place, dot_clear, submit,
  exact, misplace, win, lose, level_up, achievement, coin, hint. Registered as autoload.
  Wired into Main.gd at: dot place, drag drop, undo, clear, submit, exact feedback, win, lose.
- **Files affected:** `scripts/SoundManager.gd` (new), `scripts/Main.gd`, `project.godot`
- **Why:** Audio feedback is essential for game feel; procedural approach avoids asset licensing.
- **Revert notes:** Remove SoundManager autoload from project.godot, delete SoundManager.gd,
  remove SoundManager.play() calls from Main.gd.

---

## [CHG-010] 2026-04-01 — Expanded ad placements: Second Chance (P4) + XP Doubler (P5)

- **What changed:** Added two new rewarded ad placements in Main.gd result screen:
  P4 "SECOND CHANCE [AD]" — loss screen only, grants +3 guesses, once per game.
  P5 "DOUBLE REWARDS [AD]" — win or loss screen, doubles bonus XP/coins, once per game.
  Both use CONNECT_ONE_SHOT pattern consistent with existing hint ad.
- **Files affected:** `scripts/Main.gd`
- **Why:** Phase 6 of plan.md — highest-value ad placements at peak emotional moments.
- **Revert notes:** Remove _add_second_chance_button(), _add_xp_doubler_button() and their
  handlers from Main.gd, and the two calls in _finish_game().

---

## [CHG-009] 2026-04-01 — New game modes: BLITZ, HARD, ZEN + GameMode enum

- **What changed:** Added GameMode enum (CLASSIC/DAILY/BLITZ/HARD/ZEN) to Main.gd.
  Refactored start_new_game() to accept a mode param. Blitz: 90s countdown via _process(),
  pulsing red timer at <15s, auto-loss on time-out. Hard: 6th color (ORANGE), exact slots
  locked between guesses, locked slots cannot be tapped clear. Zen: 4 slots, no guess limit.
  Daily: delegates to DailyChallenge.get_today_sequence(). MAX_GUESSES is now a var
  set per-mode. Added warm-up first game (3 slots) for new players.
- **Files affected:** `scripts/Main.gd`
- **Why:** Phase 5 of plan.md — game variety drives replayability and longer sessions.
- **Revert notes:** Remove GameMode enum, revert start_new_game() to parameterless version,
  remove _process(), remove _hard_locked_slots logic.

---

## [CHG-008] 2026-04-01 — AchievementManager.gd autoload + 18 achievements

- **What changed:** Created `scripts/AchievementManager.gd`. Defines all 18 achievements
  from plan.md with coin rewards. Listens to SaveData.achievement_unlocked signal and
  shows a slide-in popup (from top, 2.8s hold, slide out) on the active scene root.
  Auto-checks "OMEGA PROTOCOL" (all achievements) after each unlock.
  Registered as autoload in project.godot.
- **Files affected:** `scripts/AchievementManager.gd` (new), `project.godot`
- **Why:** Phase 4 of plan.md — achievements drive long-term engagement and provide
  milestone rewards.
- **Revert notes:** Remove AchievementManager autoload, delete file.

---

## [CHG-007] 2026-04-01 — Daily Challenge + DailyChallenge.gd autoload

- **What changed:** Created `scripts/DailyChallenge.gd`. Date-seeded sequence generation
  via deterministic hash of "YYYY-MM-DD" string. 4 slots, 5 colors, 8 max guesses.
  Includes: get_today_sequence(), get_today_number(), build_share_text() (emoji grid).
  Registered as autoload in project.godot.
  In Main.gd: connected SaveData.login_streak_updated → slide-in toast popup showing
  "DAY N STREAK +NN COINS" on first open each day.
- **Files affected:** `scripts/DailyChallenge.gd` (new), `scripts/Main.gd`, `project.godot`
- **Why:** Phase 2 of plan.md — daily challenge is primary D7 retention mechanic.
- **Revert notes:** Remove DailyChallenge autoload, delete file, remove login streak
  popup wiring from Main.gd.

---

## [CHG-006] 2026-04-01 — XP, coins, levels, achievement hooks wired into Main.gd

- **What changed:** In Main.gd _finish_game(): calculates XP earned (base 15 + win bonus
  50 + guess-remaining bonus + perfect bonus 50 + ×2 if doubler), calls SaveData.add_xp()
  and add_coins(), shows animated "+NNN XP +NN COINS ▲ LEVEL N" flytext on result screen,
  calls _check_achievements_after_game() checking 8 unlock conditions.
  Warm-up first game uses 3 slots. AdManager grace period: no interstitials for first 3 games.
- **Files affected:** `scripts/Main.gd`, `scripts/AdManager.gd`
- **Why:** Phase 3 of plan.md — visible XP reward on every game end reinforces the
  progression loop and makes even losses feel worthwhile.
- **Revert notes:** Remove _finish_game() XP/coins/achievement block, remove
  _show_reward_flytext(), remove SaveData.games_played check in AdManager.

---

## [CHG-005] 2026-04-01 — SaveData.gd autoload (persistence layer)

- **What changed:** Created `scripts/SaveData.gd` as an autoload singleton. Full schema:
  XP (int), level (int, 1-50), coins (int), hint_tokens, ads_removed, games_played,
  games_won, streaks (win/daily/login), guess_distribution[10], achievements dict,
  cosmetic unlocks (themes + shapes). Helpers: add_xp() with level-up detection,
  level_progress() [0-1 float], record_game(), record_daily(), _check_login_streak()
  (fires login_streak_updated signal), unlock_achievement() (fires achievement_unlocked).
  Level-up cosmetic rewards: themes at L5/10/20/30/50, shapes at L10/15/25.
  Registered in project.godot.
- **Files affected:** `scripts/SaveData.gd` (new), `project.godot`
- **Why:** Phase 0 of plan.md — all progression, stats, and persistence flows through this.
- **Revert notes:** Remove SaveData from project.godot autoloads, delete SaveData.gd.

---

## [CHG-004] 2026-04-01 — NEURAL GRID UI overhaul + vocabulary rename

- **What changed:** Full visual redesign in Main.gd and updated ColorDotButton.gd/SlotButton.gd.
  Theme: deep void background, neon cyan panel borders, magenta CTA buttons, gold score labels.
  All UI labels renamed to futuristic vocabulary (TRANSMIT, WIPE, REVERT, ATTEMPT LOG, etc.).
  ColorDotButton: 100px, glow ring with color-matching border, scale animation on select.
  SlotButton: 100px, pulsing cyan border scan animation on empty slots.
  History rows: left accent bar (green/gold/red by result), [01] monospaced numbers,
  diamond pip (◆) feedback symbols, slide-in animation on new row.
  Result screen: "SEQUENCE DECODED" / "DECRYPTION FAILED" with neon color.
  New-player grace period gate added to AdManager.on_game_finished().
- **Files affected:** `scripts/Main.gd`, `scripts/ColorDotButton.gd`, `scripts/SlotButton.gd`,
  `scripts/AdManager.gd`
- **Why:** Phase 1 of plan.md — distinct visual identity creates memorability and shareability.
- **Revert notes:** Revert Main.gd _apply_theme() and _apply_label_vocabulary(),
  revert ColorDotButton.gd and SlotButton.gd to prior versions.

---

## [CHG-003] 2026-04-01 — Master game evolution plan created

- **What changed:** Created `plan.md` — a comprehensive 10-part game evolution document
  covering: (1) futuristic "NEURAL GRID" UI overhaul spec, (2) daily retention system
  design (daily challenge, login streak, XP/level, coins, achievements, stats),
  (3) expanded ad placement strategy (14 placement types mapped), (4) new game modes
  (Blitz, Hard, Zen, Daily Sequence), (5) social/sharing features, (6) sound design plan,
  (7) full technical architecture with new files, modified files, SaveData schema,
  and phased implementation roadmap (v1.1 → v2.0).
  Also updated all memory files: user.md, decisions.md, preference.md.
- **Files affected:** `plan.md` (new), `memory/user.md`, `memory/decisions.md`,
  `memory/preference.md`, `memory/changelog.md`
- **Why:** User requested a full brainstorm + plan covering futuristic UI redesign,
  daily retention mechanics, expanded ad suggestions, and new gameplay features.
- **Revert notes:** Delete `plan.md`. Memory files can be reverted to their blank
  template state.

---

## [CHG-002] 2026-03-30 — Created CLAUDE.md and changelog

- **What changed:** Added `CLAUDE.md` with session-start/end instructions and changelog format rules. Added this file (`memory/changelog.md`) for change tracking.
- **Files affected:** `CLAUDE.md`, `memory/changelog.md`
- **Why:** To give Claude persistent instructions across sessions and a revertable change history.
- **Revert notes:** Delete `CLAUDE.md` and `memory/changelog.md`.

---

## [CHG-001] 2026-03-30 — Initialised memory system

- **What changed:** Created `memory/` directory with `decisions.md`, `people.md`, `preference.md`, `user.md`. Also created built-in Claude memory files at `~/.claude/projects/.../memory/` with `MEMORY.md` index.
- **Files affected:** `memory/decisions.md`, `memory/people.md`, `memory/preference.md`, `memory/user.md`, and built-in memory counterparts.
- **Why:** Persistent memory so Claude retains context across sessions.
- **Revert notes:** Delete the `memory/` directory and the built-in memory files at `C:/Users/potha/.claude/projects/D--Guess-the-Dots-guess-the-dots-godot/memory/`.

---
