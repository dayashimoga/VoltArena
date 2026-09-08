class_name StrikeWeaponArsenal
extends RefCounted

## Factory for all 9 production weapons in Strike Vector.
## Creates fully configured StrikeWeaponBase instances with complete visual meshes and sockets.

const StrikeWeaponBaseScript = preload("res://games/strike-vector/weapons/strike_weapon_base.gd")

static func create_weapon_by_id(weapon_id: String) -> Node3D:
	match weapon_id:
		"vx7_assault": return create_vx7_assault()
		"tempest_smg": return create_tempest_smg()
		"breach_shotgun": return create_breach_shotgun()
		"atlas_battle_rifle": return create_atlas_battle_rifle()
		"longshot_marksman": return create_longshot_marksman()
		"cyclone_lmg": return create_cyclone_lmg()
		"arc_launcher": return create_arc_launcher()
		"pulse_cannon": return create_pulse_cannon()
		"tactical_sidearm": return create_tactical_sidearm()
		_: return create_vx7_assault()

static func get_all_weapon_ids() -> Array[String]:
	return [
		"vx7_assault", "tempest_smg", "breach_shotgun",
		"atlas_battle_rifle", "longshot_marksman", "cyclone_lmg",
		"arc_launcher", "pulse_cannon", "tactical_sidearm"
	]

# 1. VX-7 Assault Rifle — balanced automatic
static func create_vx7_assault() -> Node3D:
	var w = StrikeWeaponBaseScript.new()
	w.name = "VX7_AssaultRifle"
	w.weapon_id = "vx7_assault"
	w.weapon_name = "VX-7 Assault Rifle"
	w.damage = 25.0
	w.fire_rate_rpm = 650.0
	w.magazine_capacity = 30
	w.max_reserve_ammo = 150
	w.reload_time_sec = 2.1
	w.base_spread_deg = 1.1
	w.recoil_pitch_deg = 1.3
	w.projectile_speed = 135.0
	w.projectile_color = Color(0.1, 0.95, 1.0) # Cyan
	w.sound_fire_key = "laser_fire"
	_attach_visual(w, "vx7", Color(0.1, 0.95, 1.0))
	return w

# 2. Tempest SMG — fast movement / high RPM
static func create_tempest_smg() -> Node3D:
	var w = StrikeWeaponBaseScript.new()
	w.name = "Tempest_SMG"
	w.weapon_id = "tempest_smg"
	w.weapon_name = "Tempest SMG"
	w.damage = 18.0
	w.fire_rate_rpm = 950.0
	w.magazine_capacity = 40
	w.max_reserve_ammo = 240
	w.reload_time_sec = 1.6
	w.base_spread_deg = 1.8
	w.recoil_pitch_deg = 0.9
	w.projectile_speed = 120.0
	w.projectile_color = Color(0.2, 1.0, 0.4) # Neon Green
	w.sound_fire_key = "laser_fire"
	_attach_visual(w, "tempest", Color(0.2, 1.0, 0.4))
	return w

# 3. Breach Shotgun — close spread
static func create_breach_shotgun() -> Node3D:
	var w = StrikeWeaponBaseScript.new()
	w.name = "Breach_Shotgun"
	w.weapon_id = "breach_shotgun"
	w.weapon_name = "Breach Shotgun"
	w.damage = 16.0 # per pellet
	w.pellets_per_shot = 8
	w.fire_rate_rpm = 85.0
	w.magazine_capacity = 8
	w.max_reserve_ammo = 48
	w.reload_time_sec = 2.4
	w.base_spread_deg = 3.6
	w.recoil_pitch_deg = 3.8
	w.projectile_speed = 110.0
	w.projectile_color = Color(1.0, 0.55, 0.05) # Neon Orange
	w.sound_fire_key = "shotgun_fire"
	_attach_visual(w, "breach", Color(1.0, 0.55, 0.05))
	return w

# 4. Atlas Battle Rifle — high-damage burst / semi-auto
static func create_atlas_battle_rifle() -> Node3D:
	var w = StrikeWeaponBaseScript.new()
	w.name = "Atlas_BattleRifle"
	w.weapon_id = "atlas_battle_rifle"
	w.weapon_name = "Atlas Battle Rifle"
	w.damage = 38.0
	w.fire_rate_rpm = 420.0
	w.magazine_capacity = 24
	w.max_reserve_ammo = 96
	w.reload_time_sec = 2.2
	w.base_spread_deg = 0.6
	w.recoil_pitch_deg = 2.0
	w.projectile_speed = 160.0
	w.projectile_color = Color(1.0, 0.85, 0.1) # Amber Gold
	w.sound_fire_key = "plasma_fire"
	_attach_visual(w, "atlas", Color(1.0, 0.85, 0.1))
	return w

