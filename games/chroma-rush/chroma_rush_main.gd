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
var camera_override: bool = false
var cam_smoothed_target_pos: Vector3 = Vector3.ZERO
var cam_smoothed_forward: Vector3 = Vector3.FORWARD
var cam_smoothed_up: Vector3 = Vector3.UP
var cam_is_initialized: bool = false
var cam_trauma: float = 0.0

# Filtered Camera Pipeline & Telemetry
var cam_filtered_speed: float = 0.0
var cam_prev_raw_speed: float = 0.0
var cam_filtered_accel: float = 0.0
var cam_last_stable_speed: float = 0.0
var camera_telemetry: Dictionary = {}
const CAM_SPEED_DEADZONE: float = 1.8 # km/h dead-zone to reject micro-jitter
const CAM_BASE_FOV: float = 72.0
const CAM_MAX_FOV: float = 80.0
const CAM_MAX_FOV_RATE: float = 12.0 # deg/sec maximum rate limit

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
	target_beacon.name = "BeaconTargetReticle"

	# Sleek Holographic Diamond Target Beacon with Orbiting Guidance Ring
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.1, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.1)
	mat.emission_energy_multiplier = 2.2

	var top_cone = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 0.05
	t_cyl.bottom_radius = 0.70
	t_cyl.height = 1.3
	top_cone.mesh = t_cyl
	top_cone.material_override = mat
	top_cone.position = Vector3(0, 4.15, 0)
	target_beacon.add_child(top_cone)

	var bottom_cone = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.70
	b_cyl.bottom_radius = 0.05
	b_cyl.height = 0.9
	bottom_cone.mesh = b_cyl
	bottom_cone.material_override = mat
	bottom_cone.position = Vector3(0, 3.05, 0)
	target_beacon.add_child(bottom_cone)

	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.15
	torus.outer_radius = 1.30
	ring.mesh = torus
	ring.material_override = mat
	ring.position = Vector3(0, 3.5, 0)
	target_beacon.add_child(ring)

	var omni = OmniLight3D.new()
	omni.light_color = Color(1.0, 0.85, 0.1)
	omni.light_energy = 2.0
	omni.omni_range = 10.0
	omni.position = Vector3(0, 3.5, 0)
	target_beacon.add_child(omni)

	add_child(target_beacon)
	target_beacon.visible = false

func _init_camera() -> void:
	camera_spring_arm = SpringArm3D.new()
	camera_spring_arm.name = "CameraSpringArm"
	camera_spring_arm.spring_length = cam_distance
	add_child(camera_spring_arm)

	chase_camera = Camera3D.new()
	chase_camera.name = "ChaseCamera"
	chase_camera.current = true
	chase_camera.fov = 72.0
	add_child(chase_camera)

func _init_ui() -> void:
	hud = ChromaHUD.new()
	hud.name = "ChromaHUD"
	hud.swap_requested.connect(_on_swap_requested)
	hud.target_cycle_requested.connect(_on_target_cycle_requested)
	hud.map_expand_requested.connect(_on_map_expand_requested)
	hud.reset_to_road_requested.connect(_on_reset_to_road_requested)
	hud.briefing_dismissed.connect(_on_briefing_dismissed)
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
	pause_menu.restart_checkpoint_requested.connect(_on_reset_to_road_requested)
	pause_menu.restart_event_requested.connect(restart_mission)
	pause_menu.main_menu_requested.connect(return_to_menu)
	pause_menu.quit_to_launcher_requested.connect(return_to_menu)
	pause_menu.quit_to_desktop_requested.connect(func():
		var tree = get_tree()
		if tree and OS.get_name() != "Web":
			tree.quit()
	)
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
		hud.visible = (new_state == State.PLAYING or new_state == State.COUNTDOWN or new_state == State.BRIEFING)
	if countdown_container:
		countdown_container.visible = (new_state == State.COUNTDOWN)
	if garage:
		garage.visible = (new_state == State.GARAGE)
	if pause_menu:
		if new_state == State.PAUSED:
			pause_menu.show_pause()
		else:
			pause_menu.hide_pause()
	if results_screen:
		results_screen.visible = (new_state == State.RESULTS)
	if full_map and new_state != State.PLAYING:
		full_map.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if current_state == State.BRIEFING:
		if event.is_pressed() and not (event is InputEventMouseMotion):
			_on_briefing_dismissed()
			return

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
		elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
			_on_reset_to_road_requested()

