class_name Mission5ArcticInstallation
extends Node3D

## Mission 5: Arctic Installation
## Environment: Whiteout blizzard, frozen lake checkpoint, high-tech underground base, ice caverns.
## Objective: Breach research installation, survive ice cavern collapse, eliminate Sub-Zero Walker.
## Boss: Arctic Sub-Zero Bipedal Walker.

const MissionDefinitionsScript = preload("res://games/strike-vector/missions/mission_definitions.gd")
const SetPieceDirectorScript = preload("res://games/strike-vector/setpieces/setpiece_director.gd")

static func create_segments() -> Array:
	var segs = MissionDefinitionsScript.build_mission_segments(5)

	# Setup M5 Set-Piece: Ice-shelf avalanche and cavern collapse (Segment 4)
	if segs.size() > 3:
		var sp = SetPieceDirectorScript.new()
		sp.name = "SetPiece_IceCollapse"
		sp.setpiece_id = "m5_ice_collapse"
		sp.duration_sec = 6.0
		sp.camera_shake_amount = 0.95
		segs[3].add_child(sp)

	return segs
