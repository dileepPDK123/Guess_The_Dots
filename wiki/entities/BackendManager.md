---
title: BackendManager.gd
type: autoload
path: scripts/BackendManager.gd
lines: ~200 (estimated)
extends: Node
singleton: true
status: PLANNED
spec: docs/superpowers/specs/2026-04-19-backend-firebase-design.md
---

# BackendManager.gd

New autoload singleton. Single source of truth for all Firebase communication. Uses Firebase REST API exclusively — no native plugin required. All calls use Godot's `HTTPRequest` node and work identically on Android and iOS.

Added to autoloads in `project.godot` and `scenes/Main.tscn`.

## Architecture

```
BackendManager.gd (autoload)
  ├── _auth       → Firebase Auth REST API
  ├── _firestore  → Firestore REST API
  └── _token      → Token refresh timer (55-minute interval)
```

**Base URLs:**
```
AUTH_URL = "https://identitytoolkit.googleapis.com/v1"
FS_URL   = "https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"
```

`PROJECT_ID` and `API_KEY` are stored as Godot project settings — not hardcoded in scripts.

## Responsibilities

- Anonymous auth on first launch (`_ready()`)
- Token auto-refresh every 55 minutes + lazy check before any Firestore write
- Cloud save pull on launch (after auth, non-blocking)
- Cloud save push after game end, achievement unlock, IAP purchase, campaign level complete
- Daily Challenge leaderboard score submission
- Leaderboard read for result screen
- Account link (Google Sign-In on Android, Sign in with Apple on iOS)
- Account deletion (GDPR + Apple requirement)

## Key Methods

```gdscript
func init_auth() -> void                                    # called in _ready()
func refresh_token() -> void                                # called by timer + lazy check
func pull_save() -> void                                    # on launch
func push_save() -> void                                    # after game end
func submit_daily_score(guesses, time_ms, solved) -> void
func fetch_leaderboard(date: String) -> Array               # returns top 100
func fetch_player_count(date: String) -> int
func link_google(google_token: String) -> void
func link_apple(apple_token: String) -> void
func delete_account() -> void
```

All methods are `async` (`await` on HTTPRequest). The game never blocks waiting for Firebase. Failures on non-critical operations (push save, score submit) are logged silently — no player-visible error. Account link and deletion show explicit success/failure toasts.

## Authentication

### Anonymous Auth (first launch)
Called once in `_ready()` if no `id_token` is cached. Posts to `accounts:signUp` with `returnSecureToken: true`. Player is signed in silently with no UI. Resulting token stored in [[entities/SaveData]] `[backend]` section.

### Token Auto-Refresh
`Timer` fires every 55 minutes (before 60-minute token expiry). Also checked lazily before any Firestore write: if `Time.get_unix_time_from_system() > firebase_token_expiry - 60`, refresh before proceeding.

### Account Linking (Google / Apple)
Triggered by "Sign in to sync across devices" in Settings. Uses `accounts:signInWithIdp`. Existing anonymous UID is preserved — all data carries over. Sets `firebase_linked = true` in SaveData.

- **Android:** requires Google Sign-In Godot plugin + SHA-1 of release keystore registered in Firebase Console
- **iOS:** requires Sign in with Apple Godot plugin. Apple requires this if ANY third-party login is offered — App Store rejection risk if missing.
- **Apple name:** must be saved to SaveData on first link — Apple only sends the display name once.

### Display Name Logic
| State | Display Name |
|-------|-------------|
| Anonymous | `"Player " + firebase_uid.right(4).to_upper()` |
| Google linked | Google account display name, truncated to 20 chars |
| Apple linked | Apple-provided name (saved at first link), truncated to 20 chars |

## Cloud Save

**Firestore path:** `users/{uid}/save`

**Fields synced to cloud:** `xp`, `level`, `coins`, `total_xp_earned`, `games_played`, `games_won`, `current_win_streak`, `max_win_streak`, `daily_streak`, `daily_max_streak`, `login_streak`, `campaign_max_unlocked`, `unlocked_themes`, `unlocked_shapes`, `unlocked_sound_packs`, `unlocked_share_emoji`, `unlocked_board_skins`, `achievements`, `ads_removed`, `updated_at`.

**Not synced (local only):** `puzzle_history`, `resume_*`, `daily_history` detail, `season_xp`, token counts, active cosmetic selections, settings.

### Conflict Resolution
Always take higher `total_xp_earned`:
```gdscript
func _resolve_save(local: Dictionary, cloud: Dictionary) -> Dictionary:
    if cloud.get("total_xp_earned", 0) > local.get("total_xp_earned", 0):
        return cloud
    return local
```

### Launch Sequence
1. App opens → load local `save_data.cfg` immediately → game is playable
2. Firebase auth completes in background (1–3 s)
3. Cloud pull fires → if cloud wins: apply to local + save + show "Progress restored ✓" toast
4. If local wins or cloud missing: push local to cloud silently

### Push Rate Limiting
Minimum 10 seconds between pushes. `last_cloud_push` Unix timestamp tracked in SaveData. On failure: queue one retry on next app launch — no infinite retry loop (best-effort).

## Daily Challenge Leaderboard

**Firestore path:** `leaderboards/{YYYY-MM-DD}/scores/{uid}`

Score document fields: `guesses_used`, `time_ms`, `display_name`, `solved`, `submitted_at`.

**Submit only if improvement:** fetch existing score first; overwrite only if fewer guesses, or same guesses with lower time. A loss (`solved: false`) is submitted only if no existing score exists.

**Reading:** on result screen open (Daily only). Three parallel requests:
1. Top 100 solved scores (ordered by guesses_used ASC, time_ms ASC)
2. Player's own document
3. Total player count (aggregation query for percentile)

**Percentile** is computed client-side: count entries in top 100 with worse guesses_used, plus assume all players beyond top 100 scored worse.

Result screen shows top 10 + player's own row (always visible, highlighted). Unsolved players hidden from display.

## Account Deletion

Location: Settings → "Delete Account & Data" (requires two-tap confirmation).

Deletion sequence:
1. Anonymise leaderboard scores for last 30 days → `display_name = "Deleted Player"`
2. Delete `users/{uid}/save` Firestore document
3. Delete Firebase Auth user via `accounts:delete`
4. Wipe local `user://save_data.cfg`
5. Restart app to fresh first-launch state

Leaderboard documents older than 30 days are auto-deleted by Firestore TTL policy on `submitted_at` field — no Cloud Functions needed.

## Firestore Security Rules Summary

- `users/{uid}/save`: read + write only by authenticated owner
- `leaderboards/{date}/scores/{uid}`: read by any authenticated user; write by owner only, with server-side validation (guesses 1–8, time > 0, solved is bool)

## Related
- [[entities/SaveData]] — `[backend]` section fields
- [[concepts/daily-challenge]] — Daily Challenge mode that feeds the leaderboard
- [[concepts/data-persistence]] — overall save/load architecture
