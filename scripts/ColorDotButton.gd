class_name ColorDotButton
extends Button
## Palette dot button with neon glow ring, hover scale, and drag support.

var color_index: int = -1
var color_name: String = ""
var dot_color: Color = Color.WHITE
var is_selected: bool = false

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	text = ""
	custom_minimum_size = Vector2(100, 100)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = color_name
	_refresh_style()

func set_selected(is_selected: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.corner_radius_top_left    = 999
	sb.corner_radius_top_right   = 999
	sb.corner_radius_bottom_left  = 999
	sb.corner_radius_bottom_right = 999
	sb.bg_color = dot_color
	if is_selected:
		sb.border_color = Color(dot_color.r, dot_color.g, dot_color.b, 0.4)
		sb.border_width_left   = 3
		sb.border_width_right  = 3
		sb.border_width_top    = 3
		sb.border_width_bottom = 3
		scale = Vector2(1.12, 1.12)
	else:
		sb.border_width_left   = 0
		sb.border_width_right  = 0
		sb.border_width_top    = 0
		sb.border_width_bottom = 0
		scale = Vector2(1.0, 1.0)
	sb.shadow_color = Color(dot_color.r, dot_color.g, dot_color.b, 0.30)
	sb.shadow_size  = 8
	add_theme_stylebox_override("normal",  sb)
	add_theme_stylebox_override("hover",   sb)
	add_theme_stylebox_override("pressed", sb)

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := Panel.new()
	preview.custom_minimum_size = Vector2(72, 72)
	preview.size = Vector2(72, 72)
	preview.add_theme_stylebox_override("panel", _build_style(dot_color, true, true))
	set_drag_preview(preview)
	return {
		"type": "palette_color",
		"color_index": color_index,
	}

func _refresh_style() -> void:
	add_theme_stylebox_override("normal",   _build_style(dot_color, is_selected, false))
	add_theme_stylebox_override("hover",    _build_style(dot_color.lightened(0.18), is_selected, false))
	add_theme_stylebox_override("pressed",  _build_style(dot_color.darkened(0.18), is_selected, false))
	add_theme_stylebox_override("focus",    _build_style(dot_color, is_selected, false))
	add_theme_stylebox_override("disabled", _build_style(dot_color.darkened(0.35), false, false))

func _build_style(fill: Color, selected: bool, compact: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left     = 999
	style.corner_radius_top_right    = 999
	style.corner_radius_bottom_right = 999
	style.corner_radius_bottom_left  = 999
	# Glow ring: thin dark border normally, thick bright matching-color ring when selected
	if compact:
		style.border_width_left   = 3
		style.border_width_top    = 3
		style.border_width_right  = 3
		style.border_width_bottom = 3
		style.border_color = Color(1, 1, 1, 0.90)
	elif selected:
		style.border_width_left   = 7
		style.border_width_top    = 7
		style.border_width_right  = 7
		style.border_width_bottom = 7
		# Outer glow ring uses the dot's own color lightened
		style.border_color = fill.lightened(0.4)
		style.shadow_color = fill.lightened(0.2)
		style.shadow_size  = 10
	else:
		style.border_width_left   = 2
		style.border_width_top    = 2
		style.border_width_right  = 2
		style.border_width_bottom = 2
		style.border_color = Color(0, 0, 0, 0.35)
	return style
