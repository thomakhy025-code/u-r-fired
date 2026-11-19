class_name GameState
extends RefCounted

## Company simulation. The director is the player and has no love.

const TRAINING_FEE := 500
const BAIL_AMOUNT := 600
const SEASON_WEEKS := 8
const SEAT_COUNT := 4
const WAGE_START := 200
const WAGE_RAISED := 320
const CONSUMER_FINE := 350
const WAGE_FINE := 500
const SUBSIDY_GRANT := 1000
const SUBSIDY_PENALTY := 400
const SUBSIDY_LOCK := 4

const STRENGTH_TEXT := {
	"on_time": "meets the deadline",
	"temper_solver": "settles a bad temper",
	"long_hours": "bears a long assignment",
	"catch_junk": "catches junk",
	"sales": "closes sales",
	"books": "closes the books",
	"steady_orders": "steady repeat orders",
	"large_pay": "large payments",
	"small_mention": "a small mention of the company",
	"large_lots": "runs a large lot",
	"deadline_ship": "ships by the deadline",
}

const HABIT_TEXT := {
	"steal": "skims the drawer",
	"snap": "snaps",
	"late": "delivers late",
	"junk": "sends junk goods",
	"late_or_junk": "delivers late or sends junk",
	"bankruptcy": "goes broke and asks to borrow company money",
	"fuss": "fusses over a voucher",
	"cold_week": "has a cold week",
	"public_snap": "snaps in public",
}

var rng := RandomNumberGenerator.new()
var week := 1
var cash := 3500
var debt := 0
var credit := 3
var rate := 0.076
var market_jitter := 0.0
var min_wage := WAGE_START
var tax_rate := 0.08
var penalty_unpaid := 0
var unpaid_weeks := 0
var wage_raised := false
var floor_feelings_applied := false
var subsidy_open := false
var subsidy_used := false
var people := {}
var deals: Array = []
var mail: Array = []
var visible_applicants: Array = []
var hidden_applicants: Array = []
var known_suppliers: Array = []
var hidden_suppliers: Array = []
var cooperate_from := ""
var pending_think := {}
var pending_bailout := {}
var exit_queue: Array = []
var lost := false
var loss_reason := ""
var season_checked := false
var season_held := false
var ever_hired := false
var next_deal := 1
var next_mail := 1
var held_junk := false
var held_late := false
var week_revenue := 0
var week_wages := 0
var week_supplier := 0
var week_training := 0
var week_interest := 0
var credit_buffer := 0
var company_name := "Company"
var stock := 0
var lifetime_profit := 0
var suppress_habits := false
var forced_habits := {}
var rolled_habits := {}
var policy_blurb := "The current rules are posted."

func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value


class Person:
	var id := ""
	var display_name := ""
	var role := ""
	var balance := ""
	var strengths: Array = []
	var habit := ""
	var severity := "minor"
	var love := 3
	var base_workload := 3
	var base_pace := 3
	var ask := 0
	var pay := 0
	var active := true
	var hired := false
	var seat := -1
	var training := false
	var junior := false
	var subsidy_weeks := 0
	var goods := ""
	var recipe := ""
	var returns := true
	var made := 0

	func has_strength(gift: String) -> bool:
		return strengths.has(gift)

	func gift_line() -> String:
		var parts: Array = []
		for gift in strengths:
			parts.append(GameState.STRENGTH_TEXT.get(gift, gift))
		return ", ".join(parts)

	func habit_line() -> String:
		return GameState.HABIT_TEXT.get(habit, habit)


func setup_new_game() -> void:
	people.clear()
	deals.clear()
	mail.clear()
	_add(_person("mina", "Mina", "employee", "great strength, minor flaw", ["catch_junk", "temper_solver"], "snap", "minor", 3, 4, 3, 480, false))
	_add(_person("june", "June", "employee", "great strength, minor flaw", ["books", "on_time"], "fuss", "minor", 3, 3, 4, 460, false))
	_add(_person("otto", "Otto", "employee", "thin strength, serious flaw", ["long_hours"], "steal", "serious", 3, 2, 2, 240, true))
	_add(_person("ben", "Ben", "employee", "mixed", ["temper_solver", "sales"], "bankruptcy", "serious", 3, 3, 3, 520, false))
	_add(_person("rosa", "Rosa", "employee", "great strength, minor flaw", ["catch_junk", "on_time"], "late", "minor", 3, 3, 3, 440, false))
	_add(_person("ken", "Ken", "employee", "mixed", ["long_hours"], "snap", "moderate", 3, 4, 3, 400, false))
	_add(_person("priya", "Priya", "employee", "great strength, minor flaw", ["books", "sales"], "fuss", "minor", 3, 3, 4, 500, false))
	_add(_person("sam", "Sam", "employee", "thin strength, serious flaw", ["sales"], "steal", "serious", 3, 2, 3, 260, true))
	_add(_person("noor", "Noor", "employee", "mixed", ["temper_solver", "catch_junk"], "cold_week", "minor", 3, 3, 3, 470, false))
	_add(_person("auntie", "Auntie Shop", "customer", "great strength, minor flaw", ["steady_orders", "on_time"], "cold_week", "minor", 4, 3, 3, 48, false, "Snack Boxes", "Staff pack supplier parts into snack boxes."))
	_add(_person("lau", "Mr. Lau", "customer", "mixed", ["large_pay"], "snap", "serious", 3, 4, 3, 70, false, "Gift Hampers", "Staff pack more parts into gift hampers."))
	_add(_person("influencer", "The Influencer", "customer", "thin strength, serious flaw", ["small_mention"], "public_snap", "serious", 2, 2, 2, 30, false, "Sample Kits", "Staff pack a few parts into sample kits."))
	_add(_person("cafe", "Corner Cafe", "customer", "great strength, minor flaw", ["steady_orders"], "cold_week", "minor", 3, 3, 3, 40, false, "Lunch Packs", "Staff pack parts into lunch packs."))
	_add(_person("school", "School Desk", "customer", "mixed", ["large_pay", "on_time"], "snap", "minor", 3, 3, 3, 44, false, "Class Kits", "Staff pack parts into class kits."))
	_add(_person("steady", "Steady Supply", "supplier", "great strength, minor flaw", ["deadline_ship", "on_time"], "snap", "minor", 3, 3, 4, 32, false, "card sheets", "Ships card the staff can pack."))
	_add(_person("cheap", "Cheap Parts", "supplier", "thin strength, serious flaw", ["large_lots"], "late_or_junk", "serious", 2, 5, 2, 18, false, "clips", "Ships a big lot of clips."))
	_add(_person("north", "North Mill", "supplier", "great strength, minor flaw", ["on_time"], "snap", "minor", 3, 3, 3, 36, false, "sturdy board", "Ships board that packs cleanly."))
	_add(_person("harbor", "Harbor Paper", "supplier", "great strength, minor flaw", ["deadline_ship"], "snap", "minor", 3, 3, 4, 28, false, "paper rolls", "Ships paper by the deadline."))
	_add(_person("ink", "Bright Ink", "supplier", "thin strength, serious flaw", ["large_lots"], "late", "serious", 2, 4, 2, 16, false, "ink", "Ships a large lot, sometimes late."))
	_add(_person("oak", "Oak Crates", "supplier", "mixed", ["on_time"], "snap", "minor", 3, 3, 3, 30, false, "crates", "Ships crates the boxes travel in."))
	_add(_person("cloth", "Soft Cloth", "supplier", "great strength, minor flaw", ["on_time"], "fuss", "minor", 3, 3, 3, 26, false, "cloth", "Ships cloth for wrapping."))
	_add(_person("glass", "Night Glass", "supplier", "thin strength, serious flaw", ["large_lots"], "junk", "serious", 2, 4, 2, 14, false, "glass sheets", "Ships glass that can arrive as junk."))
	visible_applicants = ["mina"]
	hidden_applicants = ["otto", "june", "ben", "rosa", "ken", "priya", "sam", "noor"]
	known_suppliers = ["steady", "cheap"]
	hidden_suppliers = ["north", "harbor", "ink", "oak", "cloth", "glass"]
	cooperate_from = "steady"
	_recompute_rate(false)
	policy_blurb = "Week 1. The office is open. These are the rules in force."
	_push_mail("Government note", _rules_note("The published rules are now in force for this company."), "government")
	_push_mail("Application", "Mina applied. She is waiting on the recruit sign.\n" + _applicant_card(person("mina")), "application")
	_push_mail("Supplier", "Steady Supply asks to cooperate. Their price is 32 a unit. Answer them on the supplier sign.", "cooperate")
	_push_mail("Bank", "The rate on the sign is %s." % rate_text(), "rate")


