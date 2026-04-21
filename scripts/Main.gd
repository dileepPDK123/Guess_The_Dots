extends Control
## Main.gd — core game controller for Guess the Dots (NEURAL GRID build)
##
## Game modes:
##   CLASSIC  — 3-5 slots, 5 colors, 10 guesses, random every game
##   DAILY    — 4 slots, 5 colors, 8 guesses, date-seeded (once per day)
##   BLITZ    — 5 slots, 5 colors, unlimited guesses, 90-second timer
##   HARD     — 5-6 slots, 6 colors, 10 guesses; previous "exact" slots are locked
##   ZEN      — 4 slots, 5 colors, unlimited guesses, no timer, relaxed

enum GameMode { CLASSIC, BLITZ, HARD, ZEN, CAMPAIGN, EASY, MYSTERY, TIME_TRIAL }

class _BlitzRingControl extends Control:
	var progress: float = 1.0
	var seconds_left: int = 90
	var is_critical: bool = false

	func _draw() -> void:
		var center := size / 2.0
		var radius := min(size.x, size.y) / 2.0 - 4.0
		# Background track
		draw_arc(center, radius, 0.0, TAU, 64, Color(0.8, 0.8, 0.8, 0.3), 5.0, true)
		# Progress arc (clockwise from top)
		var arc_color := Color("#EF4444") if is_critical else Color("#F472B6")
		if progress > 0.0:
			draw_arc(center, radius, -PI / 2.0, -PI / 2.0 + TAU * progress, 64, arc_color, 5.0, true)
		# Center text
		var font := ThemeDB.fallback_font
		if font != null:
			draw_string(font, center - Vector2(12, -6), str(seconds_left),
				HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color("#6B4E71"))

	func update_progress(time_remaining: float, total_time: float) -> void:
		progress = clampf(time_remaining / total_time, 0.0, 1.0)
		seconds_left = int(ceil(time_remaining))
		is_critical = time_remaining <= 15.0
		queue_redraw()

const MAX_GUESSES_CLASSIC  := 10
const MAX_GUESSES_BLITZ    := 999   # effectively unlimited — timer is the constraint
const MAX_GUESSES_HARD     := 10
const MAX_GUESSES_ZEN      := 999
const BLITZ_TIME          := 90.0  # seconds
const SETTINGS_PATH       := "user://settings.cfg"

# Active per-game values (set by start_new_game based on mode)
var MAX_GUESSES: int = 10

# ── Pastel theme ─────────────────────────────────────────────────────────────
const C_BG_TOP         := Color("#FFF1F9")
const C_BG_MID         := Color("#FFF8F0")
const C_BG_BOT         := Color("#F0FFF8")
const C_PANEL          := Color(1.0, 1.0, 1.0, 0.75)
const C_PANEL_BORDER   := Color("#FFD6E7")
const C_CTA_FROM       := Color("#F472B6")
const C_CTA_TO         := Color("#A78BFA")
const C_TEXT_PRIMARY   := Color("#6B4E71")
const C_TEXT_SECONDARY := Color("#C084B8")
const C_TEXT_ACTION    := Color("#9B7BAB")
const C_PIP_EXACT      := Color("#22C55E")
const C_PIP_MISPLACE   := Color("#FACC15")
const C_PIP_EMPTY      := Color(0.784, 0.706, 0.863, 0.25)
const C_ACTIVE_ROW     := Color(0.957, 0.447, 0.714, 0.07)
const C_ACTIVE_BORDER  := Color(0.957, 0.447, 0.714, 0.4)

const PALETTE := [
	{"name": "Red",    "color": Color("#ef4444")},
	{"name": "Blue",   "color": Color("#3b82f6")},
	{"name": "Green",  "color": Color("#22c55e")},
	{"name": "Yellow", "color": Color("#facc15")},
	{"name": "Purple", "color": Color("#a855f7")},
	{"name": "Orange", "color": Color("#f97316")},  # Hard mode / Campaign — 6th color
]

const COLORBLIND_SHAPES: Array[String] = ["●", "■", "▲", "◆", "★", "✕"]
# Index matches PALETTE: Red=0, Blue=1, Green=2, Yellow=3, Purple=4, Orange=5

const CUSTOM_PUZZLE_PREFIX := "GTD-"
const _CODE_CHARS          := "ABCDEF"  # A=0, B=1, C=2, D=3, E=4, F=5

# ── Scene references ─────────────────────────────────────────────────────────
@onready var menu_layer: CenterContainer      = $MenuLayer
@onready var new_game_button: Button          = $MenuLayer/MenuPanel/MenuMargin/MenuVBox/NewGameButton
@onready var how_to_play_menu_button: Button  = $MenuLayer/MenuPanel/MenuMargin/MenuVBox/HowToPlayButton
@onready var quit_button: Button              = $MenuLayer/MenuPanel/MenuMargin/MenuVBox/QuitButton

@onready var game_layer: MarginContainer      = $GameLayer
@onready var round_info_label: Label          = $GameLayer/GameVBox/HeaderPanel/HeaderMargin/HeaderVBox/RoundInfoLabel
@onready var guess_counter_label: Label       = $GameLayer/GameVBox/HeaderPanel/HeaderMargin/HeaderVBox/GuessCounterLabel
@onready var status_label: Label              = $GameLayer/GameVBox/HeaderPanel/HeaderMargin/HeaderVBox/StatusLabel
@onready var slots_container: HBoxContainer   = $GameLayer/GameVBox/GuessPanel/GuessMargin/GuessVBox/GuessRow/SlotsContainer
@onready var submit_button: Button            = $GameLayer/GameVBox/GuessPanel/GuessMargin/GuessVBox/GuessRow/SubmitButton
@onready var clear_button: Button             = $GameLayer/GameVBox/GuessPanel/GuessMargin/GuessVBox/ActionsRow/ClearButton
@onready var undo_button: Button              = $GameLayer/GameVBox/GuessPanel/GuessMargin/GuessVBox/ActionsRow/UndoButton
@onready var hint_button: Button              = $GameLayer/GameVBox/GuessPanel/GuessMargin/GuessVBox/HintButton
@onready var palette_container: HBoxContainer = $GameLayer/GameVBox/PalettePanel/PaletteMargin/PaletteVBox/PaletteContainer
@onready var selection_label: Label           = $GameLayer/GameVBox/PalettePanel/PaletteMargin/PaletteVBox/SelectionLabel
@onready var history_scroll: ScrollContainer  = $GameLayer/GameVBox/HistoryPanel/HistoryMargin/HistoryVBox/HistoryScroll
@onready var history_container: VBoxContainer = $GameLayer/GameVBox/HistoryPanel/HistoryMargin/HistoryVBox/HistoryScroll/HistoryContainer

# Header labels
@onready var header_title_label: Label = $GameLayer/GameVBox/HeaderPanel/HeaderMargin/HeaderVBox/HeaderTitleLabel

@onready var result_layer: Control                    = $ResultLayer
@onready var result_title_label: Label                = $ResultLayer/Overlay/PopupCenter/PopupPanel/PopupMargin/PopupVBox/ResultTitleLabel
@onready var result_message_label: Label              = $ResultLayer/Overlay/PopupCenter/PopupPanel/PopupMargin/PopupVBox/ResultMessageLabel
@onready var result_dots_container: HBoxContainer     = $ResultLayer/Overlay/PopupCenter/PopupPanel/PopupMargin/PopupVBox/ResultDotsContainer
@onready var result_play_again_button: Button         = $ResultLayer/Overlay/PopupCenter/PopupPanel/PopupMargin/PopupVBox/ResultButtons/ResultPlayAgainButton
@onready var result_menu_button: Button               = $ResultLayer/Overlay/PopupCenter/PopupPanel/PopupMargin/PopupVBox/ResultButtons/ResultMenuButton

# ── Hamburger menu ────────────────────────────────────────────────────────────
@onready var hamburger_button: Button      = $GameHamburgerButton
@onready var hamburger_menu_layer: Control = $HamburgerMenuLayer
@onready var hamburger_overlay: ColorRect  = $HamburgerMenuLayer/HamburgerOverlay
@onready var new_round_menu_button: Button = $HamburgerMenuLayer/HamburgerOverlay/MenuCenter/MenuPopupPanel/MenuPopupMargin/MenuPopupVBox/NewRoundMenuButton
@onready var main_menu_menu_button: Button = $HamburgerMenuLayer/HamburgerOverlay/MenuCenter/MenuPopupPanel/MenuPopupMargin/MenuPopupVBox/MainMenuMenuButton
@onready var how_to_play_button: Button    = $HamburgerMenuLayer/HamburgerOverlay/MenuCenter/MenuPopupPanel/MenuPopupMargin/MenuPopupVBox/HowToPlayMenuButton
@onready var haptics_toggle: CheckButton   = $HamburgerMenuLayer/HamburgerOverlay/MenuCenter/MenuPopupPanel/MenuPopupMargin/MenuPopupVBox/HapticsRow/HapticsToggle
@onready var close_menu_button: Button     = $HamburgerMenuLayer/HamburgerOverlay/MenuCenter/MenuPopupPanel/MenuPopupMargin/MenuPopupVBox/CloseMenuButton

# ── Tutorial ──────────────────────────────────────────────────────────────────
@onready var tutorial_layer: Control = $TutorialLayer

# ── State ─────────────────────────────────────────────────────────────────────
var rng := RandomNumberGenerator.new()
var secret_sequence: Array[int] = []
var current_guess: Array[int]   = []
var guess_history: Array[Dictionary] = []
var slot_buttons: Array  = []
var palette_buttons: Array = []
var selected_color_index: int = -1
var slots_needed: int = 0
var round_active: bool = false
var _second_chance_used: bool = false
var _xp_doubler_active: bool = false
var _last_game_won: bool = false
var current_mode: GameMode = GameMode.CLASSIC
var _blitz_time_remaining: float = BLITZ_TIME
var _blitz_timer_active: bool = false
var _hard_locked_slots: Array[int] = []  # slot indices locked from previous exact hits
var _mystery_true_slots: int = 0
var _current_campaign_level: int = 1
var _campaign_won: bool = false
var _hint_ad_pending: bool = false
var _combo_label: Label = null
var _time_trial_puzzles_completed: int = 0
var _time_trial_total_time_ms: int = 0
var _time_trial_puzzle_times: Array[int] = []
var _time_trial_start_ms: int = 0
const TIME_TRIAL_TOTAL_PUZZLES := 5

# ── Overlay layers (built procedurally) ──────────────────────────────────────
var _mode_select_layer: Control
var _stats_layer: Control
var _campaign_layer: Control

# ── Settings ──────────────────────────────────────────────────────────────────
var haptics_enabled: bool = true
var _cfg := ConfigFile.new()

# ── Wordle board ──────────────────────────────────────────────────────────────
var _board_rows: Array = []           # Array of {container, slots, pips, index}
var _active_row_index: int = 0
var _board_built: bool = false

# ── Elimination tracker ───────────────────────────────────────────────────────
var _tracker_container: HBoxContainer
var _tracker_dot_nodes: Array = []
var _tracker_absent: Dictionary = {}   # color_index → true (confirmed absent via Smart Hint)
var _tracker_present: Dictionary = {}  # color_index → true (confirmed present via exact match)

# ── Blitz ring ────────────────────────────────────────────────────────────
var _blitz_ring_node: Control

# =============================================================================
func _process(delta: float) -> void:
	if not _blitz_timer_active or not round_active:
		return
	_blitz_time_remaining -= delta
	_blitz_time_remaining = maxf(_blitz_time_remaining, 0.0)
	if _blitz_ring_node != null and is_instance_valid(_blitz_ring_node):
		(_blitz_ring_node as _BlitzRingControl).update_progress(_blitz_time_remaining, BLITZ_TIME)
	if _blitz_time_remaining <= 0.0:
		_blitz_timer_active = false
		_finish_game(false, "Time's up!")

