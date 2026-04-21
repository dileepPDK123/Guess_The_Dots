extends Control
## Tutorial.gd — First-run animated tutorial for Guess the Dots

signal tutorial_finished

const PALETTE := [
	{"name": "Red",    "color": Color("#ef4444")},
	{"name": "Blue",   "color": Color("#3b82f6")},
	{"name": "Green",  "color": Color("#22c55e")},
	{"name": "Yellow", "color": Color("#facc15")},
	{"name": "Purple", "color": Color("#a855f7")},
]

# Demo: Secret = Yellow(3) Blue(1) Red(0)
# Attempt 1: Red   Red   Red   → exact=1 spot=0
# Attempt 2: Yellow Red  Blue  → exact=1 spot=2
# Attempt 3: Yellow Blue Red   → exact=3 WIN
const DEMO_SECRET  := [3, 1, 0]
const DEMO_GUESSES := [[0, 0, 0], [3, 0, 1], [3, 1, 0]]
const DEMO_RESULTS := [
	{"exact": 1, "misplaced": 0},
	{"exact": 1, "misplaced": 2},
	{"exact": 3, "misplaced": 0},
]

const TOTAL_SLIDES := 15

var _progress_label: Label
var _progress_track: Panel
var _progress_fill:  Panel
var _content_box:    VBoxContainer
var _skip_btn:       Button
var _next_btn:       Button

var _slide:      int  = 0
var _animating:  bool = false
var _anim_slots: Array = []

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	layout_mode  = 1
	mouse_filter = MOUSE_FILTER_STOP
	_build_shell()
	visible = false

func start() -> void:
	_slide = 0
	visible = true
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.35)
	tw.tween_callback(func(): _show_slide(0))

func _done() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.28)
	tw.tween_callback(func():
		visible = false
		tutorial_finished.emit()
	)

# ─────────────────────────────────────────────────────────────────────────────
# Shell (built once)
# ─────────────────────────────────────────────────────────────────────────────
func _build_shell() -> void:
	var bg := ColorRect.new()
	bg.layout_mode = 1
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color        = Color("#FFF1F9")
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center := CenterContainer.new()
	center.layout_mode = 1
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(840, 0)
	var _card_sb := StyleBoxFlat.new()
	_card_sb.bg_color = Color(1.0, 1.0, 1.0, 0.97)
	_card_sb.border_color = Color("#FFD6E7")
	_card_sb.border_width_left = _card_sb.border_width_right = _card_sb.border_width_top = _card_sb.border_width_bottom = 1
	_card_sb.corner_radius_top_left = _card_sb.corner_radius_top_right = 24
	_card_sb.corner_radius_bottom_left = _card_sb.corner_radius_bottom_right = 24
	card.add_theme_stylebox_override("panel", _card_sb)
	center.add_child(card)

	var cm := MarginContainer.new()
	cm.layout_mode = 2
	cm.add_theme_constant_override("margin_left",   44)
	cm.add_theme_constant_override("margin_right",  44)
	cm.add_theme_constant_override("margin_top",    44)
	cm.add_theme_constant_override("margin_bottom", 44)
	card.add_child(cm)

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 2
	vbox.add_theme_constant_override("separation", 20)
	cm.add_child(vbox)

	# Progress row
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 16)
	vbox.add_child(prow)

	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 26)
	_progress_label.add_theme_color_override("font_color", Color("#9B7EA6"))
	_progress_label.custom_minimum_size = Vector2(110, 0)
	_progress_label.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	prow.add_child(_progress_label)

	_progress_track = Panel.new()
	_progress_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_track.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	_progress_track.custom_minimum_size   = Vector2(0, 7)
	var ts := StyleBoxFlat.new()
	ts.bg_color                  = Color("#FFD6E7")
	ts.corner_radius_top_left    = 999
	ts.corner_radius_top_right   = 999
	ts.corner_radius_bottom_left = 999
	ts.corner_radius_bottom_right = 999
	_progress_track.add_theme_stylebox_override("panel", ts)
	prow.add_child(_progress_track)

	_progress_fill = Panel.new()
	_progress_fill.layout_mode    = 1
	_progress_fill.anchor_left    = 0.0
	_progress_fill.anchor_right   = 0.0
	_progress_fill.anchor_top     = 0.0
	_progress_fill.anchor_bottom  = 1.0
	_progress_fill.offset_right   = 0.0
	var fs := StyleBoxFlat.new()
	fs.bg_color                  = Color("#E0B3FF")
	fs.corner_radius_top_left    = 999
	fs.corner_radius_top_right   = 999
	fs.corner_radius_bottom_left = 999
	fs.corner_radius_bottom_right = 999
	_progress_fill.add_theme_stylebox_override("panel", fs)
	_progress_track.add_child(_progress_fill)

	# Scrollable content
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size    = Vector2(0, 660)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	vbox.add_child(scroll)

	_content_box = VBoxContainer.new()
	_content_box.layout_mode           = 2
	_content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.add_theme_constant_override("separation", 26)
	scroll.add_child(_content_box)

	# Separator
	var sep   := HSeparator.new()
	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color("#FFD6E7")
	sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	# Bottom buttons
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 18)
	vbox.add_child(brow)

	_skip_btn = Button.new()
	_skip_btn.text = "SKIP BRIEFING"
	_skip_btn.custom_minimum_size = Vector2(220, 76)
	_bsty(_skip_btn, Color("#F5E6FA"), Color("#FFD6E7"))
	_skip_btn.add_theme_color_override("font_color",       Color("#9B7EA6"))
	_skip_btn.add_theme_color_override("font_hover_color", Color("#6B4E71"))
	_skip_btn.add_theme_font_size_override("font_size", 28)
	_skip_btn.pressed.connect(_done)
	brow.add_child(_skip_btn)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brow.add_child(sp)

	_next_btn = Button.new()
	_next_btn.text = "PROCEED  →"
	_next_btn.custom_minimum_size = Vector2(270, 76)
	_bsty(_next_btn, Color("#E0B3FF"), Color("#FFD6E7"))
	_next_btn.add_theme_color_override("font_color",       Color("#6B4E71"))
	_next_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	_next_btn.add_theme_font_size_override("font_size", 30)
	_next_btn.pressed.connect(_on_next)
	brow.add_child(_next_btn)