func _process(delta: float) -> void:
	if current_state == State.PLAYING or current_state == State.COUNTDOWN:
		if is_instance_valid(player_vehicle):
			_update_camera(delta)
			_update_hud_telemetry(delta)
	elif current_state == State.BRIEFING:
		if not camera_override and is_instance_valid(player_vehicle) and is_instance_valid(chase_camera):
			var car_pos = player_vehicle.global_position if player_vehicle.is_inside_tree() else player_vehicle.position
			var orbit_angle = Time.get_ticks_msec() * 0.0004
			var orbit_offset = Vector3(sin(orbit_angle) * 11.0, 3.8, cos(orbit_angle) * 11.0)
			chase_camera.global_position = car_pos + orbit_offset
			chase_camera.look_at(car_pos + Vector3(0.0, 1.2, 0.0), Vector3.UP)

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
			_update_swap_eligibility()

func _update_camera(delta: float) -> void:
	if camera_override:
		return
	if not is_instance_valid(player_vehicle) or not is_instance_valid(chase_camera):
		return
	if not chase_camera.current:
		chase_camera.make_current()

	var car_pos = player_vehicle.global_position if player_vehicle.is_inside_tree() else player_vehicle.position
	var car_basis = player_vehicle.global_transform.basis if player_vehicle.is_inside_tree() else player_vehicle.transform.basis
	var raw_fwd = -car_basis.z.normalized()
	var raw_up = car_basis.y.normalized()

	if not cam_is_initialized or chase_camera.global_position.distance_squared_to(car_pos) > 250.0:
		cam_smoothed_target_pos = car_pos
		cam_smoothed_forward = raw_fwd
		cam_smoothed_up = raw_up
		var init_pos = car_pos - raw_fwd * cam_distance + Vector3(0.0, cam_height, 0.0)
		chase_camera.global_position = init_pos
		if chase_camera.is_inside_tree():
			chase_camera.look_at(car_pos + raw_fwd * 6.0 + Vector3(0.0, 1.2, 0.0), Vector3.UP)
		cam_is_initialized = true
		camera_telemetry = {
			"raw_speed": 0.0,
			"filtered_speed": 0.0,
			"raw_acceleration": 0.0,
			"filtered_acceleration": 0.0,
			"desired_fov": CAM_BASE_FOV,
			"actual_fov": chase_camera.fov,
			"camera_distance": cam_distance,
			"camera_transform": chase_camera.global_transform
		}
		return

	# 1. Target Tracking with Exponential Smoothing (Frame-Rate Independent)
	var alpha_pos = 1.0 - exp(-14.0 * delta)
	var alpha_rot = 1.0 - exp(-9.0 * delta)
	cam_smoothed_target_pos = cam_smoothed_target_pos.lerp(car_pos, alpha_pos)

	# Filter out high-frequency vertical pitching - decouple completely from chassis pitch chatter
	var planar_fwd = raw_fwd
	planar_fwd.y = 0.0
	if planar_fwd.length_squared() > 0.001:
		planar_fwd = planar_fwd.normalized()
	else:
		planar_fwd = raw_fwd

	cam_smoothed_forward = cam_smoothed_forward.slerp(planar_fwd, alpha_rot).normalized()
	cam_smoothed_up = cam_smoothed_up.slerp(raw_up, alpha_rot).normalized()

	# 2. Speed & Acceleration Pipeline
	var raw_speed = player_vehicle.get_speed_kmh()
	var raw_accel = (raw_speed - cam_prev_raw_speed) / maxf(delta, 0.0001)
	cam_prev_raw_speed = raw_speed

	# Low-pass filter for speed
	var speed_filter_alpha = 1.0 - exp(-12.0 * delta)
	cam_filtered_speed = lerpf(cam_filtered_speed, raw_speed, speed_filter_alpha)

	# Acceleration filter
	var accel_filter_alpha = 1.0 - exp(-12.0 * delta)
	cam_filtered_accel = lerpf(cam_filtered_accel, raw_accel, accel_filter_alpha)

	# Continuous smooth FOV with zero discrete stair-stepping
	cam_last_stable_speed = cam_filtered_speed
	var spd_ratio = clampf(cam_filtered_speed / 140.0, 0.0, 1.0)
	var desired_fov = lerpf(CAM_BASE_FOV, 76.5, spd_ratio)

	# Rate-limit FOV delta to prevent sudden zoom pumping
	var max_fov_step = CAM_MAX_FOV_RATE * delta
	var target_fov = clampf(desired_fov, chase_camera.fov - max_fov_step, chase_camera.fov + max_fov_step)
	chase_camera.fov = target_fov

	# 4. Stable Camera Placement: Fixed Distance (ZERO Dynamic Distance Pumping!)
	var ideal_pos = cam_smoothed_target_pos - cam_smoothed_forward * cam_distance + Vector3(0.0, cam_height, 0.0)
	var cam_pos = chase_camera.global_position if chase_camera.is_inside_tree() else chase_camera.position
	cam_pos = cam_pos.lerp(ideal_pos, 1.0 - exp(-12.0 * delta))
	if chase_camera.is_inside_tree():
		chase_camera.global_position = cam_pos
	else:
		chase_camera.position = cam_pos

	# 5. Stable Look-Ahead Target (avoids chassis pitch chatter)
	var look_target = cam_smoothed_target_pos + cam_smoothed_forward * 7.0 + Vector3(0.0, 1.25, 0.0)
	var up_ref = Vector3.UP if cam_smoothed_up.dot(Vector3.UP) > 0.4 else cam_smoothed_up

	if chase_camera.is_inside_tree():
		chase_camera.look_at(look_target, up_ref)

	# 6. Polynomial Event Trauma Decay (Zero continuous vibration)
	if cam_trauma > 0.0:
		cam_trauma = maxf(0.0, cam_trauma - delta * 1.8)
		var shake = cam_trauma * cam_trauma * 0.04
		chase_camera.h_offset = randf_range(-shake, shake)
		chase_camera.v_offset = randf_range(-shake, shake)
	else:
		chase_camera.h_offset = 0.0
		chase_camera.v_offset = 0.0

	if is_instance_valid(camera_spring_arm):
		if camera_spring_arm.is_inside_tree():
			camera_spring_arm.global_position = cam_pos
		else:
			camera_spring_arm.position = cam_pos

	# 7. Instrumentation Telemetry Every Frame
	var cur_cam_pos = chase_camera.global_position if chase_camera.is_inside_tree() else chase_camera.position
	var cur_cam_transform = chase_camera.global_transform if chase_camera.is_inside_tree() else chase_camera.transform
	camera_telemetry = {
		"raw_speed": raw_speed,
		"filtered_speed": cam_filtered_speed,
		"raw_acceleration": raw_accel,
		"filtered_acceleration": cam_filtered_accel,
		"desired_fov": desired_fov,
		"actual_fov": chase_camera.fov,
		"camera_distance": Vector2(cur_cam_pos.x - cam_smoothed_target_pos.x, cur_cam_pos.z - cam_smoothed_target_pos.z).length(),
		"camera_transform": cur_cam_transform
	}

