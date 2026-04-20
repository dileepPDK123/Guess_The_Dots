# Economy & Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add XP Shop + Season Track, rework ad placements, add 5 new game modes, 6 retention mechanics, combo system, reaction messages, dot trail, and Stats Deep Dive.

**Architecture:** Three new autoload singletons (ShopManager, SeasonManager, ComboManager) handle economy and season state, keeping Main.gd focused on game loop. All new modes are dispatched via `_start_<mode>_game()` methods in Main.gd. Retention mechanics hook into existing game-end and launch flows.

**Tech Stack:** Godot 4.6, GDScript, HTTPRequest for Season remote config (GitHub Gist), ConfigFile sections for new save data.

**Spec:** `docs/superpowers/specs/2026-04-19-economy-features-design.md`

**Dependency:** UI Rework plan must be completed first (this spec depends on it per spec header).

---

### Task 1: Expand SaveData with Economy/Feature Fields

**Files:**
- Modify: `scripts/SaveData.gd`

- [ ] **Step 1: Add all new variable declarations after existing sections**

```gdscript
# ── Ad system ─────────────────────────────────────────────────────────────────
var loss_count_since_ad: int = 0
var next_ad_after_losses: int = 3

# ── Consumable tokens ─────────────────────────────────────────────────────────
# hint_tokens already exists; add the rest:
var second_chance_tokens: int = 0
var extra_guess_tokens: int = 0
var streak_freezes: int = 0

# ── XP Boost ──────────────────────────────────────────────────────────────────
var xp_boost_end_time: int = 0   # Unix timestamp; 0 = inactive

# ── Season ────────────────────────────────────────────────────────────────────
var season_xp: int = 0
var season_number: int = 1
var season_claimed: Array = [false, false, false, false, false]
var season_badge: String = ""
var season_config_cache: Dictionary = {}

# ── Retention ─────────────────────────────────────────────────────────────────
var consecutive_losses: int = 0
var last_first_win_date: String = ""
var weekly_last_week: int = 0
var personal_bests: Dictionary = {}   # "MODE_NAME" -> {min_guesses, min_time_ms}
var current_combo: int = 0

# ── Resume ────────────────────────────────────────────────────────────────────
var resume_mode: int = -1
var resume_secret: Array = []
var resume_history: Array = []
var resume_campaign_level: int = 0

# ── Puzzle history ────────────────────────────────────────────────────────────
var puzzle_history: Array = []        # capped at 200

# ── Shop cosmetics ────────────────────────────────────────────────────────────
var active_sound_pack: String = "default"
var active_share_emoji: String = "default"
var active_board_skin: String = "default"
var unlocked_sound_packs: Array = []
var unlocked_share_emoji: Array = []
var unlocked_board_skins: Array = []
```

- [ ] **Step 2: Add `load_data()` entries for all new fields**

```gdscript
# Ad system
loss_count_since_ad   = _cfg.get_value("progression", "loss_count_since_ad",   0)
next_ad_after_losses  = _cfg.get_value("progression", "next_ad_after_losses",  3)

# Tokens
second_chance_tokens  = _cfg.get_value("tokens", "second_chance_tokens",  0)
extra_guess_tokens    = _cfg.get_value("tokens", "extra_guess_tokens",     0)
streak_freezes        = _cfg.get_value("tokens", "streak_freezes",         0)
xp_boost_end_time     = _cfg.get_value("tokens", "xp_boost_end_time",      0)

# Season
season_xp             = _cfg.get_value("season", "season_xp",       0)
season_number         = _cfg.get_value("season", "season_number",    1)
season_claimed        = _cfg.get_value("season", "season_claimed",   [false,false,false,false,false])
season_badge          = _cfg.get_value("season", "season_badge",     "")
season_config_cache   = _cfg.get_value("season", "config_cache",     {})

# Retention
consecutive_losses    = _cfg.get_value("retention", "consecutive_losses",   0)
last_first_win_date   = _cfg.get_value("retention", "last_first_win_date",  "")
weekly_last_week      = _cfg.get_value("retention", "weekly_last_week",     0)
personal_bests        = _cfg.get_value("retention", "personal_bests",       {})
current_combo         = _cfg.get_value("retention", "current_combo",        0)

# Resume
resume_mode           = _cfg.get_value("resume", "mode",           -1)
resume_secret         = _cfg.get_value("resume", "secret",          [])
resume_history        = _cfg.get_value("resume", "history",         [])
resume_campaign_level = _cfg.get_value("resume", "campaign_level",  0)

# Puzzle history
puzzle_history = _cfg.get_value("history", "puzzle_history", [])

# Shop cosmetics
active_sound_pack     = _cfg.get_value("shop", "active_sound_pack",  "default")
active_share_emoji    = _cfg.get_value("shop", "active_share_emoji", "default")
active_board_skin     = _cfg.get_value("shop", "active_board_skin",  "default")
unlocked_sound_packs  = _cfg.get_value("shop", "unlocked_sound_packs",  [])
unlocked_share_emoji  = _cfg.get_value("shop", "unlocked_share_emoji",  [])
unlocked_board_skins  = _cfg.get_value("shop", "unlocked_board_skins",  [])
```

- [ ] **Step 3: Add `save()` entries for all new fields** (mirror load structure, same keys)

- [ ] **Step 4: Add `record_puzzle_history()` helper**

```gdscript
func record_puzzle_history(mode_name: String, guesses: int, won: bool,
		secret: Array, slots: int, time_ms: int) -> void:
	puzzle_history.append({
		"date":   _today_str(),
		"mode":   mode_name,
		"guesses": guesses,
		"won":    won,
		"secret": secret,
		"slots":  slots,
		"time_ms": time_ms
	})
	if puzzle_history.size() > 200:
		puzzle_history.pop_front()
	save()
```

- [ ] **Step 5: Run game. Verify launch with no errors. Check save file has new sections.**

- [ ] **Step 6: Commit**
```bash
git add scripts/SaveData.gd
git commit -m "feat: expand SaveData with tokens, season, retention, resume, puzzle_history, shop fields"
```

---

### Task 2: Create ComboManager.gd

**Files:**
- Create: `scripts/ComboManager.gd`
- Modify: `project.godot` (add autoload)

- [ ] **Step 1: Create `scripts/ComboManager.gd`**

```gdscript
extends Node
## ComboManager — tracks consecutive wins without hint use and multiplies XP rewards.

signal combo_changed(new_count: int)

var _hint_used_this_round: bool = false

func _ready() -> void:
	pass  # current_combo loaded from SaveData in start_new_round()

## Call at the start of every new round.
func start_round() -> void:
	_hint_used_this_round = false

## Call when a hint is used (token or rewarded ad).
func mark_hint_used() -> void:
	_hint_used_this_round = true

## Call at game end. did_win = outcome, mode_name used to block ineligible modes.
## Returns XP multiplier to apply.
func on_game_finished(did_win: bool, mode_name: String) -> float:
	var ineligible := ["SANDBOX"]  # modes that don't affect combo
	if ineligible.has(mode_name):
		return 1.0

	if did_win and not _hint_used_this_round:
		SaveData.current_combo += 1
	else:
		SaveData.current_combo = 0

	SaveData.save()
	combo_changed.emit(SaveData.current_combo)
	return get_multiplier()

## Returns the XP multiplier for the current combo.
func get_multiplier() -> float:
	match SaveData.current_combo:
		0, 1: return 1.0
		2:    return 1.5
		3:    return 2.0
		_:    return 2.5  # 4+
```

- [ ] **Step 2: Register ComboManager as an autoload in `project.godot`**

Open Project → Project Settings → AutoLoad → Add:
- Name: `ComboManager`
- Path: `res://scripts/ComboManager.gd`

- [ ] **Step 3: In `Main.gd _ready()`, connect the combo_changed signal to update the combo UI**

