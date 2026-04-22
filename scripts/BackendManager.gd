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

## Stub methods to be filled in by later tasks
func pull_save() -> void:
	pass

func push_save() -> void:
	pass