func _update_swap_eligibility() -> void:
	if not is_instance_valid(player_vehicle) or not is_instance_valid(swap_engine) or not is_instance_valid(hud):
		return

	var req_col = ChromaConstants.ChromaColor.NONE
	if is_instance_valid(mission_director):
		req_col = mission_director.get_current_target_color()

	var player_has_req_col = (req_col != ChromaConstants.ChromaColor.NONE and player_vehicle.current_color == req_col)

	# When player already holds required objective color, prioritize checkpoint delivery guidance
	if player_has_req_col and not is_practice_mode:
		var gate_id = mission_director.get_current_target_gate_id()
		hud.show_delivery_prompt(gate_id)
		return

	var target_id = selected_target_id

	# Target persistence & prioritization:
	# If player needs mission color, lock onto vehicle carrying that color
	if not player_has_req_col and req_col != ChromaConstants.ChromaColor.NONE:
		if target_id.is_empty() or not swap_engine.has_vehicle(target_id) or swap_engine.get_vehicle_color(target_id) != req_col:
			var match_id = swap_engine.find_target_with_color("player", req_col)
			if not match_id.is_empty():
				target_id = match_id
				selected_target_id = match_id

	if target_id.is_empty() or not swap_engine.has_vehicle(target_id):
		var nearest_info = swap_engine.find_nearest_eligible_target("player")
		target_id = nearest_info.get("target_id", "")
		if selected_target_id.is_empty():
			selected_target_id = target_id

	if not target_id.is_empty() and swap_engine.has_vehicle(target_id):
		var target_color = swap_engine.get_vehicle_color(target_id)
		var check = swap_engine.evaluate_eligibility("player", target_id, false)
		var progress = check.get("alignment_progress", 0.0)
		hud.set_alignment_progress(progress)
		var is_optional = (req_col != ChromaConstants.ChromaColor.NONE and target_color != req_col)
		hud.show_swap_prompt(check.get("eligible", false), target_color, check.get("reason", ""), progress, is_optional)
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
	var player_has_req_col = (req_color != ChromaConstants.ChromaColor.NONE and player_vehicle.current_color == req_color)

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

	# Radar / MiniMap: if hunting, point to target vehicle; if delivering, point to gate
	var radar_tgt_pos = target_gate_pos
	var radar_tgt_col = target_gate_color
	var radar_has_tgt = has_target_gate

	if not player_has_req_col and not selected_target_id.is_empty() and swap_engine.has_vehicle(selected_target_id):
		var node_tgt = swap_engine.get_vehicle_node(selected_target_id)
		if is_instance_valid(node_tgt):
			radar_tgt_pos = node_tgt.global_position
			radar_tgt_col = swap_engine.get_vehicle_color(selected_target_id)
			radar_has_tgt = true

	if is_instance_valid(hud) and is_instance_valid(hud.mini_map):
		hud.mini_map.update_radar(p_pos, p_rot_y, markers, radar_tgt_pos, radar_tgt_col, radar_has_tgt)

	if is_instance_valid(full_map) and full_map.visible:
		full_map.update_full_map_telemetry(p_pos, p_rot_y, markers, radar_tgt_pos, radar_tgt_col, radar_has_tgt)

	if is_instance_valid(target_beacon):
		if player_has_req_col and has_target_gate:
			target_beacon.visible = true
			target_beacon.global_position = target_gate_pos
			target_beacon.rotate_y(2.5 * delta)
		elif not player_has_req_col and not selected_target_id.is_empty() and swap_engine.has_vehicle(selected_target_id):
			var node_tgt = swap_engine.get_vehicle_node(selected_target_id)
			if is_instance_valid(node_tgt):
				target_beacon.visible = true
				target_beacon.global_position = node_tgt.global_position + Vector3(0.0, 3.2, 0.0)
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
			hud.mini_map.set_world_data(active_world.get_spline_samples())

	# 7. Start Engine Audio & BGM
	if is_instance_valid(chase_camera):
		chase_camera.make_current()
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		if am.has_method("start_engine_sound"):
			am.start_engine_sound()
		if am.has_method("play_music"):
			am.play_music("chroma_rush")

	# Start with cinematic briefing in visual mode, or directly in PLAYING in headless test mode
	if DisplayServer.get_name() == "headless":
		if is_instance_valid(player_vehicle):
			player_vehicle.controls_enabled = true
		set_state(State.PLAYING)
	else:
		if is_instance_valid(player_vehicle):
			player_vehicle.controls_enabled = false
		var m_title = mission_data.get("title", "Mission")
		var district_str = "Downtown Financial"
		if active_world and active_world.has_method("get_district_for_position") and is_instance_valid(player_vehicle):
			district_str = active_world.get_district_for_position(player_vehicle.global_position)
		var start_col = mission_data.get("starting_color", ChromaConstants.ChromaColor.CRIMSON)
		var tgt_cols = mission_data.get("target_colors", [ChromaConstants.ChromaColor.EMERALD])
		var tgt_col = tgt_cols[0] if tgt_cols.size() > 0 else ChromaConstants.ChromaColor.EMERALD
		var clues = "1. Locate target vehicle along traffic corridors\n2. Match speed & pull alongside (<8m)\n3. Hold parallel alignment and press [E / 🎮X] to swap\n4. Deliver color to designated checkpoint gate"
		if is_instance_valid(hud):
			hud.show_mission_briefing(m_title, district_str, start_col, tgt_col, clues)
		set_state(State.BRIEFING)

