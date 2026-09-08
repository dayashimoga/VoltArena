class_name Mission7SkyFortress
extends Node3D

## Mission 7: Sky Fortress
## Environment: High-altitude drop platform, exterior catwalks, hangar deck, floating reactor conduits.
## Objective: Infiltrate aerial dreadnought, survive high-altitude wind hazards, overload aerial core.
## Boss: Sky Fortress Aerial Core Platform.

const MissionDefinitionsScript = preload("res://games/strike-vector/missions/mission_definitions.gd")
const SetPieceDirectorScript = preload("res://games/strike-vector/setpieces/setpiece_director.gd")

static func create_segments() -> Array:
	var segs = MissionDefinitionsScript.build_mission_segments(7)

	# Setup M7 Set-Piece: Crumbling exterior antenna catwalk platforming (Segment 2)
	if segs.size() > 1:
		var sp = SetPieceDirectorScript.new()
		sp.name = "SetPiece_CollapsingCatwalk"
		sp.setpiece_id = "m7_collapsing_catwalk"
		sp.duration_sec = 6.0
		sp.camera_shake_amount = 0.8
		segs[1].add_child(sp)

	return segs
