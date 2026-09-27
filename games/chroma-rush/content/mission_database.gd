class_name MissionDatabase
extends RefCounted

## Handcrafted mission definitions, data-driven schemas, and solvability validators
## Contains 24 distinct handcrafted missions distributed across all 4 modes and 4 worlds.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")

static func get_all_missions() -> Array[Dictionary]:
	return [
		# ==========================================
		# COLOR HUNT MISSIONS (1 - 6)
		# ==========================================
		{
			"id": "hunt_neon_01",
			"title": "Neon Awakening",
			"mode": ChromaConstants.GameMode.COLOR_HUNT,
			"world_id": ChromaConstants.WORLD_NEON_CITY,
			"description": "Locate an Emerald Green vehicle in the downtown corridor, execute a swap, and deliver it to Gate 4.",
			"starting_color": ChromaConstants.ChromaColor.CRIMSON,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.EMERALD, "gate_id": "gate_4", "points": 1000}
			],
			"time_limit": 90.0,
			"swap_limit": 0,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.EMERALD, ChromaConstants.ChromaColor.COBALT, ChromaConstants.ChromaColor.SOLAR],
			"credit_reward": 500,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Find Emerald in traffic", "Swap Crimson <-> Emerald", "Drive to Gate 4"]}
		},
		{
			"id": "hunt_neon_02",
			"title": "Dual Pulse Transit",
			"mode": ChromaConstants.GameMode.COLOR_HUNT,
			"world_id": ChromaConstants.WORLD_NEON_CITY,
			"description": "Chain two consecutive color exchanges: first deliver Cobalt to Gate 2, then locate Solar and deliver to Gate 3.",
			"starting_color": ChromaConstants.ChromaColor.CRIMSON,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.COBALT, "gate_id": "gate_2", "points": 1200},
				{"target_color": ChromaConstants.ChromaColor.SOLAR, "gate_id": "gate_3", "points": 1500}
			],
			"time_limit": 120.0,
			"swap_limit": 0,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.COBALT, ChromaConstants.ChromaColor.SOLAR, ChromaConstants.ChromaColor.MAGENTA],
			"credit_reward": 750,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Swap Crimson <-> Cobalt", "Gate 2", "Swap Cobalt <-> Solar", "Gate 3"]}
		},
		{
			"id": "hunt_coastal_03",
			"title": "Seaside Spectrum",
			"mode": ChromaConstants.GameMode.COLOR_HUNT,
			"world_id": ChromaConstants.WORLD_COASTAL_RUSH,
			"description": "Navigate the coastal highway to acquire Cyan from harbor traffic and deliver to Ocean Gate 2.",
			"starting_color": ChromaConstants.ChromaColor.CRIMSON,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.CYAN, "gate_id": "gate_2", "points": 1400}
			],
			"time_limit": 85.0,
			"swap_limit": 0,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.CYAN, ChromaConstants.ChromaColor.EMERALD, ChromaConstants.ChromaColor.COBALT],
			"credit_reward": 600,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Swap Crimson <-> Cyan", "Pass Gate 2"]}
		},
		{
			"id": "hunt_canyon_04",
			"title": "Canyon Sunstone",
			"mode": ChromaConstants.GameMode.COLOR_HUNT,
			"world_id": ChromaConstants.WORLD_PRISM_CANYON,
			"description": "Climb the sandstone switchbacks, retrieve Solar Gold from canyon cruisers, and score at Gate 1.",
			"starting_color": ChromaConstants.ChromaColor.COBALT,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.SOLAR, "gate_id": "gate_1", "points": 1500}
			],
			"time_limit": 95.0,
			"swap_limit": 0,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.SOLAR, ChromaConstants.ChromaColor.CRIMSON, ChromaConstants.ChromaColor.EMERALD],
			"credit_reward": 700,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Climb to Rim", "Swap Cobalt <-> Solar", "Gate 1"]}
		},
		{
			"id": "hunt_sky_05",
			"title": "Stratosphere Circuit",
			"mode": ChromaConstants.GameMode.COLOR_HUNT,
			"world_id": ChromaConstants.WORLD_SKY_CIRCUIT,
			"description": "High-altitude pursuit: obtain Magenta on Tier 3 and deliver through the corkscrew to Gate 2.",
			"starting_color": ChromaConstants.ChromaColor.CYAN,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.MAGENTA, "gate_id": "gate_2", "points": 1800}
			],
			"time_limit": 80.0,
			"swap_limit": 0,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.MAGENTA, ChromaConstants.ChromaColor.EMERALD, ChromaConstants.ChromaColor.SOLAR],
			"credit_reward": 900,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Ascend to Tier 3", "Swap Cyan <-> Magenta", "Gate 2"]}
		},
		{
			"id": "hunt_neon_06",
			"title": "Triple Prism Dash",
			"mode": ChromaConstants.GameMode.COLOR_HUNT,
			"world_id": ChromaConstants.WORLD_NEON_CITY,
			"description": "Master 3 sequential color exchanges in a single run: Crimson -> Cobalt -> Magenta through city checkpoints.",
			"starting_color": ChromaConstants.ChromaColor.SOLAR,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.CRIMSON, "gate_id": "gate_1", "points": 1200},
				{"target_color": ChromaConstants.ChromaColor.COBALT, "gate_id": "gate_2", "points": 1400},
				{"target_color": ChromaConstants.ChromaColor.MAGENTA, "gate_id": "gate_5", "points": 1800}
			],
			"time_limit": 140.0,
			"swap_limit": 0,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.CRIMSON, ChromaConstants.ChromaColor.COBALT, ChromaConstants.ChromaColor.MAGENTA],
			"credit_reward": 1200,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Swap Solar <-> Crimson", "Gate 1", "Swap Crimson <-> Cobalt", "Gate 2", "Swap Cobalt <-> Magenta", "Gate 5"]}
		},

		# ==========================================
		# CHROMA SPRINT MISSIONS (7 - 12)
		# ==========================================
		{
			"id": "sprint_neon_07",
			"title": "Downtown Rush Hour",
			"mode": ChromaConstants.GameMode.CHROMA_SPRINT,
			"world_id": ChromaConstants.WORLD_NEON_CITY,
			"description": "Deliver as many matching colors as possible in 60s. Each delivery adds +15s bonus time.",
			"starting_color": ChromaConstants.ChromaColor.CYAN,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.COBALT, "gate_id": "gate_2", "points": 800},
				{"target_color": ChromaConstants.ChromaColor.SOLAR, "gate_id": "gate_3", "points": 800},
				{"target_color": ChromaConstants.ChromaColor.EMERALD, "gate_id": "gate_4", "points": 800}
			],
			"time_limit": 60.0,
			"swap_limit": 0,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.COBALT, ChromaConstants.ChromaColor.SOLAR, ChromaConstants.ChromaColor.EMERALD, ChromaConstants.ChromaColor.CRIMSON],
			"credit_reward": 800,
			"medal_tier": "silver",
			"solvability_proof": {"steps": ["Sprint loop with +15s increments"]}
		},
		{
			"id": "sprint_coastal_08",
			"title": "Oceanic Velocity",
			"mode": ChromaConstants.GameMode.CHROMA_SPRINT,
			"world_id": ChromaConstants.WORLD_COASTAL_RUSH,
			"description": "Sprint across the suspension bridge chaining Cyan and Emerald deliveries against a strict clock.",
			"starting_color": ChromaConstants.ChromaColor.CRIMSON,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.CYAN, "gate_id": "gate_2", "points": 900},
				{"target_color": ChromaConstants.ChromaColor.EMERALD, "gate_id": "gate_5", "points": 900}
			],
			"time_limit": 55.0,
			"swap_limit": 0,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.CYAN, ChromaConstants.ChromaColor.EMERALD, ChromaConstants.ChromaColor.COBALT],
			"credit_reward": 850,
			"medal_tier": "silver",
			"solvability_proof": {"steps": ["Bridge sprint sequence"]}
		},
		{
			"id": "sprint_canyon_09",
			"title": "Gorge Overdrive",
			"mode": ChromaConstants.GameMode.CHROMA_SPRINT,
			"world_id": ChromaConstants.WORLD_PRISM_CANYON,
			"description": "Race the canyon rim chaining Solar and Crimson objectives under high-velocity drift conditions.",
			"starting_color": ChromaConstants.ChromaColor.COBALT,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.SOLAR, "gate_id": "gate_1", "points": 1000},
				{"target_color": ChromaConstants.ChromaColor.CRIMSON, "gate_id": "gate_2", "points": 1000}
			],
			"time_limit": 50.0,
			"swap_limit": 0,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.SOLAR, ChromaConstants.ChromaColor.CRIMSON, ChromaConstants.ChromaColor.MAGENTA],
			"credit_reward": 950,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Canyon rim sprint"]}
		},
		{
			"id": "sprint_sky_10",
			"title": "Cloudburst Blitz",
			"mode": ChromaConstants.GameMode.CHROMA_SPRINT,
			"world_id": ChromaConstants.WORLD_SKY_CIRCUIT,
			"description": "Chain 4 high-altitude color trades across Sky Circuit's multi-level highway.",
			"starting_color": ChromaConstants.ChromaColor.SOLAR,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.CYAN, "gate_id": "gate_1", "points": 1100},
				{"target_color": ChromaConstants.ChromaColor.MAGENTA, "gate_id": "gate_2", "points": 1100}
			],
			"time_limit": 55.0,
			"swap_limit": 0,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.CYAN, ChromaConstants.ChromaColor.MAGENTA, ChromaConstants.ChromaColor.EMERALD],
			"credit_reward": 1100,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Skyway sprint"]}
		},
		{
			"id": "sprint_neon_11",
			"title": "Neon Hyperdrive",
			"mode": ChromaConstants.GameMode.CHROMA_SPRINT,
			"world_id": ChromaConstants.WORLD_NEON_CITY,
			"description": "Rapid urban sprint through underpass tunnels with 4 target color checkpoints.",
			"starting_color": ChromaConstants.ChromaColor.EMERALD,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.MAGENTA, "gate_id": "gate_5", "points": 1200},
				{"target_color": ChromaConstants.ChromaColor.CYAN, "gate_id": "gate_6", "points": 1200}
			],
			"time_limit": 65.0,
			"swap_limit": 0,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.MAGENTA, ChromaConstants.ChromaColor.CYAN, ChromaConstants.ChromaColor.SOLAR],
			"credit_reward": 1300,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Underpass sprint sequence"]}
		},
		{
			"id": "sprint_coastal_12",
			"title": "Tide Runner",
			"mode": ChromaConstants.GameMode.CHROMA_SPRINT,
			"world_id": ChromaConstants.WORLD_COASTAL_RUSH,
			"description": "High-octane coastal time-attack testing speed preservation around seaside hairpins.",
			"starting_color": ChromaConstants.ChromaColor.SOLAR,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.CRIMSON, "gate_id": "gate_4", "points": 1300},
				{"target_color": ChromaConstants.ChromaColor.MAGENTA, "gate_id": "gate_6", "points": 1300}
			],
			"time_limit": 60.0,
			"swap_limit": 0,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.CRIMSON, ChromaConstants.ChromaColor.MAGENTA, ChromaConstants.ChromaColor.COBALT],
			"credit_reward": 1400,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Coastline sprint"]}
		},

		# ==========================================
		# PUZZLE DRIVE MISSIONS (13 - 18)
		# ==========================================
		{
			"id": "puzzle_neon_13",
			"title": "Minimalist Route",
			"mode": ChromaConstants.GameMode.PUZZLE_DRIVE,
			"world_id": ChromaConstants.WORLD_NEON_CITY,
			"description": "Deliver Solar to Gate 3 using exactly 1 color swap. Any extra swap fails the mission.",
			"starting_color": ChromaConstants.ChromaColor.CRIMSON,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.SOLAR, "gate_id": "gate_3", "points": 2000}
			],
			"time_limit": 90.0,
			"swap_limit": 1,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.SOLAR, ChromaConstants.ChromaColor.COBALT],
			"credit_reward": 1500,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Single swap Crimson <-> Solar", "Deliver to Gate 3 within 1 swap"]}
		},
		{
			"id": "puzzle_coastal_14",
			"title": "The Bridge Parity",
			"mode": ChromaConstants.GameMode.PUZZLE_DRIVE,
			"world_id": ChromaConstants.WORLD_COASTAL_RUSH,
			"description": "Deliver Emerald to Gate 5 using at most 2 swaps in a tightly constrained traffic layout.",
			"starting_color": ChromaConstants.ChromaColor.CRIMSON,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.EMERALD, "gate_id": "gate_5", "points": 2200}
			],
			"time_limit": 100.0,
			"swap_limit": 2,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.COBALT, ChromaConstants.ChromaColor.EMERALD],
			"credit_reward": 1600,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Swap 1: Crimson <-> Cobalt", "Swap 2: Cobalt <-> Emerald", "Gate 5"]}
		},
		{
			"id": "puzzle_canyon_15",
			"title": "Sandstone Equation",
			"mode": ChromaConstants.GameMode.PUZZLE_DRIVE,
			"world_id": ChromaConstants.WORLD_PRISM_CANYON,
			"description": "Reach Gate 4 with Emerald using max 2 swaps while ascending canyon elevation.",
			"starting_color": ChromaConstants.ChromaColor.SOLAR,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.EMERALD, "gate_id": "gate_4", "points": 2400}
			],
			"time_limit": 95.0,
			"swap_limit": 2,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.CRIMSON, ChromaConstants.ChromaColor.EMERALD],
			"credit_reward": 1700,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Swap 1: Solar <-> Crimson", "Swap 2: Crimson <-> Emerald", "Gate 4"]}
		},
		{
			"id": "puzzle_sky_16",
			"title": "Quantum Permutation",
			"mode": ChromaConstants.GameMode.PUZZLE_DRIVE,
			"world_id": ChromaConstants.WORLD_SKY_CIRCUIT,
			"description": "Solve a 3-swap sequence in the clouds: Cyan -> Magenta -> Cobalt -> Crimson at Gate 6.",
			"starting_color": ChromaConstants.ChromaColor.CYAN,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.CRIMSON, "gate_id": "gate_6", "points": 2800}
			],
			"time_limit": 110.0,
			"swap_limit": 3,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.MAGENTA, ChromaConstants.ChromaColor.COBALT, ChromaConstants.ChromaColor.CRIMSON],
			"credit_reward": 2000,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Swap 1: Cyan <-> Magenta", "Swap 2: Magenta <-> Cobalt", "Swap 3: Cobalt <-> Crimson", "Gate 6"]}
		},
		{
			"id": "puzzle_neon_17",
			"title": "Strict Exchange",
			"mode": ChromaConstants.GameMode.PUZZLE_DRIVE,
			"world_id": ChromaConstants.WORLD_NEON_CITY,
			"description": "Deliver Magenta to Gate 5 with at most 1 swap. Locate the single vehicle carrying it.",
			"starting_color": ChromaConstants.ChromaColor.CYAN,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.MAGENTA, "gate_id": "gate_5", "points": 2500}
			],
			"time_limit": 80.0,
			"swap_limit": 1,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.MAGENTA, ChromaConstants.ChromaColor.SOLAR],
			"credit_reward": 1800,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Swap 1: Cyan <-> Magenta", "Gate 5"]}
		},
		{
			"id": "puzzle_canyon_18",
			"title": "Prismatic Cascade",
			"mode": ChromaConstants.GameMode.PUZZLE_DRIVE,
			"world_id": ChromaConstants.WORLD_PRISM_CANYON,
			"description": "Deliver Cyan to Gate 5 using at most 2 swaps in the winding sandstone chasm.",
			"starting_color": ChromaConstants.ChromaColor.SOLAR,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.CYAN, "gate_id": "gate_5", "points": 2600}
			],
			"time_limit": 100.0,
			"swap_limit": 2,
			"rival_count": 0,
			"traffic_colors": [ChromaConstants.ChromaColor.EMERALD, ChromaConstants.ChromaColor.CYAN],
			"credit_reward": 1900,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Swap 1: Solar <-> Emerald", "Swap 2: Emerald <-> Cyan", "Gate 5"]}
		},

		# ==========================================
		# CHROMA CHAMPIONSHIP MISSIONS (19 - 24)
		# ==========================================
		{
			"id": "champ_neon_19",
			"title": "Neon Grand Prix Stage 1",
			"mode": ChromaConstants.GameMode.CHAMPIONSHIP,
			"world_id": ChromaConstants.WORLD_NEON_CITY,
			"description": "Race against 2 competitive AI rivals. Deliver 2 color checkpoints before the rivals finish.",
			"starting_color": ChromaConstants.ChromaColor.CRIMSON,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.COBALT, "gate_id": "gate_2", "points": 1500},
				{"target_color": ChromaConstants.ChromaColor.SOLAR, "gate_id": "gate_3", "points": 1800}
			],
			"time_limit": 150.0,
			"swap_limit": 0,
			"rival_count": 2,
			"traffic_colors": [ChromaConstants.ChromaColor.COBALT, ChromaConstants.ChromaColor.SOLAR, ChromaConstants.ChromaColor.EMERALD, ChromaConstants.ChromaColor.CYAN],
			"credit_reward": 2500,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Swap to Cobalt", "Gate 2", "Swap to Solar", "Gate 3", "Outpace 2 rivals"]}
		},
		{
			"id": "champ_coastal_20",
			"title": "Coastal Cup Stage 2",
			"mode": ChromaConstants.GameMode.CHAMPIONSHIP,
			"world_id": ChromaConstants.WORLD_COASTAL_RUSH,
			"description": "Contend with 3 AI rivals on the ocean highway. Outmaneuver them for Cyan and Emerald deliveries.",
			"starting_color": ChromaConstants.ChromaColor.SOLAR,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.CYAN, "gate_id": "gate_2", "points": 1600},
				{"target_color": ChromaConstants.ChromaColor.EMERALD, "gate_id": "gate_5", "points": 2000}
			],
			"time_limit": 160.0,
			"swap_limit": 0,
			"rival_count": 3,
			"traffic_colors": [ChromaConstants.ChromaColor.CYAN, ChromaConstants.ChromaColor.EMERALD, ChromaConstants.ChromaColor.COBALT],
			"credit_reward": 3000,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Swap to Cyan", "Gate 2", "Swap to Emerald", "Gate 5"]}
		},
		{
			"id": "champ_canyon_21",
			"title": "Canyon Clash Stage 3",
			"mode": ChromaConstants.GameMode.CHAMPIONSHIP,
			"world_id": ChromaConstants.WORLD_PRISM_CANYON,
			"description": "High-altitude desert showdown: 3 rivals, narrow gorges, and dual deliveries at Gate 1 and Gate 4.",
			"starting_color": ChromaConstants.ChromaColor.COBALT,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.SOLAR, "gate_id": "gate_1", "points": 1800},
				{"target_color": ChromaConstants.ChromaColor.EMERALD, "gate_id": "gate_4", "points": 2200}
			],
			"time_limit": 170.0,
			"swap_limit": 0,
			"rival_count": 3,
			"traffic_colors": [ChromaConstants.ChromaColor.SOLAR, ChromaConstants.ChromaColor.EMERALD, ChromaConstants.ChromaColor.CRIMSON],
			"credit_reward": 3500,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Swap to Solar", "Gate 1", "Swap to Emerald", "Gate 4"]}
		},
		{
			"id": "champ_sky_22",
			"title": "Stratosphere Final Stage 4",
			"mode": ChromaConstants.GameMode.CHAMPIONSHIP,
			"world_id": ChromaConstants.WORLD_SKY_CIRCUIT,
			"description": "Championship climax: 3 elite master AI rivals on the high-speed cloud circuit.",
			"starting_color": ChromaConstants.ChromaColor.CYAN,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.MAGENTA, "gate_id": "gate_2", "points": 2000},
				{"target_color": ChromaConstants.ChromaColor.CRIMSON, "gate_id": "gate_6", "points": 2500}
			],
			"time_limit": 180.0,
			"swap_limit": 0,
			"rival_count": 3,
			"traffic_colors": [ChromaConstants.ChromaColor.MAGENTA, ChromaConstants.ChromaColor.CRIMSON, ChromaConstants.ChromaColor.COBALT],
			"credit_reward": 5000,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Swap to Magenta", "Gate 2", "Swap to Crimson", "Gate 6"]}
		},
		{
			"id": "champ_neon_23",
			"title": "Midnight Rivals Tournament",
			"mode": ChromaConstants.GameMode.CHAMPIONSHIP,
			"world_id": ChromaConstants.WORLD_NEON_CITY,
			"description": "Underground street duel: 2 rivals, aggressive pursuit tactics, 3 checkpoint targets.",
			"starting_color": ChromaConstants.ChromaColor.SOLAR,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.CRIMSON, "gate_id": "gate_1", "points": 1500},
				{"target_color": ChromaConstants.ChromaColor.COBALT, "gate_id": "gate_2", "points": 1800},
				{"target_color": ChromaConstants.ChromaColor.MAGENTA, "gate_id": "gate_5", "points": 2200}
			],
			"time_limit": 190.0,
			"swap_limit": 0,
			"rival_count": 2,
			"traffic_colors": [ChromaConstants.ChromaColor.CRIMSON, ChromaConstants.ChromaColor.COBALT, ChromaConstants.ChromaColor.MAGENTA],
			"credit_reward": 4500,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["3-step championship series"]}
		},
		{
			"id": "champ_sky_24",
			"title": "Ultimate Chroma Crown",
			"mode": ChromaConstants.GameMode.CHAMPIONSHIP,
			"world_id": ChromaConstants.WORLD_SKY_CIRCUIT,
			"description": "The definitive test of driving and swap mastery. 4 rivals, all 6 colors in circulation.",
			"starting_color": ChromaConstants.ChromaColor.EMERALD,
			"objectives": [
				{"target_color": ChromaConstants.ChromaColor.CYAN, "gate_id": "gate_1", "points": 2000},
				{"target_color": ChromaConstants.ChromaColor.MAGENTA, "gate_id": "gate_2", "points": 2500},
				{"target_color": ChromaConstants.ChromaColor.CRIMSON, "gate_id": "gate_6", "points": 3000}
			],
			"time_limit": 210.0,
			"swap_limit": 0,
			"rival_count": 4,
			"traffic_colors": [ChromaConstants.ChromaColor.CYAN, ChromaConstants.ChromaColor.MAGENTA, ChromaConstants.ChromaColor.CRIMSON, ChromaConstants.ChromaColor.SOLAR],
			"credit_reward": 8000,
			"medal_tier": "gold",
			"solvability_proof": {"steps": ["Ultimate 3-color chain against 4 master rivals"]}
		}
	]

