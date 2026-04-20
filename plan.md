# NEURAL DOTS — Game Evolution Plan
**"Guess the Dots" → A Daily Habit-Forming Puzzle Experience**

_Created: 2026-04-01 | Next review: 2026-05-01_

---

## EXECUTIVE SUMMARY

**Guess the Dots** is a Mastermind/Wordle-style color-pattern puzzle game built in Godot 4.
The game has solid bones: clean logic, AdMob integration, tutorial, haptics, and a dark theme.

**The goal of this plan** is to transform it from a single-session toy into a game that people
open every single day — by adding a futuristic visual identity, a compelling daily loop,
a progression system, and smarter ad placement. Every feature serves one of three metrics:

- **D1 Retention** — do new players come back the next day?
- **D7 Retention** — are players still playing after a week?
- **ARPU** — revenue per user through ethical, non-disruptive ads + optional IAP

---

## PART 1 — FUTURISTIC UI OVERHAUL

### 1.1 Visual Identity: "NEURAL GRID"

The new aesthetic is **cyberpunk / holographic HUD** — the premise being that the player
is a hacker/analyst cracking a neural network's color encryption.

**Color Palette (theme: Neon Core — default):**
| Role            | Color      | Hex       |
|-----------------|------------|-----------|
| Background      | Deep void  | `#04030A` |
| Panel surface   | Dark glass | `#0A0F1E` |
| Panel border    | Cyan neon  | `#00E5FF` |
| Accent / CTA    | Magenta    | `#FF006E` |
| Warning / score | Gold neon  | `#FFD600` |
| Success         | Green neon | `#00FF88` |
| Danger          | Red neon   | `#FF3333` |
| Muted text      | Ice grey   | `#8899BB` |

**Typography:**
- All UI labels: uppercase, wider letter spacing
- Header font size 52px, subheader 28px, body 20px
- Use `\n` padding to give breathing room
- Numbers: monospaced "digital" feel (custom font or system mono)

---

### 1.2 Background: Animated Hex Grid

**File:** `shaders/hex_grid.gdshader` (new)

- Scrolling hexagonal grid over deep void background
- Grid lines glow faint cyan (`#00E5FF` at 8% opacity)
- Subtle scanline pass (horizontal lines at 2px every 6px, 4% opacity)
- One `ShaderMaterial` on `Background` ColorRect node
- Animation: slow upward scroll at 8px/sec (barely perceptible — ambience only)
- On win: grid briefly pulses bright and saturates for 0.6s
- On loss: grid dims and desaturates to grey for 0.6s

**Fallback if shader is too complex for MVP:** use a `TextureRect` with a hand-made
tileable hex pattern image at low opacity.

---

### 1.3 Panel / Card Redesign

Every panel gets the **glassmorphism-neon** treatment:

```
Background:  rgba(10, 15, 30, 0.92)
Border:      1.5px, Color(0, 0.9, 1, 0.35)   ← faint cyan rim
Inner glow:  shadow offset (0,0) spread 12px, Color(0, 0.9, 1, 0.06)
Corner radius: 20px (less round than current 22px — slightly more "tech")
```

Panel hierarchy (z-depth via color only, no real elevation):
1. **Background** — `#04030A`
2. **Card panels** — `#0A0F1E` with cyan rim
3. **Popups/overlays** — `#0D1425` with magenta rim

---

### 1.4 Button Redesign

| State    | Background          | Border              | Text       |
|----------|---------------------|---------------------|------------|
| Normal   | `#0F1A30`           | cyan 25% alpha      | Ice white  |
| Hover    | `#1A2E50`           | cyan 55% alpha      | Bright white + faint glow |
| Pressed  | `#060C1A`           | cyan 15% alpha      | Dimmed     |
| Disabled | `#080D18` at 40%    | none                | Muted grey |
| CTA      | Magenta gradient    | magenta 80% alpha   | White bold |

**CTA buttons** (New Game, Submit/TRANSMIT):
- Magenta-to-purple diagonal gradient background
- On hover: "neon flicker" — brightness bounces 100%→130%→100% in 0.12s
- On press: brief white flash (0.06s), scale 0.96

---

### 1.5 Color Dot Buttons (Palette)

New size: **100×100px** (up from 84×84)

Each dot:
- Filled with its color
- Outer glow ring: 4px border matching its color at 90% alpha
- Outer ring glow radius: 8px (via `draw_circle` in `_draw()` override or a drop-shadow stylebox)
- Selected state: ring becomes 8px, glow expands, scale 1.08, brightness 1.2
- Hover: gentle scale pulse (1.0 → 1.06, 0.1s ease-out)
- Drag preview: larger 72×72px, with bright ring

