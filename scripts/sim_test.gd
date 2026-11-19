extends SceneTree

## Headless checks for love, training, deals, and the government.

var failed := 0


func _init() -> void:
	_check_tracks()
	_check_training_dice()
	_check_training_steps()
	_check_habit_ignores_love()
	_check_offers()
	_check_deals_and_reports()
	_check_direct_sale()
	_check_training_abandons_deal()
	_check_wage_floor()
	_check_cast_and_government()
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


func _fresh(seed_value: int = 1) -> GameState:
	var game := GameState.new(seed_value)
	game.setup_new_game()
	game.suppress_habits = true
	return game


func _mail_blob(game: GameState) -> String:
	var blob := ""
	for item in game.mail:
		blob += str(item["title"]) + "\n" + str(item["body"]) + "\n"
	return blob


func _deal_for(game: GameState, partner_id: String) -> Dictionary:
	for deal in game.open_deals():
		if str(deal["partner_id"]) == partner_id:
			return deal
	return {}


func _check_tracks() -> void:
	var game := _fresh()
	var mina := game.person("mina")
	mina.love = 5
	var fast: int = game.finished_units(mina, 100)
	var fast_rank: int = game.pace_rank(mina)
	mina.love = 1
	var slow: int = game.finished_units(mina, 100)
	var slow_rank: int = game.pace_rank(mina)
	_ok(game.heart_scale(5) > game.heart_scale(1), "high love scales above low love")
	_ok(fast > slow, "high love finishes more units")
	_ok(fast_rank > slow_rank, "high love is faster")
	_ok(game.pace_day(mina) != "", "pace has a day")


func _check_training_dice() -> void:
	var saw_all := false
	var saw_none := false
	for seed_value in 200:
		var game := GameState.new(seed_value)
		var rolls: Array = game.roll_training_dice()
		if rolls == [true, true, true]:
			saw_all = true
		if rolls == [false, false, false]:
			saw_none = true
	_ok(saw_all, "training can improve every track")
	_ok(saw_none, "training can improve nothing")


func _check_training_steps() -> void:
	var game := _fresh()
	var mina := game.person("mina")
	mina.severity = "serious"
	mina.base_workload = 3
	mina.base_pace = 3
	game.apply_training(mina, [true, true, true])
	_ok(mina.severity == "moderate", "temper softens one step")
	_ok(mina.base_workload == 4, "workload rises one step")
	_ok(mina.base_pace == 4, "pace rises one step")
	var before_severity := mina.severity
	var before_load := mina.base_workload
	var before_pace := mina.base_pace
	game.apply_training(mina, [false, false, false])
	_ok(mina.severity == before_severity and mina.base_workload == before_load and mina.base_pace == before_pace, "a failed course changes nothing")
	mina.severity = "faint"
	mina.base_workload = 6
	mina.base_pace = 6
	game.apply_training(mina, [true, true, true])
	_ok(mina.severity == "faint" and mina.base_workload == 6 and mina.base_pace == 6, "tracks stop at the top step")


func _check_habit_ignores_love() -> void:
	var game := _fresh()
	var otto := game.person("otto")
	otto.love = 5
	game.forced_habits[otto.id] = true
	var incident: Dictionary = game._build_habit(otto)
	_ok(not incident.is_empty() and str(incident["kind"]) == "steal", "a serious habit can fire at love 5")
	otto.love = 1
	incident = game._build_habit(otto)
	_ok(str(incident["kind"]) == "steal", "the same habit can fire at love 1")


func _check_offers() -> void:
	var game := _fresh()
	game.look_for_applicant()
	game.look_for_applicant()
	var rejected: String = game.recruit_offer("june", 300)
	_ok(not game.person("june").hired and rejected.contains("rejected"), "a low salary can be rejected")
	var hired: String = game.recruit_offer("june", 330)
	_ok(game.person("june").hired and game.person("june").love == 1, "a salary under the ask can be accepted at love 1")
	_ok(hired.contains("minor flaw"), "the hire shows the balance")
	game = _fresh()
	game.look_for_applicant()
	game.look_for_applicant()
	var thinking: String = game.recruit_offer("june", 410)
	_ok(thinking.contains("think") and not game.person("june").hired, "a near offer can wait")
	game.insist("june")
	_ok(game.person("june").hired and game.person("june").love == 2, "insisting hires at low love")
	game = _fresh()
	var blocked: String = game.recruit_offer("mina", 100)
	_ok(not game.person("mina").hired and blocked.contains("wage floor"), "pay under the floor does not hire")
	var sat: String = game.recruit_offer("mina", 480)
	_ok(game.person("mina").seat >= 0 and sat.contains("sat"), "an accepted hire takes a chair")
	var cheap: String = game.supplier_offer("cheap", 13)
	_ok(game.person("cheap").love == 1 and cheap.contains("love 1"), "a low supplier price can be accepted at low love")