# ─────────────────────────────────────────────────────────────────────────────
# Navigation
# ─────────────────────────────────────────────────────────────────────────────
func _on_next() -> void:
	if _animating:
		return
	if _slide >= TOTAL_SLIDES - 1:
		_done()
		return
	_slide += 1
	_show_slide(_slide)

func _show_slide(index: int) -> void:
	_next_btn.text    = "INITIALIZE  ▶" if index == TOTAL_SLIDES - 1 else "PROCEED  →"
	_skip_btn.visible = index < TOTAL_SLIDES - 1
	_progress_label.text = "%d / %d" % [index + 1, TOTAL_SLIDES]

	_animating = true
	var tw := create_tween()
	tw.tween_property(_content_box, "modulate:a", 0.0, 0.14)
	tw.tween_callback(func():
		for ch in _content_box.get_children():
			ch.queue_free()
		_anim_slots.clear()
		_build_page(index)
		_content_box.modulate.a = 0.0
		var tw2 := create_tween()
		tw2.tween_property(_content_box, "modulate:a", 1.0, 0.22)
		tw2.tween_callback(func():
			_update_progress_bar(float(index + 1) / float(TOTAL_SLIDES))
			if index in [8, 10, 12] and not _anim_slots.is_empty():
				_run_placing_animation()
			else:
				_animating = false
		)
	)

func _update_progress_bar(ratio: float) -> void:
	await get_tree().process_frame
	var w := _progress_track.size.x
	if w <= 0.0:
		await get_tree().process_frame
		w = _progress_track.size.x
	var tw := create_tween()
	tw.tween_property(_progress_fill, "offset_right", w * ratio, 0.40)

func _run_placing_animation() -> void:
	_next_btn.disabled = true
	for i in range(_anim_slots.size()):
		await get_tree().create_timer(0.30).timeout
		var entry: Dictionary = _anim_slots[i]
		var panel: Panel      = entry["panel"]
		var cidx:  int        = entry["cidx"]
		panel.add_theme_stylebox_override("panel", _dot_style(PALETTE[cidx]["color"]))
		panel.scale = Vector2(0.15, 0.15)
		var tw := create_tween()
		tw.tween_property(panel, "scale", Vector2(1.15, 1.15), 0.13)
		tw.tween_property(panel, "scale", Vector2(1.00, 1.00), 0.10)
	await get_tree().create_timer(0.35).timeout
	_next_btn.disabled = false
	_animating         = false

