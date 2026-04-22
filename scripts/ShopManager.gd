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

func _apply_purchase(item_id: String, _item: Dictionary) -> void:
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
