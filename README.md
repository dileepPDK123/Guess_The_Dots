# Guess the Dots

A **Mastermind-style color puzzle game** built with Godot 4.6 for Android. Crack the hidden color sequence before you run out of guesses.

> **Status:** UI Rework complete (`feature/ui-rework`). Soft pastel theme, Wordle-style board, 6 game modes.

---

## Gameplay

Each round hides a secret sequence of colored dots (3–6 slots depending on mode). You guess by picking colors from the palette and submitting. After each guess you get feedback:

- **Green pip** — right color, right position
- **Yellow pip** — right color, wrong position
- **No pip** — color not in the sequence

Keep refining your guesses until you crack the code — or run out of attempts.

---

## Game Modes

| Mode | Slots | Guesses | Special Rule |
|---|---|---|---|
| Classic | 3–5 (random) | 10 | Balanced intro mode |
| Easy | 3–4 | 10 | Per-dot colored rings (great for new players) |
| Blitz | 5 | 12 | 90-second countdown timer |
| Hard | 5–6 | 8 | 6 colors + confirmed slots lock in place |
| Zen | 4 | ∞ | Unlimited guesses, no pressure |
| Campaign | varies | varies | 100 levels of escalating difficulty |

---

## Screenshots

*Coming soon*

---

## Tech Stack

| | |
|---|---|
| **Engine** | Godot 4.6 |
| **Language** | GDScript |
| **Target** | Android (1080×1920) |
| **Architecture** | Single scene, all UI procedurally built at runtime |
| **Persistence** | Godot `ConfigFile` (`user://save_data.cfg`) |
| **Ads** | AdMob via Android plugin |

---

## Project Structure

```
guess_the_dots_godot/
├── scenes/
│   ├── Main.tscn          # Entire game lives here
│   └── Splash.tscn        # Intro animation
├── scripts/
│   ├── Main.gd            # Core game controller (~2600 lines)
│   ├── SaveData.gd        # Persistent data autoload
│   ├── AdManager.gd       # AdMob integration autoload
│   ├── AchievementManager.gd
│   ├── SoundManager.gd    # Procedural audio autoload
│   ├── DailyChallenge.gd  # Daily puzzle + share text autoload
│   ├── ColorDotButton.gd  # Palette color button component
│   ├── SlotButton.gd      # Guess slot button component
│   ├── Splash.gd          # Splash screen animation
│   └── Tutorial.gd        # 15-slide onboarding tutorial
├── docs/
│   └── superpowers/
│       ├── specs/         # Design documents
│       └── plans/         # Implementation plans
└── memory/                # Session memory for AI-assisted development
```

---

## Key Features

- **Wordle-style board** — all rows visible at once, current row highlighted, flip animation on submit
- **Elimination tracker** — color strip showing which colors are confirmed absent/present
- **Smart Hint** — reveals an absent color (ad-rewarded)
- **Color-blind mode** — shape overlays on palette dots (●■▲◆★✕)
- **Hard mode lock badges** — confirmed exact slots get a 🔒 and auto-fill in the next row
- **Dot burst celebration** — particle scatter on win
- **Custom puzzles** — encode a puzzle as a `GTD-XXXX` code and share with friends
- **Daily Challenge** — worldwide synchronized daily puzzle, same sequence for everyone
- **Share grid** — Wordle-style emoji grid copied to clipboard

---

## Architecture Notes

**Everything is in one scene.** There are no scene transitions during gameplay — `Main.tscn` handles all screens by showing/hiding layers and dynamically building UI.

**Bottom sheet pattern** used for all modal UI (result screen, settings, mode select, custom puzzle):
```gdscript
var sheet := _build_bottom_sheet("Title", func(): _on_close())
var vbox  := sheet.get_node("Content") as VBoxContainer
```

**PALETTE is a Dictionary array:**
```gdscript
PALETTE[i]["color"]  # Color
PALETTE[i]["name"]   # String
```

**History entry format:**
```gdscript
{"values": Array[int], "exact": int, "misplaced": int, "per_dot": Array}
```

---

## How to Run

1. Install [Godot 4.6](https://godotengine.org/download)
2. Clone this repo
3. Open Godot → **Import** → select the repo folder
4. Press **F5** (Play)

> The game targets Android but runs fine in the Godot editor on desktop for development.

---

## Development Branches

| Branch | Status | Description |
|---|---|---|
| `master` | stable | Latest stable code |
| `feature/ui-rework` | complete, pending merge | Full pastel UI rework (Tasks 1–21) |

---

## Planned

- Firebase cloud save + leaderboard (Daily Challenge)
- XP Shop (themes, sounds, skins)
- Season Track (monthly milestones)
- 5 new modes: Mystery, Time Trial, Duo, Sudden Death, Sandbox

---

## License

Personal project — not currently open for contributions.
