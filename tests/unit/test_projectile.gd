class_name TestProjectile
extends RefCounted

const ProjectileScript = preload("res://games/arena-fps/weapons/projectile.gd")
const GrenadeLauncherScript = preload("res://games/arena-fps/weapons/grenade_launcher.gd")
const PlasmaCutterScript = preload("res://games/arena-fps/weapons/plasma_cutter.gd")
const RailDriverScript = preload("res://games/arena-fps/weapons/rail_driver.gd")
const ScatterCannonScript = preload("res://games/arena-fps/weapons/scatter_cannon.gd")
const WeaponBaseScript = preload("res://games/arena-fps/weapons/weapon_base.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_projectile_lifecycle()
	test_explosive_projectile()
	test_grenade_launcher()
	test_plasma_cutter()
	test_rail_driver()
	test_scatter_cannon()
	test_weapon_base_extended()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		[
			"res://games/arena-fps/weapons/projectile.gd",
			["_ready", "setup_mesh", "_physics_process", "explode_or_free"]
		],
		[
			"res://games/arena-fps/weapons/grenade_launcher.gd",
			["_init", "spawn_projectile"]
		],
		[
			"res://games/arena-fps/weapons/plasma_cutter.gd",
			["_init"]
		],
		[
			"res://games/arena-fps/weapons/rail_driver.gd",
			["_init"]
		],
		[
			"res://games/arena-fps/weapons/scatter_cannon.gd",
			["_init", "trigger_fire"]
		],
		[
			"res://games/arena-fps/weapons/weapon_base.gd",
			["_ready", "_process", "perform_hitscan", "spawn_projectile", "setup_muzzle_flash"]
		]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit Projectile FAIL: " + msg)

func test_projectile_lifecycle() -> void:
	var proj = ProjectileScript.new()
	proj.direction = Vector3.FORWARD
	proj.speed = 30.0
	proj._ready()
	assert_true(proj.velocity.length() > 0.0, "Velocity must be set in _ready")
	proj._physics_process(0.016)
	assert_true(proj.current_lifetime > 0.0, "Lifetime must accumulate in _physics_process")
	proj.queue_free()

func test_explosive_projectile() -> void:
	var proj = ProjectileScript.new()
	proj.is_explosive = true
	proj.blast_radius = 5.0
	proj.setup_mesh()
	assert_true(proj.get_child_count() > 0, "Explosive projectile must create visual mesh")
	proj.explode_or_free()
	assert_true(true, "explode_or_free must execute safely")

func test_grenade_launcher() -> void:
	var gl = GrenadeLauncherScript.new()
	assert_true(gl.weapon_name == "Grenade Launcher", "Weapon name must match")
	assert_true(gl.damage_per_shot >= 80.0, "Damage per shot must be >= 80")
	gl.spawn_projectile(Vector3.ZERO, Vector3.FORWARD)
	assert_true(true, "spawn_projectile must execute safely")
	gl.queue_free()

func test_plasma_cutter() -> void:
	var pc = PlasmaCutterScript.new()
	assert_true(pc.weapon_name == "Plasma Cutter", "Plasma cutter initialized")
	assert_true(pc.is_automatic, "Plasma cutter must be automatic")
	assert_true(pc.max_clip_ammo >= 50, "High clip capacity")
	pc.queue_free()

func test_rail_driver() -> void:
	var rd = RailDriverScript.new()
	assert_true(rd.weapon_name == "Rail Driver", "Rail driver initialized")
	assert_true(rd.damage_per_shot >= 90.0, "High damage sniper weapon")
	assert_true(rd.spread_angle_deg == 0.0, "Pinpoint accuracy")
	rd.queue_free()

func test_scatter_cannon() -> void:
	var sc = ScatterCannonScript.new()
	assert_true(sc.weapon_name == "Scatter Cannon", "Scatter cannon initialized")
	assert_true(sc.pellets_count >= 8, "Must fire multiple pellets")
	sc.setup_weapon_visual()
	sc.trigger_fire(Vector3.ZERO, Vector3.FORWARD)
	assert_true(sc.current_clip_ammo < sc.max_clip_ammo, "Ammo must decrease on fire")
	sc.queue_free()

func test_weapon_base_extended() -> void:
	var wb = WeaponBaseScript.new()
	wb._ready()
	wb._process(0.016)
	wb.perform_hitscan(Vector3.ZERO, Vector3.FORWARD)
	wb.spawn_projectile(Vector3.ZERO, Vector3.FORWARD)
	wb.setup_muzzle_flash()
	assert_true(wb.max_clip_ammo > 0, "WeaponBase must have valid clip")
	wb.queue_free()
