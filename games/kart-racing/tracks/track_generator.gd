class_name TrackGenerator
extends Node3D

signal track_built(waypoints: Array[Vector3], checkpoints: Array[RaceCheckpoint])

@export var track_theme: String = "metropolis" # "metropolis", "canyon", "frozen"
@export var track_width: float = 14.0

var waypoints: Array[Vector3] = []
var checkpoints: Array[RaceCheckpoint] = []

func _ready() -> void:
	build_circuit()

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

func build_circuit() -> void:
	var circuit_nodes: Array[Vector3] = []
	match track_theme.to_lower():
		"canyon":
			# Canyon Run: 18 Waypoints, ~720m expansive canyon circuit with elevation changes & mesa bridges
			circuit_nodes = [
				Vector3(0, 0, 0),           # 0: Start / Finish Line in Gorge
				Vector3(0, 0, -50),         # 1: Canyon Gorge Straight
				Vector3(20, 1.2, -100),     # 2: Turn 1 Canyon Incline Entry
				Vector3(60, 3.5, -145),     # 3: Climbing the Red Ridge
				Vector3(110, 6.0, -165),    # 4: Mesa High Plains Crest
				Vector3(170, 7.5, -150),    # 5: High Desert Mesa Straight
				Vector3(220, 8.0, -105),    # 6: Canyon Rim Bridge Approach
				Vector3(235, 7.5, -50),     # 7: Overlook Turn 2
				Vector3(225, 6.0, 10),      # 8: Sandstone Ridge Descent
				Vector3(190, 4.0, 60),      # 9: Hairpin Entry
				Vector3(150, 2.5, 95),      # 10: Hairpin Apex at Monolith
				Vector3(100, 1.0, 110),     # 11: Downhill Gorge Plunge
				Vector3(55, 0.0, 90),       # 12: Valley S-Curve Left
				Vector3(30, -0.5, 60),      # 13: Under Mesa Arch
				Vector3(15, 0.0, 35),       # 14: Final Chicane Right
				Vector3(5, 0.0, 18)         # 15: Exit to Home Straight
			]
			# Vast Red Rock Canyon Floor
			create_box(Vector3(110.0, -0.8, -25.0), Vector3(550.0, 1.0, 550.0), "canyon_rock")
			# Sandstone Mesa Formations and Natural Rock Arches
			for p in [Vector3(-45, 18, -80), Vector3(85, 24, -190), Vector3(260, 22, -40), Vector3(85, 20, 135), Vector3(-35, 16, 60), Vector3(175, 14, 25)]:
				create_box(p, Vector3(52.0, 36.0, 52.0), "canyon_rock")

		"skyline":
			# Skyline Drift: 18 Waypoints, ~760m high-altitude metropolitan highway circuit
			circuit_nodes = [
				Vector3(0, 0, 0),           # 0: Start / Finish Line
				Vector3(0, 0, -55),         # 1: Main Expressway Straight
				Vector3(15, 1.0, -110),     # 2: Turn 1 Highway Ramp Incline
				Vector3(45, 3.5, -160),     # 3: Rooftop Approach
				Vector3(95, 6.0, -190),     # 4: High Flyover Curve
				Vector3(155, 7.5, -195),    # 5: Skyline Flyover Straight
				Vector3(210, 6.5, -170),    # 6: Downtown Corner Right
				Vector3(240, 4.5, -115),    # 7: Descent to Tech Boulevard
				Vector3(235, 2.0, -55),     # 8: Lower Boulevard Sector
				Vector3(205, 0.5, 0),       # 9: Commercial Hairpin Entry
				Vector3(165, 0.0, 45),      # 10: Hairpin Apex
				Vector3(120, 0.0, 75),      # 11: Underpass Chute
				Vector3(75, 0.0, 70),       # 12: Avenue S-Bend Left
				Vector3(45, 0.0, 45),       # 13: Avenue S-Bend Right
				Vector3(20, 0.0, 22)        # 14: Final Plaza Chicane
			]
			# Metropolis Asphalt Base
			create_box(Vector3(115.0, -0.8, -55.0), Vector3(550.0, 1.0, 550.0), "asphalt")
			# Production 3D Skyscrapers & Megastructure Towers
			var building_coords = [
				[Vector3(-45, 0, -75), "a", Vector3(5, 10, 5)],
				[Vector3(75, 0, -210), "b", Vector3(6, 12, 6)],
				[Vector3(175, 0, -215), "c", Vector3(5, 11, 5)],
				[Vector3(265, 0, -60), "d", Vector3(6, 14, 6)],
				[Vector3(155, 0, 95), "a", Vector3(5, 9, 5)],
				[Vector3(-30, 0, 70), "garage", Vector3(4, 4, 4)]
			]
			for bc in building_coords:
				var bld = ModelCacheScript.get_building(bc[1])
				if bld:
					bld.position = bc[0]
					bld.scale = bc[2]
					add_child(bld)
				else:
					create_box(bc[0] + Vector3(0, 25, 0), Vector3(40, 50, 40), "dark_concrete")

		_: # "neon" / "metropolis" (Neon Circuit)
			# Neon Circuit: 16 Waypoints, ~680m high-speed night stadium motorsport complex
			circuit_nodes = [
				Vector3(0, 0, 0),           # 0: Start / Finish Line
				Vector3(0, 0, -50),         # 1: Main Straight past Pit Lane
				Vector3(12, 0, -100),       # 2: Turn 1 High-speed Right Sweeper
				Vector3(42, 0.5, -145),     # 3: Banked Turn 1 Apex
				Vector3(88, 1.0, -168),     # 4: Exit to Neon Boulevard
				Vector3(145, 1.0, -168),    # 5: Long Neon Boulevard Straight
				Vector3(195, 0.5, -140),    # 6: Turn 2 Entry (Right Curve)
				Vector3(215, 0.0, -90),     # 7: Technical Arena Sector
				Vector3(205, 0.0, -35),     # 8: Stadium Hairpin Entry
				Vector3(170, 0.0, 15),      # 9: Stadium Hairpin Apex
				Vector3(125, 0.0, 40),      # 10: Grandstand Flyover
				Vector3(80, 0.0, 60),       # 11: S-Bend Left
				Vector3(45, 0.0, 45),       # 12: S-Bend Right
				Vector3(18, 0.0, 22)        # 13: Final Chicane to Main Straight
			]
			# Metropolis Ground Surface
			create_box(Vector3(105.0, -0.8, -50.0), Vector3(500.0, 1.0, 500.0), "asphalt")
			# Stadium Paddock, Pit Garages and High-Rise Facilities
			var neon_props = [
				[Vector3(-35, 0, -70), "garage", Vector3(4, 4, 4)],
				[Vector3(70, 0, -190), "a", Vector3(5, 8, 5)],
				[Vector3(160, 0, -190), "b", Vector3(5, 9, 5)],
				[Vector3(235, 0, -55), "c", Vector3(5, 10, 5)],
				[Vector3(150, 0, 80), "d", Vector3(5, 8, 5)]
			]
			for np in neon_props:
				var b = ModelCacheScript.get_building(np[1])
				if b:
					b.position = np[0]
					b.scale = np[2]
					add_child(b)
				else:
					create_box(np[0] + Vector3(0, 20, 0), Vector3(36, 40, 36), "dark_concrete")

	waypoints = circuit_nodes

	# Build track segments between sequential nodes
	for i in range(circuit_nodes.size()):
		var p1 = circuit_nodes[i]
		var p2 = circuit_nodes[(i + 1) % circuit_nodes.size()]
		build_track_segment(p1, p2, i)

	# Start/Finish Overhead Gantry (Production glTF Arch or Truss)
	var finish_prop = ModelCacheScript.get_prop("track_finish")
	if finish_prop:
		finish_prop.position = circuit_nodes[0] + Vector3(0, 0, -1.0)
		finish_prop.scale = Vector3(3.5, 3.5, 3.5)
		add_child(finish_prop)
	else:
		var gantry = MeshBuilder.build_start_gantry(track_width)
		gantry.position = circuit_nodes[0] + Vector3(0, 0, -2.0)
		add_child(gantry)

	# Production Road Lightposts along the straightaways
	for wp_idx in [1, 5, 8, 11]:
		if wp_idx < circuit_nodes.size():
			var lp = ModelCacheScript.get_prop("road_lightposts")
			if lp:
				lp.position = circuit_nodes[wp_idx] + Vector3(-track_width * 0.5 - 2.5, 0, 0)
				lp.scale = Vector3(2.0, 2.0, 2.0)
				add_child(lp)

	# Grandstands with Spectators along Main Straight (Left & Right)
	var stand_left = MeshBuilder.build_stadium_grandstand(55.0, 8.0, 10.0)
	stand_left.position = Vector3(-track_width * 0.5 - 6.5, 0.0, -25.0)
	add_child(stand_left)

	var stand_right = MeshBuilder.build_stadium_grandstand(55.0, 8.0, 10.0)
	stand_right.position = Vector3(track_width * 0.5 + 6.5, 0.0, -25.0)
	stand_right.rotation_degrees.y = 180.0
	add_child(stand_right)

	# Stadium Floodlight Towers
	var tower1 = MeshBuilder.build_stadium_floodlight_tower(24.0)
	tower1.position = Vector3(-track_width * 0.5 - 12.0, 0.0, -48.0)
	add_child(tower1)

	var tower2 = MeshBuilder.build_stadium_floodlight_tower(24.0)
	tower2.position = Vector3(track_width * 0.5 + 12.0, 0.0, -48.0)
	tower2.rotation_degrees.y = 180.0
	add_child(tower2)

	# Place item box powerups around the circuit
	var item_indices = [1, int(circuit_nodes.size() * 0.35), int(circuit_nodes.size() * 0.65), int(circuit_nodes.size() * 0.85)]
	for idx in item_indices:
		var item = PowerUpItem.new()
		item.position = circuit_nodes[idx] + Vector3(0, 0.3, 0)
		add_child(item)

	setup_racing_environment()
	track_built.emit(waypoints, checkpoints)

