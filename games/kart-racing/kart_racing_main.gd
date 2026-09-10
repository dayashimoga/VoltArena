class_name KartRacingMain
extends Node3D

## Dedicated scene state machine coordinator for Drift Storm
## Manages DriftHome -> ModeSelect -> TrackSelect -> VehicleSelect -> RaceSetup -> Confirm -> Loading -> Grid -> Countdown -> Racing -> Finished
## Enforces complete isolation: No race world, AI karts, or race HUD are rendered before race start.

const KartControllerScript = preload("res://games/kart-racing/kart/kart_controller.gd")
const KartAIScript = preload("res://games/kart-racing/ai/kart_ai.gd")
const TrackGeneratorScript = preload("res://games/kart-racing/tracks/track_generator.gd")
const RaceManagerScript = preload("res://games/kart-racing/game/race_manager.gd")
const DriftStormHUDScript = preload("res://games/kart-racing/ui/drift_storm_hud.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")
const ResultsScreenScript = preload("res://shared/ui/results_screen.gd")

@export var selected_track: String = "speedway" # "speedway", "sunset_coast", "canyon", "skyline", "alpine_rush", "storm_harbor"
@export var selected_kart: String = "speeder" # "speeder", "phantom", "enforcer", "turbo_demon", "formula"
@export var game_mode: String = "quick_race" # "quick_race", "championship", "time_trial", "drift_challenge", "elimination"
@export var ai_racer_count: int = 5

enum State {
	PRE_RACE = 0,
	DRIFT_HOME = 0,
	MODE_SELECT = 1,
	TRACK_SELECT = 2,
	VEHICLE_SELECT = 3,
	RACE_SETUP = 4,
	CONFIRM = 5,
	LOADING = 6,
	GRID = 7,
	COUNTDOWN = 8,
	RACING = 9,
	FINISHED = 10
}

var current_state: State = State.PRE_RACE
var is_race_started: bool = false

var player_kart: Node3D
var ai_karts: Array[Node3D] = []
var all_karts: Array[Node3D] = []
var camera: Camera3D

var race_manager: Node
var track_generator: Node

var hud: Control
var pause_menu: CanvasLayer
var results_screen: CanvasLayer

var camera_override: bool = false

func _ready() -> void:
	setup_scene()

func setup_scene() -> void:
	# UI & HUD
	if not hud:
		hud = DriftStormHUDScript.new()
		hud.name = "HUD"
		add_child(hud)
		if not is_inside_tree():
			hud._ready()

	if not pause_menu:
		pause_menu = PauseMenuScript.new()
		pause_menu.name = "PauseMenu"
		pause_menu.resume_requested.connect(func(): pass)
		pause_menu.restart_requested.connect(_on_restart)
		pause_menu.quit_to_launcher_requested.connect(_on_quit_to_launcher)
		add_child(pause_menu)

	if not results_screen:
		results_screen = ResultsScreenScript.new()
		results_screen.name = "ResultsScreen"
		results_screen.restart_pressed.connect(_on_restart)
		results_screen.launcher_pressed.connect(_on_quit_to_launcher)
		add_child(results_screen)

	# Race Manager
	race_manager = RaceManagerScript.new()
	race_manager.name = "RaceManager"
	race_manager.race_finished.connect(_on_race_finished)
	add_child(race_manager)

	# Player Kart - Slot 1 on home straight
	player_kart = KartControllerScript.new()
	player_kart.name = "PlayerKart"
	player_kart.is_player = true
	player_kart.kart_type = selected_kart
	player_kart.racer_name = "Player 1"
	player_kart.position = Vector3(-2.2, 0.08, 6.0)
	player_kart.rotation.y = 0.0
	add_child(player_kart)
	all_karts.append(player_kart)

	# Follow Camera
	camera = Camera3D.new()
	camera.name = "KartCamera"
	camera.current = true
	add_child(camera)
	camera.look_at_from_position(Vector3(-2.2, 2.2, 11.5), Vector3(-2.2, 0.8, 6.0), Vector3.UP)

	# 5 Competitive AI Racers - Staggered starting grid behind start line
	var grid_slots = [
		Vector3(2.2, 0.08, 9.5),
		Vector3(-2.2, 0.08, 13.0),
		Vector3(2.2, 0.08, 16.5),
		Vector3(-2.2, 0.08, 20.0),
		Vector3(2.2, 0.08, 23.5)
	]
	var ai_names = ["Apex Nova", "Blaze Raptor", "Viper Strike", "Turbo Titan", "Cyber Ghost"]
	var ai_types = ["phantom", "enforcer", "turbo_demon", "formula", "speeder"]
	var ai_offsets = [-1.8, 1.8, -0.9, 0.9, 0.0]
	for i in range(min(ai_racer_count, grid_slots.size())):
		var ai_kart = KartControllerScript.new()
		ai_kart.name = "AI_Racer_" + str(i + 1)
		ai_kart.racer_id = i + 1
		ai_kart.racer_name = ai_names[i]
		ai_kart.kart_type = ai_types[i]
		ai_kart.is_player = false
		ai_kart.position = grid_slots[i]
		ai_kart.rotation.y = 0.0
		add_child(ai_kart)

		var ai_brain = KartAIScript.new()
		ai_brain.name = "KartAI"
		ai_brain.kart = ai_kart
		ai_brain.current_waypoint_index = 0
		ai_brain.lane_offset = ai_offsets[i]
		ai_kart.add_child(ai_brain)

		ai_karts.append(ai_kart)
		all_karts.append(ai_kart)

	# Track Generator
	track_generator = TrackGeneratorScript.new()
	track_generator.name = "TrackGenerator"
	track_generator.track_theme = selected_track
	track_generator.track_built.connect(_on_track_built)
	add_child(track_generator)
	if not is_inside_tree():
		track_generator._ready()

	# CRITICAL REQUIREMENT: NO race world/AI/HUD before Start Race
	# Hide and disable 3D race entities during pre-race menu state
	if current_state == State.PRE_RACE:
		_set_race_world_active(false)
		if hud and hud.has_method("set_in_race_hud_visible"):
			hud.set_in_race_hud_visible(false)

