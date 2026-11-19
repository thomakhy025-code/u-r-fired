extends SceneTree

## Headless checks for calls, stock, love, crafting, company skill, and the opening lesson.

var failed: int = 0


func _init() -> void:
	_check_call_needs_finished_goods()
	_check_sale_moves_cash_and_commission()
	_check_love_falls_while_waiting()
	_check_crafting_chairs_and_phones()
	_check_research_improves_next_craft()
	_check_employees_start_at_different_levels()
	_check_teaching_pauses_love_until_first_payout()
	if failed > 0:
		print("FAILED %d" % failed)
		quit(1)
	else:
		print("All simulation checks passed.")
		quit(0)


func _ok(cond: bool, message: String) -> void:
	if cond:
		print("ok ", message)
	else:
		failed += 1
		print("FAIL ", message)


func _fresh() -> GameState:
	var game := GameState.new()
	game.setup_new_game()
	game.ambient = false
	# Later calls use the normal love timer. The lesson check covers the first deal.
	game.teaching = false
	return game


func _check_call_needs_finished_goods() -> void:
	var game := _fresh()
	game.spawn_call("chair", 2)
	game.goods["chair"] = 0
	var person: GameState.Employee = game.find_employee("mina")
	var cash_before := game.cash
	var took := game.assign_employee("mina")
	_ok(person != null and person.busy and took.contains("Mina"), "Mina takes the call")
	game.tick(0.5)
	_ok(person.busy and game.caller != null and game.cash == cash_before, "the deal waits while Mina is on the phone")
	_ok(game.goods_qty("chair") == 0, "chairs stay on the shelf during the call")
	game.tick(game.answer_seconds("chair", 2))
	_ok(game.caller != null, "the caller stays when the shelf is short")
	_ok(person.busy == false, "Mina is free after the short call")
	_ok(game.cash == cash_before and person.commission == 0, "a short shelf pays nothing")
	_ok(game.goods_qty("chair") == 0, "a short call leaves the shelf unchanged")
	_ok(game.notice.contains("chair"), "the missing chairs are named")


func _check_sale_moves_cash_and_commission() -> void:
	var game := _fresh()
	game.spawn_call("phone", 2)
	game.goods["phone"] = 3
	var person: GameState.Employee = game.find_employee("otto")
	var other: GameState.Employee = game.find_employee("mina")
	var cash_before := game.cash
	var pay := game.caller.pay
	var commission := game.commission_for(pay)
	game.assign_employee("otto")
	game.tick(game.answer_seconds("phone", 2))
	_ok(game.caller == null, "the caller leaves when the phones are handed over")
	_ok(game.goods_qty("phone") == 1, "the order leaves the shelf and the spare phone stays")
	_ok(commission > 0 and commission < pay, "commission is a slice of the payment")
	_ok(game.cash == cash_before + pay - commission, "the company receives the payment after commission")
	_ok(person.commission == commission and person.calls_closed == 1, "Otto receives the commission")
	_ok(other.commission == 0 and other.busy == false, "the commission stays with the employee who took the call")
	_ok(game.notice.contains("commission") and game.notice.contains(str(pay - commission)) and game.notice.contains(str(commission)), "the payout shows company cash and commission")
	_ok(game.notice.contains(person.display_name), "the payout names the employee")


func _check_love_falls_while_waiting() -> void:
	var game := _fresh()
	game.spawn_call("phone", 2)
	var started := game.caller.love
	_ok(is_equal_approx(started, 4.0) and game.love_points(started) == 4, "a larger order starts at 4 love")
	game.spawn_call("chair", 1)
	_ok(game.caller.product_id == "phone", "a busy line keeps the caller who is waiting")
	game.tick(3.0)
	_ok(game.caller != null and game.caller.love < started, "love falls while the caller waits")
	var waited := game.caller.love
	game.assign_employee("june")
	game.tick(1.0)
	_ok(game.caller != null and game.caller.phase == "talking" and game.caller.love < waited, "love falls while the employee is on the phone")
	var cash_before := game.cash
	var goods := game.goods_qty("phone")
	game.tick(40.0)
	_ok(game.caller == null, "love at 0 hangs up")
	_ok(game.cash == cash_before and game.goods_qty("phone") == goods, "a hang up hands over nothing")
	var quiet := _fresh()
	quiet.spawn_call("chair", 1)
	_ok(is_equal_approx(quiet.caller.love, 5.0) and quiet.love_text(quiet.caller.love) == "5/5", "a small order starts at 5/5")
	var before := quiet.caller.love
	quiet.tick(4.0)
	_ok(quiet.caller != null and quiet.caller.love < before, "love falls as wait time passes")


