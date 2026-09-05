class_name MeshBuilder
extends RefCounted

## Procedural compound mesh builder for VoltArena.
## Generates original production-quality 3D assets: multi-part weapons,
## articulated characters/mutants, detailed vehicles, and stylized props.

static func build_pulse_rifle() -> Node3D:
	var root = Node3D.new()
	root.name = "PulseRifleVisual"

	# Upper Receiver (main body)
	var receiver = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = Vector3(0.09, 0.12, 0.55)
	receiver.mesh = r_box
	receiver.position = Vector3(0, 0, -0.15)
	receiver.material_override = MaterialGenerator.get_material("sci_fi_metal")
	root.add_child(receiver)

	# Tactical Rail on top
	var rail = MeshInstance3D.new()
	var rail_box = BoxMesh.new()
	rail_box.size = Vector3(0.04, 0.02, 0.35)
	rail.mesh = rail_box
	rail.position = Vector3(0, 0.07, -0.15)
	rail.material_override = MaterialGenerator.get_material("dark_hull")
	root.add_child(rail)

	# Holo-Sight Optic
	var sight = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.06, 0.06, 0.08)
	sight.mesh = s_box
	sight.position = Vector3(0, 0.11, -0.08)
	sight.material_override = MaterialGenerator.get_material("neon_cyan")
	root.add_child(sight)

	# Fluted Barrel
	var barrel = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.025
	cyl.bottom_radius = 0.025
	cyl.height = 0.38
	barrel.mesh = cyl
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0.02, -0.48)
	barrel.material_override = MaterialGenerator.get_material("dark_hull")
	root.add_child(barrel)

	# Muzzle Brake / Suppressor
	var muzzle = MeshInstance3D.new()
	var m_cyl = CylinderMesh.new()
	m_cyl.top_radius = 0.035
	m_cyl.bottom_radius = 0.035
	m_cyl.height = 0.08
	muzzle.mesh = m_cyl
	muzzle.rotation_degrees = Vector3(90, 0, 0)
	muzzle.position = Vector3(0, 0.02, -0.68)
	muzzle.material_override = MaterialGenerator.get_material("neon_cyan")
	root.add_child(muzzle)

	# Ergonomic Pistol Grip
	var grip = MeshInstance3D.new()
	var g_box = BoxMesh.new()
	g_box.size = Vector3(0.06, 0.16, 0.07)
	grip.mesh = g_box
	grip.position = Vector3(0, -0.12, 0.04)
	grip.rotation_degrees = Vector3(18, 0, 0)
	grip.material_override = MaterialGenerator.get_material("dark_hull")
	root.add_child(grip)

	# Curved Magazine
	var mag = MeshInstance3D.new()
	var m_box = BoxMesh.new()
	m_box.size = Vector3(0.05, 0.20, 0.08)
	mag.mesh = m_box
	mag.position = Vector3(0, -0.12, -0.12)
	mag.rotation_degrees = Vector3(-12, 0, 0)
	mag.material_override = MaterialGenerator.get_material("sci_fi_metal")
	root.add_child(mag)

	# Energy Glow Strip
	var strip = MeshInstance3D.new()
	var s_strip = BoxMesh.new()
	s_strip.size = Vector3(0.095, 0.02, 0.32)
	strip.mesh = s_strip
	strip.position = Vector3(0, 0.01, -0.18)
	strip.material_override = MaterialGenerator.get_material("neon_cyan")
	root.add_child(strip)

	return root

