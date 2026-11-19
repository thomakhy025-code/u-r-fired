class_name GameState
extends RefCounted

## Real-time office. Desks make products, the outbox holds them, callers buy them.

const PRODUCT_ORDER: Array[String] = ["snack", "lunch", "sample", "classkit", "hamper"]
const SUPPLY_ORDER: Array[String] = ["sheets", "clips", "paper", "ink", "board", "cloth"]
const CALLER_NAMES: Array[String] = ["Nia Cole", "Ellis Park", "Remy Cho", "Jordan Hale", "Sable Quinn"]
const CALLER_FACES: Array[String] = ["nia", "ellis", "remy", "jordan", "sable"]
const UPGRADE_ORDER: Array[String] = ["faster", "outbox", "phone", "shelf"]
const RESTOCK_COST := 22
const RESTOCK_SECONDS := 4.0
const RESTOCK_AMOUNT := 3
const STAFF_MAX := 5

var rng := RandomNumberGenerator.new()
var company_name := "Company"
var cash := 48
var supplies: Dictionary = {}
var desks: Array[Desk] = []
var outbox: Array[String] = []
var callers: Array[Caller] = []
var staff: Array[Staff] = []
var messes: Array[Mess] = []
var outbox_slots := 2
var phone_lines := 1
var shelf_size := 8
var desk_rank := 0
var restock_left := 0.0
var spawn_wait := 9.0
var mess_wait := 14.0
var allow_tips := true
var ambient := true
var notice := ""
var last_mood := ""
var mood_left := 0.0
var next_caller := 0


func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value


class Desk:
	var product_id := ""
	var seconds_left := 0.0
	var seconds_full := 0.0
	var phase := "idle"


class Caller:
	var display_name := ""
	var face_id := ""
	var product_id := ""
	var patience := 0.0
	var patience_full := 0.0
	var pay := 0


class Staff:
	var id := ""
	var display_name := ""
	var role := ""
	var level := 1
	var hired := false
	var hire_cost := 30


class Mess:
	var kind := "papers"
	var coins := 4


func setup_new_game() -> void:
	cash = 48
	company_name = "Company"
	outbox_slots = 2
	phone_lines = 1
	shelf_size = 8
	desk_rank = 0
	restock_left = 0.0
	spawn_wait = 9.0
	mess_wait = 14.0
	allow_tips = true
	ambient = true
	notice = ""
	last_mood = ""
	mood_left = 0.0
	next_caller = 0
	supplies = {
		"sheets": 4,
		"clips": 4,
		"paper": 3,
		"ink": 3,
		"board": 2,
		"cloth": 2,
	}
	desks.clear()
	desks.append(Desk.new())
	desks.append(Desk.new())
	outbox.clear()
	callers.clear()
	messes.clear()
	staff.clear()
	_add_staff("mina", "Mina Pell", "PACK", 34)
	_add_staff("june", "June Orr", "DESK", 44)
	_add_staff("otto", "Otto Lang", "RUSH", 30)
	_add_staff("rosa", "Rosa Kim", "LINE", 38)


func _add_staff(id: String, display_name: String, role: String, hire_cost: int) -> void:
	var person := Staff.new()
	person.id = id
	person.display_name = display_name
	person.role = role
	person.hire_cost = hire_cost
	staff.append(person)


func supply_name(supply_id: String) -> String:
	match supply_id:
		"sheets":
			return "Card sheets"
		"clips":
			return "Clips"
		"paper":
			return "Paper rolls"
		"ink":
			return "Ink"
		"board":
			return "Board"
		"cloth":
			return "Cloth"
		_:
			return supply_id


func supply_qty(supply_id: String) -> int:
	return int(supplies.get(supply_id, 0))


func product_name(product_id: String) -> String:
	match product_id:
		"snack":
			return "Snack Boxes"
		"lunch":
			return "Lunch Packs"
		"sample":
			return "Sample Kits"
		"classkit":
			return "Class Kits"
		"hamper":
			return "Gift Hampers"
		_:
			return product_id