func person(id: String) -> Person:
	return people[id]


func _person(id: String, display_name: String, role: String, balance: String, strengths: Array, habit: String, severity: String, love: int, workload: int, pace: int, ask: int, junior: bool, goods: String = "", recipe: String = "") -> Person:
	var p := Person.new()
	p.id = id
	p.display_name = display_name
	p.role = role
	p.balance = balance
	p.strengths = strengths.duplicate()
	p.habit = habit
	p.severity = severity
	p.love = love
	p.base_workload = workload
	p.base_pace = pace
	p.ask = ask
	p.junior = junior
	p.goods = goods
	p.recipe = recipe
	return p


func _add(p: Person) -> void:
	people[p.id] = p


func hired_people() -> Array:
	var found: Array = []
	for id in ["mina", "june", "otto", "ben"]:
		var p: Person = people[id]
		if p.hired and p.active:
			found.append(p)
	return found


func active_people() -> Array:
	var found: Array = []
	for id in people.keys():
		var p: Person = people[id]
		if p.active:
			found.append(p)
	return found


func hearts(n: int) -> String:
	return "%d/5" % clampi(n, 0, 5)


func rate_text() -> String:
	return str(snapped(rate * 100.0, 0.1)) + "%"


func unread_count() -> int:
	var count := 0
	for item in mail:
		if not item["read"]:
			count += 1
	return count


func newspaper_text() -> String:
	var subsidy := "No hiring subsidy is open."
	if subsidy_open and not subsidy_used:
		subsidy = "A hiring subsidy is open: %d if you hire, and that person stays %d weeks. Firing them early returns the grant plus a %d penalty." % [SUBSIDY_GRANT, SUBSIDY_LOCK, SUBSIDY_PENALTY]
	elif subsidy_used:
		subsidy = "The hiring subsidy has been taken. The locked employee must finish the printed weeks."
	var unpaid := "No penalties are waiting."
	if penalty_unpaid > 0:
		unpaid = "Unpaid penalties: %d. Doors shut after penalties stay unpaid for two weeks." % penalty_unpaid
	return """%s

Wage floor: %d
Tax: %d%% of a week's profit
%s

Penalty table
- Pay under the wage floor: %d
- Consumer complaint: %d
- Unpaid tax: the unpaid amount, added to penalties
- Closure: a note shuts the company after penalties stay unpaid for two weeks

%s

The government posts the rule. It does not keep a heart score.""" % [policy_blurb, min_wage, int(tax_rate * 100), subsidy, WAGE_FINE, CONSUMER_FINE, unpaid]


func heart_scale(love: int) -> float:
	match clampi(love, 0, 5):
		0:
			return 0.0
		1:
			return 0.30
		2:
			return 0.45
		3:
			return 0.65
		4:
			return 0.85
		_:
			return 1.0


func finished_units(p: Person, demand: int) -> int:
	var cap := p.base_workload * 10
	var amount := int(round(float(cap) * heart_scale(p.love)))
	if p.has_strength("long_hours") and demand > cap:
		amount += int(round(float(p.base_workload) * 4.0 * heart_scale(p.love)))
	return clampi(amount, 0, maxi(demand, 0))


func pace_rank(p: Person) -> int:
	return p.love + p.base_pace


func pace_day(p: Person) -> String:
	var speed := pace_rank(p)
	if speed >= 9:
		return "Monday"
	if speed >= 7:
		return "Wednesday"
	if speed >= 5:
		return "Friday"
	return "late in the week"


func habit_chance(severity: String) -> float:
	match severity:
		"faint":
			return 0.08
		"minor":
			return 0.18
		"moderate":
			return 0.35
		"serious":
			return 0.55
		_:
			return 0.2


func roll_training_dice() -> Array:
	return [rng.randf() < 0.5, rng.randf() < 0.5, rng.randf() < 0.5]


func severity_softer(severity: String) -> String:
	match severity:
		"serious":
			return "moderate"
		"moderate":
			return "minor"
		"minor":
			return "faint"
		_:
			return "faint"


func apply_training(p: Person, rolls: Array) -> String:
	var temper := "unchanged"
	var load := "unchanged"
	var speed := "unchanged"
	if bool(rolls[0]):
		var next := severity_softer(p.severity)
		if next != p.severity:
			p.severity = next
			temper = "a bit milder"
		else:
			temper = "already faint"
	if bool(rolls[1]):
		if p.base_workload < 6:
			p.base_workload += 1
			load = "one step larger"
		else:
			load = "already at the top step"
	if bool(rolls[2]):
		if p.base_pace < 6:
			p.base_pace += 1
			speed = "one step faster"
		else:
			speed = "already at the top step"
	return "%s's course. Temper: %s. Workload: %s. Speed: %s." % [p.display_name, temper, load, speed]


