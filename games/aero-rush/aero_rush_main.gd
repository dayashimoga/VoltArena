class_name AeroRushMain
extends Node3D

## Master Game Coordinator for AeroRush: Impossible Circuit.
## Manages state transitions, world & track procedural instantiation,
## player & rival AI spawning, stunt combo tracking, telemetry, and persistence.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")
const AeroCourseDatabase = preload("res://games/aero-rush/tracks/aero_course_database.gd")
const AeroTrackGenerator = preload("res://games/aero-rush/tracks/aero_track_generator.gd")
const AeroCheckpoint = preload("res://games/aero-rush/tracks/aero_checkpoint.gd")
const AeroMovingHazard = preload("res://games/aero-rush/tracks/aero_moving_hazard.gd")

const AeroVehicle = preload("res://games/aero-rush/vehicles/aero_vehicle.gd")
const AeroChaseCamera = preload("res://games/aero-rush/vehicles/aero_chase_camera.gd")
const AeroRivalAI = preload("res://games/aero-rush/ai/aero_rival_ai.gd")
const AeroGhostSystem = preload("res://games/aero-rush/ai/aero_ghost_system.gd")

const AeroStuntDetector = preload("res://games/aero-rush/core/aero_stunt_detector.gd")
const AeroComboSystem = preload("res://games/aero-rush/core/aero_combo_system.gd")
const AeroSaveAdapter = preload("res://games/aero-rush/persistence/aero_save_adapter.gd")
const AeroTrackValidator = preload("res://games/aero-rush/tracks/aero_track_validator.gd")


const AeroWorldMegacity = preload("res://games/aero-rush/worlds/aero_world_megacity.gd")
const AeroWorldCanyon = preload("res://games/aero-rush/worlds/aero_world_canyon.gd")
const AeroWorldCoastal = preload("res://games/aero-rush/worlds/aero_world_coastal.gd")
const AeroWorldSky = preload("res://games/aero-rush/worlds/aero_world_sky.gd")

const AeroHUD = preload("res://games/aero-rush/ui/aero_hud.gd")
const AeroMainMenu = preload("res://games/aero-rush/ui/aero_main_menu.gd")
const AeroGarage = preload("res://games/aero-rush/ui/aero_garage.gd")
const AeroCourseSelect = preload("res://games/aero-rush/ui/aero_course_select.gd")
const AeroResultsScreen = preload("res://games/aero-rush/ui/aero_results_screen.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")

# State Machine
enum State {
	MENU,
	GARAGE,
	COURSE_SELECT,
	COUNTDOWN,
	RACING,
	RESULTS
}

var current_state: State = State.MENU

# Session Configuration
var selected_course_id: String = "neon_express"
var selected_vehicle_id: String = AeroConstants.VEHICLE_APEX
var selected_paint_color: Color = Color(0.08, 0.58, 0.95)

# Runtime Scene Hierarchy
var world_container: Node3D
var track_container: Node3D
var hazards_container: Node3D
var racers_container: Node3D

var active_world: Node3D = null
var player_vehicle: AeroVehicle = null
var chase_camera: AeroChaseCamera = null
var rival_vehicles: Array[AeroVehicle] = []
var checkpoints: Array[AeroCheckpoint] = []

# Subsystems
var stunt_detector: AeroStuntDetector = null
var combo_system: AeroComboSystem = null
var ghost_system: AeroGhostSystem = null

# UI References
var hud: AeroHUD = null
var main_menu: AeroMainMenu = null
var garage: AeroGarage = null
var course_select: AeroCourseSelect = null
var results_screen: AeroResultsScreen = null
var pause_menu: PauseMenu = null

# Racing Metrics
var race_timer: float = 0.0
var countdown_timer: float = 3.5
var current_lap: int = 1
var total_laps: int = 2
var next_checkpoint_idx: int = 0
var course_def: Dictionary = {}