# =============================================================================
func _ready() -> void:
	rng.randomize()
	_load_settings()
	_apply_theme()
	_apply_label_vocabulary()

	# Menu
	new_game_button.pressed.connect(_on_new_game_pressed)
	how_to_play_menu_button.pressed.connect(func() -> void: tutorial_layer.start())
	quit_button.pressed.connect(func() -> void: get_tree().quit())

	# In-game
	submit_button.pressed.connect(_on_submit_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	undo_button.pressed.connect(_on_undo_pressed)
	hint_button.pressed.connect(_on_hint_pressed)

	# Result popup
	result_play_again_button.pressed.connect(_on_play_again_pressed)
	result_menu_button.pressed.connect(_on_result_menu_pressed)

	# Hamburger
	hamburger_button.text = "⋯"
	hamburger_button.pressed.connect(_open_settings_sheet)
	new_round_menu_button.pressed.connect(_on_new_round_from_menu)
	main_menu_menu_button.pressed.connect(_on_main_menu_from_menu)
	how_to_play_button.pressed.connect(_on_how_to_play_from_menu)
	close_menu_button.pressed.connect(_close_hamburger_menu)
	hamburger_overlay.gui_input.connect(_on_overlay_input)

	# Tutorial
	tutorial_layer.tutorial_finished.connect(_on_tutorial_finished)

	_build_palette()
	_build_mode_select()

	# STATISTICS button — injected into menu VBox after BRIEFING
	var stats_btn := Button.new()
	stats_btn.text = "STATISTICS"
	stats_btn.custom_minimum_size = Vector2(0, 74)
	stats_btn.pressed.connect(_open_stats_screen)
	var menu_vbox := get_node("MenuLayer/MenuPanel/MenuMargin/MenuVBox")
	menu_vbox.add_child(stats_btn)
	menu_vbox.move_child(stats_btn, how_to_play_menu_button.get_index() + 1)

	var rewards_btn := Button.new()
	rewards_btn.text = "REWARDS"
	rewards_btn.custom_minimum_size = Vector2(0, 74)
	rewards_btn.add_theme_font_size_override("font_size", 26)
	rewards_btn.pressed.connect(_open_rewards_screen)
	menu_vbox.add_child(rewards_btn)
	menu_vbox.move_child(rewards_btn, stats_btn.get_index() + 1)

	_show_menu()
	tutorial_layer.start()

	# Connect login streak reward signal — fires if today is a new day
	SaveData.login_streak_updated.connect(_on_login_streak_updated)
	ComboManager.combo_changed.connect(_on_combo_changed)

# =============================================================================
# Settings
# =============================================================================
func _load_settings() -> void:
	if _cfg.load(SETTINGS_PATH) == OK:
		haptics_enabled = _cfg.get_value("settings", "haptics", true)

func _save_settings() -> void:
	_cfg.set_value("settings", "haptics", haptics_enabled)
	_cfg.save(SETTINGS_PATH)

# =============================================================================
# Haptics
# =============================================================================
func _vibrate(ms: int = 25) -> void:
	if haptics_enabled:
		Input.vibrate_handheld(ms)

func _vibrate_win() -> void:
	if not haptics_enabled:
		return
	Input.vibrate_handheld(40)
	await get_tree().create_timer(0.14).timeout
	Input.vibrate_handheld(70)

func _vibrate_lose() -> void:
	if haptics_enabled:
		Input.vibrate_handheld(180)

# =============================================================================
# Pastel theme
# =============================================================================
func _apply_theme() -> void:
	# Background: pastel gradient via a full-screen ColorRect
	if not has_node("BgRect"):
		var bg := ColorRect.new()
		bg.name = "BgRect"
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# Use top color as solid fill; true gradient requires GradientTexture2D
		bg.color = C_BG_TOP
		add_child(bg)
		move_child(bg, 0)
	else:
		($BgRect as ColorRect).color = C_BG_TOP

	# Style submit button as CTA (pink gradient approximated with solid fill)
	var cta_style := StyleBoxFlat.new()
	cta_style.bg_color = C_CTA_FROM
	cta_style.corner_radius_top_left    = 14
	cta_style.corner_radius_top_right   = 14
	cta_style.corner_radius_bottom_left  = 14
	cta_style.corner_radius_bottom_right = 14
	cta_style.shadow_color = Color(0.957, 0.447, 0.714, 0.35)
	cta_style.shadow_size  = 14
	submit_button.add_theme_stylebox_override("normal", cta_style)
	submit_button.add_theme_color_override("font_color", Color.WHITE)

	# Secondary button style for clear/undo/hint
	var sec_style := StyleBoxFlat.new()
	sec_style.bg_color = Color(1.0, 1.0, 1.0, 0.75)
	sec_style.border_color = Color(0.980, 0.659, 0.831, 0.3)
	sec_style.border_width_left   = 1
	sec_style.border_width_right  = 1
	sec_style.border_width_top    = 1
	sec_style.border_width_bottom = 1
	sec_style.corner_radius_top_left    = 10
	sec_style.corner_radius_top_right   = 10
	sec_style.corner_radius_bottom_left  = 10
	sec_style.corner_radius_bottom_right = 10
	for btn in [clear_button, undo_button, hint_button]:
		btn.add_theme_stylebox_override("normal", sec_style.duplicate())
		btn.add_theme_color_override("font_color", C_TEXT_ACTION)

	# Text colors
	for lbl in [round_info_label, guess_counter_label, header_title_label]:
		lbl.add_theme_color_override("font_color", C_TEXT_PRIMARY)
	status_label.add_theme_color_override("font_color", C_TEXT_SECONDARY)

func _style_panel_glass(panel: PanelContainer) -> void:
	if panel == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_PANEL
	sb.border_color = C_PANEL_BORDER
	sb.border_width_left   = 1
	sb.border_width_right  = 1
	sb.border_width_top    = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left    = 16
	sb.corner_radius_top_right   = 16
	sb.corner_radius_bottom_left  = 16
	sb.corner_radius_bottom_right = 16
	sb.shadow_color = Color(0.655, 0.447, 0.714, 0.10)
	sb.shadow_size  = 16
	panel.add_theme_stylebox_override("panel", sb)

# =============================================================================
# Vocabulary — rename static labels to NEURAL GRID copy
# =============================================================================
func _apply_label_vocabulary() -> void:
	submit_button.text = "SUBMIT"
	clear_button.text  = "CLEAR"
	undo_button.text   = "UNDO"
	hint_button.text   = "HINT"
	new_game_button.text         = "PLAY"
	how_to_play_menu_button.text = "HOW TO PLAY"
	header_title_label.text      = "Guess the Dots"

func _find_label(node_path: String) -> Label:
	return get_node(node_path) as Label

# =============================================================================
# Navigation
# =============================================================================
func _show_menu() -> void:
	menu_layer.visible        = true
	game_layer.visible        = false
	result_layer.visible      = false
	hamburger_button.visible  = false
	hamburger_menu_layer.visible = false
	round_active = false
	AdManager.show_banner()

func start_new_game(mode: GameMode = GameMode.CLASSIC, campaign_level: int = 1) -> void:
	current_mode              = mode
	_current_campaign_level   = campaign_level
	_campaign_won             = false
	menu_layer.visible        = false
	game_layer.visible        = true
	result_layer.visible      = false
	_result_sheet_open        = false
	hamburger_button.visible  = true
	hamburger_menu_layer.visible = false
	AdManager.hide_banner()
	round_active              = true
	_second_chance_used       = false
	_xp_doubler_active        = false
	_blitz_timer_active       = false
	_blitz_time_remaining     = BLITZ_TIME
	_hard_locked_slots.clear()
	_hint_ad_pending          = false
	selected_color_index      = -1
	guess_history.clear()
	secret_sequence.clear()
	ComboManager.start_round()

	# Rebuild palette for the mode (Hard adds 6th color)
	_build_palette(6 if mode == GameMode.HARD else 5)

	# Configure per-mode rules
	match mode:
		GameMode.CLASSIC:
			MAX_GUESSES  = MAX_GUESSES_CLASSIC
			# Warm-up: first ever game uses 3 slots
			slots_needed = 3 if SaveData.games_played == 0 else rng.randi_range(3, 5)
			_populate_sequence(5)
		GameMode.BLITZ:
			MAX_GUESSES  = MAX_GUESSES_BLITZ
			slots_needed = 5
			_populate_sequence(5)
			_blitz_timer_active = true
			_build_blitz_ring()
		GameMode.HARD:
			MAX_GUESSES  = MAX_GUESSES_HARD
			slots_needed = rng.randi_range(5, 6)
			_populate_sequence(6)
		GameMode.ZEN:
			MAX_GUESSES  = MAX_GUESSES_ZEN
			slots_needed = 4
			_populate_sequence(5)
		GameMode.EASY:
			MAX_GUESSES  = 10
			slots_needed = rng.randi_range(3, 4)
			_populate_sequence(5)
		GameMode.CAMPAIGN:
			var cfg := _get_campaign_config(_current_campaign_level)
			MAX_GUESSES  = cfg["guesses"]
			slots_needed = cfg["slots"]
			_build_palette(cfg["colors"])  # override the pre-match palette call
			secret_sequence.assign(_campaign_sequence(_current_campaign_level, cfg["slots"], cfg["colors"]))
		GameMode.MYSTERY:
			_start_mystery_game()
			return
		GameMode.TIME_TRIAL:
			_start_time_trial()
			return

	_tracker_absent.clear()
	_tracker_present.clear()
	_build_elimination_tracker()

	current_guess.clear()
	current_guess.resize(slots_needed)
	for i in range(slots_needed):
		current_guess[i] = -1
	_board_built = false
	_board_rows.clear()
	_active_row_index = 0
	_build_wordle_board()
	_update_palette_selection()
	_refresh_guess_ui()
	_update_header_text("TAP A COLOR TO FILL THE NEXT SLOT, OR DRAG IT IN.")

	# Hide blitz ring for non-blitz modes
	if mode != GameMode.BLITZ:
		if _blitz_ring_node != null and is_instance_valid(_blitz_ring_node):
			_blitz_ring_node.queue_free()
			_blitz_ring_node = null

func _populate_sequence(color_count: int) -> void:
	for _i in range(slots_needed):
		secret_sequence.append(rng.randi_range(0, color_count - 1))

func _start_mystery_game() -> void:
	current_mode = GameMode.MYSTERY
	var true_slots := rng.randi_range(3, 5)
	_mystery_true_slots = true_slots
	slots_needed  = 1  # Start showing only 1 slot
	MAX_GUESSES   = 12
	secret_sequence.clear()
	for _i in range(true_slots):
		secret_sequence.append(rng.randi_range(0, 4))
	guess_history.clear()
	current_guess.clear()
	current_guess.resize(slots_needed)
	current_guess[0] = -1
	_hard_locked_slots.clear()
	_tracker_absent.clear()
	_tracker_present.clear()
	round_active = true
	_second_chance_used = false
	_xp_doubler_active = false
	_blitz_timer_active = false
	_blitz_time_remaining = BLITZ_TIME
	_hint_ad_pending = false
	selected_color_index = -1
	_board_built = false
	_board_rows.clear()
	_active_row_index = 0
	menu_layer.visible = false
	game_layer.visible = true
	result_layer.visible = false
	_result_sheet_open = false
	hamburger_button.visible = true
	hamburger_menu_layer.visible = false
	AdManager.hide_banner()
	_build_palette(5)
	ComboManager.start_round()
	if has_node("GameLayer/GameVBox/BoardVBox"):
		$GameLayer/GameVBox/BoardVBox.queue_free()
	await get_tree().process_frame
	_build_elimination_tracker()
	_build_wordle_board()
	_update_palette_selection()
	_refresh_guess_ui()
	_update_header_text("TAP A COLOR TO FILL THE NEXT SLOT, OR DRAG IT IN.")

func _start_time_trial() -> void:
	current_mode = GameMode.TIME_TRIAL
	_time_trial_puzzles_completed = 0
	_time_trial_total_time_ms     = 0
	_time_trial_puzzle_times.clear()
	_time_trial_start_ms = Time.get_ticks_msec()
	await _start_next_time_trial_puzzle()

func _start_next_time_trial_puzzle() -> void:
	slots_needed = rng.randi_range(3, 4)
	MAX_GUESSES  = 10
	secret_sequence = _generate_secret(slots_needed, 5)
	guess_history.clear()
	current_guess.clear()
	_hard_locked_slots.clear()
	round_active = true
	_board_built = false
	_board_rows.clear()
	if has_node("GameLayer/GameVBox/BoardVBox"):
		$GameLayer/GameVBox/BoardVBox.queue_free()
	await get_tree().process_frame
	_build_wordle_board()
	_build_elimination_tracker()
	_show_game_screen()

func _expand_mystery_board() -> void:
	# Resize current_guess to match new slots_needed
	current_guess.resize(slots_needed)
	current_guess[slots_needed - 1] = -1
	_board_rows.clear()
	await get_tree().process_frame
	_build_wordle_board()
	_update_palette_selection()
	_refresh_guess_ui()

func _return_to_menu() -> void:
	_show_menu()

func _on_play_again_pressed() -> void:
	if current_mode == GameMode.CAMPAIGN:
		if _campaign_won and _current_campaign_level < 100:
			start_new_game(GameMode.CAMPAIGN, _current_campaign_level + 1)
		else:
			start_new_game(GameMode.CAMPAIGN, _current_campaign_level)
	else:
		start_new_game(current_mode)

func _on_result_menu_pressed() -> void:
	if current_mode == GameMode.CAMPAIGN:
		_return_to_menu()
		_open_campaign_screen()
	else:
		_return_to_menu()

# =============================================================================
# Hamburger menu
# =============================================================================
func _close_hamburger_menu() -> void:
	hamburger_menu_layer.visible = false

func _open_settings_sheet() -> void:
	hamburger_menu_layer.visible = false
	var sheet := _build_bottom_sheet("Settings")
	var vbox := sheet.get_node("Content") as VBoxContainer

	var items := [
		{"label": "New Round",   "action": func() -> void: _on_new_round_from_menu()},
		{"label": "Main Menu",   "action": func() -> void: _on_main_menu_from_menu()},
		{"label": "How to Play", "action": func() -> void: tutorial_layer.start()},
	]
	for item in items:
		var btn := Button.new()
		btn.text = item["label"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 52)
		btn.pressed.connect(item["action"])
		vbox.add_child(btn)

	# Color-Blind toggle
	var cb_row := HBoxContainer.new()
	var cb_lbl := Label.new()
	cb_lbl.text = "Color-Blind Mode"
	cb_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cb_toggle := CheckButton.new()
	cb_toggle.button_pressed = SaveData.colorblind_enabled
	cb_toggle.toggled.connect(func(on: bool) -> void: _toggle_colorblind(on))
	cb_row.add_child(cb_lbl)
	cb_row.add_child(cb_toggle)
	vbox.add_child(cb_row)

	# Haptics toggle
	var hap_row := HBoxContainer.new()
	var hap_lbl := Label.new()
	hap_lbl.text = "Haptics"
	hap_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hap_toggle := CheckButton.new()
	hap_toggle.button_pressed = haptics_enabled
	hap_toggle.toggled.connect(func(on: bool) -> void: _on_haptics_toggled(on))
	hap_row.add_child(hap_lbl)
	hap_row.add_child(hap_toggle)
	vbox.add_child(hap_row)

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_close_hamburger_menu()

func _on_new_round_from_menu() -> void:
	_close_hamburger_menu()
	_open_mode_select()

func _on_main_menu_from_menu() -> void:
	_close_hamburger_menu()
	_return_to_menu()

func _on_how_to_play_from_menu() -> void:
	_close_hamburger_menu()
	tutorial_layer.start()

func _on_tutorial_finished() -> void:
	_cfg.set_value("settings", "tutorial_seen", true)
	_save_settings()

func _on_haptics_toggled(pressed: bool) -> void:
	haptics_enabled = pressed
	haptics_toggle.text = "ON" if pressed else "OFF"
	_save_settings()
	if pressed:
		_vibrate(30)

# =============================================================================
# Build UI
# =============================================================================
func _build_palette(count: int = 5) -> void:
	for child in palette_container.get_children():
		child.queue_free()
	palette_buttons.clear()
	for index in range(count):
		var dot := ColorDotButton.new()
		dot.color_index = index
		dot.color_name  = str(PALETTE[index]["name"])
		dot.dot_color   = PALETTE[index]["color"]
		dot.pressed.connect(_on_palette_dot_pressed.bind(index))
		dot.apply_colorblind(
			SaveData.colorblind_enabled,
			COLORBLIND_SHAPES[index] if index < COLORBLIND_SHAPES.size() else ""
		)
		palette_container.add_child(dot)
		palette_buttons.append(dot)

func _toggle_colorblind(enabled: bool) -> void:
	SaveData.colorblind_enabled = enabled
	SaveData.save()
	for i in range(palette_buttons.size()):
		if i < COLORBLIND_SHAPES.size():
			(palette_buttons[i] as ColorDotButton).apply_colorblind(enabled, COLORBLIND_SHAPES[i])
	_refresh_board_states()

func _encode_custom_puzzle(sequence: Array[int]) -> String:
	var code := CUSTOM_PUZZLE_PREFIX
	for ci in sequence:
		if ci >= 0 and ci < _CODE_CHARS.length():
			code += _CODE_CHARS[ci]
	return code

func _decode_custom_puzzle(code: String) -> Array[int]:
	if not code.begins_with(CUSTOM_PUZZLE_PREFIX):
		return []
	var body := code.substr(CUSTOM_PUZZLE_PREFIX.length())
	if body.length() < 3 or body.length() > 6:
		return []
	var result: Array[int] = []
	for ch in body:
		var idx := _CODE_CHARS.find(ch.to_upper())
		if idx == -1:
			return []
		result.append(idx)
	return result

func _build_blitz_ring() -> void:
	if _blitz_ring_node != null and is_instance_valid(_blitz_ring_node):
		_blitz_ring_node.queue_free()
	_blitz_ring_node = _BlitzRingControl.new()
	_blitz_ring_node.name = "BlitzRing"
	_blitz_ring_node.custom_minimum_size = Vector2(64, 64)
	var header := $GameLayer/GameVBox/HeaderPanel as Control
	header.add_child(_blitz_ring_node)

func _build_elimination_tracker() -> void:
	if _tracker_container != null and is_instance_valid(_tracker_container):
		_tracker_container.name = "_TrackerOld"
		_tracker_container.queue_free()

	_tracker_dot_nodes.clear()
	_tracker_container = HBoxContainer.new()
	_tracker_container.name = "EliminationTracker"
	_tracker_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_tracker_container.add_theme_constant_override("separation", 10)

	var num_colors := 6 if current_mode == GameMode.HARD else 5
	for i in range(num_colors):
		var dot_wrap := Control.new()
		dot_wrap.custom_minimum_size = Vector2(28, 28)

		# Circle panel
		var panel := PanelContainer.new()
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var sb := StyleBoxFlat.new()
		sb.bg_color = PALETTE[i]["color"]
		sb.corner_radius_top_left     = 999
		sb.corner_radius_top_right    = 999
		sb.corner_radius_bottom_left  = 999
		sb.corner_radius_bottom_right = 999
		panel.add_theme_stylebox_override("panel", sb)
		dot_wrap.add_child(panel)

		var badge := Label.new()
		badge.name = "Badge"
		badge.text = ""
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		badge.add_theme_font_size_override("font_size", 14)
		badge.visible = false
		dot_wrap.add_child(badge)

		_tracker_container.add_child(dot_wrap)
		_tracker_dot_nodes.append(dot_wrap)

	# Insert tracker between board and palette
	var game_vbox := $GameLayer/GameVBox as VBoxContainer
	# Find palette panel index (palette_container's ancestor inside GameVBox)
	var target_idx := -1
	for idx in range(game_vbox.get_child_count()):
		var child := game_vbox.get_child(idx)
		if child == palette_container or child.is_ancestor_of(palette_container):
			target_idx = idx
			break
	game_vbox.add_child(_tracker_container)
	if target_idx >= 0:
		game_vbox.move_child(_tracker_container, target_idx)

func _update_elimination_tracker() -> void:
	if _tracker_dot_nodes.is_empty():
		return
	for i in range(_tracker_dot_nodes.size()):
		var wrap: Control = _tracker_dot_nodes[i]
		if not is_instance_valid(wrap):
			continue
		var badge: Label = wrap.get_node_or_null("Badge")
		if badge == null:
			continue
		if _tracker_absent.has(i):
			wrap.modulate = Color(0.6, 0.6, 0.6, 0.8)
			badge.text = "✕"
			badge.add_theme_color_override("font_color", Color.WHITE)
			badge.visible = true
		elif _tracker_present.has(i):
			wrap.modulate = Color(1, 1, 1, 1)
			badge.text = "✓"
			badge.add_theme_color_override("font_color", Color.WHITE)
			badge.visible = true
		else:
			wrap.modulate = Color(1, 1, 1, 1)
			badge.visible = false

func _mark_tracker_absent(color_index: int) -> void:
	_tracker_absent[color_index] = true
	_update_elimination_tracker()

func _mark_tracker_present(color_index: int) -> void:
	_tracker_present[color_index] = true
	_update_elimination_tracker()

func _build_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	slot_buttons.clear()
	for index in range(slots_needed):
		var slot := SlotButton.new()
		slot.slot_index = index
		slot.color_dropped.connect(_on_slot_color_dropped)
		slot.slot_pressed_for_assign.connect(_on_slot_pressed_for_assign)
		slots_container.add_child(slot)
		slot_buttons.append(slot)

func _build_wordle_board() -> void:
	# Hide old panels (keep @onready refs valid — do NOT queue_free)
	if has_node("GameLayer/GameVBox/HistoryPanel"):
		$GameLayer/GameVBox/HistoryPanel.hide()

	# Remove previously built board if any (queue_free defers — rename to avoid collision)
	if has_node("GameLayer/GameVBox/BoardVBox"):
		var old_board := $GameLayer/GameVBox/BoardVBox
		old_board.name = "_BoardVBoxOld"
		old_board.queue_free()

	var total_rows := MAX_GUESSES if current_mode != GameMode.ZEN else 10
	var board_vbox := VBoxContainer.new()
	board_vbox.name = "BoardVBox"
	board_vbox.add_theme_constant_override("separation", 6)

	var game_vbox := $GameLayer/GameVBox as VBoxContainer
	game_vbox.add_child(board_vbox)
	game_vbox.move_child(board_vbox, 1)  # after header (index 0)

	_board_rows.clear()
	for i in range(total_rows):
		var row_data := _build_board_row(i)
		board_vbox.add_child(row_data.container)
		_board_rows.append(row_data)

	_active_row_index = guess_history.size()
	_connect_active_row_signals()
	_refresh_board_states()
	_board_built = true

func _build_board_row(row_index: int) -> Dictionary:
	var hbox := HBoxContainer.new()
	hbox.name = "BoardRow%d" % row_index
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var slots: Array = []
	for s in range(slots_needed):
		var slot := SlotButton.new()
		slot.slot_index = s
		slot.custom_minimum_size = Vector2(56, 56)
		hbox.add_child(slot)
		slots.append(slot)

	# Pip container (feedback dots, right side)
	var pip_hbox := HBoxContainer.new()
	pip_hbox.add_theme_constant_override("separation", 3)
	for _p in range(slots_needed):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(10, 10)
		pip.color = C_PIP_EMPTY
		pip_hbox.add_child(pip)
	hbox.add_child(pip_hbox)

	return {"container": hbox, "slots": slots, "pips": pip_hbox, "index": row_index}

func _connect_active_row_signals() -> void:
	if _active_row_index >= _board_rows.size():
		return
	var active_slots: Array = _board_rows[_active_row_index].slots
	# Reassign slot_buttons so all existing handlers (_refresh_guess_ui etc.) work
	slot_buttons = active_slots
	for s in range(active_slots.size()):
		var slot: SlotButton = active_slots[s]
		slot.slot_index = s
		# Disconnect existing connections first to avoid duplicates
		if slot.color_dropped.is_connected(_on_slot_color_dropped):
			slot.color_dropped.disconnect(_on_slot_color_dropped)
		if slot.slot_pressed_for_assign.is_connected(_on_slot_pressed_for_assign):
			slot.slot_pressed_for_assign.disconnect(_on_slot_pressed_for_assign)
		slot.color_dropped.connect(_on_slot_color_dropped)
		slot.slot_pressed_for_assign.connect(_on_slot_pressed_for_assign)

func _refresh_board_states() -> void:
	for i in range(_board_rows.size()):
		var row: Dictionary = _board_rows[i]
		if i < _active_row_index:
			_apply_past_row(row, guess_history[i])
		elif i == _active_row_index:
			_apply_active_row(row)
		else:
			_apply_future_row(row)

func _apply_past_row(row: Dictionary, item: Dictionary) -> void:
	# item format: {"values": Array[int], "exact": int, "misplaced": int, "per_dot": Array}
	var guess: Array = item["values"]
	var exact: int = int(item["exact"])
	var misplaced: int = int(item["misplaced"])
	var slots: Array = row.slots
	for s in range(slots.size()):
		var ci := int(guess[s])
		if ci < 0 or ci >= PALETTE.size():
			ci = 0  # fallback to first color if index is out of range
		var color := PALETTE[ci]["color"] as Color
		(slots[s] as SlotButton).set_filled_visual(color, "")
		(slots[s] as Control).modulate.a = 1.0
	_update_pips(row.pips, exact, misplaced)

	# Per-dot rings for Easy mode
	if current_mode == GameMode.EASY and item.has("per_dot"):
		var per_dot: Array = item["per_dot"]
		for s in range(slots.size()):
			if s < per_dot.size():
				_apply_dot_ring(slots[s] as Control, per_dot[s])

func _apply_dot_ring(slot: Control, state: String) -> void:
	var ring_color: Color
	match state:
		"exact":     ring_color = C_PIP_EXACT
		"misplaced": ring_color = C_PIP_MISPLACE
		_:           return  # no ring for absent
	var existing := slot.get_theme_stylebox("normal")
	if existing == null:
		return
	var sb := existing.duplicate() as StyleBoxFlat
	if sb == null:
		return
	sb.border_color = ring_color
	sb.border_width_left   = 3
	sb.border_width_right  = 3
	sb.border_width_top    = 3
	sb.border_width_bottom = 3
	slot.add_theme_stylebox_override("normal", sb)

func _apply_active_row(row: Dictionary) -> void:
	var slots: Array = row.slots
	for s in range(slots.size()):
		(slots[s] as Control).modulate.a = 1.0
		if current_mode == GameMode.HARD and _hard_locked_slots.has(s):
			# Pre-fill with confirmed color (from secret_sequence)
			var locked_color := PALETTE[secret_sequence[s]]["color"] as Color
			(slots[s] as SlotButton).set_filled_visual(locked_color, "")
			(slots[s] as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif s < current_guess.size() and current_guess[s] != -1:
			var color := PALETTE[current_guess[s]]["color"] as Color
			(slots[s] as SlotButton).set_filled_visual(color, "")
			(slots[s] as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		else:
			(slots[s] as SlotButton).set_empty_visual()
			(slots[s] as Control).mouse_filter = Control.MOUSE_FILTER_PASS

func _apply_future_row(row: Dictionary) -> void:
	for slot in row.slots:
		(slot as SlotButton).set_empty_visual()
		(slot as Control).modulate.a = 0.2

func _add_lock_badge(row_index: int, slot_index: int) -> void:
	if row_index >= _board_rows.size():
		return
	var slots: Array = _board_rows[row_index].slots
	if slot_index >= slots.size():
		return
	var slot := slots[slot_index] as Control
	# Don't add duplicate badges
	if slot.has_node("LockBadge"):
		return
	var badge := Label.new()
	badge.name = "LockBadge"
	badge.text = "🔒"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
	badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge.add_theme_font_size_override("font_size", 10)
	badge.modulate.a = 0.0
	slot.add_child(badge)
	var tw := create_tween()
	tw.tween_property(badge, "modulate:a", 1.0, 0.2)

func _update_pips(pip_container: HBoxContainer, exact: int, misplaced: int) -> void:
	var pips := pip_container.get_children()
	var idx := 0
	for _e in range(exact):
		if idx < pips.size():
			(pips[idx] as ColorRect).color = C_PIP_EXACT
			idx += 1
	for _m in range(misplaced):
		if idx < pips.size():
			(pips[idx] as ColorRect).color = C_PIP_MISPLACE
			idx += 1
	while idx < pips.size():
		(pips[idx] as ColorRect).color = C_PIP_EMPTY
		idx += 1

func _flip_row_reveal(row: Dictionary, item: Dictionary) -> void:
	var slots: Array = row.slots
	var guess: Array = item["values"]
	var exact: int = int(item["exact"])
	var misplaced: int = int(item["misplaced"])
	var stagger_sec := 0.08

	for s in range(slots.size()):
		var slot := slots[s] as Control
		var ci := int(guess[s])
		if ci < 0 or ci >= PALETTE.size():
			ci = 0
		var dot_color := PALETTE[ci]["color"] as Color

		# Phase 1: rotate 0 → 90 degrees
		var tw1 := create_tween()
		tw1.tween_property(slot, "rotation_degrees", 90.0, 0.1).set_trans(Tween.TRANS_SINE)
		await tw1.finished
		if not is_instance_valid(slot):
			return
		_set_slot_filled(slot, dot_color)

		# Phase 2: rotate 90 → 0 degrees
		var tw2 := create_tween()
		tw2.tween_property(slot, "rotation_degrees", 0.0, 0.1).set_trans(Tween.TRANS_SINE)
		await tw2.finished
		if not is_instance_valid(slot):
			return

		if s < slots.size() - 1:
			await get_tree().create_timer(stagger_sec).timeout
			if not is_inside_tree():
				return

	# Update pips after all flips
	_update_pips(row.pips, exact, misplaced)

# =============================================================================
# UI refresh
# =============================================================================
func _refresh_guess_ui() -> void:
	for index in range(slot_buttons.size()):
		var slot: SlotButton = slot_buttons[index]
		var ci := current_guess[index]
		if ci == -1:
			slot.set_empty_visual()
		else:
			var cd: Dictionary = PALETTE[ci]
			slot.set_filled_visual(cd["color"], str(cd["name"]))
	submit_button.disabled = not _is_guess_complete() or not round_active
	undo_button.disabled   = _filled_slot_count() == 0 or not round_active
	clear_button.disabled  = _filled_slot_count() == 0 or not round_active
	hint_button.disabled   = not round_active or not AdManager.is_rewarded_ready()

func _update_header_text(message: String) -> void:
	if current_mode == GameMode.CAMPAIGN:
		round_info_label.text = "LEVEL %d  ·  %d NODES  ·  REPEATS ON" % [_current_campaign_level, slots_needed]
	else:
		round_info_label.text = "SEQUENCE LENGTH: %d  ·  REPEATS ON" % slots_needed
	guess_counter_label.text = "ATTEMPT %d / %d" % [guess_history.size() + 1, MAX_GUESSES]
	status_label.text        = message

func _update_palette_selection() -> void:
	for index in range(palette_buttons.size()):
		var dot: ColorDotButton = palette_buttons[index]
		dot.set_selected(index == selected_color_index)
	var empty := slots_needed - _filled_slot_count()
	if empty == 0:
		selection_label.text = "SEQUENCE COMPLETE — SUBMIT?"
	else:
		selection_label.text = "%d NODE%s OPEN" % [empty, "" if empty == 1 else "S"]

# =============================================================================
# Input handlers
# =============================================================================
func _on_new_game_pressed() -> void:
	_open_mode_select()

func _on_palette_dot_pressed(index: int) -> void:
	if not round_active:
		return
	for i in range(current_guess.size()):
		if current_guess[i] == -1:
			current_guess[i] = index
			selected_color_index = index
			_update_palette_selection()
			_refresh_guess_ui()
			status_label.text = "PLACED %s INTO SLOT %d." % [str(PALETTE[index]["name"]), i + 1]
			_vibrate(18)
			SoundManager.play("dot_place")
			return
	status_label.text = "SEQUENCE COMPLETE — SUBMIT OR TAP A SLOT TO CLEAR IT."

func _on_slot_color_dropped(slot_index: int, color_index: int) -> void:
	if not round_active:
		return
	current_guess[slot_index] = color_index
	selected_color_index = color_index
	_update_palette_selection()
	_refresh_guess_ui()
	status_label.text = "PLACED %s INTO SLOT %d." % [str(PALETTE[color_index]["name"]), slot_index + 1]
	_vibrate(18)
	SoundManager.play("dot_place")

func _on_slot_pressed_for_assign(slot_index: int) -> void:
	if not round_active:
		return
	# Hard mode: locked slots cannot be cleared
	if current_mode == GameMode.HARD and _hard_locked_slots.has(slot_index):
		status_label.text = "SLOT %d IS LOCKED — EXACT MATCH CONFIRMED." % (slot_index + 1)
		return
	if current_guess[slot_index] != -1:
		var old_name: String = str(PALETTE[current_guess[slot_index]]["name"])
		current_guess[slot_index] = -1
		_refresh_guess_ui()
		_update_palette_selection()
		status_label.text = "CLEARED SLOT %d (%s REMOVED)." % [slot_index + 1, old_name]
		_vibrate(12)
	else:
		status_label.text = "TAP A COLOR TO FILL THIS SLOT."

func _on_clear_pressed() -> void:
	for index in range(current_guess.size()):
		current_guess[index] = -1
	_refresh_guess_ui()
	_update_palette_selection()
	status_label.text = "SEQUENCE CLEARED."
	_vibrate(20)
	SoundManager.play("dot_clear")

func _on_undo_pressed() -> void:
	for index in range(current_guess.size() - 1, -1, -1):
		if current_guess[index] != -1:
			current_guess[index] = -1
			_refresh_guess_ui()
			_update_palette_selection()
			status_label.text = "LAST NODE UNDONE."
			_vibrate(12)
			SoundManager.play("dot_clear")
			return

func _on_hint_pressed() -> void:
	if not round_active or _hint_ad_pending:
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

func _on_hint_rewarded_earned() -> void:
	_hint_ad_pending = false
	if _grant_hint():
		SaveData.hints_used += 1
		SaveData.ads_watched += 1
		SaveData.save()

func _grant_hint() -> bool:
	var absent_colors: Array[int] = []
	for ci in range(PALETTE.size()):
		if not secret_sequence.has(ci) and not _tracker_absent.has(ci):
			absent_colors.append(ci)
	if absent_colors.is_empty():
		return false
	var reveal_idx := absent_colors[rng.randi() % absent_colors.size()]
	_mark_tracker_absent(reveal_idx)
	var color_name: String = str(PALETTE[reveal_idx]["name"])
	status_label.text = "%s is not in the sequence." % color_name
	_vibrate(40)
	SoundManager.play("hint")
	return true

func _on_submit_pressed() -> void:
	if not round_active or not _is_guess_complete():
		return
	var guess_copy: Array[int] = []
	guess_copy.assign(current_guess)
	var result := _evaluate_guess(guess_copy)
	guess_history.append({
		"values":    guess_copy,
		"exact":     int(result["exact"]),
		"misplaced": int(result["misplaced"]),
		"per_dot":   result["per_dot"],
	})
	_vibrate(35)
	SoundManager.play("submit")

	# Mark colors confirmed present via exact-match slots
	var last_vals: Array = guess_history.back()["values"]
	for s in range(last_vals.size()):
		if last_vals[s] == secret_sequence[s]:
			_mark_tracker_present(last_vals[s])

	# Animate the submitted row before advancing state
	var submitted_row_index := _active_row_index
	round_active = false
	await _flip_row_reveal(_board_rows[submitted_row_index], guess_history.back())
	round_active = true

	_active_row_index = guess_history.size()
	if _active_row_index < _board_rows.size():
		_connect_active_row_signals()
	_refresh_board_states()

	# Sound feedback on result
	var ex := int(result["exact"])
	var mis := int(result["misplaced"])
	if ex == slots_needed:
		pass  # win sound plays in _finish_game
	elif ex > 0:
		SoundManager.play("exact")
	elif mis > 0:
		SoundManager.play("misplace")

	if int(result["exact"]) == slots_needed:
		_finish_game(true, "Cracked it! %d guess%s." % [
			guess_history.size(), "" if guess_history.size() == 1 else "es"
		])
		return
	if guess_history.size() >= MAX_GUESSES:
		_finish_game(false, "Better luck next time!")
		return

	# Hard mode: carry forward exact (locked) slot values into the next guess
	if current_mode == GameMode.HARD:
		_hard_locked_slots.clear()
		for index in range(slots_needed):
			if guess_copy[index] == secret_sequence[index]:
				_hard_locked_slots.append(index)
		for index in range(current_guess.size()):
			if _hard_locked_slots.has(index):
				current_guess[index] = guess_copy[index]  # keep correct slot
			else:
				current_guess[index] = -1
		# Hard mode: add lock badges to exact slots in the submitted row
		for s in range(slots_needed):
			if _hard_locked_slots.has(s):
				_add_lock_badge(submitted_row_index, s)
	else:
		for index in range(current_guess.size()):
			current_guess[index] = -1

	# Mystery mode: reveal one more slot per guess
	if current_mode == GameMode.MYSTERY and slots_needed < _mystery_true_slots:
		slots_needed += 1
		_expand_mystery_board()
		return

	_refresh_guess_ui()
	_update_palette_selection()
	_update_header_text("LOCKED: %d  ·  MISALIGNED: %d" % [int(result["exact"]), int(result["misplaced"])])

# =============================================================================
# Core algorithm
# =============================================================================
func _evaluate_guess(guess: Array[int]) -> Dictionary:
	var exact := 0
	var per_dot: Array = []
	var secret_remaining := secret_sequence.duplicate()
	var guess_remaining  := guess.duplicate()

	# First pass: exact matches
	for i in range(guess.size()):
		if guess[i] == secret_sequence[i]:
			exact += 1
			per_dot.append("exact")
			secret_remaining[i] = -1
			guess_remaining[i]  = -1
		else:
			per_dot.append("absent")

	# Second pass: misplaced
	var misplaced := 0
	for i in range(guess.size()):
		if guess_remaining[i] == -1:
			continue
		var found := secret_remaining.find(guess_remaining[i])
		if found != -1:
			misplaced += 1
			per_dot[i] = "misplaced"
			secret_remaining[found] = -1

	return {"exact": exact, "misplaced": misplaced, "per_dot": per_dot}

# =============================================================================
# History
# =============================================================================
func _rebuild_history() -> void:
	for child in history_container.get_children():
		child.queue_free()
	if guess_history.is_empty():
		var lbl := Label.new()
		lbl.text = "NO ATTEMPTS YET. YOUR CHECKED SEQUENCES WILL APPEAR HERE."
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_color_override("font_color", Color(0.53, 0.60, 0.73, 0.55))
		lbl.add_theme_font_size_override("font_size", 20)
		history_container.add_child(lbl)
		return
	for index in range(guess_history.size()):
		var row := _build_history_row(index + 1, guess_history[index])
		history_container.add_child(row)
		# Slide-in animation for the latest row
		if index == guess_history.size() - 1:
			row.modulate.a = 0.0
			row.position.x = -24.0
			var tw := row.create_tween()
			tw.tween_property(row, "modulate:a", 1.0, 0.18)
			tw.parallel().tween_property(row, "position:x", 0.0, 0.18)\
				.set_ease(Tween.EASE_OUT)

func _scroll_history_to_bottom() -> void:
	await get_tree().process_frame
	history_scroll.scroll_vertical = int(history_scroll.get_v_scroll_bar().max_value)

func _build_history_row(guess_number: int, item: Dictionary) -> Control:
	var exact_count := int(item["exact"])
	var mis_count   := int(item["misplaced"])

	# Accent bar color: green if any exact, gold if only misplaced, red if no match
	var accent_color: Color
	if exact_count > 0:
		# TODO: update to pastel
		accent_color = Color.GREEN  # C_SUCCESS
	elif mis_count > 0:
		# TODO: update to pastel
		accent_color = Color.YELLOW  # C_GOLD
	else:
		# TODO: update to pastel
		accent_color = Color.RED  # C_DANGER

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Panel style with left accent bar via content margin
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.032, 0.047, 0.090, 0.90)
	panel_style.corner_radius_top_left     = 12
	panel_style.corner_radius_top_right    = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.corner_radius_bottom_left  = 12
	panel_style.border_color = C_PANEL_BORDER
	panel_style.border_width_left   = 3   # accent bar on left
	panel_style.border_width_top    = 0
	panel_style.border_width_right  = 0
	panel_style.border_width_bottom = 0
	# Override left border color to the accent
	panel_style.border_color = accent_color
	panel.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   14)
	margin.add_theme_constant_override("margin_right",  14)
	margin.add_theme_constant_override("margin_top",    10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	# Guess number: monospaced style
	var count_lbl := Label.new()
	count_lbl.text = "[%02d]" % guess_number
	count_lbl.custom_minimum_size = Vector2(60, 0)
	count_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	# TODO: update to pastel
	#count_lbl.add_theme_color_override("font_color", C_MUTED)
	count_lbl.add_theme_font_size_override("font_size", 20)
	row.add_child(count_lbl)

	# Dot row — shrink-centred so dots never stretch vertically
	var dots_row := HBoxContainer.new()
	dots_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dots_row.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	dots_row.add_theme_constant_override("separation", 8)
	row.add_child(dots_row)
	for value in item["values"]:
		var cd: Dictionary = PALETTE[int(value)]
		dots_row.add_child(_make_dot_preview(cd["color"], str(cd["name"]), 32))

	# Feedback — single inline row so the panel never grows tall
	var feedback_col := HBoxContainer.new()
	feedback_col.alignment = BoxContainer.ALIGNMENT_CENTER
	feedback_col.add_theme_constant_override("separation", 8)
	feedback_col.custom_minimum_size = Vector2(152, 0)
	feedback_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(feedback_col)

	if exact_count == 0 and mis_count == 0:
		var none_lbl := Label.new()
		none_lbl.text = "NULL SIGNAL"
		none_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75, 0.65))
		none_lbl.add_theme_font_size_override("font_size", 20)
		none_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		feedback_col.add_child(none_lbl)
	else:
		if exact_count > 0:
			var el := Label.new()
			el.text = "%d LOCKED" % exact_count
			# TODO: update to pastel
			#el.add_theme_color_override("font_color", C_SUCCESS)
			el.add_theme_font_size_override("font_size", 20)
			el.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			feedback_col.add_child(el)
			for _i in range(exact_count):
				# TODO: update to pastel
				feedback_col.add_child(_make_diamond_pip(Color.GREEN))  # C_SUCCESS
		if exact_count > 0 and mis_count > 0:
			var sep_lbl := Label.new()
			sep_lbl.text = "·"
			# TODO: update to pastel
			#sep_lbl.add_theme_color_override("font_color", C_MUTED)
			sep_lbl.add_theme_font_size_override("font_size", 20)
			sep_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			feedback_col.add_child(sep_lbl)
		if mis_count > 0:
			var ml := Label.new()
			ml.text = "%d SHIFTED" % mis_count
			# TODO: update to pastel
			#ml.add_theme_color_override("font_color", C_GOLD)
			ml.add_theme_font_size_override("font_size", 20)
			ml.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			feedback_col.add_child(ml)
			for _i in range(mis_count):
				# TODO: update to pastel
				feedback_col.add_child(_make_diamond_pip(Color.YELLOW))  # C_GOLD

	return panel

