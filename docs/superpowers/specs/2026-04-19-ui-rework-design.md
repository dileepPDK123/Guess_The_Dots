# Guess the Dots — Full UI/UX Rework Design Spec
**Date:** 2026-04-19  
**Status:** Approved  
**Scope:** Complete visual rework + 10 new features. Core Mastermind concept preserved.

---

## 1. Visual System

### Color Palette
| Token | Value | Usage |
|-------|-------|-------|
| BG_GRADIENT | `#FFF1F9 → #FFF8F0 → #F0FFF8` | Screen background (pink-to-mint, 160deg) |
| PANEL | `rgba(255,255,255,0.75)` | Card/panel fill |
| PANEL_BORDER | `#FFD6E7` | Panel border (1px) |
| CTA_GRAD | `#F472B6 → #A78BFA` | Submit, New Game, primary buttons (135deg gradient) |
| CTA_SHADOW | `rgba(244,114,182,0.35)` | Button drop shadow |
| TEXT_PRIMARY | `#6B4E71` | Headings, important labels |
| TEXT_SECONDARY | `#C084B8` | Subheadings, hints, secondary info |
| TEXT_ACTION | `#9B7BAB` | Secondary button text |
| PIP_EXACT | `#22C55E` | Exact match pip / ring |
| PIP_MISPLACE | `#FACC15` | Misplaced pip / ring |
| PIP_EMPTY | `rgba(200,180,220,0.25)` | No-match pip |
| ACTIVE_ROW | `rgba(244,114,182,0.07)` | Current guess row fill |
| ACTIVE_BORDER | `rgba(244,114,182,0.4)` | Current guess row border |

### Dot Colors (unchanged)
| Name | Hex |
|------|-----|
| Red | `#EF4444` |
| Blue | `#3B82F6` |
| Green | `#22C55E` |
| Yellow | `#FACC15` |
| Purple | `#A855F7` |
| Orange (Hard only) | `#F97316` |

### Component Rules
- **Panels:** white glass (`rgba(255,255,255,0.75)`), `border-radius: 16px`, `1px solid #FFD6E7`, subtle shadow `0 4px 16px rgba(167,114,182,0.10)`
- **Primary buttons:** CTA gradient fill, `border-radius: 14px`, shadow `0 4px 14px rgba(244,114,182,0.35)`, white bold text
- **Secondary buttons:** white glass fill, muted `#9B7BAB` text, `1px solid rgba(249,168,212,0.3)`
- **Slot shape:** Rounded squares (`border-radius: 8px`) — not circles. Makes board rows scan faster.
- **Palette dots:** Circles (unchanged), `box-shadow: 0 2px 8px <color at 0.3 alpha>`, `border: 2px solid rgba(255,255,255,0.8)`
- **Selected palette dot:** scale 1.12, `outline: 2px solid <color at 0.4 alpha>`, `outline-offset: 3px`
- **Typography:** System sans-serif. Titles 40–48px, headers 28–34px, body 22–26px, labels 16–20px.

### Removed
- All `#051E28` / `#0F1E30` dark backgrounds
- All `#00E6FF` cyan neon borders
- All `#FF006E` magenta accents
- Cyberpunk vocabulary (TRANSMIT → SUBMIT, WIPE → CLEAR, REVERT → UNDO, SCAN → HINT)
- Hex grid shader background

---

## 2. Screen Architecture

### Splash Screen
- Pastel gradient background from frame 0
- Animation: dots fade in gently from center (no fly-in from corners), title fades up, tagline fades in
- Total duration: 2.5s (trimmed from 4.15s)
- No elastic/bounce — soft ease-in-out only

### Main Menu
- Centered white glass card, game title + subtitle
- Three buttons: **PLAY** (opens Mode Select), **HOW TO PLAY** (opens Tutorial), **STATS** (opens Stats sheet)
- Statistics button is a permanent menu item (not injected dynamically)

### Mode Select
- Bottom sheet, slides up from bottom (`0.3s ease-out`)
- 2×3 grid of mode cards: Classic, Easy, Blitz, Hard, Zen, Campaign
- Each card: mode name (bold), 1-line rule summary, icon
- Custom Puzzle entry point: small "🔗 Play a friend's code" link below grid

### Game Screen (single layout, no scroll)
Top to bottom:
1. **Header bar** — game title left, mode + guess counter right, `⋯` icon top-right
2. **Board** — Wordle-style grid (see Section 3)
3. **Elimination tracker strip** — color status row (see Section 4)
4. **Palette row** — color dots, horizontally centered
5. **Actions row** — Undo | Clear | Hint (equal-width, secondary style)
6. **Submit button** — full-width CTA gradient