func open_deals() -> Array:
	var found: Array = []
	for deal in deals:
		if str(deal["stage"]) != "closed":
			found.append(deal)
	return found


func recruit_offer(id: String, offer: int) -> String:
	if lost:
		return loss_reason
	var p: Person = person(id)
	if p.hired:
		return "%s already sits in the office." % p.display_name
	if not visible_applicants.has(id):
		return "They are not on the recruit sign."
	if _free_seat() < 0:
		return "Every chair is full."
	if offer < min_wage:
		_push_mail("Government note", _rules_note("The offer to %s was %d, under the wage floor of %d. They can report it. No hire was made." % [p.display_name, offer, min_wage]), "government")
		return "That offer is under the wage floor."
	return _negotiate(p, offer, "hire")


func supplier_offer(id: String, offer: int) -> String:
	if lost:
		return loss_reason
	if not known_suppliers.has(id):
		return "That supplier is not on the list."
	var p: Person = person(id)
	if not p.active:
		return "%s has ended the contract." % p.display_name
	return _negotiate(p, offer, "supply")


func insist(id: String) -> String:
	if not pending_think.has(id):
		return "Nobody is waiting on a reply."
	var pending: Dictionary = pending_think[id]
	pending_think.erase(id)
	var p: Person = person(id)
	return _close_offer(p, int(pending["offer"]), str(pending["kind"]), 2)


func look_for_applicant() -> String:
	if hidden_applicants.is_empty():
		return "Nobody else is looking this week."
	var id: String = hidden_applicants.pop_front()
	visible_applicants.append(id)
	var p: Person = person(id)
	_push_mail("Application", "%s is now on the recruit sign.\n%s" % [p.display_name, _applicant_card(p)], "application")
	return "%s can be hired from the recruit sign." % p.display_name


func find_supplier() -> String:
	if hidden_suppliers.is_empty():
		return "You already know the suppliers you can find."
	var id: String = hidden_suppliers.pop_front()
	known_suppliers.append(id)
	var p: Person = person(id)
	_push_mail("Supplier", "You found %s. They sell %s. Their ask is %d a unit. %s" % [p.display_name, p.goods, p.ask, _profile(p)], "cooperate")
	return "%s is now on the supplier sign." % p.display_name


func accept_cooperation() -> String:
	if cooperate_from == "":
		return "No supplier is waiting on an answer."
	var id := cooperate_from
	var p: Person = person(id)
	return supplier_offer(id, p.ask)


func set_wage(id: String, amount: int) -> String:
	if lost:
		return loss_reason
	var p: Person = person(id)
	if not p.hired:
		return "They do not work here."
	if amount < min_wage:
		return "The wage floor is %d. The newspaper prints a fine for paying under it." % min_wage
	var before := p.pay
	p.pay = amount
	if amount > before and amount >= p.ask:
		shift_love(p, 1, "the pay met their ask")
	elif amount < before:
		shift_love(p, -1, "the pay was cut")
	_jealousy(p)
	resolve_exits()
	return "%s is paid %d. %s" % [p.display_name, p.pay, hearts(p.love)]


func comply_wage_floor() -> String:
	if lost:
		return loss_reason
	var raised: Array = []
	for p in hired_people():
		if p.pay < min_wage:
			p.pay = min_wage
			raised.append(p.display_name)
			if p.junior:
				shift_love(p, 1, "the wage floor reached them")
	if not floor_feelings_applied:
		floor_feelings_applied = true
		for p in hired_people():
			if not p.junior and p.pay < min_wage + 120:
				shift_love(p, -1, "the gap over the new floor got smaller")
	resolve_exits()
	if raised.is_empty():
		return "Everyone is already at the wage floor."
	return "Raised to the floor: " + ", ".join(raised)


func train(id: String) -> String:
	if lost:
		return loss_reason
	var p: Person = person(id)
	if not p.hired or not p.active:
		return "They are not on a chair."
	if p.training:
		return "%s is already on a course this period." % p.display_name
	if cash < TRAINING_FEE:
		return "The course costs %d, on top of salary." % TRAINING_FEE
	cash -= TRAINING_FEE
	week_training += TRAINING_FEE
	p.training = true
	_pull_from_deals(p, true)
	resolve_exits()
	return "%s stays in their seat and does no work this period. The fee is paid." % p.display_name


func assign(employee_id: String, deal_id: String, on: bool) -> String:
	if lost:
		return loss_reason
	var p: Person = person(employee_id)
	if not p.hired or not p.active:
		return "They are not in a chair."
	if p.training:
		return "%s is training and cannot follow a deal this period." % p.display_name
	var deal := _deal_by_id(deal_id)
	if deal.is_empty() or str(deal["stage"]) == "closed":
		return "That deal is not open."
	var crew: Array = deal["crew"]
	if not on:
		crew.erase(employee_id)
		if crew.is_empty():
			_partner_abandoned(deal)
			resolve_exits()
		return "%s stepped off the deal." % p.display_name
	if crew.has(employee_id):
		return "%s is already on it." % p.display_name
	if crew.size() >= 3:
		return "A few employees can follow one deal. Three are already on it."
	for other in deals:
		if str(other["stage"]) == "closed":
			continue
		var other_crew: Array = other["crew"]
		if other_crew.has(employee_id):
			other_crew.erase(employee_id)
			if other_crew.is_empty():
				_partner_abandoned(other)
	crew.append(employee_id)
	resolve_exits()
	return "%s will follow this deal." % p.display_name


func release_to_market(id: String) -> String:
	var p: Person = person(id)
	if not p.hired:
		return ""
	var name := p.display_name
	p.hired = false
	p.training = false
	p.seat = -1
	_pull_from_deals(p, false)
	visible_applicants.erase(id)
	return name


func fire(id: String) -> String:
	if lost:
		return loss_reason
	var p: Person = person(id)
	if not p.hired:
		return "They are not employed."
	var name := p.display_name
	var locked := p.subsidy_weeks
	p.active = false
	p.hired = false
	p.training = false
	p.seat = -1
	_pull_from_deals(p, true)
	if locked > 0:
		var bill := SUBSIDY_GRANT + SUBSIDY_PENALTY
		cash -= bill
		_push_mail("Government note", _rules_note("%s was fired during the subsidy lock. The grant is returned and the penalty is %d. Paid %d." % [name, SUBSIDY_PENALTY, bill]), "government")
	for other in hired_people():
		shift_love(other, -1, "a colleague was fired")
	resolve_exits()
	_push_mail("Office", "%s left the chair." % name, "note")
	return "%s is no longer employed." % name


