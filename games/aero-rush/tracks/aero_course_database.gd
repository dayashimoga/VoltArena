class_name AeroCourseDatabase
extends RefCounted

## Master repository of all 12 handcrafted stunt courses for AeroRush.
## Spans 4 distinct environments (Megacity, Canyon, Coastal, Sky Circuit)
## with loops, corkscrews, wall-rides, mega jumps, and kinetic hazard fields.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

static func get_all_courses() -> Array[Dictionary]:
	return [
		_get_course_1_neon_express(),
		_get_course_2_cyber_loopway(),
		_get_course_3_skyscraper_rush(),
		_get_course_4_canyon_slingshot(),
		_get_course_5_red_rock_roller(),
		_get_course_6_ridge_hazard_run(),
		_get_course_7_azure_boardwalk(),
		_get_course_8_cliffside_wallride(),
		_get_course_9_tropic_stunt_arena(),
		_get_course_10_strato_pylon_gp(),
		_get_course_11_zenith_corkscrew(),
		_get_course_12_apex_impossible()
	]

static func get_course_by_id(course_id: String) -> Dictionary:
	for c in get_all_courses():
		if c["id"] == course_id:
			return c
	return _get_course_1_neon_express()

# ==============================================================================
# ENVIRONMENT 1: NEON MEGACITY
# ==============================================================================

static func _get_course_1_neon_express() -> Dictionary:
	return {
		"id": "neon_express",
		"name": "Neon Express",
		"tagline": "Metropolitan High-Speed Highway",
		"environment": AeroConstants.EnvironmentType.NEON_MEGACITY,
		"mode": AeroConstants.GameMode.CIRCUIT,
		"laps": 2,
		"tier": 1,
		"gold_time": 68.0,
		"silver_time": 78.0,
		"bronze_time": 92.0,
		"gold_score": 12000,
		"desc": "High-octane urban introductory circuit featuring banked expressway flyovers, a tunnel dive, and grandstand jump.",
		"spawn_pos": Vector3(0, 1.2, 0),
		"spawn_rot_y": 0.0,
		"waypoints": [
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 0, -80), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(25, 6, -160), "bank_deg": 25.0, "width": 16.0},
			{"pos": Vector3(90, 14, -220), "bank_deg": 40.0, "width": 16.0},
			{"pos": Vector3(180, 16, -210), "bank_deg": 35.0, "width": 16.0},
			{"pos": Vector3(230, 8, -130), "bank_deg": 15.0, "width": 16.0},
			{"pos": Vector3(220, 2, -30), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(150, 0, 40), "bank_deg": -25.0, "width": 16.0},
			{"pos": Vector3(60, 0, 30), "bank_deg": -15.0, "width": 16.0},
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 16.0}
		],
		"checkpoints": [0, 3, 6, 9],
		"hazards": []
	}

static func _get_course_2_cyber_loopway() -> Dictionary:
	return {
		"id": "cyber_loopway",
		"name": "Cyber Loopway",
		"tagline": "Full 360° Vertical Loop & Skyscraper Wall Ride",
		"environment": AeroConstants.EnvironmentType.NEON_MEGACITY,
		"mode": AeroConstants.GameMode.CIRCUIT,
		"laps": 2,
		"tier": 2,
		"gold_time": 75.0,
		"silver_time": 88.0,
		"bronze_time": 105.0,
		"gold_score": 18000,
		"desc": "A demanding downtown stunt course with an enormous vertical loop and a 75° high-speed tower wall ride.",
		"spawn_pos": Vector3(0, 1.2, 0),
		"spawn_rot_y": 0.0,
		"waypoints": [
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 0, -100), "bank_deg": 0.0, "width": 16.0},
			# 360 Degree Vertical Loop
			{"pos": Vector3(0, 14, -145), "bank_deg": 0.0, "width": 15.0},
			{"pos": Vector3(0, 32, -180), "bank_deg": 0.0, "width": 15.0}, # Apex inverted
			{"pos": Vector3(0, 14, -215), "bank_deg": 0.0, "width": 15.0},
			{"pos": Vector3(0, 0, -260), "bank_deg": 0.0, "width": 16.0}, # Exit loop
			# Wall Ride Entry
			{"pos": Vector3(50, 4, -310), "bank_deg": 45.0, "width": 16.0},
			{"pos": Vector3(130, 12, -320), "bank_deg": 75.0, "width": 16.0}, # Wall ride
			{"pos": Vector3(200, 12, -260), "bank_deg": 75.0, "width": 16.0},
			{"pos": Vector3(220, 2, -160), "bank_deg": 20.0, "width": 16.0},
			{"pos": Vector3(150, 0, -50), "bank_deg": -15.0, "width": 16.0},
			{"pos": Vector3(60, 0, 20), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 16.0}
		],
		"checkpoints": [0, 3, 7, 10, 12],
		"hazards": [
			{"type": 0, "pos": Vector3(0, 0, -60)},
			{"type": 1, "pos": Vector3(170, 4, -90)}
		]
	}