func _ready() -> void:
	_init_containers()
	_init_subsystems()
	_init_ui()

	# Ensure game context is registered so InputMap actions are fully populated
	var im = GameConstants.get_autoload(self, "InputManager")
	if im and im.has_method("set_game_context"):
		im.set_game_context("aero_rush")

	# Load saved vehicle selection
	var saved_data = AeroSaveAdapter.load_aero_data()
	selected_vehicle_id = saved_data.get("selected_vehicle", AeroConstants.VEHICLE_APEX)

	# Check command line arguments for instant launch
	var args = OS.get_cmdline_user_args()
	if "--quick" in args or "--test" in args:
		quick_play()
	else:
		set_state(State.MENU)

func _init_containers() -> void:
	world_container = Node3D.new()
	world_container.name = "WorldContainer"
	add_child(world_container)

	track_container = Node3D.new()
	track_container.name = "TrackContainer"
	add_child(track_container)

	hazards_container = Node3D.new()
	hazards_container.name = "HazardsContainer"
	add_child(hazards_container)

	racers_container = Node3D.new()
	racers_container.name = "RacersContainer"
	add_child(racers_container)

func _init_subsystems() -> void:
	stunt_detector = AeroStuntDetector.new()
	combo_system = AeroComboSystem.new()
	ghost_system = AeroGhostSystem.new()

	stunt_detector.stunt_verified.connect(_on_stunt_verified)
	combo_system.combo_updated.connect(_on_combo_updated)
	combo_system.combo_banked.connect(_on_combo_banked)
	combo_system.combo_dropped.connect(_on_combo_dropped)

func _init_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "AeroCanvasLayer"
	add_child(canvas)

	hud = AeroHUD.new()
	hud.restart_requested.connect(restart_race)
	hud.quit_to_menu_requested.connect(func(): set_state(State.MENU))
	canvas.add_child(hud)
	if not hud.is_node_ready():
		hud._ready()

	main_menu = AeroMainMenu.new()
	main_menu.quick_play_requested.connect(quick_play)
	main_menu.courses_menu_requested.connect(func(): set_state(State.COURSE_SELECT))
	main_menu.garage_menu_requested.connect(func(): set_state(State.GARAGE))
	main_menu.return_to_hub_requested.connect(_on_return_to_hub)
	canvas.add_child(main_menu)
	if not main_menu.is_node_ready():
		main_menu._ready()

	garage = AeroGarage.new()
	garage.vehicle_selected.connect(_on_vehicle_selected_in_garage)
	garage.back_to_menu_requested.connect(func(): set_state(State.MENU))
	canvas.add_child(garage)
	if not garage.is_node_ready():
		garage._ready()

	course_select = AeroCourseSelect.new()
	course_select.course_chosen.connect(start_race)
	course_select.back_requested.connect(func(): set_state(State.MENU))
	canvas.add_child(course_select)
	if not course_select.is_node_ready():
		course_select._ready()

	results_screen = AeroResultsScreen.new()
	results_screen.next_course_requested.connect(_on_next_course)
	results_screen.retry_requested.connect(restart_race)
	results_screen.return_to_menu_requested.connect(func(): set_state(State.MENU))
	results_screen.return_to_hub_requested.connect(_on_return_to_hub)
	canvas.add_child(results_screen)
	if not results_screen.is_node_ready():
		results_screen._ready()

	pause_menu = PauseMenuScript.new()
	pause_menu.name = "PauseMenu"
	pause_menu.resume_requested.connect(func():
		if hud:
			hud.is_paused = false
	)
	pause_menu.restart_checkpoint_requested.connect(func():
		if is_instance_valid(player_vehicle) and player_vehicle.has_method("recover_to_checkpoint"):
			player_vehicle.recover_to_checkpoint()
	)
	pause_menu.restart_event_requested.connect(restart_race)
	pause_menu.restart_requested.connect(restart_race)
	pause_menu.main_menu_requested.connect(func(): set_state(State.MENU))
	pause_menu.quit_to_launcher_requested.connect(_on_return_to_hub)
	pause_menu.quit_to_desktop_requested.connect(func():
		var tree = get_tree()
		if tree and OS.get_name() != "Web":
			tree.quit()
	)
	canvas.add_child(pause_menu)
	if not pause_menu.is_node_ready():
		pause_menu._ready()

