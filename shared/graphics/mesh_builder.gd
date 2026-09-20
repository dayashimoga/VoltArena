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

static func build_rocket_car(team_id: int = 0, archetype: String = "sports_coupe") -> Node3D:
	match archetype.to_lower():
		"rally_buggy", "dune_raider", "buggy":
			return build_rocket_rally_buggy(team_id)
		"muscle_gt", "titan_enforcer", "muscle", "turbo_truck":
			return build_rocket_muscle_gt(team_id)
		"cyber_ev", "volt_pulse", "phantom", "cyber":
			return build_rocket_cyber_ev(team_id)
		_:
			return build_rocket_sports_coupe(team_id)

# ------------------------------------------------------------------------------
# Archetype 1: Apex Spectre (Aerodynamic Sports Coupe)
# ------------------------------------------------------------------------------
static func build_rocket_sports_coupe(team_id: int = 0) -> Node3D:
	var car = Node3D.new()
	car.name = "RocketCarVisual"

	var team_color = Color(0.1, 0.85, 1.0) if team_id == 0 else Color(1.0, 0.55, 0.05)
	var mat_team = MaterialGenerator.create_pbr_material(team_color, 0.85, 0.22, team_color, 0.4)
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_tire = MaterialGenerator.get_material("asphalt_track")
	var mat_glow = MaterialGenerator.create_pbr_material(team_color, 0.3, 0.2, team_color, 2.5)
	var mat_headlight = MaterialGenerator.create_pbr_material(Color(0.95, 0.98, 1.0), 0.9, 0.1, Color(0.9, 0.95, 1.0), 3.5)
	var mat_taillight = MaterialGenerator.create_pbr_material(Color(1.0, 0.1, 0.15), 0.8, 0.2, Color(1.0, 0.05, 0.1), 3.0)

	# Aerodynamic Low-Slung Chassis Body (Canonical Forward: -Z, Rear: +Z)
	var body = _add_box(car, Vector3(1.80, 0.45, 3.50), Vector3(0, 0.42, 0), mat_team)
	body.name = "CarBodyMesh"
	# Sloped Aerodynamic Hood with Air Scoop at -Z
	var hood = _add_box(car, Vector3(1.65, 0.22, 1.20), Vector3(0, 0.45, -1.20), mat_hull)
	hood.rotation_degrees.x = 12.0
	_add_box(car, Vector3(0.55, 0.10, 0.40), Vector3(0, 0.58, -1.15), mat_metal)
	# Front Ground-Effect Splitter & Bumper at -Z
	_add_box(car, Vector3(1.95, 0.10, 0.50), Vector3(0, 0.22, -1.82), mat_hull)

	# Dual Front High-Intensity Headlights at -Z (Forward)
	for hx in [-0.55, 0.55]:
		var hl = _add_cyl(car, 0.08, 0.12, 0.12, Vector3(hx, 0.42, -1.82), mat_headlight)
		hl.rotation_degrees.x = 90.0
		hl.name = "FrontHeadlight_" + ("L" if hx < 0 else "R")

	# Cockpit Canopy with Tinted Windshield & Driver Silhouette
	_add_box(car, Vector3(1.30, 0.45, 1.60), Vector3(0, 0.82, -0.15), mat_hull)
	_add_box(car, Vector3(1.20, 0.38, 0.85), Vector3(0, 0.85, -0.55), mat_glow)
	# Driver helmet inside canopy
	var helmet = _add_cyl(car, 0.20, 0.22, 0.30, Vector3(0, 0.82, -0.10), mat_metal)
	helmet.rotation_degrees.x = 15.0
	# Roll Cage Struts
	_add_box(car, Vector3(1.25, 0.06, 1.55), Vector3(0, 1.05, -0.15), mat_metal)

	# High-Downforce Carbon-Fiber Rear Spoiler Wing at +Z (Rear)
	_add_box(car, Vector3(2.15, 0.07, 0.42), Vector3(0, 1.22, 1.60), mat_team)
	# Spoiler Wing Endplates
	_add_box(car, Vector3(0.06, 0.25, 0.46), Vector3(-1.08, 1.22, 1.60), mat_hull)
	_add_box(car, Vector3(0.06, 0.25, 0.46), Vector3(1.08, 1.22, 1.60), mat_hull)
	# Spoiler Wing Pylons
	for sx in [-0.75, 0.75]:
		_add_box(car, Vector3(0.07, 0.45, 0.12), Vector3(sx, 0.95, 1.58), mat_metal)
	# Aggressive Rear Diffuser at +Z
	_add_box(car, Vector3(1.85, 0.24, 0.45), Vector3(0, 0.32, 1.76), mat_hull)

	# Dual Rear Brake/Taillights at +Z (Rear)
	for rx in [-0.60, 0.60]:
		var tl = _add_box(car, Vector3(0.24, 0.08, 0.08), Vector3(rx, 0.48, 1.76), mat_taillight)
		tl.name = "RearTailLight_" + ("L" if rx < 0 else "R")

	# Dual Cylindrical Rocket Booster Thrusters at +Z (Rear)
	for tx in [-0.38, 0.38]:
		var thruster = _add_cyl(car, 0.14, 0.18, 0.38, Vector3(tx, 0.50, 1.88), mat_metal)
		thruster.rotation_degrees.x = 90.0
		thruster.name = "ThrusterNozzle_" + ("L" if tx < 0 else "R")
		# Active Rocket Exhaust Flame Cone at +Z (Rear)
		var flame = _add_cyl(car, 0.02, 0.13, 0.55, Vector3(tx, 0.50, 2.30), mat_glow)
		flame.rotation_degrees.x = 90.0
		flame.name = "ThrusterFlame_" + ("L" if tx < 0 else "R")

	# 4 Detailed Alloy Wheels with Radial Tires & Wishbones
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
		var tire = _add_cyl(w_node, 0.38, 0.38, 0.34, Vector3.ZERO, mat_tire)
		tire.rotation_degrees.z = 90.0
		var rim = _add_cyl(w_node, 0.28, 0.28, 0.36, Vector3(sign(wp.x) * 0.02, 0, 0), mat_metal)
		rim.rotation_degrees.z = 90.0
		_add_box(w_node, Vector3(0.12, 0.18, 0.12), Vector3(-sign(wp.x) * 0.14, 0.14, 0), mat_glow)
		_add_box(car, Vector3(0.24, 0.08, 0.14), wp + Vector3(sign(wp.x) * -0.14, 0.06, 0), mat_metal)

	return car

# ------------------------------------------------------------------------------
# Archetype 2: Dune Raider (Off-Road Rally Buggy)
# ------------------------------------------------------------------------------
static func build_rocket_rally_buggy(team_id: int = 0) -> Node3D:
	var car = Node3D.new()
	car.name = "RocketCarVisual"

	var team_color = Color(0.1, 0.85, 1.0) if team_id == 0 else Color(1.0, 0.55, 0.05)
	var mat_team = MaterialGenerator.create_pbr_material(team_color, 0.85, 0.22, team_color, 0.4)
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_tire = MaterialGenerator.get_material("asphalt_track")
	var mat_glow = MaterialGenerator.create_pbr_material(team_color, 0.3, 0.2, team_color, 2.5)
	var mat_headlight = MaterialGenerator.create_pbr_material(Color(0.95, 0.98, 1.0), 0.9, 0.1, Color(0.9, 0.95, 1.0), 3.5)
	var mat_taillight = MaterialGenerator.create_pbr_material(Color(1.0, 0.1, 0.15), 0.8, 0.2, Color(1.0, 0.05, 0.1), 3.0)

	# Tubular Roll Cage Chassis Base
	var body = _add_box(car, Vector3(1.60, 0.35, 3.20), Vector3(0, 0.52, 0), mat_team)
	body.name = "CarBodyMesh"
	# Steel Front Skid Plate at -Z (Forward)
	var skid = _add_box(car, Vector3(1.40, 0.08, 0.80), Vector3(0, 0.35, -1.55), mat_metal)
	skid.rotation_degrees.x = 22.0

	# Roll Cage Tubular Bars
	for sx in [-0.65, 0.65]:
		# A-pillar & B-pillar tubular frame
		_add_box(car, Vector3(0.06, 0.75, 0.06), Vector3(sx, 0.95, -0.65), mat_metal)
		_add_box(car, Vector3(0.06, 0.85, 0.06), Vector3(sx, 1.00, 0.45), mat_metal)
		_add_box(car, Vector3(0.06, 0.06, 1.15), Vector3(sx, 1.35, -0.10), mat_metal)
	_add_box(car, Vector3(1.36, 0.06, 0.06), Vector3(0, 1.35, -0.65), mat_metal)
	_add_box(car, Vector3(1.36, 0.06, 0.06), Vector3(0, 1.35, 0.45), mat_metal)

	# Roof-Mounted Quad LED Rally Light Bar at -Z
	for lx in [-0.45, -0.15, 0.15, 0.45]:
		var pod = _add_cyl(car, 0.06, 0.08, 0.10, Vector3(lx, 1.45, -0.62), mat_headlight)
		pod.rotation_degrees.x = 90.0
		pod.name = "RallyLight_" + str(lx)

	# Front Bumper Headlights at -Z
	for bx in [-0.55, 0.55]:
		var hl = _add_cyl(car, 0.07, 0.09, 0.10, Vector3(bx, 0.48, -1.68), mat_headlight)
		hl.rotation_degrees.x = 90.0
		hl.name = "FrontHeadlight_" + ("L" if bx < 0 else "R")

	# Cockpit Driver with Helmet
	var helmet = _add_cyl(car, 0.22, 0.24, 0.32, Vector3(0, 0.95, 0.0), mat_team)
	helmet.rotation_degrees.x = 10.0

	# High-Mount Rear Radiator Scoops
	_add_box(car, Vector3(0.85, 0.35, 0.60), Vector3(0, 0.85, 1.10), mat_hull)

	# Rear LED Taillight Strip at +Z
	var tl = _add_box(car, Vector3(1.20, 0.08, 0.08), Vector3(0, 0.65, 1.62), mat_taillight)
	tl.name = "RearTailLight_C"

	# Center Mega Rocket Thruster Cannon at +Z (Rear)
	var thruster = _add_cyl(car, 0.22, 0.26, 0.45, Vector3(0, 0.58, 1.78), mat_metal)
	thruster.rotation_degrees.x = 90.0
	thruster.name = "ThrusterNozzle_C"
	var flame = _add_cyl(car, 0.04, 0.20, 0.70, Vector3(0, 0.58, 2.30), mat_glow)
	flame.rotation_degrees.x = 90.0
	flame.name = "ThrusterFlame_C"

	# 4 Oversized Knobby Off-Road Wheels with Long-Travel Wishbones
	var wheel_offsets = [
		Vector3(-1.18, 0.48, -1.20),
		Vector3(1.18, 0.48, -1.20),
		Vector3(-1.18, 0.52, 1.20),
		Vector3(1.18, 0.52, 1.20)
	]
	for i in range(wheel_offsets.size()):
		var wp = wheel_offsets[i]
		var w_node = Node3D.new()
		w_node.name = "Wheel_" + str(i)
		w_node.position = wp
		car.add_child(w_node)
		var tire = _add_cyl(w_node, 0.46, 0.46, 0.42, Vector3.ZERO, mat_tire)
		tire.rotation_degrees.z = 90.0
		var rim = _add_cyl(w_node, 0.30, 0.30, 0.44, Vector3(sign(wp.x) * 0.02, 0, 0), mat_metal)
		rim.rotation_degrees.z = 90.0
		# Exposed Long-Travel Wishbone & Coilover Spring
		_add_box(car, Vector3(0.35, 0.08, 0.12), wp + Vector3(sign(wp.x) * -0.20, -0.05, 0), mat_metal)
		var shock = _add_cyl(car, 0.05, 0.05, 0.35, wp + Vector3(sign(wp.x) * -0.15, 0.15, 0), mat_glow)
		shock.rotation_degrees.z = sign(wp.x) * 25.0

	return car