func _set_race_world_active(p_active: bool) -> void:
	if track_generator:
		track_generator.visible = p_active
	if player_kart:
		player_kart.visible = p_active
		player_kart.process_mode = Node.PROCESS_MODE_INHERIT if p_active else Node.PROCESS_MODE_DISABLED
	for ai in ai_karts:
		if is_instance_valid(ai):
			ai.visible = p_active
			ai.process_mode = Node.PROCESS_MODE_INHERIT if p_active else Node.PROCESS_MODE_DISABLED

func _on_track_built(waypoints: Array, checkpoints: Array) -> void:
	# Provide waypoints to AI
	var typed_waypoints: Array[Vector3] = []
	for wp in waypoints:
		if wp is Vector3:
			typed_waypoints.append(wp)

	for ai_kart in ai_karts:
		var brain = ai_kart.get_node_or_null("KartAI")
		if brain:
			brain.waypoints = typed_waypoints
		else:
			for child in ai_kart.get_children():
				if "waypoints" in child:
					child.waypoints = typed_waypoints

	# Connect race manager signals if not already connected
	if race_manager:
		race_manager.racers = all_karts
		race_manager.checkpoints = checkpoints
		for cp in checkpoints:
			if cp and not cp.checkpoint_hit.is_connected(race_manager._on_checkpoint_hit):
				cp.checkpoint_hit.connect(race_manager._on_checkpoint_hit)
		race_manager.process_mode = Node.PROCESS_MODE_DISABLED
		if not race_manager.countdown_tick.is_connected(_on_countdown_tick):
			race_manager.countdown_tick.connect(_on_countdown_tick)
		if not race_manager.race_started.is_connected(_on_race_started):
			race_manager.race_started.connect(_on_race_started)

	reposition_karts_on_grid()

func _on_countdown_tick(count: int) -> void:
	if hud and hud.has_method("show_countdown"):
		hud.show_countdown(str(count))

func _on_race_started() -> void:
	current_state = State.RACING
	if race_manager:
		race_manager.process_mode = Node.PROCESS_MODE_INHERIT
	if hud and hud.has_method("show_countdown"):
		hud.show_countdown("GO!")
	if hud and hud.has_method("dismiss_onboarding"):
		hud.dismiss_onboarding()

func start_race() -> void:
	# Read user selection from HUD if available
	if hud and "selected_track_id" in hud and hud.selected_track_id != "":
		selected_track = hud.selected_track_id
	if hud and "selected_vehicle_id" in hud and hud.selected_vehicle_id != "":
		selected_kart = hud.selected_vehicle_id

	# 1. Update circuit and kart archetype
	select_track(selected_track)
	select_kart(selected_kart)

	# 2. Transition through Countdown
	current_state = State.COUNTDOWN
	is_race_started = true

	# 3. Reveal and enable 3D world and racers on starting grid
	_set_race_world_active(true)
	reposition_karts_on_grid()

	# 4. Dismiss pre-race menu and activate in-race HUD
	if hud:
		if hud.has_method("dismiss_onboarding"):
			hud.dismiss_onboarding()
		if hud.has_method("set_in_race_hud_visible"):
			hud.set_in_race_hud_visible(true)

	# 5. Launch race manager countdown sequence
	if race_manager:
		race_manager.process_mode = Node.PROCESS_MODE_INHERIT
		var cps = track_generator.checkpoints if (track_generator and not track_generator.checkpoints.is_empty()) else race_manager.checkpoints
		race_manager.initialize_race(all_karts, cps)

