class_name StrikePickup
extends Area3D

## World pickups for Strike Vector:
## Ammo, Health, Armor, Grenades, and 6 Arcade Power Modules.
## Uses authentic 3D military models and holographic tactical markers.

signal picked_up(pickup_type: String, value: int, player: Node)

enum PickupCategory {
	AMMO,
	HEALTH,
	ARMOR,
	GRENADES,
	ARCADE_MODULE
}

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

@export var pickup_category: PickupCategory = PickupCategory.AMMO
@export var pickup_type: String = "ammo_pack" # "ammo_pack", "health_pack", "armor_pack", "grenade_pack", "mod_rapid_fire", ...
@export var pickup_value: int = 50
@export var respawn_time_sec: float = 0.0 # 0.0 means single-use per mission

var is_active: bool = true
var visual_mesh: Node3D
var rotation_speed: float = 1.8
var bob_speed: float = 2.4
var bob_height: float = 0.12
var base_y: float = 0.0
var elapsed: float = 0.0

func _ready() -> void:
	add_to_group("pickups")
	collision_layer = GameConstants.LAYER_PICKUPS
	collision_mask = GameConstants.LAYER_PLAYER
	base_y = position.y

	_setup_collision()
	_setup_visual()
	body_entered.connect(_on_body_entered)

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 1.4
	col.shape = sphere
	col.position = Vector3(0, 0.4, 0)
	add_child(col)

func _setup_visual() -> void:
	visual_mesh = Node3D.new()
	visual_mesh.name = "Visual"

	var color = Color(0.2, 0.9, 1.0)
	match pickup_category:
		PickupCategory.HEALTH: color = Color(0.2, 1.0, 0.4) # Green
		PickupCategory.ARMOR: color = Color(0.1, 0.6, 1.0) # Blue
		PickupCategory.AMMO: color = Color(1.0, 0.75, 0.1) # Amber
		PickupCategory.GRENADES: color = Color(1.0, 0.3, 0.2) # Red
		PickupCategory.ARCADE_MODULE: color = Color(0.9, 0.2, 1.0) # Magenta/Purple

	match pickup_category:
		PickupCategory.AMMO:
			# Authentic 3D Ammo Box Model
			var m = ModelCacheScript.get_model("res://assets/models/weapons/ammo_box.glb")
			if m:
				m.scale = Vector3(1.2, 1.2, 1.2)
				visual_mesh.add_child(m)
			else:
				_build_fallback_case(visual_mesh, color, Vector3(0.55, 0.35, 0.35))
		PickupCategory.HEALTH:
			# High-tech Nanomed Kit
			_build_medkit_model(visual_mesh, color)
		PickupCategory.ARMOR:
			# Ballistic Nanoweave Shield Plate
			_build_armor_plate_model(visual_mesh, color)
		PickupCategory.GRENADES:
			# Tactical Frag Grenade Canister
			_build_grenade_canister(visual_mesh, color)
		PickupCategory.ARCADE_MODULE:
			# Crystalline Data Holocron
			_build_holocron_module(visual_mesh, color)

	# Holographic ground pulse ring
	var ground_ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.65
	ground_ring.mesh = torus
	var mat_ring = StandardMaterial3D.new()
	mat_ring.albedo_color = color
	mat_ring.emission_enabled = true
	mat_ring.emission = color
	mat_ring.emission_energy_multiplier = 2.0
	ground_ring.material_override = mat_ring
	ground_ring.position = Vector3(0, -0.3, 0)
	visual_mesh.add_child(ground_ring)

	# Proximity status beacon
	var light = OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.2
	light.omni_range = 3.5
	light.position = Vector3(0, 0.4, 0)
	visual_mesh.add_child(light)

	add_child(visual_mesh)

func _build_fallback_case(root: Node3D, color: Color, size: Vector3) -> void:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.22, 0.25)
	mat.metallic = 0.8
	mat.roughness = 0.3
	mi.material_override = mat
	root.add_child(mi)

	var band = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(size.x + 0.02, size.y * 0.4, size.z + 0.02)
	band.mesh = b_box
	var mat_b = StandardMaterial3D.new()
	mat_b.albedo_color = color
	mat_b.emission_enabled = true
	mat_b.emission = color
	mat_b.emission_energy_multiplier = 2.5
	band.material_override = mat_b
	root.add_child(band)

