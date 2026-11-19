class_name OfficeView
extends Control

## The office is the whole game: desks, outbox, phone, shelf, and staff cards.

const INK := Color("3a2c24")
const CREAM := Color("f6ead8")
const WOOD_DARK := Color("6b3e22")
const HONEY := Color("e0b56a")

var game: GameState
var name_label: Label
var note_label: Label
var cash_label: Label
var desk_timers: Array[Label] = []
var desk_recipes: Array[VBoxContainer] = []
var desk_ready: Array[Button] = []
var quiet_label: Label
var mood_row: HBoxContainer
var mood_face: MoodMark
var mood_label: Label
var caller_panels: Array[PanelContainer] = []
var caller_titles: Array[Label] = []
var caller_wants: Array[Label] = []
var caller_times: Array[Label] = []
var caller_fills: Array[ColorRect] = []
var caller_faces: Array[FaceBadge] = []
var outbox_buttons: Array[Button] = []
var outbox_text: Array[String] = []
var mess_row: HBoxContainer
var mess_key := ""
var supply_labels: Array[Label] = []
var restock_button: Button
var upgrade_buttons: Array[Button] = []
var staff_cards: Array[PlayerCard] = []
var staff_buttons: Array[Button] = []


class MoodMark extends Control:
	var happy := true

	func _ready() -> void:
		custom_minimum_size = Vector2(36, 36)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var mid := size * 0.5
		draw_circle(mid, 16.0, Color("f2c7a4"))
		draw_circle(mid + Vector2(-6, -3), 2.0, Color("3a2c24"))
		draw_circle(mid + Vector2(6, -3), 2.0, Color("3a2c24"))
		if happy:
			draw_line(mid + Vector2(-7, 3), mid + Vector2(0, 8), Color("3a2c24"), 2.0)
			draw_line(mid + Vector2(0, 8), mid + Vector2(7, 3), Color("3a2c24"), 2.0)
		else:
			draw_line(mid + Vector2(-7, 8), mid + Vector2(0, 3), Color("3a2c24"), 2.0)
			draw_line(mid + Vector2(0, 3), mid + Vector2(7, 8), Color("3a2c24"), 2.0)


func bind(next: GameState) -> void:
	game = next


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _process(_delta: float) -> void:
	if game == null:
		return
	_sync()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("f0b48c"))
	var floor_y := size.y * 0.12
	var band := 0
	var y := floor_y
	while y < size.y:
		var plank := Color("c4894a") if band % 2 == 0 else Color("b67a3c")
		draw_rect(Rect2(0, y, size.x, 26), plank)
		y += 26
		band += 1
	draw_rect(Rect2(0, floor_y, size.x, 10), Color("f0c27a"))
	var window := Rect2(size.x * 0.38, 16, size.x * 0.24, 58)
	draw_rect(window, Color("7eb8d4"))
	draw_rect(Rect2(window.position.x, window.position.y, window.size.x, 8), WOOD_DARK)
	draw_rect(Rect2(window.position.x, window.position.y + window.size.y - 8, window.size.x, 8), WOOD_DARK)
	draw_rect(Rect2(window.position.x + window.size.x * 0.5 - 4, window.position.y, 8, window.size.y), WOOD_DARK)
	var rug := Rect2(size.x * 0.28, size.y * 0.46, size.x * 0.36, size.y * 0.16)
	var step := 22.0
	var row := 0
	var rug_y := rug.position.y
	while rug_y < rug.end.y:
		var col := 0
		var rug_x := rug.position.x
		while rug_x < rug.end.x:
			var swatch := Color("e07a55") if (row + col) % 2 == 0 else Color("f0c27a")
			draw_rect(Rect2(rug_x, rug_y, step, step), swatch)
			rug_x += step
			col += 1
		rug_y += step
		row += 1
	_plant(Vector2(size.x - 78, size.y * 0.58))
	_plant(Vector2(64, size.y * 0.62))


func _plant(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-16, 8), Vector2(32, 28)), Color("c4512f"))
	draw_circle(at + Vector2(0, -8), 26, Color("2f8f45"))


func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_top = 10
	root.offset_right = -16
	root.offset_bottom = -10
	root.add_theme_constant_override("separation", 8)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.add_child(_header())
	var room := VBoxContainer.new()
	room.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room.add_theme_constant_override("separation", 8)
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(room)
	room.add_child(_stations())
	room.add_child(_outbox_row())
	mess_row = HBoxContainer.new()
	mess_row.add_theme_constant_override("separation", 8)
	mess_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mess_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_child(mess_row)
	var floor_space := Control.new()
	floor_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	floor_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_child(floor_space)
	root.add_child(_supply_row())
	root.add_child(_upgrade_row())
	root.add_child(_staff_row())