func _unhandled_input(event: InputEvent) -> void:
	if current_state in [State.RACING, State.COUNTDOWN]:
		var is_pause_key = event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")
		if not is_pause_key and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			is_pause_key = true
		if not is_pause_key and event is InputEventJoypadButton and event.pressed and (event.button_index == JOY_BUTTON_START or event.button_index == JOY_BUTTON_BACK):
			is_pause_key = true

		if is_pause_key and is_instance_valid(pause_menu):
			if pause_menu.visible:
				pause_menu.hide_pause()
			else:
				pause_menu.show_pause()
			get_viewport().set_input_as_handled()

func set_state(new_state: State) -> void:
	current_state = new_state
	if is_instance_valid(pause_menu):
		pause_menu.hide_pause()

	main_menu.visible = (new_state == State.MENU)
	garage.visible = (new_state == State.GARAGE)
	course_select.visible = (new_state == State.COURSE_SELECT)
	hud.visible = (new_state == State.COUNTDOWN or new_state == State.RACING)
	results_screen.visible = (new_state == State.RESULTS)

	match new_state:
		State.MENU:
			clean_up_session()
			_play_music("aero_rush")
		State.GARAGE:
			clean_up_session()
		State.COURSE_SELECT:
			clean_up_session()
		State.COUNTDOWN:
			countdown_timer = 3.5
			race_timer = 0.0
			hud.set_countdown_text("READY")
		State.RACING:
			if player_vehicle:
				player_vehicle.controls_enabled = true
				player_vehicle.programmatic_override = false
			ghost_system.start_recording()

func quick_play() -> void:
	selected_course_id = "neon_express"
	start_race(selected_course_id)

func start_race(course_id: String) -> void:
	var im = GameConstants.get_autoload(self, "InputManager")
	if im and im.has_method("set_game_context"):
		im.set_game_context("aero_rush")

	selected_course_id = course_id
	course_def = AeroCourseDatabase.get_course_by_id(course_id)

	# Pre-Launch Circuit Validation Gate
	var val_result = AeroTrackValidator.validate_before_launch(course_def)
	if not val_result.get("valid", false):
		push_warning("Circuit '%s' failed pre-launch validation: %s. Falling back to reference circuit." % [course_id, val_result.get("reason", "")])
		selected_course_id = "neon_express"
		course_def = AeroCourseDatabase.get_course_by_id("neon_express")

	total_laps = course_def.get("laps", 2)
	current_lap = 1
	next_checkpoint_idx = 0

	clean_up_session()

	# 1. Spawn World Environment
	_spawn_environment(course_def.get("environment", AeroConstants.EnvironmentType.NEON_MEGACITY))

	# 2. Build Track
	_build_track(course_def)

	# 3. Spawn Hazards
	_spawn_hazards(course_def)

	# 4. Spawn Player Vehicle & Chase Camera with Safe Ground Probing
	_spawn_player_vehicle(course_def)

	# 5. Spawn Rival Racers
	_spawn_rivals(course_def)

	# 6. Reset Stunt & Combo
	combo_system.reset()
	stunt_detector.setup(player_vehicle)

	# 7. Start Audio
	_play_course_music(course_def.get("environment", AeroConstants.EnvironmentType.NEON_MEGACITY))

	# Transition to Countdown
	set_state(State.COUNTDOWN)

func restart_race() -> void:
	start_race(selected_course_id)

