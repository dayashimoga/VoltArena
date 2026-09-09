class_name Mission6Megafactory
extends Node3D

## Mission 6: Megafactory
## Environment: Industrial loading docks, automated assembly lines, robotic stamping presses, smelting furnaces.
## Objective: Traverse conveyor belts, avoid industrial crushers, destroy Apex Factory Defense Robot.
## Boss: Apex Factory Defense Automaton.

const MissionDefinitionsScript = preload("res://games/strike-vector/missions/mission_definitions.gd")
const SetPieceDirectorScript = preload("res://games/strike-vector/setpieces/setpiece_director.gd")

static func create_segments() -> Array:
	var segs = MissionDefinitionsScript.build_mission_segments(6)

	# Setup M6 Set-Piece: Conveyor ride through moving stamping machinery (Segment 3)
	if segs.size() > 2:
		var sp = SetPieceDirectorScript.new()
		sp.name = "SetPiece_StampingPistons"
		sp.setpiece_id = "m6_stamping_pistons"
		sp.duration_sec = 6.5
		sp.camera_shake_amount = 0.9
		segs[2].add_child(sp)

	return segs