func _on_briefing_dismissed() -> void:
	if current_state == State.BRIEFING:
		if is_instance_valid(hud):
			hud.hide_mission_briefing()
		countdown_timer = 3.2
		if is_instance_valid(chase_camera):
			chase_camera.make_current()
		if is_instance_valid(player_vehicle):
			player_vehicle.controls_enabled = false
			if is_instance_valid(chase_camera):
				var p_pos = player_vehicle.global_position
				var p_fwd = -player_vehicle.global_transform.basis.z
				p_fwd.y = 0.0
				if p_fwd.length_squared() > 0.01:
					p_fwd = p_fwd.normalized()
				else:
					p_fwd = Vector3.FORWARD
				chase_camera.global_position = p_pos - p_fwd * cam_distance + Vector3(0.0, cam_height, 0.0)
				if chase_camera.is_inside_tree():
					chase_camera.look_at(p_pos + Vector3(0.0, 1.15, 0.0), Vector3.UP)
				else:
					chase_camera.look_at_from_position(chase_camera.position, p_pos + Vector3(0.0, 1.15, 0.0), Vector3.UP)
				if is_instance_valid(camera_spring_arm):
					camera_spring_arm.global_position = chase_camera.global_position
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

	world_container.add_child(player_vehicle)
	player_vehicle.global_transform = spawn_xf
	swap_engine.register_vehicle("player", player_vehicle, start_col, false)

	if is_instance_valid(chase_camera):
		var p_pos = spawn_xf.origin
		var p_fwd = -spawn_xf.basis.z
		p_fwd.y = 0.0
		if p_fwd.length_squared() > 0.01:
			p_fwd = p_fwd.normalized()
		else:
			p_fwd = Vector3.FORWARD
		chase_camera.global_position = p_pos - p_fwd * cam_distance + Vector3(0.0, cam_height, 0.0)
		if chase_camera.is_inside_tree():
			chase_camera.look_at(p_pos + Vector3(0.0, 1.15, 0.0), Vector3.UP)
		else:
			chase_camera.look_at_from_position(chase_camera.position, p_pos + Vector3(0.0, 1.15, 0.0), Vector3.UP)
		if is_instance_valid(camera_spring_arm):
			camera_spring_arm.global_position = chase_camera.global_position

