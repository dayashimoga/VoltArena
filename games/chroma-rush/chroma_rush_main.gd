class_name ChromaRushMain
extends Node3D

## Root game coordinator for Chroma Rush: The Color Chase
## Integrates 3D Worlds, Vehicle Controller, AI Traffic/Rivals, Authoritative Color Swap Engine,
## Mission Director, Progression/Saves, HUD, Turntable Garage, Interactive Tutorial, and Pause/Results.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const ColorSwapEngine = preload("res://games/chroma-rush/core/color_swap_engine.gd")
const MissionDirector = preload("res://games/chroma-rush/core/mission_director.gd")
const MissionDatabase = preload("res://games/chroma-rush/content/mission_database.gd")
const ChromaSaveAdapter = preload("res://games/chroma-rush/persistence/chroma_save_adapter.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")
const VehicleCatalog = preload("res://games/chroma-rush/vehicles/vehicle_catalog.gd")
const TrafficAgent = preload("res://games/chroma-rush/ai/traffic_agent.gd")
const RivalAI = preload("res://games/chroma-rush/ai/rival_ai.gd")

const NeonCity = preload("res://games/chroma-rush/worlds/neon_city.gd")
const CoastalRush = preload("res://games/chroma-rush/worlds/coastal_rush.gd")
const PrismCanyon = preload("res://games/chroma-rush/worlds/prism_canyon.gd")
const SkyCircuit = preload("res://games/chroma-rush/worlds/sky_circuit.gd")
const CheckpointGate = preload("res://games/chroma-rush/worlds/checkpoint_gate.gd")

const ChromaHUD = preload("res://games/chroma-rush/ui/chroma_hud.gd")
const ChromaGarage = preload("res://games/chroma-rush/ui/chroma_garage.gd")
const ChromaTutorial = preload("res://games/chroma-rush/ui/chroma_tutorial.gd")
const PauseMenu = preload("res://shared/ui/pause_menu.gd")
const ResultsScreen = preload("res://shared/ui/results_screen.gd")

enum State {
	MENU,
	MODE_SELECT,
	WORLD_SELECT,
	GARAGE,
	TUTORIAL,
	PLAYING,
	PAUSED,
	RESULTS
}

var current_state: State = State.MENU
var current_mission_id: String = "hunt_neon_01"
var selected_vehicle_id: String = "apex_striker"
var selected_paint_color: Color = Color(0.15, 0.75, 1.0)
var selected_finish: String = "gloss"

# Subsystems (RefCounted)
var swap_engine: ColorSwapEngine
var mission_director: MissionDirector
var save_adapter: ChromaSaveAdapter

# Hierarchy references
var world_container: Node3D
var active_world: Node3D
var player_vehicle: ChromaVehicle
var traffic_agents: Array[TrafficAgent] = []
var rival_agents: Array[RivalAI] = []
var chase_camera: Camera3D
var camera_spring_arm: SpringArm3D

# UI Nodes
var hud: ChromaHUD
var garage: ChromaGarage
var tutorial_mgr: ChromaTutorial
var pause_menu: PauseMenu
var results_screen: ResultsScreen
var menu_root: Control

# Camera parameters
var cam_distance: float = 7.5
var cam_height: float = 3.2
var cam_lerp_speed: float = 7.0

func _ready() -> void:
	_init_subsystems()
	_init_environment()
	_init_camera()
	_init_ui()
	_connect_events()
	set_state(State.MENU)

func _init_subsystems() -> void:
	swap_engine = ColorSwapEngine.new()
	mission_director = MissionDirector.new(swap_engine)
	save_adapter = ChromaSaveAdapter.new()

	world_container = Node3D.new()
	world_container.name = "WorldContainer"
	add_child(world_container)

	# Load saved vehicle & paint
	var profile = save_adapter.get_profile_data()
	selected_vehicle_id = profile.get("selected_vehicle", ChromaConstants.VEHICLE_APEX)
	selected_finish = profile.get("selected_finish", "gloss")
	var paint_arr = profile.get("selected_paint", [0.15, 0.75, 1.0])
	if paint_arr is Array and paint_arr.size() >= 3:
		selected_paint_color = Color(paint_arr[0], paint_arr[1], paint_arr[2])