# ------------------------------------------------------------------------------
# Archetype 3: Titan Enforcer (Heavy American Muscle GT)
# ------------------------------------------------------------------------------
static func build_rocket_muscle_gt(team_id: int = 0) -> Node3D:
	var car = Node3D.new()
	car.name = "RocketCarVisual"

	var team_color = Color(0.1, 0.85, 1.0) if team_id == 0 else Color(1.0, 0.55, 0.05)
	var mat_team = MaterialGenerator.create_pbr_material(team_color, 0.85, 0.22, team_color, 0.4)
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_tire = MaterialGenerator.get_material("asphalt_track")
	var mat_glow = MaterialGenerator.create_pbr_material(team_color, 0.3, 0.2, team_color, 2.5)
	var mat_headlight = MaterialGenerator.create_pbr_material(Color(1.0, 0.95, 0.85), 0.9, 0.1, Color(1.0, 0.9, 0.7), 3.5)
	var mat_taillight = MaterialGenerator.create_pbr_material(Color(1.0, 0.1, 0.15), 0.8, 0.2, Color(1.0, 0.05, 0.1), 3.0)

	# Broad Widebody Muscle Chassis Body (2.0m wide)
	var body = _add_box(car, Vector3(2.00, 0.52, 3.60), Vector3(0, 0.46, 0), mat_team)
	body.name = "CarBodyMesh"
	# Aggressive Front Chin Air Dam at -Z
	_add_box(car, Vector3(2.05, 0.15, 0.45), Vector3(0, 0.24, -1.85), mat_hull)

	# Massive Shaker Hood Scoop / Supercharger Blower at -Z
	_add_box(car, Vector3(1.75, 0.24, 1.30), Vector3(0, 0.50, -1.15), mat_hull)
	var scoop = _add_box(car, Vector3(0.65, 0.22, 0.55), Vector3(0, 0.74, -1.05), mat_metal)
	scoop.rotation_degrees.x = -8.0

	# Retro Quad Circular Headlights at -Z
	for hx in [-0.70, -0.45, 0.45, 0.70]:
		var hl = _add_cyl(car, 0.09, 0.09, 0.10, Vector3(hx, 0.48, -1.82), mat_headlight)
		hl.rotation_degrees.x = 90.0
		hl.name = "FrontHeadlight_" + str(hx)

	# Fastback Roofline & Tinted Windows
	_add_box(car, Vector3(1.45, 0.48, 1.80), Vector3(0, 0.88, 0.05), mat_hull)
	var windshield = _add_box(car, Vector3(1.35, 0.40, 0.75), Vector3(0, 0.90, -0.45), mat_glow)
	windshield.rotation_degrees.x = 35.0

	# Integrated Ducktail Rear Spoiler at +Z
	var ducktail = _add_box(car, Vector3(2.05, 0.18, 0.32), Vector3(0, 0.82, 1.72), mat_team)
	ducktail.rotation_degrees.x = -25.0

	# Full-Width Horizontal Rear Taillight Bar at +Z
	var tl = _add_box(car, Vector3(1.75, 0.12, 0.08), Vector3(0, 0.55, 1.82), mat_taillight)
	tl.name = "RearTailLight_Bar"

	# Quad Rectangular Chrome Rocket Thruster Nozzles at +Z
	for tx in [-0.55, -0.22, 0.22, 0.55]:
		var thruster = _add_box(car, Vector3(0.18, 0.14, 0.35), Vector3(tx, 0.38, 1.88), mat_metal)
		thruster.name = "ThrusterNozzle_" + str(tx)
		var flame = _add_cyl(car, 0.02, 0.10, 0.50, Vector3(tx, 0.38, 2.25), mat_glow)
		flame.rotation_degrees.x = 90.0
		flame.name = "ThrusterFlame_" + str(tx)

	# 4 Wide Radial Wheels with Fat Rear Tires
	var wheel_offsets = [
		Vector3(-1.12, 0.40, -1.25),
		Vector3(1.12, 0.40, -1.25),
		Vector3(-1.18, 0.42, 1.25),
		Vector3(1.18, 0.42, 1.25)
	]
	for i in range(wheel_offsets.size()):
		var wp = wheel_offsets[i]
		var is_rear = wp.z > 0
		var w_node = Node3D.new()
		w_node.name = "Wheel_" + str(i)
		w_node.position = wp
		car.add_child(w_node)
		var w_width = 0.42 if is_rear else 0.35
		var w_radius = 0.42 if is_rear else 0.38
		var tire = _add_cyl(w_node, w_radius, w_radius, w_width, Vector3.ZERO, mat_tire)
		tire.rotation_degrees.z = 90.0
		var rim = _add_cyl(w_node, w_radius * 0.7, w_radius * 0.7, w_width + 0.02, Vector3(sign(wp.x) * 0.02, 0, 0), mat_metal)
		rim.rotation_degrees.z = 90.0

	return car

# ------------------------------------------------------------------------------
# Archetype 4: Volt Pulse (Futuristic Cyberpunk EV Wedge)
# ------------------------------------------------------------------------------
static func build_rocket_cyber_ev(team_id: int = 0) -> Node3D:
	var car = Node3D.new()
	car.name = "RocketCarVisual"

	var team_color = Color(0.1, 0.85, 1.0) if team_id == 0 else Color(1.0, 0.55, 0.05)
	var mat_team = MaterialGenerator.create_pbr_material(team_color, 0.90, 0.18, team_color, 0.6)
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_tire = MaterialGenerator.get_material("asphalt_track")
	var mat_glow = MaterialGenerator.create_pbr_material(team_color, 0.2, 0.1, team_color, 3.0)
	var mat_photon = MaterialGenerator.create_pbr_material(Color(0.85, 0.98, 1.0), 0.9, 0.05, Color(0.7, 0.95, 1.0), 4.0)
	var mat_taillight = MaterialGenerator.create_pbr_material(Color(1.0, 0.05, 0.2), 0.8, 0.1, Color(1.0, 0.05, 0.2), 3.5)

	# Low Aerodynamic Stealth Wedge Body (Canonical Forward: -Z, Rear: +Z)
	var body = _add_box(car, Vector3(1.85, 0.38, 3.55), Vector3(0, 0.40, 0), mat_team)
	body.name = "CarBodyMesh"

	# Full-Width Cyber Photon Visor Headlight Blade across front nose at -Z
	var visor = _add_box(car, Vector3(1.82, 0.09, 0.15), Vector3(0, 0.42, -1.82), mat_photon)
	visor.name = "FrontHeadlight_Blade"
	# Lower Active Front Canard Flaps at -Z
	_add_box(car, Vector3(1.95, 0.05, 0.35), Vector3(0, 0.20, -1.75), mat_hull)

	# Sloped Geometric Cockpit Canopy with Panoramic Glass
	var canopy = _add_box(car, Vector3(1.25, 0.42, 1.70), Vector3(0, 0.76, -0.10), mat_glow)
	canopy.rotation_degrees.x = 10.0

	# Twin Vertical Aerodynamic Stabilizer Fins at +Z
	for fx in [-0.85, 0.85]:
		var fin = _add_box(car, Vector3(0.06, 0.45, 0.85), Vector3(fx, 0.92, 1.35), mat_team)
		fin.rotation_degrees.y = sign(fx) * -8.0

	# Rear Dynamic Laser Taillight Bar at +Z
	var tl = _add_box(car, Vector3(1.80, 0.08, 0.08), Vector3(0, 0.50, 1.78), mat_taillight)
	tl.name = "RearTailLight_Laser"

	# Central Magnetic Hyper-Thruster Containment Ring at +Z (Rear)
	var ring = _add_cyl(car, 0.26, 0.26, 0.25, Vector3(0, 0.48, 1.82), mat_metal)
	ring.rotation_degrees.x = 90.0
	ring.name = "ThrusterNozzle_C"
	var core_flame = _add_cyl(car, 0.06, 0.22, 0.65, Vector3(0, 0.48, 2.30), mat_glow)
	core_flame.rotation_degrees.x = 90.0
	core_flame.name = "ThrusterFlame_C"

	# 4 Enclosed Aerodisc Wheels with Glowing Neon Outer Rings
	var wheel_offsets = [
		Vector3(-1.05, 0.38, -1.25),
		Vector3(1.05, 0.38, -1.25),
		Vector3(-1.05, 0.38, 1.25),
		Vector3(1.05, 0.38, 1.25)
	]
	for i in range(wheel_offsets.size()):
		var wp = wheel_offsets[i]
		var w_node = Node3D.new()
		w_node.name = "Wheel_" + str(i)
		w_node.position = wp
		car.add_child(w_node)
		var tire = _add_cyl(w_node, 0.38, 0.38, 0.32, Vector3.ZERO, mat_tire)
		tire.rotation_degrees.z = 90.0
		# Flat Aerodisc Rim Face with glowing neon ring
		var disc = _add_cyl(w_node, 0.32, 0.32, 0.34, Vector3(sign(wp.x) * 0.02, 0, 0), mat_hull)
		disc.rotation_degrees.z = 90.0
		var n_ring = _add_cyl(w_node, 0.28, 0.28, 0.35, Vector3(sign(wp.x) * 0.025, 0, 0), mat_glow)
		n_ring.rotation_degrees.z = 90.0

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