func _header() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label = _label("Company", 26, INK)
	name_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(name_label)
	note_label = _label("Tap a desk, then the outbox, then the phone.", 16, INK)
	note_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(note_label)
	cash_label = _label("Cash 0", 26, INK)
	cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var plaque := PanelContainer.new()
	plaque.add_theme_stylebox_override("panel", _plate(HONEY, 12))
	plaque.add_child(cash_label)
	row.add_child(plaque)
	return row


func _stations() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for desk_index in 2:
		row.add_child(_desk(desk_index))
	row.add_child(_phone())
	return row


func _desk(desk_index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_FILL
	var top := Color("3faf8a") if desk_index == 0 else Color("3d8ec4")
	panel.add_theme_stylebox_override("panel", _plate(top, 18))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var title := _label("Desk %d" % [desk_index + 1], 22, INK)
	box.add_child(title)
	var timer := _label("", 26, INK)
	timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(timer)
	desk_timers.append(timer)
	var recipes := VBoxContainer.new()
	recipes.add_theme_constant_override("separation", 4)
	box.add_child(recipes)
	desk_recipes.append(recipes)
	for product_id in GameState.PRODUCT_ORDER:
		var recipe := _button(game.product_name(product_id), _product_color(product_id), INK)
		recipe.custom_minimum_size = Vector2(0, 32)
		recipe.clip_text = true
		recipe.set_meta("product", product_id)
		_bind_job(recipe, desk_index, product_id)
		recipes.add_child(recipe)
	var ready := _button("Outbox", HONEY, INK)
	ready.custom_minimum_size = Vector2(0, 52)
	ready.visible = false
	_bind_ready(ready, desk_index)
	box.add_child(ready)
	desk_ready.append(ready)
	return panel


func _phone() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_FILL
	panel.custom_minimum_size = Vector2(260, 0)
	panel.add_theme_stylebox_override("panel", _plate(Color("f0a598"), 18))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(_label("Phone", 22, INK))
	mood_row = HBoxContainer.new()
	mood_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mood_row.add_theme_constant_override("separation", 8)
	mood_row.visible = false
	box.add_child(mood_row)
	mood_face = MoodMark.new()
	mood_row.add_child(mood_face)
	mood_label = _label("", 20, INK)
	mood_row.add_child(mood_label)
	quiet_label = _label("The phone is quiet.", 18, INK)
	quiet_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(quiet_label)
	for caller_index in 2:
		box.add_child(_caller_card(caller_index))
	return panel


func _caller_card(caller_index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	panel.add_theme_stylebox_override("panel", _plate(Color("f3c2b4"), 14))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	box.add_child(top)
	var face := FaceBadge.for_id("nia")
	face.custom_minimum_size = Vector2(36, 36)
	top.add_child(face)
	caller_faces.append(face)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(words)
	var title := _label("Caller", 16, INK)
	words.add_child(title)
	caller_titles.append(title)
	var wants := _label("Wants", 15, INK)
	wants.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(wants)
	caller_wants.append(wants)
	var time_row := HBoxContainer.new()
	time_row.add_theme_constant_override("separation", 8)
	box.add_child(time_row)
	var time := _label("0s", 18, INK)
	time.custom_minimum_size = Vector2(52, 0)
	time_row.add_child(time)
	caller_times.append(time)
	var track := ColorRect.new()
	track.custom_minimum_size = Vector2(80, 14)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.color = Color("3a2c24")
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_row.add_child(track)
	var fill := ColorRect.new()
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill.anchor_right = 1.0
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.color = Color("3f9a4a")
	track.add_child(fill)
	caller_fills.append(fill)
	var hand := _button("Hand over", Color("e06a58"), CREAM)
	hand.custom_minimum_size = Vector2(0, 34)
	_bind_hand(hand, caller_index)
	box.add_child(hand)
	caller_panels.append(panel)
	return panel


func _outbox_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_label("Outbox", 20, INK))
	for slot in 4:
		var button := _button("Empty", Color("d7b48a"), INK)
		button.custom_minimum_size = Vector2(150, 46)
		button.visible = slot < 2
		_bind_outbox(button, slot)
		row.add_child(button)
		outbox_buttons.append(button)
		outbox_text.append("")
	return row


func _supply_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for supply_id in GameState.SUPPLY_ORDER:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _plate(Color("f0c27a"), 12))
		panel.custom_minimum_size = Vector2(120, 52)
		var label := _label(game.supply_name(supply_id), 14, INK)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(label)
		row.add_child(panel)
		supply_labels.append(label)
	restock_button = _button("Restock  %d" % GameState.RESTOCK_COST, Color("8fbf7a"), INK)
	restock_button.custom_minimum_size = Vector2(150, 52)
	restock_button.pressed.connect(func() -> void:
		_say(game.order_restock())
	)
	row.add_child(restock_button)
	return row


