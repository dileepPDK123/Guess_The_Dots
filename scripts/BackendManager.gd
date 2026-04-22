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
const PUSH_RATE_LIMIT_SECONDS := 10

var _api_key: String = ""
var _project_id: String = ""
var _fs_url: String = ""
var _initialized: bool = false
var _refresh_timer: Timer = null

func _ready() -> void:
	_api_key    = ProjectSettings.get_setting("Firebase/api_key",    "")
	_project_id = ProjectSettings.get_setting("Firebase/project_id", "")
	if _api_key.is_empty() or _project_id.is_empty():
		push_warning("BackendManager: Firebase not configured. Backend disabled.")
		return
	_fs_url = FS_URL_TEMPLATE % _project_id
	_initialized = true
	await get_tree().process_frame
	await init_auth()

## Main entry: sign in anonymously if no token cached; otherwise refresh if needed.
func init_auth() -> void:
	if not _initialized:
		return
	if SaveData.firebase_uid.is_empty():
		await _sign_in_anonymous()
	else:
		await _ensure_token_fresh()
	if not SaveData.firebase_uid.is_empty():
		_start_refresh_timer()
		# Retry pending push first, then pull
		if SaveData.pending_cloud_push:
			await push_save()
			SaveData.pending_cloud_push = false
			SaveData.save()
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

## Exchange refresh token for a new id token.
## Public — also called by timer and lazily before writes.
func refresh_token() -> void:
	var url  := "https://securetoken.googleapis.com/v1/token?key=%s" % _api_key
	var body := JSON.stringify({
		"grant_type": "refresh_token",
		"refresh_token": SaveData.firebase_refresh_token
	})
	var result := await _post_json(url, body)
	if result.is_empty():
		return
	SaveData.firebase_id_token      = result.get("id_token", "")
	SaveData.firebase_refresh_token = result.get("refresh_token", "")
	SaveData.firebase_token_expiry  = int(Time.get_unix_time_from_system()) + 3600
	SaveData.save()

## Start a timer that refreshes the token every 55 minutes.
func _start_refresh_timer() -> void:
	if _refresh_timer != null and is_instance_valid(_refresh_timer):
		_refresh_timer.queue_free()
	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 55.0 * 60.0  # 55 minutes
	_refresh_timer.one_shot  = false
	_refresh_timer.timeout.connect(refresh_token)
	add_child(_refresh_timer)
	_refresh_timer.start()

## Ensure the token is fresh before a write. Refreshes if expiring within 60 seconds.
func _ensure_token_fresh() -> void:
	var now := int(Time.get_unix_time_from_system())
	if now > SaveData.firebase_token_expiry - 60:
		await refresh_token()

## POST request returning parsed JSON dict. Returns {} on failure.
func _post_json(url: String, body: String, extra_headers: PackedStringArray = PackedStringArray()) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json"])
	headers.append_array(extra_headers)
	var err := http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		http.queue_free()
		return {}
	var response := await http.request_completed
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] not in [200, 201]:
		push_warning("BackendManager POST failed: %d %d" % [response[0], response[1]])
		return {}
	var json := JSON.new()
	if json.parse(response[3].get_string_from_utf8()) != OK:
		return {}
	var data = json.get_data()
	if not data is Dictionary:
		return {}
	return data

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
	var data = json.get_data()
	if not data is Dictionary:
		return {}
	return data

## DELETE request. Returns true on success (200 or 204).
func _delete_request(url: String, id_token: String) -> bool:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + id_token
	])
	var err := http.request(url, headers, HTTPClient.METHOD_DELETE)
	if err != OK:
		http.queue_free()
		return false
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
	var err := http.request(url, headers, HTTPClient.METHOD_PATCH, body)
	if err != OK:
		http.queue_free()
		return {}
	var response := await http.request_completed
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] not in [200, 201]:
		return {}
	var json := JSON.new()
	if json.parse(response[3].get_string_from_utf8()) != OK:
		return {}
	var data = json.get_data()
	if not data is Dictionary:
		return {}
	return data

## PUT request (for leaderboard score).
func _put_json(url: String, body: String, id_token: String) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + id_token
	])
	var err := http.request(url, headers, HTTPClient.METHOD_PUT, body)
	if err != OK:
		http.queue_free()
		return {}
	var response := await http.request_completed
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] not in [200, 201]:
		return {}
	var json := JSON.new()
	if json.parse(response[3].get_string_from_utf8()) != OK:
		return {}
	var data = json.get_data()
	if not data is Dictionary:
		return {}
	return data

## Convert SaveData to a Firestore fields dict for PATCH body.
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

## Parse a Firestore document's fields dict back to a plain Dictionary.
func _firestore_fields_to_dict(doc: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var fields: Dictionary = doc.get("fields", {})
	for k in fields:
		var v: Dictionary = fields[k]
		if v.has("integerValue"):
			result[k] = int(v["integerValue"])
		elif v.has("booleanValue"):
			result[k] = bool(v["booleanValue"])
		elif v.has("stringValue"):
			result[k] = str(v["stringValue"])
		elif v.has("arrayValue"):
			var arr: Array = []
			for item in v["arrayValue"].get("values", []):
				if item.has("stringValue"):
					arr.append(str(item["stringValue"]))
				elif item.has("integerValue"):
					arr.append(int(item["integerValue"]))
			result[k] = arr
	return result

## Apply cloud save dictionary to local SaveData fields.
func _apply_cloud_to_local(cloud: Dictionary) -> void:
	if cloud.has("xp"):                    SaveData.xp                    = cloud["xp"]
	if cloud.has("level"):                 SaveData.level                 = cloud["level"]
	if cloud.has("coins"):                 SaveData.coins                 = cloud["coins"]
	if cloud.has("total_xp_earned"):       SaveData.total_xp_earned       = cloud["total_xp_earned"]
	if cloud.has("games_played"):          SaveData.games_played          = cloud["games_played"]
	if cloud.has("games_won"):             SaveData.games_won             = cloud["games_won"]
	if cloud.has("current_win_streak"):    SaveData.current_win_streak    = cloud["current_win_streak"]
	if cloud.has("max_win_streak"):        SaveData.max_win_streak        = cloud["max_win_streak"]
	if cloud.has("daily_streak"):          SaveData.daily_streak          = cloud["daily_streak"]
	if cloud.has("daily_max_streak"):      SaveData.daily_max_streak      = cloud["daily_max_streak"]
	if cloud.has("login_streak"):          SaveData.login_streak          = cloud["login_streak"]
	if cloud.has("campaign_max_unlocked"): SaveData.campaign_max_unlocked = cloud["campaign_max_unlocked"]
	if cloud.has("unlocked_themes"):       SaveData.unlocked_themes       = cloud["unlocked_themes"]
	if cloud.has("unlocked_shapes"):       SaveData.unlocked_shapes       = cloud["unlocked_shapes"]
	if cloud.has("ads_removed"):           SaveData.ads_removed           = cloud["ads_removed"]

## Fetch cloud save and apply if cloud has higher total_xp_earned.
func pull_save() -> void:
	if SaveData.firebase_uid.is_empty() or SaveData.firebase_id_token.is_empty():
		return
	await _ensure_token_fresh()
	var url := "%s/users/%s/save" % [_fs_url, SaveData.firebase_uid]
	var doc := await _get_json(url, SaveData.firebase_id_token)
	if doc.is_empty():
		# New player or no cloud doc — push local save up
		await push_save()
		return
	var cloud := _firestore_fields_to_dict(doc)
	if cloud.get("total_xp_earned", 0) > SaveData.total_xp_earned:
		_apply_cloud_to_local(cloud)
		SaveData.save()
		cloud_save_pulled.emit()
	else:
		await push_save()

## Push local save to Firestore. Rate limited to once per 10 seconds.
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
		SaveData.pending_cloud_push = false
		SaveData.save()
		cloud_save_pushed.emit()
	else:
		# Push failed — mark for retry on next launch
		SaveData.pending_cloud_push = true
		SaveData.save()

## Submit daily challenge score. Only submits if result is an improvement.
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
			"guesses_used": {"integerValue": str(guesses_used)},
			"time_ms":      {"integerValue": str(time_ms)},
			"display_name": {"stringValue":  display_name},
			"solved":       {"booleanValue": solved},
			"submitted_at": {"integerValue": str(int(Time.get_unix_time_from_system()))}
		}
	}
	await _put_json(score_url, JSON.stringify(doc), SaveData.firebase_id_token)
