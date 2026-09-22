class_name SkyboundMain
extends Node3D

## SkyboundMain: Main Game Controller for Skybound Odyssey
## Oversees Player, Camera, 5-Region World, Quests, Inventory, and UI.

const SkyCharacterScript = preload("res://games/skybound-odyssey/character/sky_character.gd")
const SkyboundWorldScript = preload("res://games/skybound-odyssey/world/skybound_world.gd")
const SkyboundHUDScript = preload("res://games/skybound-odyssey/ui/skybound_hud.gd")
const OrbitCameraScript = preload("res://shared/cameras/orbit_camera.gd")
const DayNightCycleScript = preload("res://shared/environment/day_night_cycle.gd")
const QuestManagerScript = preload("res://shared/gameplay/quest_system.gd")
const InventorySystemScript = preload("res://shared/gameplay/inventory_system.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")
const ResultsScreenScript = preload("res://shared/ui/results_screen.gd")

var player: CharacterBody3D
var world: Node3D
var orbit_camera: Node3D
var day_night: Node3D
var world_environment: WorldEnvironment = null
var quest_manager: Node
var inventory: Node
var hud: Control
var pause_menu: CanvasLayer
var results_screen: CanvasLayer

var game_active: bool = true
var collected_shards_count: int = 0

func _on_shard_collected(_shard_id: String = "") -> void:
	collected_shards_count += 1
	if player:
		player.shards_collected = collected_shards_count

func _on_all_quests_finished() -> void:
	complete_odyssey()

func _ready() -> void:
	setup_game()

func setup_game() -> void:
	# 1. Environment & Lighting
	day_night = DayNightCycleScript.new()
	day_night.name = "DayNightCycle"
	add_child(day_night)
	_setup_environment()

	# 2. Subsystems
	quest_manager = QuestManagerScript.new()
	quest_manager.name = "QuestManager"
	add_child(quest_manager)

	inventory = InventorySystemScript.new()
	inventory.name = "InventorySystem"
	add_child(inventory)

	# 3. 5-Region 3D World
	world = SkyboundWorldScript.new()
	world.name = "SkyboundWorld"
	add_child(world)
	world.build_world()

	# 4. Player Character
	player = SkyCharacterScript.new()
	player.name = "Player"
	player.global_position = Vector3(0, 3.5, 0)
	add_child(player)

	# 5. Orbit Camera with Collision Avoidance
	orbit_camera = OrbitCameraScript.new()
	orbit_camera.name = "OrbitCamera"
	orbit_camera.set_target(player)
	add_child(orbit_camera)

	# 6. Responsive UI
	hud = SkyboundHUDScript.new()
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
	results_screen.next_stage_pressed.connect(_on_next_region_requested)
	results_screen.launcher_pressed.connect(_on_quit_to_launcher)
	add_child(results_screen)

	connect_signals()
	initialize_quest_lines()

func connect_signals() -> void:
	player.shard_collected.connect(func(total: int, amount: int):
		collected_shards_count = total
		hud.update_shards(total)
		inventory.add_item("energy_shard", amount)
		quest_manager.advance_objective("quest_emerald", "shards", amount)
		quest_manager.advance_objective("quest_apex", "apex_artifact", amount)
	)

	player.energy_changed.connect(hud.update_stamina)

	world.region_entered.connect(func(r_name: String):
		hud.update_region(r_name)
		_apply_region_environment(r_name)
		if r_name == "Crystal Caverns":
			quest_manager.start_quest("quest_caverns")
		elif r_name == "Sunken Sky Temple":
			quest_manager.start_quest("quest_temple")
		elif r_name == "Frost Peaks":
			quest_manager.start_quest("quest_peaks")
		elif r_name == "Storm Citadel":
			quest_manager.start_quest("quest_citadel")
	)

	quest_manager.objective_updated.connect(func(q_id: String, _obj_id: String, cur: int, req: int):
		var q = quest_manager.get_quest(q_id)
		if q:
			hud.update_quest(q.title, "%s (%d/%d)" % [q.objectives[0].description, cur, req])
	)

	quest_manager.quest_completed.connect(func(q_id: String, _rewards: Dictionary):
		if q_id == "quest_emerald":
			world.unlock_region(1)
			results_screen.display_results(true, {
				"Region": "Emerald Isles Cleared",
				"Shards Found": "%d / 3" % player.shards_collected,
				"Next Region": "Crystal Caverns Unlocked",
				"Status": "ALTAR AWAKENED"
			}, "ancient_relic", "ANCIENT RELIC // PORTAL UNLOCKED")
		elif q_id == "quest_caverns":
			world.unlock_region(2)
			results_screen.display_results(true, {
				"Region": "Crystal Caverns Cleared",
				"Chasm": "Crossed",
				"Next Region": "Sunken Sky Temple Unlocked",
				"Status": "TEMPLE LOCATED"
			}, "ancient_relic", "ANCIENT RELIC // TEMPLE OPENED")
		elif q_id == "quest_temple":
			world.unlock_region(3)
			results_screen.display_results(true, {
				"Region": "Sunken Sky Temple Cleared",
				"Thermal Current": "Mastered",
				"Next Region": "Frost Peaks Unlocked",
				"Status": "ASCENSION READY"
			}, "ancient_relic", "ANCIENT RELIC // PEAKS UNLOCKED")
		elif q_id == "quest_peaks":
			world.unlock_region(4)
			results_screen.display_results(true, {
				"Region": "Frost Peaks Cleared",
				"Crags": "Mantled",
				"Next Region": "Storm Citadel Unlocked",
				"Status": "SUMMIT REACHED"
			}, "ancient_relic", "ANCIENT RELIC // CITADEL UNLOCKED")
		elif q_id == "quest_citadel":
			complete_odyssey()
	)

