---
title: SaveData.gd
type: autoload
path: scripts/SaveData.gd
lines: 412 (will grow significantly)
extends: Node
singleton: true
---

# SaveData.gd

Autoload singleton. Owns all persistent player state. Everything that survives between sessions lives here.

## Save Path
`user://save_data.cfg` (Godot ConfigFile format)

## Data Sections

### [progression]
- `xp`, `level` (1–50), `coins`, `total_xp_earned` (lifetime; XP Shop deducts from this)
- `ads_removed: bool`

### [stats]
- `games_played`, `games_won`
- `current_win_streak`, `max_win_streak`
- `guess_distribution_classic`, `guess_distribution_easy` (split per mode)
- `hints_used` (now counts "color eliminated" hints), `ads_watched`, `perfect_wins`
- `personal_bests: Dictionary` → mode → `{min_guesses, min_time_ms}`

### [daily]
- `daily_last_date`, `daily_streak`, `daily_max_streak`
- `daily_history: Dictionary`
- `daily_best_time: int` (seconds for leaderboard)

### [weekly]
- `weekly_last_week: int` — ISO week of last Weekly Challenge attempt

### [login]
- `last_login_date`, `login_streak`, `login_max_streak`
- `last_first_win_date: String`

### [unlocks]
- `unlocked_themes`, `active_theme`
- `unlocked_shapes`, `active_shape`
- `unlocked_sound_packs`, `active_sound_pack`
- `unlocked_share_emoji`, `active_share_emoji`
- `unlocked_board_skins`, `active_board_skin`

### [achievements]
- `achievements: Dictionary`

### [campaign]
- `campaign_progress: Dictionary`
- `campaign_max_unlocked: int`

### [tokens] *(new)*
- `hint_tokens: int`
- `second_chance_tokens: int`
- `extra_guess_tokens: int`
- `streak_freezes: int`
- `xp_boost_end_time: int` (Unix timestamp; 0 = no active boost)

### [season] *(new)*
- `season_xp: int` — resets each season
- `season_number: int`
- `season_claimed: Array[bool]` — 5 elements
- `season_badge: String`
- `season_config_cache: Dictionary`

### [settings] *(implemented 2026-04-20)*
- `colorblind_enabled: bool` — live toggle in Settings sheet
- `sound_enabled: bool`
- `haptics_enabled_migrated: bool` — migrated from old `user://settings.cfg` (one-time)

### [retention]
- `easy_wins: int` — nudge toast at 3 ("Ready for Classic?")
- `custom_puzzles_played: int`
- `daily_best_time_ms: int`

### [resume] *(new)*
- `resume_mode: int` (-1 = none)
- `resume_secret: Array`
- `resume_history: Array`
- `resume_campaign_level: int`

### [history] *(new)*
- `puzzle_history: Array[Dictionary]` (capped at 200)

### [backend] *(new)*
Firebase auth tokens and sync state. Persisted locally in `save_data.cfg` but **not** synced to Firestore.
- `firebase_uid: String` — anonymous or linked UID assigned by Firebase Auth
- `firebase_id_token: String` — JWT, expires 1 hour after issue
- `firebase_refresh_token: String` — never expires; used to obtain new id_token
- `firebase_token_expiry: int` — Unix timestamp of id_token expiry
- `firebase_linked: bool` — `true` after successful Google or Apple account link
- `firebase_display_name: String` — shown on leaderboard; generated from UID if anonymous
- `firebase_apple_name: String` — saved on first Apple link only (Apple sends name once)
- `last_cloud_push: int` — Unix timestamp of last successful cloud save push (rate-limit guard, 10 s minimum)

## XP Shop Deduction Rule
`purchase()` deducts from `total_xp_earned`, NOT from `xp`. Player never loses level progress by shopping.

## Related
- [[concepts/data-persistence]] — save/load mechanics
- [[concepts/reward-system]] — XP/coin earning
- [[concepts/xp-shop]] — spending total_xp_earned
- [[concepts/season-track]] — season_xp fields
- [[concepts/retention-mechanics]] — retention fields
- [[entities/BackendManager]] — reads/writes the `[backend]` fields
