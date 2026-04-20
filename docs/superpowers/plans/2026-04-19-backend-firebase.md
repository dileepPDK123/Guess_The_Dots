# Backend / Firebase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Firebase anonymous auth, cloud save with conflict resolution, Daily Challenge leaderboard, and account deletion to the game — all via REST API, no native plugin required.

**Architecture:** `BackendManager.gd` is a new autoload singleton that owns all Firebase HTTP communication. `SaveData.gd` gains a `[backend]` section for auth tokens. Main.gd calls BackendManager after game events; BackendManager operates non-blocking (all methods use `await` on HTTPRequest). Failures are silent for non-critical operations.

**Tech Stack:** Godot 4.6, GDScript, `HTTPRequest` node, Firebase Auth REST API, Firestore REST API, Godot ProjectSettings for API_KEY + PROJECT_ID.

**Spec:** `docs/superpowers/specs/2026-04-19-backend-firebase-design.md`

**Prerequisite:** `SaveData.gd` economy changes from Economy plan should be in place (the backend plan reads/writes SaveData fields). Can be built in parallel with Economy plan as long as the `[backend]` section fields are added first (Task 1 of this plan).

---

### Task 1: Add Firebase Fields to SaveData

**Files:**
- Modify: `scripts/SaveData.gd`

- [ ] **Step 1: Add firebase variable declarations after the existing Cosmetic Unlocks section**

```gdscript
# ── Firebase backend ──────────────────────────────────────────────────────────
var firebase_uid: String = ""
var firebase_id_token: String = ""
var firebase_refresh_token: String = ""
var firebase_token_expiry: int = 0      # Unix timestamp; token expires at this time
var firebase_linked: bool = false       # true after Google/Apple account link
var firebase_display_name: String = ""
var firebase_apple_name: String = ""    # saved on first Apple link only
var last_cloud_push: int = 0            # Unix timestamp; rate-limit guard
```

- [ ] **Step 2: Add load/save for the `[backend]` section in `load_data()` and `save()`**

In `load_data()`:
```gdscript
# Backend
firebase_uid           = _cfg.get_value("backend", "firebase_uid",          "")
firebase_id_token      = _cfg.get_value("backend", "firebase_id_token",     "")
firebase_refresh_token = _cfg.get_value("backend", "firebase_refresh_token","")
firebase_token_expiry  = _cfg.get_value("backend", "firebase_token_expiry", 0)
firebase_linked        = _cfg.get_value("backend", "firebase_linked",       false)
firebase_display_name  = _cfg.get_value("backend", "firebase_display_name", "")
firebase_apple_name    = _cfg.get_value("backend", "firebase_apple_name",   "")
last_cloud_push        = _cfg.get_value("backend", "last_cloud_push",       0)
```

In `save()`:
```gdscript
_cfg.set_value("backend", "firebase_uid",          firebase_uid)
_cfg.set_value("backend", "firebase_id_token",     firebase_id_token)
_cfg.set_value("backend", "firebase_refresh_token",firebase_refresh_token)
_cfg.set_value("backend", "firebase_token_expiry", firebase_token_expiry)
_cfg.set_value("backend", "firebase_linked",       firebase_linked)
_cfg.set_value("backend", "firebase_display_name", firebase_display_name)
_cfg.set_value("backend", "firebase_apple_name",   firebase_apple_name)
_cfg.set_value("backend", "last_cloud_push",       last_cloud_push)
```

- [ ] **Step 3: Run the game. Verify launch succeeds. Check that `save_data.cfg` gains a `[backend]` section after the first save.**

- [ ] **Step 4: Commit**
```bash
git add scripts/SaveData.gd
git commit -m "feat: add Firebase auth fields to SaveData [backend] section"
```

---

### Task 2: Add Firebase Project Settings to project.godot

**Files:**
- Modify: `project.godot`

- [ ] **Step 1: Open Project → Project Settings → General. Create a new category "Firebase" with two settings:**
  - `Firebase/api_key` (String, default: `""`)
  - `Firebase/project_id` (String, default: `""`)

In `project.godot`, this will add:
```ini
[Firebase]
api_key=""
project_id=""
```

- [ ] **Step 2: Fill in the actual values once the Firebase project is created (see Spec Section 9 for Firebase Console setup checklist). For now, leave as empty strings — BackendManager will check and skip auth if empty.**

- [ ] **Step 3: Commit**
```bash
git add project.godot
git commit -m "config: add Firebase/api_key and Firebase/project_id project settings"
```

---

### Task 3: Create BackendManager.gd — Core Structure + Anonymous Auth

**Files:**
- Create: `scripts/BackendManager.gd`
- Modify: `project.godot` (add autoload)

- [ ] **Step 1: Create `scripts/BackendManager.gd` with core structure and anonymous auth**