```gdscript
ComboManager.combo_changed.connect(_on_combo_changed)
```

- [ ] **Step 4: Add `_on_combo_changed()` and the combo flame UI in the header**

```gdscript
var _combo_label: Label

func _on_combo_changed(count: int) -> void:
	if _combo_label == null:
		_combo_label = Label.new()
		_combo_label.name = "ComboLabel"
		$GameLayer/GameVBox/HeaderPanel.add_child(_combo_label)
	if count >= 2:
		_combo_label.text = "🔥 %d" % count
		_combo_label.visible = true
		var tw := create_tween()
		tw.tween_property(_combo_label, "scale", Vector2(1.3, 1.3), 0.1)
		tw.tween_property(_combo_label, "scale", Vector2(1.0, 1.0), 0.1)
	else:
		_combo_label.visible = false
```

- [ ] **Step 5: In `_finish_game()`, call `ComboManager.on_game_finished()` and apply the multiplier to XP**

```gdscript
var multiplier := ComboManager.on_game_finished(did_win, GameMode.keys()[current_mode])
var xp_earned  := int(_base_xp_for_mode() * multiplier)
SaveData.add_xp(xp_earned)
_last_xp_earned = xp_earned
```

- [ ] **Step 6: In `_on_hint_pressed()`, call `ComboManager.mark_hint_used()`.**

- [ ] **Step 7: Run the game. Win 2+ games without hints. Verify 🔥 counter appears in header, XP multiplier increases.**

- [ ] **Step 8: Commit**
```bash
git add scripts/ComboManager.gd project.godot scripts/Main.gd
git commit -m "feat: ComboManager autoload - consecutive win combo tracking, XP multiplier up to 2.5x"
```

---

### Task 3: Create ShopManager.gd

**Files:**
- Create: `scripts/ShopManager.gd`
- Modify: `project.godot` (add autoload)

- [ ] **Step 1: Create `scripts/ShopManager.gd`**

```gdscript
extends Node
## ShopManager — XP Shop catalog, purchase validation, token consumption.

signal purchase_completed(item_id: String)
signal purchase_failed(reason: String)

## Full catalog. cost_type: "xp" or "coins"
const CATALOG: Array[Dictionary] = [
	# Consumables
	{"id": "hint_token_3",        "name": "Hint Token ×3",        "cost": 150,  "cost_type": "xp",    "type": "consumable"},
	{"id": "second_chance_token", "name": "Second Chance Token",   "cost": 200,  "cost_type": "xp",    "type": "consumable"},
	{"id": "extra_guess_token",   "name": "Extra Guess Token",     "cost": 250,  "cost_type": "xp",    "type": "consumable"},
	{"id": "streak_freeze",       "name": "Streak Freeze",         "cost": 300,  "cost_type": "xp",    "type": "consumable"},
	{"id": "xp_boost_1hr",        "name": "XP Boost ×1hr",         "cost": 50,   "cost_type": "coins", "type": "timed"},
	# Sound packs
	{"id": "sound_soft_piano",    "name": "Sound Pack — Soft Piano",  "cost": 600,  "cost_type": "xp",  "type": "permanent"},
	{"id": "sound_nature",        "name": "Sound Pack — Nature",      "cost": 600,  "cost_type": "xp",  "type": "permanent"},
	{"id": "sound_retro_arcade",  "name": "Sound Pack — Retro Arcade","cost": 600,  "cost_type": "xp",  "type": "permanent"},
	# Share emoji packs
	{"id": "emoji_hearts",        "name": "Share Emoji — Hearts",  "cost": 400,  "cost_type": "xp",  "type": "permanent"},
	{"id": "emoji_space",         "name": "Share Emoji — Space",   "cost": 400,  "cost_type": "xp",  "type": "permanent"},
	{"id": "emoji_flowers",       "name": "Share Emoji — Flowers", "cost": 400,  "cost_type": "xp",  "type": "permanent"},
	# Board skins
	{"id": "skin_minimal",        "name": "Board Skin — Minimal",  "cost": 700,  "cost_type": "xp",  "type": "permanent"},
	{"id": "skin_rounded",        "name": "Board Skin — Rounded",  "cost": 700,  "cost_type": "xp",  "type": "permanent"},
	{"id": "skin_diamond",        "name": "Board Skin — Diamond",  "cost": 700,  "cost_type": "xp",  "type": "permanent"},
	# Themes
	{"id": "theme_neon_core",     "name": "Theme — Neon Core",     "cost": 1200, "cost_type": "xp",  "type": "permanent"},
	{"id": "theme_void_protocol", "name": "Theme — Void Protocol", "cost": 1500, "cost_type": "xp",  "type": "permanent"},
	{"id": "theme_solar_flare",   "name": "Theme — Solar Flare",   "cost": 1000, "cost_type": "xp",  "type": "permanent"},
	# Dot shapes
	{"id": "shape_hexagon",       "name": "Dot Shape — Hexagon",   "cost": 500,  "cost_type": "xp",  "type": "permanent"},
	{"id": "shape_diamond",       "name": "Dot Shape — Diamond",   "cost": 500,  "cost_type": "xp",  "type": "permanent"},
	{"id": "shape_star",          "name": "Dot Shape — Star",       "cost": 500,  "cost_type": "xp",  "type": "permanent"},
]

func get_item(item_id: String) -> Dictionary:
	for item in CATALOG:
		if item.id == item_id:
			return item
	return {}

func is_owned(item_id: String) -> bool:
	match item_id:
		"theme_neon_core":     return SaveData.unlocked_themes.has("neon_core")
		"theme_void_protocol": return SaveData.unlocked_themes.has("void_protocol")
		"theme_solar_flare":   return SaveData.unlocked_themes.has("solar_flare")
		"shape_hexagon":       return SaveData.unlocked_shapes.has("hexagon")
		"shape_diamond":       return SaveData.unlocked_shapes.has("diamond")
		"shape_star":          return SaveData.unlocked_shapes.has("star")
		"sound_soft_piano":    return SaveData.unlocked_sound_packs.has("soft_piano")
		"sound_nature":        return SaveData.unlocked_sound_packs.has("nature")
		"sound_retro_arcade":  return SaveData.unlocked_sound_packs.has("retro_arcade")
		"emoji_hearts":        return SaveData.unlocked_share_emoji.has("hearts")
		"emoji_space":         return SaveData.unlocked_share_emoji.has("space")
		"emoji_flowers":       return SaveData.unlocked_share_emoji.has("flowers")
		"skin_minimal":        return SaveData.unlocked_board_skins.has("minimal")
		"skin_rounded":        return SaveData.unlocked_board_skins.has("rounded")
		"skin_diamond":        return SaveData.unlocked_board_skins.has("diamond_skin")
	return false

func purchase(item_id: String) -> bool:
	var item := get_item(item_id)
	if item.is_empty():
		purchase_failed.emit("Unknown item")
		return false

	if item.type == "permanent" and is_owned(item_id):
		purchase_failed.emit("Already owned")
		return false

	# Check balance
	var cost: int = item.cost
	if item.cost_type == "xp":
		if SaveData.total_xp_earned < cost:
			purchase_failed.emit("Not enough XP")
			return false
		# Deduct from spendable pool without affecting level
		SaveData.total_xp_earned -= cost
	else:  # coins
		if not SaveData.spend_coins(cost):
			purchase_failed.emit("Not enough coins")
			return false

	_apply_purchase(item_id, item)
	SaveData.save()
	purchase_completed.emit(item_id)
	return true

func _apply_purchase(item_id: String, item: Dictionary) -> void:
	match item_id:
		"hint_token_3":        SaveData.hint_tokens   = mini(SaveData.hint_tokens   + 3, 10)
		"second_chance_token": SaveData.second_chance_tokens = mini(SaveData.second_chance_tokens + 1, 5)
		"extra_guess_token":   SaveData.extra_guess_tokens   = mini(SaveData.extra_guess_tokens   + 1, 5)
		"streak_freeze":       SaveData.streak_freezes       = mini(SaveData.streak_freezes       + 1, 2)
		"xp_boost_1hr":
			var now := int(Time.get_unix_time_from_system())
			SaveData.xp_boost_end_time = now + 3600
		"theme_neon_core":     SaveData.unlocked_themes.append("neon_core")
		"theme_void_protocol": SaveData.unlocked_themes.append("void_protocol")
		"theme_solar_flare":   SaveData.unlocked_themes.append("solar_flare")
		"shape_hexagon":       SaveData.unlocked_shapes.append("hexagon")
		"shape_diamond":       SaveData.unlocked_shapes.append("diamond")
		"shape_star":          SaveData.unlocked_shapes.append("star")
		"sound_soft_piano":    SaveData.unlocked_sound_packs.append("soft_piano")
		"sound_nature":        SaveData.unlocked_sound_packs.append("nature")
		"sound_retro_arcade":  SaveData.unlocked_sound_packs.append("retro_arcade")
		"emoji_hearts":        SaveData.unlocked_share_emoji.append("hearts")
		"emoji_space":         SaveData.unlocked_share_emoji.append("space")
		"emoji_flowers":       SaveData.unlocked_share_emoji.append("flowers")
		"skin_minimal":        SaveData.unlocked_board_skins.append("minimal")
		"skin_rounded":        SaveData.unlocked_board_skins.append("rounded")
		"skin_diamond":        SaveData.unlocked_board_skins.append("diamond_skin")

## Use a hint token. Returns true if token consumed, false if none available.
func consume_hint_token() -> bool:
	if SaveData.hint_tokens > 0:
		SaveData.hint_tokens -= 1
		SaveData.save()
		return true
	return false

## Use a second chance token. Returns true if consumed.
func consume_second_chance_token() -> bool:
	if SaveData.second_chance_tokens > 0:
		SaveData.second_chance_tokens -= 1
		SaveData.save()
		return true
	return false

## Returns true if an XP boost is active right now.
func is_xp_boost_active() -> bool:
	return int(Time.get_unix_time_from_system()) < SaveData.xp_boost_end_time
```

