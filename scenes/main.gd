extends Control

## The player has no avatar. Signs sit on a shelf inside the office.

const INK := Color("3a2c24")
const CREAM := Color("f3eadc")
const PAPER := Color("e7d7c3")
const SAGE := Color("5f7d68")
const CLAY := Color("a86b52")
const SEA := Color("5d7380")
const PLUM := Color("6e5d78")
const GOLD := Color("8c7344")
const MOSS := Color("4d6654")

var state: GameState
var header: Label
var office_view: OfficeView
var panel: VBoxContainer
var mail_button: Button
var bank_button: Button
var end_button: Button
var view := "home"
var status := ""


func _ready() -> void:
	state = GameState.new()
	state.setup_new_game()
	_build()
	_show_view()


func _build() -> void:
	theme = _warm_theme()
	office_view = OfficeView.new()
	office_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	office_view.seat_pressed.connect(_press_seat)
	add_child(office_view)
	office_view.bind_game(state)

	var hud := Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)

	header = Label.new()
	header.position = Vector2(28, 18)
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", CREAM)
	hud.add_child(header)

	var blotter := PanelContainer.new()
	blotter.set_anchors_preset(Control.PRESET_FULL_RECT)
	blotter.offset_left = 28
	blotter.offset_top = 360
	blotter.offset_right = -28
	blotter.offset_bottom = -92
	blotter.mouse_filter = Control.MOUSE_FILTER_STOP
	blotter.add_theme_stylebox_override("panel", _paper_box(Color("c4b09a")))
	hud.add_child(blotter)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	blotter.add_child(scroll)
	panel = VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 8)
	scroll.add_child(panel)

	var shelf := HBoxContainer.new()
	shelf.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	shelf.offset_left = 20
	shelf.offset_top = -80
	shelf.offset_right = -20
	shelf.offset_bottom = -16
	shelf.add_theme_constant_override("separation", 8)
	shelf.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(shelf)

	mail_button = _sign(shelf, "Mail", SAGE, func() -> void: view = "mail"; _show_view())
	_sign(shelf, "Paper", Color("8a7356"), func() -> void: view = "paper"; _show_view())
	_sign(shelf, "Orders", CLAY, func() -> void: view = "orders"; _show_view())
	_sign(shelf, "Suppliers", SEA, func() -> void: view = "suppliers"; _show_view())
	_sign(shelf, "Recruit", PLUM, func() -> void: view = "recruit"; _show_view())
	bank_button = _sign(shelf, "Bank", GOLD, func() -> void: view = "bank"; _show_view())
	end_button = _sign(shelf, "End week", MOSS, func() -> void:
		status = state.end_week()
		view = "mail"
		_show_view()
	)


func _warm_theme() -> Theme:
	var warm := Theme.new()
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("c47a3a")
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("d8924a")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("a8642c")
	warm.set_stylebox("normal", "Button", normal)
	warm.set_stylebox("hover", "Button", hover)
	warm.set_stylebox("pressed", "Button", pressed)
	warm.set_stylebox("focus", "Button", hover)
	warm.set_color("font_color", "Button", Color("3a2418"))
	warm.set_color("font_hover_color", "Button", Color("2c1a10"))
	warm.set_color("font_pressed_color", "Button", Color("2c1a10"))
	warm.set_color("font_color", "Label", INK)
	warm.set_color("font_color", "SpinBox", Color("3a2418"))
	warm.set_color("font_color", "LineEdit", Color("3a2418"))
	var field := StyleBoxFlat.new()
	field.bg_color = Color("f3e2cc")
	field.corner_radius_top_left = 8
	field.corner_radius_top_right = 8
	field.corner_radius_bottom_left = 8
	field.corner_radius_bottom_right = 8
	field.content_margin_left = 8
	field.content_margin_right = 8
	warm.set_stylebox("normal", "LineEdit", field)
	warm.set_font_size("font_size", "Button", 18)
	warm.set_font_size("font_size", "Label", 16)
	return warm