func _init_environment() -> void:
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.04, 0.05, 0.09)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.25, 0.30, 0.45)
	environment.ambient_light_energy = 1.3
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.15
	environment.glow_enabled = true
	environment.glow_intensity = 0.8
	environment.glow_bloom = 0.25
	env.environment = environment
	add_child(env)

	var dir_light = DirectionalLight3D.new()
	dir_light.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	dir_light.light_color = Color(0.95, 0.95, 1.0)
	dir_light.light_energy = 1.2
	dir_light.shadow_enabled = true
	add_child(dir_light)

func _init_camera() -> void:
	camera_spring_arm = SpringArm3D.new()
	camera_spring_arm.name = "CameraSpringArm"
	camera_spring_arm.spring_length = cam_distance
	camera_spring_arm.margin = 0.3
	add_child(camera_spring_arm)

	chase_camera = Camera3D.new()
	chase_camera.name = "ChaseCamera"
	chase_camera.current = true
	chase_camera.fov = 72.0
	camera_spring_arm.add_child(chase_camera)
	chase_camera.position = Vector3(0.0, 0.0, cam_distance)

func _init_ui() -> void:
	hud = ChromaHUD.new()
	hud.name = "ChromaHUD"
	hud.swap_requested.connect(_on_swap_requested)
	hud.target_cycle_requested.connect(_on_target_cycle_requested)
	add_child(hud)
	hud.visible = false

	garage = ChromaGarage.new()
	garage.name = "ChromaGarage"
	garage.save_adapter = save_adapter
	garage.vehicle_selected.connect(_on_garage_vehicle_selected)
	garage.garage_closed.connect(_on_garage_closed)
	add_child(garage)
	garage.visible = false

	tutorial_mgr = ChromaTutorial.new(null, swap_engine)
	tutorial_mgr.tutorial_completed.connect(_on_tutorial_completed)

	pause_menu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	pause_menu.resume_requested.connect(resume_game)
	pause_menu.restart_requested.connect(restart_mission)
	pause_menu.quit_to_launcher_requested.connect(return_to_menu)
	add_child(pause_menu)
	pause_menu.visible = false

	results_screen = ResultsScreen.new()
	results_screen.name = "ResultsScreen"
	results_screen.restart_pressed.connect(restart_mission)
	results_screen.next_stage_pressed.connect(next_mission)
	results_screen.launcher_pressed.connect(return_to_menu)
	add_child(results_screen)
	results_screen.visible = false

	_build_main_menu()

func _build_main_menu() -> void:
	menu_root = Control.new()
	menu_root.name = "MainMenu"
	menu_root.anchor_right = 1.0
	menu_root.anchor_bottom = 1.0
	add_child(menu_root)

	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.04, 0.06, 0.10, 0.92)
	menu_root.add_child(bg)

	var center_box = VBoxContainer.new()
	center_box.anchor_left = 0.5
	center_box.anchor_top = 0.5
	center_box.anchor_right = 0.5
	center_box.anchor_bottom = 0.5
	center_box.offset_left = -240
	center_box.offset_top = -250
	center_box.offset_right = 240
	center_box.offset_bottom = 250
	center_box.add_theme_constant_override("separation", 14)
	menu_root.add_child(center_box)

	var title = Label.new()
	title.text = "CHROMA RUSH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.modulate = Color(0.0, 1.0, 0.85)
	center_box.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "THE COLOR CHASE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.modulate = Color(0.65, 0.8, 1.0)
	center_box.add_child(subtitle)

	var sep = HSeparator.new()
	center_box.add_child(sep)

	var btn_quick = _create_menu_button("QUICK PLAY", func(): quick_play())
	center_box.add_child(btn_quick)

	var btn_continue = _create_menu_button("CONTINUE", func(): continue_game())
	center_box.add_child(btn_continue)

	var btn_modes = _create_menu_button("SELECT MISSION", func(): show_mission_select())
	center_box.add_child(btn_modes)

	var btn_garage = _create_menu_button("GARAGE & PAINTS", func(): open_garage())
	center_box.add_child(btn_garage)

	var btn_tutorial = _create_menu_button("TUTORIAL", func(): start_tutorial())
	center_box.add_child(btn_tutorial)

	var btn_quit = _create_menu_button("EXIT TO LAUNCHER", func(): quit_to_launcher())
	center_box.add_child(btn_quit)

