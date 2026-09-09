class_name Mission2HighScoreRail
extends Node3D

## Mission 2: High-Speed Rail
## Environment: Moving passenger express train, carriage interiors, wind-swept roof, rail bridge.
## Objective: Fight through passenger cars, defend train roof, destroy VTOL attack craft.
## Boss: Apex VTOL Strike Gunship.

const MissionDefinitionsScript = preload("res://games/strike-vector/missions/mission_definitions.gd")
const SetPieceDirectorScript = preload("res://games/strike-vector/setpieces/setpiece_director.gd")

static func create_segments() -> Array:
	var segs = MissionDefinitionsScript.build_mission_segments(2)

	# Setup M2 Set-Piece: Low-clearance tunnel hazard on train roof (Segment 3)
	if segs.size() > 2:
		var sp = SetPieceDirectorScript.new()
		sp.name = "SetPiece_TunnelHazard"
		sp.setpiece_id = "m2_tunnel_hazard"
		sp.duration_sec = 6.0
		sp.camera_shake_amount = 0.9
		segs[2].add_child(sp)

	return segs