- [ ] **Step 2: Register ShopManager autoload in `project.godot`**
  - Name: `ShopManager`
  - Path: `res://scripts/ShopManager.gd`

- [ ] **Step 3: Update `_on_hint_pressed()` in Main.gd to check tokens first**

```gdscript
func _on_hint_pressed() -> void:
	if not round_active:
		return
	ComboManager.mark_hint_used()
	if ShopManager.consume_hint_token():
		_grant_hint()  # instant, no ad
		return
	# Fall through to rewarded ad
	if AdManager.is_rewarded_ready():
		AdManager.rewarded_earned.connect(_on_hint_rewarded_earned, CONNECT_ONE_SHOT)
		AdManager.show_rewarded()
	else:
		_grant_hint()
```

- [ ] **Step 4: Run the game. Buy hint tokens (temporarily set SaveData.hint_tokens = 3 in code). Press HINT. Verify tokens are consumed without showing an ad.**

- [ ] **Step 5: Commit**
```bash
git add scripts/ShopManager.gd project.godot scripts/Main.gd
git commit -m "feat: ShopManager autoload - full XP Shop catalog, purchase/token flow"
```

---

### Task 4: Create SeasonManager.gd

**Files:**
- Create: `scripts/SeasonManager.gd`
- Modify: `project.godot` (add autoload)

- [ ] **Step 1: Create `scripts/SeasonManager.gd`**

```gdscript
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
	_load_cached_config()
	_fetch_config()

func _load_cached_config() -> void:
	if not SaveData.season_config_cache.is_empty():
		_active_config = SaveData.season_config_cache
	else:
		_active_config = FALLBACK_SEASON

func _fetch_config() -> void:
	_http.request(REMOTE_CONFIG_URL)
	# Timeout after 3s — handled by HTTPRequest timeout_seconds property
	_http.timeout = 3.0

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
	match reward.type:
		"coins":  SaveData.add_coins(reward.amount)
		"tokens": ShopManager._apply_purchase(reward.item, ShopManager.get_item(reward.item))
		"theme":
			if not SaveData.unlocked_themes.has(reward.theme_id):
				SaveData.unlocked_themes.append(reward.theme_id)
		"shape":
			SaveData.season_badge = reward.shape_id
```

- [ ] **Step 2: Register SeasonManager autoload in `project.godot`**
  - Name: `SeasonManager`
  - Path: `res://scripts/SeasonManager.gd`

- [ ] **Step 3: In `Main.gd _finish_game()`, after awarding XP, also feed SeasonManager**

```gdscript
var newly_reached := SeasonManager.add_season_xp(xp_earned)
if not newly_reached.is_empty():
	_show_toast("Milestone reached! Open the Rewards screen to claim.")
```

- [ ] **Step 4: Run the game. Check the Output panel. Verify SeasonManager initializes without errors and the fallback season loads (no network needed for test).**

- [ ] **Step 5: Commit**
```bash
git add scripts/SeasonManager.gd project.godot scripts/Main.gd
git commit -m "feat: SeasonManager autoload - remote config fetch, season XP, milestone claiming"
```

---

### Task 5: Rework AdManager — Loss-Only Interstitials + Native Ad

**Files:**
- Modify: `scripts/AdManager.gd`

- [ ] **Step 1: Remove the current `on_game_finished()` interstitial call. Add `on_game_lost()`**

Find and remove any `_try_show_interstitial()` call triggered on game completion regardless of outcome.

Add:
```gdscript
func on_game_lost() -> void:
	if SaveData.ads_removed:
		return
	SaveData.loss_count_since_ad += 1
	SaveData.save()
	if SaveData.loss_count_since_ad >= SaveData.next_ad_after_losses and SaveData.games_played > 3:
		_try_show_interstitial()
		SaveData.loss_count_since_ad = 0
		SaveData.next_ad_after_losses = randi_range(2, 4)
		SaveData.save()
```

- [ ] **Step 2: Add native ad support method**

```gdscript
var _native_ad_node: Control  # populated by AdMob plugin on Android

func show_native_ad(parent_container: Control) -> void:
	if SaveData.ads_removed:
		return
	if OS.get_name() != "Android":
		# Desktop placeholder: invisible
		return
	# AdMob Native Ads: create via plugin when available
	# This is a stub — actual AdMob Native Ad integration requires plugin bindings
	if _native_ad_node and is_instance_valid(_native_ad_node):
		parent_container.add_child(_native_ad_node)

func hide_native_ad() -> void:
	if _native_ad_node and is_instance_valid(_native_ad_node):
		_native_ad_node.get_parent().remove_child(_native_ad_node)
```

- [ ] **Step 3: In `Main.gd _finish_game()`, replace any `AdManager.on_game_finished()` call with:**

```gdscript
if not did_win:
	AdManager.on_game_lost()
```

- [ ] **Step 4: Run the game. Lose 3+ times. Verify interstitial fires on loss only, not on wins.**

- [ ] **Step 5: Commit**
```bash
git add scripts/AdManager.gd scripts/Main.gd
git commit -m "feat: ads rework - interstitials on loss only, native ad stub, loss counter persisted"
```

---

### Task 6: Build Rewards Screen (Shop + Season Tabs)

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add `_open_rewards_screen()` method**

