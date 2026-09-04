class_name PhysicsHelpers
extends RefCounted

static func raycast_3d(world_3d: World3D, from: Vector3, to: Vector3, collision_mask: int = 0xFFFFFFFF, exclude: Array[RID] = []) -> Dictionary:
	if not world_3d:
		return {}
	var space_state = world_3d.direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to, collision_mask, exclude)
	return space_state.intersect_ray(query)

static func calculate_ballistic_velocity(start_pos: Vector3, target_pos: Vector3, gravity: float, arc_height: float) -> Vector3:
	var disp_y = target_pos.y - start_pos.y
	var disp_xz = Vector3(target_pos.x - start_pos.x, 0.0, target_pos.z - start_pos.z)
	var peak_y = max(start_pos.y, target_pos.y) + arc_height
	var vy0 = sqrt(2.0 * gravity * (peak_y - start_pos.y))
	var t_up = vy0 / gravity
	var t_down = sqrt(2.0 * max(0.01, peak_y - target_pos.y) / gravity)
	var total_time = t_up + t_down
	var v_xz = disp_xz / max(0.01, total_time)
	return Vector3(v_xz.x, vy0, v_xz.z)

static func reflect_velocity(vel: Vector3, normal: Vector3, restitution: float = 0.8) -> Vector3:
	return vel.bounce(normal) * restitution
