class_name PlayerCard
extends PanelContainer

## A staff card in the shape of a football-game player card: level, role, face, and six stats.


func show_person(state: GameState, person: GameState.Person) -> void:
	for child in get_children():
		child.queue_free()
	custom_minimum_size = Vector2(176, 236)
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var plate := StyleBoxFlat.new()
	plate.bg_color = _tier(person.level)
	plate.border_color = Color("2c241c")
	plate.set_border_width_all(3)
	plate.set_corner_radius_all(18)
	plate.content_margin_left = 10
	plate.content_margin_right = 10
	plate.content_margin_top = 8
	plate.content_margin_bottom = 8
	add_theme_stylebox_override("panel", plate)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	add_child(box)
	var top := HBoxContainer.new()
	box.add_child(top)
	var level := Label.new()
	level.text = str(person.level)
	level.add_theme_font_override("font", ThemeDB.fallback_font)
	level.add_theme_font_size_override("font_size", 34)
	level.add_theme_color_override("font_color", Color("fff8ea"))
	top.add_child(level)
	var role_label := Label.new()
	role_label.text = state.card_role(person)
	role_label.add_theme_font_override("font", ThemeDB.fallback_font)
	role_label.add_theme_font_size_override("font_size", 16)
	role_label.add_theme_color_override("font_color", Color("fff8ea"))
	role_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(role_label)
	var face_row := CenterContainer.new()
	box.add_child(face_row)
	face_row.add_child(FaceBadge.for_id(person.id))
	var name := Label.new()
	name.text = person.display_name
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_override("font", ThemeDB.fallback_font)
	name.add_theme_font_size_override("font_size", 18)
	name.add_theme_color_override("font_color", Color("fff8ea"))
	box.add_child(name)
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 4)
	box.add_child(stats)
	var numbers: Dictionary = state.card_stats(person)
	for key in ["PAC", "OUT", "CAR", "NRV", "SAL", "STA"]:
		var column := VBoxContainer.new()
		stats.add_child(column)
		var title := Label.new()
		title.text = key
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_override("font", ThemeDB.fallback_font)
		title.add_theme_font_size_override("font_size", 9)
		title.add_theme_color_override("font_color", Color("2c241c"))
		column.add_child(title)
		var value := Label.new()
		value.text = str(int(numbers[key]))
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.add_theme_font_override("font", ThemeDB.fallback_font)
		value.add_theme_font_size_override("font_size", 14)
		value.add_theme_color_override("font_color", Color("fff8ea"))
		column.add_child(value)


func _tier(level: int) -> Color:
	if level >= 84:
		return Color("6a4e9a")
	if level >= 75:
		return Color("c49214")
	if level >= 65:
		return Color("7d868e")
	return Color("8d5a32")