func _check_crafting_chairs_and_phones() -> void:
	var game := _fresh()
	var cash_before := game.cash
	var bought := game.buy_material("wood")
	_ok(game.material_qty("wood") == GameState.PACK_QTY, "bought wood arrives in inventory")
	_ok(game.cash == cash_before - game.pack_cost("wood") and bought.contains("wood"), "buying wood spends cash")
	game.materials["wood"] = 2
	game.materials["plastic"] = 0
	game.materials["glass"] = 4
	var wood := game.material_qty("wood")
	var glass := game.material_qty("glass")
	var blocked := game.start_craft("chair")
	_ok(game.material_qty("wood") == wood and game.material_qty("glass") == glass and game.craft == null, "a missing material spends nothing")
	_ok(blocked.contains("Plastic"), "the missing material is named")
	game.materials["plastic"] = 2
	var started := game.start_craft("chair")
	_ok(started.contains("chair"), "the bench starts a chair")
	_ok(game.material_qty("wood") == 1 and game.material_qty("plastic") == 1 and game.material_qty("glass") == glass, "a chair spends wood and plastic")
	_ok(game.goods_qty("chair") == 0, "the chair stays unfinished while the bench works")
	game.tick(game.craft.seconds_left)
	_ok(game.goods_qty("chair") == 1 and game.craft == null, "the bench adds a chair")
	var wood_left := game.material_qty("wood")
	game.start_craft("phone")
	_ok(game.material_qty("plastic") == 0 and game.material_qty("glass") == glass - 1 and game.material_qty("wood") == wood_left, "a phone spends plastic and glass")
	_ok(game.goods_qty("phone") == 0 and game.goods_qty("chair") == 1, "a phone craft leaves the chair on the shelf")
	game.tick(game.craft.seconds_full)
	_ok(game.goods_qty("phone") == 1, "the bench adds a phone")


func _check_research_improves_next_craft() -> void:
	var game := _fresh()
	var before := game.craft_seconds()
	game.cash = 100
	var cash_before := game.cash
	var cost := game.research_cost()
	var bought := game.buy_research()
	_ok(game.cash == cash_before - cost, "research spends cash")
	_ok(game.skill == 2 and bought.contains("2"), "research raises the skill")
	var after := game.craft_seconds()
	_ok(after < before, "research shortens the next craft")
	game.materials["wood"] = 1
	game.materials["plastic"] = 1
	var started := game.start_craft("chair")
	_ok(game.craft != null and is_equal_approx(game.craft.seconds_full, after), "the craft started after research uses the shorter time")
	_ok(game.craft.seconds_full < before and started.contains("chair"), "the bench starts the shorter chair craft")


func _check_employees_start_at_different_levels() -> void:
	var game := _fresh()
	_ok(game.employees.size() >= 3, "the office has a staff")
	_ok(game.employees[0].level != game.employees[1].level and game.employees[1].level != game.employees[2].level, "employees start at different levels")
	_ok(game.employees[0].display_name != "" and game.employees[0].role != "", "employees have a name and a role")


func _check_teaching_pauses_love_until_first_payout() -> void:
	var game := GameState.new()
	game.setup_new_game()
	game.ambient = false
	_ok(game.teaching, "a new game teaches the first deal")
	game.spawn_call("chair", 1)
	var started := game.caller.love
	game.tick(8.0)
	_ok(game.caller != null and is_equal_approx(game.caller.love, started), "love stays while the first caller waits")
	game.assign_employee("mina")
	game.tick(30.0)
	_ok(game.caller != null and game.teaching, "the first caller stays through a short shelf")
	_ok(is_equal_approx(game.caller.love, started), "love stays while the first deal is still open")
	_ok(game.caller.phase == "waiting", "a short shelf sends the caller back to waiting")
	var cash_before := game.cash
	game.materials["wood"] = 1
	game.materials["plastic"] = 1
	game.start_craft("chair")
	game.tick(game.craft.seconds_left)
	_ok(game.goods_qty("chair") == 1 and game.teaching, "the lesson continues until the deal pays")
	game.assign_employee("mina")
	var during := game.caller.love
	game.tick(1.0)
	_ok(game.caller != null and game.caller.phase == "talking" and is_equal_approx(game.caller.love, during), "love stays while the chair is handed over")
	game.tick(game.answer_seconds("chair", 1))
	var mina := game.find_employee("mina")
	_ok(game.caller == null and game.teaching == false, "the first payout ends the lesson")
	_ok(game.cash == cash_before + game.unit_pay("chair") - game.commission_for(game.unit_pay("chair")), "the lesson deal pays the company")
	_ok(mina != null and mina.calls_closed == 1, "the lesson deal counts as closed")
	game.spawn_call("phone", 1)
	var next_love := game.caller.love
	game.tick(3.0)
	_ok(game.caller != null and game.caller.love < next_love, "love falls again after the first payout")