static func build_drift_kart(kart_color: Color = Color(0.0, 0.85, 1.0), kart_type: String = "speeder", number_id: int = 7) -> Node3D:
	match kart_type.to_lower():
		"phantom":
			return build_street_tuner(kart_color, number_id)
		"enforcer":
			return build_offroad_buggy(kart_color, number_id)
		"turbo_demon":
			return build_futuristic_ev(kart_color, number_id)
		"formula":
			return build_formula_racer(kart_color, number_id)
		_:
			return build_racing_kart(kart_color, number_id)

# ------------------------------------------------------------------------------
# Class 1: CIK-FIA Competition Racing Sprint Kart ("speeder")
# ------------------------------------------------------------------------------
static func build_racing_kart(kart_color: Color = Color(0.0, 0.85, 1.0), number_id: int = 7) -> Node3D:
	var kart = Node3D.new()
	kart.name = "DriftKartVisual"

	var mat_body = MaterialGenerator.create_pbr_material(kart_color, 0.70, 0.25, kart_color, 0.35)
	var mat_accent = MaterialGenerator.create_pbr_material(Color(0.96, 0.96, 0.98), 0.40, 0.30)
	var mat_chassis = MaterialGenerator.create_pbr_material(Color(0.12, 0.14, 0.16), 0.85, 0.35)
	var mat_carbon = MaterialGenerator.create_pbr_material(Color(0.08, 0.09, 0.10), 0.30, 0.45)
	var mat_chrome = MaterialGenerator.create_pbr_material(Color(0.92, 0.94, 0.98), 0.95, 0.08)
	var mat_gold = MaterialGenerator.create_pbr_material(Color(1.0, 0.78, 0.15), 0.90, 0.20)
	var mat_tire = MaterialGenerator.create_pbr_material(Color(0.09, 0.09, 0.10), 0.02, 0.88)
	var mat_rim = MaterialGenerator.create_pbr_material(Color(0.75, 0.70, 0.60), 0.85, 0.25)
	var mat_brake = MaterialGenerator.create_pbr_material(Color(0.95, 0.15, 0.15), 0.80, 0.20)
	var mat_helmet = MaterialGenerator.create_pbr_material(Color(0.96, 0.96, 0.98), 0.60, 0.18)
	var mat_visor = MaterialGenerator.create_pbr_material(Color(0.05, 0.08, 0.14), 0.95, 0.06, Color(0.1, 0.6, 0.9), 0.5)
	var mat_gloves = MaterialGenerator.create_pbr_material(Color(0.95, 0.18, 0.18), 0.10, 0.50)

	# Ground contact shadow decal
	_add_contact_shadow(kart, 2.2, 1.4)

	# Tubular Chromoly Steel Spaceframe Chassis
	for side in [-0.28, 0.28]:
		_add_box(kart, Vector3(0.04, 0.04, 1.45), Vector3(side, 0.07, 0.0), mat_chassis)
	_add_box(kart, Vector3(0.60, 0.04, 0.04), Vector3(0, 0.07, -0.62), mat_chassis)
	_add_box(kart, Vector3(0.60, 0.04, 0.04), Vector3(0, 0.07, 0.15), mat_chassis)
	_add_box(kart, Vector3(0.64, 0.04, 0.04), Vector3(0, 0.07, 0.62), mat_chassis)

	# Front tubular bumper & curved side nerf bars
	_add_box(kart, Vector3(0.92, 0.035, 0.035), Vector3(0, 0.09, -1.05), mat_chassis)
	for side in [-0.58, 0.58]:
		_add_box(kart, Vector3(0.035, 0.035, 0.88), Vector3(side, 0.09, 0.0), mat_chassis)
	_add_box(kart, Vector3(1.22, 0.06, 0.06), Vector3(0, 0.14, 0.82), mat_chassis)

	# Aerodynamic Front Nosecone & Splitter
	var nose = _add_box(kart, Vector3(0.88, 0.14, 0.55), Vector3(0, 0.15, -0.88), mat_body)
	nose.rotation_degrees.x = 12.0
	_add_box(kart, Vector3(1.08, 0.03, 0.26), Vector3(0, 0.045, -1.02), mat_carbon)
	var num_plate = _add_box(kart, Vector3(0.26, 0.22, 0.04), Vector3(0, 0.28, -0.66), mat_accent)
	num_plate.rotation_degrees.x = -18.0

	# Sculpted Sidepods with Radiator Inlets
	for side in [-1.0, 1.0]:
		_add_box(kart, Vector3(0.25, 0.18, 0.86), Vector3(side * 0.54, 0.16, 0.0), mat_body)
		_add_box(kart, Vector3(0.23, 0.14, 0.08), Vector3(side * 0.54, 0.16, -0.44), mat_carbon)
		_add_box(kart, Vector3(0.03, 0.06, 0.88), Vector3(side * 0.67, 0.18, 0.0), mat_accent)

	# Floor Tray, Seat & Pedals
	_add_box(kart, Vector3(0.52, 0.015, 0.82), Vector3(0, 0.05, -0.28), mat_carbon)
	_add_box(kart, Vector3(0.44, 0.12, 0.36), Vector3(0, 0.12, 0.06), mat_carbon)
	var seat_back = _add_box(kart, Vector3(0.42, 0.38, 0.10), Vector3(0, 0.29, 0.22), mat_carbon)
	seat_back.rotation_degrees.x = 22.0

	# Steering Column & Flat-Bottom Racing Wheel
	var scol = _add_cyl(kart, 0.018, 0.018, 0.40, Vector3(0, 0.28, -0.25), mat_chassis)
	scol.rotation_degrees.x = 38.0
	var st_wheel = _add_box(kart, Vector3(0.24, 0.18, 0.025), Vector3(0, 0.42, -0.38), mat_carbon)
	st_wheel.rotation_degrees.x = 38.0

	# Authentic Articulated Driver Figure
	_add_driver(kart, Vector3(0, 0.24, 0.10), 18.0, mat_body, mat_helmet, mat_visor, mat_gloves, true)

	# 125cc Competition 2-Stroke Engine & Tuned Chrome Exhaust
	_add_box(kart, Vector3(0.22, 0.20, 0.22), Vector3(0.28, 0.17, 0.42), mat_chassis)
	var exh_chamber = _add_cyl(kart, 0.055, 0.045, 0.38, Vector3(0.08, 0.24, 0.62), mat_chrome)
	exh_chamber.rotation_degrees.z = 85.0
	var silencer = _add_cyl(kart, 0.038, 0.038, 0.30, Vector3(-0.24, 0.22, 0.74), mat_chrome)
	silencer.rotation_degrees.x = 90.0

	# 4 High-Grip Competition Slick Wheels with Alloy Hubs & Brake Discs
	_attach_wheels(kart, 0.15, 0.16, 0.16, 0.24, Vector3(0.58, 0.15, -0.62), Vector3(0.64, 0.16, 0.62), mat_tire, mat_rim, mat_gold, mat_brake)
	return kart

