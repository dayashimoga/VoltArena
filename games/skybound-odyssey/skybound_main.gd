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
var quest_manager: Node
var inventory: Node
var hud: Control
var pause_menu: CanvasLayer
var results_screen: CanvasLayer

var game_active: bool = true

func _ready() -> void:
	setup_game()

func setup_game() -> void:
	# 1. Environment & Lighting
	day_night = DayNightCycleScript.new()
	day_night.name = "DayNightCycle"
	add_child(day_night)

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
	results_screen.launcher_pressed.connect(_on_quit_to_launcher)
	add_child(results_screen)

	connect_signals()
	initialize_quest_lines()

func connect_signals() -> void:
	player.shard_collected.connect(func(total: int, amount: int):
		hud.update_shards(total)
		inventory.add_item("energy_shard", amount)
		quest_manager.advance_objective("quest_emerald", "shards", amount)
		quest_manager.advance_objective("quest_apex", "apex_artifact", amount)
	)

	player.energy_changed.connect(hud.update_stamina)

	world.region_entered.connect(func(r_name: String):
		hud.update_region(r_name)
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
		elif q_id == "quest_citadel":
			complete_odyssey()
	)

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
	})

func _on_restart() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.game_restart_requested.emit()

func _on_quit_to_launcher() -> void:
	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.return_to_launcher_requested.emit()