func _base_xp_for_mode() -> int:
	match current_mode:
		GameMode.EASY:     return 20
		GameMode.CLASSIC:  return 30
		GameMode.BLITZ:    return 40
		GameMode.HARD:     return 50
		GameMode.ZEN:      return 20
		GameMode.CAMPAIGN: return 35
		_:                 return 30

# =============================================================================
# Game end
# =============================================================================
var _pending_xp: int     = 0
var _pending_coins: int  = 0
var _pending_levels: int = 0
var _result_sheet_open: bool = false

func _finish_game(did_win: bool, message: String) -> void:
	if _result_sheet_open:
		return  # already showing result — prevent double-call
	round_active        = false
	_blitz_timer_active = false
	_refresh_guess_ui()
	_last_game_won = did_win

	if did_win:
		_vibrate_win()
		SoundManager.play("win")
		_trigger_dot_burst()
	else:
		_vibrate_lose()
		SoundManager.play("lose")

	# ── Time Trial ──────────────────────────────────────────────────────────────
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
			get_tree().create_timer(1.0).timeout.connect(
				func() -> void: _start_next_time_trial_puzzle(), CONNECT_ONE_SHOT)
		return  # Skip normal result sheet

	SaveData.record_game(did_win, guess_history.size())

	# XP / coins calculation — stored as pending so callbacks can reference them
	var multiplier := ComboManager.on_game_finished(did_win, GameMode.keys()[current_mode])
	var xp_earned  := int(_base_xp_for_mode() * multiplier)
	_pending_xp = xp_earned
	if _xp_doubler_active:
		_pending_xp *= 2
	_pending_coins = 10 if did_win else 0
	if _xp_doubler_active:
		_pending_coins *= 2
	_pending_levels = SaveData.add_xp(_pending_xp)
	SaveData.add_coins(_pending_coins)

	var newly_reached := SeasonManager.add_season_xp(xp_earned)
	if not newly_reached.is_empty():
		_show_toast("Milestone reached! Open Rewards to claim.")

	_check_achievements_after_game(did_win)
	if current_mode == GameMode.EASY and did_win:
		SaveData.easy_wins += 1
		SaveData.save()
		if SaveData.easy_wins == 3:
			_show_toast("Ready for Classic? Try it without the hints!")
	if not did_win:
		AdManager.on_game_lost()

	# Add share button to result if not already present
	if not result_layer.has_node("Overlay/PopupCenter/PopupPanel/PopupMargin/PopupVBox/ResultButtons/ShareButton"):
		var share_btn := Button.new()
		share_btn.name = "ShareButton"
		share_btn.text = "SHARE"
		share_btn.custom_minimum_size = Vector2(0, 52)
		share_btn.pressed.connect(_on_share_pressed)
		var result_buttons := result_layer.get_node("Overlay/PopupCenter/PopupPanel/PopupMargin/PopupVBox/ResultButtons")
		result_buttons.add_child(share_btn)
		result_buttons.move_child(share_btn, 0)

	_show_result_sheet(did_win, guess_history.size())
	# TODO: update to pastel
	#result_message_label.add_theme_color_override("font_color", C_MUTED)

	if did_win:
		result_title_label.text = "Cracked it!"
		# TODO: update to pastel
		#result_title_label.add_theme_color_override("font_color", C_SUCCESS)
		result_message_label.text = message + "\n\nCONFIRMED SEQUENCE:"
		status_label.text = "SEQUENCE CONFIRMED."
		_reveal_answer_dots()
		_show_reward_flytext(_pending_xp, _pending_coins, _pending_levels)
		if not _xp_doubler_active and AdManager.is_rewarded_ready():
			_add_xp_doubler_button()
	else:
		result_title_label.text = "Better luck next time!"
		# TODO: update to pastel
		#result_title_label.add_theme_color_override("font_color", C_DANGER)
		result_message_label.text = message
		status_label.text = "DECIDE YOUR NEXT ACTION."
		# Offer second chance BEFORE revealing the answer
		if not _second_chance_used and AdManager.is_rewarded_ready():
			_offer_second_chance_or_reveal()
		else:
			_reveal_answer()

	# Campaign: record progress + show stars + customize buttons
	if current_mode == GameMode.CAMPAIGN:
		var cfg := _get_campaign_config(_current_campaign_level)
		var stars := _calc_campaign_stars(guess_history.size(), did_win, cfg)
		_campaign_won = did_win
		SaveData.record_campaign_level(_current_campaign_level, stars)
		_show_campaign_stars_ui(stars)
		if did_win and _current_campaign_level < 100:
			result_play_again_button.text = "NEXT LEVEL ▶"
		else:
			result_play_again_button.text = "RETRY LEVEL"
		result_menu_button.text = "CAMPAIGN MAP"