# ─────────────────────────────────────────────────────────────────────────────
# Page router
# ─────────────────────────────────────────────────────────────────────────────
func _build_page(index: int) -> void:
	match index:
		0:  _page_welcome()
		1:  _page_secret_code()
		2:  _page_placing()
		3:  _page_green()
		4:  _page_yellow()
		5:  _page_nomatch()
		6:  _page_tips()
		7:  _page_demo_intro()
		8:  _page_demo_placing(0)
		9:  _page_demo_result(0)
		10: _page_demo_placing(1)
		11: _page_demo_result(1)
		12: _page_demo_placing(2)
		13: _page_demo_win()
		14: _page_ready()

# ─────────────────────────────────────────────────────────────────────────────
# Static pages
# ─────────────────────────────────────────────────────────────────────────────
func _page_welcome() -> void:
	_add_title("WELCOME, AGENT\nGUESS THE DOTS", 44)
	var center := CenterContainer.new()
	_content_box.add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	center.add_child(row)
	for i in range(5):
		var d := _dot_panel(PALETTE[i]["color"], 80)
		d.modulate.a = 0.0
		d.scale      = Vector2(0.2, 0.2)
		row.add_child(d)
		var tw_a := create_tween()
		tw_a.tween_interval(i * 0.10)
		tw_a.tween_property(d, "modulate:a", 1.0, 0.20)
		var tw_s := create_tween()
		tw_s.tween_interval(i * 0.10)
		tw_s.tween_property(d, "scale", Vector2(1.0, 1.0), 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_add_spacer(8)
	_add_body("Crack a hidden neural sequence of colored nodes\nbefore your 10 attempts expire.\n\nThis briefing takes 60 seconds — full coverage guaranteed.")

func _page_secret_code() -> void:
	_add_title("THE ENCRYPTED SEQUENCE 🔒")
	_add_body("Each round, a secret sequence of 3 to 5 colored nodes\nis encrypted and hidden from you.")
	var c := CenterContainer.new()
	_content_box.add_child(c)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	c.add_child(row)
	for i in range(4):
		var m := _mystery_dot(72)
		m.scale      = Vector2(0.3, 0.3)
		m.modulate.a = 0.0
		row.add_child(m)
		var tw_a := create_tween()
		tw_a.tween_interval(i * 0.12)
		tw_a.tween_property(m, "modulate:a", 1.0, 0.20)
		var tw_s := create_tween()
		tw_s.tween_interval(i * 0.12)
		tw_s.tween_property(m, "scale", Vector2(1.0, 1.0), 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_add_spacer(6)
	_add_callout("Your goal: decode the EXACT colors AND their positions!", Color(0.26, 0.58, 1.0, 1.0))
	_add_body("Node colors CAN repeat — the same color may appear\nmore than once in the sequence.")

func _page_placing() -> void:
	_add_title("NODE PLACEMENT 🎨")
	_add_body("Tap any node in the COLOR MATRIX.\nIt auto-fills the next empty slot — left to right.")
	var c := CenterContainer.new()
	_content_box.add_child(c)
	var vis := HBoxContainer.new()
	vis.add_theme_constant_override("separation", 22)
	vis.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(vis)
	var pal_col := VBoxContainer.new()
	pal_col.add_theme_constant_override("separation", 10)
	vis.add_child(pal_col)
	_lbl_into(pal_col, "MATRIX", 24, Color(0.70, 0.76, 0.87, 0.85))
	var pal_row := HBoxContainer.new()
	pal_row.add_theme_constant_override("separation", 10)
	pal_col.add_child(pal_row)
	for i in range(5):
		pal_row.add_child(_dot_panel(PALETTE[i]["color"], 56))
	var arr := Label.new()
	arr.text = "→"
	arr.add_theme_font_size_override("font_size", 44)
	arr.add_theme_color_override("font_color", Color(0.26, 0.58, 1.0, 0.9))
	arr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vis.add_child(arr)
	var sl_col := VBoxContainer.new()
	sl_col.add_theme_constant_override("separation", 10)
	vis.add_child(sl_col)
	_lbl_into(sl_col, "SEQUENCE", 24, Color(0.70, 0.76, 0.87, 0.85))
	var sl_row := HBoxContainer.new()
	sl_row.add_theme_constant_override("separation", 10)
	sl_col.add_child(sl_row)
	sl_row.add_child(_dot_panel(PALETTE[0]["color"], 56))
	sl_row.add_child(_dot_panel(PALETTE[2]["color"], 56))
	sl_row.add_child(_empty_slot_panel(56))
	sl_row.add_child(_empty_slot_panel(56))
	_add_spacer(4)
	_add_callout("Or DRAG a node directly onto any specific slot!", Color(0.94, 0.70, 0.18, 1.0))
	_add_body("Tap any filled slot to clear it — easy to correct errors.")

func _page_green() -> void:
	_add_title("◆ LOCKED — EXACT POSITION 🟢")
	_add_body("After TRANSMITTING your sequence, feedback nodes appear.\nGREEN ◆ = correct color AND correct position — LOCKED.")
	var c := CenterContainer.new()
	_content_box.add_child(c)
	c.add_child(_example_row([2, 0, 2, 1], 2, 0))
	_add_callout("2 LOCKED = 2 nodes in perfect position! Maximize your lock count.", Color(0.28, 0.88, 0.48, 1.0))
	_add_body("All LOCKED = SEQUENCE DECODED — YOU WIN! 🎉")

func _page_yellow() -> void:
	_add_title("◆ MISPLACED — EXISTS IN SEQUENCE 🟡")
	_add_body("YELLOW ◆ = the node EXISTS in the secret sequence,\nbut it is in the WRONG slot. Reposition it!")
	var c := CenterContainer.new()
	_content_box.add_child(c)
	c.add_child(_example_row([1, 3, 0, 4], 0, 3))
	_add_callout("3 MISPLACED = 3 right nodes, all in wrong slots!", Color(0.96, 0.74, 0.18, 1.0))
	_add_body("Rearrange those nodes in your next sequence.")

func _page_nomatch() -> void:
	_add_title("◆ NULL SIGNAL — NOT IN SEQUENCE ⚫")
	_add_body("NULL SIGNAL means none of those nodes exist\nanywhere in the encrypted sequence.")
	var c := CenterContainer.new()
	_content_box.add_child(c)
	c.add_child(_example_row([0, 0, 0, 0], 0, 0))
	_add_callout("Eliminate those nodes from analysis — zero presence in the sequence.", Color(0.65, 0.65, 0.76, 0.90))
	_add_body("NULL SIGNAL is still intel — it eliminates nodes entirely.")

func _page_tips() -> void:
	_add_title("INTEL BRIEFING 💡")
	_add_spacer(8)
	var tips := [
		["🔁", "Node colors CAN repeat in the sequence"],
		["🔢", "You have 10 attempts per round"],
		["👆", "Tap a filled slot to clear just that one node"],
		["💡", "SCAN [AD] reveals 1 hidden node — tap the SCAN button"],
		["👀", "Run out of attempts? The sequence is always revealed"],
		["🎯", "3 to 5 nodes per round — length is randomised!"],
	]
	for tip in tips:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 18)
		_content_box.add_child(r)
		var ico := Label.new()
		ico.text = tip[0]
		ico.add_theme_font_size_override("font_size", 34)
		ico.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
		ico.custom_minimum_size = Vector2(52, 0)
		r.add_child(ico)
		var txt := Label.new()
		txt.text = tip[1]
		txt.add_theme_font_size_override("font_size", 28)
		txt.add_theme_color_override("font_color", Color(0.87, 0.90, 0.96, 1.0))
		txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		txt.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
		txt.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
		r.add_child(txt)

func _page_demo_intro() -> void:
	_add_title("SIMULATION INBOUND 🕹️", 40)
	_add_body("Simulating a 3-node sequence. Watch how each feedback clue\nnarrows the decryption step by step.")
	_add_spacer(16)
	var c := CenterContainer.new()
	_content_box.add_child(c)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	c.add_child(row)
	for i in range(3):
		var m := _mystery_dot(84)
		m.scale      = Vector2(0.3, 0.3)
		m.modulate.a = 0.0
		row.add_child(m)
		var tw_a := create_tween()
		tw_a.tween_interval(i * 0.14)
		tw_a.tween_property(m, "modulate:a", 1.0, 0.20)
		var tw_s := create_tween()
		tw_s.tween_interval(i * 0.14)
		tw_s.tween_property(m, "scale", Vector2(1.0, 1.0), 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_add_spacer(12)
	_add_callout("3 nodes encrypted above — can you decode the sequence?", Color(0.26, 0.58, 1.0, 1.0))
	_add_body("Tap PROCEED to begin ATTEMPT 01.")

func _page_demo_placing(attempt: int) -> void:
	var titles := ["ATTEMPT 01 — INITIATING", "ATTEMPT 02 — APPLYING INTEL", "ATTEMPT 03 — FINAL DECRYPT"]
	var bodies  := [
		"No data yet — transmitting Red in all slots\nto gather initial feedback.",
		"Slot 3 is LOCKED (Red confirmed).\nNow route Yellow to slot 1 and relocate Blue.",
		"Intel confirmed:\n  LOCKED: Yellow is perfect in slot 1\n  MISPLACED: Red and Blue need to swap!\nFinal sequence: Yellow, Blue, Red",
	]
	_add_title(titles[attempt], 38)
	_add_body(bodies[attempt])
	_add_spacer(8)
	_add_demo_board(attempt, false)

func _page_demo_result(attempt: int) -> void:
	var titles := ["ATTEMPT 01 — FEEDBACK RECEIVED", "ATTEMPT 02 — FEEDBACK RECEIVED"]
	var bodies  := [
		"1 LOCKED node!\nRed is perfectly positioned in slot 3.",
		"1 LOCKED (Yellow confirmed in slot 1!) plus\n2 MISPLACED — Red and Blue need to swap!",
	]
	_add_title(titles[attempt], 38)
	_add_body(bodies[attempt])
	_add_spacer(8)
	_add_demo_board(attempt, true)
	_add_spacer(4)
	var r: Dictionary = DEMO_RESULTS[attempt]
	var e := int(r["exact"])
	var m := int(r["misplaced"])
	if e > 0 and m == 0:
		_add_callout("Green x%d = %d color%s in the EXACT right spot!" % [e, e, "s" if e > 1 else ""], Color(0.28, 0.88, 0.48, 1.0))
	elif e > 0 and m > 0:
		_add_callout("Green x%d exact  +  Yellow x%d wrong spot — almost there!" % [e, m], Color(0.60, 0.80, 0.38, 1.0))

func _page_demo_win() -> void:
	_add_title("SEQUENCE DECODED! 🎉", 44)
	_add_body("All 3 nodes LOCKED — perfect decrypt!\nThe sequence was: Yellow, Blue, Red")
	_add_spacer(8)
	_add_demo_board(2, true)
	_add_spacer(8)
	_add_callout("ALL LOCKED = PERFECT DECRYPT — SEQUENCE DECODED! 🏆", Color(0.28, 0.88, 0.48, 1.0))

func _page_ready() -> void:
	_add_title("AGENT INITIALIZED 🚀", 44)
	_add_spacer(18)
	var c := CenterContainer.new()
	_content_box.add_child(c)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	c.add_child(row)
	for i in range(5):
		var d := _dot_panel(PALETTE[i]["color"], 90)
		d.modulate.a = 0.0
		d.scale      = Vector2(0.2, 0.2)
		row.add_child(d)
		var tw_a := create_tween()
		tw_a.tween_interval(i * 0.09)
		tw_a.tween_property(d, "modulate:a", 1.0, 0.20)
		var tw_s := create_tween()
		tw_s.tween_interval(i * 0.09)
		tw_s.tween_property(d, "scale", Vector2(1.0, 1.0), 0.30).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_add_spacer(20)
	_add_body("Quick intel:\nGREEN ◆ = correct node, correct slot\nYELLOW ◆ = correct node, wrong slot\nNULL SIGNAL = that node is not in the sequence\n\nDecrypt the sequence — good luck, Agent! 🎯")

# ─────────────────────────────────────────────────────────────────────────────
# Demo board
# ─────────────────────────────────────────────────────────────────────────────
func _add_demo_board(attempt: int, show_result: bool) -> void:
	var board := PanelContainer.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.add_theme_stylebox_override("panel", _ps(Color(0.050, 0.075, 0.130, 1.0), 18))
	_content_box.add_child(board)

	var bm := MarginContainer.new()
	bm.layout_mode = 2
	bm.add_theme_constant_override("margin_left",   22)
	bm.add_theme_constant_override("margin_right",  22)
	bm.add_theme_constant_override("margin_top",    22)
	bm.add_theme_constant_override("margin_bottom", 22)
	board.add_child(bm)

	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 16)
	bm.add_child(bv)

	# Header
	var hdr := HBoxContainer.new()
	bv.add_child(hdr)
	var hdr_lbl := Label.new()
	hdr_lbl.text = "SIMULATION ROUND"
	hdr_lbl.add_theme_font_size_override("font_size", 26)
	hdr_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.86, 0.85))
	hdr.add_child(hdr_lbl)
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(hsp)
	var sec_lbl := Label.new()
	sec_lbl.text = "SEQUENCE: [ENCRYPTED]"
	sec_lbl.add_theme_font_size_override("font_size", 26)
	sec_lbl.add_theme_color_override("font_color", Color(0.48, 0.54, 0.68, 0.80))
	hdr.add_child(sec_lbl)

	# History rows
	var rows_count := attempt if not show_result else attempt + 1
	for i in range(rows_count):
		bv.add_child(_demo_history_row(i))

	# Current guess slots (when not yet submitted)
	if not show_result:
		var sep := HSeparator.new()
		var ss  := StyleBoxFlat.new()
		ss.bg_color = Color(1, 1, 1, 0.08)
		sep.add_theme_stylebox_override("separator", ss)
		bv.add_child(sep)

		var lbl := Label.new()
		lbl.text = "ATTEMPT %d OF 10:" % (attempt + 1)
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", Color(0.62, 0.68, 0.82, 0.80))
		bv.add_child(lbl)

		var sc := CenterContainer.new()
		bv.add_child(sc)
		var sr := HBoxContainer.new()
		sr.add_theme_constant_override("separation", 18)
		sc.add_child(sr)

		var guess: Array = DEMO_GUESSES[attempt]
		for j in range(3):
			var slot := Panel.new()
			slot.custom_minimum_size = Vector2(72, 72)
			slot.size = Vector2(72, 72)
			slot.add_theme_stylebox_override("panel", _empty_slot_style())
			sr.add_child(slot)
			_anim_slots.append({"panel": slot, "cidx": guess[j]})

		var rem_center := CenterContainer.new()
		bv.add_child(rem_center)
		var rem_lbl := Label.new()
		rem_lbl.text = "%d ATTEMPTS REMAINING" % (10 - attempt)
		rem_lbl.add_theme_font_size_override("font_size", 24)
		rem_lbl.add_theme_color_override("font_color", Color(0.94, 0.93, 0.64, 0.90))
		rem_center.add_child(rem_lbl)

