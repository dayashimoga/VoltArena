class_name TrackRegistry
extends RefCounted

## TrackRegistry provides data-driven track definitions for Drift Storm.
## Supports 6 genuinely unique championship circuits with distinct layouts,
## elevation profiles, environment lighting, and complete circuit dossiers.

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

	# Enhanced Circuit Dossier Properties
	var location: String
	var corners_count: int
	var elevation_change_m: float
	var surface_desc: String
	var weather_desc: String
	var time_of_day: String
	var track_record: String
	var reward_desc: String
	var recommended_vehicle: String

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
		# Defaults for dossier
		location = "Championship Circuit"
		corners_count = p_nodes.size()
		elevation_change_m = 0.0
		surface_desc = "PBR Competition Asphalt & Rumble Kerbs"
		weather_desc = "Clear"
		time_of_day = "Day"
		track_record = "00:45.0"
		reward_desc = "500 XP • 1,000 Credits"
		recommended_vehicle = "Balanced / High Downforce"

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
			# Track 2: Sunset Coast - Coastal cliffside highway with seaside sweepers and ocean overpass
			var t = TrackDefinition.new(
				"sunset_coast", "Sunset Coast",
				"Sun-drenched coastal highway along ocean cliffs, golden sand beaches, and sea overpasses.",
				"coast", 960.0, 3, "Medium",
				[
					Vector3(0, 0, 0),
					Vector3(0, 0, -70),
					Vector3(-25, 2.0, -140),
					Vector3(-60, 4.5, -200),
					Vector3(-65, 6.0, -260),
					Vector3(-30, 7.5, -310),
					Vector3(40, 8.0, -320),
					Vector3(110, 7.0, -290),
					Vector3(160, 5.0, -240),
					Vector3(210, 3.0, -170),
					Vector3(240, 1.5, -90),
					Vector3(230, 0.5, 0),
					Vector3(180, 0.0, 80),
					Vector3(110, 0.0, 120),
					Vector3(40, 0.0, 90),
					Vector3(0, 0, 40)
				], 14.5
			)
			t.ambient_color = Color(0.95, 0.75, 0.55)
			t.sky_top_color = Color(0.18, 0.35, 0.72)
			t.sky_horizon_color = Color(0.98, 0.55, 0.25)
			t.fog_color = Color(0.92, 0.60, 0.40)
			t.fog_density = 0.0007
			t.location = "Pacific Coast Highway, Coral Bay"
			t.corners_count = 11
			t.elevation_change_m = 8.0
			t.surface_desc = "Coastal Marine Asphalt & Blue/White Kerbs"
			t.weather_desc = "Golden Sunset • Ocean Mist"
			t.time_of_day = "Late Sunset (19:45)"
			t.track_record = "00:44.8"
			t.reward_desc = "600 XP • Sunset Coast Gold Trophy"
			t.recommended_vehicle = "High Top Speed & Drift Stability (Phantom GT)"
			return t

		"canyon", "redrock_canyon":
			# Track 3: Redrock Canyon - Rugged desert canyon pass with dramatic mesa climbs and arches
			var t = TrackDefinition.new(
				"canyon", "Redrock Canyon",
				"High-speed desert canyon pass cut through towering sandstone arches, mesa climbs, and dusty switchbacks.",
				"canyon", 850.0, 3, "Hard",
				[
					Vector3(0, 0, 0),
					Vector3(0, 0, -50),
					Vector3(35, 4.0, -100),
					Vector3(20, 9.0, -150),
					Vector3(-25, 15.0, -190),
					Vector3(-60, 20.0, -240),
					Vector3(-45, 25.0, -290),
					Vector3(15, 28.0, -300),
					Vector3(75, 28.0, -270),
					Vector3(110, 22.0, -210),
					Vector3(90, 15.0, -150),
					Vector3(120, 10.0, -90),
					Vector3(160, 5.0, -40),
					Vector3(170, 2.0, 30),
					Vector3(130, 0.5, 90),
					Vector3(60, 0.0, 80),
					Vector3(0, 0, 30)
				], 13.5
			)
			t.ambient_color = Color(0.78, 0.58, 0.42)
			t.sky_top_color = Color(0.20, 0.45, 0.85)
			t.sky_horizon_color = Color(0.85, 0.65, 0.45)
			t.fog_color = Color(0.80, 0.60, 0.45)
			t.fog_density = 0.0014
			t.location = "Mojave Gorge National Park"
			t.corners_count = 16
			t.elevation_change_m = 28.0
			t.surface_desc = "Rough Sandstone Tarmac & Runoff Gravel"
			t.weather_desc = "Arid Sun • Desert Dust Haze"
			t.time_of_day = "High Noon (13:15)"
			t.track_record = "00:41.2"
			t.reward_desc = "750 XP • Canyon Raider Trophy"
			t.recommended_vehicle = "High Ground Clearance & Suspension Travel (Dune Enforcer)"
			return t

		"skyline", "metro_night":
			# Track 4: Metro Night Run - Neon-lit urban high-altitude highway amidst illuminated skyscrapers
			var t = TrackDefinition.new(
				"skyline", "Metro Night Run",
				"Midnight urban expressway threading through neon-lit skyscrapers, 90-degree corners, and elevated flyovers.",
				"skyline", 920.0, 3, "Medium",
				[
					Vector3(0, 0, 0),
					Vector3(0, 0, -60),
					Vector3(0, 0, -120),
					Vector3(40, 0.0, -150),
					Vector3(110, 0.0, -150),
					Vector3(150, 2.5, -180),
					Vector3(150, 6.5, -240),
					Vector3(150, 8.0, -300),
					Vector3(110, 8.0, -330),
					Vector3(40, 8.0, -330),
					Vector3(-20, 7.0, -310),
					Vector3(-60, 3.5, -260),
					Vector3(-70, 0.0, -190),
					Vector3(-60, 0.0, -120),
					Vector3(-60, 0.0, -40),
					Vector3(-40, 0.0, 25),
					Vector3(-15, 0.0, 35)
				], 14.0
			)
			t.ambient_color = Color(0.45, 0.40, 0.65)
			t.sky_top_color = Color(0.12, 0.18, 0.42)
			t.sky_horizon_color = Color(0.88, 0.40, 0.28)
			t.fog_color = Color(0.50, 0.30, 0.45)
			t.fog_density = 0.0011
			t.location = "Neo-Metropolis Financial Core"
			t.corners_count = 15
			t.elevation_change_m = 8.0
			t.surface_desc = "Wet Urban Street Asphalt & Neon Curbs"
			t.weather_desc = "Overcast Night • Neon Glow"
			t.time_of_day = "Midnight (00:30)"
			t.track_record = "00:43.1"
			t.reward_desc = "700 XP • Cyber City Cup"
			t.recommended_vehicle = "Instant Acceleration & Low Center of Gravity (Hyper EV)"
			return t

		"alpine_rush", "alpine":
			# Track 5: Alpine Rush - Mountain pass through snow peaks, hairpins, and elevation climbs
			var t = TrackDefinition.new(
				"alpine_rush", "Alpine Rush",
				"Scenic mountain circuit featuring steep climbs, snow peaks, dense pine forests, and tight hairpins.",
				"alpine", 940.0, 3, "Hard",
				[
					Vector3(0, 0, 0),
					Vector3(0, 0, -50),
					Vector3(-40, 4.0, -95),
					Vector3(-70, 9.0, -145),
					Vector3(-45, 15.0, -190),
					Vector3(-80, 21.0, -235),
					Vector3(-55, 27.0, -280),
					Vector3(0, 32.0, -310),
					Vector3(65, 34.0, -300),
					Vector3(125, 30.0, -260),
					Vector3(165, 22.0, -195),
					Vector3(180, 15.0, -125),
					Vector3(160, 8.0, -55),
					Vector3(175, 4.0, 20),
					Vector3(145, 1.5, 75),
					Vector3(85, 0.5, 95),
					Vector3(30, 0.0, 65),
					Vector3(0, 0, 25)
				], 12.5
			)
			t.ambient_color = Color(0.60, 0.72, 0.85)
			t.sky_top_color = Color(0.22, 0.45, 0.85)
			t.sky_horizon_color = Color(0.70, 0.82, 0.95)
			t.fog_color = Color(0.75, 0.85, 0.95)
			t.fog_density = 0.0009
			t.location = "Matterhorn Alpine Pass"
			t.corners_count = 18
			t.elevation_change_m = 34.0
			t.surface_desc = "Mountain Asphalt & Wooden Timber Barriers"
			t.weather_desc = "Cold Mountain Mist • Snow Drifts"
			t.time_of_day = "Morning Fog (08:15)"
			t.track_record = "00:46.5"
			t.reward_desc = "800 XP • Alpine Crown Trophy"
			t.recommended_vehicle = "Precision Handling & Downforce (Formula Apex)"
			return t

		"storm_harbor", "harbor":
			# Track 6: Storm Harbor - Industrial container shipping dockland with wet reflective asphalt
			var t = TrackDefinition.new(
				"storm_harbor", "Storm Harbor",
				"Industrial shipyard raceway between towering cargo cranes, shipping containers, and storm tides.",
				"harbor", 860.0, 3, "Expert",
				[
					Vector3(0, 0, 0),
					Vector3(0, 0, -70),
					Vector3(0, 0, -140),
					Vector3(35, 0.2, -185),
					Vector3(95, 0.2, -185),
					Vector3(135, 0.4, -220),
					Vector3(190, 0.4, -220),
					Vector3(230, 0.2, -180),
					Vector3(230, 0.2, -120),
					Vector3(190, 0.0, -70),
					Vector3(190, 0.0, 0),
					Vector3(220, 0.0, 60),
					Vector3(200, 0.0, 110),
					Vector3(140, 0.0, 120),
					Vector3(85, 0.0, 95),
					Vector3(40, 0.0, 55),
					Vector3(0, 0, 30)
				], 15.0
			)
			t.ambient_color = Color(0.40, 0.50, 0.60)
			t.sky_top_color = Color(0.12, 0.16, 0.22)
			t.sky_horizon_color = Color(0.30, 0.38, 0.45)
			t.fog_color = Color(0.28, 0.35, 0.42)
			t.fog_density = 0.0018
			t.location = "Rotterdam Container Terminal"
			t.corners_count = 12
			t.elevation_change_m = 1.2
			t.surface_desc = "Wet Dockland Asphalt with Puddles"
			t.weather_desc = "Gale Rain • Distant Lightning"
			t.time_of_day = "Storm Dusk (18:00)"
			t.track_record = "00:40.9"
			t.reward_desc = "900 XP • Harbor Master Cup"
			t.recommended_vehicle = "Traction & Agile Turn-in (Speeder / Formula)"
			return t

		_: # "speedway" / "metropolis" / "volt_speedway"
			# Track 1: Volt International Speedway - Premier stadium circuit with grandstands & paddock
			var t = TrackDefinition.new(
				"speedway", "Volt International Speedway",
				"World-class stadium super-oval and infield technical complex featuring floodlit grandstands and pit buildings.",
				"metropolis", 880.0, 3, "Easy",
				[
					Vector3(0, 0, 0),
					Vector3(0, 0, -60),
					Vector3(0, 0, -120),
					Vector3(30, 0.4, -180),
					Vector3(85, 0.8, -210),
					Vector3(150, 0.8, -210),
					Vector3(190, 0.4, -170),
					Vector3(175, 0.0, -120),
					Vector3(135, 0.0, -90),
					Vector3(110, 0.0, -50),
					Vector3(130, 0.0, 0),
					Vector3(160, 0.2, 50),
					Vector3(140, 0.4, 95),
					Vector3(80, 0.4, 110),
					Vector3(25, 0.0, 80),
					Vector3(0, 0, 35)
				], 16.0
			)
			t.ambient_color = Color(0.55, 0.65, 0.85)
			t.sky_top_color = Color(0.10, 0.16, 0.32)
			t.sky_horizon_color = Color(0.20, 0.32, 0.55)
			t.fog_color = Color(0.15, 0.22, 0.38)
			t.fog_density = 0.0008
			t.location = "Volt Metropolis Sports Complex"
			t.corners_count = 14
			t.elevation_change_m = 1.5
			t.surface_desc = "Competition Asphalt & Red/White Kerbs"
			t.weather_desc = "Clear Floodlit Night"
			t.time_of_day = "Night (21:00)"
			t.track_record = "00:39.4"
			t.reward_desc = "500 XP • Volt Speedway Trophy"
			t.recommended_vehicle = "All-Round Competition Balance (Speeder Pro Kart)"
			return t