```gdscript
extends Node
## BackendManager — Firebase REST API communication for Guess the Dots.
## All methods are async. Failures are logged silently (non-critical ops).
## Critical ops (account link, deletion) emit success/failure signals.

signal auth_completed(uid: String)
signal cloud_save_pulled
signal cloud_save_pushed
signal leaderboard_ready(top_entries: Array, player_rank: int, total_players: int, percentile: int)
signal account_linked(display_name: String)
signal account_link_failed(reason: String)
signal account_deleted
signal account_delete_failed(reason: String)

const AUTH_URL := "https://identitytoolkit.googleapis.com/v1"
const FS_URL_TEMPLATE := "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents"

var _api_key: String = ""
var _project_id: String = ""
var _fs_url: String = ""

# Each HTTPRequest node handles one concurrent request.
# We create them on demand and free after completion.

func _ready() -> void:
	_api_key    = ProjectSettings.get_setting("Firebase/api_key",    "")
	_project_id = ProjectSettings.get_setting("Firebase/project_id", "")
	if _api_key.is_empty() or _project_id.is_empty():
		push_warning("BackendManager: Firebase not configured. Backend disabled.")
		return
	_fs_url = FS_URL_TEMPLATE % _project_id
	await get_tree().process_frame
	await init_auth()

## Main entry: sign in anonymously if no token cached; otherwise refresh if needed.
func init_auth() -> void:
	if SaveData.firebase_uid.is_empty():
		await _sign_in_anonymous()
	else:
		await _ensure_token_fresh()
	if not SaveData.firebase_uid.is_empty():
		_start_refresh_timer()
		await pull_save()

## Perform anonymous sign-up. Stores UID + tokens in SaveData.
func _sign_in_anonymous() -> void:
	var url  := "%s/accounts:signUp?key=%s" % [AUTH_URL, _api_key]
	var body := '{"returnSecureToken":true}'
	var result := await _post_json(url, body)
	if result.is_empty():
		return
	SaveData.firebase_uid           = result.get("localId", "")
	SaveData.firebase_id_token      = result.get("idToken", "")
	SaveData.firebase_refresh_token = result.get("refreshToken", "")
	SaveData.firebase_token_expiry  = int(Time.get_unix_time_from_system()) + 3600
	SaveData.firebase_display_name  = "Player " + SaveData.firebase_uid.right(4).to_upper()
	SaveData.save()
	auth_completed.emit(SaveData.firebase_uid)
```

- [ ] **Step 2: Add the HTTP helper methods to BackendManager.gd**

```gdscript
## POST request returning parsed JSON dict. Returns {} on failure.
func _post_json(url: String, body: String, headers: PackedStringArray = []) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var all_headers := PackedStringArray(["Content-Type: application/json"])
	all_headers.append_array(headers)
	var err := http.request(url, all_headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		http.queue_free()
		return {}
	var response := await http.request_completed
	http.queue_free()
	# response: [result, response_code, headers, body]
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] not in [200, 201]:
		push_warning("BackendManager POST failed: %d %d" % [response[0], response[1]])
		return {}
	var json := JSON.new()
	if json.parse(response[3].get_string_from_utf8()) != OK:
		return {}
	return json.get_data()

## GET request returning parsed JSON dict.
func _get_json(url: String, id_token: String = "") -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json"])
	if not id_token.is_empty():
		headers.append("Authorization: Bearer " + id_token)
	var err := http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		http.queue_free()
		return {}
	var response := await http.request_completed
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200:
		return {}
	var json := JSON.new()
	if json.parse(response[3].get_string_from_utf8()) != OK:
		return {}
	return json.get_data()

## DELETE request. Returns true on success (204 or 200).
func _delete_request(url: String, id_token: String) -> bool:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + id_token
	])
	http.request(url, headers, HTTPClient.METHOD_DELETE)
	var response := await http.request_completed
	http.queue_free()
	return response[1] in [200, 204]

## PATCH request for Firestore document update.
func _patch_json(url: String, body: String, id_token: String) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + id_token
	])
	http.request(url, headers, HTTPClient.METHOD_PATCH, body)
	var response := await http.request_completed
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] not in [200, 201]:
		return {}
	var json := JSON.new()
	if json.parse(response[3].get_string_from_utf8()) != OK:
		return {}
	return json.get_data()

## PUT request (for leaderboard score).
func _put_json(url: String, body: String, id_token: String) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + id_token
	])
	http.request(url, headers, HTTPClient.METHOD_PUT, body)
	var response := await http.request_completed
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] not in [200, 201]:
		return {}
	var json := JSON.new()
	if json.parse(response[3].get_string_from_utf8()) != OK:
		return {}
	return json.get_data()
```

- [ ] **Step 3: Register BackendManager as an autoload in `project.godot`**
  - Name: `BackendManager`
  - Path: `res://scripts/BackendManager.gd`

- [ ] **Step 4: Run the game with Firebase project settings still empty. Verify BackendManager logs "Firebase not configured" but game starts normally.**

- [ ] **Step 5: Commit**
```bash
git add scripts/BackendManager.gd project.godot
git commit -m "feat: BackendManager autoload - anonymous auth, HTTP helper methods"
```

---

### Task 4: Token Auto-Refresh

**Files:**
- Modify: `scripts/BackendManager.gd`

- [ ] **Step 1: Add `_start_refresh_timer()` and `refresh_token()` methods**

