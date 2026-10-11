class_name AeroWorldBase
extends Node3D

## Base environment coordinator for AeroRush: Impossible Circuit.
## Manages atmospheric lighting, sky, directional sun, fog, terrain bed,
## and instancing of high-fidelity architectural structures and realistic vegetation.

const ModelCache = preload("res://shared/graphics/model_cache.gd")
const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")


var sun_light: DirectionalLight3D = null
var world_env: WorldEnvironment = null

func setup_lighting(sun_color: Color, sun_energy: float, sun_rot: Vector3, sky_top: Color, sky_horizon: Color, fog_col: Color, fog_density: float = 0.0012) -> void:
	# 1. Directional Sun (Key Light)
	sun_light = DirectionalLight3D.new()
	sun_light.name = "AeroSunLight"
	sun_light.light_color = sun_color
	sun_light.light_energy = sun_energy
	sun_light.shadow_enabled = true
	sun_light.shadow_bias = 0.03
	sun_light.shadow_normal_bias = 1.2
	sun_light.shadow_blur = 1.5
	sun_light.rotation_degrees = sun_rot
	add_child(sun_light)

	# 2. Upward Ground Fill Light (Eliminates crushed pitch-black shadows on track undersides)
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "AeroGroundFillLight"
	fill_light.light_color = sky_horizon.lerp(Color(0.85, 0.90, 1.0), 0.5)
	fill_light.light_energy = 0.55
	fill_light.shadow_enabled = false
	fill_light.rotation_degrees = Vector3(55.0, sun_rot.y + 180.0, 0.0)
	add_child(fill_light)

	# 3. World Environment with Rich Ambient Sky Lighting
	world_env = WorldEnvironment.new()
	world_env.name = "AeroWorldEnv"
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY

	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = sky_top
	sky_mat.sky_horizon_color = sky_horizon
	sky_mat.ground_bottom_color = sky_horizon.lerp(Color(0.2, 0.22, 0.25), 0.5)
	sky_mat.ground_horizon_color = sky_horizon
	sky_mat.sun_angle_max = 35.0
	sky.sky_material = sky_mat
	env.sky = sky

	# Ambient Sky Light: Guarantees visible surface details even in deep shadows
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.70, 0.74, 0.82)
	env.ambient_light_energy = 1.15
	env.ambient_light_sky_contribution = 0.80

	# Volumetric Fog & Atmospheric Depth
	env.fog_enabled = true
	env.fog_light_color = fog_col
	env.fog_density = fog_density
	env.fog_aerial_perspective = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.12
	env.glow_bloom = 0.01

	world_env.environment = env
	add_child(world_env)

func create_ground_bed(size: float, mat: Material, elevation: float = -0.5) -> MeshInstance3D:
	var ground = MeshInstance3D.new()
	ground.name = "ContinuousTerrainBed"
	var plane = PlaneMesh.new()
	plane.size = Vector2(size, size)
	ground.mesh = plane
	ground.material_override = mat
	ground.position = Vector3(0, elevation, 0)
	add_child(ground)

	var sb = StaticBody3D.new()
	sb.name = "GroundCollisionBody"
	sb.collision_layer = AeroConstants.LAYER_WORLD
	sb.collision_mask = 0
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(size, 1.0, size)
	col.shape = box
	col.position = Vector3(0, -0.5, 0)
	sb.add_child(col)
	ground.add_child(sb)

	return ground

func spawn_tree(tree_model_path: String, pos: Vector3, scale_range: Vector2 = Vector2(0.85, 1.35)) -> Node3D:
	var tree = ModelCache.get_model(tree_model_path)
	if not tree:
		return null
	var s = randf_range(scale_range.x, scale_range.y)
	tree.scale = Vector3(s, s, s)
	tree.rotation_degrees.y = randf_range(0.0, 360.0)
	tree.position = pos
	add_child(tree)
	return tree

