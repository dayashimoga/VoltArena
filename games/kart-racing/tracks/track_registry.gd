class_name TrackRegistry
extends RefCounted

## TrackRegistry provides data-driven track definitions for Drift Storm.
## Supports 6 distinct playable environments with unique geometry, environment lighting,
## spline parameters, and track characteristics.

class TrackDefinition:
	var id: String
	var name: String
	var description: String
	var theme: String
	var length_m: float
	var lap_count: int
	var difficulty: String # "Easy", "Medium", "Hard", "Expert"
	var nodes: Array[Vector3]
	var track_width: float
	var ambient_color: Color
	var sky_top_color: Color
	var sky_horizon_color: Color
	var fog_color: Color
	var fog_density: float

	func _init(p_id: String, p_name: String, p_desc: String, p_theme: String, p_length: float, p_laps: int, p_diff: String, p_nodes: Array[Vector3], p_width: float = 14.0) -> void:
		id = p_id
		name = p_name
		description = p_desc
		theme = p_theme
		length_m = p_length
		lap_count = p_laps
		difficulty = p_diff
		nodes = p_nodes
		track_width = p_width

static func get_all_tracks() -> Array[TrackDefinition]:
	var list: Array[TrackDefinition] = []
	list.append(get_track("speedway"))
	list.append(get_track("sunset_coast"))
	list.append(get_track("canyon"))
	list.append(get_track("skyline"))
	list.append(get_track("alpine_rush"))
	list.append(get_track("storm_harbor"))
	return list