func product_cost(product_id: String) -> int:
	match product_id:
		"snack":
			return 6
		"lunch":
			return 8
		"sample":
			return 10
		"classkit":
			return 14
		"hamper":
			return 18
		_:
			return 0


func product_seconds(product_id: String) -> float:
	match product_id:
		"snack":
			return 6.0
		"lunch":
			return 8.0
		"sample":
			return 9.0
		"classkit":
			return 11.0
		"hamper":
			return 13.0
		_:
			return 6.0


func product_pay(product_id: String) -> int:
	match product_id:
		"snack":
			return 18
		"lunch":
			return 26
		"sample":
			return 34
		"classkit":
			return 44
		"hamper":
			return 58
		_:
			return 0


func product_patience(product_id: String) -> float:
	match product_id:
		"snack":
			return 22.0
		"lunch":
			return 18.0
		"sample":
			return 15.0
		"classkit":
			return 12.0
		"hamper":
			return 9.0
		_:
			return 22.0


func need_count(product_id: String, supply_id: String) -> int:
	match product_id:
		"snack":
			if supply_id == "sheets" or supply_id == "clips":
				return 1
		"lunch":
			if supply_id == "paper" or supply_id == "ink":
				return 1
		"sample":
			if supply_id == "sheets" or supply_id == "ink":
				return 1
		"classkit":
			if supply_id == "board" or supply_id == "clips":
				return 1
		"hamper":
			if supply_id == "board" or supply_id == "cloth":
				return 1
	return 0


func speed_factor() -> float:
	var factor := 1.0
	var rank := 0
	while rank < desk_rank:
		factor *= 0.82
		rank += 1
	for person in staff:
		if person.hired:
			factor *= 1.0 - 0.06 * float(person.level)
	if factor < 0.35:
		return 0.35
	return factor


func job_seconds(product_id: String) -> float:
	var seconds := product_seconds(product_id) * speed_factor()
	if seconds < 1.0:
		return 1.0
	return seconds


func clock_text(seconds: float) -> String:
	var whole := maxi(int(ceil(seconds)), 0)
	if whole >= 60:
		return "%d:%02d" % [int(whole / 60), whole % 60]
	return "%ds" % whole


func start_job(desk_index: int, product_id: String) -> String:
	if desk_index < 0 or desk_index >= desks.size():
		return "That desk is missing."
	if not PRODUCT_ORDER.has(product_id):
		return "Pick a job from the desk."
	var desk := desks[desk_index]
	if desk.phase != "idle":
		return "That desk is busy."
	var cost := product_cost(product_id)
	if cash < cost:
		return "Need %d cash." % cost
	var missing := ""
	for supply_id in SUPPLY_ORDER:
		var count := need_count(product_id, supply_id)
		if count > supply_qty(supply_id):
			missing = supply_name(supply_id)
			break
	if missing != "":
		return "Need %s." % missing
	cash -= cost
	for supply_id in SUPPLY_ORDER:
		var count := need_count(product_id, supply_id)
		if count > 0:
			supplies[supply_id] = supply_qty(supply_id) - count
	var seconds := job_seconds(product_id)
	desk.product_id = product_id
	desk.seconds_left = seconds
	desk.seconds_full = seconds
	desk.phase = "cooking"
	return "Started %s." % product_name(product_id)


func place_on_outbox(desk_index: int) -> String:
	if desk_index < 0 or desk_index >= desks.size():
		return "That desk is missing."
	var desk := desks[desk_index]
	if desk.phase != "done":
		return "That desk is still working."
	if outbox.size() >= outbox_slots:
		return "The outbox is full."
	var product_id := desk.product_id
	outbox.append(product_id)
	desk.product_id = ""
	desk.seconds_left = 0.0
	desk.seconds_full = 0.0
	desk.phase = "idle"
	return "%s is on the outbox." % product_name(product_id)


