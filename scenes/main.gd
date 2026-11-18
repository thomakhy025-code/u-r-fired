extends Control

## The player has no avatar. The office is the view. The right edge is buttons.

const RAIL := 250.0

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
	var backdrop := ColorRect.new()
	backdrop.color = Color("3c2a22")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var columns := HBoxContainer.new()
	columns.set_anchors_preset(Control.PRESET_FULL_RECT)
	columns.add_theme_constant_override("separation", 0)
	add_child(columns)

	var office := MarginContainer.new()
	office.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	office.add_theme_constant_override("margin_left", 20)
	office.add_theme_constant_override("margin_top", 16)
	office.add_theme_constant_override("margin_right", 12)
	office.add_theme_constant_override("margin_bottom", 16)
	columns.add_child(office)

	var office_box := VBoxContainer.new()
	office_box.add_theme_constant_override("separation", 12)
	office.add_child(office_box)

	header = Label.new()
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color("f3e2cc"))
	office_box.add_child(header)

	office_view = OfficeView.new()
	office_view.seat_pressed.connect(_press_seat)
	office_box.add_child(office_view)
	office_view.bind_game(state)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	office_box.add_child(scroll)
	panel = VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 8)
	scroll.add_child(panel)

	var rail_bg := ColorRect.new()
	# The rail is a column of buttons, not a second scene.
	var rail := VBoxContainer.new()
	rail.custom_minimum_size = Vector2(RAIL, 0)
	rail.add_theme_constant_override("separation", 8)
	var rail_margin := MarginContainer.new()
	rail_margin.add_theme_constant_override("margin_top", 16)
	rail_margin.add_theme_constant_override("margin_right", 16)
	rail_margin.add_theme_constant_override("margin_bottom", 16)
	rail_margin.add_theme_constant_override("margin_left", 8)
	rail_margin.add_child(rail)
	columns.add_child(rail_margin)
	rail_bg.color = Color("4a3328")
	rail_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	rail_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail_margin.add_child(rail_bg)
	rail_margin.move_child(rail_bg, 0)

	mail_button = _rail_button(rail, "Mail", func() -> void: view = "mail"; _show_view())
	_rail_button(rail, "Newspaper", func() -> void: view = "paper"; _show_view())
	_rail_button(rail, "Orders", func() -> void: view = "orders"; _show_view())
	_rail_button(rail, "Suppliers", func() -> void: view = "suppliers"; _show_view())
	_rail_button(rail, "Recruit", func() -> void: view = "recruit"; _show_view())
	bank_button = _rail_button(rail, "Bank", func() -> void: view = "bank"; _show_view())
	end_button = _rail_button(rail, "End week", func() -> void:
		status = state.end_week()
		view = "mail"
		_show_view()
	)
	end_button.add_theme_color_override("font_color", Color("3a2418"))


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
	warm.set_color("font_color", "Label", Color("f6e6d4"))
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


func _rail_button(rail: VBoxContainer, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 48)
	button.pressed.connect(action)
	rail.add_child(button)
	return button


func _press_seat(seat: int) -> void:
	if seat < 0:
		status = "The director stays in the private room. The company moves when you press the signs."
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
		_add_label(status)
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
		_add_label("Press a sign on the right, or a person in a chair. A deal does not move until someone follows it.")


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
		_add_label("The inbox is empty.")
		return
	var items: Array = state.mail.duplicate()
	items.reverse()
	for item in items:
		_add_label("Week %d  ·  %s\n%s" % [int(item["week"]), str(item["title"]), str(item["body"])])
		if str(item["kind"]) == "bailout" and not state.pending_bailout.is_empty():
			_add_button("Lend the company money", func() -> void:
				_note(func() -> String: return state.answer_bailout(true))
			)
			_add_button("Refuse", func() -> void:
				_note(func() -> String: return state.answer_bailout(false))
			)
		_add_label("")


func _show_paper() -> void:
	_add_label(state.newspaper_text())
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
		_add_label("Nothing is waiting here.")


