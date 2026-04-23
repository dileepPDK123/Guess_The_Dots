class_name SlotButton
extends Button
## Circular guess slot. Empty: dashed pastel ring. Filled: vivid dot with soft shadow.

signal color_dropped(slot_index: int, color_index: int)
signal slot_pressed_for_assign(slot_index: int)

var slot_index: int = 0

const C_EMPTY_BORDER := Color("#E9D5F1")
const C_EMPTY_BG     := Color(1, 1, 1, 0.55)

var _is_filled: bool = false
var _filled_color: Color = Color.WHITE

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	text = ""
	custom_minimum_size = Vector2(64, 64)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pressed.connect(_on_pressed)
	set_empty_visual()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type", "") == "palette_color"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	color_dropped.emit(slot_index, int(data.get("color_index", -1)))

func set_empty_visual() -> void:
	_is_filled = false
	tooltip_text = "Empty — tap a color"
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_EMPTY_BG
	sb.border_color = C_EMPTY_BORDER
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 999
	sb.corner_radius_top_right = 999
	sb.corner_radius_bottom_left = 999
	sb.corner_radius_bottom_right = 999
	_apply_all(sb)

func set_filled_visual(dot_color: Color, color_name: String) -> void:
	_is_filled = true
	_filled_color = dot_color
	tooltip_text = "Placed: %s — tap to clear" % color_name
	var sb := StyleBoxFlat.new()
	sb.bg_color = dot_color
	sb.corner_radius_top_left = 999
	sb.corner_radius_top_right = 999
	sb.corner_radius_bottom_left = 999
	sb.corner_radius_bottom_right = 999
	sb.shadow_color = Color(dot_color.r, dot_color.g, dot_color.b, 0.35)
	sb.shadow_size = 6
	_apply_all(sb)

func _on_pressed() -> void:
	slot_pressed_for_assign.emit(slot_index)

func _apply_all(sb: StyleBoxFlat) -> void:
	add_theme_stylebox_override("normal", sb)
	add_theme_stylebox_override("hover", sb)
	add_theme_stylebox_override("pressed", sb)
	add_theme_stylebox_override("focus", sb)
	add_theme_stylebox_override("disabled", sb)