func _trigger_dot_burst() -> void:
	if not has_node("GameLayer/GameVBox/BoardVBox"):
		return
	var board_rect := ($GameLayer/GameVBox/BoardVBox as Control).get_global_rect()
	if board_rect.size == Vector2.ZERO:
		return
	var board_center := board_rect.get_center()
	var num_particles := 14
	var colors: Array = secret_sequence.map(func(ci: int) -> Color: return PALETTE[ci]["color"])

	for i in range(num_particles):
		var dot_color: Color = colors[i % colors.size()]
		var size_px := rng.randf_range(8.0, 12.0)

		# Use PanelContainer for rounded circle shape
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2(size_px, size_px)
		var sb := StyleBoxFlat.new()
		sb.bg_color = dot_color
		sb.corner_radius_top_left     = 999
		sb.corner_radius_top_right    = 999
		sb.corner_radius_bottom_left  = 999
		sb.corner_radius_bottom_right = 999
		dot.add_theme_stylebox_override("panel", sb)
		dot.global_position = board_center
		add_child(dot)

		var angle := (TAU / num_particles) * i + rng.randf_range(-0.3, 0.3)
		var dist  := rng.randf_range(200.0, 400.0)
		var target := board_center + Vector2(cos(angle), sin(angle)) * dist
		var dur   := rng.randf_range(1.0, 1.4)

		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(dot, "global_position", target, dur)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(dot, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
		tw.finished.connect(dot.queue_free)

func _reveal_answer_dots() -> void:
	for child in result_dots_container.get_children():
		child.queue_free()
	for value in secret_sequence:
		var cd: Dictionary = PALETTE[value]
		result_dots_container.add_child(_make_dot_preview(cd["color"], str(cd["name"]), 62))

func _reveal_answer() -> void:
	result_message_label.text += "\n\nACTUAL SEQUENCE:"
	_reveal_answer_dots()
	status_label.text = "SEQUENCE REVEALED ABOVE."
	_show_reward_flytext(_pending_xp, _pending_coins, _pending_levels)
	if not _xp_doubler_active and AdManager.is_rewarded_ready():
		_add_xp_doubler_button()

func _offer_second_chance_or_reveal() -> void:
	var popup_vbox: VBoxContainer = $ResultLayer/Overlay/PopupCenter/PopupPanel/PopupMargin/PopupVBox

	var offer_lbl := Label.new()
	offer_lbl.text = "WANT ANOTHER CHANCE?"
	offer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# TODO: update to pastel
	#offer_lbl.add_theme_color_override("font_color", C_WHITE)
	offer_lbl.add_theme_font_size_override("font_size", 26)
	popup_vbox.add_child(offer_lbl)
	popup_vbox.move_child(offer_lbl, popup_vbox.get_child_count() - 2)

	var sc_btn := Button.new()
	sc_btn.text = "⚡ SECOND CHANCE  [WATCH AD]  +3 ATTEMPTS"
	sc_btn.custom_minimum_size = Vector2(0, 64)
	_style_cta_button(sc_btn)
	popup_vbox.add_child(sc_btn)
	popup_vbox.move_child(sc_btn, popup_vbox.get_child_count() - 2)

	var no_btn := Button.new()
	no_btn.text = "NO THANKS — REVEAL SEQUENCE"
	no_btn.custom_minimum_size = Vector2(0, 54)
	popup_vbox.add_child(no_btn)
	popup_vbox.move_child(no_btn, popup_vbox.get_child_count() - 2)

	sc_btn.pressed.connect(func():
		if _second_chance_used or not AdManager.is_rewarded_ready():
			return
		sc_btn.disabled = true
		no_btn.disabled = true
		AdManager.rewarded_earned.connect(
			_apply_second_chance.bind(sc_btn, no_btn, offer_lbl), CONNECT_ONE_SHOT)
		var shown := AdManager.show_rewarded()
		if not shown:
			AdManager.rewarded_earned.disconnect(_apply_second_chance)
			sc_btn.disabled = false
			no_btn.disabled = false
	)

	no_btn.pressed.connect(func():
		offer_lbl.queue_free()
		sc_btn.queue_free()
		no_btn.queue_free()
		_reveal_answer()
	)

func _check_achievements_after_game(did_win: bool) -> void:
	SaveData.unlock_achievement("first_win") if did_win else null
	if SaveData.games_won >= 10:
		SaveData.unlock_achievement("win_10")
	if SaveData.games_won >= 50:
		SaveData.unlock_achievement("win_50")
	if SaveData.games_won >= 100:
		SaveData.unlock_achievement("win_100")
	if SaveData.perfect_wins >= 1:
		SaveData.unlock_achievement("perfect_once")
	if SaveData.perfect_wins >= 5:
		SaveData.unlock_achievement("perfect_5")
	if SaveData.games_played >= 100:
		SaveData.unlock_achievement("played_100")

# =============================================================================
# P4 — Second Chance (granted via ad)
# =============================================================================
func _apply_second_chance(sc_btn: Button, no_btn: Button, offer_lbl: Label) -> void:
	_second_chance_used = true
	SaveData.ads_watched += 1
	SaveData.save()
	offer_lbl.queue_free()
	sc_btn.queue_free()
	no_btn.queue_free()
	MAX_GUESSES += 3
	round_active         = true
	result_layer.visible = false
	game_layer.visible   = true
	for index in range(current_guess.size()):
		current_guess[index] = -1
	_refresh_guess_ui()
	_update_palette_selection()
	_update_header_text("SECOND CHANCE GRANTED — 3 BONUS ATTEMPTS.")

func _on_combo_changed(count: int) -> void:
	if _combo_label == null or not is_instance_valid(_combo_label):
		var existing := $GameLayer/GameVBox/HeaderPanel.find_child("ComboLabel", false, false)
		if existing != null:
			_combo_label = existing as Label
		else:
			_combo_label = Label.new()
			_combo_label.name = "ComboLabel"
			_combo_label.add_theme_color_override("font_color", Color("#F472B6"))
			_combo_label.add_theme_font_size_override("font_size", 24)
			$GameLayer/GameVBox/HeaderPanel.add_child(_combo_label)
	if count >= 2:
		_combo_label.text = "🔥 %d" % count
		_combo_label.visible = true
		_combo_label.pivot_offset = _combo_label.get_minimum_size() / 2.0
		var tw := create_tween()
		tw.tween_property(_combo_label, "scale", Vector2(1.3, 1.3), 0.1)
		tw.tween_property(_combo_label, "scale", Vector2(1.0, 1.0), 0.1)
	else:
		_combo_label.visible = false

# =============================================================================
# P5 — XP / Coin Doubler
# =============================================================================
func _add_xp_doubler_button() -> void:
	var btn := Button.new()
	btn.text = "✦ DOUBLE REWARDS  [WATCH AD]"
	btn.custom_minimum_size = Vector2(0, 58)
	var popup_vbox: VBoxContainer = $ResultLayer/Overlay/PopupCenter/PopupPanel/PopupMargin/PopupVBox
	popup_vbox.add_child(btn)
	popup_vbox.move_child(btn, popup_vbox.get_child_count() - 2)
	btn.pressed.connect(_on_xp_doubler_pressed.bind(btn))

func _on_xp_doubler_pressed(btn: Button) -> void:
	if _xp_doubler_active or not AdManager.is_rewarded_ready():
		return
	btn.disabled = true
	AdManager.rewarded_earned.connect(_apply_xp_doubler.bind(btn), CONNECT_ONE_SHOT)
	var shown := AdManager.show_rewarded()
	if not shown:
		AdManager.rewarded_earned.disconnect(_apply_xp_doubler)
		btn.disabled = false

func _apply_xp_doubler(btn: Button) -> void:
	_xp_doubler_active = true
	SaveData.ads_watched += 1
	# Award the bonus: an equal amount of XP and coins again
	# We compute what was earned this game and double it
	var bonus_xp := 15
	if guess_history.size() > 0:
		bonus_xp = 50  # approximate — actual bonus already tracked in _finish_game
	SaveData.add_xp(bonus_xp)
	SaveData.add_coins(10)
	btn.queue_free()
	_show_reward_flytext(bonus_xp, 10, 0)

# =============================================================================
## Show "+NNN XP  +NN COINS" briefly on the result screen.
func _show_reward_flytext(xp_earned: int, coins_earned: int, levels_gained: int) -> void:
	var lbl := Label.new()
	var text := "+%d XP" % xp_earned
	if coins_earned > 0:
		text += "   +%d COINS" % coins_earned
	if levels_gained > 0:
		text += "\n▲ LEVEL %d" % SaveData.level
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# TODO: update to pastel
	#lbl.add_theme_color_override("font_color", C_GOLD)
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.modulate.a = 0.0

	# Add to result popup VBox (above buttons)
	var popup_vbox: VBoxContainer = $ResultLayer/Overlay/PopupCenter/PopupPanel/PopupMargin/PopupVBox
	popup_vbox.add_child(lbl)
	popup_vbox.move_child(lbl, popup_vbox.get_child_count() - 2)  # above buttons

	var tw := lbl.create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.30)
	tw.tween_interval(1.50)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.40)
	tw.tween_callback(lbl.queue_free)