The board + tracker + palette + actions + submit must all fit on screen without scrolling at 1080×1920.

### Result Screen
- Full bottom sheet (not a popup) sliding up on game end
- Contains: result title, win/loss message, secret sequence reveal, XP + coins earned, Dot Burst animation (on win), share button, Play Again + Menu buttons
- Sheet height: ~70% of screen

### Stats Screen
- Bottom sheet, same glass panel style
- Shows: games played/won, win streak, guess distribution chart, level/XP bar, daily challenge streak, login streak
- No change to underlying data, only visual restyle

### Campaign Screen
- Bottom sheet, scrollable 5-column grid of 100 level buttons
- Each button: level number + star display, pastel styling

### Settings / Hamburger
- `⋯` button top-right of game screen → compact bottom sheet
- Options: New Round, Main Menu, How to Play, Color-Blind Mode toggle, Haptics toggle, Close
- Replaces the current hamburger overlay pattern

---

## 3. Gameplay Changes

### Wordle Board
- All guess rows rendered statically at once
- Row states:
  - **Past:** white glass fill, dots fully colored, pips visible on right
  - **Active (current):** `ACTIVE_ROW` fill, `ACTIVE_BORDER`, empty slots show pulsing dashed border animation
  - **Future:** `opacity: 0.15–0.25`, faint dashed outlines only
- Row count: 10 for Classic/Hard, 8 for Daily/Campaign. Zen has no row limit.
- Zen mode: shows all completed rows + 1 active row; no future-row outlines (no guess limit to display)

### Flip Animation on Submit
- On submit, each dot in the active row flips individually left-to-right
- Stagger: 80ms between each dot
- Each dot: 3D Y-axis flip (`rotateY 0→90deg` showing dot color, then `90→0deg` showing result state with pip)
- Total reveal: ~400ms for 4-slot row, ~480ms for 5-slot, ~560ms for 6-slot
- Implemented via `Tween` in Godot with `SubViewport` or shader-based flip

### Feedback Modes
**Count-Only (Classic, Hard, Blitz, Zen, Campaign, Daily):**
- Pips on right of each row: sorted green first, then yellow, then empty
- No dot in the row is highlighted or ringed
- Player must reason which positions were correct across guesses

**Per-Dot (Easy mode only):**
- After flip reveal, each dot shows a colored ring:
  - Green ring (`box-shadow: 0 0 0 3px #22C55E`) = exact
  - Yellow ring (`box-shadow: 0 0 0 3px #FACC15`) = misplaced
  - No ring = absent
- Pips still shown on right (same count)

### Hard Mode Visual Lock
- When a slot is confirmed exact (in Hard mode), after the flip reveal:
  - A small padlock badge (🔒, 16px) fades in on the bottom-right of that slot
  - The dot pulses once (scale 1.0 → 1.15 → 1.0, 200ms)
- In subsequent rows, locked slots are pre-filled with the locked color and show the padlock badge
- Locked slots ignore tap/drag input

### Smart Hint (replaces Slot Reveal)
- Tapping Hint → shows rewarded ad → reveals one color that is **not** in the sequence at all
- Result: that color dot in the elimination tracker gets a grey ✕ badge immediately
- Hint button is disabled if all absent colors are already known
- "Hint" label replaces "SCAN"

### Blitz Timer Ring
- Circular SVG ring renders around or above the board header
- Fill: CTA gradient (`#F472B6 → #A78BFA`) when >20s remaining
- Fill: red (`#EF4444`) with pulse animation when ≤15s
- Numeric seconds shown inside ring center
- `stroke-dashoffset` animated via `Tween` each second
- On timeout: ring flashes red, game ends as loss

---

## 4. New Features

### Color Elimination Tracker
- Horizontal strip between board and palette
- Shows all 5 (or 6 in Hard) color dots, smaller than palette dots (~28px)
- Badge states per dot:
  - No badge: unknown
  - Green ✓ badge (bottom-right): confirmed in sequence (at least once exact or misplaced)
  - Grey ✕ overlay: confirmed absent (never appeared in any feedback, or revealed by Smart Hint)
- Updates automatically after every submitted guess
- Present in all modes including Easy

### Win Celebration: Dot Burst
- Triggered on any win at the moment the result sheet begins to appear
- 12–16 colored dots (matching the secret sequence colors, evenly distributed) burst outward from the board center
- Each particle: 8–12px circle, launches at random angle, travels 200–400px, fades out over 1.0–1.4s
- Implemented via `GPUParticles2D` or manual `Tween` per particle node
- Does not block the result sheet