**Dot Color Names (rename for theme):**
| Old Name | New Name    | Color     |
|----------|-------------|-----------|
| Red      | CRIMSON     | `#ef4444` |
| Blue     | AZURE       | `#3b82f6` |
| Green    | MATRIX      | `#22c55e` |
| Yellow   | SOLAR       | `#facc15` |
| Purple   | VOID        | `#a855f7` |

*(Names shown as tooltips only — IDs stay as color indices internally)*

---

### 1.6 Slot Buttons

New size: **100×100px**

Empty slot:
- Dark fill `#0D1825` at 60% alpha
- Dashed cyan border (simulate with stylebox border at 25% alpha)
- Center: small `◇` unicode diamond in muted cyan (as Label child)
- "Scanning" animation: dashed border rotates slowly (fake — alternate two styles every 1s)

Filled slot:
- Filled with dot color
- Solid bright border in that color at 60% alpha
- No inner icon

Hover: slight scale 1.04, border brightens

---

### 1.7 Text / Label Renames (Futuristic Vocabulary)

| Current Label           | New Label                             |
|-------------------------|---------------------------------------|
| "Guess the Dots"        | "GUESS THE DOTS" (stylized title)     |
| "Find the hidden dot pattern..." | "CRACK THE NEURAL SEQUENCE"  |
| "New Game"              | "NEW SEQUENCE"                        |
| "How to Play"           | "BRIEFING"                            |
| "Quit"                  | "DISCONNECT"                          |
| "Build your guess"      | "BUILD SEQUENCE"                      |
| "Code length: N dots"   | "SEQUENCE LENGTH: N  ·  REPEATS ON"   |
| "Guess N / 10"          | "ATTEMPT N / 10"                      |
| "Palette"               | "COLOR MATRIX"                        |
| "Current guess"         | "ACTIVE SEQUENCE"                     |
| "Previous guesses"      | "ATTEMPT LOG"                         |
| "Submit ✓"              | "TRANSMIT ▶"                          |
| "Clear Guess"           | "WIPE"                                |
| "Undo"                  | "REVERT"                              |
| "Watch Ad for Hint — Reveal 1 Dot" | "SCAN [AD] — REVEAL 1 NODE" |
| "N slots remaining"     | "N NODES OPEN"                        |
| "All slots filled"      | "SEQUENCE COMPLETE — TRANSMIT?"       |
| "You Win! 🎉"           | "SEQUENCE DECODED"                    |
| "Game Over"             | "DECRYPTION FAILED"                   |
| "The answer was:"       | "ACTUAL SEQUENCE:"                    |
| "Secret pattern:"       | "CONFIRMED SEQUENCE:"                 |
| "Exact: N"              | "LOCKED: N"                           |
| "Wrong spot: N"         | "MISALIGNED: N"                       |
| "No match"              | "NULL SIGNAL"                         |
| "Main Menu"             | "MAIN GRID"                           |

---

### 1.8 History Row Redesign

Each row in the Attempt Log:
- Slightly darker card: `#080E1C`
- Left accent: 3px vertical bar in green (win) or yellow (partial) or red (0 match)
- Guess number as monospaced `[01]` `[02]` etc.
- Feedback pips: small neon diamonds (◆) instead of circles
  - Exact = green neon diamond  
  - Misplaced = gold neon diamond
- Row slides in from left with 0.12s ease-out on add (staggered)
- Most recent row briefly glows on entry

---

### 1.9 Result Screen Redesign

**Win ("SEQUENCE DECODED"):**
- Background: animated particle burst (radial, neon cyan/green sparks)
- Title in green neon with subtle glow
- Dots displayed large (72px) with glow matching each color
- Stats: "Cracked in N attempts — Efficiency: X%"
- Share button (new!) — generates text grid for social sharing
- XP earned display: "+NNN XP" in gold with count-up animation

**Loss ("DECRYPTION FAILED"):**
- Background: brief static/glitch effect (0.4s), then dim
- Title in red neon
- Answer revealed with dramatic slide-in, one dot at a time (0.08s stagger)
- "SECOND CHANCE" button if they haven't used it this game (rewarded ad)
- "Watch [AD] to reveal your XP anyway" — even losses earn reduced XP

---

### 1.10 Menu Screen Redesign

New layout (top-to-bottom):
1. Animated dots logo (reuse Splash code, smaller, looping)
2. Game title "GUESS THE DOTS" — large, glowing
3. **Daily Challenge card** — prominent featured card with:
   - "DAILY SEQUENCE #N" with today's number
   - Streak indicator: "🔥 N-day streak"
   - Status: "COMPLETED" (with check) or "AVAILABLE NOW" (pulsing)
   - Completion badge if done
4. Player stats bar: Level badge + XP bar + coin count
5. Mode select buttons:
   - NEW SEQUENCE (Classic)
   - DAILY SEQUENCE  
   - BLITZ PROTOCOL (timer mode)