```gdscript
func _open_rewards_screen() -> void:
	var sheet := _build_bottom_sheet("Rewards")
	var vbox := sheet.get_node("Content") as VBoxContainer

	# XP balance header
	var xp_lbl := Label.new()
	xp_lbl.text = "⚡ %d XP" % SaveData.total_xp_earned
	xp_lbl.add_theme_color_override("font_color", Color("#F472B6"))
	xp_lbl.add_theme_font_size_override("font_size", 28)
	vbox.add_child(xp_lbl)

	# Tab bar
	var tab_bar := HBoxContainer.new()
	var shop_tab_btn := Button.new()
	shop_tab_btn.text = "⚡ Shop"
	var season_tab_btn := Button.new()
	season_tab_btn.text = "🏅 Season"
	tab_bar.add_child(shop_tab_btn)
	tab_bar.add_child(season_tab_btn)
	vbox.add_child(tab_bar)

	var content_area := ScrollContainer.new()
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var content_vbox := VBoxContainer.new()
	content_area.add_child(content_vbox)
	vbox.add_child(content_area)

	# Default: show shop
	_populate_shop_tab(content_vbox)
	shop_tab_btn.pressed.connect(func():
		_clear_children(content_vbox)
		_populate_shop_tab(content_vbox)
	)
	season_tab_btn.pressed.connect(func():
		_clear_children(content_vbox)
		_populate_season_tab(content_vbox)
	)

func _populate_shop_tab(container: VBoxContainer) -> void:
	for item in ShopManager.CATALOG:
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = item.name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_color_override("font_color", Color("#6B4E71"))
		var cost_str := "%d ⚡" % item.cost if item.cost_type == "xp" else "%d coins" % item.cost
		var buy_btn := Button.new()
		if ShopManager.is_owned(item.id):
			buy_btn.text = "Owned"
			buy_btn.disabled = true
		else:
			buy_btn.text = cost_str
			var item_id: String = item.id
			buy_btn.pressed.connect(func():
				if ShopManager.purchase(item_id):
					_show_toast("Purchased!")
				else:
					_show_toast("Not enough XP")
			)
		row.add_child(name_lbl)
		row.add_child(buy_btn)
		container.add_child(row)

func _populate_season_tab(container: VBoxContainer) -> void:
	var season_name_lbl := Label.new()
	season_name_lbl.text = SeasonManager.get_season_name()
	season_name_lbl.add_theme_color_override("font_color", Color("#6B4E71"))
	container.add_child(season_name_lbl)

	var progress_lbl := Label.new()
	var milestones := SeasonManager.get_milestones()
	progress_lbl.text = "Season XP: %d / %d" % [SaveData.season_xp, milestones.back()]
	container.add_child(progress_lbl)

	for i in range(milestones.size()):
		var row := HBoxContainer.new()
		var milestone_lbl := Label.new()
		milestone_lbl.text = "%d XP" % milestones[i]
		milestone_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var claim_btn := Button.new()
		if SaveData.season_claimed[i]:
			claim_btn.text = "✓ Claimed"
			claim_btn.disabled = true
		elif SaveData.season_xp >= milestones[i]:
			claim_btn.text = "Claim!"
			var idx := i
			claim_btn.pressed.connect(func():
				SeasonManager.claim_milestone(idx)
				_show_toast("Reward claimed!")
				_clear_children(container)
				_populate_season_tab(container)
			)
		else:
			claim_btn.text = "Locked"
			claim_btn.disabled = true
		row.add_child(milestone_lbl)
		row.add_child(claim_btn)
		container.add_child(row)

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
```

- [ ] **Step 2: Add "Rewards" button to Main Menu**

In `_ready()`, after the STATS button injection:
```gdscript
var rewards_btn := Button.new()
rewards_btn.text = "REWARDS"
rewards_btn.custom_minimum_size = Vector2(0, 74)
rewards_btn.pressed.connect(_open_rewards_screen)
var menu_vbox2 := get_node("MenuLayer/MenuPanel/MenuMargin/MenuVBox")
menu_vbox2.add_child(rewards_btn)
```

- [ ] **Step 3: Run the game. Tap REWARDS. Verify the Shop tab lists all items with costs and buy buttons. Switch to Season tab and verify milestone progress.**

- [ ] **Step 4: Commit**
```bash
git add scripts/Main.gd
git commit -m "feat: Rewards screen - Shop tab with full catalog, Season tab with milestone claims"
```

---

### Task 7: Mystery Mode

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add `_start_mystery_game()` method**

```gdscript
func _start_mystery_game() -> void:
	current_mode = GameMode.MYSTERY
	var true_slots := rng.randi_range(3, 5)
	slots_needed  = 1  # Start showing only 1 slot
	MAX_GUESSES   = 12
	secret_sequence = _generate_secret(true_slots, 5)
	_mystery_true_slots = true_slots
	guess_history.clear()
	current_guess.clear()
	_hard_locked_slots.clear()
	round_active = true
	_board_built = false
	_build_wordle_board()
	_build_elimination_tracker()
	_show_game_screen()

var _mystery_true_slots: int = 0
```

- [ ] **Step 2: In `_on_submit_pressed()`, after appending to `guess_history` in Mystery mode, reveal one more slot if not at true count yet**

```gdscript
if current_mode == GameMode.MYSTERY and slots_needed < _mystery_true_slots:
	slots_needed += 1
	# Fade in the newly revealed slot in all future rows
	_expand_mystery_board()

func _expand_mystery_board() -> void:
	# Rebuild active row to show the new slot
	# Simplest: rebuild entire board preserving history
	if has_node("GameLayer/GameVBox/BoardVBox"):
		$GameLayer/GameVBox/BoardVBox.queue_free()
	await get_tree().process_frame
	_board_rows.clear()
	_build_wordle_board()
```

- [ ] **Step 3: Add Mystery to Mode Select grid in `_open_mode_select()`**

```gdscript
{"mode": GameMode.MYSTERY, "name": "Mystery", "desc": "Hidden slot count · 12 guesses"},
```

- [ ] **Step 4: Run a Mystery game. Verify board starts with 1 slot, gains a slot after each guess until true count is reached.**

- [ ] **Step 5: Commit**
```bash
git add scripts/Main.gd
git commit -m "feat: Mystery mode - hidden slot count, one slot reveals per guess"
```

---

### Task 8: Time Trial Mode

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add Time Trial state and `_start_time_trial()` method**

```gdscript
var _time_trial_puzzles_completed: int = 0
var _time_trial_total_time_ms: int = 0
var _time_trial_puzzle_times: Array[int] = []
var _time_trial_start_ms: int = 0
const TIME_TRIAL_TOTAL_PUZZLES := 5

func _start_time_trial() -> void:
	current_mode = GameMode.TIME_TRIAL
	_time_trial_puzzles_completed = 0
	_time_trial_total_time_ms     = 0
	_time_trial_puzzle_times.clear()
	_time_trial_start_ms = Time.get_ticks_msec()
	_start_next_time_trial_puzzle()

func _start_next_time_trial_puzzle() -> void:
	slots_needed = rng.randi_range(3, 4)
	MAX_GUESSES  = 10
	secret_sequence = _generate_secret(slots_needed, 5)
	guess_history.clear()
	current_guess.clear()
	_hard_locked_slots.clear()
	round_active = true
	_board_built = false
	if has_node("GameLayer/GameVBox/BoardVBox"):
		$GameLayer/GameVBox/BoardVBox.queue_free()
	await get_tree().process_frame
	_board_rows.clear()
	_build_wordle_board()
```

- [ ] **Step 2: In `_finish_game()`, handle Time Trial progression**