func _upgrade_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for upgrade_id in GameState.UPGRADE_ORDER:
		var button := _button(game.upgrade_label(upgrade_id), Color("f0b060"), INK)
		button.custom_minimum_size = Vector2(180, 44)
		_bind_upgrade(button, upgrade_id)
		row.add_child(button)
		upgrade_buttons.append(button)
	return row


func _staff_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for person in game.staff:
		var column := HBoxContainer.new()
		column.add_theme_constant_override("separation", 4)
		column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		row.add_child(column)
		var card := PlayerCard.new()
		card.show_staff(person)
		column.add_child(card)
		staff_cards.append(card)
		var button := _button("Hire", Color("d7c4e4"), INK)
		button.custom_minimum_size = Vector2(128, 58)
		button.add_theme_font_size_override("font_size", 14)
		_bind_staff(button, person.id)
		column.add_child(button)
		staff_buttons.append(button)
	return row


func _sync() -> void:
	if game.notice != "":
		note_label.text = game.notice
		game.notice = ""
	name_label.text = game.company_name
	cash_label.text = "Cash %d" % game.cash
	_sync_desks()
	_sync_phone()
	_sync_outbox()
	_sync_messes()
	_sync_supplies()
	_sync_upgrades()
	_sync_staff()


func _sync_desks() -> void:
	for desk_index in game.desks.size():
		var desk := game.desks[desk_index]
		var timer := desk_timers[desk_index]
		var recipes := desk_recipes[desk_index]
		var ready := desk_ready[desk_index]
		if desk.phase == "cooking":
			recipes.visible = false
			ready.visible = false
			timer.visible = true
			timer.text = "%s\n%s" % [game.product_name(desk.product_id), game.clock_text(desk.seconds_left)]
		elif desk.phase == "done":
			recipes.visible = false
			timer.visible = false
			ready.visible = true
			var ready_text := "Outbox  %s" % game.product_name(desk.product_id)
			if ready.text != ready_text:
				ready.text = ready_text
				_paint_button(ready, _product_color(desk.product_id), INK)
		else:
			recipes.visible = true
			ready.visible = false
			timer.visible = true
			timer.text = "Pick a job"
			for child in recipes.get_children():
				var recipe := child as Button
				if recipe == null or not recipe.has_meta("product"):
					continue
				var product_id := str(recipe.get_meta("product"))
				recipe.text = "%s   %d   %s" % [game.product_name(product_id), game.product_cost(product_id), game.clock_text(game.job_seconds(product_id))]


func _sync_phone() -> void:
	var show_mood := game.mood_left > 0.0 and game.last_mood != ""
	mood_row.visible = show_mood
	if show_mood:
		var happy := game.last_mood == "happy"
		mood_label.text = "Happy" if happy else "Unhappy"
		if mood_face.happy != happy:
			mood_face.happy = happy
			mood_face.queue_redraw()
	quiet_label.visible = game.callers.is_empty()
	for caller_index in caller_panels.size():
		var panel := caller_panels[caller_index]
		if caller_index >= game.callers.size():
			panel.visible = false
			continue
		panel.visible = true
		var caller := game.callers[caller_index]
		caller_titles[caller_index].text = caller.display_name
		caller_wants[caller_index].text = "Wants %s" % game.product_name(caller.product_id)
		caller_times[caller_index].text = game.clock_text(caller.patience)
		caller_faces[caller_index].apply_id(caller.face_id)
		var ratio := 0.0
		if caller.patience_full > 0.0:
			ratio = clampf(caller.patience / caller.patience_full, 0.0, 1.0)
		var fill := caller_fills[caller_index]
		fill.anchor_left = 0.0
		fill.anchor_top = 0.0
		fill.anchor_bottom = 1.0
		fill.offset_left = 0.0
		fill.offset_top = 0.0
		fill.offset_bottom = 0.0
		fill.offset_right = 0.0
		fill.anchor_right = ratio
		fill.color = Color("3f9a4a").lerp(Color("c4473a"), 1.0 - ratio)


func _sync_outbox() -> void:
	for slot in outbox_buttons.size():
		var button := outbox_buttons[slot]
		var open := slot < game.outbox_slots
		button.visible = open
		if not open:
			continue
		var shown := "Empty"
		var color := Color("d7b48a")
		if slot < game.outbox.size():
			shown = game.product_name(game.outbox[slot])
			color = _product_color(game.outbox[slot])
		if outbox_text[slot] == shown:
			continue
		outbox_text[slot] = shown
		button.text = shown
		_paint_button(button, color, INK)