static func _get_course_3_skyscraper_rush() -> Dictionary:
	return {
		"id": "skyscraper_rush",
		"name": "Skyscraper Rush",
		"tagline": "Rooftop Descent to Coastal Highway",
		"environment": AeroConstants.EnvironmentType.NEON_MEGACITY,
		"mode": AeroConstants.GameMode.SPRINT,
		"laps": 1,
		"tier": 2,
		"gold_time": 54.0,
		"silver_time": 64.0,
		"bronze_time": 76.0,
		"gold_score": 15000,
		"desc": "High-altitude sprint starting from a skyscraper helipad, plunging down spiral ramps across expressway gaps.",
		"spawn_pos": Vector3(0, 65.2, 0),
		"spawn_rot_y": 0.0,
		"waypoints": [
			{"pos": Vector3(0, 64, 0), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(0, 60, -90), "bank_deg": 15.0, "width": 16.0},
			{"pos": Vector3(45, 50, -170), "bank_deg": 35.0, "width": 16.0},
			{"pos": Vector3(120, 36, -210), "bank_deg": 40.0, "width": 16.0},
			{"pos": Vector3(180, 22, -160), "bank_deg": 30.0, "width": 16.0},
			{"pos": Vector3(190, 12, -70), "bank_deg": 15.0, "width": 16.0},
			{"pos": Vector3(150, 4, 30), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(80, 0, 120), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 0, 220), "bank_deg": 0.0, "width": 18.0}
		],
		"checkpoints": [0, 2, 4, 6, 8],
		"hazards": [
			{"type": 0, "pos": Vector3(120, 36, -210)}
		]
	}

# ==============================================================================
# ENVIRONMENT 2: MOUNTAIN CANYON
# ==============================================================================

static func _get_course_4_canyon_slingshot() -> Dictionary:
	return {
		"id": "canyon_slingshot",
		"name": "Canyon Slingshot",
		"tagline": "Red Rock Chasm Mega Jump",
		"environment": AeroConstants.EnvironmentType.MOUNTAIN_CANYON,
		"mode": AeroConstants.GameMode.SPRINT,
		"laps": 1,
		"tier": 1,
		"gold_time": 58.0,
		"silver_time": 68.0,
		"bronze_time": 82.0,
		"gold_score": 14000,
		"desc": "A blistering point-to-point gorge run featuring a 50m jump across a canyon chasm and banked stone curves.",
		"spawn_pos": Vector3(0, 32.2, 0),
		"spawn_rot_y": 0.0,
		"waypoints": [
			{"pos": Vector3(0, 32, 0), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 24, -120), "bank_deg": -15.0, "width": 16.0},
			{"pos": Vector3(-40, 16, -220), "bank_deg": -30.0, "width": 16.0},
			{"pos": Vector3(-30, 8, -320), "bank_deg": 0.0, "width": 15.0},
			# Natural Chasm Mega Jump
			{"pos": Vector3(10, 14, -400), "bank_deg": 0.0, "width": 16.0, "is_jump_gap": true},
			{"pos": Vector3(40, 6, -490), "bank_deg": 15.0, "width": 20.0}, # Catch basin
			{"pos": Vector3(90, 2, -580), "bank_deg": 30.0, "width": 16.0},
			{"pos": Vector3(160, 0, -620), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(250, 0, -620), "bank_deg": 0.0, "width": 16.0}
		],
		"checkpoints": [0, 2, 4, 6, 8],
		"hazards": []
	}