```gdscript
if current_mode == GameMode.TIME_TRIAL:
	var puzzle_ms := Time.get_ticks_msec() - _time_trial_start_ms
	_time_trial_puzzle_times.append(puzzle_ms)
	_time_trial_total_time_ms += puzzle_ms
	if did_win:
		_time_trial_puzzles_completed += 1
	if _time_trial_puzzles_completed >= TIME_TRIAL_TOTAL_PUZZLES or not did_win:
		_show_time_trial_result()
	else:
		_time_trial_start_ms = Time.get_ticks_msec()
		await get_tree().create_timer(1.0).timeout
		_start_next_time_trial_puzzle()
	return  # Skip normal result sheet

func _show_time_trial_result() -> void:
	var score := _time_trial_puzzles_completed * 1000 - (_time_trial_total_time_ms / 1000)
	var sheet := _build_bottom_sheet("Time Trial Complete")
	var vbox := sheet.get_node("Content") as VBoxContainer
	var score_lbl := Label.new()
	score_lbl.text = "Score: %d" % score
	vbox.add_child(score_lbl)
	for i in range(_time_trial_puzzle_times.size()):
		var t_lbl := Label.new()
		t_lbl.text = "Puzzle %d: %ds" % [i + 1, _time_trial_puzzle_times[i] / 1000]
		vbox.add_child(t_lbl)
	# Update personal best
	var pb: Dictionary = SaveData.personal_bests.get("TIME_TRIAL", {})
	if score > pb.get("best_score", -999999):
		SaveData.personal_bests["TIME_TRIAL"] = {"best_score": score}
		SaveData.save()
		var pb_lbl := Label.new()
		pb_lbl.text = "New PB 🏅"
		vbox.add_child(pb_lbl)
```

- [ ] **Step 3: Add Time Trial to Mode Select grid.**

- [ ] **Step 4: Run Time Trial. Complete 5 puzzles. Verify score = puzzles×1000 - total_seconds shown at end.**

- [ ] **Step 5: Commit**
```bash
git add scripts/Main.gd
git commit -m "feat: Time Trial mode - 5 puzzles back-to-back, cumulative timer, score display"
```

---

### Task 9: Duo Mode

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add Duo mode state**

```gdscript
var _duo_secret_b: Array[int] = []
var _duo_board_b_rows: Array = []
var _duo_board_b_active: int = 0
var _duo_solved_a: bool = false
var _duo_solved_b: bool = false
```

- [ ] **Step 2: Add `_start_duo_game()` method**

```gdscript
func _start_duo_game() -> void:
	current_mode = GameMode.DUO
	slots_needed  = 4
	MAX_GUESSES   = 10
	secret_sequence = _generate_secret(4, 5)
	_duo_secret_b   = _generate_secret(4, 5)
	_duo_solved_a = false
	_duo_solved_b = false
	guess_history.clear()
	current_guess.clear()
	_hard_locked_slots.clear()
	round_active = true

	# Build two boards side by side
	_build_duo_boards()
	_show_game_screen()

func _build_duo_boards() -> void:
	if has_node("GameLayer/GameVBox/DuoHBox"):
		$GameLayer/GameVBox/DuoHBox.queue_free()
	var hbox := HBoxContainer.new()
	hbox.name = "DuoHBox"
	hbox.add_theme_constant_override("separation", 12)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var board_a := _build_duo_single_board("Board A", _board_rows)
	var board_b := _build_duo_single_board("Board B", _duo_board_b_rows)
	hbox.add_child(board_a)
	hbox.add_child(board_b)

	var game_vbox := $GameLayer/GameVBox as VBoxContainer
	game_vbox.add_child(hbox)
	game_vbox.move_child(hbox, 1)

func _build_duo_single_board(board_name: String, row_array: Array) -> VBoxContainer:
	row_array.clear()
	var vbox := VBoxContainer.new()
	vbox.name = board_name
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in range(MAX_GUESSES):
		var row_data := _build_board_row(i, slots_needed)
		vbox.add_child(row_data.container)
		row_array.append(row_data)
	return vbox
```

- [ ] **Step 3: Modify `_on_submit_pressed()` — evaluate guess against BOTH secrets in Duo mode**

```gdscript
if current_mode == GameMode.DUO:
	var feedback_a := _evaluate_guess(current_guess, secret_sequence)
	var feedback_b := _evaluate_guess(current_guess, _duo_secret_b)
	# Store in separate histories
	guess_history.append({"guess": current_guess.duplicate(), "feedback": feedback_a})
	_duo_history_b.append({"guess": current_guess.duplicate(), "feedback": feedback_b})
	_active_row_index = guess_history.size()
	_duo_board_b_active = _active_row_index
	# Refresh both boards
	_refresh_duo_boards()
	if feedback_a.exact == slots_needed: _duo_solved_a = true
	if feedback_b.exact == slots_needed: _duo_solved_b = true
	if _duo_solved_a and _duo_solved_b:
		_finish_game(true, "Both codes cracked!")
	elif _active_row_index >= MAX_GUESSES:
		_finish_game(false, "Out of guesses")
	current_guess.clear()
	return
```

Add `var _duo_history_b: Array = []` to state variables.

- [ ] **Step 4: Add Duo to Mode Select grid.**

- [ ] **Step 5: Run a Duo game. Verify two boards appear side by side, both get feedback per guess, and the game ends only when both are solved or guesses run out.**

- [ ] **Step 6: Commit**
```bash
git add scripts/Main.gd
git commit -m "feat: Duo mode - two simultaneous boards, shared palette, independent feedback"
```

---

### Task 10: Sudden Death Mode

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add `_start_sudden_death_game()` method**

```gdscript
func _start_sudden_death_game() -> void:
	current_mode = GameMode.SUDDEN_DEATH
	slots_needed  = rng.randi_range(3, 5)
	MAX_GUESSES   = 10
	secret_sequence = _generate_secret(slots_needed, 5)
	guess_history.clear()
	current_guess.clear()
	round_active = true
	_board_built = false
	_board_rows.clear()
	if has_node("GameLayer/GameVBox/BoardVBox"):
		$GameLayer/GameVBox/BoardVBox.queue_free()
	await get_tree().process_frame
	_build_wordle_board()
	_build_elimination_tracker()
	_show_game_screen()
```

- [ ] **Step 2: In `_on_submit_pressed()`, add Sudden Death instant-loss check after evaluation**

```gdscript
if current_mode == GameMode.SUDDEN_DEATH:
	var feedback := _evaluate_guess(current_guess, secret_sequence)
	if feedback.exact == 0:
		# Zero exact = instant death
		_finish_game(false, "Zero exact — eliminated!")
		return
```

- [ ] **Step 3: Add Sudden Death to Mode Select, locked behind Level 10**

```gdscript
{"mode": GameMode.SUDDEN_DEATH, "name": "Sudden Death",
 "desc": "0 exact = instant loss · Level 10+",
 "locked": SaveData.level < 10, "unlock_text": "Unlock at Level 10"},
```

In `_open_mode_select()`, gray out locked modes and disable their cards.

- [ ] **Step 4: Run a Sudden Death game. Submit a guess with 0 exact hits. Verify immediate loss.**

- [ ] **Step 5: Commit**
```bash
git add scripts/Main.gd
git commit -m "feat: Sudden Death mode - instant loss on zero exact, locked until Level 10"
```

---

### Task 11: Sandbox Mode

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add `_start_sandbox_game()` method**

