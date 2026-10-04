extends SceneTree

func _init() -> void:
	print("=== RUNNING ALL STRIKE VECTOR SUITES ===")
	var suites = [
		["Campaign Unit", preload("res://games/strike-vector/tests/test_strike_campaign_unit.gd")],
		["Player Unit", preload("res://games/strike-vector/tests/test_strike_player_unit.gd")],
		["AI Unit", preload("res://games/strike-vector/tests/test_strike_ai_unit.gd")],
		["E2E Campaign", preload("res://games/strike-vector/tests/test_strike_vector_e2e.gd")],
		["Traversal Probes", preload("res://games/strike-vector/tests/test_strike_traversal_probes.gd")],
		["Visual Invariants", preload("res://games/strike-vector/tests/test_strike_visual_invariants.gd")],
		["Runtime Acceptance", preload("res://games/strike-vector/tests/test_strike_runtime_acceptance.gd")]
	]
	var total_p = 0
	var total_f = 0
	for entry in suites:
		var s_name = entry[0]
		var script = entry[1]
		var inst = script.new()
		var res = inst.run_tests()
		var p = res.get("passed", 0)
		var f = res.get("failed", 0)
		total_p += p
		total_f += f
		print("[%s] %d PASSED, %d FAILED [%s]" % [s_name, p, f, "PASS" if f == 0 else "FAIL"])
	print("=== STRIKE VECTOR SUITES COMPLETE: %d PASSED, %d FAILED ===" % [total_p, total_f])
	quit(0 if total_f == 0 else 1)