func _check_deals_and_reports() -> void:
	var game := _fresh()
	game.end_week()
	_ok(not _mail_blob(game).contains("On the call."), "a deal with nobody on it waits")
	game = _fresh()
	game.recruit_offer("mina", 480)
	game.stock = 500
	var deal := _deal_for(game, "auntie")
	_ok(not deal.is_empty(), "Auntie Shop's order is on the sign")
	game.accept_order(str(deal["id"]))
	game.assign("mina", str(deal["id"]), true)
	var deal_id := str(deal["id"])
	game.end_week()
	var blob := _mail_blob(game)
	_ok(blob.contains("On the call."), "the first report is the proposal")
	_ok(blob.contains("Auntie Shop") and blob.contains("Mina"), "the report names every stakeholder")
	_ok(blob.contains("Auntie Shop ") and blob.contains("Mina "), "the report lists their love")
	game.end_week()
	_ok(_mail_blob(game).contains("At the desk."), "the second report is doing")
	game.end_week()
	var finished := _mail_blob(game)
	_ok(finished.contains("Ready to send."), "the third report is almost finish")
	var closed := false
	for item in game.deals:
		if str(item["id"]) == deal_id:
			closed = str(item["stage"]) == "closed"
	_ok(closed, "three stages close the deal")


func _check_direct_sale() -> void:
	var game := _fresh()
	game.recruit_offer("mina", 480)
	var deal := _deal_for(game, "auntie")
	var units := int(deal["units"])
	var price := int(deal["unit_price"])
	var before: int = game.cash
	var ceiling := game.order_ceiling(game.person("auntie"))
	var high: String = game.sell_to_order(str(deal["id"]), ceiling + 5)
	_ok(high.contains("pay up to") and str(deal["stage"]) == "offer", "a high price stays on the order")
	game.stock = units - 1
	var short: String = game.sell_to_order(str(deal["id"]), price)
	_ok(short.contains("Inventory") and game.stock == units - 1, "a short inventory does not sell")
	game.stock = units
	var sold: String = game.sell_to_order(str(deal["id"]), price)
	_ok(str(deal["stage"]) == "closed" and game.stock == 0 and game.cash == before + units * price, "an accepted price sells the inventory")
	_ok(sold.contains("accepted"), "the order accepted the price")
	var packed := _fresh()
	packed.recruit_offer("mina", 480)
	var open_deal := _deal_for(packed, "auntie")
	var packed_units := int(open_deal["units"])
	open_deal["reserved"] = true
	open_deal["stage"] = "doing"
	packed.stock = 3
	var cash_before: int = packed.cash
	var from_pack: String = packed.sell_to_order(str(open_deal["id"]), int(open_deal["unit_price"]))
	_ok(packed.stock == 3 and packed.cash == cash_before + packed_units * int(open_deal["unit_price"]) and from_pack.contains("accepted"), "packed parts are not taken twice")
	game.visible_applicants.append("rosa")
	game.recruit_offer("rosa", 440)
	_ok(game.person("rosa").hired and game.hired_people().size() == 2, "a later hire can be chosen")


func _check_training_abandons_deal() -> void:
	var game := _fresh()
	game.recruit_offer("mina", 480)
	var deal := _deal_for(game, "auntie")
	game.assign("mina", str(deal["id"]), true)
	var before: int = game.person("auntie").love
	var message: String = game.train("mina")
	_ok(game.person("mina").training and message.contains("no work"), "training takes the period off the job")
	_ok(game.person("auntie").love == before - 1, "the last person leaving a deal drops the partner's love")
	_ok(not (deal["crew"] as Array).has("mina"), "a training employee is off the deal")


func _check_wage_floor() -> void:
	var game := _fresh()
	game.week = 3
	game.end_week()
	var blob := _mail_blob(game)
	_ok(game.week == 4 and game.min_wage == 320, "the wage floor rises in week 4")
	_ok(blob.contains("wage floor") or blob.contains("Wage floor"), "a government note announces the floor")
	_ok(game.newspaper_text().contains("320"), "the newspaper shows the new floor")
	_ok(game.newspaper_text().contains("Penalty table"), "the newspaper keeps the penalty table")


func _check_cast_and_government() -> void:
	var game := _fresh()
	_ok(game.person("mina").balance == "great strength, minor flaw", "Mina is a great strength with a minor flaw")
	_ok(game.person("otto").balance == "thin strength, serious flaw", "Otto is a thin strength with a serious flaw")
	_ok(game.person("ben").balance == "mixed", "Ben is mixed")
	_ok(game.person("auntie").balance.begins_with("great"), "Auntie Shop is marked")
	_ok(game.person("cheap").habit == "late_or_junk", "Cheap Parts can be late or junk")
	_ok(game.person("steady").has_strength("deadline_ship"), "Steady Supply meets deadlines")
	var government := false
	for id in game.people.keys():
		if game.person(str(id)).role == "government":
			government = true
	_ok(not government, "the government is not a person with love")
	_ok(game.newspaper_text().contains("does not keep a heart score"), "the paper says the government has no hearts")
	_ok(game.hired_people().is_empty(), "the office starts with empty desks")
