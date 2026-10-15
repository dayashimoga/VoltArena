class_name UrbanDistrictDefinitions
extends RefCounted

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")

## Comprehensive district specifications for Urban Legends open world (2000m x 2000m).
## Defines 8 distinct geographic and architectural zones:
## 1. Downtown Metro: High-rise commercial core with wide multi-lane boulevards.
## 2. Colinas Heights: Steep winding suburban hills (Las Colinas reference), crest jumps.
## 3. Verdant Glen: Parkland, palm trees, ponds, grassy drift shortcuts (Glen Park reference).
## 4. Harborfly Freeway: Multi-lane concrete elevated flyover viaducts (+18m elevation).
## 5. Bayview Promenade: Coastal seaside boulevard, beaches, ocean horizon.
## 6. Industrial Apex: Rail freight depots, shipping container stacks, gantry cranes.
## 7. Ridgecrest Hills: Extreme incline gravel switchbacks and communication ridges.
## 8. Skyline Airport: Perimeter service roads and twin 800m high-speed runways.

static var _DISTRICTS: Dictionary = {}

static func _ensure_initialized() -> void:
	if not _DISTRICTS.is_empty():
		return

	_DISTRICTS = {
		UrbanConstants.DISTRICT_DOWNTOWN: {
			"id": UrbanConstants.DISTRICT_DOWNTOWN,
			"name": "Downtown Metro",
			"tagline": "Corporate Skyscraper Core",
			"bounds": Rect2(-600, -600, 800, 800), # Center-North
			"elevation_min": 0.0,
			"elevation_max": 8.0,
			"speed_limit_kmh": 80.0,
			"ambient_color": Color(0.18, 0.22, 0.35),
			"sky_color_mod": Color(1.0, 1.0, 1.05),
			"ground_friction": 1.0,
			"stunt_density": "Medium",
			"description": "Dense urban canyon of high-rise towers, neon storefronts, plaza fountains, and wide asphalt grids.",
			"spawn_offsets": [
				Vector3(-200, 1.0, -200), Vector3(-100, 1.0, -350), Vector3(0, 1.0, -100),
				Vector3(120, 1.0, -280), Vector3(-450, 1.0, -150), Vector3(-300, 1.0, 50),
				Vector3(-80, 1.0, 120), Vector3(50, 1.0, 80), Vector3(-250, 1.0, -480),
				Vector3(80, 1.0, -520), Vector3(-520, 1.0, -380), Vector3(-380, 1.0, -50),
				Vector3(-150, 1.0, 180), Vector3(150, 1.0, 150)
			]
		},
		UrbanConstants.DISTRICT_COLINAS: {
			"id": UrbanConstants.DISTRICT_COLINAS,
			"name": "Colinas Heights",
			"tagline": "Scenic Hillside Switchbacks & Crest Jumps",
			"bounds": Rect2(200, 200, 600, 700), # North-East
			"elevation_min": 15.0,
			"elevation_max": 95.0,
			"speed_limit_kmh": 65.0,
			"ambient_color": Color(0.35, 0.28, 0.20),
			"sky_color_mod": Color(1.05, 0.98, 0.92),
			"ground_friction": 0.95,
			"stunt_density": "Very High",
			"description": "Steep hillside residential roads inspired by Las Colinas, hairpin turns, tile-roofed villas, and crest launch ramps.",
			"crest_jump_pos": Vector3(450.0, 52.0, 620.0),
			"spawn_offsets": [
				Vector3(260, 22.0, 280), Vector3(320, 32.0, 360), Vector3(400, 44.0, 450),
				Vector3(450, 52.0, 580), Vector3(520, 68.0, 650), Vector3(600, 82.0, 720),
				Vector3(680, 92.0, 800), Vector3(350, 36.0, 260), Vector3(480, 58.0, 380),
				Vector3(560, 72.0, 480), Vector3(640, 86.0, 560), Vector3(720, 94.0, 680),
				Vector3(280, 25.0, 520), Vector3(380, 40.0, 720)
			]
		},
		UrbanConstants.DISTRICT_VERDANT: {
			"id": UrbanConstants.DISTRICT_VERDANT,
			"name": "Verdant Glen",
			"tagline": "Lush Parkland & Grassland Drift Haven",
			"bounds": Rect2(200, -500, 600, 600), # Center-East
			"elevation_min": 4.0,
			"elevation_max": 24.0,
			"speed_limit_kmh": 70.0,
			"ambient_color": Color(0.18, 0.32, 0.16),
			"sky_color_mod": Color(0.96, 1.05, 0.96),
			"ground_friction": 0.72, # Grass friction enables long power slides
			"stunt_density": "High",
			"description": "Lush metropolitan parkland inspired by Glen Park with curving concrete paths, stone bridges, palm groves, and rolling grass berms.",
			"spawn_offsets": [
				Vector3(240, 6.0, -450), Vector3(320, 8.0, -380), Vector3(420, 12.0, -280),
				Vector3(500, 16.0, -180), Vector3(580, 20.0, -80), Vector3(660, 22.0, 20),
				Vector3(300, 7.0, -220), Vector3(380, 10.0, -120), Vector3(460, 14.0, -20),
				Vector3(540, 18.0, 60), Vector3(620, 21.0, -320), Vector3(700, 23.0, -200),
				Vector3(260, 6.0, -80), Vector3(400, 11.0, 40)
			]
		},
		UrbanConstants.DISTRICT_HARBORFLY: {
			"id": UrbanConstants.DISTRICT_HARBORFLY,
			"name": "Harborfly Freeway",
			"tagline": "High-Speed Elevated Viaduct Interchanges",
			"bounds": Rect2(-1000, -100, 2000, 250), # Transverse East-West Corridor
			"elevation_min": 0.0,
			"elevation_max": 22.0, # Elevated flyover level
			"speed_limit_kmh": 140.0,
			"ambient_color": Color(0.22, 0.22, 0.26),
			"sky_color_mod": Color(1.0, 1.0, 1.0),
			"ground_friction": 1.0,
			"stunt_density": "High",
			"description": "Multi-tier high-speed highway arterial featuring concrete flyover viaducts, cloverleaf interchanges, and launch drops.",
			"spawn_offsets": [
				Vector3(-850, 18.0, 20), Vector3(-650, 18.0, 20), Vector3(-450, 18.0, 20),
				Vector3(-250, 18.0, 20), Vector3(-50, 18.0, 20), Vector3(150, 18.0, 20),
				Vector3(350, 18.0, 20), Vector3(550, 18.0, 20), Vector3(750, 18.0, 20),
				Vector3(-750, 1.0, -50), Vector3(-350, 1.0, -50), Vector3(50, 1.0, -50),
				Vector3(450, 1.0, -50), Vector3(850, 1.0, -50)
			]
		},
		UrbanConstants.DISTRICT_BAYVIEW: {
			"id": UrbanConstants.DISTRICT_BAYVIEW,
			"name": "Bayview Promenade",
			"tagline": "Sun-Drenched Coastal Seaside Esplanade",
			"bounds": Rect2(-1000, -1000, 2000, 400), # South Coastline
			"elevation_min": 0.0,
			"elevation_max": 5.0,
			"speed_limit_kmh": 90.0,
			"ambient_color": Color(0.15, 0.26, 0.38),
			"sky_color_mod": Color(1.08, 1.02, 0.95),
			"ground_friction": 0.88, # Sand and coastal asphalt
			"stunt_density": "Medium",
			"description": "Palm-lined seaside boulevard fronting golden beaches, dunes, yacht piers, and sweeping ocean horizons.",
			"spawn_offsets": [
				Vector3(-800, 1.0, -850), Vector3(-600, 1.0, -850), Vector3(-400, 1.0, -850),
				Vector3(-200, 1.0, -850), Vector3(0, 1.0, -850), Vector3(200, 1.0, -850),
				Vector3(400, 1.0, -850), Vector3(600, 1.0, -850), Vector3(800, 1.0, -850),
				Vector3(-500, 1.0, -720), Vector3(-100, 1.0, -720), Vector3(300, 1.0, -720),
				Vector3(700, 1.0, -720), Vector3(-300, 1.0, -920)
			]
		},
		UrbanConstants.DISTRICT_INDUSTRIAL: {
			"id": UrbanConstants.DISTRICT_INDUSTRIAL,
			"name": "Industrial Apex",
			"tagline": "Freight Depot & Container Mazes",
			"bounds": Rect2(-1000, 300, 700, 700), # North-West
			"elevation_min": 0.0,
			"elevation_max": 6.0,
			"speed_limit_kmh": 75.0,
			"ambient_color": Color(0.28, 0.25, 0.22),
			"sky_color_mod": Color(0.98, 0.98, 0.94),
			"ground_friction": 0.94,
			"stunt_density": "High",
			"description": "Heavy industrial zone packed with shipping container stacks, gantry cranes, rail switchyards, and narrow warehouse alleys.",
			"spawn_offsets": [
				Vector3(-920, 1.0, 380), Vector3(-820, 1.0, 460), Vector3(-720, 1.0, 540),
				Vector3(-620, 1.0, 620), Vector3(-520, 1.0, 700), Vector3(-420, 1.0, 780),
				Vector3(-880, 1.0, 520), Vector3(-780, 1.0, 600), Vector3(-680, 1.0, 680),
				Vector3(-580, 1.0, 760), Vector3(-840, 1.0, 360), Vector3(-640, 1.0, 420),
				Vector3(-460, 1.0, 520), Vector3(-740, 1.0, 780)
			]
		},
		UrbanConstants.DISTRICT_RIDGECREST: {
			"id": UrbanConstants.DISTRICT_RIDGECREST,
			"name": "Ridgecrest Hills",
			"tagline": "Alpine Mountain Ridges & Switchbacks",
			"bounds": Rect2(-300, 700, 700, 300), # Far North Ridge
			"elevation_min": 40.0,
			"elevation_max": 160.0,
			"speed_limit_kmh": 60.0,
			"ambient_color": Color(0.24, 0.26, 0.28),
			"sky_color_mod": Color(0.95, 0.98, 1.05),
			"ground_friction": 0.82, # Gravel mountain switchbacks
			"stunt_density": "Extreme",
			"description": "Towering mountain ridge, extreme 25-degree gravel inclines, radio antenna towers, and vertigo-inducing cliff jumps.",
			"spawn_offsets": [
				Vector3(-220, 48.0, 740), Vector3(-120, 64.0, 780), Vector3(-20, 82.0, 820),
				Vector3(80, 102.0, 860), Vector3(180, 124.0, 900), Vector3(280, 142.0, 940),
				Vector3(360, 155.0, 960), Vector3(-160, 56.0, 840), Vector3(-60, 74.0, 880),
				Vector3(40, 94.0, 920), Vector3(140, 116.0, 950), Vector3(240, 136.0, 880),
				Vector3(320, 148.0, 820), Vector3(0, 88.0, 760)
			]
		},
		UrbanConstants.DISTRICT_AIRPORT: {
			"id": UrbanConstants.DISTRICT_AIRPORT,
			"name": "Skyline Airport",
			"tagline": "Twin High-Speed Runways & Drag Strips",
			"bounds": Rect2(-1000, -600, 400, 500), # West Aerodrome
			"elevation_min": 1.0,
			"elevation_max": 4.0,
			"speed_limit_kmh": 220.0,
			"ambient_color": Color(0.20, 0.24, 0.30),
			"sky_color_mod": Color(1.0, 1.0, 1.02),
			"ground_friction": 1.02, # High-grip aerodrome tarmac
			"stunt_density": "High",
			"description": "Dual 800m parallel asphalt runways, passenger terminal, hangar aprons, and flat-out top speed acceleration testing.",
			"spawn_offsets": [
				Vector3(-950, 1.0, -520), Vector3(-850, 1.0, -520), Vector3(-750, 1.0, -520),
				Vector3(-650, 1.0, -520), Vector3(-950, 1.0, -320), Vector3(-850, 1.0, -320),
				Vector3(-750, 1.0, -320), Vector3(-650, 1.0, -320), Vector3(-900, 1.0, -420),
				Vector3(-800, 1.0, -420), Vector3(-700, 1.0, -420), Vector3(-600, 1.0, -420),
				Vector3(-960, 1.0, -220), Vector3(-680, 1.0, -220)
			]
		}
	}

