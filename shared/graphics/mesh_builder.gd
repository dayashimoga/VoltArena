class_name MeshBuilder
extends RefCounted

## Production-quality procedural 3D model builder for VoltArena.
## Generates original stylized production assets: articulated humanoids,
## multi-part weapons, monsters, vehicles, subway trains, and environment props.

# ==============================================================================
# 1. WEAPONS ARSENAL (5 DISTINCT SCI-FI ENERGY WEAPONS)
# ==============================================================================

static func build_pulse_rifle() -> Node3D:
	var root = Node3D.new()
	root.name = "PulseRifleVisual"
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_cyan = MaterialGenerator.get_material("neon_cyan")

	# Main Upper Receiver Body
	_add_box(root, Vector3(0.08, 0.11, 0.46), Vector3(0, 0.02, -0.12), mat_hull)
	# Lower Receiver & Magazine Well
	_add_box(root, Vector3(0.07, 0.08, 0.22), Vector3(0, -0.06, -0.04), mat_metal)
	# Ergonomic Pistol Grip with Trigger Guard
	var grip = _add_box(root, Vector3(0.05, 0.14, 0.07), Vector3(0, -0.14, 0.06), mat_hull)
	grip.rotation_degrees.x = 18.0
	_add_box(root, Vector3(0.03, 0.08, 0.08), Vector3(0, -0.10, 0.01), mat_metal)
	# Curved Bullpup Tactical Stock
	_add_box(root, Vector3(0.07, 0.13, 0.18), Vector3(0, 0.0, 0.16), mat_hull)
	_add_box(root, Vector3(0.075, 0.14, 0.03), Vector3(0, 0.0, 0.25), mat_metal)
	# Curved Ammo Magazine (releasable)
	var mag = _add_box(root, Vector3(0.045, 0.18, 0.08), Vector3(0, -0.14, -0.10), mat_metal)
	mag.rotation_degrees.x = -12.0
	mag.name = "MagazineMesh"
	# Fluted Vented Outer Barrel
	var barrel = _add_cyl(root, 0.024, 0.024, 0.36, Vector3(0, 0.035, -0.44), mat_metal)
	barrel.rotation_degrees.x = 90.0
	# Muzzle Brake / Flash Hider
	var muzzle = _add_cyl(root, 0.032, 0.032, 0.08, Vector3(0, 0.035, -0.63), mat_cyan)
	muzzle.rotation_degrees.x = 90.0
	muzzle.name = "MuzzleTip"
	# Top Picatinny Tactical Rail
	_add_box(root, Vector3(0.035, 0.02, 0.32), Vector3(0, 0.085, -0.14), mat_hull)
	# Holographic Reflex Sight Frame & Optic Lens
	_add_box(root, Vector3(0.055, 0.06, 0.07), Vector3(0, 0.12, -0.08), mat_hull)
	var reticle = _add_box(root, Vector3(0.04, 0.04, 0.01), Vector3(0, 0.125, -0.08), mat_cyan)
	reticle.name = "SightReticle"
	# Bioluminescent Energy Conduit Strips along flanks
	_add_box(root, Vector3(0.01, 0.025, 0.28), Vector3(-0.042, 0.03, -0.14), mat_cyan)
	_add_box(root, Vector3(0.01, 0.025, 0.28), Vector3(0.042, 0.03, -0.14), mat_cyan)

	return root

static func build_scatter_cannon() -> Node3D:
	var root = Node3D.new()
	root.name = "ScatterCannonVisual"
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_orange = MaterialGenerator.get_material("neon_orange")

	# Heavy Reinforced Receiver Block
	_add_box(root, Vector3(0.13, 0.15, 0.42), Vector3(0, 0.01, -0.10), mat_hull)
	# Dual Heavy Over-Under Barrels
	var b_top = _add_cyl(root, 0.032, 0.032, 0.44, Vector3(0, 0.05, -0.42), mat_metal)
	b_top.rotation_degrees.x = 90.0
	var b_bot = _add_cyl(root, 0.032, 0.032, 0.44, Vector3(0, -0.03, -0.42), mat_metal)
	b_bot.rotation_degrees.x = 90.0
	# Perforated Heat Shroud
	_add_box(root, Vector3(0.11, 0.14, 0.28), Vector3(0, 0.01, -0.34), mat_hull)
	# Ribbed Pump Foregrip (slidable)
	var pump = _add_box(root, Vector3(0.09, 0.07, 0.18), Vector3(0, -0.08, -0.32), mat_metal)
	pump.name = "PumpSlide"
	# Ergonomic Swept Grip & Solid Stock
	var grip = _add_box(root, Vector3(0.06, 0.15, 0.08), Vector3(0, -0.13, 0.08), mat_hull)
	grip.rotation_degrees.x = 22.0
	_add_box(root, Vector3(0.08, 0.13, 0.20), Vector3(0, -0.02, 0.18), mat_metal)
	# Dual Muzzle Crowns
	var m_top = _add_cyl(root, 0.038, 0.038, 0.04, Vector3(0, 0.05, -0.64), mat_orange)
	m_top.rotation_degrees.x = 90.0
	m_top.name = "MuzzleTip"
	var m_bot = _add_cyl(root, 0.038, 0.038, 0.04, Vector3(0, -0.03, -0.64), mat_orange)
	m_bot.rotation_degrees.x = 90.0
	# Rotary Drum Magazine underneath
	var drum = _add_cyl(root, 0.065, 0.065, 0.10, Vector3(0, -0.07, -0.08), mat_metal)
	drum.rotation_degrees.z = 90.0
	drum.name = "DrumMagazine"

	return root

static func build_rail_driver() -> Node3D:
	var root = Node3D.new()
	root.name = "RailDriverVisual"
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_blue = MaterialGenerator.get_material("neon_blue")

	# Heavy Sniper Chassis Frame
	_add_box(root, Vector3(0.09, 0.12, 0.55), Vector3(0, 0.02, -0.15), mat_hull)
	# Dual Parallel Electromagnetic Accelerator Rails
	_add_box(root, Vector3(0.03, 0.035, 0.72), Vector3(0, 0.055, -0.66), mat_metal)
	_add_box(root, Vector3(0.03, 0.035, 0.72), Vector3(0, 0.005, -0.66), mat_metal)
	# Magnetic Induction Coils along the rails (4 capacitor rings)
	for z_pos in [-0.40, -0.55, -0.70, -0.85]:
		_add_box(root, Vector3(0.07, 0.09, 0.04), Vector3(0, 0.03, z_pos), mat_blue)
	# Muzzle Emitter Tip
	var m_tip = _add_box(root, Vector3(0.05, 0.08, 0.04), Vector3(0, 0.03, -1.02), mat_blue)
	m_tip.name = "MuzzleTip"
	# High-Magnification Sniper Scope
	var scope_tube = _add_cyl(root, 0.028, 0.035, 0.32, Vector3(0, 0.14, -0.20), mat_hull)
	scope_tube.rotation_degrees.x = 90.0
	var lens = _add_cyl(root, 0.032, 0.032, 0.02, Vector3(0, 0.14, -0.36), mat_blue)
	lens.rotation_degrees.x = 90.0
	lens.name = "ScopeLens"
	# Scope Mounts
	_add_box(root, Vector3(0.03, 0.05, 0.03), Vector3(0, 0.09, -0.10), mat_metal)
	_add_box(root, Vector3(0.03, 0.05, 0.03), Vector3(0, 0.09, -0.28), mat_metal)
	# Ergonomic Skeleton Thumbhole Stock
	_add_box(root, Vector3(0.06, 0.14, 0.26), Vector3(0, -0.03, 0.22), mat_hull)
	_add_box(root, Vector3(0.065, 0.16, 0.03), Vector3(0, -0.03, 0.35), mat_metal)
	# Pistol Grip & Capacitor Battery Cell
	var grip = _add_box(root, Vector3(0.05, 0.15, 0.06), Vector3(0, -0.14, 0.05), mat_hull)
	grip.rotation_degrees.x = 24.0
	var batt = _add_box(root, Vector3(0.05, 0.10, 0.12), Vector3(0, -0.10, -0.10), mat_blue)
	batt.name = "BatteryCell"
	# Folding Bipod Legs under barrel
	var bp_l = _add_box(root, Vector3(0.02, 0.18, 0.02), Vector3(-0.06, -0.08, -0.50), mat_metal)
	bp_l.rotation_degrees.z = -20.0
	var bp_r = _add_box(root, Vector3(0.02, 0.18, 0.02), Vector3(0.06, -0.08, -0.50), mat_metal)
	bp_r.rotation_degrees.z = 20.0

	return root

