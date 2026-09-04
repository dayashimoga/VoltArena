class_name FXFactory
extends RefCounted

## Factory for creating reusable 3D visual particle effects (muzzle flashes, impacts, explosions, drift smoke, exhaust).
## Uses CPUParticles3D for universal cross-platform rendering (Desktop, Mobile, Web/GLES3 compatibility).

static func create_muzzle_flash(pos: Vector3, _color: Color = Color(1.0, 0.8, 0.2)) -> CPUParticles3D:
	var p = CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.08
	p.amount = 8
	p.position = pos
	p.spread = 40.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 6.0
	var sphere = SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = 0.08
	sphere.material = MaterialGenerator.get_material("neon_orange")
	p.mesh = sphere
	return p

static func create_impact_sparks(pos: Vector3, normal: Vector3 = Vector3.UP) -> CPUParticles3D:
	var p = CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 0.25
	p.amount = 16
	p.position = pos
	p.direction = normal
	p.spread = 60.0
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 8.0
	p.gravity = Vector3(0, -9.8, 0)
	var box = BoxMesh.new()
	box.size = Vector3(0.04, 0.04, 0.04)
	box.material = MaterialGenerator.get_material("sparks")
	p.mesh = box
	return p

static func create_explosion(pos: Vector3, radius: float = 2.0) -> CPUParticles3D:
	var p = CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 0.5
	p.amount = 32
	p.position = pos
	p.spread = 180.0
	p.initial_velocity_min = 4.0 * radius
	p.initial_velocity_max = 8.0 * radius
	p.gravity = Vector3(0, -3.0, 0)
	var sphere = SphereMesh.new()
	sphere.radius = 0.12 * radius
	sphere.height = 0.24 * radius
	sphere.material = MaterialGenerator.get_material("nitro_fire")
	p.mesh = sphere
	return p

static func create_drift_smoke(pos: Vector3) -> CPUParticles3D:
	var p = CPUParticles3D.new()
	p.emitting = false
	p.one_shot = false
	p.lifetime = 0.4
	p.amount = 12
	p.position = pos
	p.spread = 45.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 3.0
	p.gravity = Vector3(0, 1.0, 0)
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	sphere.material = MaterialGenerator.get_material("drift_smoke")
	p.mesh = sphere
	return p

static func create_rocket_exhaust(pos: Vector3) -> CPUParticles3D:
	var p = CPUParticles3D.new()
	p.emitting = false
	p.one_shot = false
	p.lifetime = 0.2
	p.amount = 20
	p.position = pos
	p.direction = Vector3(0, 0, 1)
	p.spread = 15.0
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 14.0
	p.gravity = Vector3.ZERO
	var sphere = SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	sphere.material = MaterialGenerator.get_material("nitro_fire")
	p.mesh = sphere
	return p