6. Bottom row: BRIEFING · STATS · ACHIEVEMENTS · SETTINGS
7. Banner ad at the very bottom (below safe area / navigation bar)

---

## PART 2 — DAILY RETENTION SYSTEM

### 2.1 Daily Challenge Mode

**How it works:**
- One unique puzzle per day, generated by seeding the RNG with today's date
- Same puzzle for every player worldwide (like Wordle)
- Can only be played once per day
- 4 slots, 5 colors, 8 guesses (slightly harder than Classic)

**Persistence (SaveData.gd):**
```
daily_last_date: String     # "2026-04-01"
daily_streak: int           # consecutive days completed
daily_max_streak: int       # all-time best streak
daily_history: Dictionary   # date → { guesses, won, guesses_used }
```

**Seed generation:**
```gdscript
# Deterministic from date string
func get_daily_seed(date: String) -> int:
    var hash_val := 0
    for ch in date:
        hash_val = hash_val * 31 + ch.unicode_at(0)
    return hash_val
```

**Share result (like Wordle):**
```
NEURAL DOTS — Daily #42
🔴🔵🟣
🟡⬛🔴
🟢🟢🟢 ✓ (3/8)
```
Generates text to clipboard + optional OS share sheet.

---

### 2.2 Login Streak & Daily Reward

Tracked in `SaveData.gd`:
```
last_login_date: String
login_streak: int
```

On app open, if `last_login_date != today`:
1. Increment `login_streak` (reset to 1 if missed a day)
2. Show **Daily Login Reward popup** with animated coin drop
3. Award coins based on streak day (cycles every 7 days):

| Day | Reward       |
|-----|-------------|
| 1   | 20 coins    |
| 2   | 30 coins    |
| 3   | 50 coins    |
| 4   | 70 coins    |
| 5   | 100 coins   |
| 6   | 150 coins   |
| 7   | 250 coins + bonus spin (Lucky Spin popup) |

**Lucky Spin:** Simple 6-segment wheel (cosmetic): either extra coins, a hint token,
a 2-hour XP boost, or "Nice try — free retry tomorrow".

---

### 2.3 XP & Level System

**XP Sources:**
| Action                                | XP     |
|---------------------------------------|--------|
| Complete any game (win or lose)       | +15    |
| Win a Classic game                    | +50    |
| Win in ≤ 3 guesses (Perfect)          | +100   |
| Win daily challenge                   | +75    |
| Complete daily challenge (any result) | +30    |
| First win of the day                  | +25    |
| Maintain daily login streak (×streak) | ×1.0 to ×1.5 multiplier |
| Watch rewarded ad (coin doubler)      | ×2 XP for that game |

**Level table (50 levels):**
- Level 1–10: 200 XP per level
- Level 11–20: 400 XP per level
- Level 21–30: 700 XP per level
- Level 31–40: 1000 XP per level
- Level 41–50: 1500 XP per level

**Level-up rewards:**
- Every level: 100 coins
- Level 5: Unlock "SYNTHWAVE" theme
- Level 10: Unlock "MATRIX" theme + Hexagon dot shape
- Level 15: Unlock Diamond dot shape
- Level 20: Unlock "SOLAR FLARE" theme
- Level 25: Unlock Star dot shape
- Level 30: Unlock "VOID PROTOCOL" theme
- Level 50: Unlock "GOLDEN CIRCUIT" theme (max prestige)

---

### 2.4 Coin Economy

**Coin Sources:**
- Daily login reward (20–250 per day)
- Level-up bonus (100 per level)
- Achievement unlock bonus (50–500 per achievement)
- Watch rewarded ad (50 coins — optional "EARN COINS" button in menu)
- Win bonus: 10 coins per win
- IAP coin packs (optional monetization)

**Coin Spends:**
- Hint token (reveal 1 dot in-game): 100 coins OR watch ad
- Extra guess pack (+3 guesses on loss): 150 coins OR watch ad
- Cosmetic theme unlock: 500–800 coins
- Dot shape unlock: 300–500 coins
- Lucky Spin extra spin: 75 coins

---

### 2.5 Achievement System

**File:** `scripts/AchievementManager.gd` (new)

Achievements are stored in `SaveData.gd` as a dictionary of booleans.
A pop-up notification (slides in from top, 2.5s, then slides out) fires on unlock.

**Achievement List:**