static func build_grenade_launcher() -> Node3D:
	var root = Node3D.new()
	root.name = "GrenadeLauncherVisual"
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_red = MaterialGenerator.get_material("neon_red")

	# Heavy Frame & Breech Housing
	_add_box(root, Vector3(0.14, 0.16, 0.38), Vector3(0, 0.04, -0.08), mat_hull)
	# Revolving 6-Round Drum Cylinder
	var drum = _add_cyl(root, 0.11, 0.11, 0.24, Vector3(0, 0.02, -0.16), mat_metal)
	drum.rotation_degrees.x = 90.0
	drum.name = "GrenadeDrum"
	# 6 Visible Shell Primers in rear of drum
	for i in range(6):
		var angle = float(i) * PI / 3.0
		var sx = cos(angle) * 0.065
		var sy = sin(angle) * 0.065 + 0.02
		_add_cyl(root, 0.018, 0.018, 0.02, Vector3(sx, sy, -0.04), mat_red).rotation_degrees.x = 90.0
	# Wide Rifled Launcher Barrel
	var barrel = _add_cyl(root, 0.055, 0.055, 0.32, Vector3(0, 0.08, -0.42), mat_hull)
	barrel.rotation_degrees.x = 90.0
	# Flanged Muzzle Crown
	var muzzle = _add_cyl(root, 0.065, 0.065, 0.05, Vector3(0, 0.08, -0.58), mat_metal)
	muzzle.rotation_degrees.x = 90.0
	muzzle.name = "MuzzleTip"
	# Forward Foregrip and Pistol Grip
	_add_box(root, Vector3(0.05, 0.14, 0.06), Vector3(0, -0.06, -0.38), mat_hull)
	var grip = _add_box(root, Vector3(0.055, 0.15, 0.07), Vector3(0, -0.12, 0.10), mat_hull)
	grip.rotation_degrees.x = 18.0
	# Flip-up Ladder Sight
	var sight = _add_box(root, Vector3(0.02, 0.08, 0.015), Vector3(0, 0.17, -0.30), mat_red)
	sight.name = "LadderSight"
	# Folding Shoulder Brace Stock
	_add_box(root, Vector3(0.06, 0.12, 0.22), Vector3(0, 0.04, 0.24), mat_metal)

	return root

static func build_plasma_cutter() -> Node3D:
	var root = Node3D.new()
	root.name = "PlasmaCutterVisual"
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_cyan = MaterialGenerator.get_material("neon_cyan")
	var mat_magenta = MaterialGenerator.get_material("neon_magenta")

	# Heavy Industrial Tool Chassis
	_add_box(root, Vector3(0.11, 0.13, 0.40), Vector3(0, 0.02, -0.10), mat_hull)
	# Dual Magnetic Emitter Prongs
	var p_left = _add_box(root, Vector3(0.022, 0.05, 0.32), Vector3(-0.075, 0.03, -0.42), mat_metal)
	p_left.rotation_degrees.y = 8.0
	var p_right = _add_box(root, Vector3(0.022, 0.05, 0.32), Vector3(0.075, 0.03, -0.42), mat_metal)
	p_right.rotation_degrees.y = -8.0
	# Active Glowing Discharge Nodes on prong tips
	_add_sphere(root, 0.025, Vector3(-0.055, 0.03, -0.58), mat_cyan)
	_add_sphere(root, 0.025, Vector3(0.055, 0.03, -0.58), mat_cyan)
	# Central Plasma Induction Core
	var core = _add_sphere(root, 0.048, Vector3(0, 0.03, -0.30), mat_magenta)
	core.name = "PlasmaCore"
	# Magnetic Containment Rings around core
	var ring = _add_cyl(root, 0.065, 0.065, 0.025, Vector3(0, 0.03, -0.30), mat_metal)
	ring.rotation_degrees.x = 90.0
	# Dual Heavy Industrial Grips
	var g_rear = _add_box(root, Vector3(0.05, 0.16, 0.06), Vector3(0, -0.12, 0.06), mat_hull)
	g_rear.rotation_degrees.x = 22.0
	_add_box(root, Vector3(0.04, 0.06, 0.16), Vector3(0, 0.12, -0.12), mat_metal)
	# Power Coupling Cable Connector
	_add_cyl(root, 0.025, 0.025, 0.08, Vector3(0, -0.06, 0.14), mat_cyan).rotation_degrees.x = 90.0
	var m_tip = _add_box(root, Vector3(0.01, 0.01, 0.01), Vector3(0, 0.03, -0.60), mat_cyan)
	m_tip.name = "MuzzleTip"

	return root


# ==============================================================================
# 2. HUMANOID CHARACTERS (PLAYER & ARCHETYPE COMBAT BOTS)
# ==============================================================================

