# Guess the Dots — Backend & Firebase Design Spec
**Date:** 2026-04-19
**Status:** Approved
**Depends on:** `2026-04-19-ui-rework-design.md`, `2026-04-19-economy-features-design.md`
**Scope:** Firebase auth, cloud save, Daily Challenge leaderboard, security rules, account deletion.

---

## 1. Architecture Overview

```
Godot App (GDScript)
  └── BackendManager.gd (autoload)
        ├── _auth       → Firebase Auth REST API
        ├── _firestore  → Firestore REST API
        └── _token      → Token refresh timer

Firebase Project
  ├── Authentication
  │     ├── Anonymous (enabled)
  │     ├── Google Sign-In (Android + iOS)
  │     └── Sign in with Apple (iOS required)
  └── Firestore Database
        ├── users/{uid}/save         → cloud save document
        └── leaderboards/{date}/scores/{uid} → daily scores
```

**All Firebase calls use the REST API — no native plugin required.** Godot's `HTTPRequest` node handles everything. This works identically on Android and iOS.

**Base URLs:**
```
AUTH_URL  = "https://identitytoolkit.googleapis.com/v1"
FS_URL    = "https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"
```

`PROJECT_ID` and `API_KEY` stored as Godot project settings (not hardcoded in scripts).

---

## 2. Authentication

### 2a. Anonymous Auth (first launch)

Called once in `BackendManager._ready()` if no `id_token` cached locally.

**Request:**
```
POST {AUTH_URL}/accounts:signUp?key={API_KEY}
Body: {"returnSecureToken": true}
```

**Response fields stored in `SaveData`:**
```gdscript
var firebase_uid: String = ""
var firebase_id_token: String = ""        # expires in 1 hour
var firebase_refresh_token: String = ""   # never expires
var firebase_token_expiry: int = 0        # Unix timestamp
var firebase_linked: bool = false         # true after Google/Apple link
```

Player is "signed in" with no UI shown. All subsequent API calls use `id_token` in the `Authorization: Bearer {token}` header.

### 2b. Token Auto-Refresh

A `Timer` node in `BackendManager` fires every **55 minutes** (before 60-minute expiry).

**Refresh request:**
```
POST {AUTH_URL}/token?key={API_KEY}
Body: {"grant_type": "refresh_token", "refresh_token": "{refresh_token}"}
```

Updates `firebase_id_token` and `firebase_token_expiry` in SaveData. Silent — no UI.

Also checked lazily before any Firestore write: if `Time.get_unix_time_from_system() > firebase_token_expiry - 60`, refresh before proceeding.

### 2c. Link to Google / Apple (optional)

Triggered by "Sign in to sync across devices" button in Settings.

**Android — Google Sign-In:**
```
POST {AUTH_URL}/accounts:signInWithIdp?key={API_KEY}
Body: {
  "requestUri": "https://guess-the-dots.firebaseapp.com",
  "postBody": "id_token={google_id_token}&providerId=google.com",
  "returnSecureToken": true,
  "returnIdpCredential": true
}
```

Requires Google Sign-In Godot plugin to obtain `google_id_token`. SHA-1 fingerprint of release keystore must be registered in Firebase Console.

**iOS — Sign in with Apple:**
```
POST {AUTH_URL}/accounts:signInWithIdp?key={API_KEY}
Body: {
  "requestUri": "https://guess-the-dots.firebaseapp.com",
  "postBody": "id_token={apple_id_token}&providerId=apple.com",
  "returnSecureToken": true
}
```

Requires Sign in with Apple Godot plugin. Apple requires this to be offered if any third-party login is offered — App Store rejection risk if missing.

**On successful link:**
- `firebase_linked = true` saved to SaveData
- Display name updated from provider profile
- Existing anonymous UID is preserved — all data carries over
- Toast: "Account linked! Your progress is now protected ✓"

### 2d. Display Names

| State | Display Name |
|-------|-------------|
| Anonymous | `"Player " + firebase_uid.right(4).to_upper()` |
| Google linked | Google account display name, truncated to 20 chars |
| Apple linked | Apple-provided name (first launch only — Apple only sends it once), truncated to 20 chars |

Apple name must be saved to SaveData on first link — Apple does not re-send it.

---

## 3. Cloud Save

### 3a. Firestore Document Structure

**Path:** `users/{uid}/save`

```json
{
  "xp": 2480,
  "level": 12,
  "coins": 640,
  "total_xp_earned": 18500,
  "games_played": 127,
  "games_won": 89,
  "current_win_streak": 7,
  "max_win_streak": 14,
  "daily_streak": 5,
  "daily_max_streak": 21,
  "login_streak": 3,
  "campaign_max_unlocked": 42,
  "unlocked_themes": ["neon_core"],
  "unlocked_shapes": ["hexagon"],
  "unlocked_sound_packs": [],
  "unlocked_share_emoji": [],
  "unlocked_board_skins": [],
  "achievements": {"first_win": true, "wins_10": true},
  "ads_removed": false,
  "updated_at": 1776647187
}
```