func _create_menu_button(text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 44)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func():
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am and am.has_method("play_sfx"):
			am.play_sfx("ui_click")
		callback.call()
	)
	return btn

func _connect_events() -> void:
	if swap_engine:
		swap_engine.swap_committed.connect(_on_swap_committed)
		swap_engine.swap_rejected.connect(_on_swap_rejected)

	if mission_director:
		mission_director.objective_progress_updated.connect(_on_objective_progress_updated)
		mission_director.mission_completed.connect(_on_mission_director_completed)

func set_state(new_state: State) -> void:
	current_state = new_state
	if menu_root:
		menu_root.visible = (new_state == State.MENU or new_state == State.MODE_SELECT or new_state == State.WORLD_SELECT)
	if hud:
		hud.visible = (new_state == State.PLAYING)
	if garage:
		garage.visible = (new_state == State.GARAGE)
	if pause_menu:
		pause_menu.visible = (new_state == State.PAUSED)
	if results_screen:
		results_screen.visible = (new_state == State.RESULTS)

func _unhandled_input(event: InputEvent) -> void:
	if current_state == State.PLAYING:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			pause_game()
		elif event.is_action_pressed("swap"):
			_on_swap_requested()
		elif event.is_action_pressed("target_cycle"):
			_on_target_cycle_requested()

func _physics_process(delta: float) -> void:
	if current_state == State.PLAYING:
		if is_instance_valid(swap_engine):
			swap_engine.update(delta)
		if is_instance_valid(mission_director):
			mission_director.update(delta)
		for agent in traffic_agents:
			agent.update(delta)
		for rival in rival_agents:
			rival.update(delta)
		if is_instance_valid(player_vehicle):
			_update_camera(delta)
			_update_swap_eligibility()
			_update_hud_telemetry()

func _update_camera(delta: float) -> void:
	if not is_instance_valid(player_vehicle) or not is_instance_valid(camera_spring_arm):
		return
	var target_pos = player_vehicle.global_position + Vector3(0.0, cam_height, 0.0)
	camera_spring_arm.global_position = camera_spring_arm.global_position.lerp(target_pos, cam_lerp_speed * delta)
	
	var heading = -player_vehicle.global_transform.basis.z
	heading.y = 0.0
	if heading.length_squared() > 0.01:
		var target_rot_y = atan2(-heading.x, -heading.z)
		camera_spring_arm.rotation.y = lerp_angle(camera_spring_arm.rotation.y, target_rot_y, 4.0 * delta)
		camera_spring_arm.rotation.x = deg_to_rad(-12.0)

func _update_swap_eligibility() -> void:
	if not is_instance_valid(player_vehicle) or not is_instance_valid(swap_engine):
		return
	var nearest_info = swap_engine.find_nearest_eligible_target("player")
	var target_id = nearest_info.get("target_id", "")
	if not target_id.is_empty():
		var target_color = swap_engine.get_vehicle_color(target_id)
		var check = swap_engine.evaluate_eligibility("player", target_id, false)
		var progress = check.get("alignment_progress", 0.0)
		hud.set_alignment_progress(progress)
		hud.show_swap_prompt(nearest_info.get("eligible", false), target_color)
	else:
		hud.set_alignment_progress(0.0)
		hud.hide_swap_prompt()

func _update_hud_telemetry() -> void:
	if not is_instance_valid(player_vehicle) or not is_instance_valid(mission_director):
		return
	var speed_kmh = player_vehicle.get_speed_kmh()
	var time_left = mission_director.time_remaining
	var score = mission_director.score
	var combo = mission_director.combo_multiplier
	var req_color = mission_director.get_current_target_color()

	hud.update_hud(player_vehicle.current_color, req_color, speed_kmh, time_left, score, combo)