# ------------------------------------------------------------------------------
# Class 2: Japanese Widebody Street Tuner / GT Coupe ("phantom")
# ------------------------------------------------------------------------------
static func build_street_tuner(kart_color: Color = Color(0.85, 0.20, 1.0), number_id: int = 2) -> Node3D:
	var kart = Node3D.new()
	kart.name = "DriftKartVisual"

	var mat_body = MaterialGenerator.create_pbr_material(kart_color, 0.85, 0.18, kart_color, 0.30)
	var mat_accent = MaterialGenerator.create_pbr_material(Color(0.12, 0.14, 0.18), 0.60, 0.35)
	var mat_carbon = MaterialGenerator.create_pbr_material(Color(0.08, 0.09, 0.10), 0.35, 0.40)
	var mat_chrome = MaterialGenerator.create_pbr_material(Color(0.95, 0.95, 0.98), 0.95, 0.06)
	var mat_tire = MaterialGenerator.create_pbr_material(Color(0.10, 0.10, 0.11), 0.02, 0.85)
	var mat_rim = MaterialGenerator.create_pbr_material(Color(0.95, 0.78, 0.22), 0.90, 0.18) # Deep-dish gold
	var mat_brake = MaterialGenerator.create_pbr_material(Color(0.95, 0.15, 0.15), 0.80, 0.20)
	var mat_glass = MaterialGenerator.create_pbr_material(Color(0.06, 0.09, 0.14, 0.92), 0.95, 0.05, Color(0.1, 0.2, 0.4), 0.4)
	var mat_light_front = MaterialGenerator.create_pbr_material(Color(1.0, 1.0, 1.0), 0.1, 0.1, Color(0.9, 0.95, 1.0), 3.0)
	var mat_light_rear = MaterialGenerator.create_pbr_material(Color(1.0, 0.1, 0.1), 0.1, 0.1, Color(1.0, 0.15, 0.15), 3.5)
	var mat_helmet = MaterialGenerator.create_pbr_material(Color(0.15, 0.15, 0.18), 0.6, 0.2)
	var mat_visor = MaterialGenerator.create_pbr_material(Color(1.0, 0.5, 0.1), 0.95, 0.05, Color(1.0, 0.6, 0.2), 1.5)
	var mat_gloves = MaterialGenerator.create_pbr_material(Color(0.15, 0.15, 0.18), 0.1, 0.5)

	# Ground contact shadow decal
	_add_contact_shadow(kart, 2.5, 1.5)

	# Main Low-Slung GT Monocoque
	_add_box(kart, Vector3(1.16, 0.26, 1.85), Vector3(0, 0.22, 0.0), mat_body)
	# Sculpted Vented Hood with Dual Heat Extractors
	var hood = _add_box(kart, Vector3(1.05, 0.12, 0.75), Vector3(0, 0.30, -0.65), mat_body)
	hood.rotation_degrees.x = 6.0
	_add_box(kart, Vector3(0.42, 0.02, 0.26), Vector3(0, 0.35, -0.60), mat_carbon)

	# Aggressive Front Bumper with Chin Splitter and Intercooler Grille
	_add_box(kart, Vector3(1.18, 0.22, 0.32), Vector3(0, 0.18, -1.02), mat_body)
	_add_box(kart, Vector3(1.24, 0.04, 0.36), Vector3(0, 0.065, -1.08), mat_carbon)
	_add_box(kart, Vector3(0.68, 0.14, 0.04), Vector3(0, 0.15, -1.18), mat_accent)
	# Twin Xenon Projector Headlights with LED Eyebrows
	_add_box(kart, Vector3(0.24, 0.06, 0.04), Vector3(-0.42, 0.26, -1.14), mat_light_front)
	_add_box(kart, Vector3(0.24, 0.06, 0.04), Vector3(0.42, 0.26, -1.14), mat_light_front)

	# Flared Widebody Blister Fenders & Aerodynamic Side Skirts
	for side in [-1.0, 1.0]:
		_add_box(kart, Vector3(0.16, 0.28, 0.46), Vector3(side * 0.64, 0.22, -0.62), mat_body)
		_add_box(kart, Vector3(0.18, 0.28, 0.48), Vector3(side * 0.65, 0.23, 0.62), mat_body)
		_add_box(kart, Vector3(0.10, 0.06, 1.15), Vector3(side * 0.62, 0.08, 0.0), mat_carbon)
		# Aero wing mirrors
		_add_box(kart, Vector3(0.10, 0.06, 0.06), Vector3(side * 0.58, 0.44, -0.22), mat_carbon)

	# Aerodynamic Greenhouse Cabin & Tinted Windows
	_add_box(kart, Vector3(0.92, 0.26, 0.85), Vector3(0, 0.45, 0.08), mat_glass)
	_add_box(kart, Vector3(0.86, 0.04, 0.68), Vector3(0, 0.58, 0.08), mat_carbon)

	# Rear Trunk Deck, Horizon LED Taillight Bar & Carbon Diffuser
	_add_box(kart, Vector3(1.14, 0.24, 0.36), Vector3(0, 0.26, 0.95), mat_body)
	_add_box(kart, Vector3(1.10, 0.05, 0.04), Vector3(0, 0.34, 1.13), mat_light_rear)
	_add_box(kart, Vector3(0.95, 0.12, 0.25), Vector3(0, 0.10, 1.05), mat_carbon)

	# Swan-Neck Mount Carbon GT Rear Wing
	_add_box(kart, Vector3(0.04, 0.24, 0.08), Vector3(-0.35, 0.50, 1.02), mat_chrome)
	_add_box(kart, Vector3(0.04, 0.24, 0.08), Vector3(0.35, 0.50, 1.02), mat_chrome)
	var gt_wing = _add_box(kart, Vector3(1.36, 0.04, 0.28), Vector3(0, 0.62, 1.06), mat_carbon)
	gt_wing.rotation_degrees.x = -8.0
	_add_box(kart, Vector3(0.04, 0.14, 0.28), Vector3(-0.68, 0.64, 1.06), mat_carbon)
	_add_box(kart, Vector3(0.04, 0.14, 0.28), Vector3(0.68, 0.64, 1.06), mat_carbon)

	# Dual Angled Titanium Exhaust Tips
	for exh_x in [-0.26, -0.38]:
		var exh = _add_cyl(kart, 0.042, 0.038, 0.22, Vector3(exh_x, 0.14, 1.15), mat_chrome)
		exh.rotation_degrees.x = 90.0

	# Driver Inside Cabin
	_add_driver(kart, Vector3(0, 0.34, 0.05), 14.0, mat_accent, mat_helmet, mat_visor, mat_gloves, false)

	# 4 Staggered Deep-Dish Alloy Wheels with 5-Spoke Centers & Brake Calipers
	_attach_wheels(kart, 0.17, 0.18, 0.18, 0.24, Vector3(0.62, 0.17, -0.62), Vector3(0.64, 0.18, 0.62), mat_tire, mat_rim, mat_chrome, mat_brake)
	return kart

# ------------------------------------------------------------------------------
# Class 3: Extreme Off-Road Sand Rail / Dune Buggy ("enforcer")
# ------------------------------------------------------------------------------
static func build_offroad_buggy(kart_color: Color = Color(0.20, 0.85, 0.35), number_id: int = 4) -> Node3D:
	var kart = Node3D.new()
	kart.name = "DriftKartVisual"

	var mat_body = MaterialGenerator.create_pbr_material(kart_color, 0.65, 0.30, kart_color, 0.25)
	var mat_cage = MaterialGenerator.create_pbr_material(Color(0.18, 0.20, 0.22), 0.85, 0.35)
	var mat_metal = MaterialGenerator.create_pbr_material(Color(0.70, 0.72, 0.75), 0.90, 0.25)
	var mat_spring = MaterialGenerator.create_pbr_material(Color(1.0, 0.80, 0.05), 0.85, 0.20)
	var mat_tire = MaterialGenerator.create_pbr_material(Color(0.10, 0.10, 0.11), 0.02, 0.90)
	var mat_rim = MaterialGenerator.create_pbr_material(Color(0.15, 0.15, 0.18), 0.80, 0.30)
	var mat_brake = MaterialGenerator.create_pbr_material(Color(0.95, 0.15, 0.15), 0.80, 0.20)
	var mat_spotlight = MaterialGenerator.create_pbr_material(Color(1.0, 0.95, 0.8), 0.1, 0.1, Color(1.0, 0.9, 0.6), 3.5)
	var mat_helmet = MaterialGenerator.create_pbr_material(Color(0.95, 0.95, 0.98), 0.6, 0.2)
	var mat_visor = MaterialGenerator.create_pbr_material(Color(0.1, 0.1, 0.1), 0.9, 0.1)
	var mat_gloves = MaterialGenerator.create_pbr_material(Color(0.15, 0.15, 0.18), 0.1, 0.5)

	# Ground contact shadow decal
	_add_contact_shadow(kart, 2.4, 1.5)

	# Heavy Tubular Exo-Skeleton Roll Cage Chassis
	_add_box(kart, Vector3(0.86, 0.16, 1.55), Vector3(0, 0.24, 0.0), mat_body)
	for side in [-0.42, 0.42]:
		var ap = _add_cyl(kart, 0.03, 0.03, 0.68, Vector3(side, 0.50, -0.22), mat_cage)
		ap.rotation_degrees.x = -25.0
		var bp = _add_cyl(kart, 0.03, 0.03, 0.65, Vector3(side, 0.54, 0.32), mat_cage)
		bp.rotation_degrees.x = 12.0
		var stay = _add_cyl(kart, 0.028, 0.028, 0.78, Vector3(side, 0.46, 0.68), mat_cage)
		stay.rotation_degrees.x = 42.0

	# Roof Protection Bar & Overhead Quad KC Rally Spotlights
	_add_box(kart, Vector3(0.88, 0.05, 0.60), Vector3(0, 0.76, 0.05), mat_cage)
	for spot_x in [-0.30, -0.10, 0.10, 0.30]:
		var spot = _add_cyl(kart, 0.055, 0.055, 0.06, Vector3(spot_x, 0.84, -0.24), mat_cage)
		spot.rotation_degrees.x = 90.0
		_add_sphere(spot, 0.048, Vector3(0, 0, 0.03), mat_spotlight)

	# Front Angled Steel Skid Plate & Bull Bar
	var skid = _add_box(kart, Vector3(0.72, 0.04, 0.48), Vector3(0, 0.18, -0.82), mat_metal)
	skid.rotation_degrees.x = -28.0

	# 4 Long-Travel Dual Coilover Shock Absorbers
	var shock_pts = [
		Vector3(-0.46, 0.36, -0.55), Vector3(0.46, 0.36, -0.55),
		Vector3(-0.52, 0.38, 0.55),  Vector3(0.52, 0.38, 0.55)
	]
	for sp in shock_pts:
		var shock = _add_cyl(kart, 0.035, 0.035, 0.34, sp, mat_spring)
		shock.rotation_degrees.z = -18.0 if sp.x < 0 else 18.0

	# Rear Open Bed with Angled Full-Size Spare Tire
	var spare_wheel = Node3D.new()
	spare_wheel.position = Vector3(0, 0.48, 0.68)
	spare_wheel.rotation_degrees.x = 35.0
	kart.add_child(spare_wheel)
	var sp_tire = _add_cyl(spare_wheel, 0.20, 0.20, 0.20, Vector3.ZERO, mat_tire)
	sp_tire.rotation_degrees.z = 90.0
	_add_box(spare_wheel, Vector3(0.04, 0.04, 0.46), Vector3(0, 0, 0), mat_metal)

	# Driver in Open Cockpit
	_add_driver(kart, Vector3(0, 0.34, 0.05), 16.0, mat_body, mat_helmet, mat_visor, mat_gloves, true)

	# 4 Heavy Knobby All-Terrain Beadlock Wheels (High Clearance: radius 0.21m)
	_attach_wheels(kart, 0.21, 0.22, 0.22, 0.26, Vector3(0.62, 0.21, -0.62), Vector3(0.66, 0.22, 0.62), mat_tire, mat_rim, mat_spring, mat_brake)
	return kart

