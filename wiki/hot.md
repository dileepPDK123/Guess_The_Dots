---
title: Hot Cache
updated: 2026-04-19
---

# Hot Cache

Fast-load context for the most recent session.

## Current State
Two major specs approved, not yet implemented:
- **UI Rework:** `docs/superpowers/specs/2026-04-19-ui-rework-design.md`
- **Economy + Features:** `docs/superpowers/specs/2026-04-19-economy-features-design.md`

Implementation plan not yet written — next step after wiki update.

## Design Decisions Locked

### Visual
- Theme: Soft Pastel (NOT dark cyberpunk NEURAL GRID)
- BG: `#FFF1F9 → #FFF8F0 → #F0FFF8` gradient
- CTA: `#F472B6 → #A78BFA` gradient
- Panels: white glass `rgba(255,255,255,0.75)` + `#FFD6E7` border
- Slot shape: rounded squares (not circles)
- Dot colors: unchanged

### History Display
- Wordle-style board: all rows visible, current highlighted, future faded
- Flip animation on submit (80ms stagger per dot)

### Feedback
- Classic/Hard/Blitz/Zen/Campaign/Daily: count-only pips
- Easy mode: per-dot colored rings

### Ads
- Banner: gameplay only
- Interstitial: after LOSS only (every 3rd), never wins
- Native card: Stats + Menu
- Rewarded: player-initiated only

### XP
- Shop tab: spend XP on tokens, themes, sounds, skins, shapes
- Season tab: monthly milestone track (6 seasons pre-baked, remote config activation)
- Season remote config: GitHub Gist JSON

## New Autoloads (to be created)
- `SeasonManager.gd` — season fetch + milestones
- `ShopManager.gd` — purchase logic + catalog
- `ComboManager.gd` — combo multiplier
- `BackendManager.gd` — all Firebase communication

## Backend Design Decisions (Firebase)

### Auth
- **Anonymous-first:** silent anonymous auth on first launch — no signup UI, no friction
- **Optional link:** Google (Android) / Apple (iOS) via Settings "Sign in to sync across devices"
- **Anonymous UID preserved** on link — all data carries over, no migration needed
- **Apple name saved locally on first link** — Apple only sends display name once

### Firebase Access Pattern
- **REST API only — no native Firebase SDK/plugin** — HTTPRequest node handles everything, works on Android and iOS identically
- `PROJECT_ID` and `API_KEY` in Godot project settings, not hardcoded

### Cloud Save Conflict Resolution
- **Higher `total_xp_earned` always wins** — simple, deterministic, no merge logic
- Cloud save is **best-effort**: failed push queues one retry on next launch, no infinite loop
- **Rate limit:** minimum 10 seconds between pushes

### Leaderboard Scope
- **Daily Challenge only** — no weekly, no all-time, no friends graph
- Unsolved players stored in Firestore for stats but **hidden from leaderboard display**
- Leaderboard loaded once on result screen open, cached for session — no live refresh
- **Percentile is client-side** using top-100 data + total count aggregation

### Account Deletion
- Full GDPR + Apple App Store compliant
- Leaderboard scores anonymised (not deleted) to preserve board integrity
- Firestore TTL policy on `submitted_at` auto-deletes leaderboard docs after 30 days — no Cloud Functions needed

## New Game Modes (5)
Mystery, Time Trial, Duo, Sudden Death, Sandbox

## Key New SaveData Fields
`season_xp`, `streak_freezes`, `resume_secret`, `puzzle_history`, `current_combo`, `personal_bests`, `active_sound_pack`, `active_board_skin`