static func build_scatter_cannon() -> Node3D:
	var root = Node3D.new()
	root.name = "ScatterCannonVisual"

	# Heavy Receiver
	var receiver = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = Vector3(0.14, 0.16, 0.50)
	receiver.mesh = r_box
	receiver.position = Vector3(0, 0, -0.12)
	receiver.material_override = MaterialGenerator.get_material("dark_hull")
	root.add_child(receiver)

	# Twin Heavy Barrels
	var b_left = MeshInstance3D.new()
	var b_right = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.035
	cyl.bottom_radius = 0.035
	cyl.height = 0.42
	b_left.mesh = cyl
	b_left.rotation_degrees = Vector3(90, 0, 0)
	b_left.position = Vector3(-0.04, 0.03, -0.44)
	b_left.material_override = MaterialGenerator.get_material("sci_fi_metal")
	root.add_child(b_left)

	b_right.mesh = cyl
	b_right.rotation_degrees = Vector3(90, 0, 0)
	b_right.position = Vector3(0.04, 0.03, -0.44)
	b_right.material_override = MaterialGenerator.get_material("sci_fi_metal")
	root.add_child(b_right)

	# Heat Shield Shroud
	var shroud = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.15, 0.10, 0.30)
	shroud.mesh = s_box
	shroud.position = Vector3(0, 0.03, -0.38)
	shroud.material_override = MaterialGenerator.get_material("neon_orange")
	root.add_child(shroud)

	# Pump Action Grip
	var pump = MeshInstance3D.new()
	var p_box = BoxMesh.new()
	p_box.size = Vector3(0.12, 0.08, 0.16)
	pump.mesh = p_box
	pump.position = Vector3(0, -0.06, -0.32)
	pump.material_override = MaterialGenerator.get_material("sci_fi_metal")
	root.add_child(pump)

	# Stock & Grip
	var grip = MeshInstance3D.new()
	var g_box = BoxMesh.new()
	g_box.size = Vector3(0.08, 0.18, 0.09)
	grip.mesh = g_box
	grip.position = Vector3(0, -0.12, 0.06)
	grip.rotation_degrees = Vector3(20, 0, 0)
	grip.material_override = MaterialGenerator.get_material("dark_hull")
	root.add_child(grip)

	return root

static func build_rail_driver() -> Node3D:
	var root = Node3D.new()
	root.name = "RailDriverVisual"

	# Sleek Angular Chassis
	var body = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.10, 0.14, 0.65)
	body.mesh = b_box
	body.position = Vector3(0, 0, -0.20)
	body.material_override = MaterialGenerator.get_material("sci_fi_metal")
	root.add_child(body)

	# Top and Bottom Magnetic Accelerator Rails
	var top_rail = MeshInstance3D.new()
	var bot_rail = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = Vector3(0.03, 0.03, 0.55)
	top_rail.mesh = r_box
	top_rail.position = Vector3(0, 0.06, -0.55)
	top_rail.material_override = MaterialGenerator.get_material("neon_blue")
	root.add_child(top_rail)

	bot_rail.mesh = r_box
	bot_rail.position = Vector3(0, -0.04, -0.55)
	bot_rail.material_override = MaterialGenerator.get_material("neon_blue")
	root.add_child(bot_rail)

	# Heavy Battery Capacitor Core
	var core = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.05
	cyl.height = 0.22
	core.mesh = cyl
	core.position = Vector3(0, -0.02, -0.15)
	core.material_override = MaterialGenerator.get_material("neon_magenta")
	root.add_child(core)

	# Long-Range Sniper Scope
	var scope = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 0.028
	s_cyl.bottom_radius = 0.028
	s_cyl.height = 0.28
	scope.mesh = s_cyl
	scope.rotation_degrees = Vector3(90, 0, 0)
	scope.position = Vector3(0, 0.12, -0.18)
	scope.material_override = MaterialGenerator.get_material("dark_hull")
	root.add_child(scope)

	# Rear Stock
	var stock = MeshInstance3D.new()
	var st_box = BoxMesh.new()
	st_box.size = Vector3(0.08, 0.12, 0.25)
	stock.mesh = st_box
	stock.position = Vector3(0, -0.02, 0.18)
	stock.material_override = MaterialGenerator.get_material("dark_hull")
	root.add_child(stock)

	return root