```gdscript
var _refresh_timer: Timer

func _start_refresh_timer() -> void:
	if _refresh_timer != null and is_instance_valid(_refresh_timer):
		_refresh_timer.queue_free()
	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 55.0 * 60.0  # 55 minutes
	_refresh_timer.one_shot  = false
	_refresh_timer.timeout.connect(refresh_token)
	add_child(_refresh_timer)
	_refresh_timer.start()

## Refresh the id_token using the refresh_token. Called by timer and lazily before writes.
func refresh_token() -> void:
	if SaveData.firebase_refresh_token.is_empty():
		return
	var url  := "%s/token?key=%s" % [AUTH_URL, _api_key]
	var body := '{"grant_type":"refresh_token","refresh_token":"%s"}' % SaveData.firebase_refresh_token
	var result := await _post_json(url, body)
	if result.is_empty():
		return
	SaveData.firebase_id_token     = result.get("id_token", SaveData.firebase_id_token)
	SaveData.firebase_token_expiry = int(Time.get_unix_time_from_system()) + 3600
	SaveData.save()

## Ensure the token is fresh before a write. Refreshes if it expires within 60 seconds.
func _ensure_token_fresh() -> void:
	var now := int(Time.get_unix_time_from_system())
	if now > SaveData.firebase_token_expiry - 60:
		await refresh_token()
```

- [ ] **Step 2: Call `_ensure_token_fresh()` at the top of any method that makes an authenticated write**

- [ ] **Step 3: The timer starts automatically in `init_auth()` after auth completes (already wired in Task 3 Step 1). Verify by checking that `_refresh_timer` is created in Output panel on launch.**

- [ ] **Step 4: Commit**
```bash
git add scripts/BackendManager.gd
git commit -m "feat: Firebase token auto-refresh - 55min timer + lazy check before writes"
```

---

### Task 5: Cloud Save — Pull on Launch

**Files:**
- Modify: `scripts/BackendManager.gd`

- [ ] **Step 1: Add Firestore field mapping helpers**

```gdscript
## Convert SaveData to a Firestore fields dict.
func _save_to_firestore_fields() -> Dictionary:
	var fields := {}
	var int_fields := {
		"xp": SaveData.xp, "level": SaveData.level, "coins": SaveData.coins,
		"total_xp_earned": SaveData.total_xp_earned, "games_played": SaveData.games_played,
		"games_won": SaveData.games_won, "current_win_streak": SaveData.current_win_streak,
		"max_win_streak": SaveData.max_win_streak, "daily_streak": SaveData.daily_streak,
		"daily_max_streak": SaveData.daily_max_streak, "login_streak": SaveData.login_streak,
		"campaign_max_unlocked": SaveData.campaign_max_unlocked,
		"updated_at": int(Time.get_unix_time_from_system())
	}
	for k in int_fields:
		fields[k] = {"integerValue": str(int_fields[k])}

	var bool_fields := {"ads_removed": SaveData.ads_removed}
	for k in bool_fields:
		fields[k] = {"booleanValue": bool_fields[k]}

	var arr_fields := {
		"unlocked_themes": SaveData.unlocked_themes,
		"unlocked_shapes": SaveData.unlocked_shapes,
	}
	for k in arr_fields:
		var arr_vals: Array = []
		for v in arr_fields[k]:
			arr_vals.append({"stringValue": str(v)})
		fields[k] = {"arrayValue": {"values": arr_vals}}

	return {"fields": fields}

## Parse Firestore fields dict back to a plain Dictionary.
func _firestore_fields_to_dict(doc: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var fields: Dictionary = doc.get("fields", {})
	for k in fields:
		var v: Dictionary = fields[k]
		if v.has("integerValue"):
			result[k] = int(v.integerValue)
		elif v.has("booleanValue"):
			result[k] = bool(v.booleanValue)
		elif v.has("stringValue"):
			result[k] = str(v.stringValue)
		elif v.has("arrayValue"):
			var arr: Array = []
			for item in v.arrayValue.get("values", []):
				if item.has("stringValue"): arr.append(str(item.stringValue))
				elif item.has("integerValue"): arr.append(int(item.integerValue))
			result[k] = arr
	return result
```

- [ ] **Step 2: Add `pull_save()` method**

```gdscript
## Fetch cloud save and apply if it has higher total_xp_earned than local.
func pull_save() -> void:
	if SaveData.firebase_uid.is_empty() or SaveData.firebase_id_token.is_empty():
		return
	var url := "%s/users/%s/save" % [_fs_url, SaveData.firebase_uid]
	var doc := await _get_json(url, SaveData.firebase_id_token)
	if doc.is_empty():
		# Document doesn't exist (new player) — push local save up
		await push_save()
		return

	var cloud := _firestore_fields_to_dict(doc)
	var local_xp: int = SaveData.total_xp_earned
	var cloud_xp: int = cloud.get("total_xp_earned", 0)

	if cloud_xp > local_xp:
		# Cloud wins — apply to local
		_apply_cloud_to_local(cloud)
		SaveData.save()
		cloud_save_pulled.emit()
		# Toast shown by Main.gd listening to signal
	else:
		# Local wins or equal — push to cloud
		await push_save()

func _apply_cloud_to_local(cloud: Dictionary) -> void:
	if cloud.has("xp"):                  SaveData.xp                  = cloud.xp
	if cloud.has("level"):               SaveData.level               = cloud.level
	if cloud.has("coins"):               SaveData.coins               = cloud.coins
	if cloud.has("total_xp_earned"):     SaveData.total_xp_earned     = cloud.total_xp_earned
	if cloud.has("games_played"):        SaveData.games_played        = cloud.games_played
	if cloud.has("games_won"):           SaveData.games_won           = cloud.games_won
	if cloud.has("current_win_streak"):  SaveData.current_win_streak  = cloud.current_win_streak
	if cloud.has("max_win_streak"):      SaveData.max_win_streak      = cloud.max_win_streak
	if cloud.has("daily_streak"):        SaveData.daily_streak        = cloud.daily_streak
	if cloud.has("daily_max_streak"):    SaveData.daily_max_streak    = cloud.daily_max_streak
	if cloud.has("login_streak"):        SaveData.login_streak        = cloud.login_streak
	if cloud.has("campaign_max_unlocked"): SaveData.campaign_max_unlocked = cloud.campaign_max_unlocked
	if cloud.has("unlocked_themes"):     SaveData.unlocked_themes     = cloud.unlocked_themes
	if cloud.has("unlocked_shapes"):     SaveData.unlocked_shapes     = cloud.unlocked_shapes
	if cloud.has("ads_removed"):         SaveData.ads_removed         = cloud.ads_removed
```