static func _get_course_5_red_rock_roller() -> Dictionary:
	return {
		"id": "red_rock_roller",
		"name": "Red Rock Roller",
		"tagline": "Double Corkscrew Canyon Speedway",
		"environment": AeroConstants.EnvironmentType.MOUNTAIN_CANYON,
		"mode": AeroConstants.GameMode.CIRCUIT,
		"laps": 2,
		"tier": 2,
		"gold_time": 82.0,
		"silver_time": 95.0,
		"bronze_time": 115.0,
		"gold_score": 19000,
		"desc": "Technical canyon circuit with two continuous banked corkscrews and a suspended gorge suspension bridge.",
		"spawn_pos": Vector3(0, 1.2, 0),
		"spawn_rot_y": 0.0,
		"waypoints": [
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 0, -110), "bank_deg": 20.0, "width": 16.0},
			{"pos": Vector3(60, 18, -190), "bank_deg": 50.0, "width": 15.0},
			{"pos": Vector3(140, 24, -180), "bank_deg": 65.0, "width": 15.0}, # Corkscrew 1
			{"pos": Vector3(180, 14, -100), "bank_deg": 30.0, "width": 16.0},
			{"pos": Vector3(140, 6, -20), "bank_deg": -15.0, "width": 16.0},
			{"pos": Vector3(40, 12, 60), "bank_deg": -45.0, "width": 15.0},  # Corkscrew 2
			{"pos": Vector3(-40, 8, 40), "bank_deg": -30.0, "width": 16.0},
			{"pos": Vector3(-60, 4, 10), "bank_deg": -20.0, "width": 16.0},
			{"pos": Vector3(-50, 2, -30), "bank_deg": -10.0, "width": 16.0},
			{"pos": Vector3(-30, 0, -35), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 16.0}
		],
		"checkpoints": [0, 3, 6, 9, 11],
		"hazards": [
			{"type": 2, "pos": Vector3(140, 24, -180)}
		]
	}

static func _get_course_6_ridge_hazard_run() -> Dictionary:
	return {
		"id": "ridge_hazard_run",
		"name": "Ridge Hazard Run",
		"tagline": "Kinetic Crusher Cliffside Gauntlet",
		"environment": AeroConstants.EnvironmentType.MOUNTAIN_CANYON,
		"mode": AeroConstants.GameMode.HAZARD_RUN,
		"laps": 1,
		"tier": 3,
		"gold_time": 62.0,
		"silver_time": 74.0,
		"bronze_time": 90.0,
		"gold_score": 16000,
		"desc": "A hazardous mountain ridge course packed with swinging rock pendulums and oscillating crushers.",
		"spawn_pos": Vector3(0, 1.2, 0),
		"spawn_rot_y": 0.0,
		"waypoints": [
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 0, -90), "bank_deg": 0.0, "width": 14.0},
			{"pos": Vector3(30, 4, -180), "bank_deg": 25.0, "width": 14.0},
			{"pos": Vector3(90, 8, -250), "bank_deg": 35.0, "width": 14.0},
			{"pos": Vector3(160, 12, -280), "bank_deg": 15.0, "width": 14.0},
			{"pos": Vector3(230, 6, -240), "bank_deg": -20.0, "width": 14.0},
			{"pos": Vector3(260, 2, -150), "bank_deg": 0.0, "width": 14.0},
			{"pos": Vector3(220, 0, -60), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(120, 0, 20), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 16.0}
		],
		"checkpoints": [0, 3, 6, 9],
		"hazards": [
			{"type": 1, "pos": Vector3(0, 0, -90)},
			{"type": 0, "pos": Vector3(90, 8, -250)},
			{"type": 2, "pos": Vector3(230, 6, -240)}
		]
	}

# ==============================================================================
# ENVIRONMENT 3: TROPICAL COASTAL
# ==============================================================================

static func _get_course_7_azure_boardwalk() -> Dictionary:
	return {
		"id": "azure_boardwalk",
		"name": "Azure Boardwalk",
		"tagline": "Ocean Shoreline Speedway",
		"environment": AeroConstants.EnvironmentType.TROPICAL_COASTAL,
		"mode": AeroConstants.GameMode.CIRCUIT,
		"laps": 2,
		"tier": 1,
		"gold_time": 66.0,
		"silver_time": 76.0,
		"bronze_time": 90.0,
		"gold_score": 13000,
		"desc": "A scenic coastal speedway flanked by palm groves, beachfront boardwalks, and a sea arch ramp jump.",
		"spawn_pos": Vector3(0, 1.2, 0),
		"spawn_rot_y": 0.0,
		"waypoints": [
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 0, -120), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(40, 2, -210), "bank_deg": 20.0, "width": 16.0},
			{"pos": Vector3(120, 4, -260), "bank_deg": 35.0, "width": 16.0},
			{"pos": Vector3(210, 8, -240), "bank_deg": 25.0, "width": 16.0},
			{"pos": Vector3(270, 4, -160), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(260, 0, -60), "bank_deg": -15.0, "width": 16.0},
			{"pos": Vector3(180, 0, 30), "bank_deg": -25.0, "width": 16.0},
			{"pos": Vector3(90, 0, 40), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 16.0}
		],
		"checkpoints": [0, 3, 6, 9],
		"hazards": []
	}

