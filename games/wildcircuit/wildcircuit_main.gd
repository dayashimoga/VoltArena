class_name WildCircuitMain
extends Node3D

## WildCircuitMain: Main Game Controller for WildCircuit.
## Integrates 5 Biomes, Wildlife AI, Viewfinder Photography, Explorer ATV, and Field Journal.

const WildBiomesScript = preload("res://games/wildcircuit/world/wild_biomes.gd")
const ExplorerATVScript = preload("res://games/wildcircuit/traversal/explorer_atv.gd")
const PhotographySystemScript = preload("res://games/wildcircuit/photography/camera_mode.gd")
const FieldJournalScript = preload("res://games/wildcircuit/journal/field_journal.gd")
const WildCircuitHUDScript = preload("res://games/wildcircuit/ui/wildcircuit_hud.gd")
const OrbitCameraScript = preload("res://shared/cameras/orbit_camera.gd")
const DayNightCycleScript = preload("res://shared/environment/day_night_cycle.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")
const ResultsScreenScript = preload("res://shared/ui/results_screen.gd")
const AnimalDataScript = preload("res://games/wildcircuit/animals/animal_data.gd")

var biomes: Node3D
var player: CharacterBody3D
var atv: CharacterBody3D
var camera: Node3D
var day_night: Node3D
var journal: Node
var hud: Control
var pause_menu: CanvasLayer
var results_screen: CanvasLayer

var is_camera_mode: bool = false
var focal_length: float = 70.0
var active_target_animal: Node3D = null

func _ready() -> void:
	setup_game()

func setup_game() -> void:
	# 1. Day / Night Celestial Lighting
	day_night = DayNightCycleScript.new()
	day_night.name = "DayNightCycle"
	add_child(day_night)

	# 2. Field Journal
	journal = FieldJournalScript.new()
	journal.name = "FieldJournal"
	add_child(journal)

	# 3. 5 Biomes & Autonomous Wildlife
	biomes = WildBiomesScript.new()
	biomes.name = "WildBiomes"
	add_child(biomes)

	# 4. Player Explorer (On Foot)
	player = _create_player_explorer()
	player.global_position = Vector3(0, 0.5, 5.0)
	add_child(player)

	# 5. Explorer ATV Traversal Vehicle
	atv = ExplorerATVScript.new()
	atv.name = "ExplorerATV"
	atv.global_position = Vector3(4.0, 0.5, 5.0)
	add_child(atv)

	# 6. Orbit Camera
	camera = OrbitCameraScript.new()
	camera.name = "OrbitCamera"
	camera.set_target(player)
	add_child(camera)

	# 7. UI & Menus
	hud = WildCircuitHUDScript.new()
	hud.name = "HUD"
	add_child(hud)

	pause_menu = PauseMenuScript.new()
	pause_menu.name = "PauseMenu"
	pause_menu.restart_requested.connect(_on_restart)
	pause_menu.quit_to_launcher_requested.connect(_on_quit_to_launcher)
	add_child(pause_menu)

	results_screen = ResultsScreenScript.new()
	results_screen.name = "ResultsScreen"
	results_screen.restart_pressed.connect(_on_restart)
	results_screen.launcher_pressed.connect(_on_quit_to_launcher)
	add_child(results_screen)

	connect_signals()

func _create_player_explorer() -> CharacterBody3D:
	var body = CharacterBody3D.new()
	body.name = "Player"
	body.add_to_group("players")
	body.collision_layer = GameConstants.LAYER_PLAYER
	body.collision_mask = GameConstants.LAYER_WORLD

	var mi = MeshInstance3D.new()
	var cap = CapsuleMesh.new()
	cap.radius = 0.38
	cap.height = 1.75
	mi.mesh = cap
	mi.material_override = MaterialGenerator.get_material("savannah_dirt")
	mi.position = Vector3(0, 0.88, 0)
	body.add_child(mi)

	var col = CollisionShape3D.new()
	var cs = CapsuleShape3D.new()
	cs.radius = 0.38
	cs.height = 1.75
	col.shape = cs
	col.position = Vector3(0, 0.88, 0)
	body.add_child(col)

	return body

func connect_signals() -> void:
	if day_night.has_signal("time_updated"):
		day_night.time_updated.connect(hud.update_time_display)

	journal.photo_logged.connect(func(photo_record: Dictionary):
		hud.show_photo_result(photo_record)
		var total_found = journal.get_total_discovered()
		if total_found >= 4:
			complete_expedition()
	)

func _process(delta: float) -> void:
	handle_player_movement(delta)
	handle_camera_aim(delta)
	scan_viewport_for_wildlife()