# ------------------------------------------------------------------------------
# Class 4: Cyberpunk Futuristic Electric Hypercar ("turbo_demon")
# ------------------------------------------------------------------------------
static func build_futuristic_ev(kart_color: Color = Color(0.0, 0.90, 1.0), number_id: int = 5) -> Node3D:
	var kart = Node3D.new()
	kart.name = "DriftKartVisual"

	var mat_body = MaterialGenerator.create_pbr_material(kart_color, 0.92, 0.12, kart_color, 0.40)
	var mat_hull = MaterialGenerator.create_pbr_material(Color(0.06, 0.08, 0.12), 0.60, 0.30)
	var mat_neon = MaterialGenerator.create_pbr_material(Color(0.0, 1.0, 0.85), 0.1, 0.1, Color(0.0, 1.0, 0.9), 4.0)
	var mat_neon_orange = MaterialGenerator.create_pbr_material(Color(1.0, 0.35, 0.05), 0.1, 0.1, Color(1.0, 0.4, 0.1), 4.0)
	var mat_carbon = MaterialGenerator.create_pbr_material(Color(0.05, 0.06, 0.07), 0.40, 0.35)
	var mat_canopy = MaterialGenerator.create_pbr_material(Color(0.02, 0.05, 0.10, 0.95), 0.98, 0.02, Color(0.0, 0.7, 1.0), 0.8)
	var mat_tire = MaterialGenerator.create_pbr_material(Color(0.08, 0.08, 0.09), 0.02, 0.82)
	var mat_disc = MaterialGenerator.create_pbr_material(Color(0.12, 0.14, 0.18), 0.85, 0.20)
	var mat_brake = MaterialGenerator.create_pbr_material(Color(0.0, 0.9, 1.0), 0.8, 0.2, Color(0.0, 0.9, 1.0), 1.5)
	var mat_helmet = MaterialGenerator.create_pbr_material(Color(0.96, 0.96, 0.98), 0.7, 0.15)
	var mat_visor = MaterialGenerator.create_pbr_material(Color(0.0, 1.0, 0.85), 0.95, 0.05, Color(0.0, 1.0, 0.85), 2.0)
	var mat_gloves = MaterialGenerator.create_pbr_material(Color(0.1, 0.1, 0.15), 0.2, 0.5)

	# Ground contact shadow decal
	_add_contact_shadow(kart, 2.6, 1.5)

	# Razor-Sharp Wedge Monocoque
	_add_box(kart, Vector3(1.22, 0.24, 1.95), Vector3(0, 0.18, 0.0), mat_body)
	var f_wedge = _add_box(kart, Vector3(1.08, 0.12, 0.75), Vector3(0, 0.20, -0.82), mat_body)
	f_wedge.rotation_degrees.x = 14.0

	# Front Glowing Neon Laser Headlight Blades
	_add_box(kart, Vector3(0.38, 0.025, 0.06), Vector3(-0.42, 0.19, -1.16), mat_neon)
	_add_box(kart, Vector3(0.38, 0.025, 0.06), Vector3(0.42, 0.19, -1.16), mat_neon)

	# Teardrop Glass Canopy & Central Shark Fin
	var canopy = _add_box(kart, Vector3(0.68, 0.26, 1.15), Vector3(0, 0.38, -0.05), mat_canopy)
	canopy.rotation_degrees.x = -6.0
	_add_box(kart, Vector3(0.03, 0.22, 0.95), Vector3(0, 0.48, 0.25), mat_neon)

	# Lateral Battery Cooling Conduits with Glowing Neon Energy Tubes
	for side in [-1.0, 1.0]:
		_add_box(kart, Vector3(0.18, 0.22, 1.45), Vector3(side * 0.65, 0.20, 0.0), mat_hull)
		_add_box(kart, Vector3(0.03, 0.04, 1.30), Vector3(side * 0.75, 0.22, 0.0), mat_neon)

	# Floating Rear Diffuser & Full-Width Neon Horizon Brake Bar
	_add_box(kart, Vector3(1.18, 0.14, 0.38), Vector3(0, 0.14, 1.02), mat_carbon)
	_add_box(kart, Vector3(1.24, 0.03, 0.04), Vector3(0, 0.28, 1.15), mat_neon_orange)

	# Twin Electric Plasma Ion Thrusters
	for side in [-0.35, 0.35]:
		var thruster = _add_cyl(kart, 0.06, 0.075, 0.15, Vector3(side, 0.20, 1.18), mat_hull)
		thruster.rotation_degrees.x = 90.0
		_add_sphere(thruster, 0.05, Vector3(0, 0, 0.06), mat_neon)

	# Driver Inside Canopy
	_add_driver(kart, Vector3(0, 0.30, -0.05), 15.0, mat_hull, mat_helmet, mat_visor, mat_gloves, false)

	# 4 Covered Aerodynamic Turbofan Disc Wheels with Neon Accents
	_attach_wheels(kart, 0.18, 0.18, 0.19, 0.24, Vector3(0.62, 0.18, -0.62), Vector3(0.64, 0.19, 0.62), mat_tire, mat_disc, mat_neon, mat_brake)
	return kart

# ------------------------------------------------------------------------------
# Class 5: Lightweight Open-Wheel Grand Prix Formula Racer ("formula")
# ------------------------------------------------------------------------------
static func build_formula_racer(kart_color: Color = Color(0.95, 0.15, 0.20), number_id: int = 1) -> Node3D:
	var kart = Node3D.new()
	kart.name = "DriftKartVisual"

	var mat_body = MaterialGenerator.create_pbr_material(kart_color, 0.85, 0.18, kart_color, 0.30)
	var mat_carbon = MaterialGenerator.create_pbr_material(Color(0.08, 0.09, 0.10), 0.35, 0.40)
	var mat_halo = MaterialGenerator.create_pbr_material(Color(0.18, 0.20, 0.24), 0.90, 0.25)
	var mat_tire = MaterialGenerator.create_pbr_material(Color(0.09, 0.09, 0.10), 0.02, 0.85)
	var mat_rim = MaterialGenerator.create_pbr_material(Color(0.12, 0.12, 0.14), 0.85, 0.20)
	var mat_nut = MaterialGenerator.create_pbr_material(Color(0.95, 0.20, 0.15), 0.90, 0.20)
	var mat_brake = MaterialGenerator.create_pbr_material(Color(0.95, 0.15, 0.15), 0.80, 0.20)
	var mat_helmet = MaterialGenerator.create_pbr_material(Color(0.96, 0.96, 0.98), 0.70, 0.15)
	var mat_visor = MaterialGenerator.create_pbr_material(Color(0.08, 0.12, 0.18), 0.95, 0.05, Color(0.1, 0.8, 1.0), 1.5)
	var mat_gloves = MaterialGenerator.create_pbr_material(Color(0.95, 0.15, 0.15), 0.1, 0.5)
	var mat_fia_light = MaterialGenerator.create_pbr_material(Color(1.0, 0.1, 0.1), 0.1, 0.1, Color(1.0, 0.1, 0.1), 4.0)

	# Ground contact shadow decal
	_add_contact_shadow(kart, 2.6, 1.5)

	# Slender Needle Monocoque Nosecone
	_add_box(kart, Vector3(0.38, 0.18, 1.45), Vector3(0, 0.18, -0.45), mat_body)
	# Multi-Element Front Aerodynamic Wing & Curved Endplates
	_add_box(kart, Vector3(1.36, 0.035, 0.32), Vector3(0, 0.09, -1.22), mat_carbon)
	_add_box(kart, Vector3(0.035, 0.16, 0.36), Vector3(-0.68, 0.15, -1.22), mat_carbon)
	_add_box(kart, Vector3(0.035, 0.16, 0.36), Vector3(0.68, 0.15, -1.22), mat_carbon)

	# Sculpted Sidepod Radiators & Floor Bargeboards
	for side in [-1.0, 1.0]:
		_add_box(kart, Vector3(0.26, 0.22, 0.95), Vector3(side * 0.44, 0.18, 0.12), mat_body)
		_add_box(kart, Vector3(0.03, 0.24, 0.32), Vector3(side * 0.58, 0.19, -0.32), mat_carbon)
		_add_box(kart, Vector3(0.24, 0.18, 0.04), Vector3(side * 0.44, 0.18, -0.36), mat_carbon)

	# Overhead Engine Airbox Intake Scoop Above Driver
	_add_box(kart, Vector3(0.24, 0.22, 0.42), Vector3(0, 0.58, 0.28), mat_body)
	_add_box(kart, Vector3(0.16, 0.14, 0.04), Vector3(0, 0.60, 0.07), mat_carbon)

	# Titanium Halo Cockpit Safety Structure
	_add_cyl(kart, 0.024, 0.024, 0.35, Vector3(0, 0.44, -0.16), mat_halo).rotation_degrees.x = -22.0
	_add_box(kart, Vector3(0.44, 0.04, 0.38), Vector3(0, 0.50, 0.0), mat_halo)

	# Authentic Driver Figure
	_add_driver(kart, Vector3(0, 0.24, 0.02), 24.0, mat_body, mat_helmet, mat_visor, mat_gloves, true)

	# Bi-Plane Rear Wing with Endplates & DRS Actuator
	_add_box(kart, Vector3(0.04, 0.34, 0.12), Vector3(-0.25, 0.46, 0.82), mat_carbon)
	_add_box(kart, Vector3(0.04, 0.34, 0.12), Vector3(0.25, 0.46, 0.82), mat_carbon)
	var r_wing = _add_box(kart, Vector3(1.24, 0.035, 0.28), Vector3(0, 0.64, 0.88), mat_carbon)
	r_wing.rotation_degrees.x = -12.0
	_add_box(kart, Vector3(0.035, 0.28, 0.38), Vector3(-0.62, 0.62, 0.88), mat_carbon)
	_add_box(kart, Vector3(0.035, 0.28, 0.38), Vector3(0.62, 0.62, 0.88), mat_carbon)

	# Flashing Red FIA Rear Rain Light
	_add_box(kart, Vector3(0.08, 0.08, 0.04), Vector3(0, 0.18, 0.98), mat_fia_light)

	# Exposed Suspension Pushrods
	for side in [-1.0, 1.0]:
		var f_rod = _add_cyl(kart, 0.014, 0.014, 0.42, Vector3(side * 0.38, 0.16, -0.62), mat_halo)
		f_rod.rotation_degrees.z = -side * 35.0
		var r_rod = _add_cyl(kart, 0.014, 0.014, 0.44, Vector3(side * 0.42, 0.17, 0.62), mat_halo)
		r_rod.rotation_degrees.z = -side * 35.0

	# 4 Open-Wheel Slicks with Alloy Rims, Center Nuts & Brake Calipers
	_attach_wheels(kart, 0.16, 0.18, 0.17, 0.30, Vector3(0.64, 0.16, -0.62), Vector3(0.68, 0.17, 0.62), mat_tire, mat_rim, mat_nut, mat_brake)
	return kart

# ==============================================================================
# COMMON VEHICLE HELPERS (DRIVERS, 3D WHEELS, CONTACT SHADOWS)
# ==============================================================================

static func _add_contact_shadow(kart: Node3D, length: float, width: float) -> void:
	var mi = MeshInstance3D.new()
	mi.name = "ContactShadow"
	var plane = QuadMesh.new()
	plane.size = Vector2(width, length)
	plane.orientation = PlaneMesh.FACE_Y
	mi.mesh = plane
	mi.position = Vector3(0, 0.015, 0)
	mi.material_override = MaterialGenerator.get_material("contact_shadow")
	kart.add_child(mi)