func _build_medkit_model(root: Node3D, color: Color) -> void:
	_build_fallback_case(root, color, Vector3(0.5, 0.38, 0.22))
	# Green Cross symbol
	var mat_cross = StandardMaterial3D.new()
	mat_cross.albedo_color = Color(0.2, 1.0, 0.4)
	mat_cross.emission_enabled = true
	mat_cross.emission = Color(0.2, 1.0, 0.4)
	mat_cross.emission_energy_multiplier = 3.0

	var c_v = MeshInstance3D.new()
	var box_v = BoxMesh.new()
	box_v.size = Vector3(0.08, 0.24, 0.24)
	c_v.mesh = box_v
	c_v.material_override = mat_cross
	c_v.position = Vector3(0, 0, 0.12)
	root.add_child(c_v)

	var c_h = MeshInstance3D.new()
	var box_h = BoxMesh.new()
	box_h.size = Vector3(0.24, 0.08, 0.24)
	c_h.mesh = box_h
	c_h.material_override = mat_cross
	c_h.position = Vector3(0, 0, 0.12)
	root.add_child(c_h)

func _build_armor_plate_model(root: Node3D, color: Color) -> void:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.48, 0.58, 0.14)
	mi.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.16, 0.22)
	mat.metallic = 0.9
	mat.roughness = 0.25
	mi.material_override = mat
	root.add_child(mi)

	var trim = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.50, 0.12, 0.16)
	trim.mesh = t_box
	var mat_t = StandardMaterial3D.new()
	mat_t.albedo_color = color
	mat_t.emission_enabled = true
	mat_t.emission = color
	mat_t.emission_energy_multiplier = 3.2
	trim.material_override = mat_t
	root.add_child(trim)

func _build_grenade_canister(root: Node3D, color: Color) -> void:
	var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.15
	cyl.bottom_radius = 0.15
	cyl.height = 0.45
	mi.mesh = cyl
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.20, 0.16)
	mat.metallic = 0.7
	mat.roughness = 0.4
	mi.material_override = mat
	root.add_child(mi)

	var ring = MeshInstance3D.new()
	var r_cyl = CylinderMesh.new()
	r_cyl.top_radius = 0.16
	r_cyl.bottom_radius = 0.16
	r_cyl.height = 0.10
	ring.mesh = r_cyl
	var mat_r = StandardMaterial3D.new()
	mat_r.albedo_color = color
	mat_r.emission_enabled = true
	mat_r.emission = color
	mat_r.emission_energy_multiplier = 3.5
	ring.material_override = mat_r
	root.add_child(ring)

func _build_holocron_module(root: Node3D, color: Color) -> void:
	var mi = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(0.48, 0.55, 0.48)
	mi.mesh = prism
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.5
	mi.material_override = mat
	root.add_child(mi)

func _process(delta: float) -> void:
	if not is_active:
		return
	elapsed += delta
	if is_instance_valid(visual_mesh):
		visual_mesh.rotate_y(rotation_speed * delta)
		visual_mesh.position.y = sin(elapsed * bob_speed) * bob_height

func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return
	if body.is_in_group("players") or body.has_method("apply_pickup"):
		is_active = false
		visible = false
		set_physics_process(false)

		var am = GameConstants.get_autoload(self, "AudioManager")
		if am and am.has_method("play_sound"):
			am.play_sound("pickup", 1.0)

		if body.has_method("apply_pickup"):
			body.apply_pickup(pickup_type, pickup_value)

		picked_up.emit(pickup_type, pickup_value, body)

		if respawn_time_sec > 0.0:
			var tree = get_tree()
			if tree:
				tree.create_timer(respawn_time_sec).timeout.connect(_respawn)
		else:
			queue_free()

func _respawn() -> void:
	is_active = true
	visible = true
	set_physics_process(true)