func _deal_block(deal: Dictionary) -> void:
	var partner: GameState.Person = state.person(str(deal["partner_id"]))
	var crew_names: Array = []
	for member_id in deal["crew"]:
		crew_names.append(state.person(str(member_id)).display_name)
	var crew_text := "Nobody is following it." if crew_names.is_empty() else ", ".join(crew_names)
	_add_label("%s  ·  %s  ·  %d units at %d\n%s  %s\nLove %d  %s\nStrength: %s\nBad habit: %s (%s)\nFollowing: %s" % [
		str(deal["stage"]).capitalize(),
		partner.display_name,
		int(deal["units"]),
		int(deal["unit_price"]),
		partner.balance,
		state.hearts(partner.love),
		partner.love,
		state.hearts(partner.love),
		partner.gift_line(),
		partner.habit_line(),
		partner.severity,
		crew_text,
	])
	for hired in state.hired_people():
		var deal_id := str(deal["id"])
		var employee_id: String = str(hired.id)
		var on_deal: bool = (deal["crew"] as Array).has(employee_id)
		var verb := ("Take %s off" % hired.display_name) if on_deal else ("Assign %s" % hired.display_name)
		_bind_assign(employee_id, deal_id, on_deal, verb)


func _show_suppliers() -> void:
	if state.cooperate_from != "":
		var asking: GameState.Person = state.person(state.cooperate_from)
		_add_label("%s asks to cooperate at %d a unit." % [asking.display_name, asking.ask])
		_add_button("Accept their price", func() -> void:
			_note(func() -> String: return state.accept_cooperation())
		)
	_add_button("Look for a supplier", func() -> void:
		_note(func() -> String: return state.find_supplier())
	)
	for id in state.known_suppliers:
		var supplier: GameState.Person = state.person(str(id))
		_add_label("%s  %s  love %d\n%s\nStrength: %s\nBad habit: %s (%s)\nAsk: %d a unit%s" % [
			supplier.display_name,
			state.hearts(supplier.love),
			supplier.love,
			supplier.balance,
			supplier.gift_line(),
			supplier.habit_line(),
			supplier.severity,
			supplier.ask,
			"" if supplier.active else "\nThe contract has ended.",
		])
		if not supplier.active:
			continue
		if state.pending_think.has(supplier.id):
			_bind_insist(supplier.id)
		var spin := _add_spin(supplier.ask, 1, 200)
		_bind_supply_offer(supplier.id, spin)
		_bind_break(supplier.id)
	_add_label("Open supply deals")
	_show_deals("supplier")


func _show_recruit() -> void:
	_add_button("Look for someone", func() -> void:
		_note(func() -> String: return state.look_for_applicant())
	)
	if state.visible_applicants.is_empty():
		_add_label("Nobody is waiting. Look, or wait for an application in the mail.")
	for id in state.visible_applicants:
		var applicant: GameState.Person = state.person(str(id))
		_add_label(state._applicant_card(applicant))
		if state.pending_think.has(applicant.id):
			_bind_insist(applicant.id)
		var spin := _add_spin(applicant.ask, 10, 2000)
		_bind_hire_offer(applicant.id, spin)


func _show_bank() -> void:
	_add_label("The rate on the sign is %s.\nDebt %d. Credit %d.\nA large loan and a good credit record each pull the rate down. The rate also changes on its own some weeks." % [state.rate_text(), state.debt, state.credit])
	var spin := _add_spin(1000, 100, 20000)
	_add_button("Borrow this amount", func() -> void:
		_note(func() -> String: return state.borrow(int(spin.value)))
	)
	if not state.pending_bailout.is_empty():
		_add_label("Someone is asking to borrow company money. The mail has the request.")


func _show_person(id: String) -> void:
	if not state.people.has(id):
		_add_label("That chair is empty.")
		return
	var p: GameState.Person = state.person(id)
	if not p.hired:
		_add_label("That chair is empty.")
		return
	_add_label("%s\n%s\n%s  love %d\nStrength: %s\nBad habit: %s (%s)\nWorkload step %d. Pace step %d.\nPay %d. Ask %d.%s" % [
		p.display_name,
		p.balance,
		state.hearts(p.love),
		p.love,
		p.gift_line(),
		p.habit_line(),
		p.severity,
		p.base_workload,
		p.base_pace,
		p.pay,
		p.ask,
		"\nOn a course this period. No deal work." if p.training else "",
	])
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
	_add_label("Deals they can follow")
	var any := false
	for deal in state.open_deals():
		any = true
		_deal_block(deal)
	if not any:
		_add_label("No open deal. Take an order or a supplier price first.")
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