func _spawn_traffic(mission_data: Dictionary) -> void:
	if not is_instance_valid(active_world) or active_world.waypoints.size() < 4:
		return

	# Deterministic seeded randomness for dynamic variation in traffic placement
	var seed_val = mission_data.get("seed", 0)
	if seed_val == 0:
		seed_val = int(Time.get_ticks_msec())
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val

	var diff_str = str(mission_data.get("difficulty", "medium")).to_lower()
	var base_spd = 22.0
	var evasion_agg = 1.0
	match diff_str:
		"easy":
			base_spd = 18.0
			evasion_agg = 0.5
		"medium":
			base_spd = 24.0
			evasion_agg = 1.0
		"hard":
			base_spd = 30.0
			evasion_agg = 1.5
		"expert":
			base_spd = 36.0
			evasion_agg = 2.0

	var available_colors = mission_data.get("traffic_colors", [
		ChromaConstants.ChromaColor.CYAN,
		ChromaConstants.ChromaColor.MAGENTA,
		ChromaConstants.ChromaColor.SOLAR,
		ChromaConstants.ChromaColor.EMERALD
	])

	var wps = active_world.waypoints
	var traffic_count = mini(10, wps.size() - 2)
	var full_bodied_pool = [
		ChromaConstants.VEHICLE_APEX,          # car_sedan_sports.glb (sports sedan)
		ChromaConstants.VEHICLE_QUANTUM,       # car_hatchback_sports.glb (sports hatchback)
		ChromaConstants.VEHICLE_TITAN,         # car_suv_luxury.glb (luxury SUV)
		"traffic_sedan",                       # car_sedan.glb (executive sedan)
		ChromaConstants.VEHICLE_DUNE,          # car_suv.glb (crossover SUV)
		"traffic_taxi",                        # car_taxi.glb (metro cruiser)
		"traffic_police",                      # car_police.glb (highway cruiser)
		"traffic_truck"                        # truck_yellow.glb (delivery truck)
	]

	# Build prioritized color list: guaranteed required colors from mission objectives first
	var prioritized_colors: Array[int] = []
	if mission_data.has("objectives"):
		for obj in mission_data["objectives"]:
			var req_col = obj.get("color", ChromaConstants.ChromaColor.NONE)
			if req_col != ChromaConstants.ChromaColor.NONE and not prioritized_colors.has(req_col):
				prioritized_colors.append(req_col)
	for col in available_colors:
		if not prioritized_colors.has(col):
			prioritized_colors.append(col)

	var start_offset = rng.randi_range(2, 4)
	var wp_step = max(2, int(wps.size() / float(traffic_count)))

	for i in range(traffic_count):
		var veh = ChromaVehicle.new()
		var agent_id = "traffic_%d" % i
		veh.name = agent_id
		veh.vehicle_owner_id = agent_id
		veh.vehicle_id = full_bodied_pool[i % full_bodied_pool.size()]
		veh.is_player = false
		var col = prioritized_colors[i % prioritized_colors.size()]
		veh.initial_color = col
		veh.current_color = col

		# Seeded staggered waypoint distribution across mid-track districts avoiding player spawn and rear approach
		var min_safe_wp = 3
		var max_safe_wp = max(4, wps.size() - 3)
		var safe_range = max(1, max_safe_wp - min_safe_wp)
		var wp_idx = min_safe_wp + (i * safe_range / traffic_count)
		var p_cur = wps[wp_idx]
		var p_next = wps[(wp_idx + 1) % wps.size()]
		var fwd = (p_next - p_cur).normalized()
		fwd.y = 0.0
		if fwd.length_squared() < 0.001:
			fwd = Vector3.FORWARD
		fwd = fwd.normalized()
		var right = fwd.cross(Vector3.UP).normalized()
		var lane_dist = 3.2 if (i % 2 == 0) else -3.2
		var lane_offset = right * lane_dist
		var spawn_pt = p_cur + lane_offset + Vector3(0, 0.05, 0)
		world_container.add_child(veh)
		veh.global_transform = Transform3D().looking_at(fwd, Vector3.UP)
		veh.global_position = spawn_pt

		var spline_pts = active_world.get_spline_samples()
		var lane_samples: Array[Vector3] = []
		for s_idx in range(spline_pts.size()):
			lane_samples.append(active_world.get_lane_point(s_idx, lane_dist))

		var agent = TrafficAgent.new(veh, swap_engine, agent_id, col)
		agent.driver.desired_lane_offset = 0.0
		agent.set_cruise_speed(base_spd + rng.randf_range(-1.5, 2.5))
		if is_instance_valid(player_vehicle):
			agent.set_evasion_threat(player_vehicle, evasion_agg)
		agent.set_waypoints(lane_samples, (wp_idx * 6) % max(1, lane_samples.size()))
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
		veh.vehicle_id = ChromaConstants.VEHICLE_APEX if i % 2 == 0 else ChromaConstants.VEHICLE_QUANTUM
		veh.is_player = false
		veh.initial_color = ChromaConstants.ChromaColor.NONE
		veh.current_color = ChromaConstants.ChromaColor.NONE

		# Stagger rivals at wp 3, 7...
		var wp_idx = (3 + i * 4) % wps.size()
		var p_cur = wps[wp_idx]
		var p_next = wps[(wp_idx + 1) % wps.size()]
		var fwd = (p_next - p_cur).normalized()
		fwd.y = 0.0
		if fwd.length_squared() < 0.001:
			fwd = Vector3.FORWARD
		fwd = fwd.normalized()
		var right = fwd.cross(Vector3.UP).normalized()
		var lane_offset = right * (-3.0 if (i % 2 == 0) else 3.0)
		var spawn_pt = p_cur + lane_offset + Vector3(0, 0.05, 0)
		world_container.add_child(veh)
		veh.global_transform = Transform3D().looking_at(fwd, Vector3.UP)
		veh.global_position = spawn_pt

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

