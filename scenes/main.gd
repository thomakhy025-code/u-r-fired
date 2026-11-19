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
var cloud: Cloud
var gate: Control
var name_box: LineEdit
var gate_note: Label
var started := false
var pending_hire_id := ""
var pending_hire_pay := 0
var rank_rows: Array = []
var market_rows: Array = []
var paid_sales := {}
var chosen_employee := ""
var call_card: PanelContainer
var call_title: Label
var call_body: Label
var call_fill: ColorRect
var call_id := ""
var call_left := 0.0
const CALL_PATIENCE := 48.0


func _ready() -> void:
	state = GameState.new()
	state.setup_new_game()
	cloud = Cloud.new()
	cloud.account_changed.connect(_on_account)
	cloud.board_arrived.connect(_on_board)
	cloud.market_arrived.connect(_on_market)
	cloud.claim_arrived.connect(_on_claim)
	cloud.sale_arrived.connect(_on_sale)
	add_child(cloud)
	_build()
	_build_gate()
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

	var plaque := PanelContainer.new()
	plaque.position = Vector2(20, 12)
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plaque.add_theme_stylebox_override("panel", _sign_box(Color("3e3128")))
	hud.add_child(plaque)
	header = Label.new()
	header.add_theme_font_override("font", ThemeDB.fallback_font)
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", CREAM)
	plaque.add_child(header)

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
	_sign(shelf, "Calls", CLAY, func() -> void: view = "orders"; _show_view())
	_sign(shelf, "Suppliers", SEA, func() -> void: view = "suppliers"; _show_view())
	_sign(shelf, "Recruit", PLUM, func() -> void: view = "recruit"; _show_view())
	bank_button = _sign(shelf, "Bank", GOLD, func() -> void: view = "bank"; _show_view())
	_sign(shelf, "Rank", Color("6e5d48"), func() -> void:
		view = "rank"
		cloud.load_board()
		cloud.push_company(_company_card())
		_show_view()
	)
	_sign(shelf, "Market", Color("5d5d78"), func() -> void:
		view = "market"
		cloud.load_market()
		_show_view()
	)
	_build_call(hud)
	end_button = _sign(shelf, "End week", MOSS, func() -> void:
		status = state.end_week()
		view = "mail"
		cloud.push_company(_company_card())
		_show_view()
	)


func _warm_theme() -> Theme:
	var warm := Theme.new()
	warm.default_font = ThemeDB.fallback_font
	warm.default_font_size = 18
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
	button.add_theme_font_override("font", ThemeDB.fallback_font)
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
	if seat == -2:
		view = "orders"
		status = "The phone is the call desk. A ringing light means someone is waiting."
		_show_view()
		return
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
	header.text = "%s    Week %d    Cash %d    Ready %d    Debt %d" % [state.company_name, state.week, state.cash, state.stock, state.debt]
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
	elif view == "rank":
		_show_rank()
	elif view == "market":
		_show_market()
	elif view.begins_with("person:"):
		_show_person(view.substr(7))
	else:
		_show_home()


func _show_home() -> void:
	_card(SAGE, ["How a call becomes a box", "The phone rings", "A desk prepares the work", "The outbox sends it"])
	for customer in state._customers():
		_card(CLAY, [customer.display_name, "Buys " + customer.goods, customer.recipe, "Love %s" % state.hearts(customer.love)], customer.id)
	_card(SEA, ["The floor", "Four desks, one phone, one outbox", "Calls wait on the phone", "Ready stock sits on the outbox"])


func _card(tint: Color, columns: Array, face_id: String = "") -> void:
	var row := PanelContainer.new()
	var box := _paper_box(tint)
	box.bg_color = Color("f4eadc")
	box.border_width_left = 8
	box.border_color = tint
	row.add_theme_stylebox_override("panel", box)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	row.add_child(line)
	if face_id != "":
		line.add_child(FaceBadge.for_id(face_id))
	for i in columns.size():
		var text := str(columns[i])
		if text == "":
			continue
		var label := Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_override("font", ThemeDB.fallback_font)
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
		_card(CLAY, ["Calls", "The phone is quiet.", "Hire someone and a customer will call."])