# 5. Longshot Marksman — precision sniper
static func create_longshot_marksman() -> Node3D:
	var w = StrikeWeaponBaseScript.new()
	w.name = "Longshot_Marksman"
	w.weapon_id = "longshot_marksman"
	w.weapon_name = "Longshot Marksman"
	w.damage = 90.0
	w.fire_rate_rpm = 120.0
	w.magazine_capacity = 10
	w.max_reserve_ammo = 40
	w.reload_time_sec = 2.8
	w.base_spread_deg = 0.15
	w.recoil_pitch_deg = 4.2
	w.projectile_speed = 220.0
	w.projectile_color = Color(0.1, 0.4, 1.0) # Deep Electric Blue
	w.sound_fire_key = "railgun_fire"
	_attach_visual(w, "longshot", Color(0.1, 0.4, 1.0))
	return w

# 6. Cyclone LMG — sustained fire / large magazine
static func create_cyclone_lmg() -> Node3D:
	var w = StrikeWeaponBaseScript.new()
	w.name = "Cyclone_LMG"
	w.weapon_id = "cyclone_lmg"
	w.weapon_name = "Cyclone LMG"
	w.damage = 22.0
	w.fire_rate_rpm = 550.0
	w.magazine_capacity = 100
	w.max_reserve_ammo = 200
	w.reload_time_sec = 3.6
	w.base_spread_deg = 1.6
	w.recoil_pitch_deg = 1.6
	w.projectile_speed = 130.0
	w.projectile_color = Color(1.0, 0.3, 0.3) # Crimson Red
	w.sound_fire_key = "plasma_fire"
	_attach_visual(w, "cyclone", Color(1.0, 0.3, 0.3))
	return w

# 7. Arc Launcher — splash energy projectile
static func create_arc_launcher() -> Node3D:
	var w = StrikeWeaponBaseScript.new()
	w.name = "Arc_Launcher"
	w.weapon_id = "arc_launcher"
	w.weapon_name = "Arc Launcher"
	w.damage = 75.0
	w.fire_rate_rpm = 45.0
	w.magazine_capacity = 4
	w.max_reserve_ammo = 16
	w.reload_time_sec = 3.0
	w.base_spread_deg = 0.8
	w.recoil_pitch_deg = 3.2
	w.projectile_speed = 65.0
	w.is_explosive = true
	w.explosion_radius = 5.5
	w.projectile_color = Color(0.8, 0.2, 1.0) # Electric Violet
	w.sound_fire_key = "explosion"
	_attach_visual(w, "arc", Color(0.8, 0.2, 1.0))
	return w

# 8. Pulse Cannon — charged penetrating shot
static func create_pulse_cannon() -> Node3D:
	var w = StrikeWeaponBaseScript.new()
	w.name = "Pulse_Cannon"
	w.weapon_id = "pulse_cannon"
	w.weapon_name = "Pulse Cannon"
	w.damage = 120.0
	w.is_charged = true
	w.charge_time_sec = 0.5
	w.fire_rate_rpm = 90.0
	w.magazine_capacity = 5
	w.max_reserve_ammo = 25
	w.reload_time_sec = 2.6
	w.base_spread_deg = 0.2
	w.recoil_pitch_deg = 4.0
	w.projectile_speed = 200.0
	w.is_penetrating = true
	w.projectile_color = Color(0.1, 1.0, 0.8) # Bright Turquoise
	w.sound_fire_key = "railgun_fire"
	_attach_visual(w, "pulse", Color(0.1, 1.0, 0.8))
	return w

# 9. Tactical Sidearm — fast draw backup
static func create_tactical_sidearm() -> Node3D:
	var w = StrikeWeaponBaseScript.new()
	w.name = "Tactical_Sidearm"
	w.weapon_id = "tactical_sidearm"
	w.weapon_name = "Tactical Sidearm"
	w.damage = 22.0
	w.fire_rate_rpm = 420.0
	w.magazine_capacity = 15
	w.max_reserve_ammo = 999 # infinite reserve
	w.reload_time_sec = 1.2
	w.base_spread_deg = 1.0
	w.recoil_pitch_deg = 1.1
	w.projectile_speed = 140.0
	w.projectile_color = Color(1.0, 1.0, 1.0) # White/Silver
	w.sound_fire_key = "laser_fire"
	_attach_visual(w, "sidearm", Color(1.0, 1.0, 1.0))
	return w