static func build_cyber_soldier(is_bot: bool = false, accent_color: Color = Color(0.0, 0.9, 1.0)) -> Node3D:
	var soldier = Node3D.new()
	soldier.name = "CyberSoldierVisual"

	var mat_armor = MaterialGenerator.get_material("dark_hull")
	var mat_under = MaterialGenerator.get_material("sci_fi_metal")
	var mat_glow = MaterialGenerator.create_pbr_material(accent_color, 0.4, 0.3, accent_color, 2.8)

	# --- SKELETAL ROOT: Pelvis & Hips ---
	var pelvis = Node3D.new()
	pelvis.name = "Pelvis"
	pelvis.position = Vector3(0, 0.95, 0)
	soldier.add_child(pelvis)

	# Sculpted Pelvis & Tactical Belt
	_add_box(pelvis, Vector3(0.36, 0.18, 0.26), Vector3(0, 0, 0), mat_armor)
	_add_box(pelvis, Vector3(0.38, 0.05, 0.28), Vector3(0, 0.06, 0), mat_under)
	# Belt Pouches
	_add_box(pelvis, Vector3(0.07, 0.08, 0.06), Vector3(-0.16, 0.02, 0.15), mat_under)
	_add_box(pelvis, Vector3(0.07, 0.08, 0.06), Vector3(0.16, 0.02, 0.15), mat_under)

	# --- TORSO / CHEST ---
	var chest = Node3D.new()
	chest.name = "Chest"
	chest.position = Vector3(0, 0.30, 0)
	pelvis.add_child(chest)

	# Abdominal Segment
	_add_box(chest, Vector3(0.34, 0.16, 0.24), Vector3(0, -0.14, 0), mat_under)
	# Upper Pectoral Armor Plating
	_add_box(chest, Vector3(0.46, 0.32, 0.30), Vector3(0, 0.08, 0), mat_armor)
	# Glowing Arc Reactor / Power Core on Sternum
	var reactor = _add_cyl(chest, 0.055, 0.055, 0.04, Vector3(0, 0.10, 0.16), mat_glow)
	reactor.rotation_degrees.x = 90.0
	reactor.name = "ArcReactor"
	# Collar Guard
	_add_box(chest, Vector3(0.30, 0.08, 0.18), Vector3(0, 0.26, -0.02), mat_armor)

	# --- HEAD & HELMET ---
	var head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.34, 0)
	chest.add_child(head)

	# Neck Joint
	_add_cyl(head, 0.07, 0.08, 0.08, Vector3(0, -0.04, 0), mat_under)
	# Sculpted Angular Combat Helmet
	_add_box(head, Vector3(0.24, 0.26, 0.26), Vector3(0, 0.12, -0.01), mat_armor)
	# Helmet Brow & Crown Ridge
	_add_box(head, Vector3(0.25, 0.06, 0.16), Vector3(0, 0.24, 0.02), mat_under)
	# Tinted Reflective Cyber Visor with Glow
	var visor = _add_box(head, Vector3(0.22, 0.07, 0.06), Vector3(0, 0.12, 0.13), mat_glow)
	visor.name = "HelmetVisor"
	# Side Comms Headset / Sensor Ear Cups
	_add_cyl(head, 0.04, 0.04, 0.03, Vector3(-0.13, 0.11, 0), mat_under).rotation_degrees.z = 90.0
	_add_cyl(head, 0.04, 0.04, 0.03, Vector3(0.13, 0.11, 0), mat_under).rotation_degrees.z = 90.0
	# Tactical Antenna
	_add_cyl(head, 0.006, 0.006, 0.14, Vector3(0.13, 0.22, -0.04), mat_under)

	# --- LEFT ARM ---
	var l_shoulder = Node3D.new()
	l_shoulder.name = "LeftShoulder"
	l_shoulder.position = Vector3(-0.30, 0.16, 0)
	chest.add_child(l_shoulder)

	# Left Shoulder Armor Pauldron
	_add_box(l_shoulder, Vector3(0.16, 0.14, 0.18), Vector3(-0.02, 0.02, 0), mat_armor)
	# Left Bicep Arm
	_add_box(l_shoulder, Vector3(0.12, 0.24, 0.13), Vector3(0, -0.14, 0), mat_under)
	# Left Forearm & Elbow Guard
	var l_forearm = Node3D.new()
	l_forearm.name = "LeftForearm"
	l_forearm.position = Vector3(0, -0.26, 0)
	l_shoulder.add_child(l_forearm)
	_add_box(l_forearm, Vector3(0.11, 0.22, 0.12), Vector3(0, -0.10, 0), mat_armor)
	# Left Hand
	_add_box(l_forearm, Vector3(0.08, 0.09, 0.08), Vector3(0, -0.24, 0), mat_under)

	# --- RIGHT ARM ---
	var r_shoulder = Node3D.new()
	r_shoulder.name = "RightShoulder"
	r_shoulder.position = Vector3(0.30, 0.16, 0)
	chest.add_child(r_shoulder)

	# Right Shoulder Armor Pauldron
	_add_box(r_shoulder, Vector3(0.16, 0.14, 0.18), Vector3(0.02, 0.02, 0), mat_armor)
	# Right Bicep Arm
	_add_box(r_shoulder, Vector3(0.12, 0.24, 0.13), Vector3(0, -0.14, 0), mat_under)
	# Right Forearm & Elbow Guard
	var r_forearm = Node3D.new()
	r_forearm.name = "RightForearm"
	r_forearm.position = Vector3(0, -0.26, 0)
	r_shoulder.add_child(r_forearm)
	_add_box(r_forearm, Vector3(0.11, 0.22, 0.12), Vector3(0, -0.10, 0), mat_armor)
	# Right Hand Gripping Node
	var r_hand = _add_box(r_forearm, Vector3(0.08, 0.09, 0.08), Vector3(0, -0.24, 0), mat_under)
	r_hand.name = "RightHand"

	# Weapon Attachment Slot on Bot / Third-Person View
	if is_bot:
		var w_slot = Node3D.new()
		w_slot.name = "WeaponSlot"
		w_slot.position = Vector3(0, -0.24, -0.18)
		r_forearm.add_child(w_slot)
		var rifle_visual = build_pulse_rifle()
		rifle_visual.scale = Vector3(0.85, 0.85, 0.85)
		w_slot.add_child(rifle_visual)

	# --- LEFT LEG ---
	var l_hip = Node3D.new()
	l_hip.name = "LeftHip"
	l_hip.position = Vector3(-0.15, -0.12, 0)
	pelvis.add_child(l_hip)

	# Thigh Armor
	_add_box(l_hip, Vector3(0.15, 0.32, 0.17), Vector3(0, -0.16, 0), mat_armor)
	# Left Shin & Knee Guard
	var l_shin = Node3D.new()
	l_shin.name = "LeftShin"
	l_shin.position = Vector3(0, -0.34, 0)
	l_hip.add_child(l_shin)
	_add_box(l_shin, Vector3(0.14, 0.30, 0.15), Vector3(0, -0.15, 0), mat_under)
	_add_box(l_shin, Vector3(0.12, 0.10, 0.06), Vector3(0, -0.04, 0.10), mat_armor)
	# Left Tactical Boot
	_add_box(l_shin, Vector3(0.14, 0.12, 0.24), Vector3(0, -0.34, 0.04), mat_armor)

	# --- RIGHT LEG ---
	var r_hip = Node3D.new()
	r_hip.name = "RightHip"
	r_hip.position = Vector3(0.15, -0.12, 0)
	pelvis.add_child(r_hip)

	# Thigh Armor
	_add_box(r_hip, Vector3(0.15, 0.32, 0.17), Vector3(0, -0.16, 0), mat_armor)
	# Right Shin & Knee Guard
	var r_shin = Node3D.new()
	r_shin.name = "RightShin"
	r_shin.position = Vector3(0, -0.34, 0)
	r_hip.add_child(r_shin)
	_add_box(r_shin, Vector3(0.14, 0.30, 0.15), Vector3(0, -0.15, 0), mat_under)
	_add_box(r_shin, Vector3(0.12, 0.10, 0.06), Vector3(0, -0.04, 0.10), mat_armor)
	# Right Tactical Boot
	_add_box(r_shin, Vector3(0.14, 0.12, 0.24), Vector3(0, -0.34, 0.04), mat_armor)

	return soldier


# ==============================================================================
# 3. METRO MUTANT MONSTERS (CRAWLER, SPITTER, STALKER, BRUTE, BIO-COLOSSUS)
# ==============================================================================

