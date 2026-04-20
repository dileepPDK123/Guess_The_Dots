---
title: Ingest Log
---

# Ingest Log

## [2026-04-19] spec sync | Backend & Firebase Design
- Source: `docs/superpowers/specs/2026-04-19-backend-firebase-design.md`
- Pages created: [[entities/BackendManager]]
- Pages updated: [[entities/SaveData]] (new `[backend]` section), [[overview]] (new Backend section + BackendManager in autoloads), [[index]] (spec + BackendManager entry), [[hot]] (backend design decisions)
- Key insight: Firebase is REST-only (no native SDK), anonymous-first auth with optional Google/Apple link, conflict resolution is simply higher `total_xp_earned` wins, and leaderboard is Daily Challenge only.

## [2026-04-19] spec sync | UI Rework + Economy & Features Design
- Source: `docs/superpowers/specs/2026-04-19-ui-rework-design.md` + `2026-04-19-economy-features-design.md`
- Pages created: [[concepts/pastel-theme]], [[concepts/xp-shop]], [[concepts/season-track]], [[concepts/retention-mechanics]], [[entities/SeasonManager]], [[entities/ShopManager]], [[entities/ComboManager]]
- Pages updated: [[overview]], [[hot]], [[index]], [[entities/Main]], [[entities/SaveData]], [[entities/AdManager]], [[concepts/game-modes]], [[concepts/ad-economy]], [[concepts/reward-system]], [[concepts/neural-grid-theme]] (archived)
- Key insight: Game is getting a full pastel rework, 5 new modes, XP shop + season track, 6 retention mechanics. Neural Grid theme archived but available as purchasable Neon Core theme.

## [2026-04-19] ingest | Codebase Snapshot
- Source: full codebase scan (scripts/, scenes/, project.godot)
- Summary: [[sources/codebase-snapshot]]
- Pages created: [[overview]], [[entities/Main]], [[entities/SaveData]], [[entities/AdManager]], [[entities/AchievementManager]], [[entities/SoundManager]], [[entities/DailyChallenge]], [[entities/ColorDotButton]], [[entities/SlotButton]], [[entities/Splash]], [[entities/Tutorial]], [[concepts/game-modes]], [[concepts/mastermind-algorithm]], [[concepts/reward-system]], [[concepts/neural-grid-theme]], [[concepts/data-persistence]], [[concepts/campaign-mode]], [[concepts/ad-economy]], [[concepts/daily-challenge]]
- Pages updated: [[index]], [[hot]]
- Key insight: Entire game lives in two scenes; all UI is procedurally built in Main.gd at runtime with no prefabs.
