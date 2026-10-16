class_name AeroSurface3D
extends Node3D

## High-fidelity 6-DoF Aerodynamic Surface.
## Computes point velocity, continuous lift/drag across [-PI, PI], induced drag,
## ground effect, control deflection, pitching moments, and propeller slipstream.

@export var config: AeroSurfaceConfig
@export var is_control_surface: bool = false
@export var control_axis: String = "" ## "pitch", "roll", "yaw", "flaps"
@export var max_deflection_deg: float = 20.0
@export var propeller_slipstream_factor: float = 0.0 ## 0.0 to 1.0 wash fraction
@export var draw_debug_vectors: bool = false

var current_deflection_rad: float = 0.0
var current_aoa: float = 0.0
var current_cl: float = 0.0
var current_cd: float = 0.0
var current_lift_force: Vector3 = Vector3.ZERO
var current_drag_force: Vector3 = Vector3.ZERO
var current_resultant_force: Vector3 = Vector3.ZERO

# Debug immediate mesh for vector visualization
var _debug_mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh

func _ready() -> void:
	if not config:
		config = AeroSurfaceConfig.new()
	if draw_debug_vectors:
		_setup_debug_mesh()

func _setup_debug_mesh() -> void:
	_debug_mesh_instance = MeshInstance3D.new()
	_immediate_mesh = ImmediateMesh.new()
	_debug_mesh_instance.mesh = _immediate_mesh
	_debug_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_debug_mesh_instance.material_override = mat
	add_child(_debug_mesh_instance)

## Sets the control surface deflection in normalized range [-1.0, 1.0]
func set_control_input(norm_val: float) -> void:
	var max_rad = deg_to_rad(max_deflection_deg)
	current_deflection_rad = clamp(norm_val, -1.0, 1.0) * max_rad

