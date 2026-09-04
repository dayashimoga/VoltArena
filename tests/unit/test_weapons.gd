class_name TestWeapons
extends RefCounted

const WeaponBaseScript = preload("res://games/arena-fps/weapons/weapon_base.gd")
const ScatterCannonScript = preload("res://games/arena-fps/weapons/scatter_cannon.gd")
const RailDriverScript = preload("res://games/arena-fps/weapons/rail_driver.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_pulse_rifle()
	test_scatter_cannon()
	test_rail_driver()
	test_reload_mechanic()
	return {"passed": assertions_passed, "failed": assertions_failed}

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Assertion failed: " + msg)

func test_pulse_rifle() -> void:
	var w = WeaponBaseScript.new()
	assert_true(w.max_clip_ammo == 30, "Pulse rifle clip should be 30")
	assert_true(w.is_automatic, "Pulse rifle should be automatic")
	assert_true(w.damage_per_shot == 18.0, "Damage should be 18")

func test_scatter_cannon() -> void:
	var w = ScatterCannonScript.new()
	assert_true(w.weapon_name == "Scatter Cannon", "Name should be Scatter Cannon")
	assert_true(w.pellets_count == 8, "Pellets count should be 8")
	assert_true(not w.is_automatic, "Shotgun should be semi-auto")

func test_rail_driver() -> void:
	var w = RailDriverScript.new()
	assert_true(w.damage_per_shot == 95.0, "Rail Driver should have 95 damage")
	assert_true(w.max_clip_ammo == 1, "Single shot chamber")
	assert_true(w.spread_angle_deg == 0.0, "Pinpoint zero spread")

func test_reload_mechanic() -> void:
	var w = WeaponBaseScript.new()
	w.current_clip_ammo = 5
	w.max_clip_ammo = 30
	w.current_reserve_ammo = 50
	w.finish_reload()

	assert_true(w.current_clip_ammo == 30, "Clip should be full after reload")
	assert_true(w.current_reserve_ammo == 25, "Reserve should decrease by 25")