# =============================================================================
# Helpers
# =============================================================================
func _make_dot_preview(fill: Color, color_name: String, size: int) -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(size, size)
	panel.size = Vector2(size, size)
	panel.tooltip_text = color_name
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left     = 999
	style.corner_radius_top_right    = 999
	style.corner_radius_bottom_right = 999
	style.corner_radius_bottom_left  = 999
	style.border_width_left   = 2
	style.border_width_top    = 2
	style.border_width_right  = 2
	style.border_width_bottom = 2
	style.border_color = fill.lightened(0.30)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _make_diamond_pip(fill: Color) -> Control:
	var lbl := Label.new()
	lbl.text = "◆"
	lbl.add_theme_color_override("font_color", fill)
	lbl.add_theme_font_size_override("font_size", 16)
	return lbl

func _make_panel_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left     = 20
	style.corner_radius_top_right    = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left  = 20
	style.border_width_left   = 1
	style.border_width_top    = 1
	style.border_width_right  = 1
	style.border_width_bottom = 1
	style.border_color = C_PANEL_BORDER
	return style

# =============================================================================
# Login streak popup
# =============================================================================
func _on_login_streak_updated(streak: int, coins_awarded: int) -> void:
	# Show a brief toast overlay: "DAY N STREAK  +NN COINS"
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.layout_mode = 1
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var panel := PanelContainer.new()
	panel.layout_mode = 0
	var vp := get_viewport_rect().size
	panel.custom_minimum_size = Vector2(420, 0)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.08, 0.18, 0.97)))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   28)
	margin.add_theme_constant_override("margin_right",  28)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var streak_lbl := Label.new()
	streak_lbl.text = "🔥  DAY %d LOGIN STREAK" % streak
	streak_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# TODO: update to pastel
	#streak_lbl.add_theme_color_override("font_color", C_GOLD)
	streak_lbl.add_theme_font_size_override("font_size", 28)
	vbox.add_child(streak_lbl)

	var coin_lbl := Label.new()
	coin_lbl.text = "+%d COINS AWARDED" % coins_awarded
	coin_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# TODO: update to pastel
	#coin_lbl.add_theme_color_override("font_color", C_SUCCESS)
	coin_lbl.add_theme_font_size_override("font_size", 22)
	vbox.add_child(coin_lbl)

	overlay.add_child(panel)

	# Position at top-center after a frame to know the panel's size
	await get_tree().process_frame
	panel.position = Vector2((vp.x - panel.size.x) * 0.5, -panel.size.y)

	# Slide down from top, hold, slide back up
	var tw := create_tween()
	tw.tween_property(panel, "position:y", 60.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(2.5)
	tw.tween_property(panel, "position:y", -panel.size.y - 10.0, 0.30).set_ease(Tween.EASE_IN)
	tw.tween_callback(overlay.queue_free)

# =============================================================================
func _is_guess_complete() -> bool:
	for value in current_guess:
		if value == -1:
			return false
	return true

func _filled_slot_count() -> int:
	var count := 0
	for value in current_guess:
		if value != -1:
			count += 1
	return count

# =============================================================================
# Mode Select overlay
# =============================================================================
func _build_mode_select() -> void:
	pass

func _make_mode_card(data: Dictionary, open_campaign: bool = false) -> Control:
	var mode_col: Color = data["color"]

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ps := StyleBoxFlat.new()
	ps.bg_color                  = Color(0.032, 0.047, 0.090, 0.90)
	ps.corner_radius_top_left    = 14
	ps.corner_radius_top_right   = 14
	ps.corner_radius_bottom_right = 14
	ps.corner_radius_bottom_left  = 14
	ps.border_width_left          = 3
	ps.border_width_top           = 1
	ps.border_width_right         = 1
	ps.border_width_bottom        = 1
	ps.border_color               = Color(mode_col.r, mode_col.g, mode_col.b, 0.55)
	panel.add_theme_stylebox_override("panel", ps)

	var mm := MarginContainer.new()
	mm.layout_mode = 2
	mm.add_theme_constant_override("margin_left",   18)
	mm.add_theme_constant_override("margin_right",  14)
	mm.add_theme_constant_override("margin_top",    14)
	mm.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(mm)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	mm.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 5)
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = data["name"]
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_color", mode_col)
	info.add_child(name_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = data["sub"]
	sub_lbl.add_theme_font_size_override("font_size", 19)
	# TODO: update to pastel
	#sub_lbl.add_theme_color_override("font_color", C_MUTED)
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(sub_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = data["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 22)
	# TODO: update to pastel
	#desc_lbl.add_theme_color_override("font_color", C_WHITE)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc_lbl)

	var sel_btn := Button.new()
	sel_btn.text = "SELECT"
	sel_btn.custom_minimum_size = Vector2(148, 0)
	sel_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_cta_button(sel_btn)
	if open_campaign:
		sel_btn.pressed.connect(func(): _close_mode_select(); _open_campaign_screen())
	else:
		sel_btn.pressed.connect(_on_mode_selected.bind(int(data["mode"])))
	row.add_child(sel_btn)

	return panel

func _open_mode_select() -> void:
	var sheet := _build_bottom_sheet("Choose Mode")
	var vbox := sheet.get_node("Content") as VBoxContainer

	var modes := [
		{"mode": GameMode.CLASSIC,  "name": "Classic",  "desc": "3–5 slots · 10 guesses"},
		{"mode": GameMode.EASY,     "name": "Easy",     "desc": "3–4 slots · color hints"},
		{"mode": GameMode.BLITZ,    "name": "Blitz",    "desc": "5 slots · 90s timer"},
		{"mode": GameMode.HARD,     "name": "Hard",     "desc": "5–6 slots · 6 colors"},
		{"mode": GameMode.ZEN,      "name": "Zen",      "desc": "Unlimited guesses"},
		{"mode": GameMode.CAMPAIGN, "name": "Campaign", "desc": "100 levels"},
		{"mode": GameMode.MYSTERY,    "name": "Mystery",    "desc": "Slots hidden · 12 guesses"},
		{"mode": GameMode.TIME_TRIAL, "name": "Time Trial", "desc": "5 puzzles · fastest wins"},
	]

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)

	for item in modes:
		var card := PanelContainer.new()
		_style_panel_glass(card)
		card.custom_minimum_size = Vector2(0, 80)
		var card_vbox := VBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = item["name"]
		name_lbl.add_theme_color_override("font_color", C_TEXT_PRIMARY)
		name_lbl.add_theme_font_size_override("font_size", 20)
		var desc_lbl := Label.new()
		desc_lbl.text = item["desc"]
		desc_lbl.add_theme_color_override("font_color", C_TEXT_SECONDARY)
		desc_lbl.add_theme_font_size_override("font_size", 14)
		card_vbox.add_child(name_lbl)
		card_vbox.add_child(desc_lbl)
		card.add_child(card_vbox)
		var mode_val: int = item["mode"]
		card.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed:
				_close_bottom_sheet(sheet.get_meta("overlay") as Control, sheet)
				get_tree().create_timer(0.3).timeout.connect(
					func() -> void: start_new_game(mode_val as GameMode), CONNECT_ONE_SHOT)
		)
		grid.add_child(card)

	vbox.add_child(grid)

	# Custom puzzle link
	var custom_link := Button.new()
	custom_link.text = "🔗 Play a friend's code"
	custom_link.add_theme_color_override("font_color", C_TEXT_SECONDARY)
	custom_link.pressed.connect(_open_custom_puzzle_code_sheet)
	vbox.add_child(custom_link)

func _open_custom_puzzle_code_sheet() -> void:
	var sheet := _build_bottom_sheet("Enter Puzzle Code")
	var vbox := sheet.get_node("Content") as VBoxContainer

	var line_edit := LineEdit.new()
	line_edit.placeholder_text = "GTD-XXXX"
	line_edit.custom_minimum_size = Vector2(0, 52)
	vbox.add_child(line_edit)

	var play_btn := Button.new()
	play_btn.text = "Play"
	play_btn.custom_minimum_size = Vector2(0, 52)
	play_btn.pressed.connect(func() -> void:
		var code := line_edit.text.strip_edges()
		_close_bottom_sheet(sheet.get_meta("overlay") as Control, sheet)
		get_tree().create_timer(0.3).timeout.connect(
			func() -> void: _open_custom_puzzle_play(code), CONNECT_ONE_SHOT)
	)
	vbox.add_child(play_btn)

func _close_mode_select() -> void:
	pass  # replaced by _close_bottom_sheet

func _on_mode_selected(mode_int: int) -> void:
	pass  # replaced by mode card gui_input in _open_mode_select

# =============================================================================
# Rewards Screen (Shop + Season tabs)
# =============================================================================
func _open_rewards_screen() -> void:
	var sheet := _build_bottom_sheet("Rewards")
	var vbox := sheet.get_node("Content") as VBoxContainer

	# XP balance header
	var xp_lbl := Label.new()
	xp_lbl.text = "⚡ %d XP" % SaveData.total_xp_earned
	xp_lbl.add_theme_color_override("font_color", Color("#F472B6"))
	xp_lbl.add_theme_font_size_override("font_size", 28)
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(xp_lbl)

	# Tab bar
	var tab_bar := HBoxContainer.new()
	tab_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_bar.add_theme_constant_override("separation", 12)
	var shop_tab_btn := Button.new()
	shop_tab_btn.text = "⚡ Shop"
	shop_tab_btn.custom_minimum_size = Vector2(160, 52)
	var season_tab_btn := Button.new()
	season_tab_btn.text = "🏅 Season"
	season_tab_btn.custom_minimum_size = Vector2(160, 52)
	tab_bar.add_child(shop_tab_btn)
	tab_bar.add_child(season_tab_btn)
	vbox.add_child(tab_bar)

	var content_area := ScrollContainer.new()
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.custom_minimum_size = Vector2(0, 400)
	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
		row.add_theme_constant_override("separation", 8)
		var name_lbl := Label.new()
		name_lbl.text = item.name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_color_override("font_color", Color("#6B4E71"))
		name_lbl.add_theme_font_size_override("font_size", 22)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var cost_str: String
		if item.cost_type == "xp":
			cost_str = "%d ⚡" % item.cost
		else:
			cost_str = "%d 🪙" % item.cost
		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = Vector2(110, 44)
		if ShopManager.is_owned(item.id):
			buy_btn.text = "Owned ✓"
			buy_btn.disabled = true
		else:
			buy_btn.text = cost_str
			var item_id: String = item.id
			buy_btn.pressed.connect(func():
				if ShopManager.purchase(item_id):
					_show_toast("Purchased!")
					buy_btn.text = "Owned ✓"
					buy_btn.disabled = true
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
	season_name_lbl.add_theme_font_size_override("font_size", 26)
	season_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(season_name_lbl)

	var milestones := SeasonManager.get_milestones()
	var progress_lbl := Label.new()
	progress_lbl.text = "Season XP: %d / %d" % [SaveData.season_xp, milestones.back()]
	progress_lbl.add_theme_color_override("font_color", Color("#9B7EA6"))
	progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(progress_lbl)

	for i in range(milestones.size()):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var milestone_lbl := Label.new()
		milestone_lbl.text = "Milestone %d — %d XP" % [i + 1, milestones[i]]
		milestone_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		milestone_lbl.add_theme_color_override("font_color", Color("#6B4E71"))
		milestone_lbl.add_theme_font_size_override("font_size", 22)
		var claim_btn := Button.new()
		claim_btn.custom_minimum_size = Vector2(100, 44)
		if SaveData.season_claimed[i]:
			claim_btn.text = "✓ Claimed"
			claim_btn.disabled = true
		elif SaveData.season_xp >= milestones[i]:
			claim_btn.text = "Claim!"
			var idx := i
			claim_btn.pressed.connect(func():
				var reward := SeasonManager.claim_milestone(idx)
				if not reward.is_empty():
					_show_toast("Reward claimed!")
					_clear_children(container)
					_populate_season_tab(container)
			)
		else:
			claim_btn.text = "Locked 🔒"
			claim_btn.disabled = true
		row.add_child(milestone_lbl)
		row.add_child(claim_btn)
		container.add_child(row)

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

# =============================================================================
# Stats Screen overlay
# =============================================================================
func _open_stats_screen() -> void:
	# Rebuild with fresh SaveData each time
	if is_instance_valid(_stats_layer):
		_stats_layer.queue_free()
	_build_stats_screen()
	_stats_layer.visible = true
	_stats_layer.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_stats_layer, "modulate:a", 1.0, 0.22)

func _close_stats_screen() -> void:
	var tw := create_tween()
	tw.tween_property(_stats_layer, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func(): _stats_layer.queue_free())

func _build_stats_screen() -> void:
	_stats_layer = Control.new()
	_stats_layer.layout_mode = 1
	_stats_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stats_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_stats_layer.visible = false
	add_child(_stats_layer)

	var overlay := ColorRect.new()
	overlay.layout_mode = 1
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.78)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_stats_layer.add_child(overlay)

	var outer_center := CenterContainer.new()
	outer_center.layout_mode = 1
	outer_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stats_layer.add_child(outer_center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(720, 0)
	card.add_theme_stylebox_override("panel", _make_panel_style(C_PANEL))
	outer_center.add_child(card)

	var cm := MarginContainer.new()
	cm.layout_mode = 2
	cm.add_theme_constant_override("margin_left",   36)
	cm.add_theme_constant_override("margin_right",  36)
	cm.add_theme_constant_override("margin_top",    36)
	cm.add_theme_constant_override("margin_bottom", 36)
	card.add_child(cm)

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 2
	vbox.add_theme_constant_override("separation", 18)
	cm.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "AGENT STATISTICS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0, 1.0))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Row 1: core stats
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 12)
	vbox.add_child(row1)

	var win_pct := 0
	if SaveData.games_played > 0:
		win_pct = int(round(float(SaveData.games_won) / float(SaveData.games_played) * 100.0))

	# TODO: update to pastel
	for tile_data in [
		["PLAYED",      str(SaveData.games_played),       Color.WHITE],  # C_WHITE
		["WIN RATE",    "%d%%" % win_pct,                 Color.GREEN],  # C_SUCCESS
		["WIN STREAK",  str(SaveData.current_win_streak), Color.YELLOW],  # C_GOLD
		["BEST STREAK", str(SaveData.max_win_streak),     Color.YELLOW],  # C_GOLD
	]:
		row1.add_child(_make_stat_tile(tile_data[0], tile_data[1], tile_data[2]))

	vbox.add_child(HSeparator.new())

	# Guess distribution histogram
	var dist_title := Label.new()
	dist_title.text = "GUESS DISTRIBUTION"
	dist_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dist_title.add_theme_font_size_override("font_size", 24)
	# TODO: update to pastel
	#dist_title.add_theme_color_override("font_color", C_MUTED)
	vbox.add_child(dist_title)

	var dist_max := 1
	for v in SaveData.guess_distribution:
		dist_max = max(dist_max, int(v))

	var dist_vbox := VBoxContainer.new()
	dist_vbox.add_theme_constant_override("separation", 7)
	vbox.add_child(dist_vbox)

	for i in range(10):
		var count := int(SaveData.guess_distribution[i])
		var ratio := float(count) / float(dist_max)

		var dr := HBoxContainer.new()
		dr.add_theme_constant_override("separation", 8)
		dist_vbox.add_child(dr)

		var num_lbl := Label.new()
		num_lbl.text = str(i + 1)
		num_lbl.add_theme_font_size_override("font_size", 20)
		# TODO: update to pastel
		#num_lbl.add_theme_color_override("font_color", C_MUTED)
		num_lbl.custom_minimum_size = Vector2(26, 0)
		num_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
		dr.add_child(num_lbl)

		var bar_outer := HBoxContainer.new()
		bar_outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar_outer.custom_minimum_size   = Vector2(0, 26)
		dr.add_child(bar_outer)

		var filled := Panel.new()
		filled.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
		filled.size_flags_stretch_ratio = max(ratio, 0.02)
		var fs := StyleBoxFlat.new()
		# TODO: update to pastel
		fs.bg_color = Color.GREEN if count > 0 else Color(0.08, 0.12, 0.22, 0.60)  # C_SUCCESS
		fs.corner_radius_top_left     = 5
		fs.corner_radius_top_right    = 5
		fs.corner_radius_bottom_left  = 5
		fs.corner_radius_bottom_right = 5
		filled.add_theme_stylebox_override("panel", fs)
		bar_outer.add_child(filled)

		if ratio < 0.98:
			var spacer := Control.new()
			spacer.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
			spacer.size_flags_stretch_ratio = max(1.0 - ratio, 0.02)
			bar_outer.add_child(spacer)

		var cnt_lbl := Label.new()
		cnt_lbl.text = str(count)
		cnt_lbl.add_theme_font_size_override("font_size", 20)
		# TODO: update to pastel
		#cnt_lbl.add_theme_color_override("font_color", C_GOLD)
		cnt_lbl.custom_minimum_size     = Vector2(30, 0)
		cnt_lbl.horizontal_alignment    = HORIZONTAL_ALIGNMENT_RIGHT
		cnt_lbl.vertical_alignment      = VERTICAL_ALIGNMENT_CENTER
		dr.add_child(cnt_lbl)

	vbox.add_child(HSeparator.new())

	# Row 2: level / daily stats
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 12)
	vbox.add_child(row2)

	# TODO: update to pastel
	for tile_data in [
		["LEVEL",        str(SaveData.level),            Color(0.0, 0.9, 1.0, 1.0)],
		["DAILY STREAK", str(SaveData.daily_streak),     Color.YELLOW],  # C_GOLD
		["DAILY BEST",   str(SaveData.daily_max_streak), Color.YELLOW],  # C_GOLD
		["COINS",        str(SaveData.coins),             Color.YELLOW],  # C_GOLD
	]:
		row2.add_child(_make_stat_tile(tile_data[0], tile_data[1], tile_data[2]))

	vbox.add_child(HSeparator.new())

	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(0, 64)
	close_btn.pressed.connect(_close_stats_screen)
	vbox.add_child(close_btn)