## Computes and applies aerodynamic forces onto the parent RigidBody3D.
## [param body]: The aircraft RigidBody3D.
## [param com_world]: Center of Mass world position.
## [param air_density]: Ambient atmospheric air density rho (kg/m^3).
## [param prop_wash_vel]: Forward slipstream velocity vector (m/s).
## [param altitude_agl]: Radar altitude above ground level for ground effect (m).
func evaluate_and_apply_forces(
	body: RigidBody3D,
	com_world: Vector3,
	air_density: float,
	prop_wash_vel: Vector3 = Vector3.ZERO,
	altitude_agl: float = 1000.0
) -> Dictionary:
	if not config:
		return {}

	# 1. Surface Point Velocity: v = v_linear + omega.cross(p_surface - p_COM)
	var p_surface = global_position if is_inside_tree() else position
	var r_arm = p_surface - com_world
	var v_point = body.linear_velocity + body.angular_velocity.cross(r_arm)

	# 2. Add Propeller Slipstream effect
	var v_apparent = v_point
	if propeller_slipstream_factor > 0.0 and prop_wash_vel.length_squared() > 0.01:
		v_apparent += prop_wash_vel * propeller_slipstream_factor

	# 3. Transform to Local Surface Coordinate Frame
	# Local Convention: Nose is -Z, Canopy/Normal is +Y, Starboard/Span is +X
	var s_basis = global_transform.basis if is_inside_tree() else transform.basis
	var local_vel = s_basis.inverse() * v_apparent
	var speed = local_vel.length()
	if speed < 0.1:
		current_aoa = 0.0
		current_cl = 0.0
		current_cd = config.skin_friction_drag
		current_lift_force = Vector3.ZERO
		current_drag_force = Vector3.ZERO
		current_resultant_force = Vector3.ZERO
		return {"lift": Vector3.ZERO, "drag": Vector3.ZERO, "aoa": 0.0}

	# Dynamic Pressure: q = 0.5 * rho * V^2
	var q = 0.5 * air_density * speed * speed
	var area = config.get_area()

	# 4. Aerodynamic Angle of Attack: alpha = atan2(-v_local.y, -v_local.z)
	var aoa = atan2(-local_vel.y, -local_vel.z)
	current_aoa = aoa

	# 5. Control Deflection effect on effective AoA
	var delta_alpha = current_deflection_rad * config.get_control_effectiveness()
	var alpha_eff = aoa + delta_alpha

	# 6. Continuous Lift & Drag across [-PI, PI] blending thin airfoil & post-stall flat plate
	var a_finite = config.get_finite_lift_slope()
	var alpha_0 = config.zero_lift_aoa
	var stall_pos = config.positive_stall_angle
	var stall_neg = config.negative_stall_angle

	# Pre-stall thin-airfoil / finite-wing lift
	var cl_linear = a_finite * (alpha_eff - alpha_0)

	# Post-stall flat-plate lift and drag: Cl = sin(2*alpha), Cd = 2*sin^2(alpha)
	var cl_plate = sin(2.0 * alpha_eff)
	var cd_plate = 2.0 * sin(alpha_eff) * sin(alpha_eff) + config.skin_friction_drag

	# Smooth blending weight between linear and flat-plate regimes
	var blend_margin = deg_to_rad(3.5)
	var weight_pos = clamp((alpha_eff - stall_pos) / blend_margin, 0.0, 1.0)
	var weight_neg = clamp((stall_neg - alpha_eff) / blend_margin, 0.0, 1.0)
	var stall_weight = max(weight_pos, weight_neg)
	stall_weight = smoothstep(0.0, 1.0, stall_weight)

	var cl = lerp(cl_linear, cl_plate, stall_weight)

	# 7. Induced Drag with Ground Effect:
	# Ground effect reduction factor: sigma = (16*h/b)^2 / [1 + (16*h/b)^2]
	var b_span = max(config.span, 0.5)
	var h_ratio = max(0.05, altitude_agl) / b_span
	var h16 = 16.0 * h_ratio
	var sigma_ground = (h16 * h16) / (1.0 + (h16 * h16))
	sigma_ground = clamp(sigma_ground, 0.08, 1.0)

	var ar = max(config.aspect_ratio, 1.0)
	var e_oswald = max(config.oswald_efficiency, 0.6)
	var cd_induced_clean = (cl * cl) / (PI * ar * e_oswald)
	var cd_induced = cd_induced_clean * sigma_ground

	# Profile/Parasitic Drag
	var cd_parasitic = config.skin_friction_drag + 0.35 * (alpha_eff - alpha_0) * (alpha_eff - alpha_0)
	var cd_pre = cd_parasitic + cd_induced
	var cd = lerp(cd_pre, cd_plate, stall_weight)

	current_cl = cl
	current_cd = cd

	# 8. Compute Local Force Vectors
	# Airflow direction in local coordinates
	var local_flow_dir = local_vel.normalized()

	# Lift is perpendicular to local airflow in the pitch plane (plane containing airflow and local Y)
	# Normal vector to span (local X):
	var span_axis = Vector3.RIGHT
	var lift_dir_local = span_axis.cross(local_flow_dir).normalized()
	# Ensure lift vector points upwards with positive lift
	if lift_dir_local.y < 0.0 and cl > 0.0:
		lift_dir_local = -lift_dir_local

	var drag_dir_local = -local_flow_dir

	var lift_mag = q * area * cl
	var drag_mag = q * area * cd

	var f_lift_local = lift_dir_local * lift_mag
	var f_drag_local = drag_dir_local * drag_mag
	var f_total_local = f_lift_local + f_drag_local

	# 9. Transform to World Space
	var f_lift_world = s_basis * f_lift_local
	var f_drag_world = s_basis * f_drag_local
	var f_total_world = s_basis * f_total_local

	current_lift_force = f_lift_world
	current_drag_force = f_drag_world
	current_resultant_force = f_total_world

	# 10. Pitching Moment: M = q * S * chord * C_m(alpha)
	var cm = config.pitch_moment_c0 + config.pitch_moment_slope * alpha_eff
	var m_pitch_mag = q * area * config.chord * cm
	var pitch_axis_world = s_basis * Vector3.RIGHT # Starboard axis
	var m_pitch_world = pitch_axis_world * m_pitch_mag

	# 11. Apply Forces and Torques to RigidBody3D
	# Force applied at surface aerodynamic center relative to body origin
	var body_pos = body.global_position if body.is_inside_tree() else body.position
	var force_offset = p_surface - body_pos
	body.apply_force(f_total_world, force_offset)
	body.apply_torque(m_pitch_world)

	# 12. Update Debug Visualization
	if draw_debug_vectors and _immediate_mesh:
		_render_debug_vectors(f_lift_world, f_drag_world, f_total_world)

	return {
		"lift": f_lift_world,
		"drag": f_drag_world,
		"resultant": f_total_world,
		"pitch_moment": m_pitch_world,
		"aoa": aoa,
		"cl": cl,
		"cd": cd,
		"q": q
	}

func _render_debug_vectors(lift_w: Vector3, drag_w: Vector3, total_w: Vector3) -> void:
	_immediate_mesh.clear_surfaces()
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var origin = Vector3.ZERO
	var scale_factor = 0.0004 # 1000 N = 0.4 m

	# Lift Vector (Green)
	var lift_local = global_transform.basis.inverse() * (lift_w * scale_factor)
	_immediate_mesh.surface_set_color(Color(0.1, 1.0, 0.2))
	_immediate_mesh.surface_add_vertex(origin)
	_immediate_mesh.surface_set_color(Color(0.1, 1.0, 0.2))
	_immediate_mesh.surface_add_vertex(origin + lift_local)

	# Drag Vector (Red)
	var drag_local = global_transform.basis.inverse() * (drag_w * scale_factor)
	_immediate_mesh.surface_set_color(Color(1.0, 0.2, 0.1))
	_immediate_mesh.surface_add_vertex(origin)
	_immediate_mesh.surface_set_color(Color(1.0, 0.2, 0.1))
	_immediate_mesh.surface_add_vertex(origin + drag_local)

	# Resultant Vector (Yellow)
	var res_local = global_transform.basis.inverse() * (total_w * scale_factor)
	_immediate_mesh.surface_set_color(Color(1.0, 0.9, 0.1))
	_immediate_mesh.surface_add_vertex(origin)
	_immediate_mesh.surface_set_color(Color(1.0, 0.9, 0.1))
	_immediate_mesh.surface_add_vertex(origin + res_local)

	_immediate_mesh.surface_end()