func _on_next_region_requested() -> void:
	results_screen.hide_results()
	var next_reg_idx = world.current_region_idx + 1
	var spawn_points = [
		Vector3(0, 3.5, 0),             # 0: Emerald Isles
		Vector3(0, -18.0, 80.0),         # 1: Crystal Caverns
		Vector3(95.0, 14.0, 0),          # 2: Sunken Sky Temple
		Vector3(-95.0, 26.0, 0),         # 3: Frost Peaks
		Vector3(0, 44.0, -115.0)         # 4: Storm Citadel
	]
	if next_reg_idx < spawn_points.size():
		player.global_position = spawn_points[next_reg_idx]
		player.velocity = Vector3.ZERO
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am and am.has_method("play_sound"):
			am.play_sound("respawn", 1.0, 1.2)
	else:
		complete_odyssey()

func initialize_quest_lines() -> void:
	var q1_objs = [
		QuestManagerScript.Objective.new("shards", "Collect Energy Shards in Emerald Isles", 3, "shards")
	]
	quest_manager.create_and_register_quest("quest_emerald", "Awaken the Ruins", "Gather 3 ancient shards across the floating isles.", q1_objs, {"unlock_region": 1})

	var q2_objs = [
		QuestManagerScript.Objective.new("grapple_chasm", "Traverse the Chasm in Crystal Caverns", 1, "grapple")
	]
	quest_manager.create_and_register_quest("quest_caverns", "Crystal Chasm", "Use your grappling hook to bridge the glowing chasms.", q2_objs, {"unlock_region": 2}, ["quest_emerald"])

	var q3_objs = [
		QuestManagerScript.Objective.new("temple_core", "Ride the Wind Current to the High Altar", 1, "switch")
	]
	quest_manager.create_and_register_quest("quest_temple", "Sunken Sky Temple", "Deploy your glider on the upward thermal to reach the altar.", q3_objs, {"unlock_region": 3}, ["quest_caverns"])

	var q4_objs = [
		QuestManagerScript.Objective.new("frost_mantle", "Mantle the Frost Peak Crags", 1, "mantle")
	]
	quest_manager.create_and_register_quest("quest_peaks", "The Frozen Ascent", "Climb the ice ledges to reach the Storm Citadel entrance.", q4_objs, {"unlock_region": 4}, ["quest_temple"])

	var q5_objs = [
		QuestManagerScript.Objective.new("apex_artifact", "Retrieve the Apex Skybound Artifact", 1, "apex")
	]
	quest_manager.create_and_register_quest("quest_citadel", "Apex of the Sky", "Claim the legendary artifact at the Storm Citadel summit.", q5_objs, {"title": "Master Skyfarer"}, ["quest_peaks"])

	quest_manager.start_quest("quest_emerald")

func complete_odyssey() -> void:
	game_active = false
	var sm = GameConstants.get_autoload(self, "SaveManager")
	if sm:
		sm.record_skybound_progress(5, player.shards_collected, true)

	results_screen.display_results(true, {
		"Status": "ODYSSEY COMPLETE!",
		"Regions Explored": "5 / 5",
		"Energy Shards": player.shards_collected,
		"Title": "Master Skyfarer"
	}, "ancient_relic", "APEX ARTIFACT // MASTER SKYFARER")