static func _attach_visual(parent: Node3D, archetype: String, glow_color: Color) -> void:
	var root = Node3D.new()
	root.name = "VisualModel"

	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")

	var mat_glow = StandardMaterial3D.new()
	mat_glow.albedo_color = glow_color
	mat_glow.emission_enabled = true
	mat_glow.emission = glow_color
	mat_glow.emission_energy_multiplier = 3.5

	match archetype:
		"vx7", "atlas":
			# Assault / Battle Rifle frame
			_add_box(root, Vector3(0.08, 0.12, 0.50), Vector3(0, 0.02, -0.12), mat_hull)
			_add_box(root, Vector3(0.05, 0.16, 0.08), Vector3(0, -0.14, 0.06), mat_metal) # grip
			_add_box(root, Vector3(0.045, 0.18, 0.08), Vector3(0, -0.14, -0.10), mat_metal) # mag
			_add_box(root, Vector3(0.03, 0.03, 0.40), Vector3(0, 0.04, -0.42), mat_metal) # barrel
			_add_box(root, Vector3(0.02, 0.02, 0.25), Vector3(0, 0.08, -0.15), mat_glow) # rail glow
		"tempest", "sidearm":
			# Compact SMG / Pistol frame
			var l_scale = 0.30 if archetype == "sidearm" else 0.38
			_add_box(root, Vector3(0.06, 0.10, l_scale), Vector3(0, 0.02, -0.08), mat_hull)
			_add_box(root, Vector3(0.045, 0.14, 0.06), Vector3(0, -0.12, 0.04), mat_metal) # grip
			_add_box(root, Vector3(0.025, 0.025, 0.20), Vector3(0, 0.03, -0.22), mat_metal) # barrel
			_add_box(root, Vector3(0.015, 0.015, 0.18), Vector3(0, 0.06, -0.10), mat_glow) # glow
		"breach":
			# Shotgun double barrel pump
			_add_box(root, Vector3(0.12, 0.14, 0.45), Vector3(0, 0.01, -0.10), mat_hull)
			_add_box(root, Vector3(0.05, 0.05, 0.44), Vector3(0, 0.05, -0.42), mat_metal) # top barrel
			_add_box(root, Vector3(0.05, 0.05, 0.44), Vector3(0, -0.02, -0.42), mat_metal) # bottom barrel
			_add_box(root, Vector3(0.08, 0.07, 0.18), Vector3(0, -0.08, -0.30), mat_glow) # pump grip
		"longshot", "pulse":
			# Heavy Marksman / Penetrating Rail chassis
			_add_box(root, Vector3(0.09, 0.12, 0.60), Vector3(0, 0.02, -0.18), mat_hull)
			_add_box(root, Vector3(0.025, 0.03, 0.75), Vector3(0.025, 0.03, -0.65), mat_metal) # rail A
			_add_box(root, Vector3(0.025, 0.03, 0.75), Vector3(-0.025, 0.03, -0.65), mat_metal) # rail B
			_add_box(root, Vector3(0.02, 0.02, 0.65), Vector3(0, 0.03, -0.65), mat_glow) # inner core
			_add_box(root, Vector3(0.055, 0.06, 0.16), Vector3(0, 0.12, -0.14), mat_hull) # scope
		"cyclone", "arc":
			# Heavy Support / Heavy Launcher
			_add_box(root, Vector3(0.15, 0.16, 0.52), Vector3(0, 0.03, -0.12), mat_hull)
			_add_box(root, Vector3(0.14, 0.14, 0.14), Vector3(0, -0.12, -0.06), mat_metal) # drum / cell
			_add_box(root, Vector3(0.06, 0.06, 0.42), Vector3(0, 0.04, -0.45), mat_metal) # heavy bore
			_add_box(root, Vector3(0.16, 0.03, 0.32), Vector3(0, 0.04, -0.14), mat_glow) # heat sink

	parent.add_child(root)
	parent.weapon_mesh = root

static func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi
