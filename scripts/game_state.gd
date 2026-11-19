class_name GameState
extends RefCounted

## Real-time office. Customers call for chairs and mobile phones.
## Employees take the call, the bench crafts from supplier materials, and love falls while a caller waits.
## The opening lesson holds that love until the first payout, so the first deal can be finished.

const MATERIAL_ORDER: Array[String] = ["wood", "plastic", "glass"]
const CALLER_NAMES: Array[String] = ["Nia Cole", "Ellis Park", "Remy Cho", "Jordan Hale", "Sable Quinn"]
const CALLER_FACES: Array[String] = ["nia", "ellis", "remy", "jordan", "sable"]
const PACK_QTY: int = 2
const LOVE_MAX: int = 5
const LOVE_PER_SECOND: float = 0.2
const SKILL_MAX: int = 5
const START_CASH: int = 40

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var company_name: String = "Company"
var cash: int = START_CASH
var skill: int = 1
var materials: Dictionary[String, int] = {}
var goods: Dictionary[String, int] = {}
var employees: Array[Employee] = []
var caller: Caller = null
var craft: CraftJob = null
var notice: String = ""
var ambient: bool = true
var spawn_wait: float = 1.2
var calls_made: int = 0
var next_caller: int = 0
var teaching: bool = true


func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value


class Employee:
	var id: String = ""
	var display_name: String = ""
	var role: String = ""
	var level: int = 1
	var face_id: String = ""
	var commission: int = 0
	var calls_closed: int = 0
	var busy: bool = false


class Caller:
	var display_name: String = ""
	var face_id: String = ""
	var product_id: String = ""
	var qty: int = 1
	var love: float = 5.0
	var pay: int = 0
	var phase: String = "waiting"
	var employee_id: String = ""
	var seconds_left: float = 0.0
	var seconds_full: float = 0.0


class CraftJob:
	var product_id: String = ""
	var seconds_left: float = 0.0
	var seconds_full: float = 0.0


func setup_new_game() -> void:
	cash = START_CASH
	skill = 1
	company_name = "Company"
	notice = "The phone will ring."
	ambient = true
	spawn_wait = 1.2
	calls_made = 0
	next_caller = 0
	teaching = true
	caller = null
	craft = null
	materials.clear()
	materials["wood"] = 0
	materials["plastic"] = 0
	materials["glass"] = 0
	goods.clear()
	goods["chair"] = 0
	goods["phone"] = 0
	employees.clear()
	_add_employee("mina", "Mina Pell", "Calls", 1)
	_add_employee("june", "June Orr", "Floor", 2)
	_add_employee("otto", "Otto Lang", "Bench", 3)
	_add_employee("rosa", "Rosa Kim", "Desk", 4)


func _add_employee(id: String, display_name: String, role: String, level: int) -> void:
	var person := Employee.new()
	person.id = id
	person.display_name = display_name
	person.role = role
	person.level = level
	person.face_id = id
	employees.append(person)


func find_employee(employee_id: String) -> Employee:
	var index: int = 0
	while index < employees.size():
		var person: Employee = employees[index]
		if person.id == employee_id:
			return person
		index += 1
	return null


func material_name(material_id: String) -> String:
	match material_id:
		"wood":
			return "Wood"
		"plastic":
			return "Plastic"
		"glass":
			return "Glass"
		_:
			return material_id


func material_qty(material_id: String) -> int:
	if not materials.has(material_id):
		return 0
	return int(materials[material_id])


func goods_qty(product_id: String) -> int:
	if not goods.has(product_id):
		return 0
	return int(goods[product_id])


func product_name(product_id: String) -> String:
	match product_id:
		"chair":
			return "chair"
		"phone":
			return "mobile phone"
		_:
			return product_id


func product_label(product_id: String) -> String:
	match product_id:
		"chair":
			return "Chair"
		"phone":
			return "Phone"
		_:
			return "Order"


func product_phrase(product_id: String, qty: int) -> String:
	var name := product_name(product_id)
	if qty == 1:
		return "1 %s" % name
	return "%d %ss" % [qty, name]


func unit_pay(product_id: String) -> int:
	match product_id:
		"chair":
			return 16
		"phone":
			return 24
		_:
			return 0


func pack_cost(material_id: String) -> int:
	match material_id:
		"wood":
			return 8
		"plastic":
			return 8
		"glass":
			return 10
		_:
			return 0


func recipe_count(product_id: String, material_id: String) -> int:
	if product_id == "chair" and (material_id == "wood" or material_id == "plastic"):
		return 1
	if product_id == "phone" and (material_id == "plastic" or material_id == "glass"):
		return 1
	return 0


func craft_seconds() -> float:
	var seconds := 4.0
	var level := 1
	while level < skill:
		seconds *= 0.75
		level += 1
	if seconds < 1.25:
		return 1.25
	return seconds


func research_cost() -> int:
	return 14 + skill * 6


func answer_seconds(product_id: String, qty: int) -> float:
	var seconds := 3.0
	var extra := qty - 1
	if extra > 0:
		seconds += float(extra) * 1.5
	if product_id == "phone":
		seconds += 0.6
	return seconds


func starting_love(qty: int) -> float:
	if qty >= 2:
		return 4.0
	return 5.0


func love_points(love: float) -> int:
	if love >= float(LOVE_MAX):
		return LOVE_MAX
	if love <= 0.0:
		return 0
	var points := int(ceil(love))
	if points > LOVE_MAX:
		return LOVE_MAX
	if points < 0:
		return 0
	return points


func love_text(love: float) -> String:
	return "%d/%d" % [love_points(love), LOVE_MAX]


func clock_text(seconds: float) -> String:
	var whole := maxi(int(ceil(seconds)), 0)
	return "%ds" % whole


func commission_for(pay: int) -> int:
	var cut := int(pay / 4)
	if cut < 1 and pay > 0:
		return 1
	if cut > pay:
		return pay
	return cut


func buy_material(material_id: String) -> String:
	var cost := pack_cost(material_id)
	if cost <= 0:
		return "Pick wood, plastic, or glass."
	if cash < cost:
		return "Need %d cash." % cost
	cash -= cost
	var next := material_qty(material_id) + PACK_QTY
	materials[material_id] = next
	return "Bought %d %s." % [PACK_QTY, material_id]


func start_craft(product_id: String) -> String:
	if product_id != "chair" and product_id != "phone":
		return "Pick a chair or a phone."
	if craft != null:
		return "The bench is busy."
	var missing := _missing_material(product_id)
	if missing != "":
		return "Need %s." % material_name(missing)
	var index: int = 0
	while index < MATERIAL_ORDER.size():
		var material_id: String = MATERIAL_ORDER[index]
		var need := recipe_count(product_id, material_id)
		if need > 0:
			materials[material_id] = material_qty(material_id) - need
		index += 1
	var seconds := craft_seconds()
	var job := CraftJob.new()
	job.product_id = product_id
	job.seconds_left = seconds
	job.seconds_full = seconds
	craft = job
	return "Making a %s." % product_name(product_id)


func buy_research() -> String:
	if skill >= SKILL_MAX:
		return "Skill is %d." % skill
	var cost := research_cost()
	if cash < cost:
		return "Need %d cash." % cost
	cash -= cost
	skill += 1
	return "Skill is %d." % skill


func spawn_call(product_id: String, qty: int) -> String:
	if caller != null:
		return "The line is busy."
	if product_id != "chair" and product_id != "phone":
		return "Pick a chair or a phone."
	var count := qty
	if count < 1:
		count = 1
	if count > 3:
		count = 3
	var name_index := next_caller % CALLER_NAMES.size()
	next_caller += 1
	var next := Caller.new()
	next.display_name = CALLER_NAMES[name_index]
	next.face_id = CALLER_FACES[name_index]
	next.product_id = product_id
	next.qty = count
	next.love = starting_love(count)
	next.pay = unit_pay(product_id) * count
	next.phase = "waiting"
	caller = next
	notice = "%s wants %s." % [next.display_name, product_phrase(product_id, count)]
	return notice