static func _add_driver(kart: Node3D, pos: Vector3, rot_x: float, mat_suit: Material, mat_helmet: Material, mat_visor: Material, mat_gloves: Material, is_open: bool = true) -> Node3D:
	var driver_root = Node3D.new()
	driver_root.name = "DriverVisual"
	driver_root.position = pos
	driver_root.rotation_degrees.x = rot_x
	kart.add_child(driver_root)

	# Torso with racing harness
	_add_box(driver_root, Vector3(0.36, 0.36, 0.24), Vector3(0, 0.08, 0.0), mat_suit)
	var mat_belt = MaterialGenerator.create_pbr_material(Color(0.08, 0.09, 0.10), 0.2, 0.8)
	_add_box(driver_root, Vector3(0.05, 0.38, 0.01), Vector3(-0.09, 0.08, -0.125), mat_belt)
	_add_box(driver_root, Vector3(0.05, 0.38, 0.01), Vector3(0.09, 0.08, -0.125), mat_belt)

	# Articulated arms reaching forward to steering wheel
	if is_open:
		for side in [-1.0, 1.0]:
			var arm = _add_cyl(driver_root, 0.045, 0.04, 0.30, Vector3(side * 0.20, 0.12, -0.16), mat_suit)
			arm.rotation_degrees.x = 48.0
			arm.rotation_degrees.y = side * 12.0
			var hand = _add_sphere(driver_root, 0.042, Vector3(side * 0.14, 0.18, -0.32), mat_gloves)

	# Detailed Helmet with aerodynamic spoiler and reflective visor
	var head_node = Node3D.new()
	head_node.name = "DriverHead"
	head_node.position = Vector3(0, 0.34, 0.0)
	driver_root.add_child(head_node)
	var helmet_shell = _add_sphere(head_node, 0.135, Vector3.ZERO, mat_helmet)
	helmet_shell.scale = Vector3(0.92, 1.05, 1.15)
	# Helmet chin bar and visor
	_add_box(head_node, Vector3(0.20, 0.075, 0.06), Vector3(0, 0.01, -0.115), mat_visor)
	_add_box(head_node, Vector3(0.18, 0.04, 0.05), Vector3(0, -0.06, -0.105), mat_suit)
	_add_box(head_node, Vector3(0.12, 0.02, 0.06), Vector3(0, 0.08, 0.10), mat_suit) # Rear spoiler

	return driver_root

static func _attach_wheels(kart: Node3D, fr_r: float, fr_w: float, rr_r: float, rr_w: float, fr_offset: Vector3, rr_offset: Vector3, mat_tire: Material, mat_rim: Material, mat_acc: Material, mat_brake: Material = null) -> void:
	var cfgs = [
		{"name": "FrontWheel_0", "pos": Vector3(-fr_offset.x, fr_offset.y, fr_offset.z), "r": fr_r, "w": fr_w, "is_left": true},
		{"name": "FrontWheel_1", "pos": Vector3(fr_offset.x, fr_offset.y, fr_offset.z),  "r": fr_r, "w": fr_w, "is_left": false},
		{"name": "RearWheel_0",  "pos": Vector3(-rr_offset.x, rr_offset.y, rr_offset.z), "r": rr_r, "w": rr_w, "is_left": true},
		{"name": "RearWheel_1",  "pos": Vector3(rr_offset.x, rr_offset.y, rr_offset.z),  "r": rr_r, "w": rr_w, "is_left": false}
	]
	var mat_steel = MaterialGenerator.create_pbr_material(Color(0.85, 0.88, 0.92), 0.95, 0.15)
	if not mat_brake:
		mat_brake = MaterialGenerator.create_pbr_material(Color(0.95, 0.15, 0.15), 0.80, 0.20)

	for c in cfgs:
		var wn = Node3D.new()
		wn.name = c["name"]
		wn.position = c["pos"]
		kart.add_child(wn)

		# Stationary brake disc & caliper behind the spinning wheel
		var disc_x = 0.03 if c["is_left"] else -0.03
		var disc = _add_cyl(wn, c["r"] * 0.60, c["r"] * 0.60, 0.02, Vector3(disc_x, 0, 0), mat_steel)
		disc.rotation_degrees.z = 90.0
		var caliper = _add_box(wn, Vector3(0.035, c["r"] * 0.35, 0.06), Vector3(disc_x, c["r"] * 0.32, 0), mat_brake)

		# RollHub: spins around X axis with forward travel (v / r)
		var roll_hub = Node3D.new()
		roll_hub.name = "RollHub"
		wn.add_child(roll_hub)

		# Main rubber tire tread
		var tire = _add_cyl(roll_hub, c["r"], c["r"], c["w"], Vector3.ZERO, mat_tire)
		tire.rotation_degrees.z = 90.0

		# Beveled shoulder rings
		for s_offset in [-c["w"] * 0.48, c["w"] * 0.48]:
			var shoulder = _add_cyl(roll_hub, c["r"] * 0.95, c["r"] * 0.95, 0.02, Vector3(s_offset, 0, 0), mat_tire)
			shoulder.rotation_degrees.z = 90.0

		# Recessed alloy rim outer barrel
		var rim_outer = _add_cyl(roll_hub, c["r"] * 0.72, c["r"] * 0.72, c["w"] + 0.015, Vector3.ZERO, mat_rim)
		rim_outer.rotation_degrees.z = 90.0

		# 5-Spoke Alloy Wheel Pattern
		var sp_face_x = -c["w"] * 0.52 if c["is_left"] else c["w"] * 0.52
		for sp_i in range(5):
			var sp_ang = float(sp_i) * (PI * 2.0 / 5.0)
			var sp_mesh = _add_box(roll_hub, Vector3(0.02, c["r"] * 0.60, 0.035), Vector3(sp_face_x, 0, 0), mat_rim)
			sp_mesh.rotation_degrees.x = rad_to_deg(sp_ang)

		# Center lock nut
		var nut = _add_cyl(roll_hub, 0.038, 0.038, c["w"] + 0.04, Vector3.ZERO, mat_acc)
		nut.rotation_degrees.z = 90.0

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

static func build_start_gantry(track_w: float = 14.0) -> Node3D:
	var gantry = Node3D.new()
	gantry.name = "StartFinishGantry"
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_red = MaterialGenerator.get_material("neon_red")
	var mat_cyan = MaterialGenerator.get_material("neon_cyan")

	var half_w = track_w * 0.5 + 1.2
	var g_height = 8.5

	# Left and Right Steel Truss Support Columns
	for sx in [-half_w, half_w]:
		_add_box(gantry, Vector3(0.8, g_height, 0.8), Vector3(sx, g_height * 0.5, 0), mat_hull)
		_add_box(gantry, Vector3(1.4, 0.6, 1.4), Vector3(sx, 0.3, 0), mat_metal)
		# Diagonal truss bracing
		for ty in [2.5, 5.0, 7.0]:
			_add_box(gantry, Vector3(0.9, 0.15, 0.9), Vector3(sx, ty, 0), mat_metal)

	# Overhead Crossbeam Truss
	_add_box(gantry, Vector3(track_w + 3.2, 0.8, 0.8), Vector3(0, g_height, 0), mat_hull)
	_add_box(gantry, Vector3(track_w + 3.2, 0.2, 0.85), Vector3(0, g_height + 0.45, 0), mat_metal)

	# Main Start/Finish Banner Header matching Reference Screenshot 3
	var banner_w = track_w - 1.5
	var banner_h = 2.4
	# Red banner ("TURBO KART RUSH") with checkered borders
	var banner = _add_box(gantry, Vector3(banner_w, banner_h, 0.2), Vector3(0, g_height - 1.2, 0), MaterialGenerator.get_material("turbo_kart_rush_banner"))
	banner.name = "BannerHeader"

	# Ground Checkered Start/Finish Line Strip
	var ground_checker = _add_box(gantry, Vector3(track_w, 0.04, 2.4), Vector3(0, 0.02, 0), MaterialGenerator.get_material("checkered_flag"))
	ground_checker.name = "GroundCheckeredLine"

	# Row of 4 Suspended Countdown Starting Light Lamps matching Screenshot 3
	for li in range(4):
		var lx = -2.4 + li * 1.6
		var lamp_housing = _add_cyl(gantry, 0.32, 0.32, 0.25, Vector3(lx, g_height - 2.7, 0), mat_hull)
		lamp_housing.rotation_degrees.x = 90.0
		var lamp_lens = _add_cyl(gantry, 0.24, 0.24, 0.28, Vector3(lx, g_height - 2.7, 0.05), mat_red)
		lamp_lens.rotation_degrees.x = 90.0
		lamp_lens.name = "StartLight_%d" % li

	return gantry

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
	var mat_post = MaterialGenerator.get_material("sci_fi_metal")
	var mat_net = MaterialGenerator.get_material("dark_hull")
	var goal_w = 16.0
	var goal_h = 7.0
	var goal_d = 5.0

	# Heavy Glowing Front Goal Posts & Crossbar
	_add_cyl(goal, 0.35, 0.35, goal_h, Vector3(-goal_w * 0.5, goal_h * 0.5, 0), mat_team)
	_add_cyl(goal, 0.35, 0.35, goal_h, Vector3(goal_w * 0.5, goal_h * 0.5, 0), mat_team)
	var cb = _add_cyl(goal, 0.35, 0.35, goal_w, Vector3(0, goal_h, 0), mat_team)
	cb.rotation_degrees.z = 90.0

	# Ground frame
	var gb = _add_cyl(goal, 0.20, 0.20, goal_w, Vector3(0, 0.1, 0), mat_post)
	gb.rotation_degrees.z = 90.0

	# Rear Depth Struts
	var strut_l = _add_cyl(goal, 0.20, 0.20, goal_d, Vector3(-goal_w * 0.5, goal_h, -goal_d * 0.5), mat_post)
	strut_l.rotation_degrees.x = 90.0
	var strut_r = _add_cyl(goal, 0.20, 0.20, goal_d, Vector3(goal_w * 0.5, goal_h, -goal_d * 0.5), mat_post)
	strut_r.rotation_degrees.x = 90.0

	# Netting enclosure (back, top, left, right)
	_add_box(goal, Vector3(goal_w, goal_h, 0.08), Vector3(0, goal_h * 0.5, -goal_d), mat_net)
	_add_box(goal, Vector3(goal_w, 0.08, goal_d), Vector3(0, goal_h, -goal_d * 0.5), mat_net)
	_add_box(goal, Vector3(0.08, goal_h, goal_d), Vector3(-goal_w * 0.5, goal_h * 0.5, -goal_d * 0.5), mat_net)
	_add_box(goal, Vector3(0.08, goal_h, goal_d), Vector3(goal_w * 0.5, goal_h * 0.5, -goal_d * 0.5), mat_net)
	return goal