func _deal_block(deal: Dictionary) -> void:
	var partner: GameState.Person = state.person(str(deal["partner_id"]))
	var crew_names: Array = []
	for member_id in deal["crew"]:
		crew_names.append(state.person(str(member_id)).display_name)
	var crew_text := "Nobody is following it." if crew_names.is_empty() else ", ".join(crew_names)
	var bought := partner.goods if partner.goods != "" else "units"
	_card(CLAY if str(deal["kind"]) == "customer" else SEA, [
		_call_stage(str(deal["stage"])) if str(deal["kind"]) == "customer" else str(deal["stage"]).capitalize(),
		partner.display_name,
		"%d %s at %d" % [int(deal["units"]), bought, int(deal["unit_price"])],
		"Love %s" % state.hearts(partner.love),
	], partner.id)
	if str(deal["stage"]) == "offer":
		var offer_id := str(deal["id"])
		_add_button("Pick up", func() -> void:
			call_id = ""
			_note(func() -> String: return state.accept_order(offer_id))
		)
		_add_button("Let it ring out", func() -> void:
			call_id = ""
			_note(func() -> String: return state.reject_order(offer_id))
		)
	elif str(deal["stage"]) == "quality":
		var quality_id := str(deal["id"])
		_add_button("Give the money back", func() -> void:
			_note(func() -> String: return state.answer_quality(quality_id, true))
		)
		_add_button("Offer a discount", func() -> void:
			_note(func() -> String: return state.answer_quality(quality_id, false))
		)
		return
	else:
		_card(GOLD, ["Made by", partner.recipe if partner.recipe != "" else "Staff follow the deal.", "Following: " + crew_text, partner.habit_line()])
		for hired in state.hired_people():
			var deal_id := str(deal["id"])
			var employee_id: String = str(hired.id)
			var on_deal: bool = (deal["crew"] as Array).has(employee_id)
			var verb := ("Take %s off" % hired.display_name) if on_deal else ("Assign %s" % hired.display_name)
			_bind_assign(employee_id, deal_id, on_deal, verb)
	if str(deal["kind"]) == "customer":
		_sell_into_order(deal)

func _show_suppliers() -> void:
	if state.cooperate_from != "":
		var asking: GameState.Person = state.person(state.cooperate_from)
		_card(SEA, [asking.display_name, "Sells " + asking.goods, "Asks %d" % asking.ask, "Love %s" % state.hearts(asking.love)], asking.id)
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
			("Love %s" % state.hearts(supplier.love)) if supplier.active else "Contract ended",
		], supplier.id)
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
		_card(PLUM, [applicant.display_name, applicant.gift_line(), applicant.habit_line(), "Ask %d    Love %s" % [applicant.ask, state.hearts(applicant.love)]], applicant.id)
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
	_card(PLUM, [p.display_name, p.balance, "Love %s" % state.hearts(p.love), "Pay %d" % p.pay], p.id)
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
		cloud.release(who)
		_note(func() -> String:
			var text: String = state.fire(who)
			view = "home"
			return text
		)
	)
	_add_button("Choose them to sell", func() -> void:
		chosen_employee = who
		view = "market"
		cloud.load_market()
		_show_view()
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


func _build_gate() -> void:
	gate = PanelContainer.new()
	gate.set_anchors_preset(Control.PRESET_FULL_RECT)
	gate.offset_left = 48
	gate.offset_top = 36
	gate.offset_right = -48
	gate.offset_bottom = -36
	gate.add_theme_stylebox_override("panel", _paper_box(Color("8a7356")))
	add_child(gate)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gate.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)
	var title := Label.new()
	title.text = "Open the company"
	title.add_theme_font_override("font", ThemeDB.fallback_font)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", INK)
	box.add_child(title)
	for line in [
		"1. Name the company. You are the director. You do not walk. You press the shelf.",
		"2. Hire someone on Recruit. There are four chairs. Signed in, the person you hire cannot be hired by another player.",
		"3. The phone rings. Pick it up, or let it ring out. Pick up, and they may call back at a higher price. Let it ring out, and they may not call again.",
		"4. While the call is open, find a supplier. You pay cash when the supplies arrive. A desk starts once those supplies are in the office.",
		"5. You are paid when the caller takes the goods. On Market, the Ready column is the outbox. Sell that stock when your price is one they will pay.",
		"6. If they dislike the quality, choose a refund or a discount. Choose an employee on Market to sell them to another company.",
		"Love is a number out of 5. It changes how much and how fast the work goes. It does not stop a bad habit.",
	]:
		var step := Label.new()
		step.text = line
		step.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		step.custom_minimum_size = Vector2(720, 0)
		step.add_theme_font_override("font", ThemeDB.fallback_font)
		step.add_theme_color_override("font_color", INK)
		box.add_child(step)
	name_box = LineEdit.new()
	name_box.placeholder_text = "Company name"
	name_box.text = "Oak Desk"
	name_box.custom_minimum_size = Vector2(280, 40)
	name_box.add_theme_font_override("font", ThemeDB.fallback_font)
	box.add_child(name_box)
	var guest := Button.new()
	guest.text = "Play as guest"
	guest.add_theme_font_override("font", ThemeDB.fallback_font)
	guest.pressed.connect(_play_guest)
	box.add_child(guest)
	var google := Button.new()
	google.text = "Sign in with Google"
	google.add_theme_font_override("font", ThemeDB.fallback_font)
	google.pressed.connect(func() -> void: cloud.sign_in())
	box.add_child(google)
	gate_note = Label.new()
	gate_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gate_note.add_theme_font_override("font", ThemeDB.fallback_font)
	gate_note.add_theme_color_override("font_color", INK)
	gate_note.text = "A guest keeps this office on this computer. Google keeps the company, the ranking, and the staff market."
	box.add_child(gate_note)