- [ ] **Step 3: In `Main.gd _ready()`, connect `BackendManager.cloud_save_pulled` to show a toast**

```gdscript
BackendManager.cloud_save_pulled.connect(func():
	_show_toast("Progress restored ✓")
)
```

- [ ] **Step 4: Run the game with Firebase configured. Check Output for any HTTP errors. If Firebase project exists and anonymous auth succeeds, cloud save pull/push should complete silently.**

- [ ] **Step 5: Commit**
```bash
git add scripts/BackendManager.gd scripts/Main.gd
git commit -m "feat: Firebase cloud save pull on launch - conflict resolution by total_xp_earned"
```

---

### Task 6: Cloud Save — Push After Game End

**Files:**
- Modify: `scripts/BackendManager.gd`
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add `push_save()` method with rate limiting**

```gdscript
const PUSH_RATE_LIMIT_SECONDS := 10

## Push local save to Firestore. Rate limited to at most once per 10 seconds.
func push_save() -> void:
	if SaveData.firebase_uid.is_empty() or SaveData.firebase_id_token.is_empty():
		return
	var now := int(Time.get_unix_time_from_system())
	if now - SaveData.last_cloud_push < PUSH_RATE_LIMIT_SECONDS:
		return  # Rate limited
	await _ensure_token_fresh()
	var url    := "%s/users/%s/save" % [_fs_url, SaveData.firebase_uid]
	var fields := _save_to_firestore_fields()
	var body   := JSON.stringify(fields)
	var result := await _patch_json(url, body, SaveData.firebase_id_token)
	if not result.is_empty():
		SaveData.last_cloud_push = now
		SaveData.save()
		cloud_save_pushed.emit()
```

- [ ] **Step 2: In `Main.gd _finish_game()`, call `BackendManager.push_save()` after recording stats**

```gdscript
# After SaveData.save() is called in _finish_game():
BackendManager.push_save()  # async, fire and forget
```

Also call on achievement unlock and IAP purchase (those use SaveData signals — connect in BackendManager or Main.gd).

- [ ] **Step 3: Run the game. Finish a round. Verify in Firebase Console → Firestore that the `users/{uid}/save` document was created/updated.**

- [ ] **Step 4: Commit**
```bash
git add scripts/BackendManager.gd scripts/Main.gd
git commit -m "feat: Firebase cloud save push after game end - rate limited to once per 10s"
```

---

### Task 7: Daily Leaderboard — Submit Score

**Files:**
- Modify: `scripts/BackendManager.gd`
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add `submit_daily_score()` method**

```gdscript
## Submit daily challenge score to Firestore leaderboard.
## Only submits if result is an improvement over existing score.
func submit_daily_score(guesses_used: int, time_ms: int, solved: bool) -> void:
	if SaveData.firebase_uid.is_empty() or SaveData.firebase_id_token.is_empty():
		return
	await _ensure_token_fresh()
	var date := Time.get_date_string_from_system()
	var score_url := "%s/leaderboards/%s/scores/%s" % [_fs_url, date, SaveData.firebase_uid]

	# Fetch existing score for today
	var existing := await _get_json(score_url, SaveData.firebase_id_token)
	var existing_data: Dictionary = {}
	if not existing.is_empty():
		existing_data = _firestore_fields_to_dict(existing)

	# Determine if this is an improvement
	var should_submit := false
	if existing_data.is_empty():
		should_submit = true
	elif not solved:
		should_submit = false  # Don't overwrite a solved entry with a loss
	else:
		var ex_guesses: int = existing_data.get("guesses_used", 9999)
		var ex_time:    int = existing_data.get("time_ms",      9999999)
		if guesses_used < ex_guesses:
			should_submit = true
		elif guesses_used == ex_guesses and time_ms < ex_time:
			should_submit = true

	if not should_submit:
		return

	var display_name := SaveData.firebase_display_name
	if display_name.is_empty():
		display_name = "Player " + SaveData.firebase_uid.right(4).to_upper()

	var doc := {
		"fields": {
			"guesses_used":  {"integerValue": str(guesses_used)},
			"time_ms":       {"integerValue": str(time_ms)},
			"display_name":  {"stringValue":  display_name},
			"solved":        {"booleanValue": solved},
			"submitted_at":  {"integerValue": str(int(Time.get_unix_time_from_system()))}
		}
	}
	await _put_json(score_url, JSON.stringify(doc), SaveData.firebase_id_token)
```