func _demo_history_row(attempt: int) -> Control:
	var r: Dictionary = DEMO_RESULTS[attempt]
	var exact := int(r["exact"])
	var mis   := int(r["misplaced"])

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _ps(Color(0.09, 0.13, 0.22, 0.90), 14))

	var mm := MarginContainer.new()
	mm.layout_mode = 2
	mm.add_theme_constant_override("margin_left",   12)
	mm.add_theme_constant_override("margin_right",  12)
	mm.add_theme_constant_override("margin_top",    12)
	mm.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(mm)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	mm.add_child(row)

	var num := Label.new()
	num.text = "#%d" % (attempt + 1)
	num.add_theme_font_size_override("font_size", 24)
	num.add_theme_color_override("font_color", Color(0.60, 0.66, 0.80, 0.80))
	num.custom_minimum_size = Vector2(46, 0)
	num.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	row.add_child(num)

	var dr := HBoxContainer.new()
	dr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dr.add_theme_constant_override("separation", 10)
	row.add_child(dr)
	for v in DEMO_GUESSES[attempt]:
		dr.add_child(_dot_panel(PALETTE[int(v)]["color"], 34))

	var fb := VBoxContainer.new()
	fb.alignment = BoxContainer.ALIGNMENT_CENTER
	fb.custom_minimum_size = Vector2(130, 0)
	row.add_child(fb)

	if exact == 0 and mis == 0:
		var nl := Label.new()
		nl.text = "NULL SIGNAL"
		nl.add_theme_font_size_override("font_size", 22)
		nl.add_theme_color_override("font_color", Color(0.58, 0.58, 0.68, 0.80))
		fb.add_child(nl)
	else:
		if exact > 0:
			var er := HBoxContainer.new()
			er.add_theme_constant_override("separation", 6)
			fb.add_child(er)
			var el := Label.new()
			el.text = "%d LOCKED" % exact
			el.add_theme_font_size_override("font_size", 22)
			el.add_theme_color_override("font_color", Color(0.28, 0.88, 0.48, 1.0))
			er.add_child(el)
			for _i in range(exact):
				er.add_child(_pip(Color(0.28, 0.88, 0.48, 1.0)))
		if mis > 0:
			var mr := HBoxContainer.new()
			mr.add_theme_constant_override("separation", 6)
			fb.add_child(mr)
			var ml := Label.new()
			ml.text = "%d SHIFTED" % mis
			ml.add_theme_font_size_override("font_size", 22)
			ml.add_theme_color_override("font_color", Color(0.96, 0.74, 0.18, 1.0))
			mr.add_child(ml)
			for _i in range(mis):
				mr.add_child(_pip(Color(0.96, 0.74, 0.18, 1.0)))

	return panel