func _spawn_environment(env_type: int) -> void:
	match env_type:
		AeroConstants.EnvironmentType.MOUNTAIN_CANYON:
			active_world = AeroWorldCanyon.new()
		AeroConstants.EnvironmentType.TROPICAL_COASTAL:
			active_world = AeroWorldCoastal.new()
		AeroConstants.EnvironmentType.SKY_CIRCUIT:
			active_world = AeroWorldSky.new()
		_:
			active_world = AeroWorldMegacity.new()

	world_container.add_child(active_world)
	if active_world.has_method("build_environment"):
		active_world.build_environment()

func _build_track(c_def: Dictionary) -> void:
	var waypoints = c_def.get("waypoints", []) as Array
	var track_data = AeroTrackGenerator.generate_track(waypoints, 16.0)

	var root_track = track_data.get("root") as Node3D
	if root_track:
		track_container.add_child(root_track)

	# Spawn Checkpoint Area3D gates
	var cp_indices = c_def.get("checkpoints", []) as Array
	checkpoints.clear()

	for i in range(cp_indices.size()):
		var wp_idx = int(cp_indices[i])
		if wp_idx < waypoints.size():
			var wp = waypoints[wp_idx]
			var gate = AeroCheckpoint.new()
			gate.checkpoint_index = i
			gate.is_start_line = (i == 0)
			gate.is_finish_line = (i == cp_indices.size() - 1)
			gate.position = wp["pos"] as Vector3

			gate.checkpoint_passed.connect(_on_checkpoint_passed)
			track_container.add_child(gate)

			# Orient gate along forward direction safely
			var fwd = wp.get("forward", Vector3.FORWARD) as Vector3
			if fwd.length_squared() > 0.001:
				if gate.is_inside_tree():
					gate.look_at(gate.global_position + fwd, Vector3.UP)
				else:
					var up = Vector3.UP
					var z_axis = -fwd.normalized()
					var x_axis = up.cross(z_axis).normalized()
					var y_axis = z_axis.cross(x_axis).normalized()
					gate.transform.basis = Basis(x_axis, y_axis, z_axis)

			checkpoints.append(gate)

func _spawn_hazards(c_def: Dictionary) -> void:
	var hazards = c_def.get("hazards", []) as Array
	for h in hazards:
		var hazard = AeroMovingHazard.new()
		hazard.hazard_type = h.get("type", 0) as AeroMovingHazard.HazardType
		hazard.position = h.get("pos", Vector3.ZERO) as Vector3
		hazards_container.add_child(hazard)

func _spawn_player_vehicle(c_def: Dictionary) -> void:
	player_vehicle = AeroVehicle.new()
	player_vehicle.name = "PlayerAeroVehicle"
	player_vehicle.vehicle_id = selected_vehicle_id
	player_vehicle.is_player = true
	player_vehicle.paint_color = selected_paint_color
	player_vehicle.controls_enabled = false
	player_vehicle.programmatic_override = false

	var raw_spawn_pos = c_def.get("spawn_pos", Vector3(0, 0.55, 0)) as Vector3
	var spawn_rot_y = c_def.get("spawn_rot_y", 0.0) as float
	var safe_pos = _probe_track_surface_elevation(raw_spawn_pos)

	player_vehicle.position = safe_pos
	player_vehicle.rotation_degrees.y = spawn_rot_y

	racers_container.add_child(player_vehicle)
	if not player_vehicle.is_node_ready():
		player_vehicle._ready()

	player_vehicle.last_safe_checkpoint_pos = player_vehicle.global_position if player_vehicle.is_inside_tree() else safe_pos
	player_vehicle.last_safe_checkpoint_basis = player_vehicle.global_basis if player_vehicle.is_inside_tree() else Basis(Vector3.UP, deg_to_rad(spawn_rot_y))

	# Setup Camera with immediate orientation and target lock
	chase_camera = AeroChaseCamera.new()
	chase_camera.name = "AeroChaseCamera"
	racers_container.add_child(chase_camera)
	if not chase_camera.is_node_ready():
		chase_camera._ready()
	chase_camera.setup_target(player_vehicle)