func spawn_caller(product_id: String) -> String:
	if callers.size() >= phone_lines:
		return "The lines are full."
	if not PRODUCT_ORDER.has(product_id):
		return "Nobody calls for that."
	var caller := Caller.new()
	var name_index := next_caller % CALLER_NAMES.size()
	next_caller += 1
	caller.display_name = CALLER_NAMES[name_index]
	caller.face_id = CALLER_FACES[name_index]
	caller.product_id = product_id
	caller.pay = product_pay(product_id)
	caller.patience_full = product_patience(product_id)
	caller.patience = caller.patience_full
	callers.append(caller)
	notice = "%s wants %s." % [caller.display_name, product_name(product_id)]
	return notice


func hand_over(caller_index: int) -> String:
	if caller_index < 0 or caller_index >= callers.size():
		return "Nobody is on the line."
	var caller := callers[caller_index]
	var slot := outbox.find(caller.product_id)
	if slot < 0:
		return "Put %s on the outbox first." % product_name(caller.product_id)
	return _complete_handoff(caller_index, slot, true)


func hand_outbox_slot(slot: int) -> String:
	if slot < 0 or slot >= outbox.size():
		return "That slot is empty."
	if callers.is_empty():
		return "The phone is quiet."
	var product_id := outbox[slot]
	var match_index := -1
	for caller_index in callers.size():
		if callers[caller_index].product_id == product_id:
			match_index = caller_index
			break
	if match_index >= 0:
		return _complete_handoff(match_index, slot, true)
	return _complete_handoff(0, slot, false)


func order_restock() -> String:
	if restock_left > 0.0:
		return "A delivery is on the way."
	if cash < RESTOCK_COST:
		return "Need %d cash." % RESTOCK_COST
	var room := false
	for supply_id in SUPPLY_ORDER:
		if supply_qty(supply_id) < shelf_size:
			room = true
			break
	if not room:
		return "The shelf is full."
	cash -= RESTOCK_COST
	restock_left = RESTOCK_SECONDS
	return "Supplies arrive in %s." % clock_text(RESTOCK_SECONDS)


func clean_mess(index: int) -> String:
	if index < 0 or index >= messes.size():
		return "That spot is clear."
	var coins := messes[index].coins
	messes.remove_at(index)
	cash += coins
	return "Cleaned up. +%d" % coins


func hire(staff_id: String) -> String:
	var index := _staff_index(staff_id)
	if index < 0:
		return "That card is missing."
	var person := staff[index]
	if person.hired:
		return "%s is already here." % person.display_name
	if cash < person.hire_cost:
		return "Need %d cash." % person.hire_cost
	cash -= person.hire_cost
	person.hired = true
	return "%s joined the office." % person.display_name


func upgrade_staff(staff_id: String) -> String:
	var index := _staff_index(staff_id)
	if index < 0:
		return "That card is missing."
	var person := staff[index]
	if not person.hired:
		return "Hire %s first." % person.display_name
	if person.level >= STAFF_MAX:
		return "%s is at the top level." % person.display_name
	var cost := staff_upgrade_cost(person.level)
	if cash < cost:
		return "Need %d cash." % cost
	cash -= cost
	person.level += 1
	return "%s is level %d." % [person.display_name, person.level]


func staff_upgrade_cost(level: int) -> int:
	return 20 + level * 8


func upgrade_open(upgrade_id: String) -> bool:
	match upgrade_id:
		"faster":
			return desk_rank < 4
		"outbox":
			return outbox_slots < 4
		"phone":
			return phone_lines < 2
		"shelf":
			return shelf_size < 16
		_:
			return false


func upgrade_cost(upgrade_id: String) -> int:
	match upgrade_id:
		"faster":
			return 36 + desk_rank * 18
		"outbox":
			return 32
		"phone":
			return 40
		"shelf":
			return 28
		_:
			return 0


func upgrade_title(upgrade_id: String) -> String:
	match upgrade_id:
		"faster":
			return "Faster desk"
		"outbox":
			return "Outbox slot"
		"phone":
			return "Second line"
		"shelf":
			return "Bigger shelf"
		_:
			return "Upgrade"