static func _get_course_8_cliffside_wallride() -> Dictionary:
	return {
		"id": "cliffside_wallride",
		"name": "Cliffside Wallride",
		"tagline": "80° Vertical Ocean Sea-Wall Ride",
		"environment": AeroConstants.EnvironmentType.TROPICAL_COASTAL,
		"mode": AeroConstants.GameMode.SPRINT,
		"laps": 1,
		"tier": 2,
		"gold_time": 56.0,
		"silver_time": 66.0,
		"bronze_time": 80.0,
		"gold_score": 17500,
		"desc": "A thrilling point-to-point cliff run featuring a sustained 80° wall ride directly over crashing ocean waves.",
		"spawn_pos": Vector3(0, 1.2, 0),
		"spawn_rot_y": 0.0,
		"waypoints": [
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 0, -110), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(35, 6, -190), "bank_deg": 40.0, "width": 16.0},
			# 80 Degree Ocean Wall Ride
			{"pos": Vector3(100, 16, -260), "bank_deg": 80.0, "width": 16.0},
			{"pos": Vector3(180, 20, -280), "bank_deg": 80.0, "width": 16.0},
			{"pos": Vector3(250, 12, -240), "bank_deg": 50.0, "width": 16.0},
			{"pos": Vector3(290, 2, -150), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(260, 0, -40), "bank_deg": -15.0, "width": 16.0},
			{"pos": Vector3(150, 0, 30), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 16.0}
		],
		"checkpoints": [0, 3, 5, 8, 9],
		"hazards": []
	}

static func _get_course_9_tropic_stunt_arena() -> Dictionary:
	return {
		"id": "tropic_stunt_arena",
		"name": "Tropic Stunt Arena",
		"tagline": "Open Stunt Park Quarter-Pipes & Rings",
		"environment": AeroConstants.EnvironmentType.TROPICAL_COASTAL,
		"mode": AeroConstants.GameMode.STUNT_CHALLENGE,
		"laps": 1,
		"tier": 2,
		"gold_time": 90.0,
		"silver_time": 105.0,
		"bronze_time": 120.0,
		"gold_score": 25000,
		"desc": "Open tropical stunt playground filled with giant half-pipes, launch ramps, and aerial boost hoops.",
		"spawn_pos": Vector3(0, 1.2, 0),
		"spawn_rot_y": 0.0,
		"waypoints": [
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(0, 0, -90), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(50, 18, -160), "bank_deg": 55.0, "width": 20.0},
			{"pos": Vector3(130, 24, -180), "bank_deg": 65.0, "width": 20.0},
			{"pos": Vector3(190, 10, -130), "bank_deg": 25.0, "width": 20.0},
			{"pos": Vector3(170, 2, -40), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(80, 0, 30), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 20.0}
		],
		"checkpoints": [0, 3, 5, 7],
		"hazards": []
	}

# ==============================================================================
# ENVIRONMENT 4: HIGH-ALTITUDE SKY CIRCUIT
# ==============================================================================

static func _get_course_10_strato_pylon_gp() -> Dictionary:
	return {
		"id": "strato_pylon_gp",
		"name": "Strato Pylon GP",
		"tagline": "Cloud-Level Levitation Raceway",
		"environment": AeroConstants.EnvironmentType.SKY_CIRCUIT,
		"mode": AeroConstants.GameMode.CIRCUIT,
		"laps": 2,
		"tier": 1,
		"gold_time": 72.0,
		"silver_time": 84.0,
		"bronze_time": 98.0,
		"gold_score": 15000,
		"desc": "Stratospheric track suspended high above the cloud layer with high-G banked turns around magnetic pylons.",
		"spawn_pos": Vector3(0, 85.2, 0),
		"spawn_rot_y": 0.0,
		"waypoints": [
			{"pos": Vector3(0, 85, 0), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 85, -120), "bank_deg": 15.0, "width": 16.0},
			{"pos": Vector3(45, 92, -220), "bank_deg": 40.0, "width": 16.0},
			{"pos": Vector3(130, 96, -270), "bank_deg": 55.0, "width": 16.0},
			{"pos": Vector3(220, 92, -240), "bank_deg": 35.0, "width": 16.0},
			{"pos": Vector3(270, 85, -150), "bank_deg": 10.0, "width": 16.0},
			{"pos": Vector3(240, 82, -40), "bank_deg": -20.0, "width": 16.0},
			{"pos": Vector3(150, 82, 30), "bank_deg": -35.0, "width": 16.0},
			{"pos": Vector3(60, 85, 30), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 85, 0), "bank_deg": 0.0, "width": 16.0}
		],
		"checkpoints": [0, 3, 6, 9],
		"hazards": [
			{"type": 0, "pos": Vector3(130, 96, -270)}
		]
	}