# ─────────────────────────────────────────────────────────────────────────────
# Example result row for static pages
# ─────────────────────────────────────────────────────────────────────────────
func _example_row(values: Array, exact: int, mis: int) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _ps(Color(0.060, 0.085, 0.145, 1.0), 18))

	var mm := MarginContainer.new()
	mm.layout_mode = 2
	mm.add_theme_constant_override("margin_left",   18)
	mm.add_theme_constant_override("margin_right",  18)
	mm.add_theme_constant_override("margin_top",    18)
	mm.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(mm)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	mm.add_child(row)

	var dr := HBoxContainer.new()
	dr.add_theme_constant_override("separation", 12)
	row.add_child(dr)
	for v in values:
		dr.add_child(_dot_panel(PALETTE[int(v)]["color"], 54))

	var arr := Label.new()
	arr.text = "→"
	arr.add_theme_font_size_override("font_size", 38)
	arr.add_theme_color_override("font_color", Color(0.60, 0.65, 0.78, 0.75))
	arr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(arr)

	var fb := VBoxContainer.new()
	fb.alignment = BoxContainer.ALIGNMENT_CENTER
	fb.custom_minimum_size = Vector2(150, 0)
	row.add_child(fb)

	if exact == 0 and mis == 0:
		var nl := Label.new()
		nl.text = "NULL SIGNAL"
		nl.add_theme_font_size_override("font_size", 26)
		nl.add_theme_color_override("font_color", Color(0.58, 0.58, 0.70, 0.85))
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fb.add_child(nl)
	else:
		if exact > 0:
			var er := HBoxContainer.new()
			er.add_theme_constant_override("separation", 8)
			fb.add_child(er)
			for i in range(exact):
				var p := _pip(Color(0.28, 0.88, 0.48, 1.0), 22)
				p.scale = Vector2(0.2, 0.2)
				er.add_child(p)
				var tw := create_tween()
				tw.tween_interval(i * 0.12)
				tw.tween_property(p, "scale", Vector2(1.15, 1.15), 0.14).set_trans(Tween.TRANS_BACK)
				tw.tween_property(p, "scale", Vector2(1.00, 1.00), 0.10)
			var el := Label.new()
			el.text = " LOCKED"
			el.add_theme_font_size_override("font_size", 24)
			el.add_theme_color_override("font_color", Color(0.28, 0.88, 0.48, 1.0))
			er.add_child(el)
		if mis > 0:
			var mr := HBoxContainer.new()
			mr.add_theme_constant_override("separation", 8)
			fb.add_child(mr)
			for i in range(mis):
				var p := _pip(Color(0.96, 0.74, 0.18, 1.0), 22)
				p.scale = Vector2(0.2, 0.2)
				mr.add_child(p)
				var tw := create_tween()
				tw.tween_interval(i * 0.12)
				tw.tween_property(p, "scale", Vector2(1.15, 1.15), 0.14).set_trans(Tween.TRANS_BACK)
				tw.tween_property(p, "scale", Vector2(1.00, 1.00), 0.10)
			var ml := Label.new()
			ml.text = " SHIFTED"
			ml.add_theme_font_size_override("font_size", 24)
			ml.add_theme_color_override("font_color", Color(0.96, 0.74, 0.18, 1.0))
			mr.add_child(ml)

	return panel