- [ ] **Step 2: In `Main.gd _finish_game()`, call `submit_daily_score()` when mode is DAILY**

```gdscript
if current_mode == GameMode.DAILY:
	var time_ms := _game_elapsed_ms()
	BackendManager.submit_daily_score(guess_history.size(), time_ms, did_win)
```

- [ ] **Step 3: Run a Daily Challenge. Win it. Verify in Firebase Console → Firestore → leaderboards/{today}/scores/{uid} that the document was created.**

- [ ] **Step 4: Commit**
```bash
git add scripts/BackendManager.gd scripts/Main.gd
git commit -m "feat: Daily leaderboard score submission - only submits improvements"
```

---

### Task 8: Daily Leaderboard — Read and Display

**Files:**
- Modify: `scripts/BackendManager.gd`
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add `fetch_leaderboard()` and `fetch_player_count()` methods**

```gdscript
## Fetch top 100 solved scores for today's leaderboard.
## Returns Array of {display_name, guesses_used, time_ms} sorted best-first.
func fetch_leaderboard(date: String) -> Array:
	if SaveData.firebase_id_token.is_empty():
		return []
	var query_url := "%s:runQuery" % _fs_url
	var query_body := JSON.stringify({
		"structuredQuery": {
			"from": [{"collectionId": "scores", "allDescendants": true}],
			"where": {
				"fieldFilter": {
					"field": {"fieldPath": "solved"},
					"op": "EQUAL",
					"value": {"booleanValue": true}
				}
			},
			"orderBy": [
				{"field": {"fieldPath": "guesses_used"}, "direction": "ASCENDING"},
				{"field": {"fieldPath": "time_ms"},      "direction": "ASCENDING"}
			],
			"limit": 100
		}
	})
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + SaveData.firebase_id_token
	])
	var http := HTTPRequest.new()
	add_child(http)
	http.request(query_url, headers, HTTPClient.METHOD_POST, query_body)
	var response := await http.request_completed
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200:
		return []
	var json := JSON.new()
	if json.parse(response[3].get_string_from_utf8()) != OK:
		return []
	var raw: Array = json.get_data()
	var entries: Array = []
	for item in raw:
		var doc: Dictionary = item.get("document", {})
		if doc.is_empty(): continue
		var fields := _firestore_fields_to_dict(doc)
		entries.append({
			"display_name": fields.get("display_name", "?"),
			"guesses_used": fields.get("guesses_used", 0),
			"time_ms":      fields.get("time_ms", 0)
		})
	return entries

## Fetch total count of all scores (solved + unsolved) for today.
func fetch_player_count(date: String) -> int:
	if SaveData.firebase_id_token.is_empty():
		return 0
	var query_url := "%s:runAggregationQuery" % _fs_url
	var query_body := JSON.stringify({
		"structuredQuery": {"from": [{"collectionId": "scores", "allDescendants": true}]},
		"aggregations": [{"count": {}}]
	})
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + SaveData.firebase_id_token
	])
	var http := HTTPRequest.new()
	add_child(http)
	http.request(query_url, headers, HTTPClient.METHOD_POST, query_body)
	var response := await http.request_completed
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200:
		return 0
	var json := JSON.new()
	if json.parse(response[3].get_string_from_utf8()) != OK:
		return 0
	var raw: Array = json.get_data()
	if raw.is_empty(): return 0
	return int(raw[0].get("result", {}).get("aggregateFields", {}).get("field_1", {}).get("integerValue", "0"))
```

- [ ] **Step 2: Add `_compute_percentile()` client-side helper**

```gdscript
func _compute_percentile(player_guesses: int, total_players: int, top_100: Array) -> int:
	if total_players == 0:
		return 50
	var worse_count := 0
	for entry in top_100:
		if entry.get("guesses_used", 0) > player_guesses:
			worse_count += 1
	# Estimate beyond top 100: assume remaining players scored worse
	worse_count += max(0, total_players - 100)
	return int((float(worse_count) / float(total_players)) * 100)
```

- [ ] **Step 3: Wire fetch into `Main.gd _show_result_sheet()` for Daily mode**

In `_show_result_sheet()`, when `current_mode == GameMode.DAILY`:
```gdscript
if current_mode == GameMode.DAILY:
	var date := Time.get_date_string_from_system()
	# Fire parallel fetches
	var top_entries := await BackendManager.fetch_leaderboard(date)
	var total_count := await BackendManager.fetch_player_count(date)
	var player_guesses := guess_history.size()
	var percentile := BackendManager._compute_percentile(player_guesses, total_count, top_entries)

	# Build leaderboard UI in the result sheet
	var rank_lbl := Label.new()
	rank_lbl.text = "Today's Daily — Better than %d%% of %d players" % [percentile, total_count]
	vbox.add_child(rank_lbl)

	# Find player's rank in top 100
	var player_rank := -1
	for i in range(top_entries.size()):
		if top_entries[i].display_name == SaveData.firebase_display_name:
			player_rank = i + 1
			break

	# Show top 10 + player row
	var shown_count := 0
	var player_shown := false
	for i in range(mini(top_entries.size(), 10)):
		_add_leaderboard_row(vbox, i + 1, top_entries[i], false)
		shown_count += 1
		if top_entries[i].display_name == SaveData.firebase_display_name:
			player_shown = true

	if not player_shown and player_rank > 0:
		var separator_lbl := Label.new()
		separator_lbl.text = "..."
		vbox.add_child(separator_lbl)
		_add_leaderboard_row(vbox, player_rank, top_entries[player_rank - 1], true)

func _add_leaderboard_row(container: VBoxContainer, rank: int, entry: Dictionary, is_player: bool) -> void:
	var row := HBoxContainer.new()
	var rank_lbl := Label.new()
	rank_lbl.text = "#%d" % rank
	rank_lbl.custom_minimum_size.x = 40
	var name_lbl := Label.new()
	name_lbl.text = entry.get("display_name", "?")
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var score_lbl := Label.new()
	var guesses: int = entry.get("guesses_used", 0)
	var time_sec: float = entry.get("time_ms", 0) / 1000.0
	score_lbl.text = "%d guess%s · %ds" % [guesses, "es" if guesses != 1 else "", int(time_sec)]
	if is_player:
		for lbl in [rank_lbl, name_lbl, score_lbl]:
			lbl.add_theme_color_override("font_color", Color("#F472B6"))
	row.add_child(rank_lbl)
	row.add_child(name_lbl)
	row.add_child(score_lbl)
	container.add_child(row)
```

