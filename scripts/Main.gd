extends Control
## Main.gd — core game controller for Guess the Dots (NEURAL GRID build)
##
## Game modes:
##   CLASSIC  — 3-5 slots, 5 colors, 10 guesses, random every game
##   DAILY    — 4 slots, 5 colors, 8 guesses, date-seeded (once per day)
##   BLITZ    — 5 slots, 5 colors, unlimited guesses, 90-second timer
##   HARD     — 5-6 slots, 6 colors, 10 guesses; previous "exact" slots are locked
##   ZEN      — 4 slots, 5 colors, unlimited guesses, no timer, relaxed

enum GameMode { CLASSIC, BLITZ, HARD, ZEN, CAMPAIGN }

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
var current_mode: GameMode = GameMode.CLASSIC
var _blitz_time_remaining: float = BLITZ_TIME
var _blitz_timer_active: bool = false
var _hard_locked_slots: Array[int] = []  # slot indices locked from previous exact hits
var _current_campaign_level: int = 1
var _campaign_won: bool = false

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

# =============================================================================
func _process(delta: float) -> void:
	if not _blitz_timer_active or not round_active:
		return
	_blitz_time_remaining -= delta
	_blitz_time_remaining  = maxf(_blitz_time_remaining, 0.0)
	# Update counter label with countdown
	var secs := int(ceil(_blitz_time_remaining))
	guess_counter_label.text = "BLITZ  %02d:%02d" % [secs / 60, secs % 60]
	# Pulse red when under 15 seconds
	if _blitz_time_remaining <= 15.0:
		var flash := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.01)
		guess_counter_label.add_theme_color_override("font_color",
			Color(1.0, flash * 0.3, flash * 0.3, 1.0))
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
	hamburger_button.pressed.connect(_open_hamburger_menu)
	new_round_menu_button.pressed.connect(_on_new_round_from_menu)
	main_menu_menu_button.pressed.connect(_on_main_menu_from_menu)
	how_to_play_button.pressed.connect(_on_how_to_play_from_menu)
	close_menu_button.pressed.connect(_close_hamburger_menu)
	haptics_toggle.toggled.connect(_on_haptics_toggled)
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

	_show_menu()
	tutorial_layer.start()

	# Connect login streak reward signal — fires if today is a new day
	SaveData.login_streak_updated.connect(_on_login_streak_updated)

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
	hamburger_button.visible  = true
	hamburger_menu_layer.visible = false
	AdManager.hide_banner()
	round_active              = true
	_second_chance_used       = false
	_xp_doubler_active        = false
	_blitz_timer_active       = false
	_blitz_time_remaining     = BLITZ_TIME
	_hard_locked_slots.clear()
	selected_color_index      = -1
	guess_history.clear()
	secret_sequence.clear()

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
		GameMode.HARD:
			MAX_GUESSES  = MAX_GUESSES_HARD
			slots_needed = rng.randi_range(5, 6)
			_populate_sequence(6)
		GameMode.ZEN:
			MAX_GUESSES  = MAX_GUESSES_ZEN
			slots_needed = 4
			_populate_sequence(5)
		GameMode.CAMPAIGN:
			var cfg := _get_campaign_config(_current_campaign_level)
			MAX_GUESSES  = cfg["guesses"]
			slots_needed = cfg["slots"]
			_build_palette(cfg["colors"])  # override the pre-match palette call
			secret_sequence.assign(_campaign_sequence(_current_campaign_level, cfg["slots"], cfg["colors"]))

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

func _populate_sequence(color_count: int) -> void:
	for _i in range(slots_needed):
		secret_sequence.append(rng.randi_range(0, color_count - 1))

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
func _open_hamburger_menu() -> void:
	new_round_menu_button.disabled = round_active
	hamburger_menu_layer.visible = true

