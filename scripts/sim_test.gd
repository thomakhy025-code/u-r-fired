extends SceneTree

## Headless checks for the real-time desk, outbox, and phone loop.

var failed := 0


func _init() -> void:
	_check_job_spends_and_reaches_outbox()
	_check_caller_pays_only_for_the_product()
	_check_harder_caller()
	_check_upgrade_shortens_next_job()
	_check_staff_shortens_desk()
	_check_restock_arrives_later()
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
	game.allow_tips = false
	return game


func _check_job_spends_and_reaches_outbox() -> void:
	var game := _fresh()
	var sheets := game.supply_qty("sheets")
	var clips := game.supply_qty("clips")
	var cash_before := game.cash
	var cost := game.product_cost("snack")
	game.supplies["clips"] = 0
	var blocked := game.start_job(0, "snack")
	_ok(game.supply_qty("sheets") == sheets and game.cash == cash_before and game.desks[0].phase == "idle", "a missing supply spends nothing")
	_ok(blocked.contains("Clips"), "the missing supply is named")
	game.supplies["clips"] = clips
	var started := game.start_job(0, "snack")
	_ok(started.contains("Snack"), "the desk starts a snack box")
	_ok(game.supply_qty("sheets") == sheets - 1, "a snack box spends a card sheet")
	_ok(game.supply_qty("clips") == clips - 1, "a snack box spends a clip")
	_ok(game.cash == cash_before - cost, "a snack box spends cash")
	var board := game.supply_qty("board")
	var cloth := game.supply_qty("cloth")
	var after_snack := game.cash
	game.start_job(1, "hamper")
	_ok(game.supply_qty("board") == board - 1 and game.supply_qty("cloth") == cloth - 1, "a gift hamper spends board and cloth")
	_ok(game.cash == after_snack - game.product_cost("hamper"), "a gift hamper spends its own cash")
	var snack_left := game.desks[0].seconds_left
	game.tick(snack_left)
	_ok(game.desks[0].phase == "done", "the desk finishes the snack box")
	_ok(game.desks[1].phase == "cooking", "the other desk keeps its own job")
	_ok(game.outbox.is_empty(), "a finished job waits on the desk")
	var placed := game.place_on_outbox(0)
	_ok(game.outbox.size() == 1 and game.outbox[0] == "snack", "placing the finished job puts it in the outbox")
	_ok(placed.contains("outbox") and game.desks[0].phase == "idle", "the desk is free after the outbox takes the job")
	game.outbox.append("lunch")
	game.desks[0].phase = "done"
	game.desks[0].product_id = "sample"
	var full := game.place_on_outbox(0)
	_ok(game.outbox.size() == 2 and full.contains("full") and game.desks[0].phase == "done", "a full outbox keeps the finished job on the desk")


func _check_caller_pays_only_for_the_product() -> void:
	var game := _fresh()
	game.outbox.append("snack")
	game.spawn_caller("lunch")
	var cash_before := game.cash
	var missed := game.hand_over(0)
	_ok(game.cash == cash_before and game.callers.size() == 1, "a caller pays nothing until their product is handed over")
	_ok(missed.contains("Lunch") and game.outbox.has("snack"), "the other product stays on the outbox")
	var wrong := game.hand_outbox_slot(0)
	_ok(game.cash == cash_before and game.callers.is_empty() and game.outbox.is_empty(), "the wrong product pays nothing")
	_ok(wrong.contains("unhappy"), "the wrong handoff hangs up unhappy")
	game.outbox.append("lunch")
	game.spawn_caller("lunch")
	var pay := game.product_pay("lunch")
	var paid := game.hand_over(0)
	_ok(game.cash == cash_before + pay and paid.contains(str(pay)), "the caller pays when that product is handed over")
	_ok(game.callers.is_empty() and not game.outbox.has("lunch"), "the handed product leaves the outbox")
	game.spawn_caller("snack")
	var waiting := game.callers[0].patience
	game.tick(waiting)
	_ok(game.callers.is_empty() and game.cash == cash_before + pay, "a caller who runs out of patience pays nothing")


func _check_harder_caller() -> void:
	var game := _fresh()
	_ok(game.product_patience("hamper") < game.product_patience("snack"), "a harder caller waits less")
	_ok(game.product_pay("hamper") > game.product_pay("snack"), "a harder caller pays more")
	game.phone_lines = 2
	game.spawn_caller("hamper")
	game.spawn_caller("snack")
	_ok(game.callers[0].patience < game.callers[1].patience, "the hamper caller is given less time")
	_ok(game.callers[0].pay > game.callers[1].pay, "the hamper caller is worth more cash")
	game.phone_lines = 1
	game.callers.clear()
	game.spawn_caller("snack")
	var blocked := game.spawn_caller("lunch")
	_ok(game.callers.size() == 1 and blocked.contains("full"), "one phone line holds one caller")
	game.cash = 80
	game.buy_upgrade("phone")
	game.spawn_caller("lunch")
	_ok(game.phone_lines == 2 and game.callers.size() == 2, "a second line lets another caller wait")


func _check_upgrade_shortens_next_job() -> void:
	var game := _fresh()
	var before := game.job_seconds("snack")
	game.cash = 200
	var cash_before := game.cash
	var bought := game.buy_upgrade("faster")
	_ok(game.cash < cash_before and bought.contains("faster"), "an upgrade spends cash")
	var after := game.job_seconds("snack")
	_ok(after < before, "an upgrade shortens the next job")
	game.start_job(0, "snack")
	_ok(game.desks[0].seconds_full < before and is_equal_approx(game.desks[0].seconds_full, after), "the job started after the upgrade uses the shorter time")


func _check_staff_shortens_desk() -> void:
	var game := _fresh()
	var before := game.job_seconds("snack")
	game.cash = 300
	var hired := game.hire("otto")
	_ok(game.staff[game._staff_index("otto")].hired and hired.contains("Otto"), "Otto can be hired with cash")
	var with_staff := game.job_seconds("snack")
	_ok(with_staff < before, "a hired person shortens desk time")
	var cash_before := game.cash
	var raised := game.upgrade_staff("otto")
	_ok(game.cash < cash_before and game.staff[game._staff_index("otto")].level == 2, "a card upgrade spends cash and raises the level")
	_ok(game.job_seconds("snack") < with_staff and raised.contains("2"), "a higher card makes the next job faster")


func _check_restock_arrives_later() -> void:
	var game := _fresh()
	var sheets := game.supply_qty("sheets")
	game.cash = 40
	var cash_before := game.cash
	game.order_restock()
	_ok(game.cash == cash_before - GameState.RESTOCK_COST, "a restock spends cash")
	_ok(game.supply_qty("sheets") == sheets, "supplies stay put until the delivery")
	game.tick(0.2)
	_ok(game.supply_qty("sheets") == sheets, "the delivery is still on the way")
	game.tick(GameState.RESTOCK_SECONDS)
	_ok(game.supply_qty("sheets") == sheets + GameState.RESTOCK_AMOUNT, "supplies arrive after the wait")
	var coins := game.cash
	game.messes.append(GameState.Mess.new())
	game.messes[0].coins = 3
	var cleaned := game.clean_mess(0)
	_ok(game.messes.is_empty() and game.cash == coins + 3 and cleaned.contains("3"), "cleaning a mess pays a little cash")