# ─────────────────────────────────────────────────────────────────────────────
# Content helpers
# ─────────────────────────────────────────────────────────────────────────────
func _add_title(text: String, size: int = 40) -> void:
	var lbl := Label.new()
	lbl.text                 = text
	lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.97, 1.00, 1.0))
	_content_box.add_child(lbl)

func _add_body(text: String) -> void:
	var lbl := Label.new()
	lbl.text                 = text
	lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(0.80, 0.84, 0.93, 0.92))
	_content_box.add_child(lbl)

func _add_callout(text: String, color: Color) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s := StyleBoxFlat.new()
	s.bg_color              = Color(color.r, color.g, color.b, 0.14)
	s.border_width_left     = 2
	s.border_width_top      = 2
	s.border_width_right    = 2
	s.border_width_bottom   = 2
	s.border_color          = Color(color.r, color.g, color.b, 0.55)
	s.corner_radius_top_left     = 14
	s.corner_radius_top_right    = 14
	s.corner_radius_bottom_left  = 14
	s.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", s)
	_content_box.add_child(panel)

	var cm := MarginContainer.new()
	cm.layout_mode = 2
	cm.add_theme_constant_override("margin_left",   14)
	cm.add_theme_constant_override("margin_right",  14)
	cm.add_theme_constant_override("margin_top",    14)
	cm.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(cm)

	var lbl := Label.new()
	lbl.text                 = text
	lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 27)
	lbl.add_theme_color_override("font_color", Color(color.r, color.g, color.b, 1.0).lightened(0.20))
	cm.add_child(lbl)

