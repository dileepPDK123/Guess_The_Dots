# Guess the Dots — Economy, Ads & Feature Expansion Design Spec
**Date:** 2026-04-19
**Status:** Approved
**Depends on:** `2026-04-19-ui-rework-design.md` (visual rework must be completed first)
**Scope:** Ad system rework, XP Shop + Season Track, 6 retention mechanics, 5 new game modes, 4 game-feel upgrades, 5 new shop items, 2 stats features.

---

## 1. Ad System

### Placement Rules
| Ad Type | Where | Trigger | Removed by IAP |
|---------|-------|---------|----------------|
| Banner (AdMob 320×50) | Bottom of game screen | During active gameplay only | ✓ |
| Native-style card | Bottom of Stats screen + Main Menu | Always visible | ✓ |
| Interstitial | Full screen | After a **loss** only, every 3rd loss, skip first 3 games | ✓ |
| Rewarded | Result screen + Hint button | Player-initiated | ✗ (stays always) |

### Interstitial Logic (updated from current)
```
_loss_count += 1
if _loss_count >= _next_ad_after and _total_games > 3:
    _try_show_interstitial()
    _loss_count = 0
    _next_ad_after = randi_range(2, 4)
```
- Never shows after a win (removed from `on_game_finished`)
- `_loss_count` and `_next_ad_after` persist across sessions in SaveData

### Native-Style Ad Card
- Rendered as a white glass panel: app icon (30×30) + title + CTA button
- Populated by AdMob Native Ads API (`NativeAd`) on Android
- On desktop/fallback: hardcoded placeholder card, invisible to user
- Tappable — opens ad URL
- Positioned at absolute bottom of Stats screen and Main Menu, below all other content

### Remove Ads IAP
- Price: $2.99 (unchanged)
- Hides banner, native card, and interstitials permanently
- Rewarded ads remain (player-initiated, always valuable)
- `SaveData.ads_removed: bool` flag checked before showing any intrusive ad

---

## 2. XP Shop + Season Track

### Screen Layout
- New screen: "Rewards" — accessible from Main Menu and Stats screen
- Two tabs: **Shop** (⚡ XP) and **Season** (🏅)
- Header shows current XP balance (large, gradient text)

### 2a. XP Shop

**Purpose:** Give players active control over their XP — spend it on convenience items and cosmetics rather than just watching a number grow.

**Shop Catalog:**

| Item | Cost | Type | Notes |
|------|------|------|-------|
| Hint Token ×3 | 150 XP | Consumable | Skip rewarded ad for a hint; max 10 tokens held |
| Second Chance Token | 200 XP | Consumable | Skip ad for +3 guesses on loss; max 5 held |
| Extra Guess Token | 250 XP | Consumable | Add +1 max guess before game starts; max 5 held |
| Streak Freeze | 300 XP | Consumable | Protects daily streak for 1 missed day; max 2 held |
| XP Boost ×1hr | 50 coins | Timed | All XP earned ×2 for 60 min; timer runs in real time |
| Sound Pack — Soft Piano | 600 XP | Permanent | Replaces procedural audio with piano-tone generator |
| Sound Pack — Nature | 600 XP | Permanent | Chime + soft percussion tones |
| Sound Pack — Retro Arcade | 600 XP | Permanent | Classic 8-bit but punchier, more varied |
| Share Emoji Pack — Hearts | 400 XP | Permanent | ❤️🧡🖤 for share grid |
| Share Emoji Pack — Space | 400 XP | Permanent | 🌍🌙⭐ for share grid |
| Share Emoji Pack — Flowers | 400 XP | Permanent | 🌸🌼🌑 for share grid |
| Board Skin — Minimal | 700 XP | Permanent | No grid lines, floating dots only |
| Board Skin — Rounded | 700 XP | Permanent | Pill-shaped slots instead of rounded squares |
| Board Skin — Diamond | 700 XP | Permanent | Slots rotated 45° (diamond shape) |
| Theme — Neon Core | 1200 XP | Permanent | Dark cyberpunk (the old NEURAL GRID theme) |
| Theme — Void Protocol | 1500 XP | Permanent | Deep black + electric blue |
| Theme — Solar Flare | 1000 XP | Permanent | Warm amber + orange gradients |
| Dot Shape — Hexagon | 500 XP | Permanent | Hex-shaped dots |
| Dot Shape — Diamond | 500 XP | Permanent | Diamond/rotated-square dots |
| Dot Shape — Star | 500 XP | Permanent | Star-shaped dots |