static func get_track(track_id: String) -> TrackDefinition:
	var norm = track_id.to_lower()
	match norm:
		"sunset_coast", "coast":
			# Track 2: Sunset Coast - Ocean seaside boulevard with sweeping curves & coastal elevation
			var t = TrackDefinition.new(
				"sunset_coast", "Sunset Coast",
				"Sun-drenched coastal highway along cliffs, golden sands, and resort oceanfronts.",
				"coast", 820.0, 3, "Medium",
				[
					Vector3(0, 0, 0),
					Vector3(0, 0, -50),
					Vector3(12, 0.5, -95),
					Vector3(35, 1.8, -135),
					Vector3(75, 3.5, -170),
					Vector3(130, 4.5, -185),
					Vector3(190, 4.0, -170),
					Vector3(235, 2.5, -125),
					Vector3(255, 1.2, -65),
					Vector3(240, 0.5, 0),
					Vector3(200, 0.0, 55),
					Vector3(150, 0.0, 85),
					Vector3(95, 0.0, 95),
					Vector3(50, 0.0, 75),
					Vector3(20, 0.0, 45),
					Vector3(0, 0, 25)
				], 14.5
			)
			t.ambient_color = Color(0.95, 0.75, 0.55)
			t.sky_top_color = Color(0.18, 0.35, 0.72)
			t.sky_horizon_color = Color(0.98, 0.55, 0.25)
			t.fog_color = Color(0.92, 0.60, 0.40)
			t.fog_density = 0.0007
			return t

		"canyon", "redrock_canyon":
			# Track 3: Redrock Canyon - Natural sandstone canyon pass with dramatic rock formations
			var t = TrackDefinition.new(
				"canyon", "Redrock Canyon",
				"High-speed desert canyon pass cut through towering sandstone arches and dusty switchbacks.",
				"canyon", 785.0, 3, "Hard",
				[
					Vector3(0, 0, 0),
					Vector3(0, 0, -45),
					Vector3(10, 0.5, -80),
					Vector3(35, 2.0, -120),
					Vector3(75, 4.5, -150),
					Vector3(125, 7.0, -170),
					Vector3(180, 8.5, -150),
					Vector3(225, 8.0, -100),
					Vector3(240, 7.0, -45),
					Vector3(225, 5.0, 15),
					Vector3(185, 3.5, 65),
					Vector3(145, 2.0, 100),
					Vector3(95, 0.8, 105),
					Vector3(50, 0.0, 80),
					Vector3(20, 0.0, 50),
					Vector3(0, 0, 30)
				], 13.5
			)
			t.ambient_color = Color(0.75, 0.55, 0.40)
			t.sky_top_color = Color(0.20, 0.45, 0.85)
			t.sky_horizon_color = Color(0.85, 0.65, 0.45)
			t.fog_color = Color(0.80, 0.60, 0.45)
			t.fog_density = 0.0014
			return t

		"skyline", "metro_night":
			# Track 4: Metro Night Run - Neon-lit urban high-altitude highway amidst illuminated skyscrapers
			var t = TrackDefinition.new(
				"skyline", "Metro Night Run",
				"Midnight urban expressway threading through neon-lit skyscrapers, tunnels, and elevated plazas.",
				"skyline", 855.0, 3, "Medium",
				[
					Vector3(0, 0, 0),
					Vector3(0, 0, -50),
					Vector3(5, 0.5, -90),
					Vector3(25, 1.5, -130),
					Vector3(60, 4.0, -170),
					Vector3(110, 6.5, -200),
					Vector3(170, 8.0, -200),
					Vector3(220, 6.5, -165),
					Vector3(250, 4.5, -110),
					Vector3(240, 2.0, -50),
					Vector3(210, 0.5, 5),
					Vector3(165, 0.0, 50),
					Vector3(115, 0.0, 80),
					Vector3(60, 0.0, 70),
					Vector3(20, 0.0, 50),
					Vector3(0, 0, 30)
				], 14.0
			)
			t.ambient_color = Color(0.45, 0.40, 0.65)
			t.sky_top_color = Color(0.12, 0.18, 0.42)
			t.sky_horizon_color = Color(0.88, 0.40, 0.28)
			t.fog_color = Color(0.50, 0.30, 0.45)
			t.fog_density = 0.0011
			return t

		"alpine_rush", "alpine":
			# Track 5: Alpine Rush - Mountain pass through pine forests, hairpins, and elevation climbs
			var t = TrackDefinition.new(
				"alpine_rush", "Alpine Rush",
				"Scenic mountain circuit featuring steep climbs, snow peaks, dense pine forests, and tight hairpins.",
				"alpine", 830.0, 3, "Hard",
				[
					Vector3(0, 0, 0),
					Vector3(0, 0, -45),
					Vector3(-15, 1.0, -85),
					Vector3(-10, 3.5, -130),
					Vector3(20, 6.5, -165),
					Vector3(70, 9.0, -180),
					Vector3(135, 10.5, -170),
					Vector3(185, 9.0, -130),
					Vector3(215, 6.5, -80),
					Vector3(205, 4.0, -20),
					Vector3(165, 2.0, 35),
					Vector3(120, 1.0, 75),
					Vector3(75, 0.5, 90),
					Vector3(35, 0.0, 75),
					Vector3(15, 0.0, 45),
					Vector3(0, 0, 25)
				], 13.0
			)
			t.ambient_color = Color(0.60, 0.72, 0.85)
			t.sky_top_color = Color(0.22, 0.45, 0.85)
			t.sky_horizon_color = Color(0.70, 0.82, 0.95)
			t.fog_color = Color(0.75, 0.85, 0.95)
			t.fog_density = 0.0009
			return t

		"storm_harbor", "harbor":
			# Track 6: Storm Harbor - Industrial container shipping dockland with wet reflective asphalt
			var t = TrackDefinition.new(
				"storm_harbor", "Storm Harbor",
				"Industrial shipyard raceway between towering cargo cranes, shipping containers, and storm tides.",
				"harbor", 790.0, 3, "Expert",
				[
					Vector3(0, 0, 0),
					Vector3(0, 0, -45),
					Vector3(-5, 0.0, -85),
					Vector3(15, 0.2, -125),
					Vector3(55, 0.5, -155),
					Vector3(105, 0.8, -175),
					Vector3(160, 0.8, -175),
					Vector3(210, 0.5, -145),
					Vector3(230, 0.0, -90),
					Vector3(215, 0.0, -35),
					Vector3(180, 0.0, 20),
					Vector3(135, 0.0, 55),
					Vector3(85, 0.0, 70),
					Vector3(45, 0.0, 60),
					Vector3(18, 0.0, 48),
					Vector3(0, 0, 30)
				], 14.0
			)
			t.ambient_color = Color(0.40, 0.50, 0.60)
			t.sky_top_color = Color(0.12, 0.16, 0.22)
			t.sky_horizon_color = Color(0.30, 0.38, 0.45)
			t.fog_color = Color(0.28, 0.35, 0.42)
			t.fog_density = 0.0018
			return t

		_: # "speedway" / "metropolis" / "volt_speedway"
			# Track 1: Volt International Speedway - Premier stadium circuit with grandstands & paddock
			var t = TrackDefinition.new(
				"speedway", "Volt International Speedway",
				"World-class stadium super-oval and infield chicane featuring floodlit grandstands and pit complex.",
				"metropolis", 755.0, 3, "Easy",
				[
					Vector3(0, 0, 0),
					Vector3(0, 0, -45),
					Vector3(0, 0, -85),
					Vector3(18, 0, -125),
					Vector3(50, 0.2, -155),
					Vector3(95, 0.5, -175),
					Vector3(150, 0.5, -175),
					Vector3(205, 0.2, -145),
					Vector3(225, 0.0, -90),
					Vector3(215, 0.0, -35),
					Vector3(175, 0.0, 18),
					Vector3(130, 0.0, 48),
					Vector3(85, 0.0, 68),
					Vector3(45, 0.0, 58),
					Vector3(18, 0.0, 48),
					Vector3(0, 0, 30)
				], 14.0
			)
			t.ambient_color = Color(0.55, 0.65, 0.85)
			t.sky_top_color = Color(0.10, 0.16, 0.32)
			t.sky_horizon_color = Color(0.20, 0.32, 0.55)
			t.fog_color = Color(0.15, 0.22, 0.38)
			t.fog_density = 0.0008
			return t