func build_track_segment(start_pt: Vector3, end_pt: Vector3, segment_index: int) -> void:
	var delta = end_pt - start_pt
	var seg_length = delta.length()
	var center = start_pt + delta * 0.5
	var angle_y = atan2(-delta.x, -delta.z)

	# Asphalt road slab with PBR aggregate texture & lane lines
	var road = StaticBody3D.new()
	road.collision_layer = GameConstants.LAYER_WORLD
	road.position = center
	road.rotation.y = angle_y

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(track_width, 0.5, seg_length + 2.0)
	col.shape = box
	road.add_child(col)

	var mesh = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(track_width, 0.5, seg_length + 2.0)
	mesh.mesh = b_mesh
	mesh.material_override = MaterialGenerator.get_material("asphalt_track")
	road.add_child(mesh)

	# Red/White Ripple Rumble Curbs along both sides of the racing line
	var curb_mesh = BoxMesh.new()
	curb_mesh.size = Vector3(0.8, 0.15, seg_length + 2.0)
	var curb_mat = MaterialGenerator.get_material("curb_stripes")

	var curb_l = MeshInstance3D.new()
	curb_l.mesh = curb_mesh
	curb_l.position = Vector3(-track_width * 0.5 + 0.4, 0.28, 0)
	curb_l.material_override = curb_mat
	road.add_child(curb_l)

	var curb_r = MeshInstance3D.new()
	curb_r.mesh = curb_mesh
	curb_r.position = Vector3(track_width * 0.5 - 0.4, 0.28, 0)
	curb_r.material_override = curb_mat
	road.add_child(curb_r)

	# Continuous Physical Crash Barriers along both flanks with COLLISION SHAPES
	var rail_w = 0.6
	var rail_h = 2.0

	var left_rail = MeshInstance3D.new()
	var r_mesh = BoxMesh.new()
	r_mesh.size = Vector3(rail_w, rail_h, seg_length + 2.0)
	left_rail.mesh = r_mesh
	left_rail.position = Vector3(-track_width * 0.5 - rail_w * 0.5, rail_h * 0.5, 0)
	left_rail.material_override = MaterialGenerator.get_material("neon_magenta")
	road.add_child(left_rail)

	var right_rail = MeshInstance3D.new()
	right_rail.mesh = r_mesh
	right_rail.position = Vector3(track_width * 0.5 + rail_w * 0.5, rail_h * 0.5, 0)
	right_rail.material_override = MaterialGenerator.get_material("neon_cyan")
	road.add_child(right_rail)

	# Left physical barrier collider
	var col_l = CollisionShape3D.new()
	var bar_shape_l = BoxShape3D.new()
	bar_shape_l.size = Vector3(rail_w, rail_h + 1.2, seg_length + 2.0)
	col_l.shape = bar_shape_l
	col_l.position = Vector3(-track_width * 0.5 - rail_w * 0.5, rail_h * 0.5 + 0.3, 0)
	road.add_child(col_l)

	# Right physical barrier collider
	var col_r = CollisionShape3D.new()
	var bar_shape_r = BoxShape3D.new()
	bar_shape_r.size = Vector3(rail_w, rail_h + 1.2, seg_length + 2.0)
	col_r.shape = bar_shape_r
	col_r.position = Vector3(track_width * 0.5 + rail_w * 0.5, rail_h * 0.5 + 0.3, 0)
	road.add_child(col_r)

	# Outer safety tire wall at apex
	var tire_wall = MeshInstance3D.new()
	var tw_mesh = BoxMesh.new()
	tw_mesh.size = Vector3(0.8, 1.2, seg_length + 2.0)
	tire_wall.mesh = tw_mesh
	tire_wall.position = Vector3(track_width * 0.5 + 1.1, 0.6, 0)
	tire_wall.material_override = MaterialGenerator.get_material("dark_hull")
	road.add_child(tire_wall)

	add_child(road)

	# Add checkpoint at the start of each segment
	var cp = RaceCheckpoint.new()
	cp.checkpoint_index = segment_index
	cp.is_finish_line = (segment_index == 0)
	cp.checkpoint_width = track_width
	cp.position = start_pt + Vector3(0, 0.5, 0)
	cp.rotation.y = angle_y
	add_child(cp)
	checkpoints.append(cp)