static func build_crawler_mesh() -> Node3D:
	var root = Node3D.new()
	root.name = "CrawlerVisual"
	var mat_chitin = MaterialGenerator.get_material("enemy_crawler")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_eyes = MaterialGenerator.get_material("neon_magenta")

	# Segmented Thorax & Abdomen
	_add_box(root, Vector3(0.55, 0.28, 0.70), Vector3(0, 0.35, 0.10), mat_chitin)
	_add_box(root, Vector3(0.45, 0.24, 0.40), Vector3(0, 0.38, -0.32), mat_hull)
	# Spiked Dorsal Ridge
	for z_pos in [-0.20, 0.0, 0.20]:
		var spine = _add_cyl(root, 0.01, 0.035, 0.18, Vector3(0, 0.54, z_pos), mat_hull)
		spine.rotation_degrees.x = -15.0
	# Triangular Head with Razor Mandibles
	_add_box(root, Vector3(0.32, 0.18, 0.25), Vector3(0, 0.34, -0.58), mat_chitin)
	# Dual Scythe Mandibles
	var m_l = _add_box(root, Vector3(0.04, 0.06, 0.22), Vector3(-0.14, 0.28, -0.74), mat_hull)
	m_l.rotation_degrees = Vector3(10, -25, 0)
	var m_r = _add_box(root, Vector3(0.04, 0.06, 0.22), Vector3(0.14, 0.28, -0.74), mat_hull)
	m_r.rotation_degrees = Vector3(10, 25, 0)
	# 6 Glowing Cluster Eyes
	for i in range(6):
		var ex = -0.10 + float(i % 3) * 0.10
		var ey = 0.38 + (0.05 if i >= 3 else 0.0)
		_add_sphere(root, 0.024, Vector3(ex, ey, -0.68), mat_eyes)

	# 6 Articulated Spider Scythe Legs
	for side in [-1.0, 1.0]:
		for leg_i in range(3):
			var z_off = -0.25 + float(leg_i) * 0.28
			var coxa = Node3D.new()
			coxa.position = Vector3(side * 0.26, 0.35, z_off)
			coxa.rotation_degrees.y = side * (35.0 - float(leg_i) * 30.0)
			root.add_child(coxa)
			# Upper Femur
			var femur = _add_box(coxa, Vector3(side * 0.06, 0.06, 0.32), Vector3(side * 0.16, 0.08, 0), mat_chitin)
			femur.rotation_degrees.z = -side * 28.0
			# Lower Tibia / Scythe Tip
			var tibia = _add_box(coxa, Vector3(side * 0.04, 0.05, 0.38), Vector3(side * 0.32, -0.16, 0), mat_hull)
			tibia.rotation_degrees.z = side * 35.0

	return root

static func build_spitter_mesh() -> Node3D:
	var root = Node3D.new()
	root.name = "SpitterVisual"
	var mat_chitin = MaterialGenerator.get_material("enemy_crawler")
	var mat_acid = MaterialGenerator.get_material("acid_pool")
	var mat_hull = MaterialGenerator.get_material("dark_hull")

	# Hunched Bulbous Thorax
	_add_box(root, Vector3(0.60, 0.65, 0.80), Vector3(0, 0.75, 0.0), mat_chitin)
	# Swollen Glowing Caustic Acid Sac
	var sac = _add_sphere(root, 0.34, Vector3(0, 0.70, -0.35), mat_acid)
	sac.scale = Vector3(1.0, 1.2, 1.4)
	sac.name = "AcidSac"
	# Spitting Maw & Acid Vent Tube
	var maw = _add_cyl(root, 0.12, 0.05, 0.28, Vector3(0, 0.85, -0.65), mat_acid)
	maw.rotation_degrees.x = 90.0
	maw.name = "AcidMaw"
	# Spine Crest
	for sz in [-0.2, 0.1, 0.3]:
		_add_box(root, Vector3(0.06, 0.18, 0.08), Vector3(0, 1.12, sz), mat_hull)
	# 4 Sturdy Tripod/Quad Claw Legs
	for side in [-1.0, 1.0]:
		for leg_z in [-0.25, 0.30]:
			var leg = _add_box(root, Vector3(0.10, 0.65, 0.10), Vector3(side * 0.38, 0.32, leg_z), mat_chitin)
			leg.rotation_degrees = Vector3(15.0 if leg_z > 0 else -15.0, 0, -side * 22.0)

	return root

static func build_stalker_mesh() -> Node3D:
	var root = Node3D.new()
	root.name = "StalkerVisual"
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_bio = MaterialGenerator.get_material("neon_green")

	# Slender Elongated Torso with Bioluminescent Ribs
	_add_box(root, Vector3(0.32, 1.10, 0.26), Vector3(0, 1.05, 0), mat_hull)
	for y in [0.75, 0.92, 1.09, 1.26, 1.43]:
		_add_box(root, Vector3(0.38, 0.035, 0.30), Vector3(0, y, 0), mat_bio)
	# Shadow Cloak / Crest Collar
	_add_box(root, Vector3(0.44, 0.30, 0.18), Vector3(0, 1.62, -0.06), mat_hull)
	# Faceless Skull Mask with Green Slit Eyes
	_add_box(root, Vector3(0.20, 0.28, 0.24), Vector3(0, 1.76, -0.04), mat_hull)
	_add_box(root, Vector3(0.16, 0.04, 0.06), Vector3(0, 1.80, -0.16), mat_bio)
	# Twin Elongated Scythe Blade Arms
	for side in [-1.0, 1.0]:
		var arm = _add_box(root, Vector3(0.07, 0.50, 0.08), Vector3(side * 0.26, 1.15, -0.05), mat_hull)
		arm.rotation_degrees = Vector3(25.0, 0, -side * 15.0)
		var scythe = _add_box(root, Vector3(0.04, 0.70, 0.12), Vector3(side * 0.32, 0.75, -0.28), mat_bio)
		scythe.rotation_degrees = Vector3(55.0, 0, 0)
	# Tall Slender Stilt Legs
	for side in [-1.0, 1.0]:
		_add_box(root, Vector3(0.09, 0.90, 0.10), Vector3(side * 0.14, 0.45, 0), mat_hull)

	return root

static func build_brute_mesh() -> Node3D:
	var root = Node3D.new()
	root.name = "BruteVisual"
	var mat_armor = MaterialGenerator.get_material("dark_concrete")
	var mat_lava = MaterialGenerator.get_material("neon_red")
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")

	# Massive Hunchbacked Rock Torso
	_add_box(root, Vector3(1.30, 1.40, 1.10), Vector3(0, 1.40, 0), mat_armor)
	# Molten Magma Fissures coursing across back and chest
	_add_box(root, Vector3(0.95, 0.10, 1.15), Vector3(0, 1.55, 0), mat_lava)
	_add_box(root, Vector3(1.15, 0.10, 0.95), Vector3(0, 1.30, 0), mat_lava)
	# Heavy Spiked Shoulder Blocks
	for side in [-1.0, 1.0]:
		_add_box(root, Vector3(0.55, 0.55, 0.65), Vector3(side * 0.85, 1.85, -0.05), mat_armor)
		var horn = _add_cyl(root, 0.02, 0.14, 0.50, Vector3(side * 0.85, 2.25, 0), mat_metal)
		horn.rotation_degrees.z = -side * 35.0
	# Giant Crushing Boulder Fists
	for side in [-1.0, 1.0]:
		var b_arm = _add_box(root, Vector3(0.35, 0.80, 0.35), Vector3(side * 0.88, 1.15, -0.15), mat_armor)
		b_arm.rotation_degrees.x = 20.0
		var fist = _add_box(root, Vector3(0.55, 0.65, 0.55), Vector3(side * 0.92, 0.55, -0.35), mat_metal)
		fist.name = "Fist_" + ("Left" if side < 0 else "Right")
	# Sturdy Elephantine Stomp Legs
	for side in [-1.0, 1.0]:
		_add_cyl(root, 0.28, 0.38, 0.85, Vector3(side * 0.42, 0.42, 0), mat_armor)

	return root