func _make_stat_tile(label: String, value: String, value_color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.032, 0.047, 0.090, 0.90)
	ps.corner_radius_top_left     = 14
	ps.corner_radius_top_right    = 14
	ps.corner_radius_bottom_left  = 14
	ps.corner_radius_bottom_right = 14
	ps.border_width_left   = 1
	ps.border_width_top    = 1
	ps.border_width_right  = 1
	ps.border_width_bottom = 1
	ps.border_color = C_PANEL_BORDER
	panel.add_theme_stylebox_override("panel", ps)

	var mm := MarginContainer.new()
	mm.layout_mode = 2
	mm.add_theme_constant_override("margin_left",   12)
	mm.add_theme_constant_override("margin_right",  12)
	mm.add_theme_constant_override("margin_top",    14)
	mm.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(mm)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	mm.add_child(vb)

	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_size_override("font_size", 34)
	val_lbl.add_theme_color_override("font_color", value_color)
	vb.add_child(val_lbl)

	var key_lbl := Label.new()
	key_lbl.text = label
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_lbl.add_theme_font_size_override("font_size", 17)
	# TODO: update to pastel
	#key_lbl.add_theme_color_override("font_color", C_MUTED)
	vb.add_child(key_lbl)

	return panel

# =============================================================================
# Campaign helpers
# =============================================================================
func _get_campaign_config(level: int) -> Dictionary:
	if level <= 20:
		return {"slots": 3, "colors": 3, "guesses": 8, "star3": 3, "star2": 5}
	elif level <= 50:
		return {"slots": 4, "colors": 4, "guesses": 8, "star3": 4, "star2": 6}
	elif level <= 80:
		return {"slots": 4, "colors": 5, "guesses": 8, "star3": 4, "star2": 6}
	else:
		return {"slots": 5, "colors": 6, "guesses": 8, "star3": 5, "star2": 7}

