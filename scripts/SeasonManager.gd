extends Node
## SeasonManager — fetches remote season config, manages season XP and milestone claiming.

signal season_loaded(season_name: String)
signal milestone_claimed(milestone_index: int, reward: Dictionary)

const REMOTE_CONFIG_URL := "https://gist.githubusercontent.com/PLACEHOLDER/raw/season.json"
# Replace PLACEHOLDER with actual Gist URL after creating it in GitHub

## Fallback season data used when network is unavailable.
const FALLBACK_SEASON: Dictionary = {
	"active_season": 1,
	"season_name": "Cherry Blossom 🌸",
	"season_end": "2026-06-30",
	"milestones": [500, 1000, 2000, 3500, 5000]
}

## All 6 pre-baked seasons (cosmetics keyed by season number).
const SEASON_DATA: Dictionary = {
	1: {"name": "Cherry Blossom 🌸", "theme": "cherry_blossom", "emoji": "sakura"},
	2: {"name": "Ocean Depths 🌊",   "theme": "ocean_depths",   "emoji": "wave"},
	3: {"name": "Golden Harvest 🌾", "theme": "golden_harvest", "emoji": "harvest"},
	4: {"name": "Northern Lights 🌌","theme": "northern_lights","emoji": "star"},
	5: {"name": "Ember Forest 🍂",   "theme": "ember_forest",   "emoji": "leaf"},
	6: {"name": "Frost Crystal ❄️",  "theme": "frost_crystal",  "emoji": "snowflake"},
}

var _http: HTTPRequest
var _active_config: Dictionary = {}

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_config_fetched)
	_http.timeout = 3.0
	_load_cached_config()
	_fetch_config()

func _load_cached_config() -> void:
	if not SaveData.season_config_cache.is_empty():
		_active_config = SaveData.season_config_cache
	else:
		_active_config = FALLBACK_SEASON

func _fetch_config() -> void:
	_http.request(REMOTE_CONFIG_URL)

func _on_config_fetched(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return  # Use cached config
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return
	var data: Dictionary = json.get_data()
	if not data.has("active_season"):
		return
	# Check if season number changed — reset season_xp if so
	if data.active_season != SaveData.season_number:
		SaveData.season_number  = data.active_season
		SaveData.season_xp      = 0
		SaveData.season_claimed = [false, false, false, false, false]
		SaveData.season_badge   = ""
	_active_config = data
	SaveData.season_config_cache = data
	SaveData.save()
	season_loaded.emit(data.get("season_name", ""))

func get_season_name() -> String:
	return _active_config.get("season_name", "Cherry Blossom 🌸")

func get_milestones() -> Array:
	return _active_config.get("milestones", [500, 1000, 2000, 3500, 5000])

func get_season_end() -> String:
	return _active_config.get("season_end", "")

## Add XP to season progress. Returns list of newly reached milestone indices.
func add_season_xp(amount: int) -> Array[int]:
	SaveData.season_xp += amount
	var milestones := get_milestones()
	var newly_reached: Array[int] = []
	for i in range(milestones.size()):
		if SaveData.season_xp >= milestones[i] and not SaveData.season_claimed[i]:
			newly_reached.append(i)
	SaveData.save()
	return newly_reached

## Claim a milestone reward by index. Returns the reward dict.
func claim_milestone(index: int) -> Dictionary:
	if index < 0 or index >= SaveData.season_claimed.size():
		return {}
	if SaveData.season_claimed[index]:
		return {}
	var milestones := get_milestones()
	if SaveData.season_xp < milestones[index]:
		return {}
	SaveData.season_claimed[index] = true
	var reward := _get_milestone_reward(index)
	_apply_milestone_reward(reward, index)
	SaveData.save()
	milestone_claimed.emit(index, reward)
	return reward

func _get_milestone_reward(index: int) -> Dictionary:
	match index:
		0: return {"type": "coins",   "amount": 100}
		1: return {"type": "tokens",  "item": "hint_token_3"}
		2: return {"type": "theme",   "theme_id": SEASON_DATA.get(SaveData.season_number, {}).get("theme", "")}
		3: return {"type": "coins",   "amount": 300}
		4: return {"type": "shape",   "shape_id": "season_%d_champion" % SaveData.season_number}
	return {}

func _apply_milestone_reward(reward: Dictionary, _index: int) -> void:
	match reward.get("type", ""):
		"coins":  SaveData.add_coins(reward.amount)
		"tokens": ShopManager._apply_purchase(reward.item, ShopManager.get_item(reward.item))
		"theme":
			var tid: String = reward.get("theme_id", "")
			if not tid.is_empty() and not SaveData.unlocked_themes.has(tid):
				SaveData.unlocked_themes.append(tid)
		"shape":
			SaveData.season_badge = reward.get("shape_id", "")
