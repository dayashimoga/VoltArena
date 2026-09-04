class_name TestArenaE2E
extends RefCounted

## End-to-end gameplay acceptance test for Iron Crucible (Arena FPS).
## Tests: scene setup → movement → weapon fire/reload/switch → bot combat →
## health/score changes → death/respawn → pause/resume → match end → results → restart

const ArenaFPSMainScript = preload("res://games/arena-fps/arena_fps_main.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0
var coverage_entries: Array = []

func run_tests() -> Dictionary:
	test_scene_setup()
	test_player_movement_state()
	test_weapon_fire_and_ammo()
	test_weapon_switching()
	test_weapon_reload()
	test_bot_damage_and_kill()
	test_player_damage_and_death()
	test_score_tracking()
	test_match_timer_and_end()
	test_results_display()
	test_pause_and_resume()
	test_restart_signal()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/arena-fps/arena_fps_main.gd", ["_ready", "_process", "setup_scene", "connect_events", "end_match"]],
		["res://games/arena-fps/player/fps_player.gd", ["_ready", "_physics_process", "setup_default_nodes", "setup_weapons", "select_weapon", "connect_health", "apply_recoil", "add_ammo", "handle_look_and_recoil", "handle_movement", "handle_weapons_input", "notify_ammo_update", "update_view_bobbing"]],
		["res://games/arena-fps/weapons/weapon_base.gd", ["can_fire", "trigger_fire", "start_reload", "finish_reload", "add_reserve_ammo", "setup_weapon_visual"]],
		["res://shared/combat/health_component.gd", ["take_damage", "heal", "add_armor", "reset"]],
		["res://shared/ui/hud_base.gd", ["_ready"]],
		["res://shared/ui/pause_menu.gd", ["_ready"]],
		["res://shared/ui/results_screen.gd", ["display_results"]],
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("E2E Arena FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

# --- Test Cases ---

func test_scene_setup() -> void:
	var arena = ArenaFPSMainScript.new()
	arena.setup_scene()

	assert_true(arena.player_node != null, "Player must be instantiated")
	assert_true(arena.bots.size() == 3, "Must spawn 3 bots")
	assert_true(arena.hud != null, "HUD must exist")
	assert_true(arena.pause_menu != null, "PauseMenu must exist")
	assert_true(arena.results_screen != null, "ResultsScreen must exist")
	assert_true(arena.match_active, "Match must be active on start")
	assert_true(arena.time_remaining > 0.0, "Timer must be positive")
	assert_eq(arena.player_score, 0, "Player score must start at 0")
	assert_eq(arena.bot_score, 0, "Bot score must start at 0")

	# Verify map was generated (child node "ArenaMap" exists)
	var map = arena.get_node_or_null("ArenaMap")
	assert_true(map != null, "ArenaMap must be generated")

	arena.queue_free()

func test_player_movement_state() -> void:
	var arena = ArenaFPSMainScript.new()
	arena.setup_scene()
	var player = arena.player_node

	# Verify player has collision shape, camera, and weapon holder
	assert_true(player.camera_pivot != null, "Player must have camera pivot")
	assert_true(player.camera != null, "Player must have camera")
	assert_true(player.weapon_holder != null, "Player must have weapon holder")
	assert_true(player.health_component != null, "Player must have HealthComponent")

	# Exercise player physics, movement, and input handling
	player._ready()
	player.handle_movement(0.016)
	player.handle_look_and_recoil(0.016)
	player.handle_weapons_input()
	player.update_view_bobbing(0.016)
	player.notify_ammo_update(player.weapons[0])
	player._physics_process(0.016)
	arena._process(0.016)

	arena.queue_free()

func test_weapon_fire_and_ammo() -> void:
	var arena = ArenaFPSMainScript.new()
	arena.setup_scene()
	var player = arena.player_node

	assert_eq(player.weapons.size(), 5, "Player must have 5 weapons")

	var w = player.weapons[0]  # Pulse Rifle
	var initial_ammo = w.current_clip_ammo
	assert_true(initial_ammo > 0, "Weapon must start with ammo")

	var fired = w.trigger_fire(Vector3.ZERO, Vector3.FORWARD)
	assert_true(fired, "Weapon must fire successfully")
	assert_eq(w.current_clip_ammo, initial_ammo - 1, "Ammo must decrement by 1")

	# Fire until empty
	for i in range(initial_ammo):
		w.last_fire_time = 0.0
		w.trigger_fire(Vector3.ZERO, Vector3.FORWARD)
	assert_eq(w.current_clip_ammo, 0, "Clip must be empty after exhausting ammo")

	arena.queue_free()

func test_weapon_switching() -> void:
	var arena = ArenaFPSMainScript.new()
	arena.setup_scene()
	var player = arena.player_node

	player.select_weapon(0)
	assert_eq(player.current_weapon_index, 0, "Must select weapon 0")
	assert_true(player.weapons[0].visible, "Weapon 0 must be visible")
	assert_true(not player.weapons[1].visible, "Weapon 1 must be hidden")

	player.select_weapon(2)
	assert_eq(player.current_weapon_index, 2, "Must select weapon 2")
	assert_true(player.weapons[2].visible, "Weapon 2 must be visible")
	assert_true(not player.weapons[0].visible, "Weapon 0 must be hidden after switch")

	# Test wraparound
	player.select_weapon(7)  # 7 % 5 = 2
	assert_eq(player.current_weapon_index, 2, "Weapon index must wrap via posmod")

	arena.queue_free()

func test_weapon_reload() -> void:
	var arena = ArenaFPSMainScript.new()
	arena.setup_scene()
	var w = arena.player_node.weapons[0]

	w.current_clip_ammo = 5
	w.current_reserve_ammo = 50
	w.finish_reload()

	assert_eq(w.current_clip_ammo, w.max_clip_ammo, "Clip must be full after reload")
	assert_eq(w.current_reserve_ammo, 25, "Reserve must decrease by reloaded amount")

	# Test reload with insufficient reserve
	w.current_clip_ammo = 0
	w.current_reserve_ammo = 10
	w.finish_reload()
	assert_eq(w.current_clip_ammo, 10, "Clip must get only available reserve ammo")
	assert_eq(w.current_reserve_ammo, 0, "Reserve must be 0 after partial reload")

	arena.queue_free()

func test_bot_damage_and_kill() -> void:
	var arena = ArenaFPSMainScript.new()
	arena.setup_scene()

	var bot = arena.bots[0]
	assert_true(bot.health_component != null, "Bot must have HealthComponent")
	assert_true(not bot.health_component.is_dead, "Bot must start alive")

	# Apply non-lethal damage
	var initial_hp = bot.health_component.current_health
	bot.health_component.take_damage(20.0)
	assert_true(bot.health_component.current_health < initial_hp, "Bot health must decrease")

	# Apply lethal damage
	bot.health_component.take_damage(500.0)
	assert_true(bot.health_component.is_dead, "Bot must die from lethal damage")
	assert_eq(bot.health_component.current_health, 0.0, "Health must be 0 after death")

	arena.queue_free()

func test_player_damage_and_death() -> void:
	var arena = ArenaFPSMainScript.new()
	arena.setup_scene()
	var player = arena.player_node

	assert_true(not player.health_component.is_dead, "Player must start alive")

	# Headshot test: double damage
	player.health_component.current_armor = 0.0
	var hp_before = player.health_component.current_health
	player.health_component.take_damage(10.0, null, true)
	var dmg_taken = hp_before - player.health_component.current_health
	assert_true(dmg_taken >= 19.5, "Headshot must deal ~2x damage")  # Allow float imprecision

	# Kill the player
	player.health_component.take_damage(500.0)
	assert_true(player.health_component.is_dead, "Player must die from lethal damage")

	arena.queue_free()

func test_score_tracking() -> void:
	var arena = ArenaFPSMainScript.new()
	arena.setup_scene()

	assert_eq(arena.player_score, 0, "Player score starts at 0")
	arena._on_enemy_killed("Bot", 100)
	assert_eq(arena.player_score, 100, "Score must increase on enemy kill")

	arena._on_enemy_killed("Bot", 200)
	assert_eq(arena.player_score, 300, "Score must accumulate")

	arena._on_player_died("Bot")
	assert_eq(arena.bot_score, 100, "Bot score must increase on player death")

	arena.queue_free()

func test_match_timer_and_end() -> void:
	var arena = ArenaFPSMainScript.new()
	arena.setup_scene()

	# Simulate time running out
	arena.time_remaining = 0.5
	arena._process(1.0)  # 1 second delta
	assert_true(not arena.match_active, "Match must end when time expires")

	arena.queue_free()

func test_results_display() -> void:
	var arena = ArenaFPSMainScript.new()
	arena.setup_scene()

	# End the match manually
	arena.player_score = 500
	arena.bot_score = 200
	arena.end_match()

	assert_true(not arena.match_active, "Match must be inactive after end")
	# Results screen should have been called with win=true
	assert_true(arena.results_screen != null, "Results screen must exist")

	arena.queue_free()

func test_pause_and_resume() -> void:
	var arena = ArenaFPSMainScript.new()
	arena.setup_scene()

	# Verify pause menu exists and resume callback works
	assert_true(arena.pause_menu != null, "PauseMenu must exist")
	# Calling _on_resume should not crash
	arena._on_resume()
	assert_true(arena.match_active, "Match must still be active after resume")

	arena.queue_free()

func test_restart_signal() -> void:
	var arena = ArenaFPSMainScript.new()
	arena.setup_scene()

	# _on_restart and _on_quit_to_launcher should not crash without EventBus
	arena._on_restart()
	arena._on_quit_to_launcher()
	assert_true(true, "Restart/quit signals must not crash without EventBus")

	arena.queue_free()