func _add_spacer(h: int) -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	_content_box.add_child(c)

func _lbl_into(parent: Control, text: String, size: int, color: Color) -> void:
	var lbl := Label.new()
	lbl.text                 = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)

# ─────────────────────────────────────────────────────────────────────────────
# Visual builders
# ─────────────────────────────────────────────────────────────────────────────
func _dot_panel(color: Color, size: int) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(size, size)
	p.size = Vector2(size, size)
	p.add_theme_stylebox_override("panel", _dot_style(color))
	return p

func _dot_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color                   = color
	s.corner_radius_top_left     = 999
	s.corner_radius_top_right    = 999
	s.corner_radius_bottom_left  = 999
	s.corner_radius_bottom_right = 999
	s.border_width_left          = 2
	s.border_width_top           = 2
	s.border_width_right         = 2
	s.border_width_bottom        = 2
	s.border_color               = Color(1, 1, 1, 0.22)
	return s

func _empty_slot_panel(size: int) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(size, size)
	p.size = Vector2(size, size)
	p.add_theme_stylebox_override("panel", _empty_slot_style())
	return p

func _empty_slot_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color                   = Color(0.15, 0.20, 0.34, 0.50)
	s.corner_radius_top_left     = 999
	s.corner_radius_top_right    = 999
	s.corner_radius_bottom_left  = 999
	s.corner_radius_bottom_right = 999
	s.border_width_left          = 3
	s.border_width_top           = 3
	s.border_width_right         = 3
	s.border_width_bottom        = 3
	s.border_color               = Color(1, 1, 1, 0.45)
	return s