static func build_colossus_boss_mesh() -> Node3D:
	var root = Node3D.new()
	root.name = "BioColossusVisual"
	var mat_armor = MaterialGenerator.get_material("dark_concrete")
	var mat_core = MaterialGenerator.get_material("neon_red")
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")

	# Massive 3-Story Armored Titan Torso
	_add_box(root, Vector3(2.8, 3.2, 2.4), Vector3(0, 3.4, 0), mat_armor)
	# Glowing Vulnerable Bioreactor Core Heart Weakpoint
	var heart = _add_sphere(root, 0.70, Vector3(0, 3.6, -1.25), mat_core)
	heart.name = "CoreHeartWeakpoint"
	# Protective Rib Plating over Core
	for ry in [3.1, 3.6, 4.1]:
		_add_box(root, Vector3(1.8, 0.12, 0.20), Vector3(0, ry, -1.35), mat_metal)
	# Dorsal Volcanic Spines
	for sz in [-0.8, 0.0, 0.8]:
		var spine = _add_cyl(root, 0.06, 0.35, 1.6, Vector3(0, 5.2, sz), mat_metal)
		spine.rotation_degrees.x = sz * 20.0
	# Crushing Excavator Arms and Fists
	for side in [-1.0, 1.0]:
		_add_box(root, Vector3(0.9, 2.2, 0.9), Vector3(side * 2.1, 2.8, -0.3), mat_armor)
		var fist = _add_box(root, Vector3(1.4, 1.4, 1.4), Vector3(side * 2.2, 1.1, -0.8), mat_metal)
		fist.name = "CrusherFist_" + ("Left" if side < 0 else "Right")
	# Massive Pillar Stomp Legs
	for side in [-1.0, 1.0]:
		_add_cyl(root, 0.55, 0.80, 1.8, Vector3(side * 1.0, 0.9, 0), mat_armor)

	return root


# ==============================================================================
# 4. SUBWAY TRAIN & METRO STATION PROPS
# ==============================================================================

static func build_subway_car_mesh() -> Node3D:
	var train = Node3D.new()
	train.name = "SubwayTrainCar"
	var mat_steel = MaterialGenerator.get_material("subway_rust_metal")
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_win = MaterialGenerator.get_material("neon_cyan")
	var mat_hazard = MaterialGenerator.get_material("hazard_stripe")
	var mat_headlight = MaterialGenerator.get_material("neon_yellow")
	var mat_taillight = MaterialGenerator.get_material("neon_red")

	var train_length = 24.0
	var train_width = 3.4
	var train_height = 3.2
	var floor_y = 1.4

	# Main Streamlined Carriage Body
	_add_box(train, Vector3(train_width, train_height, train_length), Vector3(0, floor_y + train_height * 0.5, 0), mat_steel)
	# Corrugated Steel Roof Curve
	_add_box(train, Vector3(train_width - 0.3, 0.35, train_length - 0.2), Vector3(0, floor_y + train_height + 0.15, 0), mat_hull)
	# Roof HVAC Units
	_add_box(train, Vector3(1.6, 0.40, 4.0), Vector3(0, floor_y + train_height + 0.45, -5.0), mat_metal)
	_add_box(train, Vector3(1.6, 0.40, 4.0), Vector3(0, floor_y + train_height + 0.45, 5.0), mat_metal)
	# Aerodynamic Sloped Locomotive Nose Cowl (at -Z end)
	_add_box(train, Vector3(train_width - 0.1, train_height - 0.2, 2.2), Vector3(0, floor_y + train_height * 0.5, -train_length * 0.5 - 1.1), mat_steel)
	# Front Windshield
	_add_box(train, Vector3(train_width - 0.6, 1.1, 0.15), Vector3(0, floor_y + 2.1, -train_length * 0.5 - 2.22), mat_win)
	# High-Intensity LED Headlights
	for hx in [-1.1, 1.1]:
		var hl = _add_cyl(train, 0.18, 0.18, 0.15, Vector3(hx, floor_y + 1.2, -train_length * 0.5 - 2.25), mat_headlight)
		hl.rotation_degrees.x = 90.0
	# Rear Red Marker Taillights (at +Z end)
	for tx in [-1.1, 1.1]:
		var tl = _add_cyl(train, 0.14, 0.14, 0.12, Vector3(tx, floor_y + 1.4, train_length * 0.5 + 0.05), mat_taillight)
		tl.rotation_degrees.x = 90.0
	# Heavy Anti-Climber Crash Bumpers and Couplers
	_add_box(train, Vector3(train_width + 0.2, 0.45, 0.8), Vector3(0, floor_y + 0.3, -train_length * 0.5 - 1.8), mat_hull)
	_add_box(train, Vector3(train_width + 0.2, 0.45, 0.8), Vector3(0, floor_y + 0.3, train_length * 0.5 + 0.4), mat_hull)
	# Yellow Hazard Striping along bottom sill
	_add_box(train, Vector3(train_width + 0.05, 0.20, train_length + 0.2), Vector3(0, floor_y + 0.12, 0), mat_hazard)

	# Side Windows & Bi-Parting Passenger Doors along flanks
	for side in [-1.0, 1.0]:
		var x_pos = side * (train_width * 0.5 + 0.02)
		# 4 Large Passenger Windows
		for wz in [-8.0, -3.0, 3.0, 8.0]:
			_add_box(train, Vector3(0.04, 1.10, 2.20), Vector3(x_pos, floor_y + 2.0, wz), mat_win)
		# 2 Bi-Parting Passenger Doors
		for dz in [-5.5, 5.5]:
			var door_panel = _add_box(train, Vector3(0.06, 2.20, 1.60), Vector3(x_pos, floor_y + 1.15, dz), mat_metal)
			door_panel.name = "PassengerDoor_" + str(dz)

	# --- 2 REALISTIC DUAL-AXLE BOGIES WITH STEEL FLANGED WHEELS ---
	for b_z in [-7.5, 7.5]:
		var bogie = Node3D.new()
		bogie.name = "Bogie_" + str(b_z)
		bogie.position = Vector3(0, 0.45, b_z)
		train.add_child(bogie)

		# Bogie Cast Steel Frame
		_add_box(bogie, Vector3(2.6, 0.30, 3.4), Vector3(0, 0.25, 0), mat_hull)
		# 4 Flanged Steel Train Wheels on Rails
		for wx in [-1.2, 1.2]:
			for wz in [-1.1, 1.1]:
				var wheel = _add_cyl(bogie, 0.42, 0.42, 0.22, Vector3(wx, 0.22, wz), mat_metal)
				wheel.rotation_degrees.z = 90.0

	return train

