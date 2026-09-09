class_name StrikeVectorMain
extends Node3D

## Main Game Scene Orchestrator for STRIKE VECTOR.
## Coordinates: CampaignManager, MissionStreamer, CameraDirector, StrikePlayer, StrikeHUD, and Results.

const CampaignManagerScript = preload("res://games/strike-vector/campaign/campaign_manager.gd")
const MissionManagerScript = preload("res://games/strike-vector/campaign/mission_manager.gd")
const MissionStreamerScript = preload("res://games/strike-vector/campaign/mission_streamer.gd")
const CameraDirectorScript = preload("res://games/strike-vector/camera/camera_director.gd")
const StrikePlayerScript = preload("res://games/strike-vector/player/strike_player.gd")
const StrikeAudioDirectorScript = preload("res://games/strike-vector/audio/strike_audio_director.gd")
const MissionDefinitionsScript = preload("res://games/strike-vector/missions/mission_definitions.gd")
const StrikeHUDScript = preload("res://games/strike-vector/ui/strike_hud.gd")
const StrikeResultsScript = preload("res://games/strike-vector/ui/strike_results_screen.gd")
const PauseMenuScript = preload("res://shared/ui/pause_menu.gd")

@export var start_mission_index: int = 1

var campaign_mgr: Node = null
var mission_mgr: Node = null
var mission_streamer: Node3D = null
var camera_director: Node3D = null
var player_node: CharacterBody3D = null
var audio_director: Node = null

var hud: Control = null
var pause_menu: CanvasLayer = null
var results_screen: CanvasLayer = null

func _ready() -> void:
	setup_subsystems()
	load_mission(start_mission_index)

func setup_subsystems() -> void:
	if campaign_mgr != null:
		return
	campaign_mgr = CampaignManagerScript.new()
	campaign_mgr.name = "CampaignManager"
	add_child(campaign_mgr)

	mission_mgr = MissionManagerScript.new()
	mission_mgr.name = "MissionManager"
	mission_mgr.mission_completed.connect(_on_mission_completed)
	add_child(mission_mgr)

	audio_director = StrikeAudioDirectorScript.new()
	audio_director.name = "AudioDirector"
	add_child(audio_director)

	# Setup Global Environment Lighting & Atmosphere
	_setup_environment_lighting()

	# Setup UI
	hud = StrikeHUDScript.new()
	hud.name = "HUD"
	add_child(hud)

	pause_menu = PauseMenuScript.new()
	pause_menu.name = "PauseMenu"
	pause_menu.resume_requested.connect(_on_resume)
	pause_menu.restart_requested.connect(restart_mission)
	pause_menu.quit_to_launcher_requested.connect(_on_quit_to_launcher)
	add_child(pause_menu)

	results_screen = StrikeResultsScript.new()
	results_screen.name = "ResultsScreen"
	results_screen.next_mission_requested.connect(_on_next_mission_requested)
	results_screen.restart_requested.connect(restart_mission)
	results_screen.launcher_requested.connect(_on_quit_to_launcher)
	add_child(results_screen)

	# Capture mouse
	var im = GameConstants.get_autoload(self, "InputManager")
	if im and im.has_method("capture_mouse"):
		im.capture_mouse(true)

func _setup_environment_lighting() -> void:
	if has_node("WorldEnvironment"):
		return

	var we = WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var env = Environment.new()

	# Procedural midnight sky with dark atmospheric horizon
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.01, 0.03, 0.08)
	sky_mat.sky_horizon_color = Color(0.06, 0.10, 0.18)
	sky_mat.sky_curve = 0.12
	sky_mat.ground_bottom_color = Color(0.02, 0.03, 0.05)
	sky_mat.ground_horizon_color = Color(0.04, 0.07, 0.12)
	sky_mat.ground_curve = 0.08
	sky_mat.energy_multiplier = 0.60

	var sky = Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky

	# Moody, tactical ambient illumination for Urban Blackout
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.16, 0.24)
	env.ambient_light_energy = 0.35

	# Filmic tonemapper with high dynamic range
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.15
	env.tonemap_white = 4.0

	# Glow bloom on neon signs and muzzle flashes
	env.glow_enabled = true
	env.glow_intensity = 0.65
	env.glow_bloom = 0.25

	# Subtle atmospheric blackout depth fog
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.06, 0.12)
	env.fog_density = 0.0035

	we.environment = env
	add_child(we)

	# Directional Moonlight
	var dir_light = DirectionalLight3D.new()
	dir_light.name = "KeyMoonlight"
	dir_light.light_color = Color(0.70, 0.82, 0.96)
	dir_light.light_energy = 0.85
	dir_light.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	dir_light.shadow_enabled = true
	add_child(dir_light)