static func build_grandstand_with_crowd(stand_len: float = 24.0, stand_h: float = 8.0, stand_d: float = 8.0) -> Node3D:
	var stand = Node3D.new()
	stand.name = "GrandstandWithCrowd"
	var mat_conc = MaterialGenerator.get_material("grimy_concrete")
	var mat_crowd = MaterialGenerator.get_material("crowd_spectators")
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")

	var tiers = 4
	for t in range(tiers):
		var step_y = float(t + 1) * (stand_h / float(tiers))
		var step_z = float(t) * (stand_d / float(tiers))
		var step_h = stand_h / float(tiers)
		var step_d = stand_d / float(tiers)

		_add_box(stand, Vector3(stand_len, step_h, step_d), Vector3(0, step_y - step_h * 0.5, step_z), mat_conc)
		_add_box(stand, Vector3(stand_len - 0.4, 0.9, step_d * 0.7), Vector3(0, step_y + 0.45, step_z), mat_crowd)

	var canopy = _add_box(stand, Vector3(stand_len + 1.0, 0.25, stand_d + 2.0), Vector3(0, stand_h + 1.5, stand_d * 0.4), mat_metal)
	canopy.rotation_degrees.x = -8.0
	return stand

static func build_race_gantry_mesh() -> Node3D:
	return build_start_gantry(14.0)

static func build_speed_demon_kart() -> Node3D:
	return build_drift_kart(Color(1.0, 0.2, 0.2), "speeder")

static func build_drift_king_kart() -> Node3D:
	return build_drift_kart(Color(0.8, 0.2, 1.0), "phantom")

static func build_turbo_tank_kart() -> Node3D:
	return build_drift_kart(Color(0.2, 0.8, 0.3), "enforcer")

# ==============================================================================
# 7. MULTI-LOCATION ENVIRONMENT SCENERY PROPS
# ==============================================================================

static func build_palm_tree(height: float = 7.0) -> Node3D:
	var tree = Node3D.new()
	tree.name = "PalmTree"
	var mat_trunk = MaterialGenerator.get_material("pine_wood")
	var mat_fronds = MaterialGenerator.get_material("racing_turf")

	# Segmented curving trunk
	var segments = 6
	var seg_h = height / float(segments)
	var cur_pos = Vector3.ZERO
	var lean_angle = 12.0
	for i in range(segments):
		var r = lerpf(0.28, 0.16, float(i) / float(segments))
		var cyl = _add_cyl(tree, r * 0.9, r, seg_h, cur_pos + Vector3(0, seg_h * 0.5, 0), mat_trunk)
		cyl.rotation_degrees.z = lean_angle * (float(i) / float(segments))
		cur_pos += Vector3(sin(deg_to_rad(lean_angle)) * seg_h * 0.5, seg_h * 0.95, 0)

	# Palm Fronds Crown
	var crown_pos = cur_pos
	for frond_idx in range(8):
		var angle = float(frond_idx) * (360.0 / 8.0)
		var frond = _add_box(tree, Vector3(0.35, 0.04, 2.8), crown_pos + Vector3(0, 0.1, 1.2), mat_fronds)
		frond.rotation_degrees.y = angle
		frond.rotation_degrees.x = 24.0
	return tree

static func build_pine_tree(height: float = 9.0) -> Node3D:
	var tree = Node3D.new()
	tree.name = "PineTree"
	var mat_trunk = MaterialGenerator.get_material("pine_wood")
	var mat_needles = MaterialGenerator.get_material("pine_needles")

	# Trunk
	_add_cyl(tree, 0.22, 0.35, height * 0.4, Vector3(0, height * 0.2, 0), mat_trunk)

	# Layered Needle Cones
	var tiers = 4
	for t in range(tiers):
		var t_ratio = float(t) / float(tiers)
		var cone_y = height * (0.3 + t_ratio * 0.6)
		var cone_r = lerpf(2.2, 0.6, t_ratio)
		var cone_h = height * 0.28
		_add_cyl(tree, 0.05, cone_r, cone_h, Vector3(0, cone_y, 0), mat_needles)
	return tree

static func build_shipping_container(container_color: String = "container_blue", size: Vector3 = Vector3(2.8, 2.6, 6.5)) -> Node3D:
	var cont = Node3D.new()
	cont.name = "ShippingContainer"
	var mat_paint = MaterialGenerator.get_material(container_color)
	var mat_frame = MaterialGenerator.get_material("dark_hull")

	# Main container box
	_add_box(cont, size, Vector3(0, size.y * 0.5, 0), mat_paint)
	# Corner posts
	for cx in [-size.x * 0.5 + 0.06, size.x * 0.5 - 0.06]:
		for cz in [-size.z * 0.5 + 0.06, size.z * 0.5 - 0.06]:
			_add_box(cont, Vector3(0.14, size.y + 0.02, 0.14), Vector3(cx, size.y * 0.5, cz), mat_frame)
	# Door locking bars
	for bar_x in [-0.4, 0.4]:
		_add_cyl(cont, 0.025, 0.025, size.y * 0.85, Vector3(bar_x, size.y * 0.5, size.z * 0.5 + 0.02), mat_frame)
	return cont

static func build_harbor_crane(crane_height: float = 28.0) -> Node3D:
	var crane = Node3D.new()
	crane.name = "HarborGantryCrane"
	var mat_steel = MaterialGenerator.get_material("harbor_crane_metal")
	var mat_dark = MaterialGenerator.get_material("dark_hull")

	# 4 Stilt Legs spanning over containers
	var leg_span_x = 14.0
	var leg_span_z = 10.0
	for lx in [-leg_span_x * 0.5, leg_span_x * 0.5]:
		for lz in [-leg_span_z * 0.5, leg_span_z * 0.5]:
			var leg = _add_box(crane, Vector3(0.8, crane_height * 0.7, 0.8), Vector3(lx, crane_height * 0.35, lz), mat_steel)
			leg.rotation_degrees.z = -6.0 if lx < 0 else 6.0

	# Upper horizontal gantry bridge
	_add_box(crane, Vector3(leg_span_x + 8.0, 1.8, 3.2), Vector3(0, crane_height * 0.72, 0), mat_steel)
	# Operator Cab
	_add_box(crane, Vector3(2.4, 2.2, 2.8), Vector3(-leg_span_x * 0.35, crane_height * 0.65, 0), mat_dark)
	# High-reach cantilever boom
	var boom = _add_box(crane, Vector3(leg_span_x + 22.0, 1.4, 2.2), Vector3(6.0, crane_height * 0.85, 0), mat_steel)
	boom.rotation_degrees.z = -5.0
	return crane

static func build_neon_skyscraper(height: float = 55.0, width: float = 18.0, depth: float = 18.0, neon_col_name: String = "neon_cyan") -> Node3D:
	var bld = Node3D.new()
	bld.name = "NeonSkyscraper"
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_neon = MaterialGenerator.get_material(neon_col_name)

	# Main Tower Body
	_add_box(bld, Vector3(width, height, depth), Vector3(0, height * 0.5, 0), mat_hull)
	# Vertical Glowing Light Strips along 4 edges
	for ox in [-width * 0.5 + 0.05, width * 0.5 - 0.05]:
		for oz in [-depth * 0.5 + 0.05, depth * 0.5 - 0.05]:
			_add_box(bld, Vector3(0.2, height * 0.95, 0.2), Vector3(ox, height * 0.5, oz), mat_neon)
	# Horizontal Window Bands
	var floors = 8
	for f in range(1, floors):
		var fy = height * (float(f) / float(floors))
		_add_box(bld, Vector3(width + 0.1, 0.35, depth + 0.1), Vector3(0, fy, 0), mat_neon)
	# Rooftop Spire / Antenna
	var spire = _add_cyl(bld, 0.05, 0.35, 12.0, Vector3(0, height + 6.0, 0), mat_neon)
	return bld

static func build_rock_arch(width: float = 24.0, height: float = 16.0) -> Node3D:
	var arch = Node3D.new()
	arch.name = "CanyonRockArch"
	var mat_rock = MaterialGenerator.get_material("canyon_rock")

	# Left pillar
	var p_left = _add_box(arch, Vector3(5.0, height, 5.0), Vector3(-width * 0.5, height * 0.5, 0), mat_rock)
	p_left.rotation_degrees.z = -8.0
	# Right pillar
	var p_right = _add_box(arch, Vector3(5.0, height, 5.0), Vector3(width * 0.5, height * 0.5, 0), mat_rock)
	p_right.rotation_degrees.z = 8.0
	# Overhead arch span
	var top = _add_box(arch, Vector3(width + 6.0, 4.5, 5.5), Vector3(0, height + 1.2, 0), mat_rock)
	return arch

