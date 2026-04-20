---
title: Codebase Snapshot
source_type: codebase
ingested: 2026-04-19
files_scanned:
  - project.godot
  - scenes/Splash.tscn
  - scenes/Main.tscn
  - scripts/Main.gd
  - scripts/SaveData.gd
  - scripts/AdManager.gd
  - scripts/AchievementManager.gd
  - scripts/SoundManager.gd
  - scripts/DailyChallenge.gd
  - scripts/ColorDotButton.gd
  - scripts/SlotButton.gd
  - scripts/Splash.gd
  - scripts/Tutorial.gd
---

# Source: Codebase Snapshot (2026-04-19)

Full ingest of the Guess the Dots Godot project at the time of CHG-014 (Campaign Mode complete).

## Summary
- **Engine:** Godot 4.6, Android target, 1080×1920
- **Entry point:** Splash.tscn (4s animation) → Main.tscn (entire game)
- **Architecture:** 5 autoload singletons + 1 game controller + 2 UI components
- **Lines of code (key files):** Main.gd (1834), Tutorial.gd (921), SaveData.gd (412), AdManager.gd (161), AchievementManager.gd (157), SoundManager.gd (145), DailyChallenge.gd (86), SlotButton.gd (90), ColorDotButton.gd (80), Splash.gd (197)

## Entities Identified
- [[entities/Main]] — game controller
- [[entities/SaveData]] — persistence autoload
- [[entities/AdManager]] — ads autoload
- [[entities/AchievementManager]] — achievements autoload
- [[entities/SoundManager]] — audio autoload
- [[entities/DailyChallenge]] — daily puzzle autoload
- [[entities/ColorDotButton]] — palette button
- [[entities/SlotButton]] — guess slot
- [[entities/Splash]] — intro screen
- [[entities/Tutorial]] — onboarding

## Concepts Identified
- [[concepts/game-modes]]
- [[concepts/mastermind-algorithm]]
- [[concepts/reward-system]]
- [[concepts/neural-grid-theme]]
- [[concepts/data-persistence]]
- [[concepts/campaign-mode]]
- [[concepts/ad-economy]]
- [[concepts/daily-challenge]]