func load_mission(m_idx: int) -> void:
	# Ensure subsystems are initialized even if called before _ready()
	if campaign_mgr == null:
		setup_subsystems()

	# Clear existing streamer, player, camera
	if is_instance_valid(mission_streamer):
		mission_streamer.queue_free()
	if is_instance_valid(player_node):
		player_node.queue_free()
	if is_instance_valid(camera_director):
		camera_director.queue_free()

	# Create Mission Streamer & Segments
	mission_streamer = MissionStreamerScript.new()
	mission_streamer.name = "MissionStreamer"
	add_child(mission_streamer)

	var segs = MissionDefinitionsScript.build_mission_segments(m_idx)
	mission_streamer.setup_segments(segs)

	# Spawn Player safely on grounded roadway
	player_node = StrikePlayerScript.new()
	player_node.name = "Player"
	player_node.position = Vector3(0, 0.1, -6.0)
	add_child(player_node)

	# Connect Player Signals to HUD & Checkpoints
	player_node.health_changed.connect(hud.update_health)
	player_node.armor_changed.connect(hud.update_armor)
	player_node.damage_taken.connect(func(_amt, _dealer, _wep, _pos):
		var threat_pos = Vector3.ZERO
		var closest_dist = 9999.0
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(enemy) and enemy is Node3D:
				var d = player_node.global_position.distance_to(enemy.global_position)
				if d < closest_dist:
					closest_dist = d
					threat_pos = enemy.global_position
		if closest_dist > 60.0:
			threat_pos = player_node.global_position - player_node.global_transform.basis.z * 12.0
		var cam_yaw = player_node.rotation.y
		if is_instance_valid(camera_director) and is_instance_valid(camera_director.camera):
			var cam_fwd = -camera_director.camera.global_transform.basis.z
			cam_yaw = atan2(-cam_fwd.x, -cam_fwd.z)
		hud.trigger_damage_feedback(threat_pos, player_node.global_position, cam_yaw)
	)
	player_node.weapon_switched.connect(func(_idx, w_name, ammo, res):
		var f_mode = "AUTO"
		if is_instance_valid(player_node.active_weapon):
			var w = player_node.active_weapon
			f_mode = "AUTO" if w.is_automatic else ("BURST" if w.is_burst else ("CHARGE" if w.is_charged else "SEMI"))
		hud.update_weapon(w_name, ammo, res, f_mode)
	)
	player_node.ammo_updated.connect(func(w_name, ammo, res):
		var f_mode = "AUTO"
		if is_instance_valid(player_node.active_weapon):
			var w = player_node.active_weapon
			f_mode = "AUTO" if w.is_automatic else ("BURST" if w.is_burst else ("CHARGE" if w.is_charged else "SEMI"))
		hud.update_weapon(w_name, ammo, res, f_mode)
	)
	player_node.player_died.connect(_on_player_died)

	# Register initial checkpoint
	mission_mgr.checkpoint_mgr.register_checkpoint("m%d_start" % m_idx, player_node.position, 0.0, m_idx, 0, player_node)

	# Setup Camera Director
	camera_director = CameraDirectorScript.new()
	camera_director.name = "CameraDirector"
	camera_director.target_player = player_node
	add_child(camera_director)

	# Connect Segments
	_connect_segment_events()

	var meta = MissionDefinitionsScript.get_mission_meta(m_idx)
	mission_mgr.start_mission(m_idx, meta["name"], mission_streamer)
	hud.update_objective(meta["objective"])
	hud.show_context_alert("DEPLOYED: " + meta["name"].to_upper(), Color(0.2, 1.0, 0.4))
	audio_director.set_audio_state(StrikeAudioDirectorScript.AudioState.EXPLORATION)