func _campaign_sequence(level: int, p_slots: int, color_count: int) -> Array[int]:
	var r := RandomNumberGenerator.new()
	r.seed = level * 7919 + 42
	var seq: Array[int] = []
	for _i in range(p_slots):
		seq.append(r.randi_range(0, color_count - 1))
	return seq

func _calc_campaign_stars(guesses_used: int, did_win: bool, config: Dictionary) -> int:
	if not did_win:
		return 0
	if guesses_used <= int(config["star3"]):
		return 3
	if guesses_used <= int(config["star2"]):
		return 2
	return 1

## Injects a level label + star rating into the result popup (above message).
## Uses a group tag so a second _finish_game call can replace them safely.
func _show_campaign_stars_ui(stars: int) -> void:
	var popup_vbox: VBoxContainer = $ResultLayer/Overlay/PopupCenter/PopupPanel/PopupMargin/PopupVBox

	# Remove any previously injected campaign labels
	for child in popup_vbox.get_children().duplicate():
		if child.is_in_group("campaign_ui"):
			child.free()

	var lvl_lbl := Label.new()
	lvl_lbl.text = "LEVEL %d" % _current_campaign_level
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_lbl.add_theme_font_size_override("font_size", 22)
	# TODO: update to pastel
	#lvl_lbl.add_theme_color_override("font_color", C_MUTED)
	lvl_lbl.add_to_group("campaign_ui")
	popup_vbox.add_child(lvl_lbl)
	popup_vbox.move_child(lvl_lbl, 1)  # just below title

	var star_str := ""
	for i in range(3):
		star_str += "★" if i < stars else "☆"
	var star_lbl := Label.new()
	star_lbl.text = star_str
	star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_lbl.add_theme_font_size_override("font_size", 54)
	# TODO: update to pastel
	star_lbl.add_theme_color_override("font_color", Color.YELLOW if stars > 0 else Color.GRAY)  # C_GOLD if stars > 0 else C_MUTED
	star_lbl.add_to_group("campaign_ui")
	popup_vbox.add_child(star_lbl)
	popup_vbox.move_child(star_lbl, 2)  # below level label

# =============================================================================
# Campaign Level Select screen
# =============================================================================
func _open_campaign_screen() -> void:
	if is_instance_valid(_campaign_layer):
		_campaign_layer.queue_free()
	_build_campaign_screen()
	_campaign_layer.visible = true
	_campaign_layer.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_campaign_layer, "modulate:a", 1.0, 0.22)

func _close_campaign_screen() -> void:
	var tw := create_tween()
	tw.tween_property(_campaign_layer, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func():
		if is_instance_valid(_campaign_layer):
			_campaign_layer.queue_free()
	)

func _build_campaign_screen() -> void:
	_campaign_layer = Control.new()
	_campaign_layer.layout_mode = 1
	_campaign_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_campaign_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_campaign_layer.visible = false
	add_child(_campaign_layer)

	var bg := ColorRect.new()
	bg.layout_mode = 1
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	# TODO: update to pastel
	bg.color = Color(0.0, 0.0, 0.0, 0.97)  # C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_campaign_layer.add_child(bg)

	var margin := MarginContainer.new()
	margin.layout_mode = 1
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   24)
	margin.add_theme_constant_override("margin_right",  24)
	margin.add_theme_constant_override("margin_top",    24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_campaign_layer.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.layout_mode = 2
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var content := VBoxContainer.new()
	content.layout_mode = 2
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 20)
	scroll.add_child(content)

	# Title
	var title := Label.new()
	title.text = "CAMPAIGN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	# TODO: update to pastel
	#title.add_theme_color_override("font_color", C_GOLD)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "100 LEVELS  ·  EARN UP TO ★★★  ·  DIFFICULTY SCALES"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	# TODO: update to pastel
	#subtitle.add_theme_color_override("font_color", C_MUTED)
	content.add_child(subtitle)

	content.add_child(HSeparator.new())

	# Tier legend
	var legend := Label.new()
	legend.text = "L1–20: 3 nodes  ·  L21–50: 4 nodes  ·  L51–80: 4 nodes+  ·  L81–100: 5 nodes / 6 colors"
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.add_theme_font_size_override("font_size", 17)
	# TODO: update to pastel
	#legend.add_theme_color_override("font_color", C_MUTED)
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(legend)

	# 5-column grid
	var grid := GridContainer.new()
	grid.columns = 5
	grid.layout_mode = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)

	var max_unlocked := SaveData.campaign_max_unlocked
	for lvl in range(1, 101):
		var key := str(lvl)
		var stars := 0
		if SaveData.campaign_progress.has(key):
			stars = int(SaveData.campaign_progress[key].get("stars", 0))
		var is_locked := lvl > max_unlocked
		grid.add_child(_make_campaign_level_button(lvl, stars, is_locked))

	content.add_child(HSeparator.new())

	var back_btn := Button.new()
	back_btn.text = "← BACK TO MENU"
	back_btn.custom_minimum_size = Vector2(0, 64)
	back_btn.pressed.connect(_close_campaign_screen)
	content.add_child(back_btn)

