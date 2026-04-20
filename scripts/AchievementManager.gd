extends Node
## AchievementManager — tracks achievements and fires unlock notifications
## Autoloaded. Listens to SaveData.achievement_unlocked signal and shows
## a slide-in popup at the top of the screen.

# ── Achievement definitions ──────────────────────────────────────────────────
const ACHIEVEMENTS: Dictionary = {
	"first_win":       {"name": "FIRST DECODE",       "desc": "Win your first game",                  "coins": 50},
	"win_10":          {"name": "PATTERN HUNTER",      "desc": "Win 10 games",                         "coins": 100},
	"win_50":          {"name": "GRID MASTER",         "desc": "Win 50 games",                         "coins": 200},
	"win_100":         {"name": "NEURAL ARCHITECT",    "desc": "Win 100 games",                        "coins": 500},
	"perfect_once":    {"name": "SURGICAL PRECISION",  "desc": "Win in 3 guesses or fewer",            "coins": 150},
	"perfect_5":       {"name": "SYSTEM CRACKER",      "desc": "Win in ≤3 guesses 5 times",            "coins": 300},
	"daily_7":         {"name": "WEEK DECODED",        "desc": "Complete 7 daily challenges",          "coins": 200},
	"streak_7":        {"name": "STREAK PROTOCOL",     "desc": "Daily challenge streak of 7",          "coins": 300},
	"streak_30":       {"name": "IRON GRID",           "desc": "Daily challenge streak of 30",         "coins": 1000},
	"no_hints_10":     {"name": "PURE SIGNAL",         "desc": "Win 10 games without hints",           "coins": 150},
	"played_100":      {"name": "VETERAN DECODER",     "desc": "Play 100 games",                       "coins": 200},
	"login_7":         {"name": "DAILY OPERATIVE",     "desc": "Log in 7 days in a row",              "coins": 150},
	"login_30":        {"name": "GRID ADDICT",         "desc": "Log in 30 days in a row",             "coins": 500},
	"win_blitz":       {"name": "SPEED RUNNER",        "desc": "Win a game in Blitz Mode",            "coins": 100},
	"blitz_30s":       {"name": "LIGHTNING CRACK",     "desc": "Win a Blitz game in under 30 seconds","coins": 300},
	"share_result":    {"name": "BROADCAST SIGNAL",    "desc": "Share a result",                       "coins": 50},
	"ad_watcher":      {"name": "SYSTEM SUPPORTER",    "desc": "Watch 10 rewarded ads",               "coins": 100},
	"all_achievements":{"name": "OMEGA PROTOCOL",      "desc": "Unlock all other achievements",        "coins": 0},
}

# Neon theme colors (duplicated here to avoid circular dependency with Main.gd)
const C_PANEL  := Color(0.039, 0.059, 0.118, 0.97)
const C_BORDER := Color(1.00, 0.84, 0.00, 0.55)   # gold border for achievement
const C_GOLD   := Color(1.00, 0.84, 0.00, 1.0)
const C_MUTED  := Color(0.53, 0.60, 0.73, 1.0)

var _popup_queue: Array[String] = []
var _showing_popup: bool = false

# =============================================================================
func _ready() -> void:
	SaveData.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_achievement_unlocked(achievement_id: String) -> void:
	# Award coins defined in ACHIEVEMENTS table
	var def: Dictionary = ACHIEVEMENTS.get(achievement_id, {})
	if def.is_empty():
		return
	var reward_coins: int = def.get("coins", 0)
	if reward_coins > 0:
		SaveData.add_coins(reward_coins)

	# Check for "all achievements" meta-achievement
	_check_all_achievements()

	_popup_queue.append(achievement_id)
	if not _showing_popup:
		_show_next_popup()

func _check_all_achievements() -> void:
	for key in ACHIEVEMENTS.keys():
		if key == "all_achievements":
			continue
		if not SaveData.has_achievement(key):
			return
	SaveData.unlock_achievement("all_achievements")

# =============================================================================
# Popup
# =============================================================================
func _show_next_popup() -> void:
	if _popup_queue.is_empty():
		_showing_popup = false
		return
	_showing_popup = true
	var achievement_id := _popup_queue.pop_front() as String
	var def: Dictionary = ACHIEVEMENTS.get(achievement_id, {})
	if def.is_empty():
		_show_next_popup()
		return

	# Find the topmost viewport root to attach the popup to
	var root := get_tree().root.get_child(get_tree().root.get_child_count() - 1)

	var panel := PanelContainer.new()
	panel.layout_mode = 0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = C_PANEL
	panel_style.corner_radius_top_left     = 16
	panel_style.corner_radius_top_right    = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.corner_radius_bottom_left  = 16
	panel_style.border_width_left   = 1
	panel_style.border_width_top    = 1
	panel_style.border_width_right  = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = C_BORDER
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.custom_minimum_size = Vector2(460, 0)
	panel.z_index = 100

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   22)
	margin.add_theme_constant_override("margin_right",  22)
	margin.add_theme_constant_override("margin_top",    14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	margin.add_child(hbox)

	# Trophy icon
	var icon_lbl := Label.new()
	icon_lbl.text = "🏆"
	icon_lbl.add_theme_font_size_override("font_size", 36)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_lbl)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_col)

	var tag_lbl := Label.new()
	tag_lbl.text = "ACHIEVEMENT UNLOCKED"
	tag_lbl.add_theme_color_override("font_color", C_GOLD)
	tag_lbl.add_theme_font_size_override("font_size", 18)
	text_col.add_child(tag_lbl)

	var name_lbl := Label.new()
	name_lbl.text = str(def.get("name", achievement_id))
	name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	name_lbl.add_theme_font_size_override("font_size", 26)
	text_col.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = str(def.get("desc", ""))
	desc_lbl.add_theme_color_override("font_color", C_MUTED)
	desc_lbl.add_theme_font_size_override("font_size", 20)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_col.add_child(desc_lbl)

	root.add_child(panel)
	await root.get_tree().process_frame

	# Centre horizontally near top
	var vp_w := root.get_viewport().get_visible_rect().size.x
	panel.position = Vector2((vp_w - panel.size.x) * 0.5, -panel.size.y - 10.0)

	var tw := panel.create_tween()
	tw.tween_property(panel, "position:y", 55.0, 0.35)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(2.80)
	tw.tween_property(panel, "position:y", -panel.size.y - 10.0, 0.28)\
		.set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		panel.queue_free()
		_show_next_popup()
	)