func _process(_delta: float) -> void:
	if not is_instance_valid(player_node) or not is_instance_valid(hud):
		return

	var p_pos = player_node.global_position
	var heading_rad = player_node.rotation.y
	if is_instance_valid(camera_director) and is_instance_valid(camera_director.camera):
		var cam_fwd = -camera_director.camera.global_transform.basis.z
		cam_fwd.y = 0.0
		if cam_fwd.length_squared() > 0.01:
			heading_rad = atan2(-cam_fwd.x, -cam_fwd.z)

	var target_pos = Vector3(0, 0, -160.0)
	var target_name = "DESTROY JAMMER"
	if is_instance_valid(mission_streamer):
		var act_seg = mission_streamer.get_active_segment()
		if act_seg:
			if act_seg.is_boss_segment:
				target_pos = act_seg.global_position + Vector3(0, 0, -20.0)
				target_name = "EXTRACTION ZONE"
			else:
				target_pos = act_seg.global_position + Vector3(0, 0, -20.0)
				target_name = act_seg.segment_name

	var threat_positions: Array = []
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy is Node3D:
			var e_dist = p_pos.distance_to(enemy.global_position)
			var is_alert = false
			if enemy.get("current_state") != null and int(enemy.current_state) >= 4:
				is_alert = true
			if e_dist <= 24.0 or is_alert:
				threat_positions.append(enemy.global_position)

	hud.update_navigation_state(p_pos, heading_rad, target_pos, target_name, threat_positions)

func _connect_segment_events() -> void:
	for seg in mission_streamer.segments:
		if is_instance_valid(seg.encounter_director):
			seg.encounter_director.route_cleared.connect(func():
				hud.show_context_alert("ROUTE CLEAR // ADVANCE", Color(0.0, 1.0, 1.0))
				if seg.segment_index < mission_streamer.segments.size() - 1:
					advance_segment()
				else:
					# All segments cleared -> Mission complete!
					mission_mgr.complete_mission()
			)

func advance_segment() -> void:
	if not is_instance_valid(mission_streamer):
		return
	mission_streamer.advance_to_next_segment()
	var act_seg = mission_streamer.get_active_segment()
	if act_seg and is_instance_valid(player_node):
		# Register checkpoint at next segment entrance
		mission_mgr.checkpoint_mgr.register_checkpoint(
			"m%d_seg%d" % [mission_mgr.mission_index, act_seg.segment_index],
			act_seg.checkpoint_pos,
			0.0,
			mission_mgr.mission_index,
			act_seg.segment_index,
			player_node
		)
		hud.show_context_alert("CHECKPOINT REACHED", Color(0.2, 0.9, 1.0))

func _on_player_died() -> void:
	mission_mgr.record_death()
	hud.show_context_alert("CRITICAL DAMAGE // RESTORING", Color(1.0, 0.2, 0.2))

	# Respawn after short delay
	var tree = get_tree()
	if tree:
		tree.create_timer(1.2).timeout.connect(func():
			if is_instance_valid(player_node):
				mission_mgr.checkpoint_mgr.restore_player_to_checkpoint(player_node)
		)

func _on_mission_completed(m_idx: int, results: Dictionary) -> void:
	audio_director.set_audio_state(StrikeAudioDirectorScript.AudioState.VICTORY)
	campaign_mgr.on_mission_completed(m_idx, results)
	results_screen.display_results(results)

func _on_next_mission_requested() -> void:
	results_screen.hide_results()
	var next_m = campaign_mgr.get_next_mission_index()
	load_mission(next_m)

func restart_mission() -> void:
	results_screen.hide_results()
	load_mission(mission_mgr.mission_index)

func _on_resume() -> void:
	var im = GameConstants.get_autoload(self, "InputManager")
	if im and im.has_method("capture_mouse"):
		im.capture_mouse(true)

func _on_quit_to_launcher() -> void:
	var gm = GameConstants.get_autoload(self, "GameManager")
	if gm and gm.has_method("return_to_launcher"):
		gm.return_to_launcher()