func assign_employee(employee_id: String) -> String:
	var person := find_employee(employee_id)
	if person == null:
		return "That person is out."
	if caller == null:
		return "The phone is quiet."
	if caller.phase == "talking":
		var current := find_employee(caller.employee_id)
		if current != null:
			return "%s is on the phone." % current.display_name
		return "The line is taken."
	if person.busy:
		return "%s is on the phone." % person.display_name
	person.busy = true
	caller.phase = "talking"
	caller.employee_id = person.id
	caller.seconds_full = answer_seconds(caller.product_id, caller.qty)
	caller.seconds_left = caller.seconds_full
	notice = "%s takes the call." % person.display_name
	return notice


func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	var left := delta
	var guard := 0
	while left > 0.00001 and guard < 16:
		guard += 1
		var step := _next_step(left)
		if step <= 0.000001:
			_resolve_timers()
			break
		_apply_step(step)
		_resolve_timers()
		left -= step


func _next_step(left: float) -> float:
	var step := left
	if caller != null and _love_drains() and caller.love > 0.0:
		var love_time := caller.love / LOVE_PER_SECOND
		if love_time < step:
			step = love_time
	if craft != null and craft.seconds_left > 0.0:
		if craft.seconds_left < step:
			step = craft.seconds_left
	if caller != null and caller.phase == "talking" and caller.seconds_left > 0.0:
		if caller.seconds_left < step:
			step = caller.seconds_left
	if ambient and caller == null and spawn_wait > 0.0:
		if spawn_wait < step:
			step = spawn_wait
	return step


func _love_drains() -> bool:
	return not teaching


func _apply_step(step: float) -> void:
	if caller != null and _love_drains():
		caller.love -= LOVE_PER_SECOND * step
	if craft != null:
		craft.seconds_left -= step
	if caller != null and caller.phase == "talking":
		caller.seconds_left -= step
	if ambient and caller == null:
		spawn_wait -= step


func _resolve_timers() -> void:
	if caller != null and caller.love <= 0.0001:
		_hang_up()
	if craft != null and craft.seconds_left <= 0.0001:
		_finish_craft()
	if caller != null and caller.phase == "talking" and caller.seconds_left <= 0.0001:
		_try_close_deal()
	if ambient and caller == null and spawn_wait <= 0.0001:
		spawn_wait = rng.randf_range(7.0, 11.0)
		_ambient_order()


func _hang_up() -> void:
	if caller == null:
		return
	var buyer := caller.display_name
	var person := find_employee(caller.employee_id)
	if person != null:
		person.busy = false
	caller = null
	spawn_wait = 6.5
	notice = "%s hung up." % buyer


func _finish_craft() -> void:
	if craft == null:
		return
	var product_id := craft.product_id
	goods[product_id] = goods_qty(product_id) + 1
	craft = null
	notice = "%s ready." % product_label(product_id)


func _try_close_deal() -> void:
	if caller == null:
		return
	var person := find_employee(caller.employee_id)
	if person != null:
		person.busy = false
	var product_id := caller.product_id
	var qty := caller.qty
	var have := goods_qty(product_id)
	var buyer := caller.display_name
	var pay := caller.pay
	caller.employee_id = ""
	caller.phase = "waiting"
	caller.seconds_left = 0.0
	if have < qty:
		notice = "Need %s." % product_phrase(product_id, qty - have)
		return
	goods[product_id] = have - qty
	var commission := commission_for(pay)
	var company_gain := pay - commission
	if person != null:
		cash += company_gain
		person.commission += commission
		person.calls_closed += 1
		notice = "%s paid %d. Company +%d after commission. %s +%d." % [buyer, pay, company_gain, person.display_name, commission]
	else:
		cash += pay
		notice = "%s paid %d." % [buyer, pay]
	teaching = false
	caller = null
	spawn_wait = 6.5


func _missing_material(product_id: String) -> String:
	var index: int = 0
	while index < MATERIAL_ORDER.size():
		var material_id: String = MATERIAL_ORDER[index]
		var need := recipe_count(product_id, material_id)
		if need > material_qty(material_id):
			return material_id
		index += 1
	return ""


func _ambient_order() -> void:
	calls_made += 1
	if calls_made == 1:
		spawn_call("chair", 1)
		return
	var product_id := "chair"
	if calls_made % 2 == 0:
		product_id = "phone"
	var qty := 1
	if calls_made % 3 == 0:
		qty = 2
	spawn_call(product_id, qty)