func _on_restart() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.game_restart_requested.emit()

func _on_quit_to_launcher() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.return_to_launcher_requested.emit()

func _setup_environment() -> void:
	world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var env = Environment.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.18, 0.45, 0.85)
	sky_mat.sky_horizon_color = Color(0.68, 0.82, 0.95)
	sky_mat.ground_bottom_color = Color(0.15, 0.22, 0.28)
	sky_mat.ground_horizon_color = Color(0.55, 0.72, 0.88)
	sky_mat.sun_angle_max = 30.0
	sky_mat.energy_multiplier = 1.15
	var sky = Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.40, 0.55, 0.75)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.10
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.15
	env.fog_enabled = true
	env.fog_light_color = Color(0.62, 0.78, 0.92)
	env.fog_density = 0.0035
	env.fog_aerial_perspective = 0.4
	world_environment.environment = env
	add_child(world_environment)

func _apply_region_environment(r_name: String) -> void:
	if not world_environment or not world_environment.environment:
		return
	var env = world_environment.environment
	var sky = env.sky
	var sky_mat = sky.sky_material as ProceduralSkyMaterial if sky else null

	match r_name:
		"Crystal Caverns":
			if sky_mat:
				sky_mat.sky_top_color = Color(0.06, 0.04, 0.16)
				sky_mat.sky_horizon_color = Color(0.18, 0.35, 0.55)
				sky_mat.ground_bottom_color = Color(0.04, 0.02, 0.08)
				sky_mat.ground_horizon_color = Color(0.12, 0.18, 0.30)
			env.ambient_light_color = Color(0.25, 0.20, 0.45)
			env.ambient_light_energy = 0.65
			env.fog_light_color = Color(0.15, 0.22, 0.38)
			env.fog_density = 0.008
		"Sunken Sky Temple":
			if sky_mat:
				sky_mat.sky_top_color = Color(0.22, 0.38, 0.65)
				sky_mat.sky_horizon_color = Color(0.92, 0.72, 0.45)
				sky_mat.ground_bottom_color = Color(0.20, 0.15, 0.10)
				sky_mat.ground_horizon_color = Color(0.65, 0.48, 0.30)
			env.ambient_light_color = Color(0.55, 0.42, 0.25)
			env.ambient_light_energy = 0.95
			env.fog_light_color = Color(0.75, 0.60, 0.42)
			env.fog_density = 0.004
		"Frost Peaks":
			if sky_mat:
				sky_mat.sky_top_color = Color(0.10, 0.25, 0.55)
				sky_mat.sky_horizon_color = Color(0.78, 0.90, 0.98)
				sky_mat.ground_bottom_color = Color(0.35, 0.45, 0.55)
				sky_mat.ground_horizon_color = Color(0.70, 0.82, 0.92)
			env.ambient_light_color = Color(0.45, 0.55, 0.68)
			env.ambient_light_energy = 0.90
			env.fog_light_color = Color(0.75, 0.85, 0.95)
			env.fog_density = 0.006
		"Storm Citadel":
			if sky_mat:
				sky_mat.sky_top_color = Color(0.05, 0.06, 0.14)
				sky_mat.sky_horizon_color = Color(0.35, 0.20, 0.42)
				sky_mat.ground_bottom_color = Color(0.04, 0.04, 0.08)
				sky_mat.ground_horizon_color = Color(0.18, 0.14, 0.25)
			env.ambient_light_color = Color(0.30, 0.25, 0.45)
			env.ambient_light_energy = 0.60
			env.fog_light_color = Color(0.25, 0.18, 0.32)
			env.fog_density = 0.007
		_:
			if sky_mat:
				sky_mat.sky_top_color = Color(0.18, 0.45, 0.85)
				sky_mat.sky_horizon_color = Color(0.68, 0.82, 0.95)
				sky_mat.ground_bottom_color = Color(0.15, 0.22, 0.28)
				sky_mat.ground_horizon_color = Color(0.55, 0.72, 0.88)
			env.ambient_light_color = Color(0.40, 0.55, 0.75)
			env.ambient_light_energy = 0.85
			env.fog_light_color = Color(0.62, 0.78, 0.92)
			env.fog_density = 0.0035