func _sign(shelf: HBoxContainer, text: String, color: Color, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", CREAM)
	button.add_theme_color_override("font_pressed_color", CREAM)
	button.add_theme_stylebox_override("normal", _sign_box(color))
	button.add_theme_stylebox_override("hover", _sign_box(color.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _sign_box(color.darkened(0.08)))
	button.add_theme_stylebox_override("focus", _sign_box(color.lightened(0.08)))
	button.pressed.connect(action)
	shelf.add_child(button)
	return button


func _sign_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = 14
	box.corner_radius_top_right = 14
	box.corner_radius_bottom_left = 14
	box.corner_radius_bottom_right = 14
	box.content_margin_left = 8
	box.content_margin_right = 8
	return box


func _paper_box(edge: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PAPER
	box.border_color = edge
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.corner_radius_top_left = 16
	box.corner_radius_top_right = 16
	box.corner_radius_bottom_left = 16
	box.corner_radius_bottom_right = 16
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box


func _press_seat(seat: int) -> void:
	if seat < 0:
		status = "The director stays in the private room. The company moves from the shelf."
		view = "home"
		_show_view()
		return
	for hired in state.hired_people():
		if hired.seat == seat:
			view = "person:" + hired.id
			_show_view()
			return
	view = "home"
	_show_view()


func _show_view() -> void:
	header.text = "Week %d    Cash %d    Debt %d    Credit %d" % [state.week, state.cash, state.debt, state.credit]
	if state.lost:
		header.text += "\n" + state.loss_reason
	elif state.season_held:
		header.text += "\nThe season holds."
	office_view.sync_staff()
	mail_button.text = "Mail  %d" % state.unread_count()
	bank_button.text = "Bank  %s" % state.rate_text()
	end_button.disabled = state.lost
	for child in panel.get_children():
		child.queue_free()
	if status != "":
		_card(GOLD, ["Note", status, ""])
	if view == "mail":
		_show_mail()
	elif view == "paper":
		_show_paper()
	elif view == "orders":
		_show_deals("customer")
	elif view == "suppliers":
		_show_suppliers()
	elif view == "recruit":
		_show_recruit()
	elif view == "bank":
		_show_bank()
	elif view.begins_with("person:"):
		_show_person(view.substr(7))
	else:
		_show_home()


func _show_home() -> void:
	_card(SAGE, ["How a box is made", "Buy parts from a supplier", "Staff pack those parts", "The customer pays"])
	for customer in state._customers():
		_card(CLAY, [customer.display_name, "Buys " + customer.goods, customer.recipe, state.hearts(customer.love)])
	_card(SEA, ["Chairs", "Four desks", "Look on Recruit for more people", "Look on Suppliers for more parts"])


func _card(tint: Color, columns: Array) -> void:
	var row := PanelContainer.new()
	var box := _paper_box(tint)
	box.bg_color = Color("f4eadc")
	box.border_width_left = 8
	box.border_color = tint
	row.add_theme_stylebox_override("panel", box)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	row.add_child(line)
	for i in columns.size():
		var text := str(columns[i])
		if text == "":
			continue
		var label := Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", INK)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.custom_minimum_size = Vector2(120 if i == 0 else 0, 0)
		line.add_child(label)
	panel.add_child(row)


func _add_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(680, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(label)
	return label


func _add_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	panel.add_child(button)
	return button


func _add_spin(value: int, low: int, high: int) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = low
	spin.max_value = high
	spin.step = 1
	spin.value = value
	spin.custom_minimum_size = Vector2(160, 36)
	panel.add_child(spin)
	return spin


func _note(action: Callable) -> void:
	var result = action.call()
	status = "" if result == null else str(result)
	_show_view()


func _show_mail() -> void:
	state.mark_mail_read()
	mail_button.text = "Mail  0"
	if state.mail.is_empty():
		_card(SAGE, ["Mail", "The inbox is empty.", ""])
		return
	var items: Array = state.mail.duplicate()
	items.reverse()
	for item in items:
		_card(_mail_tint(str(item["kind"])), ["Week %d" % int(item["week"]), str(item["title"]), str(item["body"])])
		if str(item["kind"]) == "bailout" and not state.pending_bailout.is_empty():
			_add_button("Lend the company money", func() -> void:
				_note(func() -> String: return state.answer_bailout(true))
			)
			_add_button("Refuse", func() -> void:
				_note(func() -> String: return state.answer_bailout(false))
			)
		_add_label("")


func _mail_tint(kind: String) -> Color:
	match kind:
		"order":
			return CLAY
		"application":
			return PLUM
		"cooperate":
			return SEA
		"government":
			return SAGE
		"rate", "ledger":
			return GOLD
		"bailout":
			return CLAY
		_:
			return Color("8a7356")


func _show_paper() -> void:
	for line in state.newspaper_text().split("\n"):
		if line == "":
			continue
		_card(SAGE, ["Paper", line, ""])
	_add_button("Comply with the wage floor", func() -> void:
		_note(func() -> String: return state.comply_wage_floor())
	)
	_add_button("Pay printed penalties", func() -> void:
		_note(func() -> String: return state.pay_penalties())
	)


func _show_deals(kind: String) -> void:
	var any := false
	for deal in state.open_deals():
		if str(deal["kind"]) != kind:
			continue
		any = true
		_deal_block(deal)
	if not any:
		_card(CLAY, ["Orders", "Nothing is waiting here.", "Take a customer, then assign a person."])


func _deal_block(deal: Dictionary) -> void:
	var partner: GameState.Person = state.person(str(deal["partner_id"]))
	var crew_names: Array = []
	for member_id in deal["crew"]:
		crew_names.append(state.person(str(member_id)).display_name)
	var crew_text := "Nobody is following it." if crew_names.is_empty() else ", ".join(crew_names)
	var bought := partner.goods if partner.goods != "" else "units"
	_card(CLAY if str(deal["kind"]) == "customer" else SEA, [
		str(deal["stage"]).capitalize(),
		partner.display_name,
		"%d %s at %d" % [int(deal["units"]), bought, int(deal["unit_price"])],
		state.hearts(partner.love),
	])
	_card(GOLD, ["Made by", partner.recipe if partner.recipe != "" else "Staff follow the deal.", "Following: " + crew_text, partner.habit_line()])
	for hired in state.hired_people():
		var deal_id := str(deal["id"])
		var employee_id: String = str(hired.id)
		var on_deal: bool = (deal["crew"] as Array).has(employee_id)
		var verb := ("Take %s off" % hired.display_name) if on_deal else ("Assign %s" % hired.display_name)
		_bind_assign(employee_id, deal_id, on_deal, verb)


func _show_suppliers() -> void:
	if state.cooperate_from != "":
		var asking: GameState.Person = state.person(state.cooperate_from)
		_card(SEA, [asking.display_name, "Sells " + asking.goods, "Asks %d" % asking.ask, state.hearts(asking.love)])
		_add_button("Accept their price", func() -> void:
			_note(func() -> String: return state.accept_cooperation())
		)
	_add_button("Look for a supplier", func() -> void:
		_note(func() -> String: return state.find_supplier())
	)
	for id in state.known_suppliers:
		var supplier: GameState.Person = state.person(str(id))
		_card(SEA, [
			supplier.display_name,
			"Sells " + supplier.goods,
			"Ask %d" % supplier.ask,
			state.hearts(supplier.love) if supplier.active else "Contract ended",
		])
		_card(GOLD, [supplier.gift_line(), supplier.habit_line(), supplier.severity, ""])
		if not supplier.active:
			continue
		if state.pending_think.has(supplier.id):
			_bind_insist(supplier.id)
		var spin := _add_spin(supplier.ask, 1, 200)
		_bind_supply_offer(supplier.id, spin)
		_bind_break(supplier.id)
	_card(SEA, ["Open supply deals", "Parts waiting to be packed", "", ""])
	_show_deals("supplier")


func _show_recruit() -> void:
	_add_button("Look for someone", func() -> void:
		_note(func() -> String: return state.look_for_applicant())
	)
	if state.visible_applicants.is_empty():
		_card(PLUM, ["Recruit", "Nobody is waiting.", "Look, or wait for mail."])
	for id in state.visible_applicants:
		var applicant: GameState.Person = state.person(str(id))
		_card(PLUM, [applicant.display_name, applicant.gift_line(), applicant.habit_line(), "Ask %d" % applicant.ask])
		if state.pending_think.has(applicant.id):
			_bind_insist(applicant.id)
		var spin := _add_spin(applicant.ask, 10, 2000)
		_bind_hire_offer(applicant.id, spin)


func _show_bank() -> void:
	_card(GOLD, ["Rate", state.rate_text(), "Debt %d" % state.debt, "Credit %d" % state.credit])
	_card(SEA, ["How the rate moves", "A large loan can lower it", "Good credit can lower it", "Some weeks it jitters"])
	var spin := _add_spin(1000, 100, 20000)
	_add_button("Borrow this amount", func() -> void:
		_note(func() -> String: return state.borrow(int(spin.value)))
	)
	if not state.pending_bailout.is_empty():
		_card(CLAY, ["Bailout", "Someone wants company money.", "Answer it in the mail."])


func _show_person(id: String) -> void:
	if not state.people.has(id):
		_add_label("That chair is empty.")
		return
	var p: GameState.Person = state.person(id)
	if not p.hired:
		_add_label("That chair is empty.")
		return
	_card(PLUM, [p.display_name, p.balance, state.hearts(p.love), "Pay %d" % p.pay])
	_card(SAGE, [p.gift_line(), p.habit_line(), "Workload %d" % p.base_workload, "Pace %d" % p.base_pace])
	if p.training:
		_card(GOLD, ["Training", "No deal work this period.", "The salary is still paid.", ""])
	var spin := _add_spin(p.pay, state.min_wage, 3000)
	var who: String = p.id
	_add_button("Set pay", func() -> void:
		_note(func() -> String: return state.set_wage(who, int(spin.value)))
	)
	_add_button("Pay %d for a training period" % GameState.TRAINING_FEE, func() -> void:
		_note(func() -> String: return state.train(who))
	)
	_add_button("Fire", func() -> void:
		_note(func() -> String:
			var text: String = state.fire(who)
			view = "home"
			return text
		)
	)
	_card(CLAY, ["Deals they can follow", "Assign them from a row below.", "", ""])
	var any := false
	for deal in state.open_deals():
		any = true
		_deal_block(deal)
	if not any:
		_card(CLAY, ["No open deal", "Take an order or a supplier price first.", "", ""])
	if not state.pending_bailout.is_empty() and str(state.pending_bailout["id"]) == p.id:
		_add_button("Lend %d" % int(state.pending_bailout["amount"]), func() -> void:
			_note(func() -> String: return state.answer_bailout(true))
		)
		_add_button("Refuse the loan", func() -> void:
			_note(func() -> String: return state.answer_bailout(false))
		)


func _bind_assign(employee_id: String, deal_id: String, on_deal: bool, label: String) -> void:
	_add_button(label, func() -> void:
		_note(func() -> String: return state.assign(employee_id, deal_id, not on_deal))
	)


func _bind_insist(who: String) -> void:
	_add_button("Insist on the current offer", func() -> void:
		_note(func() -> String: return state.insist(who))
	)


func _bind_supply_offer(who: String, spin: SpinBox) -> void:
	_add_button("Offer this price", func() -> void:
		_note(func() -> String: return state.supplier_offer(who, int(spin.value)))
	)


func _bind_break(who: String) -> void:
	_add_button("Break this contract", func() -> void:
		_note(func() -> String: return state.break_contract(who))
	)


func _bind_hire_offer(who: String, spin: SpinBox) -> void:
	_add_button("Offer this salary", func() -> void:
		_note(func() -> String: return state.recruit_offer(who, int(spin.value)))
	)