static func _get_course_11_zenith_corkscrew() -> Dictionary:
	return {
		"id": "zenith_corkscrew",
		"name": "Zenith Corkscrew",
		"tagline": "Terminal-Velocity Vertical Dive",
		"environment": AeroConstants.EnvironmentType.SKY_CIRCUIT,
		"mode": AeroConstants.GameMode.SPRINT,
		"laps": 1,
		"tier": 2,
		"gold_time": 52.0,
		"silver_time": 62.0,
		"bronze_time": 75.0,
		"gold_score": 21000,
		"desc": "An astonishing supersonic plunge down a triple corkscrew dropping 100 meters into a floating landing bay.",
		"spawn_pos": Vector3(0, 110.2, 0),
		"spawn_rot_y": 0.0,
		"waypoints": [
			{"pos": Vector3(0, 110, 0), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 105, -90), "bank_deg": 25.0, "width": 16.0},
			{"pos": Vector3(40, 85, -170), "bank_deg": 65.0, "width": 15.0},
			{"pos": Vector3(100, 65, -200), "bank_deg": 75.0, "width": 15.0}, # Corkscrew Dive
			{"pos": Vector3(160, 45, -170), "bank_deg": 60.0, "width": 15.0},
			{"pos": Vector3(180, 30, -90), "bank_deg": 35.0, "width": 16.0},
			{"pos": Vector3(140, 20, 0), "bank_deg": 15.0, "width": 16.0},
			{"pos": Vector3(60, 15, 80), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(0, 15, 160), "bank_deg": 0.0, "width": 18.0}
		],
		"checkpoints": [0, 2, 4, 6, 8],
		"hazards": [
			{"type": 1, "pos": Vector3(100, 65, -200)}
		]
	}

static func _get_course_12_apex_impossible() -> Dictionary:
	return {
		"id": "apex_impossible",
		"name": "Apex Impossible Circuit",
		"tagline": "The Ultimate Championship Stunt Track",
		"environment": AeroConstants.EnvironmentType.SKY_CIRCUIT,
		"mode": AeroConstants.GameMode.CIRCUIT,
		"laps": 3,
		"tier": 4,
		"gold_time": 105.0,
		"silver_time": 122.0,
		"bronze_time": 145.0,
		"gold_score": 35000,
		"desc": "The pinnacle of stunt driving: combines a 360° vertical loop, double wall ride, oscillating laser obstacles, and an aerial mega jump.",
		"spawn_pos": Vector3(0, 70.2, 0),
		"spawn_rot_y": 0.0,
		"waypoints": [
			{"pos": Vector3(0, 70, 0), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 70, -110), "bank_deg": 0.0, "width": 16.0},
			# Full Vertical Loop
			{"pos": Vector3(0, 85, -155), "bank_deg": 0.0, "width": 15.0},
			{"pos": Vector3(0, 105, -195), "bank_deg": 0.0, "width": 15.0}, # Apex loop
			{"pos": Vector3(0, 85, -235), "bank_deg": 0.0, "width": 15.0},
			{"pos": Vector3(0, 70, -280), "bank_deg": 0.0, "width": 16.0},
			# Mega Wall Ride
			{"pos": Vector3(60, 76, -340), "bank_deg": 45.0, "width": 16.0},
			{"pos": Vector3(140, 86, -360), "bank_deg": 80.0, "width": 16.0}, # Wall ride
			{"pos": Vector3(220, 86, -300), "bank_deg": 80.0, "width": 16.0},
			{"pos": Vector3(260, 74, -200), "bank_deg": 35.0, "width": 16.0},
			{"pos": Vector3(220, 68, -80), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(120, 68, 30), "bank_deg": -25.0, "width": 16.0},
			{"pos": Vector3(0, 70, 0), "bank_deg": 0.0, "width": 16.0}
		],
		"checkpoints": [0, 3, 7, 10, 12],
		"hazards": [
			{"type": 0, "pos": Vector3(0, 70, -70)},
			{"type": 1, "pos": Vector3(220, 86, -300)},
			{"type": 2, "pos": Vector3(170, 68, -20)}
		]
	}