static func build_grenade_launcher() -> Node3D:
	var root = Node3D.new()
	root.name = "GrenadeLauncherVisual"

	# Receiver
	var rec = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = Vector3(0.12, 0.14, 0.40)
	rec.mesh = r_box
	rec.position = Vector3(0, 0, -0.10)
	rec.material_override = MaterialGenerator.get_material("sci_fi_metal")
	root.add_child(rec)

	# Rotary Cylinder Drum (6-chamber grenade drum)
	var drum = MeshInstance3D.new()
	var d_cyl = CylinderMesh.new()
	d_cyl.top_radius = 0.09
	d_cyl.bottom_radius = 0.09
	d_cyl.height = 0.18
	drum.mesh = d_cyl
	drum.position = Vector3(0, -0.02, -0.16)
	drum.material_override = MaterialGenerator.get_material("dark_hull")
	root.add_child(drum)

	# Wide Bore Launcher Barrel
	var barrel = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.065
	b_cyl.bottom_radius = 0.065
	b_cyl.height = 0.35
	barrel.mesh = b_cyl
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0.04, -0.42)
	barrel.material_override = MaterialGenerator.get_material("dark_hull")
	root.add_child(barrel)

	# Grip and Stock
	var grip = MeshInstance3D.new()
	var g_box = BoxMesh.new()
	g_box.size = Vector3(0.07, 0.16, 0.08)
	grip.mesh = g_box
	grip.position = Vector3(0, -0.14, 0.04)
	grip.rotation_degrees = Vector3(15, 0, 0)
	grip.material_override = MaterialGenerator.get_material("sci_fi_metal")
	root.add_child(grip)

	return root

static func build_plasma_cutter() -> Node3D:
	var root = Node3D.new()
	root.name = "PlasmaCutterVisual"

	# Main Body
	var body = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.10, 0.12, 0.45)
	body.mesh = b_box
	body.position = Vector3(0, 0, -0.10)
	body.material_override = MaterialGenerator.get_material("dark_hull")
	root.add_child(body)

	# Dual Plasma Emitter Prongs
	var p_left = MeshInstance3D.new()
	var p_right = MeshInstance3D.new()
	var p_box = BoxMesh.new()
	p_box.size = Vector3(0.025, 0.04, 0.28)

	p_left.mesh = p_box
	p_left.position = Vector3(-0.06, 0.02, -0.42)
	p_left.material_override = MaterialGenerator.get_material("neon_cyan")
	root.add_child(p_left)

	p_right.mesh = p_box
	p_right.position = Vector3(0.06, 0.02, -0.42)
	p_right.material_override = MaterialGenerator.get_material("neon_cyan")
	root.add_child(p_right)

	# Plasma Arc Lens
	var lens = MeshInstance3D.new()
	var l_sphere = SphereMesh.new()
	l_sphere.radius = 0.035
	l_sphere.height = 0.07
	lens.mesh = l_sphere
	lens.position = Vector3(0, 0.02, -0.32)
	lens.material_override = MaterialGenerator.get_material("neon_magenta")
	root.add_child(lens)

	return root