- [ ] **Step 4: Run a Daily Challenge with Firebase configured. Win it. Verify the leaderboard appears on the result sheet, showing your rank and percentile.**

- [ ] **Step 5: Commit**
```bash
git add scripts/BackendManager.gd scripts/Main.gd
git commit -m "feat: Daily leaderboard read + display - top 10 + player rank + percentile"
```

---

### Task 9: Google Sign-In (Android)

**Files:**
- Modify: `scripts/BackendManager.gd`

This task requires the Google Sign-In Godot plugin. The plugin provides a `GoogleSignIn` singleton.

- [ ] **Step 1: Install the Google Sign-In plugin from Godot Asset Library. Enable it in Project → Export → Android.**

- [ ] **Step 2: Add `link_google()` method to BackendManager**

```gdscript
## Link anonymous account to Google. Requires GoogleSignIn plugin.
## google_token: the ID token returned by the plugin after user signs in.
func link_google(google_token: String) -> void:
	if SaveData.firebase_uid.is_empty():
		account_link_failed.emit("Not signed in")
		return
	await _ensure_token_fresh()
	var url := "%s/accounts:signInWithIdp?key=%s" % [AUTH_URL, _api_key]
	var body := JSON.stringify({
		"requestUri": "https://guess-the-dots.firebaseapp.com",
		"postBody": "id_token=%s&providerId=google.com" % google_token,
		"returnSecureToken": true,
		"returnIdpCredential": true,
		"idToken": SaveData.firebase_id_token  # links to existing anonymous account
	})
	var result := await _post_json(url, body)
	if result.is_empty() or result.has("error"):
		account_link_failed.emit(result.get("error", {}).get("message", "Link failed"))
		return
	# Update tokens (UID stays the same — anonymous account is preserved)
	SaveData.firebase_id_token      = result.get("idToken", SaveData.firebase_id_token)
	SaveData.firebase_refresh_token = result.get("refreshToken", SaveData.firebase_refresh_token)
	SaveData.firebase_token_expiry  = int(Time.get_unix_time_from_system()) + 3600
	SaveData.firebase_linked        = true
	# Update display name from Google profile
	var provider_data: Array = result.get("providerUserInfo", [])
	if not provider_data.is_empty():
		var display_name: String = provider_data[0].get("displayName", "")
		if not display_name.is_empty():
			SaveData.firebase_display_name = display_name.left(20)
	SaveData.save()
	account_linked.emit(SaveData.firebase_display_name)

## Trigger the Google Sign-In flow (calls plugin, then calls link_google with the token).
func start_google_sign_in() -> void:
	if not ClassDB.class_exists("GoogleSignIn"):
		account_link_failed.emit("Google Sign-In plugin not available")
		return
	var gsi := ClassDB.instantiate("GoogleSignIn")
	# Plugin-specific call — adjust to actual plugin API
	var token: String = await gsi.get_google_id_token()
	if token.is_empty():
		account_link_failed.emit("Sign-in cancelled")
		return
	await link_google(token)
```

- [ ] **Step 3: In `Main.gd`, add "Sign in to sync across devices" button in Settings sheet**

```gdscript
if not SaveData.firebase_linked:
	var sync_btn := Button.new()
	sync_btn.text = "Sign in to sync across devices"
	sync_btn.pressed.connect(func():
		if OS.get_name() == "Android":
			BackendManager.start_google_sign_in()
		elif OS.get_name() == "iOS":
			BackendManager.start_apple_sign_in()
	)
	vbox.add_child(sync_btn)
else:
	var linked_lbl := Label.new()
	linked_lbl.text = "✓ Synced as %s" % SaveData.firebase_display_name
	vbox.add_child(linked_lbl)

BackendManager.account_linked.connect(func(name: String):
	_show_toast("Account linked! Your progress is now protected ✓")
)
BackendManager.account_link_failed.connect(func(reason: String):
	_show_toast("Sign-in failed: %s" % reason)
)
```

- [ ] **Step 4: Test on Android device with the plugin installed. Tap "Sign in" → Google sign-in sheet appears → select account → verify `firebase_linked = true` in save file.**