func borrow(amount: int) -> String:
	if lost:
		return loss_reason
	if amount < 100:
		return "The bank's smallest loan is 100."
	cash += amount
	debt += amount
	_recompute_rate(true)
	return "The bank lent %d. The rate on the sign is %s." % [amount, rate_text()]


func pay_penalties() -> String:
	if penalty_unpaid <= 0:
		return "Nothing is owed to the government."
	if cash < penalty_unpaid:
		return "The unpaid penalties are %d and the cash is %d." % [penalty_unpaid, cash]
	cash -= penalty_unpaid
	penalty_unpaid = 0
	unpaid_weeks = 0
	_push_mail("Government note", _rules_note("The printed penalties were paid. The file is clear."), "government")
	return "The penalties are paid."


func answer_bailout(lend: bool) -> String:
	if pending_bailout.is_empty():
		return "Nobody is asking to borrow."
	var id := str(pending_bailout["id"])
	var amount := int(pending_bailout["amount"])
	pending_bailout = {}
	var p: Person = person(id)
	if not p.hired or not p.active:
		return "%s is no longer here." % p.display_name
	if lend:
		if cash < amount:
			pending_bailout = {"id": id, "amount": amount}
			return "The company does not have %d free." % amount
		cash -= amount
		shift_love(p, 1, "the company covered the debt")
		if credit > 0:
			credit -= 1
			_recompute_rate(true)
		resolve_exits()
		return "Lent %d to %s. It stays out of the drawer. %s" % [amount, p.display_name, hearts(p.love)]
	shift_love(p, -1, "the company refused the debt")
	resolve_exits()
	return "Refused %s. %s" % [p.display_name, hearts(p.love)]


func break_contract(id: String) -> String:
	var p: Person = person(id)
	if p.role != "supplier":
		return "That is not a supplier."
	p.love = 0
	p.active = false
	cash -= 200
	for deal in deals:
		if str(deal["partner_id"]) != id or str(deal["stage"]) == "closed":
			continue
		deal["stage"] = "closed"
		for member_id in deal["crew"]:
			var member: Person = person(str(member_id))
			if member.hired and member.active:
				shift_love(member, -1, "the contract broke mid-deal")
	if cooperate_from == id:
		cooperate_from = ""
	resolve_exits()
	_push_mail("Supplier", "The contract with %s is broken. The fee is 200." % p.display_name, "note")
	return "The contract with %s is broken." % p.display_name


func end_week() -> String:
	if lost:
		return loss_reason
	week_revenue = 0
	week_wages = 0
	week_supplier = 0
	week_interest = 0
	rolled_habits = {}
	for p in hired_people():
		rolled_habits[p.id] = _build_habit(p)
	for outsider in _outsiders():
		if outsider.active:
			rolled_habits[outsider.id] = _build_habit(outsider)
	_apply_habit_side_effects()
	var training_lines: Array = []
	for p in hired_people():
		if not p.training:
			continue
		var line := apply_training(p, roll_training_dice())
		var incident: Dictionary = rolled_habits.get(p.id, {})
		if not incident.is_empty():
			line += "\n" + str(incident["text"])
		training_lines.append(line)
	if training_lines.size() > 0:
		_push_mail("Training", "\n".join(training_lines), "training")
	for deal in _deals_of_kind("supplier"):
		_resolve_stage(deal)
	for deal in _deals_of_kind("customer"):
		_resolve_stage(deal)
	for p in hired_people():
		p.training = false
	_june_reveal()
	_pay_wages()
	_pay_tax()
	_pay_interest()
	_tick_subsidies()
	_law_check()
	resolve_exits()
	_credit_tick()
	_ledger()
	_check_endings()
	if lost:
		return loss_reason
	week += 1
	_begin_week()
	return "Week %d." % week


func shift_love(p: Person, delta: int, reason: String) -> String:
	if delta == 0 or not p.active:
		return "%s %d." % [p.display_name, p.love]
	var before := p.love
	p.love = clampi(p.love + delta, 0, 5)
	var applied := p.love - before
	if applied == 0:
		return "%s %d." % [p.display_name, p.love]
	if p.love == 0 and p.active:
		if not exit_queue.has(p.id):
			exit_queue.append(p.id)
	var sign := "+" if applied > 0 else ""
	var line := "%s %d (%s%d, %s)." % [p.display_name, p.love, sign, applied, reason]
	if p.love == 0:
		line += " Their term ended."
	return line


func resolve_exits() -> void:
	var guard := 0
	while exit_queue.size() > 0 and guard < 16:
		guard += 1
		var id: String = exit_queue.pop_front()
		var p: Person = person(id)
		if not p.active:
			continue
		if p.love > 0:
			continue
		p.active = false
		p.training = false
		if p.hired:
			p.hired = false
			p.seat = -1
			_pull_from_deals(p, true)
			_push_mail("Office", "%s left the chair. Their love is 0." % p.display_name, "note")
		else:
			for deal in deals:
				if str(deal["partner_id"]) == id and str(deal["stage"]) != "closed":
					deal["stage"] = "closed"
					deal["crew"] = []
			_push_mail("Account", "%s ended the account." % p.display_name, "note")
		if p.role == "customer" and _customers_all_gone():
			_lose("Every customer ended the account.")


func _negotiate(p: Person, offer: int, kind: String) -> String:
	if offer <= 0:
		return "The offer has to be a number above zero."
	var ratio := float(offer) / float(maxi(p.ask, 1))
	if ratio + 0.001 >= 1.0:
		var love := 5 if ratio >= 1.2 else 4
		return _close_offer(p, offer, kind, love)
	if ratio >= 0.85:
		pending_think[p.id] = {"offer": offer, "kind": kind}
		return "%s will think about %d. Insist, or raise the offer." % [p.display_name, offer]
	if ratio >= 0.7:
		return _close_offer(p, offer, kind, 1)
	return "%s rejected %d." % [p.display_name, offer]


func _close_offer(p: Person, offer: int, kind: String, love: int) -> String:
	if kind == "hire":
		if _free_seat() < 0:
			return "Every chair is full."
		p.love = love
		p.pay = offer
		p.hired = true
		p.active = true
		p.seat = _free_seat()
		visible_applicants.erase(p.id)
		ever_hired = true
		if hired_people().size() == 1:
			_open_order(person("auntie"))
		var extra := ""
		if subsidy_open and not subsidy_used:
			subsidy_used = true
			p.subsidy_weeks = SUBSIDY_LOCK
			cash += SUBSIDY_GRANT
			extra = " The subsidy note granted %d. %s must stay %d weeks." % [SUBSIDY_GRANT, p.display_name, SUBSIDY_LOCK]
			_push_mail("Government note", _rules_note("The company qualified for the hiring subsidy. %s must stay %d weeks. The grant is %d. Firing them early returns it plus %d." % [p.display_name, SUBSIDY_LOCK, SUBSIDY_GRANT, SUBSIDY_PENALTY]), "government")
		return "%s accepted %d and sat down. Love %d. %s.%s" % [p.display_name, offer, p.love, p.balance, extra]
	p.love = love
	if cooperate_from == p.id:
		cooperate_from = ""
	var units := p.base_workload * 8
	_make_deal("supplier", p.id, units, offer, units >= 40)
	return "%s accepted %d a unit with love %d. Assign someone to follow the deal." % [p.display_name, offer, p.love]