static func build_cyber_soldier(is_bot: bool = false, accent_color: Color = Color(0.0, 0.9, 1.0)) -> Node3D:
	var soldier = Node3D.new()
	soldier.name = "CyberSoldierVisual"

	var armor_mat = MaterialGenerator.get_material("dark_hull")
	var under_mat = MaterialGenerator.get_material("sci_fi_metal")
	var glow_mat = MaterialGenerator.create_pbr_material(accent_color, 0.5, 0.2, accent_color, 2.5)

	# Pelvis / Hips
	var pelvis = Node3D.new()
	pelvis.name = "Pelvis"
	pelvis.position = Vector3(0, 0.85, 0)
	soldier.add_child(pelvis)

	var p_mesh = MeshInstance3D.new()
	var p_box = BoxMesh.new()
	p_box.size = Vector3(0.40, 0.22, 0.28)
	p_mesh.mesh = p_box
	p_mesh.material_override = armor_mat
	pelvis.add_child(p_mesh)

	# Torso / Chest
	var chest = Node3D.new()
	chest.name = "Chest"
	chest.position = Vector3(0, 0.32, 0)
	pelvis.add_child(chest)

	var c_mesh = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.48, 0.44, 0.32)
	c_mesh.mesh = c_box
	c_mesh.material_override = armor_mat
	chest.add_child(c_mesh)

	# Core Energy Reactor on chest
	var reactor = MeshInstance3D.new()
	var r_cyl = CylinderMesh.new()
	r_cyl.top_radius = 0.06
	r_cyl.bottom_radius = 0.06
	r_cyl.height = 0.06
	reactor.mesh = r_cyl
	reactor.rotation_degrees = Vector3(90, 0, 0)
	reactor.position = Vector3(0, 0.04, 0.17)
	reactor.material_override = glow_mat
	chest.add_child(reactor)

	# Head / Helmet
	var head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.36, 0)
	chest.add_child(head)

	var h_mesh = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.26, 0.28, 0.28)
	h_mesh.mesh = h_box
	h_mesh.material_override = armor_mat
	head.add_child(h_mesh)

	# Visor
	var visor = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.24, 0.08, 0.08)
	visor.mesh = v_box
	visor.position = Vector3(0, 0.02, 0.15)
	visor.material_override = glow_mat
	head.add_child(visor)

	# Left Arm Hierarchy
	var l_shoulder = Node3D.new()
	l_shoulder.name = "LeftShoulder"
	l_shoulder.position = Vector3(-0.32, 0.14, 0)
	chest.add_child(l_shoulder)

	var l_arm_mesh = MeshInstance3D.new()
	var arm_box = BoxMesh.new()
	arm_box.size = Vector3(0.14, 0.34, 0.16)
	l_arm_mesh.mesh = arm_box
	l_arm_mesh.position = Vector3(0, -0.15, 0)
	l_arm_mesh.material_override = under_mat
	l_shoulder.add_child(l_arm_mesh)

	# Right Arm Hierarchy
	var r_shoulder = Node3D.new()
	r_shoulder.name = "RightShoulder"
	r_shoulder.position = Vector3(0.32, 0.14, 0)
	chest.add_child(r_shoulder)

	var r_arm_mesh = MeshInstance3D.new()
	r_arm_mesh.mesh = arm_box
	r_arm_mesh.position = Vector3(0, -0.15, 0)
	r_arm_mesh.material_override = under_mat
	r_shoulder.add_child(r_arm_mesh)

	# Left Leg Hierarchy
	var l_hip = Node3D.new()
	l_hip.name = "LeftHip"
	l_hip.position = Vector3(-0.15, -0.15, 0)
	pelvis.add_child(l_hip)

	var l_leg_mesh = MeshInstance3D.new()
	var leg_box = BoxMesh.new()
	leg_box.size = Vector3(0.16, 0.58, 0.18)
	l_leg_mesh.mesh = leg_box
	l_leg_mesh.position = Vector3(0, -0.28, 0)
	l_leg_mesh.material_override = armor_mat
	l_hip.add_child(l_leg_mesh)

	# Right Leg Hierarchy
	var r_hip = Node3D.new()
	r_hip.name = "RightHip"
	r_hip.position = Vector3(0.15, -0.15, 0)
	pelvis.add_child(r_hip)

	var r_leg_mesh = MeshInstance3D.new()
	r_leg_mesh.mesh = leg_box
	r_leg_mesh.position = Vector3(0, -0.28, 0)
	r_leg_mesh.material_override = armor_mat
	r_hip.add_child(r_leg_mesh)

	return soldier

