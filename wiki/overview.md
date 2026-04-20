---
title: Project Overview
updated: 2026-04-19
---

# Guess the Dots — Overview

A mobile Mastermind puzzle game built in **Godot 4.6** for Android. Players decode a hidden color sequence using feedback from each guess.

## Key Facts
- **Viewport:** 1080 × 1920 (portrait mobile)
- **Entry point:** `scenes/Splash.tscn` → `scenes/Main.tscn`
- **Theme:** Soft Pastel (pink-to-mint gradient, rose→violet CTAs, white glass panels)
- **Monetization:** AdMob (banner + interstitial on loss + rewarded) + $2.99 Remove Ads IAP + XP Shop

## Planned Rework (Specs Approved)
See [`docs/superpowers/specs/2026-04-19-ui-rework-design.md`] and [`docs/superpowers/specs/2026-04-19-economy-features-design.md`] for full details.

## Architecture

```
Autoloads (global singletons):
  AdManager        → ad lifecycle, rewarded ad signals, native ad cards
  SaveData         → all persistent player state
  DailyChallenge   → date-seeded worldwide puzzle + share text
  AchievementManager → achievement toasts + coin rewards
  SoundManager     → procedural audio (default + 3 sound pack variants)
  SeasonManager    → remote config fetch, season state, milestone claiming [NEW]
  ShopManager      → XP shop catalog, purchase logic, token consumption [NEW]
  ComboManager     → combo tracking, multiplier calculation [NEW]
  BackendManager   → Firebase auth, cloud save, Daily Challenge leaderboard [NEW]

Scenes:
  Splash.tscn      → 2.5s animated intro (pastel theme, soft easing)
  Main.tscn        → entire game UI (menu, game, result, overlays)
```

## Backend (Firebase)

All Firebase calls use the **REST API only** — no native plugin required. Godot's `HTTPRequest` node handles everything, working identically on Android and iOS.

```
Firebase Project
  ├── Authentication
  │     ├── Anonymous (silent, first launch)
  │     ├── Google Sign-In (Android)
  │     └── Sign in with Apple (iOS — required by App Store)
  └── Firestore Database
        ├── users/{uid}/save             → cloud save document
        └── leaderboards/{date}/scores/{uid} → Daily Challenge scores
```

- **Auth flow:** anonymous on first launch → optional Google/Apple link via Settings
- **Cloud save:** pull on launch (background), push after game end. Conflict = higher `total_xp_earned` wins.
- **Leaderboard:** Daily Challenge only. Top 100 scores shown on result screen. Client-side percentile calculation.
- **Security:** Firestore rules enforce owner-only writes; leaderboard scores validated server-side (guesses 1–8, valid time, boolean solved).
- **Account deletion:** full GDPR + Apple-compliant sequence — anonymise leaderboard, delete Firestore doc, delete Auth user, wipe local save.
- See [[entities/BackendManager]] for full API details.

## Visual System (Reworked)
- **Background:** `#FFF1F9 → #FFF8F0 → #F0FFF8` pastel gradient
- **Panels:** white glass `rgba(255,255,255,0.75)` with `#FFD6E7` border
- **CTA buttons:** `#F472B6 → #A78BFA` gradient (rose → violet)
- **Dot colors:** unchanged — Red/Blue/Green/Yellow/Purple/Orange
- **Slots shape:** rounded squares (not circles) for Wordle-board rows
- See [[concepts/pastel-theme]] for full token reference

## Game Modes (9 total after rework)
| Mode | Slots | Colors | Guesses | Feedback |
|------|-------|--------|---------|----------|
| Classic | 3–5 | 5 | 10 | Count-only |
| Easy | 3–4 | 5 | 10 | Per-dot rings |
| Blitz | 5 | 5 | 90s | Count-only |
| Hard | 5–6 | 6 | 10 | Count-only + locks |
| Zen | 4 | 5 | ∞ | Count-only |
| Campaign | varies | varies | varies | Count-only |
| Mystery | hidden 3–5 | 5 | 12 | Count-only |
| Time Trial | 3–4 | 5 | 5 puzzles | Count-only |
| Duo | 4+4 | 5 | 10 each | Count-only |
| Sudden Death | 3–5 | 5 | until wrong | Count-only |
| Sandbox | player-set | any | ∞ | Per-dot (always) |

## Economy
- **XP:** earns via wins, doubles with combo/boosts, spendable in XP Shop + Season Track
- **Coins:** earns via wins/achievements/login, spent on timed XP Boosts
- **Tokens:** Hint, Second Chance, Extra Guess, Streak Freeze — bought with XP or in shop
- See [[concepts/xp-shop]], [[concepts/season-track]], [[concepts/reward-system]]

## Ad Strategy
- Banner: gameplay screen only
- Interstitial: losses only (every 3rd), never wins
- Native card: Stats + Menu screens
- Rewarded: player-initiated (hint, second chance, XP doubler)
- All intrusive ads removed by $2.99 IAP
- See [[concepts/ad-economy]]

## Version State
- v1.1–v1.5 complete (dark cyberpunk theme, original features)
- Full rework approved and specced — see specs above