func accept_order(deal_id: String) -> String:
	var deal := _deal_by_id(deal_id)
	if deal.is_empty() or str(deal["stage"]) != "offer":
		return "That order is not waiting for an answer."
	if hired_people().is_empty():
		return "Hire someone before you accept an order."
	deal["stage"] = "proposal"
	deal["reserved"] = false
	var buyer: Person = person(str(deal["partner_id"]))
	return "Accepted %s. Assign someone, and find a supplier if the parts are not here. If this goes well, they may return at a higher price." % buyer.goods


func reject_order(deal_id: String) -> String:
	var deal := _deal_by_id(deal_id)
	if deal.is_empty() or str(deal["stage"]) != "offer":
		return "That order is not waiting for an answer."
	deal["stage"] = "closed"
	var buyer: Person = person(str(deal["partner_id"]))
	buyer.returns = false
	shift_love(buyer, -1, "the order was refused")
	_push_mail("Order", "%s was turned away. They may not come back." % buyer.display_name, "order")
	return "%s may not come back." % buyer.display_name


func answer_quality(deal_id: String, refund: bool) -> String:
	var deal := _deal_by_id(deal_id)
	if deal.is_empty() or str(deal["stage"]) != "quality":
		return "Nobody is waiting on a quality answer."
	var buyer: Person = person(str(deal["partner_id"]))
	var pay := int(deal.get("pay", 0))
	deal["stage"] = "closed"
	if refund:
		shift_love(buyer, -1, "the goods were refunded")
		_push_mail("Quality", "%s got their money back. You were not paid." % buyer.display_name, "order")
		return "Refunded %s. No payment came in." % buyer.display_name
	var discounted := int(round(float(pay) * 0.6))
	cash += discounted
	week_revenue += discounted
	lifetime_profit += discounted
	buyer.ask += 4
	_push_mail("Quality", "%s took a discount and paid %d." % [buyer.display_name, discounted], "order")
	return "%s paid %d after the discount." % [buyer.display_name, discounted]


func _deal_by_id(deal_id: String) -> Dictionary:
	for deal in deals:
		if str(deal["id"]) == deal_id:
			return deal
	return {}


func _make_deal(kind: String, partner_id: String, units: int, unit_price: int, heavy: bool, stage: String = "proposal") -> void:
	deals.append({
		"id": "d%d" % next_deal,
		"kind": kind,
		"partner_id": partner_id,
		"crew": [],
		"stage": stage,
		"units": units,
		"unit_price": unit_price,
		"heavy": heavy,
		"pay": 0,
	})
	next_deal += 1


func _open_order(customer: Person) -> void:
	if not ever_hired:
		return
	if not customer.returns:
		return
	if not customer.active or customer.love <= 0:
		return
	if _open_deal_for(customer.id):
		return
	var units := 16 + customer.love * 6
	if customer.has_strength("large_pay"):
		units += 18
	if customer.has_strength("small_mention"):
		units = 8 + customer.love * 2
	if customer.has_strength("steady_orders"):
		units = 22 + customer.love * 4
	_make_deal("customer", customer.id, units, customer.ask, units >= 40, "offer")
	_push_mail("Order", "%s wants %d %s at %d each. %s Accept it, or reject it. If you accept, find a supplier while the order is open. You pay the supplier when the parts arrive, and you are paid when the customer takes the goods." % [customer.display_name, units, customer.goods, customer.ask, customer.recipe], "order")


func _free_seat() -> int:
	var used := {}
	for p in hired_people():
		used[p.seat] = true
	for seat in SEAT_COUNT:
		if not used.has(seat):
			return seat
	return -1


func _applicant_card(p: Person) -> String:
	return "%s. %s. Strength: %s. Bad habit: %s (%s). Ask: %d." % [p.display_name, p.balance, p.gift_line(), p.habit_line(), p.severity, p.ask]


func _profile(p: Person) -> String:
	return "%s. Strength: %s. Bad habit: %s (%s)." % [p.balance, p.gift_line(), p.habit_line(), p.severity]


func _jealousy(raised: Person) -> void:
	var top := 0
	for other in hired_people():
		if other.pay > top:
			top = other.pay
	if raised.pay < top or raised.pay < int(float(raised.ask) * 1.15):
		return
	for other in hired_people():
		if other.id == raised.id:
			continue
		if other.pay * 10 < raised.pay * 7:
			shift_love(other, -1, "the pay gap was unfair")


func _pull_from_deals(p: Person, drop_partner: bool) -> void:
	for deal in deals:
		if str(deal["stage"]) == "closed":
			continue
		var crew: Array = deal["crew"]
		if not crew.has(p.id):
			continue
		crew.erase(p.id)
		if drop_partner and crew.is_empty():
			_partner_abandoned(deal)


func _partner_abandoned(deal: Dictionary) -> void:
	if str(deal["stage"]) == "closed":
		return
	var partner: Person = person(str(deal["partner_id"]))
	if partner.active:
		shift_love(partner, -1, "nobody followed the work")


func _open_deal_for(partner_id: String) -> bool:
	for deal in deals:
		if str(deal["partner_id"]) == partner_id and str(deal["stage"]) != "closed":
			return true
	return false


func _deals_of_kind(kind: String) -> Array:
	var found: Array = []
	for deal in deals:
		if str(deal["kind"]) == kind and str(deal["stage"]) != "closed":
			found.append(deal)
	return found


func _build_habit(p: Person) -> Dictionary:
	var fire := false
	if forced_habits.has(p.id):
		fire = true
	elif suppress_habits:
		fire = false
	else:
		fire = rng.randf() < habit_chance(p.severity)
	if not fire or p.habit == "":
		return {}
	var kind := p.habit
	var late := false
	var junk := false
	if kind == "late_or_junk":
		if rng.randf() < 0.5:
			kind = "junk"
			junk = true
		else:
			kind = "late"
			late = true
	var secret := kind == "steal"
	var cash_hit := 0
	if kind == "steal":
		match p.severity:
			"faint":
				cash_hit = 15
			"minor":
				cash_hit = 60
			"moderate":
				cash_hit = 180
			_:
				cash_hit = 350
	var label := p.severity.capitalize()
	var verb: String = str(HABIT_TEXT.get(kind, str(HABIT_TEXT.get(p.habit, kind))))
	var text := "%s %s. %s habit." % [p.display_name, verb, label]
	return {
		"actor_id": p.id,
		"kind": kind,
		"text": text,
		"secret": secret,
		"cash": cash_hit,
		"junk": junk or kind == "junk",
		"late": late or kind == "late",
		"public": kind == "public_snap",
		"refund": kind == "snap" and p.role == "customer",
		"bailout": BAIL_AMOUNT if kind == "bankruptcy" else 0,
	}