func _probe_track_surface_elevation(origin_pos: Vector3) -> Vector3:
	var world3d = get_world_3d()
	if world3d and world3d.direct_space_state:
		var space = world3d.direct_space_state
		var query = PhysicsRayQueryParameters3D.create(
			origin_pos + Vector3(0, 30.0, 0),
			origin_pos - Vector3(0, 30.0, 0),
			AeroConstants.LAYER_WORLD
		)
		var hit = space.intersect_ray(query)
		if not hit.is_empty():
			return hit["position"] + Vector3(0, 0.55, 0)
	return origin_pos + Vector3(0, 0.55, 0)

func _spawn_rivals(c_def: Dictionary) -> void:
	rival_vehicles.clear()
	var waypoints = c_def.get("waypoints", []) as Array
	var spawn_pos = c_def.get("spawn_pos", Vector3(0, 0.45, 0)) as Vector3
	var rival_models = [AeroConstants.VEHICLE_STRYKER, AeroConstants.VEHICLE_DUNE, AeroConstants.VEHICLE_QUANTUM]

	for r in range(2):
		var rival = AeroVehicle.new()
		rival.name = "RivalAeroVehicle_%d" % r
		rival.vehicle_id = rival_models[r % rival_models.size()]
		rival.is_player = false
		rival.paint_color = Color(0.95, 0.22, 0.18) if r == 0 else Color(0.18, 0.85, 0.32)

		var offset_x = -3.8 if r == 0 else 3.8
		var r_pos = spawn_pos + Vector3(offset_x, 0.0, 8.0 + float(r * 4.5))
		var safe_r_pos = _probe_track_surface_elevation(r_pos)
		rival.position = safe_r_pos
		racers_container.add_child(rival)

		var ai = AeroRivalAI.new()
		ai.name = "AIController"
		ai.setup(rival, waypoints, 0.85)
		rival.add_child(ai)
		rival_vehicles.append(rival)

func _physics_process(delta: float) -> void:
	match current_state:
		State.COUNTDOWN:
			_process_countdown(delta)
		State.RACING:
			_process_racing(delta)

func _process_countdown(delta: float) -> void:
	countdown_timer -= delta
	if countdown_timer > 2.5:
		hud.set_countdown_text("3")
	elif countdown_timer > 1.5:
		hud.set_countdown_text("2")
	elif countdown_timer > 0.5:
		hud.set_countdown_text("1")
	elif countdown_timer > 0.0:
		hud.set_countdown_text("AERO RUSH!")
	else:
		hud.set_countdown_text("")
		set_state(State.RACING)

func _process_racing(delta: float) -> void:
	race_timer += delta
	stunt_detector.update(delta)
	combo_system.update(delta)

	if player_vehicle and is_instance_valid(player_vehicle):
		hud.update_speed(player_vehicle.get_speed_kmh())
		hud.update_boost(player_vehicle.boost_gauge, player_vehicle.max_boost_gauge)
		hud.update_time(race_timer)
		hud.update_lap(current_lap, total_laps)
		hud.update_checkpoint(next_checkpoint_idx + 1, checkpoints.size())
		ghost_system.record_frame(player_vehicle, delta, race_timer)

	ghost_system.update_playback(delta)

func _on_checkpoint_passed(cp_idx: int, vehicle: CharacterBody3D) -> void:
	if vehicle == player_vehicle:
		if cp_idx == next_checkpoint_idx:
			next_checkpoint_idx += 1
			_play_sfx("beep_high")

			# Check if crossed finish line
			if next_checkpoint_idx >= checkpoints.size():
				next_checkpoint_idx = 0
				current_lap += 1
				if current_lap > total_laps:
					_finish_race(true)