func _close_hamburger_menu() -> void:
	hamburger_menu_layer.visible = false

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
		palette_container.add_child(dot)
		palette_buttons.append(dot)

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
	# item format: {"values": Array[int], "exact": int, "misplaced": int}
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

func _apply_active_row(row: Dictionary) -> void:
	var slots: Array = row.slots
	for s in range(slots.size()):
		(slots[s] as Control).modulate.a = 1.0
		if s < current_guess.size() and current_guess[s] != -1:
			var color := PALETTE[current_guess[s]]["color"] as Color
			(slots[s] as SlotButton).set_filled_visual(color, "")
		else:
			(slots[s] as SlotButton).set_empty_visual()

func _apply_future_row(row: Dictionary) -> void:
	for slot in row.slots:
		(slot as SlotButton).set_empty_visual()
		(slot as Control).modulate.a = 0.2

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
	if not round_active:
		return
	if not AdManager.is_rewarded_ready():
		status_label.text = "HINT NOT AVAILABLE YET — RETRY SHORTLY."
		return
	AdManager.rewarded_earned.connect(_apply_hint, CONNECT_ONE_SHOT)
	var shown := AdManager.show_rewarded()
	if not shown:
		AdManager.rewarded_earned.disconnect(_apply_hint)
		status_label.text = "AD NOT READY — RETRY SHORTLY."

func _apply_hint() -> void:
	SaveData.hints_used += 1
	SaveData.ads_watched += 1
	SaveData.save()
	for i in range(slots_needed):
		if current_guess[i] != secret_sequence[i]:
			current_guess[i] = secret_sequence[i]
			_refresh_guess_ui()
			_update_palette_selection()
			status_label.text = "HINT COMPLETE — NODE %d REVEALED." % (i + 1)
			_vibrate(40)
			return
	status_label.text = "ALL NODES ALREADY CORRECT."

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
	})
	_vibrate(35)
	SoundManager.play("submit")

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
	else:
		for index in range(current_guess.size()):
			current_guess[index] = -1
	_refresh_guess_ui()
	_update_palette_selection()
	_update_header_text("LOCKED: %d  ·  MISALIGNED: %d" % [int(result["exact"]), int(result["misplaced"])])

# =============================================================================
# Core algorithm
# =============================================================================
func _evaluate_guess(guess: Array[int]) -> Dictionary:
	var exact := 0
	var secret_counts := {}
	var guess_counts  := {}
	for index in range(secret_sequence.size()):
		if guess[index] == secret_sequence[index]:
			exact += 1
		else:
			secret_counts[secret_sequence[index]] = secret_counts.get(secret_sequence[index], 0) + 1
			guess_counts[guess[index]]             = guess_counts.get(guess[index], 0) + 1
	var misplaced := 0
	for ci in guess_counts.keys():
		misplaced += min(int(guess_counts[ci]), int(secret_counts.get(ci, 0)))
	return {"exact": exact, "misplaced": misplaced}

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

# =============================================================================
# Game end
# =============================================================================
var _pending_xp: int     = 0
var _pending_coins: int  = 0
var _pending_levels: int = 0