func _apply_habit_side_effects() -> void:
	var short := 0
	var revealed: Array = []
	for id in rolled_habits.keys():
		var incident: Dictionary = rolled_habits[id]
		if incident.is_empty():
			continue
		if int(incident["cash"]) > 0:
			var hit := int(incident["cash"])
			cash -= hit
			short += hit
		if int(incident["bailout"]) > 0 and pending_bailout.is_empty():
			pending_bailout = {"id": str(incident["actor_id"]), "amount": int(incident["bailout"])}
			_push_mail("Bailout", str(incident["text"]) + " Lend the company money, or refuse.", "bailout")
		if bool(incident["public"]):
			var settled := _solver_on_partner(str(id))
			if not settled:
				_issue_penalty(CONSUMER_FINE, "%s snapped in public. The consumer rule prints a penalty of %d." % [person(str(id)).display_name, CONSUMER_FINE])
	if short > 0:
		var named := _june_can_name()
		if named:
			for id in rolled_habits.keys():
				var incident: Dictionary = rolled_habits[id]
				if incident.is_empty() or not bool(incident["secret"]):
					continue
				revealed.append(str(incident["text"]))
		if revealed.is_empty():
			_push_mail("Drawer", "The drawer is short by %d." % short, "note")
		else:
			_push_mail("June's books", "June closed the books.\n" + "\n".join(revealed), "report")


func _solver_on_partner(partner_id: String) -> bool:
	for deal in deals:
		if str(deal["partner_id"]) != partner_id or str(deal["stage"]) == "closed":
			continue
		for member_id in deal["crew"]:
			var member: Person = person(str(member_id))
			if member.hired and member.active and not member.training and member.has_strength("temper_solver"):
				return true
	return false


func _june_can_name() -> bool:
	var june: Person = person("june")
	if not june.hired or not june.active or june.training:
		return false
	return heart_scale(june.love) >= 0.7


func _june_reveal() -> void:
	if not _june_can_name():
		return
	var lines: Array = []
	for id in rolled_habits.keys():
		var incident: Dictionary = rolled_habits[id]
		if incident.is_empty() or not bool(incident["secret"]):
			continue
		lines.append(str(incident["text"]))
	if lines.is_empty():
		return
	if _mail_has_title("June's books"):
		return
	_push_mail("June's books", "June closed the books.\n" + "\n".join(lines), "report")


func _mail_has_title(title: String) -> bool:
	for item in mail:
		if str(item["title"]) == title and int(item["week"]) == week:
			return true
	return false


func _resolve_stage(deal: Dictionary) -> void:
	var stage_now := str(deal["stage"])
	if stage_now == "closed" or stage_now == "offer" or stage_now == "quality":
		return
	var crew := _live_crew(deal)
	if crew.is_empty():
		return
	var partner: Person = person(str(deal["partner_id"]))
	if not partner.active:
		deal["stage"] = "closed"
		return
	if str(deal["kind"]) == "customer" and not bool(deal.get("reserved", false)):
		var need := int(deal["units"])
		if stock < need:
			var waiting := "Parts for %s" % partner.display_name
			if not _mail_has_title(waiting):
				_push_mail(waiting, "%s is accepted. The office has %d parts and this order needs %d. Packing waits until a supplier sends them. You pay the supplier when the parts arrive." % [partner.display_name, stock, need], "order")
			return
		stock -= need
		deal["reserved"] = true
	var stage := str(deal["stage"])
	var demand := int(deal["units"])
	var total := 0
	var speed := 0
	var on_time := false
	var solver := false
	var inspector_scale := 0.0
	var lines: Array = []
	for member in crew:
		var fin := finished_units(member, demand)
		total += fin
		speed += pace_rank(member)
		if member.has_strength("on_time") or member.has_strength("deadline_ship"):
			on_time = true
		if member.has_strength("temper_solver"):
			solver = true
		if member.has_strength("catch_junk"):
			inspector_scale = maxf(inspector_scale, heart_scale(member.love))
		member.made += fin
		lines.append("%s reached %d by %s." % [member.display_name, fin, pace_day(member)])
	total = mini(total, demand)
	var share := float(total) / float(maxi(demand, 1))
	var avg_speed := float(speed) / float(crew.size())
	var incident: Dictionary = rolled_habits.get(partner.id, {})
	var settled := false
	if not incident.is_empty() and solver and str(incident["kind"]) in ["snap", "public_snap"]:
		settled = true
		lines.append("%s settled %s's temper." % [_solver_name(crew), partner.display_name])
	if not incident.is_empty() and bool(incident["junk"]):
		if inspector_scale >= 0.5:
			lines.append("%s caught the junk in the units they reached." % _inspector_name(crew))
		else:
			held_junk = true
			lines.append("Junk got through.")
	if not incident.is_empty() and bool(incident["late"]):
		held_late = true
		on_time = false
		lines.append("The delivery missed the date.")
	if str(deal["kind"]) == "customer" and stage == "almost":
		if held_junk:
			total = int(float(total) * 0.6)
			held_junk = false
			lines.append("Junk from the supply cut the goods.")
		if held_late:
			on_time = false
			held_late = false
			lines.append("The date slipped.")
	var partner_delta := 0
	var partner_reason := "the stage held"
	if share >= 0.75 and avg_speed >= 7.0:
		partner_delta = 1
		partner_reason = "the stage was fast and full"
	elif share <= 0.45 or avg_speed <= 4.0:
		partner_delta = -1
		partner_reason = "the stage was small and slow"
	if not incident.is_empty() and not settled and str(incident["kind"]) in ["snap", "public_snap", "junk", "late"]:
		partner_delta -= 1
		partner_reason = "their habit hit the deal"
	if str(deal["kind"]) == "supplier" and partner.has_strength("deadline_ship") and not bool(incident.get("late", false)):
		on_time = true
	var love_lines: Array = []
	love_lines.append(shift_love(partner, partner_delta, partner_reason))
	for member in crew:
		var delta := 0
		var reason := "the other side stayed fair"
		if settled and member.has_strength("temper_solver"):
			delta = 0
			reason = "they settled the temper"
		elif not incident.is_empty() and not settled and str(incident["kind"]) in ["snap", "public_snap", "junk", "late"]:
			delta = -1
			reason = "they took the snap"
		elif partner_delta >= 0 and partner.love >= 3 and share >= 0.45:
			delta = 1
			reason = "a fair week from %s" % partner.display_name
		if share < 0.45 and delta > 0:
			delta = 0
			reason = "the work was too thin to earn it"
		love_lines.append(shift_love(member, delta, reason))
	for member in crew:
		var own: Dictionary = rolled_habits.get(member.id, {})
		if own.is_empty():
			continue
		if str(own["kind"]) == "snap":
			love_lines.append(shift_love(partner, -1, "an employee snapped"))
		elif str(own["kind"]) == "steal" and str(deal["kind"]) == "customer":
			love_lines.append(shift_love(partner, -1, "a payment went missing"))
	var stage_name := _stage_name(stage)
	if stage == "almost":
		var bill_line := _settle_money(deal, partner, total, on_time, incident, settled)
		if bill_line != "":
			love_lines.append(bill_line)
		if str(deal.get("hold", "")) == "quality":
			deal["stage"] = "quality"
		else:
			deal["stage"] = "closed"
	elif stage == "proposal":
		deal["stage"] = "doing"
	else:
		deal["stage"] = "almost"
	var writer: Person = crew[0]
	for member in crew:
		if member.id == "june":
			writer = member
	var habit_lines: Array = []
	_append_visible_habit(habit_lines, incident, writer)
	for member in crew:
		_append_visible_habit(habit_lines, rolled_habits.get(member.id, {}), writer)
	var heart_bits: Array = []
	heart_bits.append("%s %d" % [partner.display_name, partner.love])
	for member in crew:
		heart_bits.append("%s %d" % [member.display_name, member.love])
	var did := _stage_work_line(stage_name, crew, total, demand, on_time)
	var body := "%s. %s. %s" % [stage_name, ". ".join(heart_bits), did]
	if lines.size() > 0:
		body += "\n" + "\n".join(lines)
	if habit_lines.size() > 0:
		body += "\n" + "\n".join(habit_lines)
	body += "\n" + " ".join(love_lines)
	_push_mail(stage_name, body, "report")