func handle_player_movement(delta: float) -> void:
	if is_instance_valid(atv) and atv.is_occupied:
		return

	if not player.is_on_floor():
		player.velocity.y -= 22.0 * delta

	var im = GameConstants.get_autoload(self, "InputManager")
	var raw_x = 0.0
	var raw_z = 0.0

	if Input.is_action_pressed("move_forward"): raw_z -= 1.0
	if Input.is_action_pressed("move_back"): raw_z += 1.0
	if Input.is_action_pressed("move_left"): raw_x -= 1.0
	if Input.is_action_pressed("move_right"): raw_x += 1.0

	if im and im.virtual_move_vector.length_squared() > 0.01:
		raw_x = im.virtual_move_vector.x
		raw_z = im.virtual_move_vector.y

	var cam_node = camera.camera if "camera" in camera else null
	var move_dir = Vector3.ZERO
	if cam_node:
		var fwd = -cam_node.global_transform.basis.z
		fwd.y = 0.0
		fwd = fwd.normalized()
		var right = cam_node.global_transform.basis.x
		right.y = 0.0
		right = right.normalized()
		move_dir = (right * raw_x + fwd * -raw_z).normalized()
	else:
		move_dir = Vector3(raw_x, 0, raw_z).normalized()

	var is_sprint = Input.is_action_pressed("sprint")
	var spd = 9.0 if is_sprint else 5.0
	if is_camera_mode:
		spd = 2.0 # Slow creep while framing photos

	player.velocity.x = move_dir.x * spd
	player.velocity.z = move_dir.z * spd
	player.move_and_slide()

	# Mount / Dismount ATV
	if Input.is_action_just_pressed("interact"):
		if atv.is_occupied:
			atv.dismount()
			camera.set_target(player)
		elif player.global_position.distance_to(atv.global_position) < 3.0:
			atv.mount(player)
			camera.set_target(atv)

func handle_camera_aim(_delta: float) -> void:
	# Right click or 'C' toggles Viewfinder Camera Mode
	if Input.is_action_just_pressed("crouch") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		toggle_camera_mode(not is_camera_mode)

	if is_camera_mode:
		# Mouse wheel zooms focal length
		if Input.is_action_just_pressed("next_weapon"):
			focal_length = minf(300.0, focal_length + 25.0)
			hud.update_zoom(focal_length)
		elif Input.is_action_just_pressed("prev_weapon"):
			focal_length = maxf(24.0, focal_length - 25.0)
			hud.update_zoom(focal_length)

		# Left click captures photograph
		if Input.is_action_just_pressed("fire"):
			capture_photograph()

func toggle_camera_mode(active: bool) -> void:
	is_camera_mode = active
	hud.toggle_viewfinder(active)
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("zoom_in" if active else "zoom_out", 1.0, 0.8)

func scan_viewport_for_wildlife() -> void:
	var cam_node: Camera3D = camera.camera if "camera" in camera else null
	if not cam_node or not is_camera_mode:
		return

	active_target_animal = null
	var animals = get_tree().get_nodes_in_group("animals")
	var best_dist = 999.0

	for a in animals:
		if not is_instance_valid(a):
			continue
		var to_a = a.global_position - cam_node.global_position
		var fwd = -cam_node.global_transform.basis.z
		if fwd.dot(to_a.normalized()) > 0.6: # In front of camera
			var d = to_a.length()
			if d < best_dist and d < 45.0:
				best_dist = d
				active_target_animal = a

	if active_target_animal:
		var sp_id = active_target_animal.get("species_id")
		var sp_info = AnimalDataScript.get_species(sp_id)
		var beh = active_target_animal.get_current_behavior_name() if active_target_animal.has_method("get_current_behavior_name") else "Resting"
		hud.update_subject_info(sp_info.get("name", "Wildlife"), "%.1fm" % best_dist, beh)
	else:
		hud.update_subject_info("No Target", "--", "Scanning habitat...")

func capture_photograph() -> void:
	var cam_node: Camera3D = camera.camera if "camera" in camera else null
	if not cam_node:
		return

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("weapon_beam", 0.9, 0.6) # Shutter sound

	var space = get_world_3d().direct_space_state
	if active_target_animal:
		var result = PhotographySystemScript.score_photograph(cam_node, active_target_animal, space)
		if result.get("valid", false):
			journal.log_photo(result)
			if active_target_animal.has_signal("photographed"):
				active_target_animal.photographed.emit(result["score"], result["grade"])
	else:
		var bus = GameConstants.get_autoload(self, "EventBus")
		if bus:
			bus.show_toast_requested.emit("No wildlife in viewfinder frame!", Color(1.0, 0.4, 0.3))

func complete_expedition() -> void:
	results_screen.display_results(true, {
		"Status": "CONSERVATION SURVEY COMPLETE!",
		"Species Documented": "%d / %d" % [journal.get_total_discovered(), AnimalDataScript.SPECIES.size()],
		"Rank": "Master Field Ranger",
		"Conservation Rating": "100% Certified"
	})

func _on_restart() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.game_restart_requested.emit()

func _on_quit_to_launcher() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.return_to_launcher_requested.emit()
