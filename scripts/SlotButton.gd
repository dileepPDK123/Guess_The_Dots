class_name SlotButton
extends Button
## Guess slot button with neon scanning animation when empty.

signal color_dropped(slot_index: int, color_index: int)
signal slot_pressed_for_assign(slot_index: int)

var slot_index: int = 0

# Neon theme colors
const C_EMPTY_BG     := Color(0.05, 0.09, 0.17, 0.70)
const C_EMPTY_BORDER := Color(0.00, 0.90, 1.00, 0.30)  # faint cyan dashed feel
const C_FILLED_ALPHA := 0.65                             # filled border alpha

var _is_filled: bool = false
var _filled_color: Color = Color.WHITE
var _scan_tween: Tween = null

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	text = ""
	custom_minimum_size = Vector2(100, 100)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pressed.connect(_on_pressed)
	set_empty_visual()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type", "") == "palette_color"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	color_dropped.emit(slot_index, int(data.get("color_index", -1)))

func set_empty_visual() -> void:
	_is_filled = false
	tooltip_text = "Empty — tap a color to fill, or drag one here"
	_apply_all(_build_style(C_EMPTY_BG, C_EMPTY_BORDER, 2))
	_start_scan_anim()

func set_filled_visual(dot_color: Color, color_name: String) -> void:
	_is_filled = true
	_filled_color = dot_color
	tooltip_text = "Placed: %s — tap to clear" % color_name
	_stop_scan_anim()
	_apply_all(_build_style(dot_color, dot_color.lightened(0.25), 4))

func _on_pressed() -> void:
	slot_pressed_for_assign.emit(slot_index)

# ── Scanning animation (empty slots) ─────────────────────────────────────────
func _start_scan_anim() -> void:
	_stop_scan_anim()
	_scan_tween = create_tween().set_loops()
	_scan_tween.tween_method(_set_border_alpha, 0.18, 0.55, 0.75)\
		.set_ease(Tween.EASE_IN_OUT)
	_scan_tween.tween_method(_set_border_alpha, 0.55, 0.18, 0.75)\
		.set_ease(Tween.EASE_IN_OUT)

func _stop_scan_anim() -> void:
	if _scan_tween and _scan_tween.is_valid():
		_scan_tween.kill()
	_scan_tween = null

func _set_border_alpha(alpha: float) -> void:
	if _is_filled:
		return
	var border := Color(0.00, 0.90, 1.00, alpha)
	_apply_all(_build_style(C_EMPTY_BG, border, 2))

# ── Style builders ────────────────────────────────────────────────────────────
func _apply_all(style: StyleBoxFlat) -> void:
	add_theme_stylebox_override("normal",   style)
	add_theme_stylebox_override("hover",    style)
	add_theme_stylebox_override("pressed",  style)
	add_theme_stylebox_override("focus",    style)
	add_theme_stylebox_override("disabled", style)

func _build_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left     = 999
	style.corner_radius_top_right    = 999
	style.corner_radius_bottom_right = 999
	style.corner_radius_bottom_left  = 999
	style.border_width_left   = border_width
	style.border_width_top    = border_width
	style.border_width_right  = border_width
	style.border_width_bottom = border_width
	style.border_color = border
	return style