static func build_crawler_mesh() -> Node3D:
	var root = Node3D.new()
	root.name = "CrawlerVisual"

	var chitin_mat = MaterialGenerator.get_material("enemy_crawler")
	var eye_mat = MaterialGenerator.get_material("neon_magenta")

	# Low segmented thorax / carapace
	var thorax = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.65, 0.35, 0.95)
	thorax.mesh = t_box
	thorax.position = Vector3(0, 0.35, 0)
	thorax.material_override = chitin_mat
	root.add_child(thorax)

	# Dorsal Spines
	for z in [-0.2, 0.0, 0.2]:
		var spine = MeshInstance3D.new()
		var s_cone = CylinderMesh.new()
		s_cone.top_radius = 0.01
		s_cone.bottom_radius = 0.04
		s_cone.height = 0.22
		spine.mesh = s_cone
		spine.position = Vector3(0, 0.60, z)
		spine.material_override = MaterialGenerator.get_material("dark_hull")
		root.add_child(spine)

	# Cluster Eyes
	for x in [-0.12, -0.04, 0.04, 0.12]:
		var eye = MeshInstance3D.new()
		var e_sphere = SphereMesh.new()
		e_sphere.radius = 0.03
		e_sphere.height = 0.06
		eye.mesh = e_sphere
		eye.position = Vector3(x, 0.42, -0.50)
		eye.material_override = eye_mat
		root.add_child(eye)

	# Articulated Spider Claw Limbs (6 legs)
	var leg_mesh = BoxMesh.new()
	leg_mesh.size = Vector3(0.08, 0.10, 0.50)
	for i in range(3):
		var z_off = -0.25 + i * 0.25
		# Left leg
		var l_leg = MeshInstance3D.new()
		l_leg.mesh = leg_mesh
		l_leg.position = Vector3(-0.48, 0.22, z_off)
		l_leg.rotation_degrees = Vector3(15, 30, -25)
		l_leg.material_override = chitin_mat
		root.add_child(l_leg)

		# Right leg
		var r_leg = MeshInstance3D.new()
		r_leg.mesh = leg_mesh
		r_leg.position = Vector3(0.48, 0.22, z_off)
		r_leg.rotation_degrees = Vector3(15, -30, 25)
		r_leg.material_override = chitin_mat
		root.add_child(r_leg)

	return root

static func build_stalker_mesh() -> Node3D:
	var root = Node3D.new()
	root.name = "StalkerVisual"

	var shadow_mat = MaterialGenerator.get_material("dark_hull")
	var bio_mat = MaterialGenerator.get_material("neon_green")

	# Tall slender torso
	var torso = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.38, 1.15, 0.32)
	torso.mesh = t_box
	torso.position = Vector3(0, 0.95, 0)
	torso.material_override = shadow_mat
	root.add_child(torso)

	# Bioluminescent Ribs
	for y in [0.70, 0.85, 1.00, 1.15]:
		var rib = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		r_box.size = Vector3(0.42, 0.04, 0.34)
		rib.mesh = r_box
		rib.position = Vector3(0, y, 0)
		rib.material_override = bio_mat
		root.add_child(rib)

	# Skull Mask / Head
	var head = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.24, 0.32, 0.28)
	head.mesh = h_box
	head.position = Vector3(0, 1.62, -0.05)
	head.material_override = shadow_mat
	root.add_child(head)

	var eye = MeshInstance3D.new()
	var e_box = BoxMesh.new()
	e_box.size = Vector3(0.18, 0.06, 0.08)
	eye.mesh = e_box
	eye.position = Vector3(0, 1.66, -0.20)
	eye.material_override = bio_mat
	root.add_child(eye)

	# Elongated Blade Arms
	var arm_mesh = BoxMesh.new()
	arm_mesh.size = Vector3(0.08, 0.95, 0.10)
	var l_arm = MeshInstance3D.new()
	l_arm.mesh = arm_mesh
	l_arm.position = Vector3(-0.32, 0.85, -0.15)
	l_arm.rotation_degrees = Vector3(30, 0, 0)
	l_arm.material_override = shadow_mat
	root.add_child(l_arm)

	var r_arm = MeshInstance3D.new()
	r_arm.mesh = arm_mesh
	r_arm.position = Vector3(0.32, 0.85, -0.15)
	r_arm.rotation_degrees = Vector3(30, 0, 0)
	r_arm.material_override = shadow_mat
	root.add_child(r_arm)

	return root

