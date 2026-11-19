class_name PlayerCard
extends PanelContainer

## Compact staff card: level, face, and one role.

var level_label: Label
var role_label: Label
var name_label: Label
var plate: StyleBoxFlat


func show_staff(person: GameState.Staff) -> void:
	for child in get_children():
		child.queue_free()
	custom_minimum_size = Vector2(168, 58)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plate = StyleBoxFlat.new()
	plate.bg_color = _tier(person.level)
	plate.border_color = Color("3a2c24")
	plate.set_border_width_all(3)
	plate.set_corner_radius_all(14)
	plate.content_margin_left = 6
	plate.content_margin_right = 8
	plate.content_margin_top = 4
	plate.content_margin_bottom = 4
	add_theme_stylebox_override("panel", plate)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	var face := FaceBadge.for_id(person.id)
	face.custom_minimum_size = Vector2(40, 40)
	row.add_child(face)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(words)
	var top := HBoxContainer.new()
	words.add_child(top)
	level_label = Label.new()
	level_label.add_theme_font_override("font", ThemeDB.fallback_font)
	level_label.add_theme_font_size_override("font_size", 22)
	level_label.add_theme_color_override("font_color", Color("fff6e8"))
	top.add_child(level_label)
	role_label = Label.new()
	role_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	role_label.add_theme_font_override("font", ThemeDB.fallback_font)
	role_label.add_theme_font_size_override("font_size", 14)
	role_label.add_theme_color_override("font_color", Color("fff6e8"))
	top.add_child(role_label)
	name_label = Label.new()
	name_label.add_theme_font_override("font", ThemeDB.fallback_font)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color("fff6e8"))
	words.add_child(name_label)
	refresh(person)


func refresh(person: GameState.Staff) -> void:
	if level_label == null or plate == null:
		return
	level_label.text = str(person.level)
	role_label.text = person.role
	name_label.text = person.display_name
	plate.bg_color = _tier(person.level)


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
