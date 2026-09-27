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
const ChromaFullMap = preload("res://games/chroma-rush/ui/chroma_full_map.gd")
const WorldSelectScreen = preload("res://games/chroma-rush/ui/world_select_screen.gd")
const PauseMenu = preload("res://shared/ui/pause_menu.gd")
const ResultsScreen = preload("res://shared/ui/results_screen.gd")

enum State {
	MENU,
	MODE_SELECT,
	WORLD_SELECT,
	GARAGE,
	TUTORIAL,
	LOADING,
	BRIEFING,
	COUNTDOWN,
	PLAYING,
	PAUSED,
	RESULTS
}

var current_state: State = State.MENU
var current_mission_id: String = "hunt_neon_01"
var selected_vehicle_id: String = "apex_striker"
var selected_paint_color: Color = Color(0.15, 0.75, 1.0)
var selected_finish: String = "gloss"
var is_practice_mode: bool = false

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
var target_beacon: Node3D
var main_env_node: WorldEnvironment
var main_light_node: DirectionalLight3D
var menu_environment: Environment = null
var selected_target_id: String = ""

# UI Nodes
var hud: ChromaHUD
var garage: ChromaGarage
var tutorial_mgr: ChromaTutorial
var pause_menu: PauseMenu
var results_screen: ResultsScreen
var menu_root: Control
var full_map: ChromaFullMap
var world_select_screen: WorldSelectScreen
var countdown_container: Control
var countdown_label: Label
var countdown_timer: float = 0.0

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
	main_env_node = WorldEnvironment.new()
	main_env_node.name = "MainMenuEnvironment"
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.04, 0.05, 0.09)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.20, 0.25, 0.35)
	environment.ambient_light_energy = 1.0
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.4
	environment.glow_bloom = 0.05
	menu_environment = environment
	main_env_node.environment = environment
	add_child(main_env_node)

	main_light_node = DirectionalLight3D.new()
	main_light_node.name = "MainMenuLight"
	main_light_node.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	main_light_node.light_color = Color(0.95, 0.95, 1.0)
	main_light_node.light_energy = 1.0
	main_light_node.shadow_enabled = true
	add_child(main_light_node)

	_init_target_beacon()

func _init_target_beacon() -> void:
	target_beacon = Node3D.new()
	target_beacon.name = "TargetBeacon3D"

	var mesh_inst = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(2.4, 3.6, 2.4)
	mesh_inst.mesh = prism
	mesh_inst.rotation_degrees = Vector3(180, 0, 0)
	mesh_inst.position = Vector3(0, 5.5, 0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.1)
	mat.emission_energy_multiplier = 2.5
	mesh_inst.material_override = mat
	target_beacon.add_child(mesh_inst)

	var omni = OmniLight3D.new()
	omni.light_color = Color(1.0, 0.85, 0.1)
	omni.light_energy = 3.0
	omni.omni_range = 18.0
	omni.position = Vector3(0, 5.0, 0)
	target_beacon.add_child(omni)

	add_child(target_beacon)
	target_beacon.visible = false

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
	hud.map_expand_requested.connect(_on_map_expand_requested)
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

	full_map = ChromaFullMap.new()
	full_map.name = "ChromaFullMap"
	full_map.map_closed.connect(_on_full_map_closed)
	add_child(full_map)
	full_map.visible = false

	world_select_screen = WorldSelectScreen.new()
	world_select_screen.name = "WorldSelectScreen"
	world_select_screen.world_mode_selected.connect(_on_world_mode_selected)
	world_select_screen.back_pressed.connect(func(): set_state(State.MENU))
	add_child(world_select_screen)
	world_select_screen.visible = false

	# Countdown Display Container
	countdown_container = Control.new()
	countdown_container.name = "CountdownContainer"
	countdown_container.anchor_right = 1.0
	countdown_container.anchor_bottom = 1.0
	countdown_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(countdown_container)
	countdown_container.visible = false

	countdown_label = Label.new()
	countdown_label.anchor_left = 0.5
	countdown_label.anchor_top = 0.35
	countdown_label.anchor_right = 0.5
	countdown_label.anchor_bottom = 0.35
	countdown_label.offset_left = -200
	countdown_label.offset_top = -60
	countdown_label.offset_right = 200
	countdown_label.offset_bottom = 60
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 76)
	countdown_label.modulate = Color(1.0, 0.9, 0.1)
	countdown_container.add_child(countdown_label)

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

	var btn_modes = _create_menu_button("SELECT WORLD & MODE", func(): show_world_select())
	center_box.add_child(btn_modes)

	var btn_practice = _create_menu_button("FREE DRIVE (PRACTICE)", func(): start_practice_mode())
	center_box.add_child(btn_practice)

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
		menu_root.visible = (new_state == State.MENU or new_state == State.MODE_SELECT)
	if world_select_screen:
		world_select_screen.visible = (new_state == State.WORLD_SELECT)
	if hud:
		hud.visible = (new_state == State.PLAYING or new_state == State.COUNTDOWN)
	if countdown_container:
		countdown_container.visible = (new_state == State.COUNTDOWN)
	if garage:
		garage.visible = (new_state == State.GARAGE)
	if pause_menu:
		pause_menu.visible = (new_state == State.PAUSED)
	if results_screen:
		results_screen.visible = (new_state == State.RESULTS)
	if full_map and new_state != State.PLAYING:
		full_map.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if is_instance_valid(full_map) and full_map.visible:
			full_map.close_map()
		elif current_state == State.PLAYING:
			pause_game()
		elif current_state == State.PAUSED:
			resume_game()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_M:
		_toggle_full_map()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		if is_instance_valid(hud):
			hud.toggle_diagnostics()
	elif current_state == State.PLAYING:
		if event.is_action_pressed("swap") or (event is InputEventKey and event.pressed and (event.keycode == KEY_E or event.keycode == KEY_SPACE)):
			_on_swap_requested()
		elif event.is_action_pressed("target_cycle") or (event is InputEventKey and event.pressed and event.keycode == KEY_TAB):
			_on_target_cycle_requested()