func _play_guest() -> void:
	var named := name_box.text.strip_edges()
	if named.length() < 2:
		gate_note.text = "Give the company a name of at least 2 letters."
		return
	state.company_name = named
	started = true
	gate.visible = false
	_show_view()


func _company_card() -> Dictionary:
	var best_output := 0
	for person in state.hired_people():
		best_output = maxi(best_output, person.made)
	return {
		"name": state.company_name,
		"profit": state.lifetime_profit,
		"capital": state.cash,
		"workers": state.hired_people().size(),
		"best_worker": state.best_worker_name(),
		"best_output": best_output,
	}


func _on_account() -> void:
	if gate_note == null:
		return
	if cloud.last_error != "":
		gate_note.text = cloud.last_error
	elif cloud.signed_in and not started:
		var named := name_box.text.strip_edges()
		if named.length() < 2:
			named = cloud.display_name if cloud.display_name != "" else "Company"
		state.company_name = named
		started = true
		gate.visible = false
		gate_note.text = "Signed in."
		_show_view()
	elif cloud.signed_in:
		gate_note.text = "Signed in as %s." % cloud.display_name


func _on_board(rows: Array) -> void:
	rank_rows = rows
	if view == "rank":
		_show_view()


func _on_market(rows: Array) -> void:
	market_rows = rows
	if view == "market":
		_show_view()


func _on_claim(person_id: String, ok: bool, reason: String) -> void:
	if pending_hire_id == "" or person_id != pending_hire_id:
		return
	var who := pending_hire_id
	var pay := pending_hire_pay
	pending_hire_id = ""
	if not ok:
		status = reason
		_show_view()
		return
	_note(func() -> String: return state.recruit_offer(who, pay))


func _on_sale(ok: bool, reason: String, info: Dictionary) -> void:
	if not ok:
		status = reason if reason != "" else "The market did not move."
		_show_view()
		return
	var kind := str(info.get("kind", ""))
	if kind == "buy":
		var price := int(info.get("price", 0))
		var person_id := str(info.get("person", ""))
		if state.hired_people().size() >= GameState.SEAT_COUNT:
			status = "Every chair is full, so the transfer waits."
			_show_view()
			return
		if state.people.has(person_id) and not state.person(person_id).hired:
			if not state.visible_applicants.has(person_id):
				state.visible_applicants.append(person_id)
			state.hidden_applicants.erase(person_id)
			state.cash -= price
			var hired: String = state.recruit_offer(person_id, state.person(person_id).ask)
			status = "Paid %d. %s" % [price, hired]
		else:
			status = "%s is already here." % str(info.get("name", "They"))
	elif info.has("person") and not info.has("kind"):
		var sale_key := str(info.get("id", ""))
		if paid_sales.has(sale_key):
			return
		paid_sales[sale_key] = true
		var sold_id := str(info.get("person", ""))
		var sold_name := state.release_to_market(sold_id)
		var gained := int(info.get("price", 0))
		if sold_name != "":
			state.cash += gained
			status = "%s joined another company. You received %d." % [sold_name, gained]
	else:
		status = reason if reason != "" else "The listing is on the market."
	cloud.load_market()
	_show_view()


