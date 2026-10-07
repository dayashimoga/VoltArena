class_name AeroGhostSystem
extends RefCounted

## Records, serializes, and plays back ghost telemetry runs for AeroRush Time Attack.
## Visualizes personal bests as a translucent holographic rival vehicle.

const ModelCache = preload("res://shared/graphics/model_cache.gd")

var recorded_frames: Array[Dictionary] = [] # [{"time": float, "pos": Vector3, "basis": Basis}]
var is_recording: bool = false
var record_timer: float = 0.0
const SAMPLE_INTERVAL: float = 0.05 # 20 Hz

# Playback State
var ghost_node: Node3D = null
var playback_frames: Array[Dictionary] = []
var playback_time: float = 0.0
var playback_idx: int = 0
var is_playing: bool = false

func start_recording() -> void:
	recorded_frames.clear()
	is_recording = true
	record_timer = 0.0

func record_frame(vehicle: CharacterBody3D, delta: float, race_time: float) -> void:
	if not is_recording or not vehicle:
		return
	record_timer += delta
	if record_timer >= SAMPLE_INTERVAL:
		record_timer = 0.0
		var v_pos = vehicle.global_position if vehicle.is_inside_tree() else vehicle.position
		var v_basis = vehicle.global_basis if vehicle.is_inside_tree() else vehicle.transform.basis
		recorded_frames.append({
			"time": race_time,
			"pos": v_pos,
			"basis": v_basis
		})

func stop_recording() -> Array[Dictionary]:
	is_recording = false
	return recorded_frames.duplicate(true)

func load_ghost_data(frames: Array) -> void:
	playback_frames = []
	for f in frames:
		if f is Dictionary:
			playback_frames.append(f)

func spawn_ghost_visual(parent: Node3D, glb_path: String) -> Node3D:
	ghost_node = Node3D.new()
	ghost_node.name = "AeroGhostVehicle"

	var model = ModelCache.get_model(glb_path)
	if model:
		var ghost_mat = StandardMaterial3D.new()
		ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ghost_mat.albedo_color = Color(0.2, 0.8, 1.0, 0.40)
		ghost_mat.emission_enabled = true
		ghost_mat.emission = Color(0.2, 0.8, 1.0) * 1.5
		_apply_ghost_material(model, ghost_mat)
		ghost_node.add_child(model)

	parent.add_child(ghost_node)
	is_playing = not playback_frames.is_empty()
	playback_time = 0.0
	playback_idx = 0
	return ghost_node

func update_playback(delta: float) -> void:
	if not is_playing or not ghost_node or playback_frames.size() < 2:
		return

	playback_time += delta
	while playback_idx < playback_frames.size() - 2 and playback_frames[playback_idx + 1]["time"] < playback_time:
		playback_idx += 1

	var f0 = playback_frames[playback_idx]
	var f1 = playback_frames[playback_idx + 1]
	var t0 = f0["time"] as float
	var t1 = f1["time"] as float
	var span = maxf(t1 - t0, 0.001)
	var factor = clampf((playback_time - t0) / span, 0.0, 1.0)

	var p0 = f0["pos"] as Vector3
	var p1 = f1["pos"] as Vector3
	var b0 = f0["basis"] as Basis
	var b1 = f1["basis"] as Basis

	var interp_pos = p0.lerp(p1, factor)
	var q0 = Quaternion(b0)
	var q1 = Quaternion(b1)
	var interp_basis = Basis(q0.slerp(q1, factor))
	if ghost_node.is_inside_tree():
		ghost_node.global_position = interp_pos
		ghost_node.global_basis = interp_basis
	else:
		ghost_node.position = interp_pos
		ghost_node.transform.basis = interp_basis

func _apply_ghost_material(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for c in node.get_children():
		_apply_ghost_material(c, mat)

func clear() -> void:
	is_recording = false
	is_playing = false
	recorded_frames.clear()
	playback_frames.clear()
	if is_instance_valid(ghost_node):
		ghost_node.queue_free()
		ghost_node = null