### Color-Blind Mode
- Toggle in Settings sheet (persisted in SaveData)
- When enabled: each dot renders a white shape icon inside (~40% of dot size):
  - Red → circle (●)
  - Blue → square (■)
  - Green → triangle (▲)
  - Yellow → diamond (◆)
  - Purple → star (★)
  - Orange → cross (✕)
- Shape is a `Label` node overlaid on the dot, white color, centered

### Share Result Grid
- Available on result sheet for all modes (not just Daily)
- Format:
  ```
  Guess the Dots · Classic · 3/10 🟢🟡
  ⬜⬜⬜⬜
  🟡⬜🟡⬜
  🟢🟢🟢🟢
  #GuessTheDots
  ```
- Uses `DisplayServer.clipboard_set()` + optional native share intent on Android
- `DailyChallenge.build_share_text()` extended to handle all modes

### Create & Share a Puzzle
- Entry: "Play a friend's code" link on Mode Select
- **Create flow:** Player picks 4 slots, selects secret sequence using palette → generates code
- **Code format:** `GTD-` + 4–5 base-6 digits (e.g. `GTD-R4BG`). Encodes color indices. Decoded client-side, no server.
- **Play flow:** Player enters code → plays that exact sequence in a variant of Classic mode (no campaign progress, no daily streak)
- Stored in memory only (no persistence needed)

### Weekly Leaderboard (Daily Challenge)
- Shown on result sheet after completing Daily Challenge
- Displays: player's result + 9 simulated entries seeded from today's date (deterministic, same for everyone)
- Simulated names drawn from a fixed list of 50 neutral names
- Ranking by fewest guesses, then fastest time
- Framed as "Today's Top 10" — clearly simulated, not real network data
- Real backend leaderboard is a future phase

### Easy Mode
- 6th game mode on Mode Select
- Rules: 3–4 slots (random, starts at 3), 5 colors, 10 guesses
- Feedback: per-dot ring (see Section 3)
- After 3 Easy wins: result sheet shows a gentle nudge — "Ready for Classic? Try it without the hints."
- Tracked via `SaveData.easy_wins: int`

---

## 5. Data & Save Changes

### New fields in SaveData.gd
```gdscript
# Settings (consolidated into save_data.cfg [settings] section)
var colorblind_enabled: bool = false
var sound_enabled: bool = true
# haptics_enabled already exists, moved here from separate file

# Easy mode
var easy_wins: int = 0

# Custom puzzles
var custom_puzzles_played: int = 0

# Weekly leaderboard (daily)
var daily_best_time: int = 0  # seconds taken for today's daily
```

### Modified
- `hints_used` semantic changes: now counts "color eliminated" hints (not slot reveals)
- Haptics setting migrated from `user://settings.cfg` into `save_data.cfg [settings]` section
- `guess_distribution` split: `guess_distribution_classic` and `guess_distribution_easy` tracked separately

### Custom Puzzle Encoding
No persistence. Code `GTD-XXXX` encodes color indices as characters (A=0, B=1, C=2, D=3, E=4, F=5). Decoded in a pure function `_decode_custom_puzzle(code: String) -> Array[int]`. Invalid codes show an error toast.

### No Backend Required
All features in this rework are fully client-side. The weekly leaderboard uses deterministic simulation. Real network leaderboard is out of scope for this phase.

---

## 6. Files Affected

| File | Change Type |
|------|-------------|
| `scripts/Main.gd` | Major rewrite — all UI theming, board, overlays, new features |
| `scripts/SaveData.gd` | Add new fields, migrate settings |
| `scripts/ColorDotButton.gd` | Restyled for pastel theme, color-blind shape overlay |
| `scripts/SlotButton.gd` | Rounded square shape, flip animation support |
| `scripts/Splash.gd` | Shorter animation, pastel theme |
| `scripts/Tutorial.gd` | Visual restyle only |
| `scripts/DailyChallenge.gd` | Extend `build_share_text()` for all modes |
| `scripts/AdManager.gd` | No logic change, hint integration only |
| `scenes/Main.tscn` | Structural changes to match new layout |
| `scenes/Splash.tscn` | Restyled |

---

## 7. Out of Scope (This Phase)
- Real backend leaderboard
- Multiplayer head-to-head
- IAP shop / cosmetics store
- Additional themes/skins
- Sound system changes (SoundManager.gd untouched)
- AchievementManager changes (achievements fire same signals, no new achievements this phase)