func upgrade_label(upgrade_id: String) -> String:
	if upgrade_open(upgrade_id):
		return "%s  %d" % [upgrade_title(upgrade_id), upgrade_cost(upgrade_id)]
	match upgrade_id:
		"faster":
			return "Desks upgraded"
		"outbox":
			return "Outbox ready"
		"phone":
			return "Both lines open"
		"shelf":
			return "Shelf expanded"
		_:
			return "Done"


func buy_upgrade(upgrade_id: String) -> String:
	if not upgrade_open(upgrade_id):
		return "That is already in the room."
	var cost := upgrade_cost(upgrade_id)
	if cash < cost:
		return "Need %d cash." % cost
	cash -= cost
	match upgrade_id:
		"faster":
			desk_rank += 1
			return "The desks are faster."
		"outbox":
			outbox_slots += 1
			return "The outbox has another slot."
		"phone":
			phone_lines += 1
			return "A second line is open."
		"shelf":
			shelf_size += 4
			return "The supply shelf is bigger."
		_:
			return "That upgrade is missing."


func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	for desk in desks:
		if desk.phase != "cooking":
			continue
		desk.seconds_left -= delta
		if desk.seconds_left <= 0.0:
			desk.seconds_left = 0.0
			desk.phase = "done"
	var caller_index := callers.size() - 1
	while caller_index >= 0:
		var caller := callers[caller_index]
		caller.patience -= delta
		if caller.patience <= 0.0:
			notice = "%s hung up unhappy." % caller.display_name
			_set_mood("unhappy")
			callers.remove_at(caller_index)
		caller_index -= 1
	if restock_left > 0.0:
		restock_left = maxf(restock_left - delta, 0.0)
		if restock_left == 0.0:
			_apply_restock()
			notice = "Supplies arrived."
	if mood_left > 0.0:
		mood_left = maxf(mood_left - delta, 0.0)
		if mood_left == 0.0:
			last_mood = ""
	if not ambient:
		return
	spawn_wait -= delta
	if spawn_wait <= 0.0:
		spawn_wait = rng.randf_range(8.0, 13.0)
		if callers.size() < phone_lines:
			spawn_caller(_ambient_product())
	mess_wait -= delta
	if mess_wait <= 0.0:
		mess_wait = 15.0
		_maybe_mess()


func _staff_index(staff_id: String) -> int:
	for index in staff.size():
		if staff[index].id == staff_id:
			return index
	return -1


func _complete_handoff(caller_index: int, slot: int, matched: bool) -> String:
	var caller := callers[caller_index]
	outbox.remove_at(slot)
	callers.remove_at(caller_index)
	if not matched:
		_set_mood("unhappy")
		return "%s hung up unhappy." % caller.display_name
	var tip := 0
	if allow_tips and rng.randf() < 0.28:
		tip = 5
	cash += caller.pay + tip
	_set_mood("happy")
	if tip > 0:
		return "%s paid %d and left a %d tip." % [caller.display_name, caller.pay, tip]
	return "%s paid %d." % [caller.display_name, caller.pay]


func _set_mood(mood: String) -> void:
	last_mood = mood
	mood_left = 1.8


func _apply_restock() -> void:
	for supply_id in SUPPLY_ORDER:
		var next := supply_qty(supply_id) + RESTOCK_AMOUNT
		if next > shelf_size:
			next = shelf_size
		supplies[supply_id] = next


func _ambient_product() -> String:
	if not outbox.is_empty() and rng.randf() < 0.75:
		return outbox[rng.randi() % outbox.size()]
	var roll := rng.randi() % 10
	if roll < 4:
		return "snack"
	if roll < 7:
		return "lunch"
	if roll < 8:
		return "sample"
	if roll < 9:
		return "classkit"
	return "hamper"


func _maybe_mess() -> void:
	if messes.size() >= 3:
		return
	if rng.randf() > 0.7:
		return
	var mess := Mess.new()
	if rng.randf() < 0.45:
		mess.kind = "cup"
		mess.coins = 4
	else:
		mess.kind = "papers"
		mess.coins = 3
	messes.append(mess)