func _mystery_dot(size: int) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(size, size)
	p.size = Vector2(size, size)
	var s := StyleBoxFlat.new()
	s.bg_color                   = Color(0.12, 0.16, 0.28, 0.85)
	s.corner_radius_top_left     = 999
	s.corner_radius_top_right    = 999
	s.corner_radius_bottom_left  = 999
	s.corner_radius_bottom_right = 999
	s.border_width_left          = 3
	s.border_width_top           = 3
	s.border_width_right         = 3
	s.border_width_bottom        = 3
	s.border_color               = Color(0.40, 0.50, 0.70, 0.55)
	p.add_theme_stylebox_override("panel", s)
	var lbl := Label.new()
	lbl.layout_mode = 1
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.text                 = "?"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", size / 2)
	lbl.add_theme_color_override("font_color", Color(0.50, 0.58, 0.76, 0.75))
	p.add_child(lbl)
	return p

func _pip(color: Color, size: int = 18) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(size, size)
	var s := StyleBoxFlat.new()
	s.bg_color                   = color
	s.corner_radius_top_left     = 999
	s.corner_radius_top_right    = 999
	s.corner_radius_bottom_left  = 999
	s.corner_radius_bottom_right = 999
	p.add_theme_stylebox_override("panel", s)
	return p

func _ps(color: Color, radius: int = 22) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color                   = color
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	s.border_width_left          = 1
	s.border_width_top           = 1
	s.border_width_right         = 1
	s.border_width_bottom        = 1
	s.border_color               = Color("#FFD6E7")
	return s

func _bsty(btn: Button, bg: Color, border: Color) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var s := StyleBoxFlat.new()
		if state == "hover":
			s.bg_color = bg.lightened(0.12)
		elif state == "pressed":
			s.bg_color = bg.darkened(0.10)
		elif state == "disabled":
			s.bg_color = Color(bg.r, bg.g, bg.b, bg.a * 0.55)
		else:
			s.bg_color = bg
		s.corner_radius_top_left     = 14
		s.corner_radius_top_right    = 14
		s.corner_radius_bottom_left  = 14
		s.corner_radius_bottom_right = 14
		s.border_width_left          = 1
		s.border_width_top           = 1
		s.border_width_right         = 1
		s.border_width_bottom        = 1
		s.border_color               = border
		btn.add_theme_stylebox_override(state, s)