| ID                   | Name                | Description                          | Reward     |
|----------------------|---------------------|--------------------------------------|------------|
| `first_win`          | FIRST DECODE        | Win your first game                  | 50 coins   |
| `win_10`             | PATTERN HUNTER      | Win 10 games                         | 100 coins  |
| `win_50`             | GRID MASTER         | Win 50 games                         | 200 coins  |
| `win_100`            | NEURAL ARCHITECT    | Win 100 games                        | 500 coins  |
| `perfect_once`       | SURGICAL PRECISION  | Win in 3 guesses or fewer            | 150 coins  |
| `perfect_5`          | SYSTEM CRACKER      | Win in ≤3 guesses 5 times            | 300 coins  |
| `daily_7`            | WEEK DECODED        | Complete 7 daily challenges           | 200 coins  |
| `streak_7`           | STREAK PROTOCOL     | Daily challenge streak of 7           | 300 coins  |
| `streak_30`          | IRON GRID           | Daily challenge streak of 30          | 1000 coins |
| `no_hints_10`        | PURE SIGNAL         | Win 10 games without any hints        | 150 coins  |
| `played_100`         | VETERAN DECODER     | Play 100 games                        | 200 coins  |
| `login_7`            | DAILY OPERATIVE     | Log in 7 days in a row               | 150 coins  |
| `login_30`           | GRID ADDICT         | Log in 30 days in a row              | 500 coins  |
| `win_blitz`          | SPEED RUNNER        | Win a game in Blitz Mode             | 100 coins  |
| `blitz_30s`          | LIGHTNING CRACK     | Win a Blitz game in under 30 seconds | 300 coins  |
| `share_result`       | BROADCAST SIGNAL    | Share a result to social media       | 50 coins   |
| `ad_watcher`         | SYSTEM SUPPORTER    | Watch 10 rewarded ads                | 100 coins  |
| `all_achievements`   | OMEGA PROTOCOL      | Unlock all other achievements        | Golden Circuit theme |

---

### 2.6 Statistics Dashboard

**Scene:** `scenes/StatsScreen.tscn` (new)
**Script:** `scripts/StatsScreen.gd` (new)

Displayed stats:
- **Overview tab:**
  - Total games / wins / losses
  - Win rate % (animated radial gauge, neon cyan)
  - Current win streak / Best win streak
  - Total XP / Level with progress bar
  
- **Guess Distribution tab:**
  - Bar chart: how often player wins in 1, 2, 3... 10 guesses
  - Highlight the player's "sweet spot"
  - Average guesses to win
  
- **Daily Challenge tab:**
  - Current streak / Max streak
  - Calendar heatmap (last 30 days — green=won, red=lost, grey=not played)
  - Last 7 daily results as emoji grid preview
  
- **Coin / Economy tab:**
  - Total coins earned lifetime
  - Total hints used
  - Ads watched

---

### 2.7 Progression Notifications

Notify players (push notification — requires OS permission) for:
- "Daily Challenge is ready" — once per day at 9 AM local time
- "Your N-day streak is waiting!" — if player hasn't played by 8 PM
- "New week, new sequence — come back!" — every Monday

---

## PART 3 — EXPANDED AD STRATEGY

### 3.1 Current Ad Setup (keep)

| Type           | Trigger                    | Frequency |
|----------------|----------------------------|-----------|
| Banner         | Menu screen visible        | Always    |
| Interstitial   | After game finishes        | Every 2–4 games |
| Rewarded       | "Reveal 1 Node" hint       | On demand |

### 3.2 New Ad Placements

**P4 — Rewarded: Second Chance**
- Trigger: Game over screen (loss only)
- Placement: Prominent "SECOND CHANCE [WATCH AD]" button above "MAIN GRID"
- Reward: +3 bonus guesses (extend MAX_GUESSES from 10 to 13)
- Limit: Once per game, once per session
- Implementation: `second_chance_used: bool` flag in game state
- UX copy: "Decryption failed. Watch a short ad for 3 more attempts."

**P5 — Rewarded: XP / Coin Doubler**
- Trigger: Shown on result screen (both win and loss) as a secondary option
- Placement: Small button below "PLAY AGAIN" — "DOUBLE REWARDS [AD]"
- Reward: 2× XP and coins for that completed game
- Limit: Once per game
- UX copy: "Double your signal gains — watch a short ad."

**P6 — Rewarded: Daily Challenge Reveal**
- Trigger: Failed daily challenge result screen only
- Placement: "REVEAL SEQUENCE [AD]" button below result
- Reward: Reveals the correct answer without ending the streak (player still marked "attempted")
- Limit: Once per day challenge

**P7 — Rewarded: Extra Hint**
- Current: 1 hint per game (free with ad)
- New: Allow up to 3 hints per game — 2nd and 3rd hint each require their own rewarded ad
- Button text updates: "SCAN #1 [AD]" → "SCAN #2 [AD]" → "SCAN #3 [AD]"