func _show_rank() -> void:
	_card(GOLD, ["Company", "Profit", "Capital", "Workers"])
	if rank_rows.is_empty():
		_card(SEA, ["Ranking", "No companies posted yet.", "End a week while signed in.", ""])
		return
	rank_rows.sort_custom(func(a, b) -> bool:
		return int(a.get("profit", 0)) > int(b.get("profit", 0))
	)
	for row in rank_rows:
		var best := str(row.get("best_worker", ""))
		if best == "":
			best = "none yet"
		_card(SAGE, [
			str(row.get("name", "Company")),
			"Profit %d" % int(row.get("profit", 0)),
			"Capital %d" % int(row.get("capital", 0)),
			"Workers %d    Best %s, %d made" % [int(row.get("workers", 0)), best, int(row.get("best_output", 0))],
		])


func _build_call(parent: Control) -> void:
	call_card = PanelContainer.new()
	call_card.visible = false
	call_card.mouse_filter = Control.MOUSE_FILTER_STOP
	call_card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	call_card.offset_left = -250
	call_card.offset_top = 58
	call_card.offset_right = 250
	call_card.offset_bottom = 250
	call_card.add_theme_stylebox_override("panel", _paper_box(Color("e06a58")))
	parent.add_child(call_card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	call_card.add_child(box)
	call_title = Label.new()
	call_title.add_theme_font_override("font", ThemeDB.fallback_font)
	call_title.add_theme_font_size_override("font_size", 22)
	call_title.add_theme_color_override("font_color", INK)
	box.add_child(call_title)
	call_body = Label.new()
	call_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	call_body.custom_minimum_size = Vector2(420, 0)
	call_body.add_theme_font_override("font", ThemeDB.fallback_font)
	call_body.add_theme_color_override("font_color", INK)
	box.add_child(call_body)
	var track := ColorRect.new()
	track.custom_minimum_size = Vector2(420, 16)
	track.color = Color("3a2c24")
	box.add_child(track)
	call_fill = ColorRect.new()
	call_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	call_fill.color = Color("3f9a4a")
	track.add_child(call_fill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var pick := Button.new()
	pick.text = "Pick up"
	pick.add_theme_font_override("font", ThemeDB.fallback_font)
	pick.pressed.connect(_pick_up)
	row.add_child(pick)
	var leave := Button.new()
	leave.text = "Let it ring out"
	leave.add_theme_font_override("font", ThemeDB.fallback_font)
	leave.pressed.connect(_ring_out)
	row.add_child(leave)


func _process(delta: float) -> void:
	if not started or call_card == null or state == null or state.lost:
		if call_card != null:
			call_card.visible = false
		return
	var offer := _waiting_call()
	if offer.is_empty():
		call_id = ""
		call_card.visible = false
		return
	var id := str(offer["id"])
	if id != call_id:
		call_id = id
		call_left = CALL_PATIENCE
	call_left = maxf(call_left - delta, 0.0)
	var buyer: GameState.Person = state.person(str(offer["partner_id"]))
	var goods := buyer.goods if buyer.goods != "" else "units"
	call_title.text = "%s is calling" % buyer.display_name
	call_body.text = "%d %s at %d each. The bar is how long they stay on the line." % [int(offer["units"]), goods, int(offer["unit_price"])]
	var ratio := clampf(call_left / CALL_PATIENCE, 0.0, 1.0)
	call_fill.offset_right = -420.0 * (1.0 - ratio)
	call_fill.color = Color("3f9a4a").lerp(Color("c4473a"), 1.0 - ratio)
	call_card.visible = true
	if call_left <= 0.0:
		var ended := call_id
		call_id = ""
		call_card.visible = false
		status = state.reject_order(ended)
		_show_view()


func _waiting_call() -> Dictionary:
	for deal in state.open_deals():
		if str(deal["kind"]) == "customer" and str(deal["stage"]) == "offer":
			return deal
	return {}


func _pick_up() -> void:
	if call_id == "":
		return
	var id := call_id
	call_id = ""
	call_card.visible = false
	status = state.accept_order(id)
	view = "orders"
	_show_view()


func _ring_out() -> void:
	if call_id == "":
		return
	var id := call_id
	call_id = ""
	call_card.visible = false
	status = state.reject_order(id)
	view = "orders"
	_show_view()


func _call_stage(stage: String) -> String:
	match stage:
		"offer":
			return "Calling"
		"proposal":
			return "On the call"
		"doing":
			return "At the desk"
		"almost":
			return "Ready to send"
		"quality":
			return "Not happy"
		_:
			return stage.capitalize()


func _show_market() -> void:
	if chosen_employee != "" and (not state.people.has(chosen_employee) or not state.person(chosen_employee).hired):
		chosen_employee = ""
	_card(SEA, ["Outbox", "Ready stock", "Qty %d" % state.stock, "Sits on the counter"])
	_card(GOLD, ["Order", "Product", "Qty needed", "Pays up to"])
	var any_order := false
	for deal in state.open_deals():
		if str(deal["kind"]) != "customer" or str(deal["stage"]) == "quality":
			continue
		any_order = true
		var buyer: GameState.Person = state.person(str(deal["partner_id"]))
		_card(CLAY, [
			buyer.display_name,
			buyer.goods,
			"Qty %d" % int(deal["units"]),
			"Pays up to %d" % state.order_ceiling(buyer),
		], buyer.id)
		_sell_into_order(deal)
	if not any_order:
		_card(CLAY, ["Orders", "None are open.", "Hire someone and an order arrives.", "Inventory Qty %d" % state.stock])
	_card(PLUM, ["Employee", "Ability", "Love", "Choose to sell"])
	if state.hired_people().is_empty():
		_card(PLUM, ["Employees", "Nobody is hired.", "Hire on Recruit, then choose them here.", ""])
	for person in state.hired_people():
		var picked: bool = chosen_employee == person.id
		_card(PLUM, [
			person.display_name,
			person.gift_line(),
			"Love %s" % state.hearts(person.love),
			"Chosen" if picked else "On the desk",
		], person.id)
		_bind_choose_employee(person.id, person.display_name, picked)
		if picked:
			var asking := maxi(person.pay * 4, 100)
			var price_box := _add_spin(asking, 100, 20000)
			_bind_list_employee(person.id, price_box)
	if not cloud.signed_in:
		_card(GOLD, ["Other companies", "Sign in with Google to buy or receive a person.", "A guest can still sell parts into an order.", ""])
		return
	_card(SAGE, ["For sale", "Ability", "Price", "Agree"])
	if market_rows.is_empty():
		_card(SEA, ["Other companies", "Nobody is listed.", "Choose one of your employees and set a price.", ""])
	for row in market_rows:
		_card(PLUM, [
			str(row.get("name", "")),
			str(row.get("ability", "")),
			"Price %d" % int(row.get("price", 0)),
			"Love travels with them",
		], str(row.get("person", "")))
		_bind_agree(str(row.get("id", "")), int(row.get("price", 0)))


func _sell_into_order(deal: Dictionary) -> void:
	var deal_id := str(deal["id"])
	var buyer: GameState.Person = state.person(str(deal["partner_id"]))
	var ceiling := state.order_ceiling(buyer)
	var price_box := _add_spin(buyer.ask, 1, maxi(ceiling * 2, buyer.ask + 1))
	_add_button("Sell Qty %d at this price" % int(deal["units"]), func() -> void:
		_note(func() -> String: return state.sell_to_order(deal_id, int(price_box.value)))
	)


func _bind_choose_employee(person_id: String, person_name: String, picked: bool) -> void:
	var label := "Chosen" if picked else "Choose %s" % person_name
	_add_button(label, func() -> void:
		chosen_employee = "" if picked else person_id
		_show_view()
	)


func _bind_list_employee(person_id: String, price_box: SpinBox) -> void:
	var person := state.person(person_id)
	_add_button("Sell %s to another company" % person.display_name, func() -> void:
		cloud.list_sale(person_id, person.display_name, person.gift_line(), int(price_box.value))
	)


func _bind_agree(listing_id: String, price: int) -> void:
	_add_button("Agree and pay %d" % price, func() -> void:
		if state.hired_people().size() >= GameState.SEAT_COUNT:
			status = "Every chair is full."
			_show_view()
			return
		if state.cash < price:
			status = "Cash is short for this transfer."
			_show_view()
			return
		cloud.buy(listing_id)
	)


func _bind_hire_offer(who: String, spin: SpinBox) -> void:
	_add_button("Offer this salary", func() -> void:
		pending_hire_id = who
		pending_hire_pay = int(spin.value)
		var person := state.person(who)
		cloud.claim(who, person.display_name, person.gift_line())
	)
