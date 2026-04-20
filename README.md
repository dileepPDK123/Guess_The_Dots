# Guess the Dots — Godot 4 GDScript mini-project

This is a small Godot 4 project for a Mastermind-style color guessing game.

## What it includes
- Main menu with **New Game** and **Quit**
- Random secret length from **3 to 5 dots**
- **5 reusable colors**
- Place colors by **clicking a palette color then tapping a slot**
- Or **drag a palette dot onto a slot**
- A **tick/check button** to submit once all slots are filled
- Feedback per guess:
  - **Exact** = right color in the right spot
  - **Wrong spot** = right color in the wrong spot
- **10 total guesses**
- Full guess history UI
- Secret reveal and replay flow on win/lose

## How to run
1. Open Godot 4.x.
2. Import this folder as a project.
3. Open `res://scenes/Main.tscn` if needed.
4. Press Play.

## Files
- `project.godot`
- `scenes/Main.tscn`
- `scripts/Main.gd`
- `scripts/ColorDotButton.gd`
- `scripts/SlotButton.gd`

## Notes
- The project is intentionally lightweight and UI-driven, so it is easy to extend.
- Good next upgrades would be sound effects, animated feedback, and mobile-specific polish.