**Purchase flow:**
1. Tap item → confirmation sheet: item name, cost, "Buy for 150 ⚡" button
2. If insufficient XP: button shows "Not enough XP" (disabled), link to earn more
3. On confirm: deduct XP, add to inventory, haptic feedback + coin sound
4. Permanent items: added to unlocked lists in SaveData, immediately selectable in settings

**Consumable token usage:**
- Hint Tokens: checked first before showing rewarded ad — if token available, hint is instant (no ad)
- Second Chance Token: same — skips ad entirely, applies 3 bonus guesses
- Extra Guess Token: shown as a toggle on Mode Select screen ("Use token: +1 guess ✓")
- Streak Freeze: auto-consumed silently when daily streak would break — toast: "Streak Freeze used 🧊 Streak preserved!"

### 2b. Season Track

**Purpose:** Monthly milestone progression that gives XP an additional long-term goal and delivers exclusive cosmetics.

**Season Structure:**
- Season duration: 2 months (configurable via remote config)
- 5 milestones per season: 500 / 1000 / 2000 / 3500 / 5000 XP
- XP earned always counts toward both level-up AND season progress simultaneously (not split)
- Season XP resets to 0 at season end; level XP and total XP are unaffected

**Milestone Rewards (per season, example):**
| Milestone | Reward |
|-----------|--------|
| 500 XP | 100 coins |
| 1000 XP | Hint Token ×5 |
| 2000 XP | Season exclusive theme (e.g. "Cherry Season" gradient) |
| 3500 XP | 300 coins + season emoji pack |
| 5000 XP | Season exclusive dot shape + "Season Champion" badge |

**Season content (pre-baked for 6 seasons / 1 year):**

| Season | Name | Palette | Exclusive |
|--------|------|---------|-----------|
| 1 | Cherry Blossom 🌸 | `#FFE4F0 → #FFF0FA` | Petal gradient theme + sakura emoji pack |
| 2 | Ocean Depths 🌊 | `#E0F4FF → #F0FAFF` | Deep blue theme + wave emoji pack |
| 3 | Golden Harvest 🌾 | `#FFF8E0 → #FFFAF0` | Amber theme + harvest emoji pack |
| 4 | Northern Lights 🌌 | `#E8F0FF → #F0E8FF` | Aurora theme + star emoji pack |
| 5 | Ember Forest 🍂 | `#FFF0E8 → #FFF8F0` | Rust/orange theme + leaf emoji pack |
| 6 | Frost Crystal ❄️ | `#F0F8FF → #F8F0FF` | Ice blue theme + snowflake emoji pack |

**Remote Config:**
- URL: GitHub Gist (JSON, publicly readable, free)
- Format:
  ```json
  {
    "active_season": 1,
    "season_name": "Cherry Blossom 🌸",
    "season_end": "2026-06-30",
    "milestones": [500, 1000, 2000, 3500, 5000]
  }
  ```
- Fetched on app launch via `HTTPRequest` node; cached in SaveData
- Fallback: if no internet or fetch fails, use last cached season (or Season 1 if first launch)
- Fetch timeout: 3 seconds; non-blocking (game loads normally regardless)

**Season progress in SaveData:**
```gdscript
var season_xp: int = 0           # resets each season
var season_number: int = 1        # current season
var season_claimed: Array[bool]   # [false, false, false, false, false] — which milestones claimed
var season_badge: String = ""     # "season_1_champion" etc.
```

**Claiming rewards:**
- Season tab shows milestone nodes on a progress track (visual journey map)
- Unclaimed reached milestones pulse with a glow animation
- Tap to claim — reward added to inventory, milestone marked claimed
- Rewards don't expire mid-season; season badge expires if not claimed before reset

---

## 3. Retention Features

### Streak Freeze
- Purchased in XP Shop (300 XP each, max 2 held)
- Auto-activates when `is_daily_done_today()` would return false on a new day AND player had a streak ≥ 2
- Shows toast: "Streak Freeze used 🧊 Your X-day streak is safe!"
- Does not activate if player has no streak to protect
- `SaveData.streak_freezes: int` tracks held count

### Auto-Save / Resume
- After every `_on_submit_pressed()`, save game state to `SaveData`:
  ```gdscript
  var resume_mode: int             # GameMode enum
  var resume_secret: Array[int]    # the hidden sequence
  var resume_history: Array        # all guesses so far
  var resume_campaign_level: int   # if CAMPAIGN
  ```