static func build_brute_mesh() -> Node3D:
	var root = Node3D.new()
	root.name = "BruteVisual"

	var armor_mat = MaterialGenerator.get_material("dark_concrete")
	var flesh_mat = MaterialGenerator.get_material("enemy_crawler")
	var lava_mat = MaterialGenerator.get_material("neon_red")

	# Massive hunchbacked torso
	var torso = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(1.20, 1.40, 1.05)
	torso.mesh = t_box
	torso.position = Vector3(0, 1.30, 0)
	torso.material_override = armor_mat
	root.add_child(torso)

	# Molten Fissures / Glowing Veins
	var vein = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.85, 0.08, 1.10)
	vein.mesh = v_box
	vein.position = Vector3(0, 1.40, 0)
	vein.material_override = lava_mat
	root.add_child(vein)

	# Shoulder Spikes / Bone Plates
	for s_x in [-0.75, 0.75]:
		var spike = MeshInstance3D.new()
		var cone = CylinderMesh.new()
		cone.top_radius = 0.02
		cone.bottom_radius = 0.16
		cone.height = 0.55
		spike.mesh = cone
		spike.position = Vector3(s_x, 1.95, 0)
		spike.rotation_degrees = Vector3(0, 0, -35 * signf(s_x))
		spike.material_override = MaterialGenerator.get_material("sci_fi_metal")
		root.add_child(spike)

	# Heavy Boulder Fists
	for f_x in [-0.85, 0.85]:
		var fist = MeshInstance3D.new()
		var f_box = BoxMesh.new()
		f_box.size = Vector3(0.48, 0.65, 0.48)
		fist.mesh = f_box
		fist.position = Vector3(f_x, 0.60, -0.30)
		fist.material_override = armor_mat
		root.add_child(fist)

	return root

static func build_rocket_car(team_id: int = 0) -> Node3D:
	var car = Node3D.new()
	car.name = "RocketCarVisual"

	var team_mat = MaterialGenerator.get_material("neon_cyan" if team_id == 0 else "neon_orange")
	var body_mat = MaterialGenerator.get_material("dark_hull")
	var wheel_mat = MaterialGenerator.get_material("asphalt_track")

	# Aerodynamic Low-Slung Chassis
	var chassis = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(1.85, 0.55, 3.60)
	chassis.mesh = c_box
	chassis.position = Vector3(0, 0.45, 0)
	chassis.material_override = team_mat
	car.add_child(chassis)

	# Cabin Cockpit / Slanted Windshield
	var cabin = MeshInstance3D.new()
	var cb_box = BoxMesh.new()
	cb_box.size = Vector3(1.30, 0.45, 1.60)
	cabin.mesh = cb_box
	cabin.position = Vector3(0, 0.85, -0.20)
	cabin.material_override = body_mat
	car.add_child(cabin)

	# Front Splitter Bumper
	var splitter = MeshInstance3D.new()
	var sp_box = BoxMesh.new()
	sp_box.size = Vector3(1.95, 0.12, 0.45)
	splitter.mesh = sp_box
	splitter.position = Vector3(0, 0.22, -1.85)
	splitter.material_override = body_mat
	car.add_child(splitter)

	# Rear High-Downforce Spoiler Wing
	var wing = MeshInstance3D.new()
	var w_box = BoxMesh.new()
	w_box.size = Vector3(2.10, 0.08, 0.38)
	wing.mesh = w_box
	wing.position = Vector3(0, 1.25, 1.60)
	wing.material_override = team_mat
	car.add_child(wing)

	# Wing Struts
	for sx in [-0.7, 0.7]:
		var strut = MeshInstance3D.new()
		var st_box = BoxMesh.new()
		st_box.size = Vector3(0.06, 0.45, 0.10)
		strut.mesh = st_box
		strut.position = Vector3(sx, 0.95, 1.60)
		strut.material_override = body_mat
		car.add_child(strut)

	# Dual Rocket Thruster Nozzles
	for tx in [-0.35, 0.35]:
		var thruster = MeshInstance3D.new()
		var t_cyl = CylinderMesh.new()
		t_cyl.top_radius = 0.14
		t_cyl.bottom_radius = 0.18
		t_cyl.height = 0.35
		thruster.mesh = t_cyl
		thruster.rotation_degrees = Vector3(90, 0, 0)
		thruster.position = Vector3(tx, 0.50, 1.85)
		thruster.material_override = MaterialGenerator.get_material("sci_fi_metal")
		car.add_child(thruster)

	# 4 Detailed Alloy Wheels
	var wheel_mesh = CylinderMesh.new()
	wheel_mesh.top_radius = 0.38
	wheel_mesh.bottom_radius = 0.38
	wheel_mesh.height = 0.34

	var wheel_offsets = [
		Vector3(-1.05, 0.38, -1.25),
		Vector3(1.05, 0.38, -1.25),
		Vector3(-1.05, 0.38, 1.25),
		Vector3(1.05, 0.38, 1.25)
	]
	for pos in wheel_offsets:
		var w = MeshInstance3D.new()
		w.mesh = wheel_mesh
		w.rotation_degrees = Vector3(0, 0, 90)
		w.position = pos
		w.material_override = wheel_mat
		car.add_child(w)

	return car