func reposition_karts_on_grid() -> void:
	if not track_generator:
		return
	var spline = track_generator.get("race_spline")
	if not spline or spline.track_length <= 0.0:
		return
	var t_len = spline.track_length
	for i in range(all_karts.size()):
		var kart = all_karts[i]
		if not is_instance_valid(kart):
			continue
		var grid_dist = fposmod(t_len - (5.0 + i * 3.5), t_len)
		var samp = spline.sample_at_distance(grid_dist)
		var lat_sign = -1.0 if i % 2 == 0 else 1.0
		var pos = samp["pos"] + samp["binormal"] * (lat_sign * 2.2) + Vector3(0, 0.08, 0)
		kart.global_position = pos
		if samp["tangent"].length_squared() > 0.01:
			kart.look_at(pos + samp["tangent"], samp["normal"])
		kart.forward_speed = 0.0
		kart.velocity = Vector3.ZERO

func _process(delta: float) -> void:
	if current_state == State.PRE_RACE or current_state == State.DRIFT_HOME:
		# Menu state: 3D race logic and camera follow remain dormant
		return

	update_camera(delta)

	if hud and is_instance_valid(player_kart):
		if hud.has_method("update_speed"):
			hud.update_speed(player_kart.forward_speed)
		if hud.has_method("update_lap"):
			hud.update_lap(player_kart.current_lap, 3)
		if hud.has_method("update_drift_charge"):
			var tier = 0
			if player_kart.drift_charge_time > 2.5:
				tier = 3
			elif player_kart.drift_charge_time > 1.5:
				tier = 2
			elif player_kart.drift_charge_time > 0.8:
				tier = 1
			hud.update_drift_charge(player_kart.drift_charge_time, tier)
		if hud.has_method("set_wrong_way"):
			hud.set_wrong_way(player_kart.is_wrong_way)
		if race_manager:
			if hud.has_method("update_lap_times"):
				hud.update_lap_times(race_manager.race_time, player_kart.best_lap_time)
			if hud.has_method("update_position") and race_manager.has_method("get_racer_position"):
				hud.update_position(race_manager.get_racer_position(player_kart), race_manager.racers.size())

func update_camera(delta: float) -> void:
	if camera_override:
		return
	if not is_instance_valid(player_kart) or not is_instance_valid(camera):
		return

	var k_pos = player_kart.global_position if player_kart.is_inside_tree() else player_kart.position
	var k_fwd = -player_kart.global_transform.basis.z if player_kart.is_inside_tree() else -player_kart.transform.basis.z

	# Dynamic speed-based FOV and lookahead
	var speed_ratio = clampf(absf(player_kart.forward_speed) / 38.0, 0.0, 1.0)
	var target_fov = lerpf(70.0, 84.0, speed_ratio)
	camera.fov = lerpf(camera.fov, target_fov, delta * 5.0)

	var target_cam = k_pos - k_fwd * (6.5 + speed_ratio * 1.5) + Vector3(0, 2.6, 0)
	if camera.is_inside_tree():
		camera.global_position = camera.global_position.lerp(target_cam, delta * 12.0)
		camera.look_at(k_pos + Vector3(0, 0.9, 0), Vector3.UP)
	else:
		camera.position = camera.position.lerp(target_cam, delta * 12.0)
		camera.look_at_from_position(camera.position, k_pos + Vector3(0, 0.9, 0), Vector3.UP)

func _on_race_finished(winner: Node) -> void:
	current_state = State.FINISHED
	var won = (winner == player_kart)
	var best_lap = player_kart.best_lap_time
	var sm = GameConstants.get_autoload(self, "SaveManager")
	if sm:
		sm.record_kart_race(selected_track, best_lap, won)

	results_screen.display_results(won, {
		"Position": "1st Place (WINNER!)" if won else "Finished",
		"Total Time": "%.2fs" % race_manager.race_time,
		"Best Lap": "%.2fs" % best_lap if best_lap < 900.0 else "N/A"
	})

func _on_restart() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.game_restart_requested.emit()

func _on_quit_to_launcher() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.return_to_launcher_requested.emit()

func select_track(track_name: String) -> void:
	selected_track = track_name
	if track_generator and is_instance_valid(track_generator):
		track_generator.track_theme = selected_track
		track_generator.waypoints.clear()
		track_generator.checkpoints.clear()
		for child in track_generator.get_children():
			child.queue_free()
		track_generator.build_circuit()
		reposition_karts_on_grid()

func select_kart(kart_name: String) -> void:
	selected_kart = kart_name
	if player_kart and is_instance_valid(player_kart) and player_kart.has_method("set_kart_type"):
		player_kart.set_kart_type(selected_kart)