# --- Gameplay Flow Methods ---

func start_mission(mission_id: String) -> void:
	current_mission_id = mission_id
	var mission_data = MissionDatabase.get_mission_by_id(mission_id)
	if mission_data.is_empty():
		push_error("Mission not found: " + mission_id)
		return

	clean_up_session()

	# 1. Load World
	var world_id = mission_data.get("world_id", ChromaConstants.WORLD_NEON_CITY)
	_load_world(world_id)

	# 2. Spawn Player Vehicle
	_spawn_player_vehicle(mission_data)

	# 3. Spawn Ambient Traffic
	_spawn_traffic(mission_data)

	# 4. Spawn Rival AI if applicable
	if mission_data.get("rival_count", 0) > 0:
		_spawn_rivals(mission_data)

	# 5. Initialize Mission Director
	mission_director.start_mission(mission_data)

	# 6. Setup HUD
	hud.setup_mission(mission_data.get("title", "Mission"), mission_data.get("time_limit", 90.0))

	# 7. Start Engine Audio & BGM
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		if am.has_method("start_engine_sound"):
			am.start_engine_sound()
		if am.has_method("play_music"):
			am.play_music("chroma_rush")

	set_state(State.PLAYING)

func _load_world(world_id: String) -> void:
	match world_id:
		ChromaConstants.WORLD_COASTAL_RUSH:
			active_world = CoastalRush.new()
		ChromaConstants.WORLD_PRISM_CANYON:
			active_world = PrismCanyon.new()
		ChromaConstants.WORLD_SKY_CIRCUIT:
			active_world = SkyCircuit.new()
		_:
			active_world = NeonCity.new()

	active_world.name = "ActiveWorld"
	world_container.add_child(active_world)
	active_world._ready()

	# Connect checkpoint triggers
	for gate in active_world.checkpoints:
		gate.checkpoint_entered.connect(_on_checkpoint_gate_entered.bind(gate))

func _spawn_player_vehicle(mission_data: Dictionary) -> void:
	player_vehicle = ChromaVehicle.new()
	player_vehicle.name = "PlayerVehicle"
	player_vehicle.vehicle_id = selected_vehicle_id
	player_vehicle.vehicle_owner_id = "player"
	player_vehicle.is_player = true
	player_vehicle.paint_finish = selected_finish
	player_vehicle.custom_paint_color = selected_paint_color
	
	var start_col = mission_data.get("starting_color", ChromaConstants.ChromaColor.NONE)
	player_vehicle.initial_color = start_col
	player_vehicle.current_color = start_col

	var spawn_pos = Vector3(0.0, 1.0, 0.0)
	if active_world:
		spawn_pos = active_world.player_spawn_transform.origin
	player_vehicle.position = spawn_pos

	world_container.add_child(player_vehicle)
	player_vehicle._ready()
	swap_engine.register_vehicle("player", player_vehicle, start_col, false)

	if camera_spring_arm:
		camera_spring_arm.global_position = spawn_pos + Vector3(0.0, cam_height, 0.0)

func _spawn_traffic(mission_data: Dictionary) -> void:
	if not is_instance_valid(active_world) or active_world.waypoints.size() < 4:
		return

	var available_colors = mission_data.get("traffic_colors", [
		ChromaConstants.ChromaColor.CYAN,
		ChromaConstants.ChromaColor.MAGENTA,
		ChromaConstants.ChromaColor.SOLAR,
		ChromaConstants.ChromaColor.EMERALD
	])

	var traffic_count = 6
	for i in range(traffic_count):
		var veh = ChromaVehicle.new()
		var agent_id = "traffic_%d" % i
		veh.name = agent_id
		veh.vehicle_owner_id = agent_id
		veh.vehicle_id = ChromaConstants.VEHICLE_VORTEX
		veh.is_player = false
		var col = available_colors[i % available_colors.size()]
		veh.initial_color = col
		veh.current_color = col

		var wp_idx = (i * 3) % active_world.waypoints.size()
		veh.position = active_world.waypoints[wp_idx] + Vector3(randf_range(-1.0, 1.0), 1.0, randf_range(-1.0, 1.0))

		world_container.add_child(veh)
		veh._ready()

		var agent = TrafficAgent.new(veh, swap_engine, agent_id, col)
		agent.set_waypoints(active_world.waypoints, wp_idx)
		traffic_agents.append(agent)

