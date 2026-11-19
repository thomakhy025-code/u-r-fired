class_name PlayerCard
extends PanelContainer

## Employee card: big level, face, role, commission, and calls closed.

var level_label: Label
var role_label: Label
var name_label: Label
var commission_label: Label
var calls_label: Label
var plate: StyleBoxFlat


func show_employee(person: GameState.Employee) -> void:
	var kids: Array[Node] = get_children()
	var index: int = 0
	while index < kids.size():
		kids[index].queue_free()
		index += 1
	custom_minimum_size = Vector2(236, 100)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	plate = StyleBoxFlat.new()
	plate.bg_color = _tier(person.level)
	plate.border_color = Color("3a2c24")
	plate.set_border_width_all(3)
	plate.set_corner_radius_all(14)
	plate.content_margin_left = 8
	plate.content_margin_right = 8
	plate.content_margin_top = 6
	plate.content_margin_bottom = 6
	add_theme_stylebox_override("panel", plate)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var face := FaceBadge.for_id(person.face_id)
	face.custom_minimum_size = Vector2(52, 52)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(face)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_theme_constant_override("separation", 0)
	row.add_child(words)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(top)
	level_label = _line("", 32, Color("fff6e8"))
	top.add_child(level_label)
	role_label = _line("", 14, Color("fff6e8"))
	role_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(role_label)
	name_label = _line("", 16, Color("fff6e8"))
	words.add_child(name_label)
	var stats := HBoxContainer.new()
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(stats)
	commission_label = _line("", 13, Color("fff6e8"))
	commission_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(commission_label)
	calls_label = _line("", 13, Color("fff6e8"))
	calls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats.add_child(calls_label)
	_ignore_tree(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	refresh(person)


func refresh(person: GameState.Employee) -> void:
	if level_label == null or plate == null:
		return
	level_label.text = str(person.level)
	if person.busy:
		role_label.text = "Phone"
	else:
		role_label.text = person.role
	name_label.text = person.display_name
	commission_label.text = "Commission %d" % person.commission
	calls_label.text = "Calls %d" % person.calls_closed
	plate.bg_color = _tier(person.level)


func set_hot(hot: bool) -> void:
	if plate == null:
		return
	if hot:
		plate.border_color = Color("e06a58")
		plate.set_border_width_all(5)
	else:
		plate.border_color = Color("3a2c24")
		plate.set_border_width_all(3)


func _line(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", ThemeDB.fallback_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _ignore_tree(node: Node) -> void:
	var kids: Array[Node] = node.get_children()
	var index: int = 0
	while index < kids.size():
		var child: Node = kids[index]
		var control: Control = child as Control
		if control != null:
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_tree(child)
		index += 1


func _tier(level: int) -> Color:
	if level >= 5:
		return Color("7a4e86")
	if level >= 4:
		return Color("b5832a")
	if level >= 3:
		return Color("3d6e96")
	if level >= 2:
		return Color("2f7d62")
	return Color("8d5a32")