- On game launch (after splash), if `resume_secret` is non-empty: show "Resume?" prompt
- Resume reconstructs the board from history — no cheating possible (secret already set)
- Cleared on game end (win/loss) or "New Game"
- Does NOT save Blitz timer state (timers don't resume)

### Comeback Mechanic
- Tracked silently via `SaveData.consecutive_losses: int`
- After 3 consecutive losses in Classic/Easy/Hard: `_comeback_active = true`
- When `_comeback_active`: `max_guesses += 1` OR `slots = max(3, slots - 1)` (whichever applies)
- Resets on any win, never shown to player explicitly
- Does not apply to Daily, Campaign, Time Trial, Sudden Death

### First Win of Day Bonus
- `SaveData.last_first_win_date: String` — tracks last date bonus was given
- On first win of calendar day: XP × 2 + 15 coins
- Toast notification: "First win bonus! ×2 XP ☀️"
- Stacks with combo multiplier

### Weekly Challenge
- Seeded from ISO week number: `Time.get_datetime_dict_from_system()["week"]`
- Config: 5 slots, 6 colors, 8 guesses
- Reward: 200 XP + 50 coins
- One attempt per week (same gating as daily: `SaveData.weekly_last_week: int`)
- Shown on Mode Select as a 7th card with countdown to reset
- Share text includes "Weekly #N"

### Personal Records
- Tracked per mode in SaveData:
  ```gdscript
  var personal_bests: Dictionary  # mode_name -> {min_guesses, min_time_ms}
  ```
- Updated in `_finish_game()` if new record
- On result screen: if record broken, show "New PB 🏅" badge with brief scale animation
- Shown in Stats screen per mode

---

## 4. New Game Modes

All new modes added to `GameMode` enum and Mode Select screen.

### Mystery Mode
- Slots count is hidden at round start (randomly 3–5, same as Classic)
- Board shows only 1 slot initially
- After each submitted guess, one additional slot fades in (up to the true slot count). Slots are always revealed left-to-right regardless of feedback.
- Feedback: count-only pips (same as Classic)
- Max guesses: 12 (extra allowance for the exploration mechanic)
- XP reward: 1.5× Classic

### Time Trial
- 5 Classic puzzles back-to-back (3–4 slots, 5 colors each)
- Single cumulative timer counting up from 0
- No per-puzzle timer pressure — just total time
- Score: `puzzles_solved × 1000 - total_seconds`
- Result screen shows score + time breakdown per puzzle
- Personal best tracked separately: `pb_time_trial_score`
- Interstitials: never during Time Trial session

### Duo Mode
- Two independent 4-slot, 5-color secrets generated simultaneously
- Board shows two side-by-side grids, each with their own history
- One shared palette row at bottom
- Submitting a guess evaluates it against **both** secrets independently — each grid gets its own feedback pips
- Win: both grids solved. Loss: either grid runs out of guesses (10 each)
- Palette selection applies to both boards simultaneously — same color placed in same slot index on both

### Sudden Death
- Standard Classic rules BUT: any submitted guess with 0 exact matches = instant loss
- (Partial matches allowed — only completely wrong guesses kill you)
- Locked behind Level 10 on Mode Select (grayed out with "Unlock at Level 10")
- No hints available
- XP reward: 2× Classic on win

### Sandbox
- No secret sequence randomly generated — player sets their own target
- Step 1: Player builds their own secret by tapping palette in a "set sequence" UI
- Step 2: Play as normal against that sequence
- No XP, no coins, no streak effect
- Hints always free (no ad, no token)
- "Reveal" button always visible
- Useful for practicing logic or showing the game to someone

---

## 5. Game Feel

### Combo System
- `SaveData.current_combo: int` — consecutive wins without hint use
- Combo breaks on: any loss, any hint used (token or rewarded ad), mode change
- XP multipliers:
  | Combo | Multiplier |
  |-------|-----------|
  | 0–1 | 1.0× |
  | 2 | 1.5× |
  | 3 | 2.0× |
  | 4+ | 2.5× |
- UI: small flame icon `🔥` in header showing combo count
- On combo increase: flame bounces with scale tween + warm haptic pulse
- Combo count shown on result screen alongside XP earned

### Puzzle History / Archive
- Every completed game appended to `SaveData.puzzle_history: Array[Dictionary]`:
  ```gdscript
  {"date": "2026-04-19", "mode": "CLASSIC", "guesses": 4, "won": true,
   "secret": [0,2,3,1], "slots": 4, "time_ms": 45000}
  ```
- Capped at 200 entries (rolling, oldest removed)
- Accessible from Stats screen: "Archive" button
- Archive screen: scrollable list grouped by date, tap to expand and see secret + guess count

### Reaction Messages
- Shown in header status area after each submitted guess
- Message selected from a tiered pool based on `exact` count and `guesses_remaining`:
  | Condition | Sample messages |
  |-----------|----------------|
  | exact == 0, first guess | "Cold start — keep going", "No hits yet, adjust your approach" |
  | exact == 0, guess ≥ 4 | "Still searching… think differently", "Zero exact — time to rethink" |
  | exact == 1 | "One locked in!", "Warm — 1 confirmed" |
  | exact == slots - 1 | "So close — one slot away!", "One more to crack it!" |
  | exact == slots | (win — handled by win flow) |
  | guesses_remaining == 1 | "Last chance!", "Final attempt — make it count" |
- Messages rotate randomly within tier (3–4 per tier, no repeats in a session)

### Dot Trail Animation
- On drag start from palette dot: create a `Line2D` node following touch position
- Line2D color matches the dragged dot color, width 4px, fades via modulate alpha tween
- Trail fades to 0 alpha over 200ms after drag ends or dot is dropped
- Cleared and freed after fade completes

---

## 6. Stats & Social

### Percentile Comparison (Daily Challenge)
- After completing Daily Challenge, result sheet shows: "You solved in N guesses — better than X% of players"
- X% computed deterministically:
  - Generate a simulated normal distribution centered at 5 guesses, σ=1.5
  - Seed from today's date (same for all players)
  - Find what percentile the player's guess count falls in
- No server required. Recomputed each time result is shown.

### Stats Deep Dive
Stats screen gains an expandable "Deep Dive" section:
- **Win rate sparkline:** last 30 games as a tiny `W/L` bar chart (Canvas-drawn)
- **Average guesses per mode:** table showing avg and best for each mode played
- **Best day of week:** which weekday you win most (computed from puzzle_history)
- **Longest session:** most games in one sitting (gap >30min = new session)
- **Total time played:** sum of all `time_ms` in puzzle_history

---

## 7. SaveData Changes

### New fields
```gdscript
# Ad system
var loss_count_since_ad: int = 0
var next_ad_after_losses: int = 3

# Consumable tokens
var hint_tokens: int = 0          # already exists, now actually used
var second_chance_tokens: int = 0
var extra_guess_tokens: int = 0
var streak_freezes: int = 0

# XP Boost
var xp_boost_end_time: int = 0    # Unix timestamp; 0 = no active boost

# Season
var season_xp: int = 0
var season_number: int = 1
var season_claimed: Array = [false, false, false, false, false]
var season_badge: String = ""
var season_config_cache: Dictionary = {}  # last fetched remote config

# Retention
var consecutive_losses: int = 0
var last_first_win_date: String = ""
var weekly_last_week: int = 0
var personal_bests: Dictionary = {}  # mode -> {min_guesses, min_time_ms}
var current_combo: int = 0

# Resume
var resume_mode: int = -1
var resume_secret: Array = []
var resume_history: Array = []
var resume_campaign_level: int = 0

# Puzzle history
var puzzle_history: Array = []

# Shop
var active_sound_pack: String = "default"
var active_share_emoji: String = "default"
var active_board_skin: String = "default"
var unlocked_sound_packs: Array = []
var unlocked_share_emoji: Array = []
var unlocked_board_skins: Array = []
```

### New save section `[tokens]`
```
hint_tokens=3
second_chance_tokens=1
extra_guess_tokens=0
streak_freezes=2
xp_boost_end_time=0
```

### New save section `[season]`
```
season_xp=1240
season_number=1
season_claimed=[false,true,false,false,false]
season_badge=""
```

---

## 8. New Files Required

| File | Purpose |
|------|---------|
| `scripts/SeasonManager.gd` | Autoload — fetches remote config, manages season state, milestone claiming |
| `scripts/ShopManager.gd` | Autoload — shop catalog, purchase logic, token consumption |
| `scripts/ComboManager.gd` | Autoload — combo tracking, multiplier calculation |

These are extracted from Main.gd to keep it from growing further. Each is small (<150 lines).

---

## 9. Files Modified

| File | Change |
|------|--------|
| `scripts/Main.gd` | Combo UI, reaction messages, dot trail, resume prompt, comeback mechanic, first-win bonus, new mode dispatch |
| `scripts/SaveData.gd` | All new fields above |
| `scripts/AdManager.gd` | Interstitial logic: loss-only trigger; add native ad support |
| `scripts/DailyChallenge.gd` | Percentile computation; extend share text for all modes + emoji pack support |
| `scripts/Tutorial.gd` | Visual restyle only (from UI rework spec) |
| `scenes/Main.tscn` | Rewards screen node, new mode buttons |

---

## 10. Out of Scope (This Phase)
- Real multiplayer (Duo Mode is single-device, two puzzles)
- Push notifications for daily challenge reminders
- Cloud save / cross-device sync
- Real leaderboard backend (percentile is simulated)
- In-app review prompt
- Onboarding for new modes (future Tutorial update)