```gdscript
var _sandbox_setting_phase: bool = false

func _start_sandbox_game() -> void:
	current_mode = GameMode.SANDBOX
	slots_needed  = 4
	MAX_GUESSES   = 999
	secret_sequence = []
	_sandbox_setting_phase = true
	guess_history.clear()
	current_guess.clear()
	round_active = false
	_board_built = false
	_board_rows.clear()
	if has_node("GameLayer/GameVBox/BoardVBox"):
		$GameLayer/GameVBox/BoardVBox.queue_free()
	await get_tree().process_frame
	_build_wordle_board()
	_show_game_screen()
	# Show "Set your secret" instruction
	status_label.text = "Set your secret sequence below"
	submit_button.text = "Start Game"
	_sandbox_creator_sequence = []
	_build_sandbox_creator()

var _sandbox_creator_sequence: Array[int] = []

func _build_sandbox_creator() -> void:
	# Repurpose the active row slots for secret selection
	var row := _board_rows[0]
	for s in range(slots_needed):
		var slot := row.slots[s] as Control
		slot.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed:
				if selected_color_index >= 0:
					if _sandbox_creator_sequence.size() <= s:
						_sandbox_creator_sequence.resize(s + 1)
					_sandbox_creator_sequence[s] = selected_color_index
					_set_slot_filled(slot, PALETTE[selected_color_index].color)
		)

func _on_sandbox_submit_pressed() -> void:
	if _sandbox_setting_phase:
		if _sandbox_creator_sequence.size() < slots_needed or _sandbox_creator_sequence.has(-1):
			_show_toast("Fill all slots to set your secret")
			return
		secret_sequence = _sandbox_creator_sequence.duplicate()
		_sandbox_setting_phase = false
		round_active = true
		submit_button.text = "SUBMIT"
		status_label.text = "Now guess your own sequence!"
		_refresh_board_states()
		return
	# Normal submit
	_on_submit_pressed()
```

- [ ] **Step 2: In Sandbox mode, hints are always free (no ad, no token) and a Reveal button is always visible.**

```gdscript
# In _grant_hint():
if current_mode == GameMode.SANDBOX:
	# Always free
	_grant_hint()
	return
```

Add a "Reveal" button in the game screen that only shows in Sandbox mode:
```gdscript
if current_mode == GameMode.SANDBOX:
	var reveal_btn := Button.new()
	reveal_btn.text = "Reveal"
	reveal_btn.pressed.connect(func():
		status_label.text = "Secret: " + " ".join(secret_sequence.map(func(ci): return PALETTE[ci].name))
	)
	$GameLayer/GameVBox.add_child(reveal_btn)
```

- [ ] **Step 3: In `_finish_game()`, skip XP/coins/streak updates for Sandbox mode.**

```gdscript
if current_mode == GameMode.SANDBOX:
	_show_result_sheet(did_win, guess_history.size())
	return  # No XP/coins/stats
```

- [ ] **Step 4: Add Sandbox to Mode Select grid.**

- [ ] **Step 5: Run Sandbox. Set a secret. Play against it. Verify no XP earned, Reveal always works, hints are free.**

- [ ] **Step 6: Commit**
```bash
git add scripts/Main.gd
git commit -m "feat: Sandbox mode - player sets own secret, free hints, Reveal button, no XP"
```

---

### Task 12: Weekly Challenge

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add `_start_weekly_challenge()` method**

```gdscript
func _start_weekly_challenge() -> void:
	var week_num: int = Time.get_datetime_dict_from_system().get("week", 1)
	if SaveData.weekly_last_week == week_num:
		_show_toast("Already completed this week's challenge!")
		return
	current_mode = GameMode.CLASSIC  # uses Classic rules
	slots_needed  = 5
	MAX_GUESSES   = 8
	# Seed from week number for consistent puzzle across all players
	rng.seed = week_num * 1337 + 42
	secret_sequence = _generate_secret(5, 6)
	rng.randomize()  # restore random state
	guess_history.clear()
	current_guess.clear()
	round_active = true
	_board_built = false
	_board_rows.clear()
	if has_node("GameLayer/GameVBox/BoardVBox"):
		$GameLayer/GameVBox/BoardVBox.queue_free()
	await get_tree().process_frame
	_build_wordle_board()
	_build_elimination_tracker()
	_show_game_screen()
	_weekly_week_num = week_num

var _weekly_week_num: int = 0
```

- [ ] **Step 2: In `_finish_game()`, award Weekly Challenge reward**

```gdscript
if _weekly_week_num > 0 and current_mode == GameMode.CLASSIC:
	# Was a weekly challenge (detect by _weekly_week_num > 0)
	if did_win:
		SaveData.weekly_last_week = _weekly_week_num
		SaveData.add_xp(200)
		SaveData.add_coins(50)
		_show_toast("Weekly Challenge complete! +200 XP +50 coins")
	_weekly_week_num = 0
```

- [ ] **Step 3: Add Weekly Challenge card to Mode Select with countdown to reset**

```gdscript
var week_num: int = Time.get_datetime_dict_from_system().get("week", 1)
var weekly_done: bool = SaveData.weekly_last_week == week_num
var weekly_card := PanelContainer.new()
_style_panel_glass(weekly_card)
var wlbl := Label.new()
wlbl.text = "Weekly #%d%s" % [week_num, " ✓" if weekly_done else ""]
weekly_card.add_child(wlbl)
if not weekly_done:
	weekly_card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			_close_bottom_sheet(...)
			_start_weekly_challenge()
	)
```

- [ ] **Step 4: Run the game. Start Weekly Challenge. Verify the puzzle is consistent (same sequence each run in the same week). Win and verify 200 XP + 50 coins awarded.**

- [ ] **Step 5: Commit**
```bash
git add scripts/Main.gd
git commit -m "feat: Weekly Challenge - seeded from ISO week, 5 slots 8 guesses, 200 XP reward"
```

---

### Task 13: Retention Mechanics

**Files:**
- Modify: `scripts/Main.gd`
- Modify: `scripts/SaveData.gd`

- [ ] **Step 1: Auto-Save / Resume — save game state after every submit**

In `_on_submit_pressed()`, at the very end (after all processing):
```gdscript
# Auto-save resume state
if round_active and current_mode not in [GameMode.SANDBOX, GameMode.TIME_TRIAL, GameMode.DUO]:
	SaveData.resume_mode    = current_mode
	SaveData.resume_secret  = secret_sequence.duplicate()
	SaveData.resume_history = guess_history.duplicate(true)
	SaveData.resume_campaign_level = _current_campaign_level
	SaveData.save()
```

Clear resume state in `_finish_game()`:
```gdscript
SaveData.resume_mode   = -1
SaveData.resume_secret = []
SaveData.resume_history = []
SaveData.save()
```

- [ ] **Step 2: Show Resume prompt on launch if `SaveData.resume_secret` is non-empty**

In `_ready()`, after `_show_menu()`:
```gdscript
if not SaveData.resume_secret.is_empty():
	_show_resume_prompt()

func _show_resume_prompt() -> void:
	var sheet := _build_bottom_sheet("Resume Game?")
	var vbox := sheet.get_node("Content") as VBoxContainer
	var mode_name := GameMode.keys()[SaveData.resume_mode] if SaveData.resume_mode >= 0 else "Unknown"
	var info_lbl := Label.new()
	info_lbl.text = "%s — %d guesses in" % [mode_name.capitalize(), SaveData.resume_history.size()]
	vbox.add_child(info_lbl)
	var resume_btn := Button.new()
	resume_btn.text = "Resume"
	resume_btn.pressed.connect(func():
		_close_bottom_sheet(sheet.get_parent().get_child(sheet.get_index() - 1), sheet)
		_resume_game()
	)
	var new_btn := Button.new()
	new_btn.text = "New Game"
	new_btn.pressed.connect(func():
		SaveData.resume_secret = []
		SaveData.save()
		_close_bottom_sheet(sheet.get_parent().get_child(sheet.get_index() - 1), sheet)
	)
	vbox.add_child(resume_btn)
	vbox.add_child(new_btn)

func _resume_game() -> void:
	current_mode    = SaveData.resume_mode as GameMode
	secret_sequence = SaveData.resume_secret.duplicate()
	guess_history   = SaveData.resume_history.duplicate(true)
	slots_needed    = secret_sequence.size()
	_active_row_index = guess_history.size()
	MAX_GUESSES     = MAX_GUESSES_CLASSIC  # restore per mode if needed
	_current_campaign_level = SaveData.resume_campaign_level
	round_active = true
	_board_built = false
	_board_rows.clear()
	if has_node("GameLayer/GameVBox/BoardVBox"):
		$GameLayer/GameVBox/BoardVBox.queue_free()
	await get_tree().process_frame
	_build_wordle_board()
	_show_game_screen()
```