func _physics_process(delta: float) -> void:
	if current_state == State.COUNTDOWN:
		countdown_timer -= delta
		if countdown_timer > 2.0:
			countdown_label.text = "3"
			countdown_label.modulate = Color(1.0, 0.3, 0.3)
		elif countdown_timer > 1.0:
			countdown_label.text = "2"
			countdown_label.modulate = Color(1.0, 0.8, 0.1)
		elif countdown_timer > 0.0:
			countdown_label.text = "1"
			countdown_label.modulate = Color(0.2, 0.8, 1.0)
		else:
			countdown_label.text = "GO!"
			countdown_label.modulate = Color(0.1, 1.0, 0.4)
			var am = GameConstants.get_autoload(self, "AudioManager")
			if am and am.has_method("play_sfx"):
				am.play_sfx("race_start", 1.0, 0.0)
			set_state(State.PLAYING)
			if is_instance_valid(player_vehicle):
				player_vehicle.controls_enabled = true

	elif current_state == State.PLAYING:
		if is_instance_valid(swap_engine):
			swap_engine.update(delta)
		if is_instance_valid(mission_director) and not is_practice_mode:
			mission_director.update(delta)
		for agent in traffic_agents:
			agent.update(delta)
		for rival in rival_agents:
			rival.update(delta)
		if is_instance_valid(player_vehicle):
			_update_camera(delta)
			_update_swap_eligibility()
			_update_hud_telemetry(delta)

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
	if not is_instance_valid(player_vehicle) or not is_instance_valid(swap_engine) or not is_instance_valid(hud):
		return

	var target_id = selected_target_id
	if target_id.is_empty() or not swap_engine.has_vehicle(target_id):
		# Objective-guided target selection: prioritize vehicle with required mission color
		var req_col = ChromaConstants.ChromaColor.NONE
		if is_instance_valid(mission_director):
			req_col = mission_director.get_current_target_color()
		if req_col != ChromaConstants.ChromaColor.NONE and player_vehicle.current_color != req_col:
			var match_id = swap_engine.find_target_with_color("player", req_col)
			if not match_id.is_empty():
				var node_tgt = swap_engine.get_vehicle_node(match_id)
				if is_instance_valid(node_tgt):
					var dist = player_vehicle.global_position.distance_to(node_tgt.global_position)
					if dist < 45.0:
						target_id = match_id

		if target_id.is_empty():
			var nearest_info = swap_engine.find_nearest_eligible_target("player")
			target_id = nearest_info.get("target_id", "")

	if not target_id.is_empty() and swap_engine.has_vehicle(target_id):
		var target_color = swap_engine.get_vehicle_color(target_id)
		var check = swap_engine.evaluate_eligibility("player", target_id, false)
		var progress = check.get("alignment_progress", 0.0)
		hud.set_alignment_progress(progress)
		hud.show_swap_prompt(check.get("eligible", false), target_color)
	else:
		hud.set_alignment_progress(0.0)
		hud.hide_swap_prompt()