static func get_mission_by_id(m_id: String) -> Dictionary:
	for m in get_all_missions():
		if m["id"] == m_id:
			return m
	return {}

static func get_missions_for_mode(mode: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for m in get_all_missions():
		if m["mode"] == mode:
			result.append(m)
	return result

static func validate_mission(m: Dictionary) -> Dictionary:
	var errors: Array[String] = []

	if not m.has("id") or m["id"] == "":
		errors.append("Mission missing ID")
	if not m.has("world_id") or not (m["world_id"] in ChromaConstants.ALL_WORLDS):
		errors.append("Invalid world_id: %s" % str(m.get("world_id", "")))
	if not m.has("starting_color") or m["starting_color"] == ChromaConstants.ChromaColor.NONE:
		errors.append("Invalid starting_color")
	if not m.has("objectives") or m["objectives"].is_empty():
		errors.append("Mission has no objectives")

	# Check traffic colors availability vs required objectives
	var available_colors: Dictionary = {}
	available_colors[m.get("starting_color", 0)] = true
	for c in m.get("traffic_colors", []):
		available_colors[c] = true

	var objectives: Array = m.get("objectives", [])
	for obj in objectives:
		var target_col = obj.get("target_color", 0)
		if not available_colors.has(target_col):
			errors.append("Objective color %d not present in traffic or starting inventory" % target_col)
		if not obj.has("gate_id") or obj["gate_id"] == "":
			errors.append("Objective missing gate_id")

	# Check swap limit validity for puzzle drive
	if m.get("mode", -1) == ChromaConstants.GameMode.PUZZLE_DRIVE:
		var limit = m.get("swap_limit", 0)
		if limit < 1:
			errors.append("Puzzle Drive mode must have swap_limit >= 1")

	return {
		"is_valid": errors.is_empty(),
		"errors": errors
	}

static func validate_all_missions() -> Dictionary:
	var all_missions = get_all_missions()
	var total_errors: Array[String] = []

	for m in all_missions:
		var res = validate_mission(m)
		if not res["is_valid"]:
			for err in res["errors"]:
				total_errors.append("[%s] %s" % [m.get("id", "UNKNOWN"), err])

	return {
		"is_valid": total_errors.is_empty(),
		"total_missions": all_missions.size(),
		"errors": total_errors
	}