**Not synced** (local only): `puzzle_history`, `resume_*`, `daily_history` detail, `season_xp`, token counts, active cosmetic selections, settings.

### 3b. Pull (cloud → local) on Launch

Called once in `BackendManager._ready()` after auth completes, non-blocking.

```
GET {FS_URL}/users/{uid}/save
Authorization: Bearer {id_token}
```

**Conflict resolution — always take higher `total_xp_earned`:**
```gdscript
func _resolve_save(local: Dictionary, cloud: Dictionary) -> Dictionary:
    if cloud.get("total_xp_earned", 0) > local.get("total_xp_earned", 0):
        return cloud
    return local
```

If cloud document does not exist (new player, first install): skip pull, push local save instead.

**Loading sequence:**
1. App opens → load local `save_data.cfg` immediately → game is playable
2. Firebase auth completes in background (1–3s)
3. Cloud pull fires → if cloud wins conflict: apply to local + save to `save_data.cfg` + show toast "Progress restored ✓"
4. If local wins or cloud missing: push local to cloud silently

### 3c. Push (local → cloud) on Game End

Called in `SaveData.save()` when triggered after: game end, achievement unlock, IAP purchase, campaign level complete.

```
PATCH {FS_URL}/users/{uid}/save
Authorization: Bearer {id_token}
Body: {fields mapped from SaveData}
```

**Retry on failure:** if request fails (no network), queue one retry on next app launch. No infinite retry loop — cloud save is best-effort.

**Rate limiting guard:** minimum 10 seconds between pushes. Rapid consecutive game completions won't spam Firestore.

---

## 4. Daily Challenge Leaderboard

### 4a. Firestore Document Structure

**Path:** `leaderboards/{YYYY-MM-DD}/scores/{uid}`

```json
{
  "guesses_used": 4,
  "time_ms": 83000,
  "display_name": "Player 7F2A",
  "solved": true,
  "submitted_at": 1776647187
}
```

### 4b. Submitting a Score

Called in `_finish_game()` when mode is DAILY, after local save completes.

**Only submit if improvement:**
1. Fetch existing score document for today
2. If none exists: submit unconditionally
3. If exists: only overwrite if `guesses_used < existing.guesses_used`, or `guesses_used == existing.guesses_used && time_ms < existing.time_ms`
4. If loss (`solved: false`): only submit if no existing score

```
PUT {FS_URL}/leaderboards/{date}/scores/{uid}
Authorization: Bearer {id_token}
Body: {guesses_used, time_ms, display_name, solved, submitted_at}
```

### 4c. Reading the Leaderboard

Called once when result screen opens after a Daily Challenge.

**Two parallel requests:**

**1. Top 100 scores (winners only):**
```
POST {FS_URL}:runQuery
Body: {
  structuredQuery: {
    from: [{collectionId: "scores"}],
    where: {field: "solved", op: "EQUAL", value: true},
    orderBy: [{field: "guesses_used", direction: "ASCENDING"},
              {field: "time_ms", direction: "ASCENDING"}],
    limit: 100
  }
}
```

**2. Player's own document:**
```
GET {FS_URL}/leaderboards/{date}/scores/{uid}
```

**3. Total player count** (for percentile):
```
POST {FS_URL}:runAggregationQuery
Body: {structuredQuery: {from: [{collectionId: "scores"}]},
       aggregations: [{count: {}}]}
```

**Percentile calculation (client-side):**
```gdscript
func _compute_percentile(player_guesses: int, total_players: int, top_100: Array) -> int:
    var worse_count = 0
    for entry in top_100:
        if entry.guesses_used > player_guesses:
            worse_count += 1
    # Estimate beyond top 100: assume remaining players scored worse
    worse_count += max(0, total_players - 100)
    return int((float(worse_count) / total_players) * 100)
```

### 4d. What Players See

On result screen after Daily Challenge:

```
Today's Daily — #47 / 312 players

  #1  SamR          1 guess  · 0:12
  #2  Player A3F2   2 guesses · 0:34
  ...
  #47 You           4 guesses · 1:23    ← highlighted
  ...
  #100 ...

  Better than 73% of today's players
```

- List shows top 10 + player's own row (always visible, highlighted)
- If player is in top 10, their row is shown in place
- Unsolved players not shown in the list (kept in Firestore for stats, hidden from display)
- Loaded once, cached for session — no live refresh

---

## 5. Firestore Security Rules