func _update_hud_telemetry(delta: float = 0.016) -> void:
	if not is_instance_valid(player_vehicle) or not is_instance_valid(mission_director):
		return
	var speed_kmh = player_vehicle.get_speed_kmh()
	var time_left = mission_director.time_remaining if not is_practice_mode else 9999.0
	var score = mission_director.score if not is_practice_mode else 0
	var combo = mission_director.combo_multiplier if not is_practice_mode else 1.0
	var req_color = mission_director.get_current_target_color()

	hud.update_hud(player_vehicle.current_color, req_color, speed_kmh, time_left, score, combo)

	# Minimap & FullMap telemetry
	var p_pos = player_vehicle.global_position
	var p_rot_y = player_vehicle.global_rotation.y

	var markers: Array[Dictionary] = []
	for agent in traffic_agents:
		if is_instance_valid(agent.vehicle):
			markers.append({
				"pos": agent.vehicle.global_position,
				"color": agent.vehicle.current_color,
				"is_rival": false
			})
	for rival in rival_agents:
		if is_instance_valid(rival.vehicle):
			markers.append({
				"pos": rival.vehicle.global_position,
				"color": rival.vehicle.current_color,
				"is_rival": true
			})

	var target_gate_pos = Vector3.ZERO
	var target_gate_color = ChromaConstants.ChromaColor.NONE
	var has_target_gate = false

	if not is_practice_mode:
		var gate_id = mission_director.get_current_target_gate_id()
		target_gate_color = req_color
		if is_instance_valid(active_world):
			for gate in active_world.checkpoints:
				if gate.gate_id == gate_id or gate_id.is_empty():
					target_gate_pos = gate.global_position
					has_target_gate = true
					break

	if is_instance_valid(hud) and is_instance_valid(hud.mini_map):
		hud.mini_map.update_radar(p_pos, p_rot_y, markers, target_gate_pos, target_gate_color, has_target_gate)

	if is_instance_valid(full_map) and full_map.visible:
		full_map.update_full_map_telemetry(p_pos, p_rot_y, markers, target_gate_pos, target_gate_color, has_target_gate)

	if is_instance_valid(target_beacon):
		if has_target_gate:
			target_beacon.visible = true
			target_beacon.global_position = target_gate_pos
			target_beacon.rotate_y(2.5 * delta)
		else:
			target_beacon.visible = false

	# Real-time diagnostics feed
	if is_instance_valid(hud) and hud.has_method("update_diagnostics"):
		var wp_idx = 0
		var tot_wps = 0
		if is_instance_valid(active_world):
			wp_idx = active_world.get_nearest_waypoint_index(p_pos)
			tot_wps = active_world.get_total_waypoints()
		var tgt_color_name = "NONE"
		var tgt_dist = 0.0
		var align_prog = 0.0
		if not selected_target_id.is_empty() and is_instance_valid(swap_engine) and swap_engine.has_vehicle(selected_target_id):
			tgt_color_name = ChromaConstants.get_color_name(swap_engine.get_vehicle_color(selected_target_id))
			var node_t = swap_engine.get_vehicle_node(selected_target_id)
			if is_instance_valid(node_t):
				tgt_dist = p_pos.distance_to(node_t.global_position)
			align_prog = swap_engine.get_alignment_progress("player", selected_target_id)

		hud.update_diagnostics({
			"speed_kph": speed_kmh,
			"vel": player_vehicle.velocity,
			"grounded": player_vehicle.is_grounded,
			"normal": player_vehicle.ground_normal,
			"contacts": player_vehicle.get_slide_collision_count() if player_vehicle.is_inside_tree() else 0,
			"nearest_wp": wp_idx,
			"total_wps": tot_wps,
			"target_id": selected_target_id if not selected_target_id.is_empty() else "AUTO",
			"target_color": tgt_color_name,
			"target_dist": tgt_dist,
			"align_pct": align_prog,
			"player_color": ChromaConstants.get_color_name(player_vehicle.current_color),
			"mission_id": current_mission_id,
			"mission_phase": State.keys()[current_state]
		})