func _finish_game(did_win: bool, message: String) -> void:
	if result_layer.visible:
		return  # already showing result — prevent double-call
	round_active        = false
	_blitz_timer_active = false
	_refresh_guess_ui()

	if did_win:
		_vibrate_win()
		SoundManager.play("win")
	else:
		_vibrate_lose()
		SoundManager.play("lose")

	SaveData.record_game(did_win, guess_history.size())

	# XP / coins calculation — stored as pending so callbacks can reference them
	_pending_xp = 15
	if did_win:
		_pending_xp += 50
		_pending_xp += (MAX_GUESSES - guess_history.size()) * 10
		if guess_history.size() <= 3:
			_pending_xp += 50
	if _xp_doubler_active:
		_pending_xp *= 2
	_pending_coins = 10 if did_win else 0
	if _xp_doubler_active:
		_pending_coins *= 2
	_pending_levels = SaveData.add_xp(_pending_xp)
	SaveData.add_coins(_pending_coins)

	_check_achievements_after_game(did_win)
	AdManager.on_game_finished()

	result_layer.visible = true
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
	_mode_select_layer = Control.new()
	_mode_select_layer.layout_mode = 1
	_mode_select_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mode_select_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_mode_select_layer.visible = false
	add_child(_mode_select_layer)

	var overlay := ColorRect.new()
	overlay.layout_mode = 1
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.78)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_mode_select_layer.add_child(overlay)

	var center := CenterContainer.new()
	center.layout_mode = 1
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mode_select_layer.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(720, 0)
	card.add_theme_stylebox_override("panel", _make_panel_style(C_PANEL))
	center.add_child(card)

	var cm := MarginContainer.new()
	cm.layout_mode = 2
	cm.add_theme_constant_override("margin_left",   36)
	cm.add_theme_constant_override("margin_right",  36)
	cm.add_theme_constant_override("margin_top",    36)
	cm.add_theme_constant_override("margin_bottom", 36)
	card.add_child(cm)

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 2
	vbox.add_theme_constant_override("separation", 16)
	cm.add_child(vbox)

	var title := Label.new()
	title.text = "SELECT PROTOCOL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0, 1.0))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var modes := [
		{
			"mode":  GameMode.CLASSIC,
			"name":  "CLASSIC",
			"sub":   "3–5 NODES  ·  5 COLORS  ·  10 ATTEMPTS",
			"desc":  "The standard protocol. Random length each round.",
			"color": Color(0.0, 0.9, 1.0, 1.0),
			"open_campaign": false,
		},
		{
			"mode":  GameMode.CAMPAIGN,
			"name":  "CAMPAIGN",
			"sub":   "100 LEVELS  ·  SCALING DIFFICULTY",
			"desc":  "Progress through 100 hand-crafted levels. Earn stars.",
			"color": Color(1.0, 0.84, 0.0, 1.0),
			"open_campaign": true,
		},
		{
			"mode":  GameMode.BLITZ,
			"name":  "BLITZ",
			"sub":   "5 NODES  ·  5 COLORS  ·  90 SECONDS",
			"desc":  "The clock is your enemy. Decrypt before time expires.",
			"color": Color(1.0, 0.35, 0.10, 1.0),
			"open_campaign": false,
		},
		{
			"mode":  GameMode.HARD,
			"name":  "HARD MODE",
			"sub":   "5–6 NODES  ·  6 COLORS  ·  LOCKED EXACT SLOTS",
			"desc":  "Adds Orange as 6th color. Exact slots carry forward locked.",
			"color": Color(1.0, 0.0, 0.43, 1.0),
			"open_campaign": false,
		},
		{
			"mode":  GameMode.ZEN,
			"name":  "ZEN",
			"sub":   "4 NODES  ·  5 COLORS  ·  UNLIMITED ATTEMPTS",
			"desc":  "No timer. No attempt limit. Pure decryption.",
			"color": Color(0.45, 0.88, 0.50, 1.0),
			"open_campaign": false,
		},
	]

	for data in modes:
		vbox.add_child(_make_mode_card(data, bool(data.get("open_campaign", false))))

	vbox.add_child(HSeparator.new())

	var cancel_btn := Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.custom_minimum_size = Vector2(0, 64)
	cancel_btn.pressed.connect(_close_mode_select)
	vbox.add_child(cancel_btn)

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
	_mode_select_layer.visible = true
	_mode_select_layer.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_mode_select_layer, "modulate:a", 1.0, 0.20)

func _close_mode_select() -> void:
	var tw := create_tween()
	tw.tween_property(_mode_select_layer, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func(): _mode_select_layer.visible = false)

func _on_mode_selected(mode_int: int) -> void:
	_close_mode_select()
	await get_tree().create_timer(0.20).timeout
	start_new_game(mode_int as GameMode)

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