func _live_crew(deal: Dictionary) -> Array:
	var crew: Array = []
	for member_id in deal["crew"]:
		var member: Person = person(str(member_id))
		if member.hired and member.active and not member.training:
			crew.append(member)
	return crew


func _solver_name(crew: Array) -> String:
	for member in crew:
		if member.has_strength("temper_solver"):
			return member.display_name
	return "The crew"


func _inspector_name(crew: Array) -> String:
	for member in crew:
		if member.has_strength("catch_junk"):
			return member.display_name
	return "The crew"


func _append_visible_habit(lines: Array, incident: Dictionary, writer: Person) -> void:
	if incident.is_empty():
		return
	var actor := str(incident["actor_id"])
	var june_writing := writer.id == "june"
	if bool(incident["secret"]) and actor == writer.id and not june_writing:
		return
	var text := str(incident["text"])
	if not lines.has(text):
		lines.append(text)


func _stage_name(stage: String) -> String:
	match stage:
		"proposal":
			return "Proposal"
		"doing":
			return "Doing"
		_:
			return "Almost finish"


func _stage_work_line(stage_name: String, crew: Array, total: int, demand: int, on_time: bool) -> String:
	var lead: Person = crew[0]
	var when := pace_day(lead)
	for member in crew:
		if pace_rank(member) > pace_rank(lead):
			lead = member
			when = pace_day(member)
	if stage_name == "Proposal":
		var cover := "most of the order" if float(total) / float(maxi(demand, 1)) >= 0.75 else "a thin slice of the order"
		return "%s answered by %s. The opening covers %s." % [lead.display_name, when, cover]
	var date := " The finished goods hit the date." if on_time else " The date is open."
	return "%s checked %d of %d by %s.%s" % [lead.display_name, total, demand, when, date]


func _settle_money(deal: Dictionary, partner: Person, total: int, on_time: bool, incident: Dictionary, settled: bool) -> String:
	if str(deal["kind"]) == "customer":
		var units := total
		var complain := held_junk
		if not incident.is_empty() and (bool(incident["refund"]) or bool(incident["junk"])) and not settled:
			complain = true
			units = int(float(units) * 0.5)
		if not on_time:
			units = int(float(units) * 0.85)
		var revenue := int(round(float(units * int(deal["unit_price"])) * (0.75 + 0.08 * float(partner.love))))
		if complain:
			deal["hold"] = "quality"
			deal["pay"] = revenue
			return "%s dislikes the quality. Choose a refund or a discount before any cash comes in." % partner.display_name
		cash += revenue
		week_revenue += revenue
		lifetime_profit += revenue
		partner.ask += 6
		return "%s accepted the goods and paid %d. They may return at a higher price." % [partner.display_name, revenue]
	var arrived := maxi(total, 0)
	stock += arrived
	var cost := int(deal["units"]) * int(deal["unit_price"])
	if cash >= cost:
		cash -= cost
		week_supplier += cost
		return ""
	week_supplier += maxi(cash, 0)
	cash = 0
	if credit > 0:
		credit -= 1
		_recompute_rate(true)
	return shift_love(partner, -1, "the bill was short")


func _pay_wages() -> void:
	var due := 0
	for p in hired_people():
		due += p.pay
	week_wages = due
	if due <= 0:
		return
	if cash >= due:
		cash -= due
		return
	cash -= due
	for p in hired_people():
		shift_love(p, -1, "payroll was late")
	if credit > 0:
		credit -= 1
		_recompute_rate(true)
	_push_mail("Payroll", "Payroll was short. Love fell in the room.", "note")


func _pay_tax() -> void:
	var profit := week_revenue - week_wages - week_supplier - week_training - week_interest
	if profit <= 0:
		return
	var tax := int(round(float(profit) * tax_rate))
	if tax <= 0:
		return
	if cash >= tax:
		cash -= tax
	else:
		_issue_penalty(tax, "Tax of %d on the week's profit was not paid." % tax)


func _pay_interest() -> void:
	if debt <= 0:
		return
	var due := int(round(float(debt) * rate / 8.0))
	week_interest = due
	if due <= 0:
		return
	if cash >= due:
		cash -= due
	else:
		debt += due
		if credit > 0:
			credit -= 1
			_recompute_rate(true)
		_push_mail("Bank", "Interest of %d was added to the loan. The rate on the sign is %s." % [due, rate_text()], "rate")


func _tick_subsidies() -> void:
	for p in hired_people():
		if p.subsidy_weeks > 0:
			p.subsidy_weeks -= 1