# --- Gameplay Flow Methods ---

func start_mission(mission_id: String) -> void:
	current_mission_id = mission_id
	is_practice_mode = false
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
	if is_instance_valid(hud):
		hud.setup_mission(mission_data.get("title", "Mission"), mission_data.get("time_limit", 90.0))
		if is_instance_valid(active_world) and is_instance_valid(hud.mini_map):
			hud.mini_map.set_world_data(active_world.waypoints)

	# 7. Start Engine Audio & BGM
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		if am.has_method("start_engine_sound"):
			am.start_engine_sound()
		if am.has_method("play_music"):
			am.play_music("chroma_rush")

	# Start with Countdown in visual mode, or directly in PLAYING in headless test mode
	if DisplayServer.get_name() == "headless":
		if is_instance_valid(player_vehicle):
			player_vehicle.controls_enabled = true
		set_state(State.PLAYING)
	else:
		countdown_timer = 3.2
		if is_instance_valid(player_vehicle):
			player_vehicle.controls_enabled = false
		set_state(State.COUNTDOWN)

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

	# Deactivate main menu environment & light so active_world's lighting has full authority
	if is_instance_valid(main_env_node):
		main_env_node.environment = null
	if is_instance_valid(main_light_node):
		main_light_node.visible = false

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

	var spawn_xf = Transform3D.IDENTITY
	if active_world:
		spawn_xf = active_world.player_spawn_transform
	player_vehicle.global_transform = spawn_xf

	world_container.add_child(player_vehicle)
	swap_engine.register_vehicle("player", player_vehicle, start_col, false)

	if camera_spring_arm:
		camera_spring_arm.global_position = spawn_xf.origin + Vector3(0.0, cam_height, 0.0)

func _spawn_traffic(mission_data: Dictionary) -> void:
	if not is_instance_valid(active_world) or active_world.waypoints.size() < 4:
		return

	var available_colors = mission_data.get("traffic_colors", [
		ChromaConstants.ChromaColor.CYAN,
		ChromaConstants.ChromaColor.MAGENTA,
		ChromaConstants.ChromaColor.SOLAR,
		ChromaConstants.ChromaColor.EMERALD
	])

	var wps = active_world.waypoints
	var traffic_count = mini(6, wps.size() - 2)
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

		# Stagger starting at waypoint 2 onwards, so waypoint 0 is never occupied by traffic
		var wp_idx = (2 + i * 2) % wps.size()
		var p_cur = wps[wp_idx]
		var p_next = wps[(wp_idx + 1) % wps.size()]
		var fwd = (p_next - p_cur).normalized()
		var right = Vector3.UP.cross(fwd).normalized()
		var lane_dist = 3.2 if (i % 2 == 0) else -3.2
		var lane_offset = right * lane_dist
		var spawn_pt = p_cur + lane_offset + Vector3(0, 0.4, 0)
		var basis = Basis(right, Vector3.UP, fwd)
		veh.global_transform = Transform3D(basis, spawn_pt)

		world_container.add_child(veh)

		var agent = TrafficAgent.new(veh, swap_engine, agent_id, col)
		agent.driver.desired_lane_offset = lane_dist
		agent.set_waypoints(wps, wp_idx)
		traffic_agents.append(agent)

