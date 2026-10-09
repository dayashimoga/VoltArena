class_name AeroCourseDatabase
extends RefCounted

## Master repository of all 12 handcrafted stunt courses for AeroRush.
## Spans all 6 distinct biomes (Neon Afterdark, Desert Extreme, Coastal Velocity,
## Snowbound Peaks, Wild Forest, Skyline Rush) with modular disconnected islands,
## launch kickers, genuine ballistic air gaps, landing catch aprons, 360° loops,
## 75° wall-rides, and kinetic moving platforms.

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
# BIOME 1: NEON AFTERDARK / MEGACITY (Courses 1, 2, 3)
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
		"gold_time": 72.0,
		"silver_time": 85.0,
		"bronze_time": 105.0,
		"gold_score": 15000,
		"desc": "The definitive AeroRush stunt circuit: Disconnected stunt islands spanning high-speed boulevard launch, 52m aerial gap, 360° vertical loop, drop transfer, 75° skyscraper wall ride, kinetic moving platform, and grand finish stadium.",
		"spawn_pos": Vector3(0, 1.0, 0),
		"spawn_rot_y": 0.0,
		"islands": [
			{
				"id": "island_1_boulevard_launch",
				"name": "Boulevard Launch & Ramp A",
				"waypoints": [
					{"pos": Vector3(0, 1.0, 0), "bank_deg": 0.0, "width": 20.0},
					{"pos": Vector3(0, 1.0, -45), "bank_deg": 0.0, "width": 20.0},
					{"pos": Vector3(0, 2.0, -90), "bank_deg": 0.0, "width": 18.0},
					{"pos": Vector3(0, 6.0, -135), "bank_deg": 0.0, "width": 18.0},
					{"pos": Vector3(0, 14.0, -170), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"speed_boost_pads": [1, 3],
				"support_pillars": true
			},
			{
				"id": "island_2_loop_deck",
				"name": "Landing Apron B & 360° Loop Deck",
				"waypoints": [
					{"pos": Vector3(0, 9.0, -195), "bank_deg": 0.0, "width": 24.0},
					{"pos": Vector3(0, 8.0, -260), "bank_deg": 0.0, "width": 18.0},
					{"pos": Vector3(0, 10.0, -290), "bank_deg": 0.0, "width": 17.0},
					{"pos": Vector3(0, 22.0, -315), "bank_deg": 0.0, "width": 16.0},
					{"pos": Vector3(0, 38.0, -330), "bank_deg": 0.0, "width": 16.0},
					{"pos": Vector3(0, 36.0, -345), "bank_deg": 0.0, "width": 16.0},
					{"pos": Vector3(0, 20.0, -360), "bank_deg": 0.0, "width": 16.0},
					{"pos": Vector3(0, 7.0, -380), "bank_deg": 0.0, "width": 17.0},
					{"pos": Vector3(10, 8.0, -410), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 16.0,
				"support_pillars": true
			},
			{
				"id": "island_3_wallride_island",
				"name": "Rooftop Platform C & 75° Wall Ride",
				"waypoints": [
					{"pos": Vector3(16, 6.0, -422), "bank_deg": 18.0, "width": 24.0},
					{"pos": Vector3(45, 6.0, -435), "bank_deg": 45.0, "width": 18.0},
					{"pos": Vector3(100, 12.0, -400), "bank_deg": 75.0, "width": 18.0},
					{"pos": Vector3(115, 12.0, -350), "bank_deg": 75.0, "width": 18.0},
					{"pos": Vector3(105, 8.0, -300), "bank_deg": 38.0, "width": 18.0},
					{"pos": Vector3(90, 11.0, -260), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 28.0, "jump_speed_target": 38.0, "jump_speed_max": 50.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"support_pillars": true
			},
			{
				"id": "island_4_split_stunt_island",
				"name": "Kinetic Moving Stunt Platform D & Transfer Jump",
				"is_moving_platform": true,
				"movement_axis": Vector3(1.0, 0.0, 0.0),
				"movement_distance": 16.0,
				"movement_speed": 1.1,
				"waypoints": [
					{"pos": Vector3(78, 7.0, -240), "bank_deg": 0.0, "width": 24.0},
					{"pos": Vector3(65, 5.0, -205), "bank_deg": 0.0, "width": 22.0},
					{"pos": Vector3(55, 4.0, -165), "bank_deg": -22.0, "width": 18.0},
					{"pos": Vector3(35, 3.0, -125), "bank_deg": 22.0, "width": 18.0},
					{"pos": Vector3(20, 2.0, -85), "bank_deg": 0.0, "width": 19.0},
					{"pos": Vector3(10, 8.0, -50), "bank_deg": 0.0, "width": 20.0, "is_jump_gap": true, "jump_speed_min": 28.0, "jump_speed_target": 38.0, "jump_speed_max": 50.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 22.0,
				"speed_boost_pads": [3],
				"support_pillars": false
			},
			{
				"id": "island_5_finish_stadium",
				"name": "Grand Stadium Finish Platform",
				"waypoints": [
					{"pos": Vector3(5, 1.5, -25), "bank_deg": 0.0, "width": 24.0},
					{"pos": Vector3(0, 1.0, 0), "bank_deg": 0.0, "width": 22.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 28.0,
				"support_pillars": true
			}
		],
		"waypoints": [
			{"pos": Vector3(0, 1.0, 0), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(0, 1.0, -45), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(0, 2.0, -90), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(0, 6.0, -135), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(0, 14.0, -170), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(0, 9.0, -195), "bank_deg": 0.0, "width": 24.0},
			{"pos": Vector3(0, 8.0, -260), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(0, 10.0, -290), "bank_deg": 0.0, "width": 17.0},
			{"pos": Vector3(0, 22.0, -315), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 38.0, -330), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 36.0, -345), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 20.0, -360), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 7.0, -380), "bank_deg": 0.0, "width": 17.0},
			{"pos": Vector3(10, 8.0, -410), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(16, 6.0, -422), "bank_deg": 18.0, "width": 24.0},
			{"pos": Vector3(45, 6.0, -435), "bank_deg": 45.0, "width": 18.0},
			{"pos": Vector3(100, 12.0, -400), "bank_deg": 75.0, "width": 18.0},
			{"pos": Vector3(115, 12.0, -350), "bank_deg": 75.0, "width": 18.0},
			{"pos": Vector3(105, 8.0, -300), "bank_deg": 38.0, "width": 18.0},
			{"pos": Vector3(90, 11.0, -260), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 28.0, "jump_speed_target": 38.0, "jump_speed_max": 50.0},
			{"pos": Vector3(78, 7.0, -240), "bank_deg": 0.0, "width": 24.0},
			{"pos": Vector3(65, 5.0, -205), "bank_deg": 0.0, "width": 22.0},
			{"pos": Vector3(55, 4.0, -165), "bank_deg": -22.0, "width": 18.0},
			{"pos": Vector3(35, 3.0, -125), "bank_deg": 22.0, "width": 18.0},
			{"pos": Vector3(20, 2.0, -85), "bank_deg": 0.0, "width": 19.0},
			{"pos": Vector3(10, 8.0, -50), "bank_deg": 0.0, "width": 20.0, "is_jump_gap": true, "jump_speed_min": 28.0, "jump_speed_target": 38.0, "jump_speed_max": 50.0},
			{"pos": Vector3(5, 1.5, -25), "bank_deg": 0.0, "width": 24.0},
			{"pos": Vector3(0, 1.0, 0), "bank_deg": 0.0, "width": 22.0}
		],
		"checkpoints": [0, 4, 5, 13, 14, 19, 20, 25, 27],
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
		"desc": "A demanding downtown stunt course with an enormous vertical loop, 45m aerial gap, and a 75° high-speed tower wall ride.",
		"spawn_pos": Vector3(0, 1.2, 0),
		"spawn_rot_y": 0.0,
		"islands": [
			{
				"id": "c2_island_1_runway",
				"name": "Downtown Boulevard Launch",
				"waypoints": [
					{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 18.0},
					{"pos": Vector3(0, 0, -50), "bank_deg": 0.0, "width": 18.0},
					{"pos": Vector3(0, 4, -95), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"speed_boost_pads": [1],
				"support_pillars": true
			},
			{
				"id": "c2_island_2_vertical_loop",
				"name": "360° Vertical Loop Deck",
				"waypoints": [
					{"pos": Vector3(0, 5, -125), "bank_deg": 0.0, "width": 22.0},
					{"pos": Vector3(0, 14, -155), "bank_deg": 0.0, "width": 16.0},
					{"pos": Vector3(0, 32, -180), "bank_deg": 0.0, "width": 16.0},
					{"pos": Vector3(0, 14, -205), "bank_deg": 0.0, "width": 16.0},
					{"pos": Vector3(0, 4, -235), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 24.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 16.0,
				"support_pillars": true
			},
			{
				"id": "c2_island_3_wallride",
				"name": "75° Skyscraper Wall Ride Platform",
				"waypoints": [
					{"pos": Vector3(25, 4, -260), "bank_deg": 25.0, "width": 22.0},
					{"pos": Vector3(80, 8, -280), "bank_deg": 55.0, "width": 18.0},
					{"pos": Vector3(140, 12, -260), "bank_deg": 75.0, "width": 18.0},
					{"pos": Vector3(180, 10, -200), "bank_deg": 50.0, "width": 18.0},
					{"pos": Vector3(160, 6, -130), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 24.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"support_pillars": true
			},
			{
				"id": "c2_island_4_finish",
				"name": "Return Speedway & Finish Gantry",
				"waypoints": [
					{"pos": Vector3(120, 2, -100), "bank_deg": 0.0, "width": 22.0},
					{"pos": Vector3(50, 0, -30), "bank_deg": 0.0, "width": 20.0},
					{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 20.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 24.0,
				"support_pillars": true
			}
		],
		"waypoints": [
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(0, 0, -50), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(0, 4, -95), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(0, 5, -125), "bank_deg": 0.0, "width": 22.0},
			{"pos": Vector3(0, 14, -155), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 32, -180), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 14, -205), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 4, -235), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(25, 4, -260), "bank_deg": 25.0, "width": 22.0},
			{"pos": Vector3(80, 8, -280), "bank_deg": 55.0, "width": 18.0},
			{"pos": Vector3(140, 12, -260), "bank_deg": 75.0, "width": 18.0},
			{"pos": Vector3(180, 10, -200), "bank_deg": 50.0, "width": 18.0},
			{"pos": Vector3(160, 6, -130), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(120, 2, -100), "bank_deg": 0.0, "width": 22.0},
			{"pos": Vector3(50, 0, -30), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 20.0}
		],
		"checkpoints": [0, 2, 7, 12, 15],
		"hazards": [
			{"type": 0, "pos": Vector3(0, 0, -40)},
			{"type": 1, "pos": Vector3(140, 12, -260)}
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
		"desc": "High-altitude sprint starting from a skyscraper helipad, plunging down spiral ramps across aerial gaps.",
		"spawn_pos": Vector3(0, 65.2, 0),
		"spawn_rot_y": 0.0,
		"islands": [
			{
				"id": "c3_island_1_helipad",
				"name": "Helipad Launch Deck",
				"waypoints": [
					{"pos": Vector3(0, 64, 0), "bank_deg": 0.0, "width": 20.0},
					{"pos": Vector3(0, 62, -60), "bank_deg": 10.0, "width": 18.0},
					{"pos": Vector3(15, 56, -110), "bank_deg": 25.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"speed_boost_pads": [1],
				"support_pillars": true
			},
			{
				"id": "c3_island_2_spiral",
				"name": "Mid-Altitude Spiral Deck",
				"waypoints": [
					{"pos": Vector3(40, 48, -140), "bank_deg": 35.0, "width": 24.0},
					{"pos": Vector3(100, 38, -170), "bank_deg": 40.0, "width": 18.0},
					{"pos": Vector3(160, 26, -130), "bank_deg": 25.0, "width": 18.0},
					{"pos": Vector3(170, 16, -60), "bank_deg": 10.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"support_pillars": true
			},
			{
				"id": "c3_island_3_finish",
				"name": "Ground Speedway Finish",
				"waypoints": [
					{"pos": Vector3(140, 8, -20), "bank_deg": 0.0, "width": 24.0},
					{"pos": Vector3(70, 2, 60), "bank_deg": 0.0, "width": 20.0},
					{"pos": Vector3(0, 0, 140), "bank_deg": 0.0, "width": 20.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"support_pillars": true
			}
		],
		"waypoints": [
			{"pos": Vector3(0, 64, 0), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(0, 62, -60), "bank_deg": 10.0, "width": 18.0},
			{"pos": Vector3(15, 56, -110), "bank_deg": 25.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(40, 48, -140), "bank_deg": 35.0, "width": 24.0},
			{"pos": Vector3(100, 38, -170), "bank_deg": 40.0, "width": 18.0},
			{"pos": Vector3(160, 26, -130), "bank_deg": 25.0, "width": 18.0},
			{"pos": Vector3(170, 16, -60), "bank_deg": 10.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(140, 8, -20), "bank_deg": 0.0, "width": 24.0},
			{"pos": Vector3(70, 2, 60), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(0, 0, 140), "bank_deg": 0.0, "width": 20.0}
		],
		"checkpoints": [0, 2, 6, 9],
		"hazards": []
	}

# ==============================================================================
# BIOME 2: DESERT EXTREME / CANYON (Courses 4, 5, 6)
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
		"islands": [
			{
				"id": "c4_island_1_cliff",
				"name": "High Mesa Runway",
				"waypoints": [
					{"pos": Vector3(0, 32, 0), "bank_deg": 0.0, "width": 18.0},
					{"pos": Vector3(0, 26, -90), "bank_deg": -10.0, "width": 18.0},
					{"pos": Vector3(-20, 20, -170), "bank_deg": -20.0, "width": 18.0},
					{"pos": Vector3(-10, 24, -240), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 20.0,
				"speed_boost_pads": [2],
				"support_pillars": true
			},
			{
				"id": "c4_island_2_chasm",
				"name": "Chasm Catch Basin & Stone Arch",
				"waypoints": [
					{"pos": Vector3(10, 16, -280), "bank_deg": 15.0, "width": 26.0},
					{"pos": Vector3(60, 10, -360), "bank_deg": 30.0, "width": 18.0},
					{"pos": Vector3(130, 6, -430), "bank_deg": 15.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 28.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 16.0,
				"support_pillars": true
			},
			{
				"id": "c4_island_3_valley",
				"name": "Canyon Floor Finish Runway",
				"waypoints": [
					{"pos": Vector3(170, 2, -470), "bank_deg": 0.0, "width": 24.0},
					{"pos": Vector3(230, 0, -540), "bank_deg": 0.0, "width": 20.0},
					{"pos": Vector3(300, 0, -540), "bank_deg": 0.0, "width": 20.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"support_pillars": true
			}
		],
		"waypoints": [
			{"pos": Vector3(0, 32, 0), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(0, 26, -90), "bank_deg": -10.0, "width": 18.0},
			{"pos": Vector3(-20, 20, -170), "bank_deg": -20.0, "width": 18.0},
			{"pos": Vector3(-10, 24, -240), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(10, 16, -280), "bank_deg": 15.0, "width": 26.0},
			{"pos": Vector3(60, 10, -360), "bank_deg": 30.0, "width": 18.0},
			{"pos": Vector3(130, 6, -430), "bank_deg": 15.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(170, 2, -470), "bank_deg": 0.0, "width": 24.0},
			{"pos": Vector3(230, 0, -540), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(300, 0, -540), "bank_deg": 0.0, "width": 20.0}
		],
		"checkpoints": [0, 3, 6, 9],
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
		"desc": "Technical canyon circuit with two continuous banked corkscrews, kinetic moving mesa, and aerial chasm leaps.",
		"spawn_pos": Vector3(0, 1.2, 0),
		"spawn_rot_y": 0.0,
		"islands": [
			{
				"id": "c5_island_1_start",
				"name": "Canyon Ridge Start Deck",
				"waypoints": [
					{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 18.0},
					{"pos": Vector3(0, 2, -60), "bank_deg": 15.0, "width": 18.0},
					{"pos": Vector3(25, 8, -120), "bank_deg": 30.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 44.0, "jump_speed_target": 48.0, "jump_speed_max": 54.0}
				],
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"speed_boost_pads": [1],
				"support_pillars": true
			},
			{
				"id": "c5_island_2_corkscrew",
				"name": "Double Corkscrew Ridge Deck",
				"waypoints": [
					{"pos": Vector3(60, 12, -160), "bank_deg": 45.0, "width": 24.0},
					{"pos": Vector3(120, 22, -170), "bank_deg": 65.0, "width": 16.0},
					{"pos": Vector3(160, 14, -110), "bank_deg": 35.0, "width": 16.0},
					{"pos": Vector3(140, 8, -40), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"support_pillars": true
			},
			{
				"id": "c5_island_3_moving",
				"name": "Kinetic Moving Mesa Platform",
				"is_moving_platform": true,
				"movement_axis": Vector3(0.0, 1.0, 0.0),
				"movement_distance": 14.0,
				"movement_speed": 1.0,
				"waypoints": [
					{"pos": Vector3(100, 10, 0), "bank_deg": -15.0, "width": 24.0},
					{"pos": Vector3(40, 10, 45), "bank_deg": -35.0, "width": 20.0},
					{"pos": Vector3(-20, 6, 30), "bank_deg": 0.0, "width": 20.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 16.0,
				"support_pillars": false
			},
			{
				"id": "c5_island_4_finish",
				"name": "Return Speedway & Finish Deck",
				"waypoints": [
					{"pos": Vector3(-42, 3, 5), "bank_deg": 0.0, "width": 24.0},
					{"pos": Vector3(-25, 0, -15), "bank_deg": 0.0, "width": 20.0},
					{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 20.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"support_pillars": true
			}
		],
		"waypoints": [
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(0, 2, -60), "bank_deg": 15.0, "width": 18.0},
			{"pos": Vector3(25, 8, -120), "bank_deg": 30.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 44.0, "jump_speed_target": 48.0, "jump_speed_max": 54.0},
			{"pos": Vector3(60, 12, -160), "bank_deg": 45.0, "width": 24.0},
			{"pos": Vector3(120, 22, -170), "bank_deg": 65.0, "width": 16.0},
			{"pos": Vector3(160, 14, -110), "bank_deg": 35.0, "width": 16.0},
			{"pos": Vector3(140, 8, -40), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(100, 10, 0), "bank_deg": -15.0, "width": 24.0},
			{"pos": Vector3(40, 10, 45), "bank_deg": -35.0, "width": 20.0},
			{"pos": Vector3(-20, 6, 30), "bank_deg": 0.0, "width": 20.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(-42, 3, 5), "bank_deg": 0.0, "width": 24.0},
			{"pos": Vector3(-25, 0, -15), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 20.0}
		],
		"checkpoints": [0, 2, 6, 9, 12],
		"hazards": [
			{"type": 2, "pos": Vector3(120, 22, -170)}
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
		"desc": "A hazardous mountain ridge course packed with swinging pendulums, aerial leaps, and oscillating hazards.",
		"spawn_pos": Vector3(0, 1.2, 0),
		"spawn_rot_y": 0.0,
		"islands": [
			{
				"id": "c6_island_1",
				"name": "Ridge Entry Runway",
				"waypoints": [
					{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 16.0},
					{"pos": Vector3(0, 0, -60), "bank_deg": 0.0, "width": 16.0},
					{"pos": Vector3(15, 4, -120), "bank_deg": 15.0, "width": 16.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"support_pillars": true
			},
			{
				"id": "c6_island_2",
				"name": "Crusher Ridge Deck",
				"waypoints": [
					{"pos": Vector3(40, 6, -160), "bank_deg": 25.0, "width": 24.0},
					{"pos": Vector3(90, 8, -230), "bank_deg": 35.0, "width": 16.0},
					{"pos": Vector3(150, 10, -260), "bank_deg": 15.0, "width": 16.0},
					{"pos": Vector3(210, 6, -220), "bank_deg": -15.0, "width": 16.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"support_pillars": true
			},
			{
				"id": "c6_island_3",
				"name": "Finish Basin Deck",
				"waypoints": [
					{"pos": Vector3(230, 2, -170), "bank_deg": 0.0, "width": 24.0},
					{"pos": Vector3(180, 0, -60), "bank_deg": 0.0, "width": 18.0},
					{"pos": Vector3(80, 0, 10), "bank_deg": 0.0, "width": 18.0},
					{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 18.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"support_pillars": true
			}
		],
		"waypoints": [
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 0, -60), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(15, 4, -120), "bank_deg": 15.0, "width": 16.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(40, 6, -160), "bank_deg": 25.0, "width": 24.0},
			{"pos": Vector3(90, 8, -230), "bank_deg": 35.0, "width": 16.0},
			{"pos": Vector3(150, 10, -260), "bank_deg": 15.0, "width": 16.0},
			{"pos": Vector3(210, 6, -220), "bank_deg": -15.0, "width": 16.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(230, 2, -170), "bank_deg": 0.0, "width": 24.0},
			{"pos": Vector3(180, 0, -60), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(80, 0, 10), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 18.0}
		],
		"checkpoints": [0, 2, 6, 10],
		"hazards": [
			{"type": 1, "pos": Vector3(0, 0, -60)},
			{"type": 0, "pos": Vector3(90, 8, -230)}
		]
	}

# ==============================================================================
# BIOME 3: COASTAL VELOCITY (Courses 7, 8, 9)
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
		"desc": "A scenic coastal speedway flanked by palm groves, beachfront boardwalks, and a sea arch ramp jump over crashing waves.",
		"spawn_pos": Vector3(0, 1.2, 0),
		"spawn_rot_y": 0.0,
		"islands": [
			{
				"id": "c7_island_1_beach",
				"name": "Boardwalk Launch Runway",
				"waypoints": [
					{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 18.0},
					{"pos": Vector3(0, 0, -70), "bank_deg": 0.0, "width": 18.0},
					{"pos": Vector3(20, 3, -140), "bank_deg": 15.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"speed_boost_pads": [1],
				"support_pillars": true
			},
			{
				"id": "c7_island_2_sea_arch",
				"name": "Sea Arch Ocean Platform",
				"waypoints": [
					{"pos": Vector3(50, 4, -180), "bank_deg": 25.0, "width": 24.0},
					{"pos": Vector3(120, 6, -230), "bank_deg": 35.0, "width": 18.0},
					{"pos": Vector3(190, 8, -210), "bank_deg": 20.0, "width": 18.0},
					{"pos": Vector3(230, 4, -140), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 16.0,
				"support_pillars": true
			},
			{
				"id": "c7_island_3_boardwalk",
				"name": "Marina Finish Platform",
				"waypoints": [
					{"pos": Vector3(210, 1, -100), "bank_deg": -10.0, "width": 24.0},
					{"pos": Vector3(140, 0, -20), "bank_deg": -15.0, "width": 20.0},
					{"pos": Vector3(60, 0, 20), "bank_deg": 0.0, "width": 20.0},
					{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 20.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"support_pillars": true
			}
		],
		"waypoints": [
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(0, 0, -70), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(20, 3, -140), "bank_deg": 15.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(50, 4, -180), "bank_deg": 25.0, "width": 24.0},
			{"pos": Vector3(120, 6, -230), "bank_deg": 35.0, "width": 18.0},
			{"pos": Vector3(190, 8, -210), "bank_deg": 20.0, "width": 18.0},
			{"pos": Vector3(230, 4, -140), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(210, 1, -100), "bank_deg": -10.0, "width": 24.0},
			{"pos": Vector3(140, 0, -20), "bank_deg": -15.0, "width": 20.0},
			{"pos": Vector3(60, 0, 20), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 20.0}
		],
		"checkpoints": [0, 2, 6, 10],
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
		"islands": [
			{
				"id": "c8_island_1",
				"name": "Coastal Approach Runway",
				"waypoints": [
					{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 18.0},
					{"pos": Vector3(0, 0, -70), "bank_deg": 0.0, "width": 18.0},
					{"pos": Vector3(20, 4, -135), "bank_deg": 25.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 42.0, "jump_speed_target": 48.0, "jump_speed_max": 54.0}
				],
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"support_pillars": true
			},
			{
				"id": "c8_island_2_wall",
				"name": "80° Sea-Wall Ride Platform",
				"waypoints": [
					{"pos": Vector3(50, 8, -170), "bank_deg": 50.0, "width": 24.0},
					{"pos": Vector3(120, 16, -220), "bank_deg": 80.0, "width": 18.0},
					{"pos": Vector3(180, 18, -210), "bank_deg": 80.0, "width": 18.0},
					{"pos": Vector3(230, 8, -160), "bank_deg": 35.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"support_pillars": true
			},
			{
				"id": "c8_island_3_finish",
				"name": "Harbor Docks Finish Runway",
				"waypoints": [
					{"pos": Vector3(210, 2, -110), "bank_deg": 0.0, "width": 24.0},
					{"pos": Vector3(130, 0, -30), "bank_deg": 0.0, "width": 20.0},
					{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 20.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"support_pillars": true
			}
		],
		"waypoints": [
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(0, 0, -70), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(20, 4, -135), "bank_deg": 25.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 42.0, "jump_speed_target": 48.0, "jump_speed_max": 54.0},
			{"pos": Vector3(50, 8, -170), "bank_deg": 50.0, "width": 24.0},
			{"pos": Vector3(120, 16, -220), "bank_deg": 80.0, "width": 18.0},
			{"pos": Vector3(180, 18, -210), "bank_deg": 80.0, "width": 18.0},
			{"pos": Vector3(230, 8, -160), "bank_deg": 35.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(210, 2, -110), "bank_deg": 0.0, "width": 24.0},
			{"pos": Vector3(130, 0, -30), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 20.0}
		],
		"checkpoints": [0, 2, 6, 9],
		"hazards": []
	}

static func _get_course_9_tropic_stunt_arena() -> Dictionary:
	return {
		"id": "tropic_stunt_arena",
		"name": "Tropic Stunt Arena",
		"tagline": "Open Stunt Park Quarter-Pipes & Kinetic Rings",
		"environment": AeroConstants.EnvironmentType.TROPICAL_COASTAL,
		"mode": AeroConstants.GameMode.STUNT_CHALLENGE,
		"laps": 1,
		"tier": 2,
		"gold_time": 90.0,
		"silver_time": 105.0,
		"bronze_time": 120.0,
		"gold_score": 25000,
		"desc": "Open tropical stunt playground filled with giant launch ramps, kinetic rotating platforms, and aerial boost hoops.",
		"spawn_pos": Vector3(0, 1.2, 0),
		"spawn_rot_y": 0.0,
		"islands": [
			{
				"id": "c9_island_1",
				"name": "Arena Launch Runway",
				"waypoints": [
					{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 20.0},
					{"pos": Vector3(0, 0, -60), "bank_deg": 0.0, "width": 20.0},
					{"pos": Vector3(25, 8, -120), "bank_deg": 25.0, "width": 20.0, "is_jump_gap": true, "jump_speed_min": 50.0, "jump_speed_target": 54.0, "jump_speed_max": 58.0}
				],
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 20.0,
				"speed_boost_pads": [1],
				"support_pillars": true
			},
			{
				"id": "c9_island_2_rotating",
				"name": "Kinetic Rotating Stunt Platform",
				"is_moving_platform": true,
				"is_rotating": true,
				"rotation_axis": Vector3(0.0, 1.0, 0.0),
				"rotation_speed_deg": 16.0,
				"movement_distance": 0.0,
				"waypoints": [
					{"pos": Vector3(60, 14, -160), "bank_deg": 35.0, "width": 26.0},
					{"pos": Vector3(120, 18, -180), "bank_deg": 50.0, "width": 22.0},
					{"pos": Vector3(170, 10, -140), "bank_deg": 20.0, "width": 22.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 28.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"support_pillars": false
			},
			{
				"id": "c9_island_3_finish",
				"name": "Tropic Stadium Finish Deck",
				"waypoints": [
					{"pos": Vector3(150, 4, -80), "bank_deg": 0.0, "width": 24.0},
					{"pos": Vector3(80, 0, 10), "bank_deg": 0.0, "width": 20.0},
					{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 20.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"support_pillars": true
			}
		],
		"waypoints": [
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(0, 0, -60), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(25, 8, -120), "bank_deg": 25.0, "width": 20.0, "is_jump_gap": true, "jump_speed_min": 50.0, "jump_speed_target": 54.0, "jump_speed_max": 58.0},
			{"pos": Vector3(60, 14, -160), "bank_deg": 35.0, "width": 26.0},
			{"pos": Vector3(120, 18, -180), "bank_deg": 50.0, "width": 22.0},
			{"pos": Vector3(170, 10, -140), "bank_deg": 20.0, "width": 22.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(150, 4, -80), "bank_deg": 0.0, "width": 24.0},
			{"pos": Vector3(80, 0, 10), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(0, 0, 0), "bank_deg": 0.0, "width": 20.0}
		],
		"checkpoints": [0, 2, 5, 8],
		"hazards": []
	}

# ==============================================================================
# BIOMES 4, 5, 6: SNOWBOUND PEAKS, WILD FOREST, SKYLINE RUSH (Courses 10, 11, 12)
# ==============================================================================

static func _get_course_10_strato_pylon_gp() -> Dictionary:
	return {
		"id": "strato_pylon_gp",
		"name": "Snowbound Apex",
		"tagline": "Glacial Summit & Frozen Crevasse Mega Jump",
		"environment": AeroConstants.EnvironmentType.SNOWBOUND_PEAKS,
		"mode": AeroConstants.GameMode.CIRCUIT,
		"laps": 2,
		"tier": 2,
		"gold_time": 72.0,
		"silver_time": 84.0,
		"bronze_time": 98.0,
		"gold_score": 16000,
		"desc": "Alpine winter stunt circuit suspended high above snow-capped mountain peaks and frozen glacial crevasses.",
		"spawn_pos": Vector3(0, 45.2, 0),
		"spawn_rot_y": 0.0,
		"islands": [
			{
				"id": "c10_island_1_summit",
				"name": "Glacial Summit Runway",
				"waypoints": [
					{"pos": Vector3(0, 45, 0), "bank_deg": 0.0, "width": 18.0},
					{"pos": Vector3(0, 45, -70), "bank_deg": 10.0, "width": 18.0},
					{"pos": Vector3(20, 52, -140), "bank_deg": 25.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 20.0,
				"speed_boost_pads": [1],
				"support_pillars": true
			},
			{
				"id": "c10_island_2_crevasse",
				"name": "Icy Crevasse Suspension Deck",
				"waypoints": [
					{"pos": Vector3(50, 48, -180), "bank_deg": 30.0, "width": 24.0},
					{"pos": Vector3(120, 54, -220), "bank_deg": 50.0, "width": 18.0},
					{"pos": Vector3(180, 50, -190), "bank_deg": 30.0, "width": 18.0},
					{"pos": Vector3(210, 46, -120), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"support_pillars": true
			},
			{
				"id": "c10_island_3_finish",
				"name": "Alpine Stadium Finish Runway",
				"waypoints": [
					{"pos": Vector3(180, 44, -70), "bank_deg": -15.0, "width": 24.0},
					{"pos": Vector3(100, 44, 0), "bank_deg": -15.0, "width": 20.0},
					{"pos": Vector3(0, 45, 0), "bank_deg": 0.0, "width": 20.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"support_pillars": true
			}
		],
		"waypoints": [
			{"pos": Vector3(0, 45, 0), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(0, 45, -70), "bank_deg": 10.0, "width": 18.0},
			{"pos": Vector3(20, 52, -140), "bank_deg": 25.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(50, 48, -180), "bank_deg": 30.0, "width": 24.0},
			{"pos": Vector3(120, 54, -220), "bank_deg": 50.0, "width": 18.0},
			{"pos": Vector3(180, 50, -190), "bank_deg": 30.0, "width": 18.0},
			{"pos": Vector3(210, 46, -120), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(180, 44, -70), "bank_deg": -15.0, "width": 24.0},
			{"pos": Vector3(100, 44, 0), "bank_deg": -15.0, "width": 20.0},
			{"pos": Vector3(0, 45, 0), "bank_deg": 0.0, "width": 20.0}
		],
		"checkpoints": [0, 2, 6, 9],
		"hazards": [
			{"type": 0, "pos": Vector3(120, 54, -220)}
		]
	}

static func _get_course_11_zenith_corkscrew() -> Dictionary:
	return {
		"id": "zenith_corkscrew",
		"name": "Redwood Canopy",
		"tagline": "Dense Forest Canopy & Waterfall Gorge Leap",
		"environment": AeroConstants.EnvironmentType.WILD_FOREST,
		"mode": AeroConstants.GameMode.SPRINT,
		"laps": 1,
		"tier": 2,
		"gold_time": 52.0,
		"silver_time": 62.0,
		"bronze_time": 75.0,
		"gold_score": 21000,
		"desc": "Suspended high above dense forest canopies and rushing rivers, with an astonishing leap across a waterfall chasm.",
		"spawn_pos": Vector3(0, 35.2, 0),
		"spawn_rot_y": 0.0,
		"islands": [
			{
				"id": "c11_island_1",
				"name": "Tree Canopy Launch Runway",
				"waypoints": [
					{"pos": Vector3(0, 35, 0), "bank_deg": 0.0, "width": 18.0},
					{"pos": Vector3(0, 32, -60), "bank_deg": 15.0, "width": 18.0},
					{"pos": Vector3(25, 30, -125), "bank_deg": 35.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"speed_boost_pads": [1],
				"support_pillars": true
			},
			{
				"id": "c11_island_2",
				"name": "Waterfall Gorge Catch Deck",
				"waypoints": [
					{"pos": Vector3(55, 24, -165), "bank_deg": 40.0, "width": 24.0},
					{"pos": Vector3(110, 20, -190), "bank_deg": 50.0, "width": 18.0},
					{"pos": Vector3(160, 16, -150), "bank_deg": 25.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"support_pillars": true
			},
			{
				"id": "c11_island_3",
				"name": "Forest Clearing Finish Deck",
				"waypoints": [
					{"pos": Vector3(150, 10, -90), "bank_deg": 0.0, "width": 24.0},
					{"pos": Vector3(80, 4, -20), "bank_deg": 0.0, "width": 20.0},
					{"pos": Vector3(0, 0, 50), "bank_deg": 0.0, "width": 20.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"support_pillars": true
			}
		],
		"waypoints": [
			{"pos": Vector3(0, 35, 0), "bank_deg": 0.0, "width": 18.0},
			{"pos": Vector3(0, 32, -60), "bank_deg": 15.0, "width": 18.0},
			{"pos": Vector3(25, 30, -125), "bank_deg": 35.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(55, 24, -165), "bank_deg": 40.0, "width": 24.0},
			{"pos": Vector3(110, 20, -190), "bank_deg": 50.0, "width": 18.0},
			{"pos": Vector3(160, 16, -150), "bank_deg": 25.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(150, 10, -90), "bank_deg": 0.0, "width": 24.0},
			{"pos": Vector3(80, 4, -20), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(0, 0, 50), "bank_deg": 0.0, "width": 20.0}
		],
		"checkpoints": [0, 2, 5, 8],
		"hazards": [
			{"type": 1, "pos": Vector3(110, 20, -190)}
		]
	}

static func _get_course_12_apex_impossible() -> Dictionary:
	return {
		"id": "apex_impossible",
		"name": "Metropolitan Apex",
		"tagline": "The Ultimate Championship Stunt Track",
		"environment": AeroConstants.EnvironmentType.SKYLINE_RUSH,
		"mode": AeroConstants.GameMode.CIRCUIT,
		"laps": 3,
		"tier": 4,
		"gold_time": 105.0,
		"silver_time": 122.0,
		"bronze_time": 145.0,
		"gold_score": 35000,
		"desc": "The pinnacle of stunt driving: combines high-speed rooftop launches, 360° vertical loop, 80° tower wall ride, kinetic moving platform, and an aerial mega jump.",
		"spawn_pos": Vector3(0, 50.2, 0),
		"spawn_rot_y": 0.0,
		"islands": [
			{
				"id": "c12_island_1_runway",
				"name": "Rooftop Launch Deck",
				"waypoints": [
					{"pos": Vector3(0, 50, 0), "bank_deg": 0.0, "width": 20.0},
					{"pos": Vector3(0, 50, -60), "bank_deg": 0.0, "width": 20.0},
					{"pos": Vector3(0, 56, -115), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 20.0,
				"speed_boost_pads": [1],
				"support_pillars": true
			},
			{
				"id": "c12_island_2_loop",
				"name": "Glass Loop & Transfer Platform",
				"waypoints": [
					{"pos": Vector3(0, 52, -150), "bank_deg": 0.0, "width": 24.0},
					{"pos": Vector3(0, 68, -190), "bank_deg": 0.0, "width": 16.0},
					{"pos": Vector3(0, 88, -220), "bank_deg": 0.0, "width": 16.0},
					{"pos": Vector3(0, 68, -250), "bank_deg": 0.0, "width": 16.0},
					{"pos": Vector3(0, 54, -285), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"support_pillars": true
			},
			{
				"id": "c12_island_3_wall",
				"name": "80° Office Tower Wall Ride",
				"waypoints": [
					{"pos": Vector3(30, 54, -315), "bank_deg": 35.0, "width": 24.0},
					{"pos": Vector3(100, 62, -340), "bank_deg": 80.0, "width": 18.0},
					{"pos": Vector3(180, 64, -300), "bank_deg": 80.0, "width": 18.0},
					{"pos": Vector3(220, 56, -220), "bank_deg": 40.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 18.0,
				"support_pillars": true
			},
			{
				"id": "c12_island_4_moving",
				"name": "Kinetic Moving Transfer Deck",
				"is_moving_platform": true,
				"movement_axis": Vector3(1.0, 0.0, 0.0),
				"movement_distance": 20.0,
				"movement_speed": 1.2,
				"waypoints": [
					{"pos": Vector3(190, 50, -170), "bank_deg": 0.0, "width": 24.0},
					{"pos": Vector3(130, 48, -100), "bank_deg": -15.0, "width": 20.0},
					{"pos": Vector3(70, 48, -40), "bank_deg": 0.0, "width": 20.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"has_launch_ramp": true,
				"launch_kicker_angle_deg": 16.0,
				"support_pillars": false
			},
			{
				"id": "c12_island_5_finish",
				"name": "Championship Finish Stadium Deck",
				"waypoints": [
					{"pos": Vector3(30, 48, -10), "bank_deg": 0.0, "width": 24.0},
					{"pos": Vector3(0, 50, 0), "bank_deg": 0.0, "width": 22.0}
				],
				"has_landing_apron": true,
				"landing_apron_width": 26.0,
				"support_pillars": true
			}
		],
		"waypoints": [
			{"pos": Vector3(0, 50, 0), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(0, 50, -60), "bank_deg": 0.0, "width": 20.0},
			{"pos": Vector3(0, 56, -115), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(0, 52, -150), "bank_deg": 0.0, "width": 24.0},
			{"pos": Vector3(0, 68, -190), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 88, -220), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 68, -250), "bank_deg": 0.0, "width": 16.0},
			{"pos": Vector3(0, 54, -285), "bank_deg": 0.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(30, 54, -315), "bank_deg": 35.0, "width": 24.0},
			{"pos": Vector3(100, 62, -340), "bank_deg": 80.0, "width": 18.0},
			{"pos": Vector3(180, 64, -300), "bank_deg": 80.0, "width": 18.0},
			{"pos": Vector3(220, 56, -220), "bank_deg": 40.0, "width": 18.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(190, 50, -170), "bank_deg": 0.0, "width": 24.0},
			{"pos": Vector3(130, 48, -100), "bank_deg": -15.0, "width": 20.0},
			{"pos": Vector3(70, 48, -40), "bank_deg": 0.0, "width": 20.0, "is_jump_gap": true, "jump_speed_min": 26.0, "jump_speed_target": 36.0, "jump_speed_max": 48.0},
			{"pos": Vector3(30, 48, -10), "bank_deg": 0.0, "width": 24.0},
			{"pos": Vector3(0, 50, 0), "bank_deg": 0.0, "width": 22.0}
		],
		"checkpoints": [0, 2, 7, 11, 14, 16],
		"hazards": [
			{"type": 0, "pos": Vector3(0, 50, -60)},
			{"type": 1, "pos": Vector3(140, 64, -320)}
		]
	}