- [ ] **Step 5: Commit**
```bash
git add scripts/BackendManager.gd scripts/Main.gd
git commit -m "feat: Google Sign-In link - anonymous account preserved, display name from Google profile"
```

---

### Task 10: Sign in with Apple (iOS)

**Files:**
- Modify: `scripts/BackendManager.gd`

Apple Sign-In is required if ANY third-party login is offered on iOS.

- [ ] **Step 1: Install Sign in with Apple Godot plugin. Enable in Project → Export → iOS.**

- [ ] **Step 2: Add `link_apple()` and `start_apple_sign_in()` methods**

```gdscript
func link_apple(apple_token: String, apple_display_name: String = "") -> void:
	if SaveData.firebase_uid.is_empty():
		account_link_failed.emit("Not signed in")
		return
	await _ensure_token_fresh()
	# Save Apple name immediately — Apple only sends it once (first sign-in)
	if not apple_display_name.is_empty() and SaveData.firebase_apple_name.is_empty():
		SaveData.firebase_apple_name = apple_display_name.left(20)

	var url := "%s/accounts:signInWithIdp?key=%s" % [AUTH_URL, _api_key]
	var body := JSON.stringify({
		"requestUri": "https://guess-the-dots.firebaseapp.com",
		"postBody": "id_token=%s&providerId=apple.com" % apple_token,
		"returnSecureToken": true,
		"idToken": SaveData.firebase_id_token
	})
	var result := await _post_json(url, body)
	if result.is_empty() or result.has("error"):
		account_link_failed.emit(result.get("error", {}).get("message", "Link failed"))
		return
	SaveData.firebase_id_token      = result.get("idToken", SaveData.firebase_id_token)
	SaveData.firebase_refresh_token = result.get("refreshToken", SaveData.firebase_refresh_token)
	SaveData.firebase_token_expiry  = int(Time.get_unix_time_from_system()) + 3600
	SaveData.firebase_linked        = true
	# Use saved Apple name for display (Apple doesn't resend name on subsequent logins)
	if not SaveData.firebase_apple_name.is_empty():
		SaveData.firebase_display_name = SaveData.firebase_apple_name
	SaveData.save()
	account_linked.emit(SaveData.firebase_display_name)

func start_apple_sign_in() -> void:
	if not ClassDB.class_exists("AppleSignIn"):
		account_link_failed.emit("Sign in with Apple plugin not available")
		return
	var asi := ClassDB.instantiate("AppleSignIn")
	# Plugin-specific call — adjust to actual plugin API
	var result: Dictionary = await asi.get_apple_credential()
	var token: String = result.get("id_token", "")
	var name: String  = result.get("display_name", "")
	if token.is_empty():
		account_link_failed.emit("Sign-in cancelled")
		return
	await link_apple(token, name)
```

- [ ] **Step 3: Verify the Settings sheet "Sign in" button (added in Task 9) already handles iOS by calling `start_apple_sign_in()` when `OS.get_name() == "iOS"`.**

- [ ] **Step 4: Test on iOS device. Tap "Sign in" → Apple sheet → select account → verify linked.**

- [ ] **Step 5: Commit**
```bash
git add scripts/BackendManager.gd
git commit -m "feat: Sign in with Apple - saves name on first link (Apple only sends it once)"
```

---

### Task 11: Account Deletion (GDPR + Apple Requirement)

**Files:**
- Modify: `scripts/BackendManager.gd`
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add `delete_account()` method**

```gdscript
## Delete account: anonymise leaderboard → delete save → delete auth → wipe local.
func delete_account() -> void:
	if SaveData.firebase_uid.is_empty():
		account_delete_failed.emit("Not signed in")
		return
	await _ensure_token_fresh()
	var uid   := SaveData.firebase_uid
	var token := SaveData.firebase_id_token

	# Step 1: Anonymise last 30 days of leaderboard scores
	await _anonymise_leaderboard_scores(uid, token)

	# Step 2: Delete cloud save document
	var save_url := "%s/users/%s/save" % [_fs_url, uid]
	await _delete_request(save_url, token)

	# Step 3: Delete Firebase Auth user
	var auth_url := "%s/accounts:delete?key=%s" % [AUTH_URL, _api_key]
	var body     := '{"idToken":"%s"}' % token
	await _post_json(auth_url, body)

	# Step 4: Wipe local save file
	DirAccess.remove_absolute("user://save_data.cfg")

	# Step 5: Emit signal — Main.gd will restart/reset
	account_deleted.emit()

func _anonymise_leaderboard_scores(uid: String, token: String) -> void:
	# Only anonymise last 30 days (TTL policy handles older records)
	var now := Time.get_unix_time_from_system()
	for days_back in range(30):
		var unix := now - days_back * 86400
		var date := Time.get_date_string_from_unix_time(int(unix))
		var url  := "%s/leaderboards/%s/scores/%s" % [_fs_url, date, uid]
		# Check if doc exists — fetch first
		var existing := await _get_json(url, token)
		if existing.is_empty():
			continue
		# PATCH display_name to "Deleted Player"
		var patch_body := JSON.stringify({
			"fields": {"display_name": {"stringValue": "Deleted Player"}}
		})
		await _patch_json(url + "?updateMask.fieldPaths=display_name", patch_body, token)
```

- [ ] **Step 2: Add "Delete Account & Data" button in Settings sheet in Main.gd**

```gdscript
var delete_btn := Button.new()
delete_btn.text = "Delete Account & Data"
delete_btn.add_theme_color_override("font_color", Color("#EF4444"))
delete_btn.pressed.connect(_confirm_account_deletion)
vbox.add_child(delete_btn)

func _confirm_account_deletion() -> void:
	var sheet := _build_bottom_sheet("Delete Account?")
	var vbox := sheet.get_node("Content") as VBoxContainer
	var warn_lbl := Label.new()
	warn_lbl.text = "This permanently deletes your progress, XP, achievements, and leaderboard history. This cannot be undone."
	warn_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warn_lbl.add_theme_color_override("font_color", Color("#6B4E71"))
	vbox.add_child(warn_lbl)
	var confirm_btn := Button.new()
	confirm_btn.text = "Delete Everything"
	confirm_btn.add_theme_color_override("font_color", Color.WHITE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#EF4444")
	sb.corner_radius_top_left = sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = sb.corner_radius_bottom_right = 14
	confirm_btn.add_theme_stylebox_override("normal", sb)
	confirm_btn.pressed.connect(func():
		BackendManager.delete_account()
	)
	vbox.add_child(confirm_btn)
```

- [ ] **Step 3: Connect `BackendManager.account_deleted` signal to restart the app to a clean state**

```gdscript
BackendManager.account_deleted.connect(func():
	# Restart: reload the scene tree from Splash
	get_tree().change_scene_to_file("res://scenes/Splash.tscn")
)
BackendManager.account_delete_failed.connect(func(reason: String):
	_show_toast("Delete failed: %s" % reason)
)
```

- [ ] **Step 4: Test account deletion. Go to Settings → Delete Account. Confirm. Verify the app returns to splash with no saved data, and Firestore shows the save document deleted.**

- [ ] **Step 5: Commit**
```bash
git add scripts/BackendManager.gd scripts/Main.gd
git commit -m "feat: account deletion - anonymise leaderboard, delete Firestore doc, wipe local, restart"
```

---

### Task 12: Deploy Firestore Security Rules

This is a one-time manual step in the Firebase Console — not a code change.

- [ ] **Step 1: Open Firebase Console → Firestore → Rules.**

- [ ] **Step 2: Paste and publish the following rules:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Cloud save — owner only
    match /users/{uid}/save {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    // Leaderboard — anyone authenticated can read; owner can only write their own score
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

- [ ] **Step 3: Set Firestore TTL policy on leaderboards collection:**
  - Firebase Console → Firestore → Indexes → TTL policies
  - Collection: `leaderboards/{date}/scores`
  - Field: `submitted_at`
  - TTL: 30 days

- [ ] **Step 4: Register Android app in Firebase Console:**
  - Add Android app with package name matching `project.godot` export config
  - Add SHA-1 fingerprint of debug + release keystores
  - Download `google-services.json` → place in `android/build/`

- [ ] **Step 5: Register iOS app in Firebase Console:**
  - Add iOS app with bundle ID matching export config
  - Download `GoogleService-Info.plist` → place in `ios/` export folder

- [ ] **Step 6: Commit a note that security rules are deployed and checklist is done**
```bash
git commit --allow-empty -m "ops: Firebase security rules deployed, TTL policy set, apps registered"
```

---

## Self-Review Checklist

- [x] **SaveData [backend] section**: 8 firebase fields + last_cloud_push
- [x] **Project settings**: Firebase/api_key and Firebase/project_id
- [x] **Anonymous auth**: Signs up silently on first launch, stores UID + tokens
- [x] **Token auto-refresh**: 55-min timer + lazy `_ensure_token_fresh()` before writes
- [x] **Cloud save pull**: On launch after auth, conflict by total_xp_earned
- [x] **Cloud save push**: After game end, rate limited 10s, best-effort
- [x] **Leaderboard submit**: Daily only, improvement-only, Security Rules validate
- [x] **Leaderboard read**: Top 100 + player count + percentile, shown on Daily result
- [x] **Google Sign-In**: Android, links anonymous UID, display name from profile
- [x] **Sign in with Apple**: iOS required, saves name on first link (Apple sends once)
- [x] **Account deletion**: GDPR + Apple requirement, anonymises leaderboard rows, 5-step sequence
- [x] **Security Rules**: guesses 1–8, positive time, boolean solved, owner-only writes
- [x] **TTL policy**: leaderboard documents auto-expire after 30 days (free Firebase feature)

**Display name for anonymous users** (spec Section 2d): `"Player " + firebase_uid.right(4).to_upper()` — wired in `_sign_in_anonymous()`. After Google/Apple link, name comes from provider (already in `link_google()` and `link_apple()`).

**Retry on failed push** (spec Section 3c): The spec calls for one retry on next app launch. Implement by adding a `pending_cloud_push: bool` flag to SaveData:

```gdscript
# In push_save(), on failure:
# result.is_empty() means push failed
# SaveData.pending_cloud_push = true; SaveData.save()

# In init_auth() after auth completes:
# if SaveData.pending_cloud_push:
#   await push_save()
#   SaveData.pending_cloud_push = false
#   SaveData.save()
```

Add `var pending_cloud_push: bool = false` to SaveData and wire this up in BackendManager. This covers the "queue one retry on next launch" requirement.