func _spawn_rivals(mission_data: Dictionary) -> void:
	if not is_instance_valid(active_world) or active_world.waypoints.size() < 4:
		return
	var rival_count = mission_data.get("rival_count", 2)
	var wps = active_world.waypoints
	for i in range(rival_count):
		var veh = ChromaVehicle.new()
		var rival_id = "rival_%d" % i
		veh.name = rival_id
		veh.vehicle_owner_id = rival_id
		veh.vehicle_id = ChromaConstants.VEHICLE_VORTEX if i % 2 == 0 else ChromaConstants.VEHICLE_QUANTUM
		veh.is_player = false
		veh.initial_color = ChromaConstants.ChromaColor.NONE
		veh.current_color = ChromaConstants.ChromaColor.NONE

		# Stagger rivals at wp 3, 7...
		var wp_idx = (3 + i * 4) % wps.size()
		var p_cur = wps[wp_idx]
		var p_next = wps[(wp_idx + 1) % wps.size()]
		var fwd = (p_next - p_cur).normalized()
		var right = Vector3.UP.cross(fwd).normalized()
		var lane_offset = right * (-3.0 if (i % 2 == 0) else 3.0)
		var spawn_pt = p_cur + lane_offset + Vector3(0, 0.4, 0)
		var basis = Basis(right, Vector3.UP, fwd)
		veh.global_transform = Transform3D(basis, spawn_pt)

		world_container.add_child(veh)

		var rival = RivalAI.new(veh, swap_engine, rival_id, ChromaConstants.ChromaColor.NONE, "skilled")
		rival_agents.append(rival)

func clean_up_session() -> void:
	selected_target_id = ""

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

	# Restore main menu environment & light for garage/menu screens
	if is_instance_valid(main_env_node):
		main_env_node.environment = menu_environment
	if is_instance_valid(main_light_node):
		main_light_node.visible = true

	if is_instance_valid(target_beacon):
		target_beacon.visible = false

	if is_instance_valid(full_map):
		full_map.visible = false

	if is_instance_valid(countdown_container):
		countdown_container.visible = false

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("stop_engine_sound"):
		am.stop_engine_sound()

# --- Swap & Input Handling ---

func _on_swap_requested() -> void:
	if not is_instance_valid(player_vehicle) or not is_instance_valid(swap_engine):
		return
	var target_id = selected_target_id
	if target_id.is_empty() or not swap_engine.has_vehicle(target_id):
		var nearest_info = swap_engine.find_nearest_eligible_target("player")
		target_id = nearest_info.get("target_id", "")
	if not target_id.is_empty():
		swap_engine.request_swap("player", target_id)

func _on_target_cycle_requested() -> void:
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("ui_hover")

	if not is_instance_valid(swap_engine) or not is_instance_valid(player_vehicle):
		return

	var all_ids = swap_engine.get_registered_vehicle_ids()
	var candidates: Array[String] = []
	for id in all_ids:
		if id != "player":
			candidates.append(id)

	if candidates.is_empty():
		return

	var cur_idx = candidates.find(selected_target_id)
	var next_idx = (cur_idx + 1) % candidates.size()
	selected_target_id = candidates[next_idx]

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
		player_vehicle.set_color(initiator_color)
	elif target_id == "player" and is_instance_valid(player_vehicle):
		player_vehicle.set_color(target_color)

	var node_a = swap_engine.get_vehicle_node(initiator_id)
	var node_b = swap_engine.get_vehicle_node(target_id)
	if node_a and is_instance_valid(node_a) and node_a is ChromaVehicle and node_a != player_vehicle:
		node_a.set_color(initiator_color)
	if node_b and is_instance_valid(node_b) and node_b is ChromaVehicle and node_b != player_vehicle:
		node_b.set_color(target_color)

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

	if is_instance_valid(results_screen):
		results_screen.display_results(true, {
			"Mission": MissionDatabase.get_mission_by_id(current_mission_id).get("title", "Victory"),
			"Score": "%d" % stats.get("score", 0),
			"Stars": "%d / 3" % stats.get("stars", 1),
			"Credits Earned": "+%d CR" % earned.get("credits_earned", 500),
			"Time Taken": "%.1fs" % stats.get("time_elapsed", 0.0)
		})

func _on_mission_failed(reason: String) -> void:
	set_state(State.RESULTS)
	var friendly_reason = reason
	if reason == "TIME_EXPIRED":
		friendly_reason = "Time Ran Out! Follow the route guidance ribbon and use boost (SPACE / Shift) to reach your target color faster."
	elif reason == "WRONG_COLOR":
		friendly_reason = "Mismatched Color! Match your vehicle paint to the checkpoint gate requirement before driving through."
	elif reason == "OFF_COURSE":
		friendly_reason = "Off course! Use road recovery to return safely to the asphalt."

	if is_instance_valid(results_screen):
		results_screen.display_results(false, {
			"Mission": MissionDatabase.get_mission_by_id(current_mission_id).get("title", "Failed"),
			"Status": "MISSION INCOMPLETE",
			"Reason": friendly_reason
		})