static func get_district_ids() -> Array[String]:
	_ensure_initialized()
	var ids: Array[String] = []
	for k in _DISTRICTS.keys():
		ids.append(k)
	return ids

static func get_district_def(district_id: String) -> Dictionary:
	_ensure_initialized()
	var def = _DISTRICTS.get(district_id, {}).duplicate()
	if not def.is_empty():
		var offsets: Array = def.get("spawn_offsets", [])
		if not offsets.is_empty():
			def["spawn_point"] = offsets[0]
	return def

static func get_district(district_id: String) -> Dictionary:
	return get_district_def(district_id)

static func get_district_at_position(world_pos: Vector3) -> String:
	_ensure_initialized()
	var pt = Vector2(world_pos.x, world_pos.z)

	# Elevated Harborfly Freeway viaducts take precedence when elevation >= 10.0
	if world_pos.y >= 10.0:
		var h_def = _DISTRICTS.get(UrbanConstants.DISTRICT_HARBORFLY, {})
		var h_b: Rect2 = h_def.get("bounds", Rect2())
		if h_b.has_point(pt):
			return UrbanConstants.DISTRICT_HARBORFLY

	for d_id in _DISTRICTS.keys():
		if d_id == UrbanConstants.DISTRICT_HARBORFLY and world_pos.y < 10.0:
			continue
		var def = _DISTRICTS[d_id]
		var b: Rect2 = def.get("bounds", Rect2())
		if b.has_point(pt):
			return d_id
	return UrbanConstants.DISTRICT_DOWNTOWN

static func get_district_spawn_points(district_id: String) -> Array[Transform3D]:
	_ensure_initialized()
	var def = get_district_def(district_id)
	var offsets: Array = def.get("spawn_offsets", [])
	var list: Array[Transform3D] = []
	for off in offsets:
		var t = Transform3D()
		t.origin = off
		list.append(t)
	return list

static func get_all_spawn_points() -> Array[Transform3D]:
	_ensure_initialized()
	var all_spawns: Array[Transform3D] = []
	for d_id in get_district_ids():
		all_spawns.append_array(get_district_spawn_points(d_id))
	return all_spawns