func spawn_building(model_path: String, pos: Vector3, rot_y: float = 0.0, scale_mult: Vector3 = Vector3.ONE) -> Node3D:
	var bld = ModelCache.get_model(model_path)
	if not bld:
		return null
	bld.position = pos
	bld.rotation_degrees.y = rot_y
	bld.scale = scale_mult
	add_child(bld)
	return bld

## Extracts all course waypoints and island jump gaps into a unified trajectory list
func get_course_polyline(course_def: Dictionary) -> Array[Dictionary]:
	var points: Array[Dictionary] = []
	if course_def.has("islands"):
		var islands = course_def.get("islands", []) as Array
		for idx in range(islands.size()):
			var isl = islands[idx] as Dictionary
			var wps = isl.get("waypoints", []) as Array
			for wp in wps:
				points.append(wp)
			# If there is a next island, link last waypoint of current to first waypoint of next
			if idx + 1 < islands.size():
				var next_isl = islands[idx + 1] as Dictionary
				var next_wps = next_isl.get("waypoints", []) as Array
				if not wps.is_empty() and not next_wps.is_empty():
					var last_wp = wps[-1] as Dictionary
					var first_next_wp = next_wps[0] as Dictionary
					# Add ballistic flight midpoint for jump gap
					var mid_pos = (last_wp.get("pos", Vector3.ZERO) + first_next_wp.get("pos", Vector3.ZERO)) * 0.5 + Vector3(0, 16.0, 0)
					points.append({"pos": mid_pos, "width": 30.0, "is_jump_arc": true})
	elif course_def.has("waypoints"):
		var wps = course_def.get("waypoints", []) as Array
		for wp in wps:
			points.append(wp)
	return points

## Authoritative swept-volume test: checks if a 3D position is within the track driving or camera corridor
func is_point_in_corridor(pos: Vector3, course_def: Dictionary, min_horizontal: float = 28.0, min_vert_down: float = 6.0, min_vert_up: float = 38.0) -> bool:
	var pts = get_course_polyline(course_def)
	if pts.size() < 2:
		return false

	for i in range(pts.size() - 1):
		var p1 = pts[i].get("pos", Vector3.ZERO) as Vector3
		var p2 = pts[i + 1].get("pos", Vector3.ZERO) as Vector3
		var w = maxf(float(pts[i].get("width", 18.0)), float(pts[i + 1].get("width", 18.0)))
		var req_h_dist = min_horizontal + (w * 0.5)

		var seg = p2 - p1
		var seg_len_sq = seg.length_squared()
		var t = 0.0
		if seg_len_sq > 0.001:
			t = clampf((pos - p1).dot(seg) / seg_len_sq, 0.0, 1.0)
		var closest = p1 + seg * t

		var h_dist = Vector2(pos.x - closest.x, pos.z - closest.z).length()
		var y_diff = pos.y - closest.y

		if h_dist < req_h_dist and y_diff >= -min_vert_down and y_diff <= min_vert_up:
			return true
	return false

## Swept-volume scenery pruning engine: automatically removes any world props, buildings, or trees
## that intersect the vehicle driving envelope, camera clearance, or ballistic jump arcs.
func prune_scenery_in_corridor(course_def: Dictionary) -> int:
	var pruned_count: int = 0
	var nodes_to_check: Array[Node] = []
	for child in get_children():
		nodes_to_check.append(child)

	for node in nodes_to_check:
		if node is DirectionalLight3D or node is WorldEnvironment:
			continue
		if node.name.begins_with("ContinuousTerrain") or node.name.begins_with("GroundCollision"):
			continue

		var check_pos = Vector3.ZERO
		if node is Node3D:
			check_pos = (node as Node3D).position

		if is_point_in_corridor(check_pos, course_def):
			print("[AeroWorldBase] Pruned corridor-obstructing scenery: %s at %s" % [node.name, str(check_pos)])
			node.queue_free()
			pruned_count += 1

	return pruned_count