static func build_ticket_turnstile() -> Node3D:
	var root = Node3D.new()
	root.name = "TicketTurnstile"
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_cyan = MaterialGenerator.get_material("neon_cyan")

	# Housing Pedestal
	_add_box(root, Vector3(0.40, 1.10, 1.20), Vector3(0, 0.55, 0), mat_hull)
	# Stainless Top Plate
	_add_box(root, Vector3(0.44, 0.06, 1.24), Vector3(0, 1.12, 0), mat_metal)
	# Swipe Scanner Screen
	_add_box(root, Vector3(0.18, 0.02, 0.24), Vector3(0, 1.15, -0.30), mat_cyan)
	# Rotary Tripod Arm Hub
	var hub = _add_cyl(root, 0.06, 0.06, 0.12, Vector3(-0.24, 0.85, 0), mat_metal)
	hub.rotation_degrees.z = 90.0
	# Turnstile Barrier Bar
	var arm = _add_cyl(root, 0.025, 0.025, 0.70, Vector3(-0.55, 0.85, 0), mat_metal)
	arm.rotation_degrees.z = 90.0

	return root

static func build_subway_bench() -> Node3D:
	var root = Node3D.new()
	root.name = "SubwayBench"
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")

	# Seat Slab
	_add_box(root, Vector3(0.65, 0.08, 2.20), Vector3(0, 0.48, 0), mat_hull)
	# Backrest
	_add_box(root, Vector3(0.08, 0.55, 2.20), Vector3(-0.28, 0.76, 0), mat_hull)
	# 2 Steel Leg Frames
	for bz in [-0.85, 0.85]:
		_add_box(root, Vector3(0.60, 0.44, 0.08), Vector3(0, 0.22, bz), mat_metal)

	return root

static func build_vending_machine() -> Node3D:
	var root = Node3D.new()
	root.name = "VendingMachine"
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_cyan = MaterialGenerator.get_material("neon_cyan")
	var mat_orange = MaterialGenerator.get_material("neon_orange")

	# Main Cabinet
	_add_box(root, Vector3(1.10, 2.20, 0.90), Vector3(0, 1.10, 0), mat_hull)
	# Glass Product Display Bay
	_add_box(root, Vector3(0.85, 1.20, 0.08), Vector3(0, 1.35, 0.46), mat_cyan)
	# Illuminated Header Branding
	_add_box(root, Vector3(0.95, 0.25, 0.08), Vector3(0, 2.05, 0.46), mat_orange)
	# Coin / Card Terminal and Dispenser Tray
	_add_box(root, Vector3(0.70, 0.30, 0.15), Vector3(0, 0.30, 0.46), mat_hull)

	return root

static func build_scrap_gear_mesh() -> Node3D:
	var root = Node3D.new()
	root.name = "ScrapGear"
	var mat_gold = MaterialGenerator.get_material("gold_pickup")
	var mat_cyan = MaterialGenerator.get_material("neon_cyan")

	# Heavy Brass Gear Disc
	var gear = _add_cyl(root, 0.32, 0.32, 0.09, Vector3(0, 0.35, 0), mat_gold)
	gear.rotation_degrees.x = 90.0
	# Center Axle Hole with Energy Core
	var center = _add_cyl(root, 0.10, 0.10, 0.11, Vector3(0, 0.35, 0), mat_cyan)
	center.rotation_degrees.x = 90.0
	# 8 Peripheral Gear Teeth
	for i in range(8):
		var angle = float(i) * PI / 4.0
		var tooth = _add_box(root, Vector3(0.08, 0.14, 0.08), Vector3(cos(angle) * 0.38, 0.35 + sin(angle) * 0.38, 0), mat_gold)
		tooth.rotation_degrees.z = rad_to_deg(angle)

	return root


# ==============================================================================
# 5. NITRO KICK ROCKET CAR & PROFESSIONAL STADIUM ASSETS
# ==============================================================================

static func build_rocket_car(team_id: int = 0) -> Node3D:
	var car = Node3D.new()
	car.name = "RocketCarVisual"

	var team_color = Color(0.1, 0.85, 1.0) if team_id == 0 else Color(1.0, 0.55, 0.05)
	var mat_team = MaterialGenerator.create_pbr_material(team_color, 0.85, 0.22, team_color, 0.4)
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_tire = MaterialGenerator.get_material("asphalt_track")
	var mat_glow = MaterialGenerator.create_pbr_material(team_color, 0.3, 0.2, team_color, 2.5)

	# Aerodynamic Sculpted Low-Slung Chassis Body
	var body = _add_box(car, Vector3(1.80, 0.45, 3.50), Vector3(0, 0.42, 0), mat_team)
	body.name = "CarBodyMesh"
	# Sloped Aerodynamic Hood with Air Scoop
	var hood = _add_box(car, Vector3(1.65, 0.22, 1.20), Vector3(0, 0.45, -1.20), mat_hull)
	hood.rotation_degrees.x = 12.0
	_add_box(car, Vector3(0.55, 0.10, 0.40), Vector3(0, 0.58, -1.15), mat_metal)
	# Front Ground-Effect Splitter & Bumper
	_add_box(car, Vector3(1.95, 0.10, 0.50), Vector3(0, 0.22, -1.82), mat_hull)
	# Cockpit Canopy with Tinted Windshield
	_add_box(car, Vector3(1.30, 0.45, 1.60), Vector3(0, 0.82, -0.15), mat_hull)
	_add_box(car, Vector3(1.20, 0.38, 0.85), Vector3(0, 0.85, -0.55), mat_glow)
	# Roll Cage Struts
	_add_box(car, Vector3(1.25, 0.06, 1.55), Vector3(0, 1.05, -0.15), mat_metal)
	# High-Downforce Carbon-Fiber Rear Spoiler Wing
	_add_box(car, Vector3(2.15, 0.07, 0.42), Vector3(0, 1.22, 1.60), mat_team)
	# Spoiler Wing Endplates
	_add_box(car, Vector3(0.06, 0.25, 0.46), Vector3(-1.08, 1.22, 1.60), mat_hull)
	_add_box(car, Vector3(0.06, 0.25, 0.46), Vector3(1.08, 1.22, 1.60), mat_hull)
	# Spoiler Wing Pylons
	for sx in [-0.75, 0.75]:
		_add_box(car, Vector3(0.07, 0.45, 0.12), Vector3(sx, 0.95, 1.58), mat_metal)
	# Aggressive Rear Diffuser
	_add_box(car, Vector3(1.85, 0.24, 0.45), Vector3(0, 0.32, 1.76), mat_hull)
	# Dual Cylindrical Rocket Booster Thrusters
	for tx in [-0.38, 0.38]:
		var thruster = _add_cyl(car, 0.14, 0.18, 0.38, Vector3(tx, 0.50, 1.88), mat_metal)
		thruster.rotation_degrees.x = 90.0
		# Active Rocket Exhaust Flame Cone
		var flame = _add_cyl(car, 0.02, 0.13, 0.55, Vector3(tx, 0.50, 2.30), mat_glow)
		flame.rotation_degrees.x = 90.0
		flame.name = "ThrusterFlame_" + ("L" if tx < 0 else "R")

	# --- 4 DETAILED ALLOY WHEELS WITH RADIAL TIRES & SUSPENSION ---
	var wheel_offsets = [
		Vector3(-1.08, 0.38, -1.25),
		Vector3(1.08, 0.38, -1.25),
		Vector3(-1.08, 0.40, 1.25),
		Vector3(1.08, 0.40, 1.25)
	]
	for i in range(wheel_offsets.size()):
		var wp = wheel_offsets[i]
		var w_node = Node3D.new()
		w_node.name = "Wheel_" + str(i)
		w_node.position = wp
		car.add_child(w_node)

		# Tire Tread Cylinder
		var tire = _add_cyl(w_node, 0.38, 0.38, 0.34, Vector3.ZERO, mat_tire)
		tire.rotation_degrees.z = 90.0
		# Alloy Rim Face
		var rim = _add_cyl(w_node, 0.28, 0.28, 0.36, Vector3(sign(wp.x) * 0.02, 0, 0), mat_metal)
		rim.rotation_degrees.z = 90.0
		# Brake Caliper
		_add_box(w_node, Vector3(0.12, 0.18, 0.12), Vector3(-sign(wp.x) * 0.14, 0.14, 0), mat_glow)
		# Suspension Wishbone Arm
		_add_box(car, Vector3(0.24, 0.08, 0.14), wp + Vector3(sign(wp.x) * -0.14, 0.06, 0), mat_metal)

	return car