- [ ] **Step 3: Comeback Mechanic**

In `_finish_game()`, track and apply comeback:
```gdscript
var ineligible_modes := [GameMode.DAILY, GameMode.CAMPAIGN, GameMode.TIME_TRIAL, GameMode.SUDDEN_DEATH]
if not ineligible_modes.has(current_mode):
	if did_win:
		SaveData.consecutive_losses = 0
		_comeback_active = false
	else:
		SaveData.consecutive_losses += 1
		if SaveData.consecutive_losses >= 3:
			_comeback_active = true
	SaveData.save()
```

In `start_new_game()`, apply comeback difficulty reduction:
```gdscript
if _comeback_active:
	slots_needed = max(3, slots_needed - 1)
	# Note: never shown to player
```

- [ ] **Step 4: First Win of Day Bonus**

In `_finish_game()`, after XP calculation:
```gdscript
var today := Time.get_date_string_from_system()
if did_win and SaveData.last_first_win_date != today:
	SaveData.last_first_win_date = today
	xp_earned *= 2
	SaveData.add_coins(15)
	SaveData.save()
	_show_toast("First win bonus! ×2 XP ☀️")
```

- [ ] **Step 5: Streak Freeze — auto-consume in `SaveData._check_login_streak()`**

In `SaveData._check_login_streak()`, before resetting streak:
```gdscript
# Before: elif last_login_date == yesterday → streak += 1
# Check if missed by exactly 1 day AND streak_freezes > 0
var two_days_ago := _date_offset(-2)
if last_login_date == two_days_ago and login_streak >= 2 and streak_freezes > 0:
	streak_freezes -= 1
	# Don't increment streak, just preserve it
	login_streak += 0  # no change
	last_login_date = today
	save()
	login_streak_updated.emit(login_streak, 0)
	return
```

- [ ] **Step 6: Personal Records — update on game end**

In `_finish_game()`:
```gdscript
if did_win:
	var mode_key := GameMode.keys()[current_mode]
	var pb: Dictionary = SaveData.personal_bests.get(mode_key, {})
	var new_min_guesses: int = guess_history.size()
	var new_min_time: int = _game_elapsed_ms()
	var is_new_pb := false
	if new_min_guesses < pb.get("min_guesses", 9999):
		pb["min_guesses"] = new_min_guesses
		is_new_pb = true
	if new_min_time < pb.get("min_time_ms", 9999999):
		pb["min_time_ms"] = new_min_time
		is_new_pb = true
	if is_new_pb:
		SaveData.personal_bests[mode_key] = pb
		SaveData.save()
		# Show PB badge on result sheet (set a flag read by _show_result_sheet)
		_is_new_pb = true
```

Add `var _is_new_pb: bool = false` to state.

- [ ] **Step 7: Add game timer — track elapsed time per game**

```gdscript
var _game_start_ms: int = 0

func _start_timer() -> void:
	_game_start_ms = Time.get_ticks_msec()

func _game_elapsed_ms() -> int:
	return Time.get_ticks_msec() - _game_start_ms
```

Call `_start_timer()` in `start_new_game()`.

- [ ] **Step 8: Run the game. Lose 3 times in Classic. Verify the next game starts with 1 fewer slot (comeback). Win on the first attempt of the day and verify the ×2 XP toast.**

- [ ] **Step 9: Commit**
```bash
git add scripts/Main.gd scripts/SaveData.gd
git commit -m "feat: retention mechanics - auto-save/resume, comeback, first win bonus, streak freeze, personal bests"
```

---

### Task 14: Reaction Messages

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add reaction message pools and `_get_reaction_message()` method**

```gdscript
const REACTION_MESSAGES: Dictionary = {
	"cold_start": ["Cold start — keep going", "No hits yet, adjust your approach"],
	"cold_late":  ["Still searching… think differently", "Zero exact — time to rethink"],
	"one_exact":  ["One locked in!", "Warm — 1 confirmed"],
	"one_away":   ["So close — one slot away!", "One more to crack it!"],
	"last_chance":["Last chance!", "Final attempt — make it count"],
}
var _used_reactions: Array[String] = []

func _get_reaction_message(exact: int, guesses_remaining: int) -> String:
	var pool_key := ""
	if exact == 0 and guess_history.size() == 1:
		pool_key = "cold_start"
	elif exact == 0 and guess_history.size() >= 4:
		pool_key = "cold_late"
	elif exact == 1:
		pool_key = "one_exact"
	elif exact == slots_needed - 1:
		pool_key = "one_away"
	elif guesses_remaining == 1:
		pool_key = "last_chance"
	if pool_key.is_empty():
		return ""
	var pool: Array = REACTION_MESSAGES[pool_key]
	# Pick one not used recently
	var candidates := pool.filter(func(m): return not _used_reactions.has(m))
	if candidates.is_empty():
		candidates = pool
		_used_reactions.clear()
	var msg: String = candidates[rng.randi() % candidates.size()]
	_used_reactions.append(msg)
	if _used_reactions.size() > 4:
		_used_reactions.pop_front()
	return msg
```

- [ ] **Step 2: In `_on_submit_pressed()`, after evaluating and before next round, set status_label**

```gdscript
var feedback := guess_history.back().feedback
var remaining := MAX_GUESSES - guess_history.size()
var reaction := _get_reaction_message(feedback.exact, remaining)
if not reaction.is_empty():
	status_label.text = reaction
```

- [ ] **Step 3: Run the game. Submit guesses with 0 exact on first guess → "Cold start" message. Have 1 exact → "One locked in!" message.**

- [ ] **Step 4: Commit**
```bash
git add scripts/Main.gd
git commit -m "feat: reaction messages in header - tiered pool based on guess quality and remaining guesses"
```

---

### Task 15: Dot Trail Animation

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add dot trail state and methods**

```gdscript
var _trail_line: Line2D = null
var _trail_color: Color = Color.WHITE
var _trail_dragging: bool = false

func _start_trail(color: Color) -> void:
	if _trail_line != null and is_instance_valid(_trail_line):
		_trail_line.queue_free()
	_trail_line = Line2D.new()
	_trail_line.width = 4.0
	_trail_line.default_color = color
	_trail_line.z_index = 100
	add_child(_trail_line)
	_trail_color = color
	_trail_dragging = true

func _update_trail(pos: Vector2) -> void:
	if _trail_line == null or not is_instance_valid(_trail_line):
		return
	_trail_line.add_point(pos)
	if _trail_line.get_point_count() > 20:
		_trail_line.remove_point(0)

func _end_trail() -> void:
	_trail_dragging = false
	if _trail_line == null or not is_instance_valid(_trail_line):
		return
	var tw := create_tween()
	tw.tween_property(_trail_line, "modulate:a", 0.0, 0.2)
	tw.tween_callback(_trail_line.queue_free)
	_trail_line = null
```

- [ ] **Step 2: Connect drag events in `ColorDotButton.gd`**

Add a signal:
```gdscript
signal drag_started(color: Color, global_pos: Vector2)
signal drag_moved(global_pos: Vector2)
signal drag_ended
```

In `ColorDotButton._gui_input()`:
```gdscript
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			drag_started.emit(_dot_color, event.global_position)
		else:
			drag_ended.emit()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		drag_moved.emit(event.global_position)
```

- [ ] **Step 3: In `_build_palette()` in Main.gd, connect drag signals**

```gdscript
btn.drag_started.connect(func(color, pos): _start_trail(color))
btn.drag_moved.connect(func(pos): _update_trail(pos))
btn.drag_ended.connect(func(): _end_trail())
```

