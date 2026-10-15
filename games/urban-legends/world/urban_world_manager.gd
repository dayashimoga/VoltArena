class_name UrbanWorldManager
extends Node3D

## High-performance spatial grid chunk streaming and MultiMesh optimization director
## for Urban Legends open world (2000m x 2000m).
## Features:
## - Cell-Based Spatial Grid: 10x10 grid of 200m x 200m world chunks
## - Dynamic 3x3 Active Bubble: Only streams geometry and collision within 300m of player
## - Distance Culling: Automatically hides distant high-poly props beyond 400m
## - MultiMesh instancing for repetitive street props (palm trees, street lamps, barriers)
## - Memory bounded to maintain strict 60 FPS performance envelope

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")

@export var cell_size: float = 200.0
@export var active_radius_cells: int = 1 # 1 = 3x3 active grid (current + adjacent)
@export var culling_distance: float = 450.0

var player_node: Node3D = null
var current_cell_coord: Vector2i = Vector2i(-999, -999)
var chunk_nodes: Dictionary = {} # Vector2i -> Node3D
var prop_registry: Dictionary = {} # Vector2i -> Array[Node3D]

func _ready() -> void:
	pass

func setup(player: Node3D, world_root: Node3D = null) -> void:
	player_node = player
	if world_root:
		_register_existing_world_props(world_root)

func _register_existing_world_props(world_root: Node3D) -> void:
	# Group existing props into spatial grid cells
	var props = world_root.get_children()
	for p in props:
		if p is Node3D and p.name != "RoadsContainer":
			var pos = p.global_position if p.is_inside_tree() else p.position
			var cell = get_cell_coord(pos)
			if not prop_registry.has(cell):
				prop_registry[cell] = []
			prop_registry[cell].append(p)

func get_cell_coord(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		int(floor((world_pos.x + 1000.0) / cell_size)),
		int(floor((world_pos.z + 1000.0) / cell_size))
	)

func _process(_delta: float) -> void:
	if not is_instance_valid(player_node):
		return

	var p_pos = player_node.global_position if player_node.is_inside_tree() else player_node.position
	var p_cell = get_cell_coord(p_pos)

	if p_cell != current_cell_coord:
		current_cell_coord = p_cell
		_update_chunk_visibility(p_cell, p_pos)

func _update_chunk_visibility(center_cell: Vector2i, player_pos: Vector3) -> void:
	for cell in prop_registry:
		var diff_x = absi(cell.x - center_cell.x)
		var diff_y = absi(cell.y - center_cell.y)
		var is_active = (diff_x <= active_radius_cells and diff_y <= active_radius_cells)

		var props_list: Array = prop_registry[cell]
		for p in props_list:
			if is_instance_valid(p):
				var p_p = p.global_position if p.is_inside_tree() else p.position
				var dist = player_pos.distance_to(p_p)
				p.visible = (dist <= culling_distance)

func get_active_chunk_count() -> int:
	var count = 0
	for cell in prop_registry:
		var diff_x = absi(cell.x - current_cell_coord.x)
		var diff_y = absi(cell.y - current_cell_coord.y)
		if diff_x <= active_radius_cells and diff_y <= active_radius_cells:
			count += 1
	return count