# --- Navigation & Menu Actions ---

func _toggle_full_map() -> void:
	if not is_instance_valid(full_map):
		return
	if full_map.visible:
		full_map.close_map()
	elif (current_state == State.PLAYING or current_state == State.COUNTDOWN) and is_instance_valid(active_world):
		var gates_data: Array[Dictionary] = []
		for gate in active_world.checkpoints:
			gates_data.append({
				"id": gate.gate_id,
				"pos": gate.global_position,
				"color": gate.target_color,
				"cleared": gate.is_cleared
			})
		full_map.open_map(active_world.world_name, active_world.waypoints, gates_data)

func _on_map_expand_requested() -> void:
	_toggle_full_map()

func _on_full_map_closed() -> void:
	pass

func show_world_select() -> void:
	set_state(State.WORLD_SELECT)

func _on_world_mode_selected(world_id: String, mode_id: String) -> void:
	if mode_id == "free_drive":
		start_practice_mode(world_id)
		return

	var m_id = "hunt_neon_01"
	match world_id:
		ChromaConstants.WORLD_COASTAL_RUSH:
			m_id = "hunt_coastal_01" if mode_id == "hunt" else "sprint_coastal_01"
		ChromaConstants.WORLD_PRISM_CANYON:
			m_id = "hunt_canyon_01" if mode_id == "hunt" else "puzzle_canyon_01"
		ChromaConstants.WORLD_SKY_CIRCUIT:
			m_id = "sprint_sky_01" if mode_id == "sprint" else "hunt_sky_01"
		_:
			m_id = "hunt_neon_01" if mode_id == "hunt" else "sprint_neon_01"
	start_mission(m_id)

func start_practice_mode(w_id: String = ChromaConstants.WORLD_NEON_CITY) -> void:
	is_practice_mode = true
	var mission_data = {
		"id": "free_drive",
		"title": "Free Drive (Practice)",
		"world_id": w_id,
		"time_limit": 9999.0,
		"starting_color": ChromaConstants.ChromaColor.CYAN,
		"traffic_colors": [
			ChromaConstants.ChromaColor.MAGENTA,
			ChromaConstants.ChromaColor.SOLAR,
			ChromaConstants.ChromaColor.EMERALD,
			ChromaConstants.ChromaColor.COBALT
		],
		"rival_count": 1,
		"checkpoints": []
	}
	clean_up_session()
	_load_world(w_id)
	_spawn_player_vehicle(mission_data)
	_spawn_traffic(mission_data)
	_spawn_rivals(mission_data)
	mission_director.start_mission(mission_data)
	if is_instance_valid(hud):
		hud.setup_mission("Free Drive (Practice)", 9999.0)
		if is_instance_valid(active_world) and is_instance_valid(hud.mini_map):
			hud.mini_map.set_world_data(active_world.waypoints)
	if is_instance_valid(player_vehicle):
		player_vehicle.controls_enabled = true
	set_state(State.PLAYING)

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
	show_world_select()

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
	if not tutorial_mgr:
		if not swap_engine:
			_init_subsystems()
		tutorial_mgr = ChromaTutorial.new(null, swap_engine)
		tutorial_mgr.tutorial_completed.connect(_on_tutorial_completed)
	set_state(State.TUTORIAL)
	tutorial_mgr.start_tutorial()

func _on_tutorial_completed() -> void:
	set_state(State.MENU)
	start_mission("hunt_neon_01")

func _on_tutorial_skipped() -> void:
	set_state(State.MENU)

func pause_game() -> void:
	if current_state == State.PLAYING or current_state == State.COUNTDOWN:
		set_state(State.PAUSED)

func resume_game() -> void:
	if current_state == State.PAUSED:
		set_state(State.PLAYING)

func restart_mission() -> void:
	if is_practice_mode:
		start_practice_mode()
	else:
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