static func build_drift_kart(kart_color: Color = Color(0.2, 1.0, 0.5)) -> Node3D:
	var kart = Node3D.new()
	kart.name = "DriftKartVisual"

	var primary_mat = MaterialGenerator.create_pbr_material(kart_color, 0.8, 0.3, kart_color, 0.5)
	var frame_mat = MaterialGenerator.get_material("sci_fi_metal")
	var tire_mat = MaterialGenerator.get_material("asphalt_track")

	# Tubular Kart Chassis
	var chassis = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(1.25, 0.28, 2.50)
	chassis.mesh = c_box
	chassis.position = Vector3(0, 0.28, 0)
	chassis.material_override = frame_mat
	kart.add_child(chassis)

	# Aerodynamic Front Nose Fairing
	var nose = MeshInstance3D.new()
	var n_box = BoxMesh.new()
	n_box.size = Vector3(1.15, 0.22, 0.70)
	nose.mesh = n_box
	nose.position = Vector3(0, 0.30, -1.15)
	nose.material_override = primary_mat
	kart.add_child(nose)

	# Side Pods (Side bumpers with racing decals)
	for px in [-0.68, 0.68]:
		var pod = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.24, 0.26, 1.30)
		pod.mesh = p_box
		pod.position = Vector3(px, 0.30, 0)
		pod.material_override = primary_mat
		kart.add_child(pod)

	# Racing Bucket Seat
	var seat = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.55, 0.55, 0.45)
	seat.mesh = s_box
	seat.position = Vector3(0, 0.55, 0.25)
	seat.material_override = MaterialGenerator.get_material("dark_hull")
	kart.add_child(seat)

	# Steering Wheel Column
	var col = MeshInstance3D.new()
	var col_cyl = CylinderMesh.new()
	col_cyl.top_radius = 0.02
	col_cyl.bottom_radius = 0.02
	col_cyl.height = 0.40
	col.mesh = col_cyl
	col.rotation_degrees = Vector3(45, 0, 0)
	col.position = Vector3(0, 0.52, -0.22)
	col.material_override = frame_mat
	kart.add_child(col)

	# Steering Wheel
	var wheel = MeshInstance3D.new()
	var w_torus = TorusMesh.new()
	w_torus.inner_radius = 0.10
	w_torus.outer_radius = 0.14
	wheel.mesh = w_torus
	wheel.rotation_degrees = Vector3(45, 0, 0)
	wheel.position = Vector3(0, 0.66, -0.34)
	wheel.material_override = MaterialGenerator.get_material("dark_hull")
	kart.add_child(wheel)

	# Rear Engine Block with Dual Exhausts
	var engine = MeshInstance3D.new()
	var e_box = BoxMesh.new()
	e_box.size = Vector3(0.55, 0.40, 0.45)
	engine.mesh = e_box
	engine.position = Vector3(0, 0.45, 0.85)
	engine.material_override = MaterialGenerator.get_material("sci_fi_metal")
	kart.add_child(engine)

	# Rear Wing
	var wing = MeshInstance3D.new()
	var w_box = BoxMesh.new()
	w_box.size = Vector3(1.30, 0.06, 0.28)
	wing.mesh = w_box
	wing.position = Vector3(0, 0.80, 1.15)
	wing.material_override = primary_mat
	kart.add_child(wing)

	# 4 Low-Profile Wide Slick Tires
	var tire_mesh = CylinderMesh.new()
	tire_mesh.top_radius = 0.28
	tire_mesh.bottom_radius = 0.28
	tire_mesh.height = 0.28

	var tire_offsets = [
		Vector3(-0.72, 0.28, -0.85),
		Vector3(0.72, 0.28, -0.85),
		Vector3(-0.76, 0.32, 0.85),
		Vector3(0.76, 0.32, 0.85)
	]
	for i in range(tire_offsets.size()):
		var t = MeshInstance3D.new()
		t.name = "FrontWheel_%d" % i if i < 2 else "RearWheel_%d" % (i - 2)
		t.mesh = tire_mesh
		t.rotation_degrees = Vector3(0, 0, 90)
		t.position = tire_offsets[i]
		t.material_override = tire_mat
		kart.add_child(t)

	return kart