func _spawn_rivals(mission_data: Dictionary) -> void:
	if not is_instance_valid(active_world) or active_world.waypoints.size() < 4:
		return
	var rival_count = mission_data.get("rival_count", 2)
	for i in range(rival_count):
		var veh = ChromaVehicle.new()
		var rival_id = "rival_%d" % i
		veh.name = rival_id
		veh.vehicle_owner_id = rival_id
		veh.vehicle_id = ChromaConstants.VEHICLE_VORTEX if i % 2 == 0 else ChromaConstants.VEHICLE_QUANTUM
		veh.is_player = false
		veh.initial_color = ChromaConstants.ChromaColor.NONE
		veh.current_color = ChromaConstants.ChromaColor.NONE

		var wp_idx = (i * 4 + 2) % active_world.waypoints.size()
		veh.position = active_world.waypoints[wp_idx] + Vector3(0.0, 1.0, 0.0)

		world_container.add_child(veh)
		veh._ready()

		var rival = RivalAI.new(veh, swap_engine, rival_id, ChromaConstants.ChromaColor.NONE, "skilled")
		rival_agents.append(rival)

func clean_up_session() -> void:
	if is_instance_valid(swap_engine):
		for id in swap_engine.get_registered_vehicle_ids():
			swap_engine.unregister_vehicle(id)

	if is_instance_valid(player_vehicle):
		player_vehicle.queue_free()
		player_vehicle = null

	for agent in traffic_agents:
		if is_instance_valid(agent.vehicle):
			agent.vehicle.queue_free()
	traffic_agents.clear()

	for rival in rival_agents:
		if is_instance_valid(rival.vehicle):
			rival.vehicle.queue_free()
	rival_agents.clear()

	if is_instance_valid(active_world):
		active_world.queue_free()
		active_world = null

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("stop_engine_sound"):
		am.stop_engine_sound()

# --- Swap & Input Handling ---

func _on_swap_requested() -> void:
	if not is_instance_valid(player_vehicle) or not is_instance_valid(swap_engine):
		return
	var nearest_info = swap_engine.find_nearest_eligible_target("player")
	var target_id = nearest_info.get("target_id", "")
	if not target_id.is_empty():
		swap_engine.request_swap("player", target_id)

func _on_target_cycle_requested() -> void:
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("ui_hover")

func _on_swap_committed(initiator_id: String, target_id: String, initiator_color: int, target_color: int) -> void:
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("chroma_swap", 1.0, 0.0)

	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus and bus.has_signal("chroma_swap_committed"):
		var node_a = swap_engine.get_vehicle_node(initiator_id)
		var node_b = swap_engine.get_vehicle_node(target_id)
		bus.chroma_swap_committed.emit(node_a, node_b, initiator_color, target_color)

	if initiator_id == "player" and is_instance_valid(player_vehicle):
		player_vehicle.current_color = initiator_color
	elif target_id == "player" and is_instance_valid(player_vehicle):
		player_vehicle.current_color = target_color

func _on_swap_rejected(initiator_id: String, _target_id: String, reason: String) -> void:
	if initiator_id == "player":
		hud.show_swap_rejected(reason)

func _on_checkpoint_gate_entered(body: Node3D, gate: Node3D) -> void:
	if body == player_vehicle and is_instance_valid(mission_director) and gate is CheckpointGate:
		var target_color = mission_director.get_current_target_color()
		if player_vehicle.current_color == target_color:
			var am = GameConstants.get_autoload(self, "AudioManager")
			if am and am.has_method("play_sfx"):
				am.play_sfx("chroma_gate_success", 1.0, 0.0)
		else:
			var am = GameConstants.get_autoload(self, "AudioManager")
			if am and am.has_method("play_sfx"):
				am.play_sfx("chroma_gate_fail", 1.0, 0.0)
		mission_director.handle_checkpoint_reached(player_vehicle, gate)