func _sync_messes() -> void:
	var key := ""
	for mess in game.messes:
		key += mess.kind
		key += str(mess.coins)
		key += "|"
	if key == mess_key:
		return
	mess_key = key
	for child in mess_row.get_children():
		mess_row.remove_child(child)
		child.queue_free()
	for index in game.messes.size():
		var mess := game.messes[index]
		var title := "Papers  +%d" % mess.coins
		var color := Color("f6ead8")
		if mess.kind == "cup":
			title = "Cup  +%d" % mess.coins
			color = Color("d7efe8")
		var button := _button(title, color, INK)
		button.custom_minimum_size = Vector2(140, 40)
		_bind_mess(button, index)
		mess_row.add_child(button)


func _sync_supplies() -> void:
	for index in supply_labels.size():
		var supply_id := GameState.SUPPLY_ORDER[index]
		supply_labels[index].text = "%s\n%d / %d" % [game.supply_name(supply_id), game.supply_qty(supply_id), game.shelf_size]
	if game.restock_left > 0.0:
		restock_button.text = "Arrives  %s" % game.clock_text(game.restock_left)
		restock_button.disabled = true
	else:
		restock_button.text = "Restock  %d" % GameState.RESTOCK_COST
		restock_button.disabled = false


func _sync_upgrades() -> void:
	for index in upgrade_buttons.size():
		var upgrade_id := GameState.UPGRADE_ORDER[index]
		upgrade_buttons[index].text = game.upgrade_label(upgrade_id)
		upgrade_buttons[index].disabled = not game.upgrade_open(upgrade_id)


func _sync_staff() -> void:
	for index in game.staff.size():
		var person := game.staff[index]
		staff_cards[index].refresh(person)
		var button := staff_buttons[index]
		if not person.hired:
			button.text = "Hire  %d" % person.hire_cost
			button.disabled = false
		elif person.level >= GameState.STAFF_MAX:
			button.text = "Level %d" % person.level
			button.disabled = true
		else:
			button.text = "Upgrade  %d" % game.staff_upgrade_cost(person.level)
			button.disabled = false


func _say(text: String) -> void:
	if text != "" and note_label != null:
		note_label.text = text


func _bind_job(button: Button, desk_index: int, product_id: String) -> void:
	button.pressed.connect(func() -> void:
		_say(game.start_job(desk_index, product_id))
	)


func _bind_ready(button: Button, desk_index: int) -> void:
	button.pressed.connect(func() -> void:
		_say(game.place_on_outbox(desk_index))
	)


func _bind_hand(button: Button, caller_index: int) -> void:
	button.pressed.connect(func() -> void:
		_say(game.hand_over(caller_index))
	)


func _bind_outbox(button: Button, slot: int) -> void:
	button.pressed.connect(func() -> void:
		_say(game.hand_outbox_slot(slot))
	)


func _bind_upgrade(button: Button, upgrade_id: String) -> void:
	button.pressed.connect(func() -> void:
		_say(game.buy_upgrade(upgrade_id))
	)


func _bind_staff(button: Button, staff_id: String) -> void:
	button.pressed.connect(func() -> void:
		var person_index := game._staff_index(staff_id)
		if person_index < 0:
			return
		if game.staff[person_index].hired:
			_say(game.upgrade_staff(staff_id))
		else:
			_say(game.hire(staff_id))
	)


func _bind_mess(button: Button, index: int) -> void:
	button.pressed.connect(func() -> void:
		_say(game.clean_mess(index))
	)


func _product_color(product_id: String) -> Color:
	match product_id:
		"snack":
			return Color("7dcea0")
		"lunch":
			return Color("f0c36a")
		"sample":
			return Color("8ec8e8")
		"classkit":
			return Color("c9b4e0")
		"hamper":
			return Color("f0a090")
		_:
			return HONEY


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", ThemeDB.fallback_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, color: Color, ink: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	_paint_button(button, color, ink)
	return button


func _paint_button(button: Button, color: Color, ink: Color) -> void:
	button.add_theme_font_override("font", ThemeDB.fallback_font)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_hover_color", ink)
	button.add_theme_color_override("font_pressed_color", ink)
	button.add_theme_color_override("font_disabled_color", Color("6d5848"))
	button.add_theme_stylebox_override("normal", _plate(color, 12))
	button.add_theme_stylebox_override("hover", _plate(color.lightened(0.06), 12))
	button.add_theme_stylebox_override("pressed", _plate(color.darkened(0.08), 12))
	button.add_theme_stylebox_override("focus", _plate(color.lightened(0.06), 12))
	button.add_theme_stylebox_override("disabled", _plate(color.darkened(0.18), 12))


func _plate(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = WOOD_DARK
	box.set_border_width_all(3)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box