static func build_pit_building(num_garages: int = 6) -> Node3D:
	var root = Node3D.new()
	root.name = "PitBuilding"
	var mat_conc = MaterialGenerator.get_material("grimy_concrete")
	var mat_glass = MaterialGenerator.get_material("glass_cockpit")
	var mat_metal = MaterialGenerator.get_material("sci_fi_metal")
	var mat_dark = MaterialGenerator.get_material("dark_hull")
	var mat_banner = MaterialGenerator.get_material("stadium_score_banner_blue")

	var garage_w = 7.5
	var total_len = float(num_garages) * garage_w
	var build_h = 8.5
	var build_d = 14.0

	# Main 2-Story Pit Complex Structure
	_add_box(root, Vector3(total_len, build_h, build_d), Vector3(0, build_h * 0.5, 0), mat_conc)
	# Upper VIP Hospitality Suite Glass Facade
	_add_box(root, Vector3(total_len - 1.0, 2.8, 0.2), Vector3(0, build_h * 0.72, -build_d * 0.5 - 0.05), mat_glass)
	# Rooftop Paddock Terrace & Railings
	_add_box(root, Vector3(total_len + 0.8, 0.4, build_d + 0.8), Vector3(0, build_h + 0.2, 0), mat_metal)
	_add_box(root, Vector3(total_len, 0.9, 0.08), Vector3(0, build_h + 0.85, -build_d * 0.5), mat_dark)

	# Ground-Level Open Pit Garages
	for g in range(num_garages):
		var gx = -total_len * 0.5 + float(g) * garage_w + garage_w * 0.5
		# Recessed dark garage bay interior
		_add_box(root, Vector3(garage_w - 0.8, 4.2, 0.15), Vector3(gx, 2.1, -build_d * 0.5 - 0.02), mat_dark)
		# Garage division column
		_add_box(root, Vector3(0.5, 4.4, 0.4), Vector3(gx - garage_w * 0.5, 2.2, -build_d * 0.5 - 0.1), mat_metal)
		# Team sponsor banner over garage bay
		_add_box(root, Vector3(garage_w - 1.0, 0.8, 0.1), Vector3(gx, 4.6, -build_d * 0.5 - 0.08), mat_banner)

	# Attached Race Control & Timing Tower on the right flank
	var tower_x = total_len * 0.5 + 4.5
	var tower_h = 16.0
	_add_box(root, Vector3(7.0, tower_h, 9.0), Vector3(tower_x, tower_h * 0.5, 0), mat_conc)
	# 360-degree glass observation deck
	_add_box(root, Vector3(8.2, 3.4, 10.2), Vector3(tower_x, tower_h - 2.5, 0), mat_glass)
	# Digital Timing Board Display Screen
	_add_box(root, Vector3(0.15, 6.0, 4.5), Vector3(tower_x - 3.55, tower_h * 0.5, 0), mat_banner)

	return root

static func build_cargo_ship(ship_length: float = 75.0) -> Node3D:
	var ship = Node3D.new()
	ship.name = "CargoShip"
	var mat_hull = MaterialGenerator.get_material("dark_hull")
	var mat_deck = MaterialGenerator.get_material("grimy_concrete")
	var mat_bridge = MaterialGenerator.get_material("sci_fi_metal")
	var mat_glass = MaterialGenerator.get_material("glass_cockpit")

	var ship_w = 16.0
	var ship_h = 10.0

	# Cargo Vessel Lower Hull
	_add_box(ship, Vector3(ship_length, ship_h, ship_w), Vector3(0, ship_h * 0.5, 0), mat_hull)
	# Main Deck Plane
	_add_box(ship, Vector3(ship_length - 2.0, 0.3, ship_w - 0.8), Vector3(0, ship_h + 0.15, 0), mat_deck)

	# Multi-tier shipping container stacks on deck (red, blue, yellow, green)
	var colors = ["container_red", "container_blue", "container_yellow", "container_red"]
	for stack_x in range(-int(ship_length * 0.35), int(ship_length * 0.25), 8):
		for stack_z in [-3.5, 3.5]:
			for stack_y in [0, 2.7]:
				var col_name = colors[(abs(stack_x) + int(stack_z * 2.0) + int(stack_y)) % colors.size()]
				var cont = build_shipping_container(col_name, Vector3(2.6, 2.5, 6.2))
				cont.position = Vector3(float(stack_x), ship_h + 0.3 + float(stack_y), stack_z)
				ship.add_child(cont)

	# Stern Navigation Bridge Tower
	var bridge_x = ship_length * 0.38
	_add_box(ship, Vector3(9.0, 11.0, 14.0), Vector3(bridge_x, ship_h + 5.5, 0), mat_bridge)
	_add_box(ship, Vector3(9.2, 2.2, 14.2), Vector3(bridge_x, ship_h + 9.5, 0), mat_glass)
	# Radar Mast / Chimney Exhaust
	_add_cyl(ship, 0.8, 1.2, 5.0, Vector3(bridge_x - 2.5, ship_h + 13.5, 0), mat_hull)

	return ship

static func build_suspension_bridge_tower(tower_height: float = 32.0) -> Node3D:
	var bridge = Node3D.new()
	bridge.name = "SuspensionBridgeTower"
	var mat_tower = MaterialGenerator.get_material("sci_fi_metal")
	var mat_cable = MaterialGenerator.get_material("dark_hull")

	# Twin Vertical Suspension Pylons
	for pz in [-8.5, 8.5]:
		_add_box(bridge, Vector3(2.2, tower_height, 2.2), Vector3(0, tower_height * 0.5, pz), mat_tower)
		_add_box(bridge, Vector3(2.6, 0.8, 2.6), Vector3(0, tower_height * 0.75, pz), mat_tower)

	# Crossbeam Braces
	_add_box(bridge, Vector3(2.0, 1.4, 17.0), Vector3(0, tower_height * 0.50, 0), mat_tower)
	_add_box(bridge, Vector3(2.0, 1.6, 17.0), Vector3(0, tower_height * 0.95, 0), mat_tower)

	# Main Steel Suspension Cables Angled to Roadway Deck
	for pz in [-8.5, 8.5]:
		var cable_fwd = _add_cyl(bridge, 0.06, 0.06, tower_height * 1.1, Vector3(0, tower_height * 0.55, pz), mat_cable)
		cable_fwd.rotation_degrees.z = 24.0
		cable_fwd.position.x = -tower_height * 0.22

		var cable_back = _add_cyl(bridge, 0.06, 0.06, tower_height * 1.1, Vector3(0, tower_height * 0.55, pz), mat_cable)
		cable_back.rotation_degrees.z = -24.0
		cable_back.position.x = tower_height * 0.22

	return bridge

static func build_marshal_post() -> Node3D:
	var post = Node3D.new()
	post.name = "MarshalSafetyPost"
	var mat_post = MaterialGenerator.get_material("dark_hull")
	var mat_roof = MaterialGenerator.get_material("sci_fi_metal")
	var mat_marshal = MaterialGenerator.create_pbr_material(Color(1.0, 0.45, 0.05), 0.1, 0.6) # High-vis orange vest
	var mat_flag = MaterialGenerator.create_pbr_material(Color(0.15, 0.95, 0.25), 0.1, 0.5)   # Green safety flag

	# Raised Marshalling Platform
	_add_box(post, Vector3(2.4, 1.6, 2.4), Vector3(0, 0.8, 0), mat_post)
	_add_box(post, Vector3(2.6, 0.1, 2.6), Vector3(0, 3.2, 0), mat_roof)
	# Platform canopy roof posts
	for ox in [-1.1, 1.1]:
		for oz in [-1.1, 1.1]:
			_add_cyl(post, 0.04, 0.04, 1.6, Vector3(ox, 2.4, oz), mat_post)

	# Marshal Figure in High-Vis Orange
	_add_cyl(post, 0.18, 0.18, 0.85, Vector3(0, 2.05, 0), mat_marshal)
	_add_sphere(post, 0.12, Vector3(0, 2.6, 0), MaterialGenerator.get_material("white_plastic"))

	# Safety Flag
	var flag_pole = _add_cyl(post, 0.015, 0.015, 1.6, Vector3(0.5, 2.4, 0), mat_post)
	flag_pole.rotation_degrees.z = -25.0
	var flag_cloth = _add_box(post, Vector3(0.02, 0.45, 0.65), Vector3(0.8, 2.8, 0), mat_flag)

	return post

static func build_mountain_peak(width: float = 65.0, height: float = 55.0) -> Node3D:
	var mtn = Node3D.new()
	mtn.name = "MountainPeak"
	var mat_rock = MaterialGenerator.get_material("alpine_rock")
	var mat_snow = MaterialGenerator.get_material("snow_ice")

	# Base Mountain Massif
	var mi_base = MeshInstance3D.new()
	var prism_base = PrismMesh.new()
	prism_base.size = Vector3(width, height * 0.75, width * 0.85)
	mi_base.mesh = prism_base
	mi_base.position = Vector3(0, height * 0.375, 0)
	mi_base.material_override = mat_rock
	mtn.add_child(mi_base)

	# Snow Cap Summit
	var mi_snow = MeshInstance3D.new()
	var prism_snow = PrismMesh.new()
	prism_snow.size = Vector3(width * 0.52, height * 0.42, width * 0.48)
	mi_snow.mesh = prism_snow
	mi_snow.position = Vector3(0, height * 0.78, 0)
	mi_snow.material_override = mat_snow
	mtn.add_child(mi_snow)

	return mtn

static func build_alpine_chalet() -> Node3D:
	var chalet = Node3D.new()
	chalet.name = "AlpineChalet"
	var mat_wood = MaterialGenerator.get_material("pine_wood")
	var mat_roof = MaterialGenerator.get_material("dark_hull")
	var mat_snow = MaterialGenerator.get_material("snow_ice")
	var mat_glass = MaterialGenerator.get_material("glass_cockpit")

	# Main Timber Lodge Body
	_add_box(chalet, Vector3(8.5, 5.0, 7.0), Vector3(0, 2.5, 0), mat_wood)
	# Balcony
	_add_box(chalet, Vector3(9.2, 0.2, 2.0), Vector3(0, 3.2, 3.5), mat_wood)
	_add_box(chalet, Vector3(9.2, 0.8, 0.08), Vector3(0, 3.7, 4.4), mat_wood)
	# Illuminated Window Glass
	_add_box(chalet, Vector3(1.8, 1.2, 0.05), Vector3(-2.2, 3.8, 3.52), mat_glass)
	_add_box(chalet, Vector3(1.8, 1.2, 0.05), Vector3(2.2, 3.8, 3.52), mat_glass)

	# Steep Sloping Gabled Roof
	var mi_roof = MeshInstance3D.new()
	var prism_roof = PrismMesh.new()
	prism_roof.size = Vector3(9.8, 3.5, 8.2)
	mi_roof.mesh = prism_roof
	mi_roof.position = Vector3(0, 6.75, 0)
	mi_roof.material_override = mat_roof
	chalet.add_child(mi_roof)

	# Snow Layer on Roof
	var mi_snow = MeshInstance3D.new()
	var prism_snow = PrismMesh.new()
	prism_snow.size = Vector3(9.9, 0.3, 8.3)
	mi_snow.mesh = prism_snow
	mi_snow.position = Vector3(0, 7.8, 0)
	mi_snow.material_override = mat_snow
	chalet.add_child(mi_snow)

	# Stone Chimney
	_add_box(chalet, Vector3(1.0, 4.5, 1.0), Vector3(2.8, 6.5, -1.5), MaterialGenerator.get_material("grimy_concrete"))

	return chalet