Deployed to Firebase Console. Prevents cheating and enforces data ownership.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Cloud save — owner only
    match /users/{uid}/save {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    // Leaderboard — anyone can read, owner can only write their own score
    match /leaderboards/{date}/scores/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.auth.uid == uid
        && request.resource.data.guesses_used is int
        && request.resource.data.guesses_used >= 1
        && request.resource.data.guesses_used <= 8
        && request.resource.data.time_ms is int
        && request.resource.data.time_ms > 0
        && request.resource.data.solved is bool;
    }

  }
}
```

**What these rules enforce:**
- Users can only read/write their own save document
- Leaderboard is publicly readable (for displaying scores) but writable only by owner
- Score must be valid: guesses 1–8, positive time, boolean solved flag
- Cannot fake another user's score

---

## 6. Account Deletion (GDPR + Apple Requirement)

**Location:** Settings screen → "Delete Account & Data" (destructive, requires confirmation).

**Confirmation flow:**
1. Tap "Delete Account & Data"
2. Alert: "This permanently deletes your progress, XP, achievements, and leaderboard history. This cannot be undone."
3. Confirm → execute deletion sequence

**Deletion sequence:**
```gdscript
# Step 1: Anonymise leaderboard scores (don't delete — preserves board integrity)
# Update all leaderboards/{date}/scores/{uid} → display_name = "Deleted Player"
# (Only last 30 days — beyond that, document expires via TTL policy)

# Step 2: Delete cloud save document
DELETE {FS_URL}/users/{uid}/save

# Step 3: Delete Firebase Auth user
POST {AUTH_URL}/accounts:delete?key={API_KEY}
Body: {"idToken": id_token}

# Step 4: Wipe local save
DirAccess.remove_absolute("user://save_data.cfg")

# Step 5: Restart app (or return to fresh first-launch state)
```

**Firestore TTL policy:** Set `submitted_at` field as TTL on leaderboard documents. Firebase auto-deletes documents older than 30 days. Free feature, no Cloud Functions needed.

---

## 7. BackendManager.gd

New autoload singleton. Single source of truth for all Firebase communication.

**Responsibilities:**
- Anonymous auth on first launch
- Token auto-refresh (55-minute timer)
- Cloud save pull on launch + push on game end
- Leaderboard score submission
- Leaderboard read for result screen
- Account link (Google/Apple)
- Account deletion

**Key methods:**
```gdscript
func init_auth() -> void          # called in _ready()
func refresh_token() -> void       # called by timer + lazy check
func pull_save() -> void           # on launch
func push_save() -> void           # after game end
func submit_daily_score(guesses, time_ms, solved) -> void
func fetch_leaderboard(date: String) -> Array  # returns top 100
func fetch_player_count(date: String) -> int
func link_google(google_token: String) -> void
func link_apple(apple_token: String) -> void
func delete_account() -> void
```

**All methods are async** (`await` on HTTPRequest completion). Game never blocks waiting for Firebase. Failures are logged silently — no error shown to player for non-critical operations (score submit, push save). Account link and deletion show explicit success/failure toasts.

**Estimated size:** ~200 lines.

---

## 8. SaveData Changes

**New fields:**
```gdscript
# Firebase auth (persisted in save_data.cfg [backend] section)
var firebase_uid: String = ""
var firebase_id_token: String = ""
var firebase_refresh_token: String = ""
var firebase_token_expiry: int = 0
var firebase_linked: bool = false
var firebase_display_name: String = ""
var firebase_apple_name: String = ""  # saved on first Apple link only
var last_cloud_push: int = 0          # Unix timestamp, for rate limiting
```

**New save section `[backend]`:**
```
firebase_uid=abc123
firebase_id_token=eyJh...
firebase_refresh_token=AMf-...
firebase_token_expiry=1776651000
firebase_linked=false
firebase_display_name=Player 7F2A
last_cloud_push=1776647187
```

---

## 9. Firebase Console Setup Checklist

These are one-time manual steps in the Firebase Console:

- [ ] Create Firebase project "guess-the-dots"
- [ ] Enable Firestore in production mode
- [ ] Deploy Security Rules (Section 5)
- [ ] Enable Authentication providers: Anonymous, Google, Apple
- [ ] Register Android app: add SHA-1 of release keystore
- [ ] Register iOS app: add bundle ID
- [ ] Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- [ ] Set Firestore TTL policy on `leaderboards` collection: field `submitted_at`, 30-day expiry
- [ ] Store `PROJECT_ID` and `API_KEY` in Godot project settings

---

## 10. Files Affected

| File | Change |
|------|--------|
| `scripts/BackendManager.gd` | New autoload — all Firebase communication |
| `scripts/SaveData.gd` | New `[backend]` section + fields |
| `scenes/Main.tscn` | BackendManager added to autoloads |
| `project.godot` | BackendManager autoload registration + Firebase project settings |

**External dependencies:**
- Google Sign-In Godot plugin (Android)
- Sign in with Apple Godot plugin (iOS)
- Both available on Godot Asset Library

---

## 11. Out of Scope (This Phase)
- Push notifications (daily challenge reminders)
- Cloud Functions (all logic is client-side or Security Rules)
- Friends leaderboard / social graph
- Weekly / all-time leaderboards (Daily only)
- In-app review prompt
- Analytics / crash reporting (Firebase Analytics is a separate decision)
- Profanity filtering for display names