static func build_energy_ball() -> Node3D:
	var ball = Node3D.new()
	ball.name = "EnergyBallVisual"

	# Polyhedral Outer Core
	var outer = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 1.05
	sphere.height = 2.10
	outer.mesh = sphere
	outer.material_override = MaterialGenerator.get_material("energy_ball")
	ball.add_child(outer)

	# Hexagonal Equator Rings
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.02
	torus.outer_radius = 1.14
	ring.mesh = torus
	ring.material_override = MaterialGenerator.get_material("neon_cyan")
	ball.add_child(ring)

	var ring2 = MeshInstance3D.new()
	ring2.mesh = torus
	ring2.rotation_degrees = Vector3(90, 0, 0)
	ring2.material_override = MaterialGenerator.get_material("neon_orange")
	ball.add_child(ring2)

	return ball

static func build_item_box() -> Node3D:
	var box = Node3D.new()
	box.name = "ItemBoxVisual"

	var outer = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(1.1, 1.1, 1.1)
	outer.mesh = b_mesh
	outer.material_override = MaterialGenerator.get_material("neon_orange")
	box.add_child(outer)

	var inner = MeshInstance3D.new()
	var in_mesh = BoxMesh.new()
	in_mesh.size = Vector3(0.8, 0.8, 0.8)
	inner.mesh = in_mesh
	inner.material_override = MaterialGenerator.get_material("gold_pickup")
	box.add_child(inner)

	return box

static func build_pickup_mesh(type: int) -> Node3D:
	var root = Node3D.new()
	root.name = "PickupVisual"

	var core = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(0.5, 0.7, 0.5)
	core.mesh = prism

	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.45
	torus.outer_radius = 0.55
	ring.mesh = torus

	match type:
		0: # Health
			core.material_override = MaterialGenerator.get_material("health_red")
			ring.material_override = MaterialGenerator.get_material("neon_red")
		1: # Armor
			core.material_override = MaterialGenerator.get_material("neon_blue")
			ring.material_override = MaterialGenerator.get_material("neon_cyan")
		2: # Ammo
			core.material_override = MaterialGenerator.get_material("gold_pickup")
			ring.material_override = MaterialGenerator.get_material("neon_orange")
		_:
			core.material_override = MaterialGenerator.get_material("gold_pickup")
			ring.material_override = MaterialGenerator.get_material("neon_cyan")

	root.add_child(core)
	root.add_child(ring)
	return root

static func build_cyber_crate(size: Vector3 = Vector3(2.0, 2.0, 2.0)) -> Node3D:
	var root = Node3D.new()
	root.name = "CyberCrate"

	var main_box = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = size
	main_box.mesh = b
	main_box.material_override = MaterialGenerator.get_material("dark_hull")
	root.add_child(main_box)

	# Beveled Corner Reinforcements
	var rim = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = Vector3(size.x + 0.05, size.y * 0.25, size.z + 0.05)
	rim.mesh = r_box
	rim.material_override = MaterialGenerator.get_material("sci_fi_metal")
	root.add_child(rim)

	# Glowing Status Strip
	var strip = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(size.x + 0.06, 0.08, size.z * 0.4)
	strip.mesh = s_box
	strip.material_override = MaterialGenerator.get_material("neon_cyan")
	root.add_child(strip)

	return root