static func build_stadium_grandstand(width: float = 80.0, height: float = 14.0, depth: float = 16.0) -> Node3D:
	var stand = Node3D.new()
	stand.name = "StadiumGrandstand"
	var mat_concrete = MaterialGenerator.get_material("dark_concrete")
	var mat_spectators = MaterialGenerator.get_material("stadium_spectators")
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")

	var num_tiers = 6
	for t in range(num_tiers):
		var frac = float(t) / float(num_tiers)
		var ty = 1.0 + frac * height
		var tz = frac * depth
		_add_box(stand, Vector3(width, 1.6, depth / float(num_tiers)), Vector3(0, ty, tz), mat_concrete)
		_add_box(stand, Vector3(width - 2.0, 1.2, 0.8), Vector3(0, ty + 1.2, tz + 0.4), mat_spectators)
		_add_box(stand, Vector3(width, 0.85, 0.05), Vector3(0, ty + 1.2, tz - depth / float(num_tiers * 2)), mat_metal)

	return stand

static func build_stadium_floodlight_tower(height: float = 24.0) -> Node3D:
	var tower = Node3D.new()
	tower.name = "FloodlightTower"
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_glow = MaterialGenerator.get_material("neon_yellow")

	_add_box(tower, Vector3(1.2, height, 1.2), Vector3(0, height * 0.5, 0), mat_metal)
	for h in range(4, int(height), 4):
		_add_box(tower, Vector3(2.4, 0.15, 2.4), Vector3(0, float(h), 0), mat_hull)
	_add_box(tower, Vector3(5.5, 0.35, 2.2), Vector3(0, height, 0), mat_metal)
	for i in range(6):
		var lx = -2.2 + float(i) * 0.88
		var lamp = _add_cyl(tower, 0.32, 0.32, 0.22, Vector3(lx, height + 0.5, 0.8), mat_glow)
		lamp.rotation_degrees.x = 45.0

	return tower


# ==============================================================================
# 6. DRIFT STORM RACING KARTS & TRACK PROPS
# ==============================================================================

static func build_drift_kart(kart_color: Color = Color(0.2, 1.0, 0.5), _kart_type: String = "speeder") -> Node3D:
	var kart = Node3D.new()
	kart.name = "DriftKartVisual"

	var mat_body = MaterialGenerator.create_pbr_material(kart_color, 0.82, 0.25, kart_color, 0.4)
	var mat_frame = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_tire = MaterialGenerator.get_material("asphalt_track")

	# Tubular Steel Spaceframe Chassis
	_add_box(kart, Vector3(1.30, 0.24, 2.60), Vector3(0, 0.26, 0), mat_frame)
	# Front Nose Fairing with Aerodynamic Splitter
	_add_box(kart, Vector3(1.20, 0.22, 0.75), Vector3(0, 0.28, -1.22), mat_body)
	_add_box(kart, Vector3(1.35, 0.06, 0.28), Vector3(0, 0.18, -1.55), mat_hull)
	# Side Pods with Radiator Intake Ducts
	for side in [-1.0, 1.0]:
		_add_box(kart, Vector3(0.28, 0.26, 1.35), Vector3(side * 0.72, 0.30, 0), mat_body)
		_add_box(kart, Vector3(0.24, 0.18, 0.08), Vector3(side * 0.72, 0.30, -0.68), mat_hull)
	# Contoured Racing Bucket Seat
	_add_box(kart, Vector3(0.55, 0.55, 0.48), Vector3(0, 0.52, 0.22), mat_hull)
	# Helmeted Driver Silhouette
	var driver_head = _add_sphere(kart, 0.18, Vector3(0, 0.98, 0.22), mat_body)
	driver_head.name = "DriverHead"
	_add_box(kart, Vector3(0.22, 0.08, 0.08), Vector3(0, 0.98, 0.08), mat_hull)
	_add_box(kart, Vector3(0.42, 0.36, 0.28), Vector3(0, 0.68, 0.22), mat_hull)
	# Driver Arms reaching for Steering Wheel
	var arm_l = _add_box(kart, Vector3(0.08, 0.08, 0.42), Vector3(-0.18, 0.64, -0.06), mat_hull)
	arm_l.rotation_degrees.x = -22.0
	var arm_r = _add_box(kart, Vector3(0.08, 0.08, 0.42), Vector3(0.18, 0.64, -0.06), mat_hull)
	arm_r.rotation_degrees.x = -22.0
	# Angled Steering Column & Wheel
	var col = _add_cyl(kart, 0.02, 0.02, 0.42, Vector3(0, 0.50, -0.25), mat_frame)
	col.rotation_degrees.x = 42.0
	var wheel_hub = Node3D.new()
	wheel_hub.name = "SteeringWheelHub"
	wheel_hub.position = Vector3(0, 0.66, -0.38)
	kart.add_child(wheel_hub)
	var st_wheel = _add_cyl(wheel_hub, 0.15, 0.15, 0.03, Vector3.ZERO, mat_hull)
	st_wheel.rotation_degrees.x = 45.0
	# Exposed Rear High-Output Engine Block
	_add_box(kart, Vector3(0.58, 0.42, 0.48), Vector3(0, 0.44, 0.88), mat_frame)
	# Dual Chrome Exhaust Pipes
	for ex in [-0.20, 0.20]:
		var exh = _add_cyl(kart, 0.045, 0.045, 0.35, Vector3(ex, 0.38, 1.25), mat_frame)
		exh.rotation_degrees.x = 90.0
		exh.name = "Exhaust_" + ("L" if ex < 0 else "R")
	# High-Downforce Rear Wing
	_add_box(kart, Vector3(1.35, 0.06, 0.32), Vector3(0, 0.82, 1.18), mat_body)
	_add_box(kart, Vector3(0.06, 0.40, 0.12), Vector3(-0.48, 0.62, 1.15), mat_frame)
	_add_box(kart, Vector3(0.06, 0.40, 0.12), Vector3(0.48, 0.62, 1.15), mat_frame)

	# 4 Wide Slick Racing Tires on Alloy Wheels
	var tire_offsets = [
		Vector3(-0.76, 0.28, -0.88),
		Vector3(0.76, 0.28, -0.88),
		Vector3(-0.80, 0.32, 0.88),
		Vector3(0.80, 0.32, 0.88)
	]
	for i in range(tire_offsets.size()):
		var tp = tire_offsets[i]
		var w_node = Node3D.new()
		w_node.name = "FrontWheel_%d" % i if i < 2 else "RearWheel_%d" % (i - 2)
		w_node.position = tp
		kart.add_child(w_node)

		var radius = 0.28 if i < 2 else 0.32
		var tire = _add_cyl(w_node, radius, radius, 0.28, Vector3.ZERO, mat_tire)
		tire.rotation_degrees.z = 90.0
		var rim = _add_cyl(w_node, radius * 0.75, radius * 0.75, 0.30, Vector3.ZERO, mat_frame)
		rim.rotation_degrees.z = 90.0

	return kart