**P8 — Rewarded: Earn Coins**
- Trigger: Idle button in menu and stats screen
- Placement: "EARN 50 COINS [AD]" in the coin balance header area
- Limit: 5 times per day (cap to prevent abuse)
- Recharges every 15 minutes (show countdown timer)
- This surfaces the rewarded ad inventory to non-hint-users

**P9 — Rewarded: Blitz Time Extension**
- Trigger: When Blitz mode timer drops below 15 seconds
- Placement: Auto-prompted (not forced — player can dismiss)
- Reward: +30 seconds added to timer
- Limit: Once per Blitz game

**P10 — Rewarded: Lucky Spin Extra Turn**
- Trigger: After the daily free spin is used
- Placement: "SPIN AGAIN [AD]" button on the Lucky Spin popup
- Reward: One more spin on the reward wheel
- Limit: 2 extra spins per day

**P11 — Banner: Stats / Achievements Screens**
- Show banner when player is browsing Stats or Achievements
- Same unit ID as menu banner — just call `show_banner()` when entering those screens
- Remember to `hide_banner()` when entering gameplay

**P12 — Interstitial: Post-Tutorial**
- Trigger: First time only, after the tutorial finishes
- Gate: Only if `tutorial_seen` count >= 1 and player is being sent to menu
- Note: Don't show on subsequent tutorial views (too aggressive)

**P13 — Interstitial: App Resume After Long Absence**
- Trigger: `_notification(NOTIFICATION_WM_WINDOW_FOCUS_IN)` after >30 minutes background
- Show only if it's been ≥2 games since last interstitial
- Implementation: track `last_focused_time` timestamp
- Do NOT show if player was mid-game when backgrounded

**P14 — Native/Inline Ad in Attempt Log (Stretch Goal)**
- After guess #5, insert a "SPONSORED SIGNAL" row in the history
- Same card styling as history rows but with a small "ad" label and banner content
- Requires AdMob Native Ad support in the Godot plugin — verify availability first

### 3.3 Ad Frequency Caps

To avoid user frustration (kills retention worse than any mechanic):
- **New player grace period:** NO interstitials or inline ads for the first 3 games ever
  played. Banner and rewarded (opt-in) are still OK. Research confirms new players are
  most likely to churn — ad-free onboarding significantly improves D1/D3 retention.
  Tracked via `SaveData.games_played < 3` check in `AdManager.on_game_finished()`.
- **Interstitial:** No more than 1 every 3 minutes (time-cap in addition to game-cap)
- **Rewarded:** Always opt-in, no cap (user controls this)
- **Banner:** Always on — but hidden during gameplay (maintains focus)
- **Total forced ads per session:** Max 3 interstitials per 30-minute session

### 3.4 Remove-Ads IAP

- Price: **$2.99**
- Removes: Banner, Interstitial (P4/P12/P13), Inline native ad (P14)
- Keeps: All rewarded ads (player still opts in for hints, coins, second chance)
- Stored in `SaveData.gd` as `ads_removed: bool`
- Shown prominently as "REMOVE ADS" in Settings / hamburger menu
- On menu screen: small "★ Remove Ads" text link near banner area

---

## PART 4 — NEW GAME MODES

### 4.1 Classic Mode (current)
- 3–5 slots, 5 colors, 10 guesses
- Random every game
- XP and coins awarded
- Unchanged from current logic

### 4.2 Daily Sequence Mode (new — see Part 2.1)
- 4 slots, 5 colors, 8 guesses
- Date-seeded, same worldwide
- Once per day
- Shareable emoji result
- Streak tracking

### 4.3 Blitz Protocol Mode (new)
- 5 slots, 5 colors, unlimited guesses
- 90-second countdown timer (shown as neon progress bar at top)
- Guess as fast as possible — score = (time remaining × 10) + (10 − guesses used × 50)
- High score saved and shown
- Ad: rewarded time extension when <15s remaining
- Sound design is especially important here (ticking, urgency)
- XP = base 30 + (score / 100) bonus

### 4.4 Hard Mode (new)
- 5–6 slots, 6 colors (add Orange: `#f97316`)
- 10 guesses
- Each guess must use previous "exact" clues (like Wordle Hard Mode):
  any dot marked "exact" in a previous guess must be placed in the same slot
- UI shows which slots are "locked" from previous exact hits
- More XP: ×1.5 multiplier on win

### 4.5 Zen Mode (new)
- 4 slots, 5 colors, unlimited guesses
- No timer, no pressure
- Fewer ads (no interstitial after, just banner on menu)
- Minimal XP (×0.5 multiplier)
- Target: new players and casual browsers
- Perfect entry-point after losing Classic

### 4.6 Mode Selection UI
- Mode select screen replaces direct "NEW SEQUENCE" flow
- Four cards in a 2×2 grid:
  - CLASSIC (always available)
  - DAILY (available once per day)
  - BLITZ (unlocks at Level 3)
  - ZEN (always available)
  - HARD (unlocks at Level 8) — greyed with "LOCKED: Lv.8" until then

---

## PART 5 — SOCIAL & SHARING

### 5.1 Share Result (Priority 1)
After any completed game, generate a shareable text:

```
NEURAL DOTS — Daily #42  🔐
🔴🔵🟣 ▸ ◆◆ ⬡
🟡⬛🔴 ▸ ◆ ⬡⬡
🟢🟢🟢 ▸ DECODED ✓
Solved in 3/8 — streak: 14 🔥
Play at [store link]
```

- Copy to clipboard button
- On Android: `OS.shell_open("share:...")` pattern
- Generate pure text (no image needed for MVP — images are expensive to render)

### 5.2 Challenge Mode (Post-Launch)
- Player selects their own secret sequence
- Game generates a short shareable code (base-36 encoded sequence)
- Friend opens game, enters code, plays against the same sequence
- "You challenged [friend] and they cracked it in N guesses!"

### 5.3 Weekly Leaderboard (Post-Launch)
- Weekly shared puzzle (server-seeded or globally agreed)
- Submit score (guesses used) anonymously
- Show "This week's top solvers: ≤3 guesses: 12% of players"
- No backend needed for MVP — use a free Firebase Realtime DB or leaderboard service

---

## PART 6 — SOUND DESIGN

**File:** `scripts/SoundManager.gd` (new — autoload singleton)

All sounds are generated procedurally via AudioStreamGenerator for MVP (avoids asset
licensing), or use royalty-free 8-bit/synth samples.

| Event                        | Sound Design                              |
|------------------------------|-------------------------------------------|
| Button tap                   | Short digital click (200ms, 800Hz sine)   |
| Dot placed in slot           | Soft tink (100ms, 1200Hz)                 |
| Slot cleared                 | Reverse tink                              |
| Guess submitted              | Whoosh + digital stamp                    |
| Exact match feedback         | Rising chime per exact dot                |
| Misplaced feedback           | Neutral blip                              |
| No match feedback            | Low thud                                  |
| Win                          | 3-note ascending fanfare, neon synth      |
| Loss                         | Descending drone, static crackle          |
| Level up                     | Triumphant 5-note synth burst             |
| Achievement unlock           | Notification chime (2 notes)              |
| Daily streak extend          | Warm confirmation tone                    |
| Hint used                    | Scanner beep + reveal chime               |
| Second chance granted        | Soft reboot sound                         |
| Coin collected               | Fast ascending ding ding                  |

Settings: Master volume, Music volume, SFX volume (sliders in hamburger menu)

---

## PART 7 — TECHNICAL ARCHITECTURE

### 7.1 New Files Required

| File                              | Purpose                                         |
|-----------------------------------|-------------------------------------------------|
| `scripts/SaveData.gd`             | Autoload — all persistence (XP, streak, coins, unlocks, stats) |
| `scripts/DailyChallenge.gd`       | Date-seeded puzzle generation + streak logic    |
| `scripts/AchievementManager.gd`   | Track achievements, fire unlock popups          |
| `scripts/SoundManager.gd`         | Autoload — audio management                     |
| `scripts/ThemeManager.gd`         | Manages active visual theme + unlocked cosmetics|
| `scenes/ModeSelectScreen.tscn`    | Mode selection UI                               |
| `scenes/StatsScreen.tscn`         | Statistics dashboard                            |
| `scenes/AchievementsScreen.tscn`  | Achievement browser                             |
| `scenes/DailyResultPopup.tscn`    | Daily challenge result + share                  |
| `scenes/LevelUpPopup.tscn`        | Level-up celebration overlay                    |
| `scenes/AchievementPopup.tscn`    | Achievement unlock notification                 |
| `scenes/DailyLoginPopup.tscn`     | Daily login reward popup                        |
| `shaders/hex_grid.gdshader`       | Animated background grid                        |

### 7.2 Existing Files to Modify

| File                  | Changes                                              |
|-----------------------|------------------------------------------------------|
| `Main.gd`             | Add mode parameter, XP/coin award, hook AchievementManager, second-chance ad |
| `Main.tscn`           | Full visual redesign — new colors, labels, layout    |
| `Splash.gd`           | Add neon glow effect, faster animation               |
| `AdManager.gd`        | Add P4–P13 ad placement logic, time caps, IAP check  |
| `ColorDotButton.gd`   | Add glow ring, hover animation, shape variant support|
| `SlotButton.gd`       | Add scanning animation, shape variant support        |
| `Tutorial.gd`         | Update copy to match new vocabulary                  |
| `project.godot`       | Register new autoloads (SaveData, SoundManager, etc.)|

### 7.3 SaveData Schema

```gdscript
# SaveData.gd — autoload singleton (user://save_data.cfg)

# --- Progression ---
var xp: int = 0
var level: int = 1
var coins: int = 0

# --- Stats ---
var games_played: int = 0
var games_won: int = 0
var current_win_streak: int = 0
var max_win_streak: int = 0
var guess_distribution: Array = [0,0,0,0,0,0,0,0,0,0]  # index = guesses used
var hints_used: int = 0
var ads_watched: int = 0
var perfect_wins: int = 0  # won in ≤ 3 guesses

# --- Daily ---
var daily_last_date: String = ""
var daily_streak: int = 0
var daily_max_streak: int = 0
var daily_history: Dictionary = {}  # "2026-04-01" → {won, guesses_used}

# --- Login ---
var last_login_date: String = ""
var login_streak: int = 0
var login_max_streak: int = 0
var daily_ad_coin_count: int = 0  # resets daily

# --- Unlocks ---
var ads_removed: bool = false
var unlocked_themes: Array = ["neon_core"]
var active_theme: String = "neon_core"
var unlocked_shapes: Array = ["circle"]
var active_shape: String = "circle"

# --- Achievements ---
var achievements: Dictionary = {}  # id → true/false

# --- Hint tokens ---
var hint_tokens: int = 0  # stored hints (from coin purchase)
```

### 7.4 Implementation Phases

**Phase 0 — Foundation (1–2 days):**
- Create `SaveData.gd` autoload with schema above
- Register autoloads in `project.godot`
- Basic load/save working

**Phase 1 — UI Overhaul (3–5 days):**
- Update `_apply_theme()` in `Main.gd` with NEURAL GRID palette
- Update all label text to futuristic vocabulary
- Resize dot and slot buttons to 100px
- Add glow ring to `ColorDotButton.gd`
- Redesign history rows with left accent bar + diamond pips
- Result screen win/loss redesign
- Menu screen new layout with daily challenge card placeholder

**Phase 2 — Daily System (2–3 days):**
- Implement `DailyChallenge.gd` with date seeding
- Add daily challenge mode to `Main.gd`
- Daily streak tracking in `SaveData.gd`
- Share result text generation

**Phase 3 — Progression (2–3 days):**
- XP award on game end
- Level-up detection and popup
- Coin economy basics
- Login streak + daily reward popup

**Phase 4 — Achievements (1–2 days):**
- `AchievementManager.gd`
- Achievement notification popup
- Achievements screen scene

**Phase 5 — Game Modes (2–3 days):**
- Blitz mode (timer)
- Hard mode (locked clues)
- Zen mode (no limit)
- Mode select screen

**Phase 6 — Expanded Ads (1–2 days):**
- Second Chance (P4)
- XP Doubler (P5)
- Daily Reveal (P6)
- Earn Coins (P8)
- Banner on Stats/Achievements (P11)
- Time caps and frequency logic

**Phase 7 — Sound (1–2 days):**
- `SoundManager.gd`
- Core SFX for buttons, guesses, win/lose
- Volume settings in hamburger menu

**Phase 8 — Polish (ongoing):**
- Hex grid shader background
- Particle effects on win
- Achievement screen cosmetics browser
- Stats screen full implementation
- Push notifications
- Remove-Ads IAP

---

## PART 8 — AD PLACEMENT MAP (Visual Summary)

```
┌─────────────────────────────────────────────────────────────┐
│  MENU SCREEN                                                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Daily Challenge Card (streak + status)              │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  NEW SEQUENCE  │  DAILY  │  BLITZ  │  ZEN           │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  STATS  │  ACHIEVEMENTS  │  SETTINGS  │  EARN COINS ←── P8 Rewarded
│  └──────────────────────────────────────────────────────┘   │
│  [BANNER AD]  ←── P1 Banner (always visible on menu)        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  GAMEPLAY SCREEN (no banner) ←── P1 banner hidden          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  ATTEMPT LOG                                         │   │
│  │  ...guess rows...                                    │   │
│  │  [guess #5+ → P14 Native inline ad — stretch goal]  │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  SCAN #1 [AD]  ←── P3 Rewarded hint                 │   │
│  │  SCAN #2 [AD]  ←── P7 Rewarded 2nd hint             │   │
│  └──────────────────────────────────────────────────────┘   │
│  (Blitz mode only: time bar low → P9 Rewarded +30s)         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  GAME OVER SCREEN                                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  DECRYPTION FAILED                                   │   │
│  │  Answer revealed                                     │   │
│  │  ┌────────────────────────────────────────────────┐  │   │
│  │  │  SECOND CHANCE [WATCH AD]  ←── P4 Rewarded     │  │   │
│  │  └────────────────────────────────────────────────┘  │   │
│  │  DOUBLE REWARDS [AD]  ←── P5 Rewarded               │   │
│  │  REVEAL SEQUENCE [AD] ←── P6 (daily only)           │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  [INTERSTITIAL fires here] ←── P2 (every 2-4 games) │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  WIN SCREEN                                                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  SEQUENCE DECODED ✓                                  │   │
│  │  +NNN XP  +NN coins                                  │   │
│  │  DOUBLE REWARDS [AD]  ←── P5 Rewarded                │   │
│  │  SHARE RESULT  ←── social sharing                    │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  [INTERSTITIAL fires here] ←── P2 (every 2-4 games) │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  STATS / ACHIEVEMENTS SCREENS                               │
│  [BANNER AD]  ←── P11 Banner (shown here too)              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  LUCKY SPIN POPUP (after daily login Day 7)                 │
│  SPIN AGAIN [AD]  ←── P10 Rewarded (up to 2 extra/day)     │
└─────────────────────────────────────────────────────────────┘
```

---

## PART 9 — COMPETITIVE ANALYSIS & INSPIRATION

### What makes Wordle work (apply to Daily mode):
- One puzzle per day → scarcity drives return visits
- Shared experience → social conversation
- Shareable result → free organic marketing
- No progression needed — simplicity IS the hook

### What makes Duolingo work (apply to streak system):
- Streak is the core retention mechanic — players fear breaking it
- Daily reward scales with streak length
- Streak freeze (purchasable) reduces churn from missed days
- Consider: "Streak Freeze" item purchasable for 150 coins

### What makes Royal Match / Candy Crush work (apply carefully):
- Lives system can frustrate — AVOID for puzzle game
- Level progression makes players feel movement
- "Almost!" states (lose by 1 guess) are perfect moments for Second Chance ads
- Collect currencies → spend currencies → satisfying loop

### What makes NYT Games suite work:
- Variety of modes keeps players engaged longer per session
- Stats and history make the game feel like a personal journal
- Minimal ads (premium model) — but we're ad-supported, so be tasteful

### Monetization benchmarks (mobile casual):
- **ARPU target:** $0.05–$0.20 per DAU per day from ads (rewarded video > interstitial > banner)
- **Rewarded video eCPM:** $8–25 (highest revenue per ad unit)
- **Interstitial eCPM:** $4–12
- **Banner eCPM:** $0.50–2
- **Remove Ads conversion:** ~3–8% of engaged users (worth implementing)
- **Retention targets:** D1: 40%+, D7: 20%+, D30: 8%+

### Research-validated retention data (2024):
- **Streak mechanics boost DAU by 20–35%** — this is the single highest-ROI feature
- **Optional rewarded ads improve retention 10–18%** (vs. forced ads which hurt it)
- **Daily challenges with 45–60% participation rate** strongly correlates with D7 retention >40%
- **Leaderboards + social sharing boost retention 15–25%**
- **First 3 games are the highest-churn window** — no forced ads in this period is critical
- **Win rate should be 88–92% for casual players** — currently variable (3–5 slots, rng)
  → Consider a "warm-up" first game with 3 slots always, to ensure early wins
- **Cosmetic unlocks drive 15–20% of long-term retention** for players who don't pay

---

## PART 10 — OPEN QUESTIONS & RISKS

| Question                               | Risk Level | Decision Needed              |
|----------------------------------------|------------|------------------------------|
| Push notifications — do we have them?  | Medium     | Research Godot Android push  |
| Native ads in Godot AdMob plugin?      | Medium     | Check plugin docs             |
| Backend needed for leaderboard?        | Low (stretch) | Firebase or skip for v1   |
| IAP plugin for Remove Ads?             | Medium     | Research Godot IAP plugins    |
| Daily challenge timezone handling?     | Low        | Use UTC date for seed        |
| Streak freeze item — add to economy?  | Low        | Yes, add after core is done  |
| Localization?                          | Low (v2)   | English only for v1          |
| Font licensing for futuristic type?    | Medium     | Use Google Fonts (open)      |

---

## VERSION TARGETS

| Version | Features                                                      |
|---------|---------------------------------------------------------------|
| v1.1    | Full UI overhaul (Part 1), SaveData foundation, basic XP/coins |
| v1.2    | Daily Challenge, login streak, share result                   |
| v1.3    | Achievements, Stats screen, Level-up popup                    |
| v1.4    | Blitz mode, Hard mode, Zen mode, Mode select screen           |
| v1.5    | Expanded ads (P4–P11), Second Chance, Coin Doubler            |
| v1.6    | Sound design, polish, shader background                       |
| v2.0    | Leaderboard, Challenge-a-Friend, IAP, Push notifications      |

---

_End of plan. All implementation work against this document should reference CHG numbers._
_Last updated: 2026-04-01_
