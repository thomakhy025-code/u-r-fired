extends Control

const INK := Color("3a2c24")
const CREAM := Color("f6ead8")
const PEACH := Color("e7a07a")

var state: GameState
var office: OfficeView
var gate: Control
var name_box: LineEdit
var gate_note: Label
var started := false


func _ready() -> void:
	state = GameState.new()
	state.setup_new_game()
	theme = _warm_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	office = OfficeView.new()
	office.set_anchors_preset(Control.PRESET_FULL_RECT)
	office.bind(state)
	add_child(office)
	_build_gate()


func _process(delta: float) -> void:
	if not started or state == null:
		return
	state.tick(delta)


func _warm_theme() -> Theme:
	var warm := Theme.new()
	warm.default_font = ThemeDB.fallback_font
	warm.default_font_size = 16
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("e0a04a")
	normal.set_corner_radius_all(12)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("e8b15e")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("c4842e")
	warm.set_stylebox("normal", "Button", normal)
	warm.set_stylebox("hover", "Button", hover)
	warm.set_stylebox("pressed", "Button", pressed)
	warm.set_stylebox("focus", "Button", hover)
	warm.set_color("font_color", "Button", INK)
	warm.set_color("font_hover_color", "Button", INK)
	warm.set_color("font_pressed_color", "Button", INK)
	warm.set_color("font_color", "Label", INK)
	warm.set_color("font_color", "LineEdit", INK)
	var field := StyleBoxFlat.new()
	field.bg_color = Color("f6ead8")
	field.set_corner_radius_all(8)
	field.content_margin_left = 8
	field.content_margin_right = 8
	warm.set_stylebox("normal", "LineEdit", field)
	warm.set_font("font", "Button", ThemeDB.fallback_font)
	warm.set_font("font", "Label", ThemeDB.fallback_font)
	warm.set_font("font", "LineEdit", ThemeDB.fallback_font)
	return warm


func _build_gate() -> void:
	gate = Control.new()
	gate.set_anchors_preset(Control.PRESET_FULL_RECT)
	gate.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(gate)
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = PEACH
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gate.add_child(backdrop)
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -280
	card.offset_top = -170
	card.offset_right = 280
	card.offset_bottom = 170
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color("f0c27a")
	plate.border_color = Color("6b3e22")
	plate.set_border_width_all(6)
	plate.set_corner_radius_all(22)
	plate.content_margin_left = 22
	plate.content_margin_right = 22
	plate.content_margin_top = 18
	plate.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", plate)
	gate.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var title := Label.new()
	title.text = "Name the company"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", ThemeDB.fallback_font)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", INK)
	box.add_child(title)
	var line := Label.new()
	line.text = "Tap a desk, fill the outbox, answer the phone."
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_theme_font_override("font", ThemeDB.fallback_font)
	line.add_theme_font_size_override("font_size", 18)
	line.add_theme_color_override("font_color", INK)
	box.add_child(line)
	name_box = LineEdit.new()
	name_box.placeholder_text = "Company name"
	name_box.custom_minimum_size = Vector2(360, 44)
	name_box.add_theme_font_override("font", ThemeDB.fallback_font)
	name_box.add_theme_font_size_override("font_size", 20)
	box.add_child(name_box)
	var open := Button.new()
	open.text = "Open the office"
	open.custom_minimum_size = Vector2(360, 52)
	open.add_theme_font_override("font", ThemeDB.fallback_font)
	open.add_theme_font_size_override("font_size", 22)
	open.add_theme_color_override("font_color", CREAM)
	open.add_theme_color_override("font_hover_color", CREAM)
	open.add_theme_color_override("font_pressed_color", CREAM)
	var open_box := StyleBoxFlat.new()
	open_box.bg_color = Color("e06a58")
	open_box.set_corner_radius_all(14)
	open.add_theme_stylebox_override("normal", open_box)
	open.add_theme_stylebox_override("hover", open_box)
	open.add_theme_stylebox_override("pressed", open_box)
	open.add_theme_stylebox_override("focus", open_box)
	open.pressed.connect(_open_office)
	box.add_child(open)
	gate_note = Label.new()
	gate_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gate_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gate_note.add_theme_font_override("font", ThemeDB.fallback_font)
	gate_note.add_theme_color_override("font_color", INK)
	box.add_child(gate_note)
	name_box.text_submitted.connect(func(_new_text: String) -> void:
		_open_office()
	)


func _open_office() -> void:
	var named := name_box.text.strip_edges()
	if named == "":
		gate_note.text = "Type a company name."
		return
	if named.length() > 22:
		named = named.substr(0, 22)
	state.company_name = named
	started = true
	gate.visible = false