- [ ] **Step 4: Run the game. Drag from a palette dot. Verify a colored line follows the touch/mouse and fades after release.**

- [ ] **Step 5: Commit**
```bash
git add scripts/Main.gd scripts/ColorDotButton.gd
git commit -m "feat: dot trail animation - Line2D follows drag from palette dot, fades on release"
```

---

### Task 16: Stats Deep Dive

**Files:**
- Modify: `scripts/Main.gd`

- [ ] **Step 1: Add Stats Deep Dive section to the stats screen**

In `_build_stats_screen()` or `_open_stats_sheet()`, add an expandable Deep Dive section:
```gdscript
func _build_deep_dive_section(container: VBoxContainer) -> void:
	var deep_dive_header := Button.new()
	deep_dive_header.text = "Deep Dive ▼"
	deep_dive_header.pressed.connect(func():
		deep_dive_content.visible = not deep_dive_content.visible
	)
	container.add_child(deep_dive_header)

	var deep_dive_content := VBoxContainer.new()
	deep_dive_content.visible = false
	container.add_child(deep_dive_content)

	# Total time played
	var total_ms: int = 0
	for entry in SaveData.puzzle_history:
		total_ms += entry.get("time_ms", 0)
	var time_lbl := Label.new()
	var total_sec := total_ms / 1000
	time_lbl.text = "Total time played: %dm %ds" % [total_sec / 60, total_sec % 60]
	deep_dive_content.add_child(time_lbl)

	# Average guesses per mode
	var mode_stats: Dictionary = {}
	for entry in SaveData.puzzle_history:
		if entry.get("won", false):
			var m: String = entry.get("mode", "CLASSIC")
			if not mode_stats.has(m):
				mode_stats[m] = {"total": 0, "count": 0, "best": 9999}
			mode_stats[m].total += entry.get("guesses", 0)
			mode_stats[m].count += 1
			mode_stats[m].best   = mini(mode_stats[m].best, entry.get("guesses", 9999))
	for mode_key in mode_stats:
		var stats: Dictionary = mode_stats[mode_key]
		var avg: float = float(stats.total) / float(stats.count) if stats.count > 0 else 0
		var avg_lbl := Label.new()
		avg_lbl.text = "%s: avg %.1f guesses, best %d" % [mode_key.capitalize(), avg, stats.best]
		deep_dive_content.add_child(avg_lbl)

	# Best day of week
	var day_wins: Array = [0, 0, 0, 0, 0, 0, 0]  # Mon–Sun
	for entry in SaveData.puzzle_history:
		if entry.get("won", false) and entry.has("date"):
			var dt := Time.get_datetime_dict_from_datetime_string(entry.date + "T00:00:00", false)
			var dow: int = dt.get("weekday", 0)
			day_wins[dow % 7] += 1
	var best_day_idx := day_wins.find(day_wins.max())
	const DAY_NAMES := ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
	var day_lbl := Label.new()
	day_lbl.text = "Best day: %s (%d wins)" % [DAY_NAMES[best_day_idx], day_wins[best_day_idx]]
	deep_dive_content.add_child(day_lbl)
```

- [ ] **Step 2: Add Puzzle Archive button to stats screen**

```gdscript
var archive_btn := Button.new()
archive_btn.text = "Archive"
archive_btn.pressed.connect(_open_archive_screen)
container.add_child(archive_btn)

func _open_archive_screen() -> void:
	var sheet := _build_bottom_sheet("Puzzle Archive")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox := VBoxContainer.new()
	scroll.add_child(vbox)
	sheet.get_node("Content").add_child(scroll)

	# Group by date
	var by_date: Dictionary = {}
	for entry in SaveData.puzzle_history:
		var d: String = entry.get("date", "Unknown")
		if not by_date.has(d): by_date[d] = []
		by_date[d].append(entry)

	var sorted_dates := by_date.keys()
	sorted_dates.sort()
	sorted_dates.reverse()
	for date in sorted_dates:
		var date_lbl := Label.new()
		date_lbl.text = date
		date_lbl.add_theme_color_override("font_color", Color("#6B4E71"))
		vbox.add_child(date_lbl)
		for entry in by_date[date]:
			var entry_lbl := Label.new()
			var mode_str: String = entry.get("mode", "?")
			var guesses: int = entry.get("guesses", 0)
			var won: bool = entry.get("won", false)
			entry_lbl.text = "  %s %s · %d guesses" % [mode_str, "✓" if won else "✗", guesses]
			entry_lbl.add_theme_color_override("font_color", Color("#9B7BAB"))
			vbox.add_child(entry_lbl)
```

- [ ] **Step 3: Run the game. Play 5+ games. Open Stats → Deep Dive. Verify time played, avg guesses per mode, best day of week are shown. Open Archive and verify puzzle history list.**

- [ ] **Step 4: Commit**
```bash
git add scripts/Main.gd
git commit -m "feat: Stats Deep Dive - total time, avg guesses per mode, best day; puzzle archive"
```

---

## Self-Review Checklist

- [x] **SaveData fields**: All 25+ new fields across tokens/season/retention/resume/history/shop sections
- [x] **ShopManager**: Full 20-item catalog, purchase validation, XP deduction, token consumption API
- [x] **SeasonManager**: Remote config fetch, fallback, season reset, milestone claiming, 6 seasons defined
- [x] **ComboManager**: Consecutive-win tracking, 4-tier multiplier (1.0×/1.5×/2.0×/2.5×), flame UI
- [x] **Ad rework**: Interstitials loss-only, loss counter persisted, native ad stub
- [x] **Rewards screen**: Shop + Season tabs, XP balance header, claim flow
- [x] **Mystery mode**: 1 slot shown, 1 revealed per guess, 12 max guesses
- [x] **Time Trial**: 5 puzzles, cumulative timer, score = puzzles×1000 - seconds
- [x] **Duo mode**: Two boards, one shared palette, independent feedback per board
- [x] **Sudden Death**: 0 exact = instant loss, locked at Level 10
- [x] **Sandbox**: Player sets secret, free hints, Reveal button, no XP
- [x] **Weekly Challenge**: ISO week seed, 200 XP reward, once per week
- [x] **Auto-save/resume**: Save after every submit, resume prompt on launch
- [x] **Comeback**: 3 losses → difficulty reduced silently
- [x] **First win bonus**: ×2 XP + 15 coins, once per calendar day
- [x] **Streak Freeze**: Auto-consumes when daily missed and freeze held
- [x] **Personal bests**: Per mode, PB badge on result sheet
- [x] **Reaction messages**: Tiered pool, no repeats in session
- [x] **Dot trail**: Line2D follows palette drag, fades on release
- [x] **Stats Deep Dive**: Total time, avg guesses per mode, best day, puzzle archive

**Percentile comparison (spec Section 6.1)** uses deterministic simulation — implement in `_show_result_sheet()` for Daily mode. Seed from today's date hash, simulate normal distribution (mean=5, σ=1.5), compute where player's guess count falls:

```gdscript
func _compute_daily_percentile(player_guesses: int) -> int:
	var seed_val := Time.get_date_string_from_system().hash()
	var rng_sim := RandomNumberGenerator.new()
	rng_sim.seed = seed_val
	var sim_count := 1000
	var worse := 0
	for _i in range(sim_count):
		# Box-Muller normal distribution approximation
		var u1 := rng_sim.randf()
		var u2 := rng_sim.randf()
		var z := sqrt(-2.0 * log(max(u1, 0.0001))) * cos(TAU * u2)
		var sim_guesses := int(round(5.0 + 1.5 * z))
		if sim_guesses > player_guesses:
			worse += 1
	return int((float(worse) / sim_count) * 100)
```