func _law_check() -> void:
	var under: Array = []
	for p in hired_people():
		if p.pay < min_wage:
			under.append("%s is paid %d" % [p.display_name, p.pay])
	if under.size() > 0:
		_issue_penalty(WAGE_FINE, "Wage floor is %d. %s." % [min_wage, "; ".join(under)])
	elif wage_raised and not floor_feelings_applied:
		floor_feelings_applied = true
		for p in hired_people():
			if p.junior and p.pay >= min_wage and p.pay <= min_wage + 30:
				shift_love(p, 1, "the wage floor reached them")
			elif not p.junior and p.pay < min_wage + 120:
				shift_love(p, -1, "the gap over the new floor got smaller")
	if penalty_unpaid > 0:
		unpaid_weeks += 1
		if unpaid_weeks >= 2:
			_lose("A government note ordered the doors shut. The printed penalties stayed unpaid.")
			_push_mail("Government note", _rules_note(loss_reason), "government")
	else:
		unpaid_weeks = 0


func _issue_penalty(amount: int, fact: String) -> void:
	penalty_unpaid += amount
	_push_mail("Government note", _rules_note("%s Penalty on the table: %d. Unpaid total: %d." % [fact, amount, penalty_unpaid]), "government")


func _rules_note(fact: String) -> String:
	return "Rule, from the newspaper.\n%s" % fact


func _credit_tick() -> void:
	var payroll_ok := week_wages <= 0 or cash >= 0
	if payroll_ok and hired_people().size() > 0:
		credit_buffer += 1
	var auntie: Person = person("auntie")
	if auntie.active and auntie.love >= 3:
		credit_buffer += 1
	if week_supplier > 0 and cash >= 0:
		credit_buffer += 1
	if penalty_unpaid > 0 or cash < 0:
		credit_buffer -= 2
	if credit_buffer >= 3 and credit < 5:
		credit += 1
		credit_buffer = 0
		_recompute_rate(true)
	elif credit_buffer <= -2 and credit > 0:
		credit -= 1
		credit_buffer = 0
		_recompute_rate(true)


func _ledger() -> void:
	var profit := week_revenue - week_wages - week_supplier - week_training - week_interest
	lifetime_profit += profit - week_revenue
	_push_mail("Ledger", "Orders paid: %d\nSuppliers: %d\nWages: %d\nTraining: %d\nInterest: %d\nUnpaid penalties: %d\nDebt: %d\nParts: %d\nCash now: %d" % [week_revenue, week_supplier, week_wages, week_training, week_interest, penalty_unpaid, debt, stock, cash], "ledger")


func best_worker_name() -> String:
	var best: Person = null
	for p in hired_people():
		if best == null or p.made > best.made:
			best = p
	if best == null or best.made <= 0:
		return ""
	return best.display_name


func _check_endings() -> void:
	if cash < 0 and credit <= 0 and debt > 0:
		_lose("Credit is broken and cash is below zero. The bank called the loan.")
	if ever_hired and hired_people().is_empty() and not lost:
		_lose("Nobody is left to allocate work to.")
	if _customers_all_gone() and not lost:
		_lose("Every customer ended the account.")


func _customers_all_gone() -> bool:
	for customer in _customers():
		if customer.active:
			return false
	return true


func _customers() -> Array:
	var found: Array = []
	for id in people.keys():
		var p: Person = person(str(id))
		if p.role == "customer":
			found.append(p)
	return found


func _outsiders() -> Array:
	var found: Array = []
	for id in people.keys():
		var p: Person = person(str(id))
		if p.role == "customer" or p.role == "supplier":
			found.append(p)
	return found


func _lose(reason: String) -> void:
	if lost:
		return
	lost = true
	loss_reason = reason
	_push_mail("U r fired", reason, "end")


func _begin_week() -> void:
	week_training = 0
	if week == 4 and not wage_raised:
		wage_raised = true
		floor_feelings_applied = false
		min_wage = WAGE_RAISED
		policy_blurb = "Week 4. The wage floor is now %d. Pay under it is a %d penalty, printed here." % [min_wage, WAGE_FINE]
		_push_mail("Government note", _rules_note("The wage floor rose to %d. Juniors who receive it will feel it. Seniors feel it when the gap over the floor shrinks and their pay does not. Comply from the newspaper, or the penalty table applies." % min_wage), "government")
	elif week == 6 and not subsidy_open and not subsidy_used:
		subsidy_open = true
		policy_blurb = "Week 6. A hiring subsidy is open."
		_push_mail("Government note", _rules_note("The company qualifies for a hiring subsidy of %d. The new hire must stay %d weeks. Firing them early returns the grant plus %d." % [SUBSIDY_GRANT, SUBSIDY_LOCK, SUBSIDY_PENALTY]), "government")
	if rng.randf() < 0.35:
		market_jitter = 0.005 if rng.randf() < 0.5 else -0.005
		_recompute_rate(true)
	if week == 2:
		_open_order(person("lau"))
	elif week == 3:
		_open_order(person("influencer"))
	if week == 4:
		_open_order(person("cafe"))
	elif week == 5:
		_open_order(person("school"))
	if week > 3:
		for customer in _customers():
			if customer.active and not _open_deal_for(customer.id) and rng.randf() < 0.45:
				_open_order(customer)
	if not hidden_applicants.is_empty() and rng.randf() < 0.4:
		look_for_applicant()
	if week > SEASON_WEEKS and not season_checked and not lost:
		season_checked = true
		var hearts_ok := true
		for p in active_people():
			if p.love < 1 and p.role != "employee":
				hearts_ok = false
			if p.role == "employee" and p.hired and p.love < 1:
				hearts_ok = false
		if cash > 0 and hired_people().size() > 0 and hearts_ok:
			season_held = true
			_push_mail("Season", "The season holds. Cash is above zero, the chairs are filled, and every active person still has a heart.", "end")


func _recompute_rate(announce: bool) -> void:
	var old := rate
	var size_cut := 0.0
	if debt >= 3000:
		size_cut = 0.03
	elif debt >= 1500:
		size_cut = 0.015
	rate = clampf(0.10 - size_cut - float(credit) * 0.008 + market_jitter, 0.03, 0.16)
	if announce and not is_equal_approx(old, rate):
		_push_mail("Bank", "The interest rate changed. The sign now reads %s." % rate_text(), "rate")


func _push_mail(title: String, body: String, kind: String) -> void:
	mail.append({
		"id": next_mail,
		"week": week,
		"title": title,
		"body": body,
		"read": false,
		"kind": kind,
	})
	next_mail += 1


func mark_mail_read() -> void:
	for item in mail:
		item["read"] = true