func _on_reset_to_road_requested() -> void:
	if not is_instance_valid(player_vehicle) or current_state != State.PLAYING:
		return
	if is_instance_valid(active_world) and active_world.waypoints.size() > 1:
		var safe_tf = active_world.get_nearest_safe_road_transform(player_vehicle.global_position)
		player_vehicle.reset_to_road(safe_tf.origin, safe_tf.basis.get_euler().y)
	else:
		player_vehicle.reset_to_road()
	cam_is_initialized = false
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("ui_click")


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

	var node_a = swap_engine.get_vehicle_node(initiator_id)
	var node_b = swap_engine.get_vehicle_node(target_id)

	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus and bus.has_signal("chroma_swap_committed"):
		bus.chroma_swap_committed.emit(node_a, node_b, initiator_color, target_color)

	if initiator_id == "player" and is_instance_valid(player_vehicle):
		player_vehicle.set_color(initiator_color)
	elif target_id == "player" and is_instance_valid(player_vehicle):
		player_vehicle.set_color(target_color)

	if node_a and is_instance_valid(node_a) and node_a is ChromaVehicle and node_a != player_vehicle:
		node_a.set_color(initiator_color)
	if node_b and is_instance_valid(node_b) and node_b is ChromaVehicle and node_b != player_vehicle:
		node_b.set_color(target_color)

	# Deliver HUD confirmation banner
	if is_instance_valid(hud):
		var player_new_col = initiator_color if initiator_id == "player" else target_color
		var player_old_col = target_color if initiator_id == "player" else initiator_color
		hud.show_swap_success(player_new_col, player_old_col)

	_spawn_swap_vfx(node_a, node_b, initiator_color, target_color)