func create_box(pos: Vector3, size: Vector3, material_name: String) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = GameConstants.LAYER_WORLD
	body.collision_mask = 0
	body.position = pos

	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape
	body.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.material_override = MaterialGenerator.get_material(material_name)
	body.add_child(mesh_inst)

	add_child(body)
	return body

func setup_racing_environment() -> void:
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	var sky_mat = ProceduralSkyMaterial.new()

	match track_theme.to_lower():
		"canyon":
			# High desert golden sun with sandstone dust atmosphere
			sky_mat.sky_top_color = Color(0.20, 0.45, 0.85)
			sky_mat.sky_horizon_color = Color(0.85, 0.65, 0.45)
			sky_mat.ground_bottom_color = Color(0.35, 0.20, 0.12)
			sky_mat.ground_horizon_color = Color(0.70, 0.45, 0.30)
			environment.ambient_light_color = Color(0.75, 0.55, 0.40)
			environment.ambient_light_energy = 1.2
			environment.fog_enabled = true
			environment.fog_light_color = Color(0.80, 0.60, 0.45)
			environment.fog_density = 0.0015
		"skyline":
			# High-altitude sunset / twilight metropolitan horizon
			sky_mat.sky_top_color = Color(0.12, 0.18, 0.42)
			sky_mat.sky_horizon_color = Color(0.88, 0.40, 0.28)
			sky_mat.ground_bottom_color = Color(0.08, 0.08, 0.15)
			sky_mat.ground_horizon_color = Color(0.40, 0.22, 0.35)
			environment.ambient_light_color = Color(0.45, 0.40, 0.65)
			environment.ambient_light_energy = 1.1
			environment.fog_enabled = true
			environment.fog_light_color = Color(0.50, 0.30, 0.45)
			environment.fog_density = 0.0012
		_: # "neon" / "metropolis"
			# Night motorsport complex under brilliant stadium floodlights & cyber ambient glow
			sky_mat.sky_top_color = Color(0.12, 0.20, 0.42)
			sky_mat.sky_horizon_color = Color(0.24, 0.38, 0.65)
			sky_mat.ground_bottom_color = Color(0.10, 0.14, 0.22)
			sky_mat.ground_horizon_color = Color(0.16, 0.24, 0.38)
			environment.ambient_light_color = Color(0.60, 0.70, 0.90)
			environment.ambient_light_energy = 1.6
			environment.fog_enabled = false

	var sky = Sky.new()
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.35
	environment.tonemap_white = 6.0

	environment.glow_enabled = true
	environment.glow_intensity = 0.45
	environment.glow_bloom = 0.18

	env.environment = environment
	add_child(env)

	# Primary Track Lighting
	var sun = DirectionalLight3D.new()
	if track_theme.to_lower() == "neon":
		sun.rotation_degrees = Vector3(-65, 30, 0)
		sun.light_color = Color(0.85, 0.92, 1.0)
		sun.light_energy = 1.8
	elif track_theme.to_lower() == "canyon":
		sun.rotation_degrees = Vector3(-45, 55, 0)
		sun.light_color = Color(1.0, 0.92, 0.80)
		sun.light_energy = 2.4
	else:
		sun.rotation_degrees = Vector3(-50, 40, 0)
		sun.light_color = Color(1.0, 0.88, 0.82)
		sun.light_energy = 2.0
	sun.shadow_enabled = true
	add_child(sun)

	# Fill Light
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(40, -140, 0)
	fill.light_color = Color(0.35, 0.50, 0.80)
	fill.light_energy = 0.7
	fill.shadow_enabled = false
	add_child(fill)
