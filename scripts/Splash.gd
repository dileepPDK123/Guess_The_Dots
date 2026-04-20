extends Control
## Splash.gd — Logo intro animation for Guess the Dots

const C_RED    := Color("#ef4444")
const C_BLUE   := Color("#3b82f6")
const C_GREEN  := Color("#22c55e")
const C_YELLOW := Color("#facc15")
const C_PURPLE := Color("#a855f7")
const C_BG     := Color(0.010, 0.018, 0.044, 1.0)

const DOT_R := 68.0   # corner dot radius (half-size)
const DOT_C := 58.0   # center dot radius
const GAP   := 140.0  # distance from screen-center to each corner dot center

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	layout_mode  = 1
	mouse_filter = MOUSE_FILTER_STOP
	# Wait one frame so the viewport rect is fully resolved
	await get_tree().process_frame
	_build_and_animate()

func _build_and_animate() -> void:
	var vp := get_viewport_rect().size  # e.g. 1080 × 1920
	var cx := vp.x * 0.5               # horizontal center
	var cy := vp.y * 0.5               # vertical center

	# ── Background (anchored, not animated — this is fine) ────────────────
	var bg := ColorRect.new()
	bg.layout_mode = 1
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color        = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# ── All animated nodes use layout_mode=0 (free / manual position) ─────
	#    position = top-left corner of the node
	#    pivot_offset = center of the node, so scale/rotation is from center

	# Corner dot final top-left positions (centered on their target point)
	#   Red    → center (cx-GAP, cy-GAP)
	#   Blue   → center (cx+GAP, cy-GAP)
	#   Green  → center (cx-GAP, cy+GAP)
	#   Yellow → center (cx+GAP, cy+GAP)
	var corner_data: Array = [
		# [color,    final_pos,                                  start_pos           ]
		[C_RED,    Vector2(cx - GAP - DOT_R, cy - GAP - DOT_R), Vector2(-DOT_R * 4, -DOT_R * 4)],
		[C_BLUE,   Vector2(cx + GAP - DOT_R, cy - GAP - DOT_R), Vector2(vp.x,       -DOT_R * 4)],
		[C_GREEN,  Vector2(cx - GAP - DOT_R, cy + GAP - DOT_R), Vector2(-DOT_R * 4,  vp.y      )],
		[C_YELLOW, Vector2(cx + GAP - DOT_R, cy + GAP - DOT_R), Vector2(vp.x,        vp.y      )],
	]

	var corner_dots: Array = []
	for entry in corner_data:
		var dot := _make_dot(entry[0] as Color, DOT_R, false)
		dot.layout_mode  = 0
		dot.position     = entry[2] as Vector2          # start off-screen
		dot.pivot_offset = Vector2(DOT_R, DOT_R)        # scale from center
		dot.modulate.a   = 0.0
		add_child(dot)
		corner_dots.append({"node": dot, "final": entry[1] as Vector2})

	# ── Center purple dot ─────────────────────────────────────────────────
	var center_dot := _make_dot(C_PURPLE, DOT_C, true)
	center_dot.layout_mode  = 0
	center_dot.position     = Vector2(cx - DOT_C, cy - DOT_C)
	center_dot.pivot_offset = Vector2(DOT_C, DOT_C)     # scale from center
	center_dot.scale        = Vector2(0.0, 0.0)
	center_dot.modulate.a   = 0.0
	add_child(center_dot)

	# ── Title label ───────────────────────────────────────────────────────
	var title_lbl := Label.new()
	title_lbl.text                 = "Guess the Dots"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 72)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0, 1.0))
	title_lbl.layout_mode          = 0
	var title_y := cy + GAP + DOT_R + 40.0
	title_lbl.position             = Vector2(0.0, title_y + 50.0)  # starts 50px lower
	title_lbl.size                 = Vector2(vp.x, 100.0)
	title_lbl.modulate.a           = 0.0
	add_child(title_lbl)

	# ── Tagline label ─────────────────────────────────────────────────────
	var tag_lbl := Label.new()
	tag_lbl.text                 = "Find the hidden pattern"
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.add_theme_font_size_override("font_size", 36)
	tag_lbl.add_theme_color_override("font_color", Color(0.60, 0.68, 0.84, 0.85))
	tag_lbl.layout_mode          = 0
	tag_lbl.position             = Vector2(0.0, title_y + 110.0)
	tag_lbl.size                 = Vector2(vp.x, 60.0)
	tag_lbl.modulate.a           = 0.0
	add_child(tag_lbl)

	# ── Fade overlay (on top of everything, fades in/out) ─────────────────
	var fade := ColorRect.new()
	fade.layout_mode  = 1
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color        = Color(0, 0, 0, 1.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)

	# ═════════════════════════════════════════════════════════════════════
	# Animation sequence
	# ═════════════════════════════════════════════════════════════════════

	# Phase 1 — fade in from black (0.0 → 0.55s)
	var tw_in := create_tween()
	tw_in.tween_property(fade, "modulate:a", 0.0, 0.55)

	# Phase 2 — corner dots fly in (starts 0.4s)
	for i in range(4):
		var entry: Dictionary = corner_dots[i]
		var dot: Control      = entry["node"]
		var final: Vector2    = entry["final"]

		var tw_a := create_tween()
		tw_a.tween_interval(0.40)
		tw_a.tween_property(dot, "modulate:a", 1.0, 0.15)

		var tw_p := create_tween()
		tw_p.tween_interval(0.40)
		tw_p.tween_property(dot, "position", final, 0.60)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	# Phase 3 — center dot pops in (1.10s)
	var tw_ca := create_tween()
	tw_ca.tween_interval(1.10)
	tw_ca.tween_property(center_dot, "modulate:a", 1.0, 0.10)

	var tw_cs := create_tween()
	tw_cs.tween_interval(1.10)
	tw_cs.tween_property(center_dot, "scale", Vector2(1.30, 1.30), 0.18)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_cs.tween_property(center_dot, "scale", Vector2(1.00, 1.00), 0.12)

	# Phase 4 — title slides up (1.35s)
	var tw_ta := create_tween()
	tw_ta.tween_interval(1.35)
	tw_ta.tween_property(title_lbl, "modulate:a", 1.0, 0.40)

	var tw_tp := create_tween()
	tw_tp.tween_interval(1.35)
	tw_tp.tween_property(title_lbl, "position:y", title_y, 0.40)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Phase 5 — tagline fades in (1.80s)
	var tw_tag := create_tween()
	tw_tag.tween_interval(1.80)
	tw_tag.tween_property(tag_lbl, "modulate:a", 1.0, 0.40)

	# Phase 6 — center dot gentle pulse (2.30s)
	var tw_pulse := create_tween()
	tw_pulse.tween_interval(2.30)
	tw_pulse.tween_property(center_dot, "scale", Vector2(1.10, 1.10), 0.40)\
		.set_ease(Tween.EASE_IN_OUT)
	tw_pulse.tween_property(center_dot, "scale", Vector2(1.00, 1.00), 0.40)\
		.set_ease(Tween.EASE_IN_OUT)

	# Phase 7 — fade to black and load Main (3.60s)
	var tw_out := create_tween()
	tw_out.tween_interval(3.60)
	tw_out.tween_property(fade, "modulate:a", 1.0, 0.55)
	tw_out.tween_callback(_go_to_main)

func _go_to_main() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

# ── Dot factory ───────────────────────────────────────────────────────────────
func _make_dot(color: Color, radius: float, with_ring: bool) -> Panel:
	var size  := radius * 2.0
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(size, size)
	panel.size                = Vector2(size, size)
	var s := StyleBoxFlat.new()
	s.bg_color                   = color
	s.corner_radius_top_left     = 999
	s.corner_radius_top_right    = 999
	s.corner_radius_bottom_left  = 999
	s.corner_radius_bottom_right = 999
	if with_ring:
		s.border_width_left   = 6
		s.border_width_top    = 6
		s.border_width_right  = 6
		s.border_width_bottom = 6
		s.border_color        = Color(1, 1, 1, 0.90)
	else:
		s.border_width_left   = 3
		s.border_width_top    = 3
		s.border_width_right  = 3
		s.border_width_bottom = 3
		s.border_color        = Color(1, 1, 1, 0.22)
	panel.add_theme_stylebox_override("panel", s)
	return panel
