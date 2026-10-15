class_name FlightMissionDefinitions
extends RefCounted

## MissionDefinitions: Catalog of 8 diverse flight missions with objectives,
## difficulty ratings, target waypoints, and medal grading thresholds.

const FlightConst = preload("res://games/aircraft-flight/core/flight_constants.gd")

static var MISSIONS: Dictionary = {
	"m1_free_flight": {
		"id": "m1_free_flight",
		"title": "Open Skies Exploration",
		"type": FlightConst.MissionType.FREE_FLIGHT,
		"world_id": "metropolitan_city",
		"desc": "Freely explore the vast 8km open world. Practice high-speed low-altitude runs, aerobatic maneuvers, and touch-and-go landings.",
		"spawn_type": "runway_takeoff",
		"allowed_aircraft": ["fa18_hornet", "f22_raptor", "a320_airliner", "extra330_sport", "uh60_helicopter"],
		"time_limit_s": 0.0, # Infinite
		"gold_score": 1000,
		"silver_score": 500,
		"bronze_score": 250
	},
	"m2_takeoff_landing": {
		"id": "m2_takeoff_landing",
		"title": "Commercial Runway Certification",
		"type": FlightConst.MissionType.TAKEOFF_LANDING,
		"world_id": "metropolitan_city",
		"desc": "Takeoff from Runway 09L, climb to 600m on crosswind leg, establish ILS glide slope, and perform a butter-smooth touchdown flare (< 2.5 m/s VSI).",
		"spawn_type": "runway_takeoff",
		"allowed_aircraft": ["a320_airliner", "fa18_hornet", "extra330_sport"],
		"time_limit_s": 180.0,
		"target_climb_alt_m": 600.0,
		"max_touchdown_vsi": 2.8,
		"gold_score": 5000,
		"silver_score": 3500,
		"bronze_score": 2000
	},
	"m3_urban_corridor": {
		"id": "m3_urban_corridor",
		"title": "Skyscraper Low-Altitude Run",
		"type": FlightConst.MissionType.URBAN_LOW_ALTITUDE,
		"world_id": "metropolitan_city",
		"desc": "Thread the needle through downtown Manhattan skyscraper corridors below 100m AGL without triggering ceiling violations.",
		"spawn_type": "city_skimming",
		"allowed_aircraft": ["fa18_hornet", "f22_raptor", "extra330_sport"],
		"time_limit_s": 120.0,
		"max_allowed_alt_m": 120.0,
		"gold_score": 6000,
		"silver_score": 4000,
		"bronze_score": 2500
	},
	"m4_checkpoint_race": {
		"id": "m4_checkpoint_race",
		"title": "Harbor & River Air Race",
		"type": FlightConst.MissionType.CHECKPOINT_AIR_RACE,
		"world_id": "metropolitan_city",
		"desc": "Navigate 8 3D aerial slalom rings through harbor cranes, under the suspension bridge, and over the skyline.",
		"spawn_type": "airborne_approach",
		"allowed_aircraft": ["fa18_hornet", "f22_raptor", "extra330_sport"],
		"time_limit_s": 90.0,
		"gold_time_s": 45.0,
		"silver_time_s": 60.0,
		"bronze_time_s": 80.0,
		"ring_waypoints": [
			Vector3(-1200.0, 180.0, 2000.0),
			Vector3(-600.0, 150.0, 1200.0),
			Vector3(0.0, 120.0, 600.0),
			Vector3(800.0, 85.0, 0.0),
			Vector3(1600.0, 55.0, -300.0), # Under suspension bridge!
			Vector3(2200.0, 95.0, -800.0), # Harbor cranes
			Vector3(1400.0, 220.0, -1400.0),
			Vector3(-1200.0, 120.0, -1800.0) # Final airport approach
		]
	},
	"m5_deadstick": {
		"id": "m5_deadstick",
		"title": "Emergency Flameout Deadstick",
		"type": FlightConst.MissionType.DEADSTICK_DESCENT,
		"world_id": "alpine_mountains",
		"desc": "Both engines flame out at 2,800m over mountain peaks. Manage glide ratio and airspeed to deadstick land on the plateau runway.",
		"spawn_type": "airborne_approach",
		"allowed_aircraft": ["fa18_hornet", "a320_airliner", "extra330_sport"],
		"time_limit_s": 150.0,
		"engine_cut": true,
		"gold_score": 5500,
		"silver_score": 3800,
		"bronze_score": 2000
	},
	"m6_mountain_slalom": {
		"id": "m6_mountain_slalom",
		"title": "Alpine Razor Ridge Slalom",
		"type": FlightConst.MissionType.MOUNTAIN_SLALOM,
		"world_id": "alpine_mountains",
		"desc": "High-G knife-edge turns through narrow granite canyons and glacial passes.",
		"spawn_type": "airborne_approach",
		"allowed_aircraft": ["fa18_hornet", "f22_raptor", "extra330_sport"],
		"time_limit_s": 110.0,
		"gold_time_s": 55.0,
		"silver_time_s": 75.0,
		"bronze_time_s": 95.0
	},
	"m7_landmark_recon": {
		"id": "m7_landmark_recon",
		"title": "Aerial Photography Recon",
		"type": FlightConst.MissionType.LANDMARK_RECON,
		"world_id": "metropolitan_city",
		"desc": "Scout and photograph 4 municipal landmarks (Suspension Bridge, Empire Tower, Harbour Terminal, Control Tower) within 250m.",
		"spawn_type": "airborne_approach",
		"allowed_aircraft": ["extra330_sport", "uh60_helicopter", "fa18_hornet"],
		"time_limit_s": 240.0,
		"recon_targets": [
			{"name": "Suspension Bridge", "pos": Vector3(2200.0, 45.0, 0.0), "captured": false},
			{"name": "Stepped Empire Tower", "pos": Vector3(880.0, 220.0, -1200.0), "captured": false},
			{"name": "Container Ship Docks", "pos": Vector3(1800.0, 20.0, -600.0), "captured": false},
			{"name": "Airport Control Tower", "pos": Vector3(-850.0, 85.0, -280.0), "captured": false}
		],
		"gold_score": 4000,
		"silver_score": 3000,
		"bronze_score": 2000
	},
	"m8_helicopter_sar": {
		"id": "m8_helicopter_sar",
		"title": "Rotorcraft Search & Rescue",
		"type": FlightConst.MissionType.ROTORCRAFT_SAR,
		"world_id": "metropolitan_city",
		"desc": "Pilot the UH-60 helicopter, hover over emergency distress flare in harbor basin for 5s to hoist survivors, then land on hospital rooftop helipad.",
		"spawn_type": "runway_takeoff",
		"allowed_aircraft": ["uh60_helicopter"],
		"time_limit_s": 200.0,
		"beacon_pos": Vector3(1600.0, 15.0, -400.0),
		"helipad_pos": Vector3(720.0, 145.0, -1400.0),
		"hover_time_required": 4.0,
		"gold_score": 5000,
		"silver_score": 3500,
		"bronze_score": 2000
	}
}

static func get_mission(id: String) -> Dictionary:
	if MISSIONS.has(id):
		return MISSIONS[id].duplicate(true)
	return MISSIONS["m1_free_flight"].duplicate(true)

static func get_all_missions() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for k in MISSIONS.keys():
		list.append(MISSIONS[k])
	return list