# --- Mission Director Callbacks ---

func _on_objective_progress_updated(cur_idx: int, total_objs: int, needed_color: int, _gate_id: String) -> void:
	hud.show_notification("Checkpoint Cleared! (%d/%d)" % [cur_idx, total_objs])
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus and bus.has_signal("chroma_checkpoint_cleared"):
		bus.chroma_checkpoint_cleared.emit(needed_color, cur_idx, total_objs)

func _on_mission_director_completed(victory: bool, results: Dictionary) -> void:
	if victory:
		_on_mission_completed(results)
	else:
		_on_mission_failed(results.get("failure_reason", "Mission Failed"))

func _on_mission_completed(stats: Dictionary) -> void:
	set_state(State.RESULTS)
	var earned = save_adapter.record_mission_completion(
		current_mission_id,
		true,
		stats.get("score", 0),
		stats.get("stars", 1),
		stats.get("time_elapsed", 0.0),
		stats.get("credits_earned", 500)
	)

	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus and bus.has_signal("chroma_mission_completed"):
		bus.chroma_mission_completed.emit(current_mission_id, stats)

	results_screen.display_results(true, {
		"Mission": MissionDatabase.get_mission_by_id(current_mission_id).get("title", "Victory"),
		"Score": "%d" % stats.get("score", 0),
		"Stars": "%d / 3" % stats.get("stars", 1),
		"Credits Earned": "+%d CR" % earned.get("credits_earned", 500),
		"Time Taken": "%.1fs" % stats.get("time_elapsed", 0.0)
	})

func _on_mission_failed(reason: String) -> void:
	set_state(State.RESULTS)
	results_screen.display_results(false, {
		"Mission": MissionDatabase.get_mission_by_id(current_mission_id).get("title", "Failed"),
		"Status": "OBJECTIVE FAILED",
		"Reason": reason
	})

# --- Navigation & Menu Actions ---

func quick_play() -> void:
	start_mission("hunt_neon_01")

func continue_game() -> void:
	var profile = save_adapter.get_profile_data()
	var resumable = profile.get("resumable_session", {})
	if not resumable.is_empty() and resumable.has("mission_id"):
		start_mission(resumable["mission_id"])
	else:
		start_mission("hunt_neon_01")

func show_mission_select() -> void:
	start_mission("hunt_neon_01")

func open_garage() -> void:
	set_state(State.GARAGE)
	garage.open_garage()

func _on_garage_vehicle_selected(v_id: String, color: Color, finish: String) -> void:
	selected_vehicle_id = v_id
	selected_paint_color = color
	selected_finish = finish

func _on_garage_closed() -> void:
	set_state(State.MENU)

func start_tutorial() -> void:
	set_state(State.TUTORIAL)
	tutorial_mgr.start_tutorial()

func _on_tutorial_completed() -> void:
	set_state(State.MENU)
	start_mission("hunt_neon_01")

func _on_tutorial_skipped() -> void:
	set_state(State.MENU)

func pause_game() -> void:
	if current_state == State.PLAYING:
		set_state(State.PAUSED)

func resume_game() -> void:
	if current_state == State.PAUSED:
		set_state(State.PLAYING)

func restart_mission() -> void:
	start_mission(current_mission_id)

func next_mission() -> void:
	var next_id = _get_next_mission_id(current_mission_id)
	start_mission(next_id)

func _get_next_mission_id(current_id: String) -> String:
	var all_m = MissionDatabase.get_all_missions()
	for i in range(all_m.size()):
		if all_m[i]["id"] == current_id and i + 1 < all_m.size():
			return all_m[i + 1]["id"]
	return "hunt_neon_01"

func return_to_menu() -> void:
	clean_up_session()
	set_state(State.MENU)

func quit_to_launcher() -> void:
	clean_up_session()
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus and bus.has_signal("return_to_launcher_requested"):
		bus.return_to_launcher_requested.emit()
	else:
		get_tree().change_scene_to_file("res://launcher/launcher.tscn")