func _spawn_swap_vfx(node_a: Node3D, node_b: Node3D, col_a: int, _col_b: int) -> void:
	if not is_instance_valid(node_a) or not is_instance_valid(node_b):
		return

	# Haptic pulse if supported
	if Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(100)

	var p1 = node_a.global_position + Vector3(0, 0.6, 0)
	var p2 = node_b.global_position + Vector3(0, 0.6, 0)
	var color_val = ChromaConstants.get_color_value(col_a)

	# Dynamic 3D OmniLight pulse at swap epicenter (no camera FOV disruption)
	var pulse_light = OmniLight3D.new()
	pulse_light.light_color = color_val
	pulse_light.light_energy = 8.5
	pulse_light.omni_range = 25.0
	pulse_light.global_position = (p1 + p2) * 0.5 + Vector3(0, 1.2, 0)
	add_child(pulse_light)
	var lt_tw = create_tween()
	lt_tw.tween_property(pulse_light, "light_energy", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lt_tw.tween_callback(pulse_light.queue_free)

	# 3D Expanding Energy Shockwave Ring
	var shockwave = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.4
	torus.outer_radius = 1.1
	shockwave.mesh = torus
	var s_mat = StandardMaterial3D.new()
	s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	s_mat.albedo_color = color_val
	s_mat.emission_enabled = true
	s_mat.emission = color_val
	s_mat.emission_energy_multiplier = 4.0
	shockwave.material_override = s_mat
	shockwave.global_position = (p1 + p2) * 0.5
	shockwave.rotation_degrees = Vector3(90, 0, 0)
	add_child(shockwave)

	var sw_tw = create_tween().set_parallel(true)
	sw_tw.tween_property(shockwave, "scale", Vector3(3.2, 3.2, 3.2), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sw_tw.tween_property(s_mat, "albedo_color:a", 0.0, 0.26)
	sw_tw.chain().tween_callback(shockwave.queue_free)

	# 3D Energy Arc Line between vehicles
	var arc = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	arc.mesh = immediate_mesh
	var arc_mat = StandardMaterial3D.new()
	arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc_mat.albedo_color = color_val.lightened(0.2)
	arc_mat.emission_enabled = true
	arc_mat.emission = color_val
	arc_mat.emission_energy_multiplier = 3.5
	arc.material_override = arc_mat

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(p1)
	immediate_mesh.surface_add_vertex(p2)
	immediate_mesh.surface_end()

	add_child(arc)
	var arc_tw = create_tween()
	arc_tw.tween_property(arc_mat, "albedo_color:a", 0.0, 0.3)
	arc_tw.tween_callback(arc.queue_free)

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
		full_map.open_map(active_world.world_name, active_world.get_spline_samples(), gates_data)

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
			hud.mini_map.set_world_data(active_world.get_spline_samples())
	if is_instance_valid(player_vehicle):
		player_vehicle.controls_enabled = true
	set_state(State.PLAYING)

func quick_play() -> void:
	start_mission("hunt_neon_01")
	if current_state == State.BRIEFING:
		_on_briefing_dismissed()
		countdown_timer = 0.0
		if is_instance_valid(player_vehicle):
			player_vehicle.controls_enabled = true
		set_state(State.PLAYING)

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
	if is_instance_valid(chase_camera):
		chase_camera.make_current()

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