func _finish_race(victory: bool) -> void:
	if current_state != State.RACING:
		return

	if player_vehicle:
		player_vehicle.controls_enabled = false

	# Bank any pending combo
	combo_system._bank_combo()
	var final_stunt_score = combo_system.total_banked_score

	# Calculate Medal
	var gold_t = course_def.get("gold_time", 75.0) as float
	var silver_t = course_def.get("silver_time", 90.0) as float
	var bronze_t = course_def.get("bronze_time", 110.0) as float

	var medal = AeroConstants.Medal.BRONZE
	if race_timer <= gold_t * 0.90:
		medal = AeroConstants.Medal.PLATINUM
	elif race_timer <= gold_t:
		medal = AeroConstants.Medal.GOLD
	elif race_timer <= silver_t:
		medal = AeroConstants.Medal.SILVER

	var total_score = int(10000.0 / maxf(race_timer, 10.0) * 100.0) + final_stunt_score

	# Record to Persistence
	var save_res = AeroSaveAdapter.record_course_result(
		selected_course_id,
		race_timer,
		total_score,
		medal,
		600
	)

	_play_sfx("goal")
	set_state(State.RESULTS)

	results_screen.display_results({
		"course_name": course_def.get("name", "CIRCUIT"),
		"time_taken": race_timer,
		"stunt_score": final_stunt_score,
		"total_score": total_score,
		"credits_earned": save_res.get("credits_granted", 600),
		"medal": medal
	})

func _on_next_course() -> void:
	var all_courses = AeroCourseDatabase.get_all_courses()
	for i in range(all_courses.size()):
		if all_courses[i]["id"] == selected_course_id:
			var next_idx = (i + 1) % all_courses.size()
			selected_course_id = all_courses[next_idx]["id"]
			start_race(selected_course_id)
			return
	quick_play()

func _on_stunt_verified(stunt_id: int, points: int, label: String) -> void:
	combo_system.add_stunt(stunt_id, points, label)
	_play_sfx("pickup")

func _on_combo_updated(multiplier: int, pending: int, ratio: float, label: String) -> void:
	hud.update_combo(multiplier, pending, ratio, label)

func _on_combo_banked(banked: int, total: int) -> void:
	hud.show_stunt_toast("COMBO BANKED!", banked)
	_play_sfx("wave_clear")

func _on_combo_dropped() -> void:
	hud.hide_combo()
	hud.show_stunt_toast("COMBO LOST!", 0)

func _on_vehicle_selected_in_garage(v_id: String, col: Color) -> void:
	selected_vehicle_id = v_id
	selected_paint_color = col

func _on_return_to_hub() -> void:
	clean_up_session()
	var gm = GameConstants.get_autoload(self, "GameManager")
	if gm and gm.has_method("return_to_launcher"):
		gm.return_to_launcher()
	else:
		get_tree().change_scene_to_file("res://launcher/launcher.tscn")

func clean_up_session() -> void:
	for c in world_container.get_children():
		c.queue_free()
	for c in track_container.get_children():
		c.queue_free()
	for c in hazards_container.get_children():
		c.queue_free()
	for c in racers_container.get_children():
		c.queue_free()

	checkpoints.clear()
	rival_vehicles.clear()
	player_vehicle = null
	chase_camera = null
	active_world = null
	ghost_system.clear()

func _play_music(track_id: String) -> void:
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_music"):
		am.play_music(track_id)

func _play_course_music(env_type: int) -> void:
	match env_type:
		AeroConstants.EnvironmentType.MOUNTAIN_CANYON:
			_play_music("drift_storm")
		AeroConstants.EnvironmentType.TROPICAL_COASTAL:
			_play_music("chroma_rush")
		AeroConstants.EnvironmentType.SKY_CIRCUIT:
			_play_music("iron_crucible")
		_:
			_play_music("aero_rush")

func _play_sfx(sfx_name: String) -> void:
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sfx_name)