static func build_track_barrier(barrier_length: float = 10.0, height: float = 1.4) -> Node3D:
	var root = Node3D.new()
	root.name = "TrackBarrier"
	var mat_barrier = MaterialGenerator.get_material("sci_fi_metal")
	var mat_fence = MaterialGenerator.get_material("dark_hull")
	var mat_stripes = MaterialGenerator.get_material("curb_stripes")

	# Lower Concrete Armco Barrier Base
	_add_box(root, Vector3(0.60, height * 0.6, barrier_length), Vector3(0, height * 0.3, 0), mat_barrier)
	# Upper Steel Catch Fence Mesh & Posts
	_add_box(root, Vector3(0.08, height * 0.4, barrier_length), Vector3(0, height * 0.8, 0), mat_fence)
	# Top Red/White Safety Stripe
	_add_box(root, Vector3(0.62, 0.15, barrier_length), Vector3(0, height * 0.6, 0), mat_stripes)

	return root


# ==============================================================================
# 7. HELPER PRIMITIVE BUILDERS (CREATES VISIBLE MESH INSTANCES WITH PROPER UVs)
# ==============================================================================

static func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = r_top
	cyl.bottom_radius = r_bot
	cyl.height = h
	cyl.radial_segments = 16
	mi.mesh = cyl
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_sphere(parent: Node3D, r: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var sp = SphereMesh.new()
	sp.radius = r
	sp.height = r * 2.0
	sp.radial_segments = 16
	sp.rings = 8
	mi.mesh = sp
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

# Backwards-compatibility aliases for existing callers
static func build_item_box() -> Node3D:
	var root = Node3D.new()
	root.name = "ItemBoxVisual"
	var mat_orange = MaterialGenerator.get_material("neon_orange")
	var mat_gold = MaterialGenerator.get_material("gold_pickup")
	_add_box(root, Vector3(1.1, 1.1, 1.1), Vector3.ZERO, mat_orange)
	_add_box(root, Vector3(0.8, 0.8, 0.8), Vector3.ZERO, mat_gold)
	return root

static func build_pickup_mesh(type: int) -> Node3D:
	var root = Node3D.new()
	root.name = "PickupVisual"
	var mat_core = MaterialGenerator.get_material("health_red" if type == 0 else ("neon_blue" if type == 1 else "gold_pickup"))
	var mi = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(0.5, 0.7, 0.5)
	mi.mesh = prism
	mi.material_override = mat_core
	root.add_child(mi)
	return root

static func build_cyber_crate(size: Vector3 = Vector3(2.0, 2.0, 2.0)) -> Node3D:
	var root = Node3D.new()
	root.name = "CyberCrate"
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_cyan = MaterialGenerator.get_material("neon_cyan")
	_add_box(root, size, Vector3.ZERO, mat_hull)
	_add_box(root, Vector3(size.x + 0.05, size.y * 0.25, size.z + 0.05), Vector3.ZERO, mat_metal)
	_add_box(root, Vector3(size.x + 0.06, 0.08, size.z * 0.4), Vector3.ZERO, mat_cyan)
	return root

static func build_upgrade_kiosk_mesh() -> Node3D:
	var root = Node3D.new()
	root.name = "UpgradeKiosk"
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_cyan = MaterialGenerator.get_material("neon_cyan")
	_add_box(root, Vector3(1.6, 2.2, 0.8), Vector3(0, 1.1, 0), mat_hull)
	_add_box(root, Vector3(1.2, 0.8, 0.05), Vector3(0, 1.5, 0.42), mat_cyan)
	return root

static func build_blast_door_mesh() -> Node3D:
	var root = Node3D.new()
	root.name = "BlastDoor"
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hazard = MaterialGenerator.get_material("hazard_stripe")
	_add_box(root, Vector3(5.0, 4.5, 0.6), Vector3(0, 2.25, 0), mat_metal)
	var panel = _add_box(root, Vector3(3.8, 3.8, 0.4), Vector3(0, 2.0, 0), mat_hazard)
	panel.name = "DoorSlidingPanel"
	return root

static func build_boost_orb_mesh() -> Node3D:
	var root = Node3D.new()
	root.name = "BoostOrb"
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_gold = MaterialGenerator.get_material("gold_pickup")
	_add_cyl(root, 0.8, 1.0, 0.3, Vector3(0, 0.15, 0), mat_metal)
	var core = _add_sphere(root, 0.55, Vector3(0, 1.2, 0), mat_gold)
	core.name = "FloatingOrbCore"
	return root

static func build_energy_ball() -> Node3D:
	var root = Node3D.new()
	root.name = "EnergyBallVisual"
	var mat_ball = MaterialGenerator.get_material("energy_ball")
	_add_sphere(root, 1.05, Vector3.ZERO, mat_ball)
	return root

static func build_stadium_goal_mesh(team_id: int = 0) -> Node3D:
	var goal = Node3D.new()
	goal.name = "StadiumGoal"
	var mat_team = MaterialGenerator.get_material("neon_cyan" if team_id == 0 else "neon_orange")
	var mat_net = MaterialGenerator.get_material("dark_hull")
	var goal_w = 16.0
	var goal_h = 7.0
	var goal_d = 5.0

	_add_cyl(goal, 0.25, 0.25, goal_h, Vector3(-goal_w * 0.5, goal_h * 0.5, 0), mat_team)
	_add_cyl(goal, 0.25, 0.25, goal_h, Vector3(goal_w * 0.5, goal_h * 0.5, 0), mat_team)
	var cb = _add_cyl(goal, 0.25, 0.25, goal_w, Vector3(0, goal_h, 0), mat_team)
	cb.rotation_degrees.z = 90.0
	_add_box(goal, Vector3(goal_w, goal_h, 0.1), Vector3(0, goal_h * 0.5, -goal_d), mat_net)
	return goal

static func build_start_gantry(gantry_width: float = 14.0) -> Node3D:
	var gantry = Node3D.new()
	gantry.name = "StartFinishGantry"
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_sign = MaterialGenerator.get_material("digital_signage_cyan")
	_add_box(gantry, Vector3(1.2, 7.5, 1.2), Vector3(-gantry_width * 0.5 - 1.0, 3.75, 0), mat_metal)
	_add_box(gantry, Vector3(1.2, 7.5, 1.2), Vector3(gantry_width * 0.5 + 1.0, 3.75, 0), mat_metal)
	_add_box(gantry, Vector3(gantry_width + 3.2, 1.4, 1.2), Vector3(0, 7.0, 0), mat_metal)
	_add_box(gantry, Vector3(gantry_width - 1.0, 1.2, 0.2), Vector3(0, 7.0, -0.65), mat_sign)
	return gantry

static func build_race_gantry_mesh() -> Node3D:
	return build_start_gantry(14.0)

static func build_speed_demon_kart() -> Node3D:
	return build_drift_kart(Color(1.0, 0.2, 0.2), "speeder")

static func build_drift_king_kart() -> Node3D:
	return build_drift_kart(Color(0.8, 0.2, 1.0), "phantom")

static func build_turbo_tank_kart() -> Node3D:
	return build_drift_kart(Color(0.2, 0.8, 0.3), "enforcer")
