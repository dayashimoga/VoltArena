class_name TestPickupBase
extends RefCounted

const PickupBaseScript = preload("res://games/arena-fps/pickups/pickup_base.gd")
const PowerUpItemScript = preload("res://games/kart-racing/powerups/powerup_item.gd")
const KartControllerScript = preload("res://games/kart-racing/kart/kart_controller.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_pickup_initialization()
	test_pickup_consume_and_respawn()
	test_pickup_process_bobbing()
	test_powerup_item()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		[
			"res://games/arena-fps/pickups/pickup_base.gd",
			["_ready", "setup_visual", "_process", "consume", "respawn"]
		],
		[
			"res://games/kart-racing/powerups/powerup_item.gd",
			["setup_visual", "_process"]
		]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit PickupBase FAIL: " + msg)

func test_pickup_initialization() -> void:
	var p = PickupBaseScript.new()
	p.pickup_type = p.PickupType.HEALTH
	p._ready()
	assert_true(p.is_active, "Pickup must start active")
	assert_true(p.visual_mesh != null, "Pickup must have visual mesh")
	p.queue_free()

func test_pickup_consume_and_respawn() -> void:
	var p = PickupBaseScript.new()
	p.pickup_type = p.PickupType.ARMOR
	p._ready()
	p.consume()
	assert_true(not p.is_active, "Pickup must become inactive on consume")
	assert_true(not p.visible, "Pickup must hide on consume")
	assert_true(p.respawn_timer > 0.0, "Respawn timer must start")

	p.respawn()
	assert_true(p.is_active, "Pickup must be active after respawn")
	assert_true(p.visible, "Pickup must be visible after respawn")
	p.queue_free()

func test_pickup_process_bobbing() -> void:
	var p = PickupBaseScript.new()
	p._ready()
	p._process(0.016)
	assert_true(p.is_active, "Active pickup processes animation")
	p.consume()
	p.respawn_timer = 0.01
	p._process(0.02)
	assert_true(p.is_active, "Pickup must respawn automatically when timer expires")
	p.queue_free()

func test_powerup_item() -> void:
	var item = PowerUpItemScript.new()
	item.setup_visual()
	assert_true(item.box_mesh != null, "Powerup must have box mesh")
	item._process(0.016)
	assert_true(item.is_active, "Powerup item must start active")
	item.queue_free()