func _make_campaign_level_button(lvl: int, stars: int, is_locked: bool) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 72)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.disabled = is_locked

	var ps := StyleBoxFlat.new()
	ps.corner_radius_top_left     = 12
	ps.corner_radius_top_right    = 12
	ps.corner_radius_bottom_right = 12
	ps.corner_radius_bottom_left  = 12
	ps.border_width_left   = 2
	ps.border_width_top    = 2
	ps.border_width_right  = 2
	ps.border_width_bottom = 2

	var font_color: Color
	if is_locked:
		ps.bg_color    = Color(0.04, 0.06, 0.10, 0.55)
		ps.border_color = Color(0.20, 0.22, 0.30, 0.25)
		font_color = Color(0.35, 0.38, 0.48, 0.55)
	elif stars == 3:
		ps.bg_color    = Color(0.12, 0.10, 0.02, 0.92)
		# TODO: update to pastel
		ps.border_color = Color(Color.YELLOW.r, Color.YELLOW.g, Color.YELLOW.b, 0.80)  # C_GOLD
		font_color = Color.YELLOW  # C_GOLD
	elif stars > 0:
		ps.bg_color    = Color(0.02, 0.10, 0.14, 0.92)
		ps.border_color = Color(0.00, 0.90, 1.00, 0.60)
		font_color = Color(0.00, 0.90, 1.00, 1.0)
	else:
		ps.bg_color    = Color(0.04, 0.08, 0.16, 0.90)
		ps.border_color = Color(0.00, 0.90, 1.00, 0.90)
		# TODO: update to pastel
		font_color = Color.WHITE  # C_WHITE

	btn.add_theme_stylebox_override("normal",   ps)
	btn.add_theme_stylebox_override("focus",    ps)
	btn.add_theme_stylebox_override("disabled", ps)

	var star_str := ""
	if is_locked:
		star_str = "🔒"
	else:
		for i in range(3):
			star_str += "★" if i < stars else "☆"

	btn.text = "%d\n%s" % [lvl, star_str]
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color",          font_color)
	btn.add_theme_color_override("font_disabled_color", font_color)

	if not is_locked:
		btn.pressed.connect(func():
			_close_campaign_screen()
			await get_tree().create_timer(0.22).timeout
			start_new_game(GameMode.CAMPAIGN, lvl)
		)

	return btn

func _show_toast(message: String) -> void:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#6B4E71")
	sb.corner_radius_top_left     = 12
	sb.corner_radius_top_right    = 12
	sb.corner_radius_bottom_left  = 12
	sb.corner_radius_bottom_right = 12
	sb.content_margin_left   = 20
	sb.content_margin_right  = 20
	sb.content_margin_top    = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = message
	lbl.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(lbl)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position.y -= 120
	add_child(panel)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(panel, "modulate:a", 0.0, 0.5)
	tw.finished.connect(panel.queue_free)

func _build_bottom_sheet(title: String, on_close: Callable = Callable()) -> Control:
	var overlay := ColorRect.new()
	overlay.name = "BottomSheetOverlay"
	overlay.color = Color(0.0, 0.0, 0.0, 0.5)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var sheet := PanelContainer.new()
	sheet.name = "BottomSheet"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 1.0, 0.97)
	sb.corner_radius_top_left  = 24
	sb.corner_radius_top_right = 24
	sb.content_margin_left   = 24
	sb.content_margin_right  = 24
	sb.content_margin_top    = 24
	sb.content_margin_bottom = 24
	sheet.add_theme_stylebox_override("panel", sb)
	sheet.set_anchor_and_offset(SIDE_LEFT,   0.0, 0.0)
	sheet.set_anchor_and_offset(SIDE_RIGHT,  1.0, 0.0)
	sheet.set_anchor_and_offset(SIDE_BOTTOM, 1.0, 0.0)
	sheet.set_anchor_and_offset(SIDE_TOP,    0.3, 0.0)
	sheet.position.y = get_viewport_rect().size.y
	add_child(sheet)

	var vbox := VBoxContainer.new()
	vbox.name = "Content"
	vbox.add_theme_constant_override("separation", 16)
	sheet.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_color_override("font_color", Color("#6B4E71"))
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	# Slide-up animation
	var tw := create_tween()
	tw.tween_property(sheet, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Close on overlay tap
	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			if on_close.is_valid():
				on_close.call()
			_close_bottom_sheet(overlay, sheet)
	)

	sheet.set_meta("overlay", overlay)
	return sheet

func _close_bottom_sheet(overlay: Control, sheet: Control) -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sheet, "position:y", get_viewport_rect().size.y, 0.25)
	tw.tween_property(overlay, "modulate:a", 0.0, 0.25)
	tw.finished.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
		if is_instance_valid(sheet):
			sheet.queue_free()
	)

func _show_time_trial_result() -> void:
	var score := _time_trial_puzzles_completed * 1000 - (_time_trial_total_time_ms / 1000)
	var sheet := _build_bottom_sheet("Time Trial Complete")
	var vbox := sheet.get_node("Content") as VBoxContainer

	var score_lbl := Label.new()
	score_lbl.text = "Score: %d" % score
	score_lbl.add_theme_font_size_override("font_size", 36)
	score_lbl.add_theme_color_override("font_color", Color("#F472B6"))
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(score_lbl)

	var solved_lbl := Label.new()
	solved_lbl.text = "Solved: %d / %d" % [_time_trial_puzzles_completed, TIME_TRIAL_TOTAL_PUZZLES]
	solved_lbl.add_theme_color_override("font_color", Color("#6B4E71"))
	solved_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(solved_lbl)

	for i in range(_time_trial_puzzle_times.size()):
		var t_lbl := Label.new()
		t_lbl.text = "Puzzle %d: %ds" % [i + 1, _time_trial_puzzle_times[i] / 1000]
		t_lbl.add_theme_color_override("font_color", Color("#9B7EA6"))
		vbox.add_child(t_lbl)

	# Personal best check
	var pb: Dictionary = SaveData.personal_bests.get("TIME_TRIAL", {})
	if score > pb.get("best_score", -999999):
		SaveData.personal_bests["TIME_TRIAL"] = {"best_score": score}
		SaveData.save()
		var pb_lbl := Label.new()
		pb_lbl.text = "🏅 New Personal Best!"
		pb_lbl.add_theme_color_override("font_color", Color("#F472B6"))
		pb_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(pb_lbl)

	# Play Again button
	var overlay := sheet.get_meta("overlay") as Control
	var play_again := Button.new()
	play_again.text = "Play Again"
	play_again.custom_minimum_size = Vector2(0, 64)
	play_again.pressed.connect(func():
		_close_bottom_sheet(overlay, sheet)
		get_tree().create_timer(0.3).timeout.connect(
			func(): start_new_game(GameMode.TIME_TRIAL), CONNECT_ONE_SHOT)
	)
	vbox.add_child(play_again)

	var menu_btn := Button.new()
	menu_btn.text = "Menu"
	menu_btn.custom_minimum_size = Vector2(0, 64)
	menu_btn.pressed.connect(func():
		_close_bottom_sheet(overlay, sheet)
		get_tree().create_timer(0.3).timeout.connect(
			func(): _show_menu(), CONNECT_ONE_SHOT)
	)
	vbox.add_child(menu_btn)

func _show_result_sheet(did_win: bool, guesses_used: int) -> void:
	_result_sheet_open = true
	var title_text := "You won! 🎉" if did_win else "Better luck next time"
	var sheet := _build_bottom_sheet(title_text, func() -> void: _result_sheet_open = false)
	var vbox := sheet.get_node("Content") as VBoxContainer

	# Title already added by _build_bottom_sheet; update its size
	var title_lbl := vbox.get_child(0) as Label
	title_lbl.add_theme_font_size_override("font_size", 32)

	# Secret reveal row — use PanelContainer + StyleBoxFlat for rounded dots
	var secret_row := HBoxContainer.new()
	secret_row.alignment = BoxContainer.ALIGNMENT_CENTER
	secret_row.add_theme_constant_override("separation", 8)
	for ci in secret_sequence:
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2(40, 40)
		var dot_sb := StyleBoxFlat.new()
		dot_sb.bg_color = PALETTE[ci]["color"]
		dot_sb.corner_radius_top_left    = 8
		dot_sb.corner_radius_top_right   = 8
		dot_sb.corner_radius_bottom_left  = 8
		dot_sb.corner_radius_bottom_right = 8
		dot.add_theme_stylebox_override("panel", dot_sb)
		secret_row.add_child(dot)
	vbox.add_child(secret_row)

	# XP + coins label
	var reward_lbl := Label.new()
	reward_lbl.text = "+%d XP  +%d coins" % [_pending_xp, _pending_coins]
	reward_lbl.add_theme_color_override("font_color", Color("#8B6E91"))
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(reward_lbl)

	# Share button
	var share_btn := Button.new()
	share_btn.text = "Share 🔗"
	share_btn.custom_minimum_size = Vector2(0, 52)
	share_btn.pressed.connect(_on_share_pressed)
	vbox.add_child(share_btn)

	# Play Again + Menu buttons
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	var play_again := Button.new()
	play_again.text = "Play Again"
	play_again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_again.custom_minimum_size = Vector2(0, 52)
	var menu_btn := Button.new()
	menu_btn.text = "Menu"
	menu_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_btn.custom_minimum_size = Vector2(0, 52)
	btn_row.add_child(play_again)
	btn_row.add_child(menu_btn)
	vbox.add_child(btn_row)

	var overlay := sheet.get_meta("overlay") as Control

	play_again.pressed.connect(func() -> void:
		_result_sheet_open = false
		_close_bottom_sheet(overlay, sheet)
		_on_play_again_pressed()
	)
	menu_btn.pressed.connect(func() -> void:
		_result_sheet_open = false
		_close_bottom_sheet(overlay, sheet)
		_on_result_menu_pressed()
	)

func _open_custom_puzzle_create() -> void:
	var sheet := _build_bottom_sheet("Create a Puzzle")
	var vbox := sheet.get_node("Content") as VBoxContainer

	var slot_row := HBoxContainer.new()
	slot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_row.add_theme_constant_override("separation", 8)
	var creator_slots: Array = []
	var creator_sequence: Array[int] = [-1, -1, -1, -1]
	var selected_slot_ref := [0]

	for _s in range(4):
		var slot := SlotButton.new()
		slot.custom_minimum_size = Vector2(56, 56)
		slot_row.add_child(slot)
		creator_slots.append(slot)
	vbox.add_child(slot_row)

	var palette_row := HBoxContainer.new()
	palette_row.alignment = BoxContainer.ALIGNMENT_CENTER
	palette_row.add_theme_constant_override("separation", 8)
	for ci in range(5):
		var btn := ColorDotButton.new()
		btn.color_index = ci
		btn.dot_color   = PALETTE[ci]["color"]
		btn.color_name  = str(PALETTE[ci]["name"])
		var captured_ci := ci
		btn.pressed.connect(func() -> void:
			var s := selected_slot_ref[0]
			if s < 4:
				creator_sequence[s] = captured_ci
				(creator_slots[s] as SlotButton).set_filled_visual(PALETTE[captured_ci]["color"], "")
				selected_slot_ref[0] = min(s + 1, 3)
		)
		palette_row.add_child(btn)
	vbox.add_child(palette_row)

	var generate_btn := Button.new()
	generate_btn.text = "Copy Code"
	generate_btn.custom_minimum_size = Vector2(0, 48)
	generate_btn.pressed.connect(func() -> void:
		if creator_sequence.has(-1):
			_show_toast("Fill all 4 slots first")
			return
		var code := _encode_custom_puzzle(creator_sequence)
		DisplayServer.clipboard_set(code)
		_show_toast("Code copied: %s" % code)
	)
	vbox.add_child(generate_btn)

func _open_custom_puzzle_play(code: String) -> void:
	var sequence := _decode_custom_puzzle(code)
	if sequence.is_empty():
		_show_toast("Invalid code — must start with GTD- and use 3-6 letters A-F")
		return
	# Set slot count before game starts so board builds correctly
	slots_needed = sequence.size()
	start_new_game(GameMode.CLASSIC)
	# Override the randomly-generated sequence with the custom one
	secret_sequence.clear()
	secret_sequence.assign(sequence)
	SaveData.custom_puzzles_played += 1
	SaveData.save()

func _on_share_pressed() -> void:
	var mode_name := GameMode.keys()[current_mode].capitalize()
	var text := DailyChallenge.build_share_text_general(
		mode_name, guess_history, secret_sequence,
		_last_game_won, MAX_GUESSES
	)
	DisplayServer.clipboard_set(text)
	_show_toast("Copied to clipboard!")
