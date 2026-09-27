class_name ChromaConstants
extends RefCounted

## Authoritative constants and metadata for Chroma Rush: The Color Chase

# --- COLOR IDENTIFIERS ---
enum ChromaColor {
	NONE = 0,
	CRIMSON = 1,
	COBALT = 2,
	SOLAR = 3,
	EMERALD = 4,
	MAGENTA = 5,
	CYAN = 6
}

# --- ACCESSIBILITY SYMBOLS ---
const SYMBOLS = {
	ChromaColor.NONE: "—",
	ChromaColor.CRIMSON: "◆", # Diamond
	ChromaColor.COBALT: "⬡",  # Hexagon
	ChromaColor.SOLAR: "★",   # Star
	ChromaColor.EMERALD: "▲", # Triangle
	ChromaColor.MAGENTA: "✚", # Cross
	ChromaColor.CYAN: "●"     # Circle
}

const COLOR_NAMES = {
	ChromaColor.NONE: "Neutral",
	ChromaColor.CRIMSON: "Crimson Red",
	ChromaColor.COBALT: "Cobalt Blue",
	ChromaColor.SOLAR: "Solar Gold",
	ChromaColor.EMERALD: "Emerald Green",
	ChromaColor.MAGENTA: "Neon Magenta",
	ChromaColor.CYAN: "Electric Cyan"
}

const COLOR_VALUES = {
	ChromaColor.NONE: Color(0.6, 0.6, 0.65),
	ChromaColor.CRIMSON: Color(1.0, 0.16, 0.33),  # #FF2A55
	ChromaColor.COBALT: Color(0.0, 0.53, 1.0),    # #0088FF
	ChromaColor.SOLAR: Color(1.0, 0.80, 0.0),     # #FFCC00
	ChromaColor.EMERALD: Color(0.0, 0.90, 0.46),  # #00E676
	ChromaColor.MAGENTA: Color(0.88, 0.25, 0.98), # #E040FB
	ChromaColor.CYAN: Color(0.0, 0.94, 1.0)       # #00F0FF
}

const PATTERN_TYPES = {
	ChromaColor.NONE: "smooth",
	ChromaColor.CRIMSON: "diagonal_stripes",
	ChromaColor.COBALT: "honeycomb",
	ChromaColor.SOLAR: "radial_dots",
	ChromaColor.EMERALD: "chevron",
	ChromaColor.MAGENTA: "crosshatch",
	ChromaColor.CYAN: "concentric_rings"
}

# --- SWAP ENGINE THRESHOLDS ---
const MAX_SWAP_DISTANCE: float = 8.0 # meters
const MAX_RELATIVE_SPEED: float = 12.5 # m/s
const MAX_ALIGNMENT_ANGLE_DEG: float = 38.0 # degrees parallel
const REQUIRED_ALIGNMENT_DURATION: float = 0.55 # seconds of continuous lock
const SWAP_COOLDOWN: float = 1.2 # seconds
const INPUT_DEBOUNCE_WINDOW: float = 0.2 # seconds

# --- REJECTION REASONS ---
const REJECT_COOLDOWN: String = "COOLDOWN_ACTIVE"
const REJECT_DISTANCE: String = "TARGET_OUT_OF_RANGE"
const REJECT_SPEED: String = "SPEED_MISMATCH"
const REJECT_ANGLE: String = "NOT_ALIGNED"
const REJECT_ALIGNMENT_TIME: String = "ALIGNMENT_INCOMPLETE"
const REJECT_SAME_COLOR: String = "SAME_COLOR"
const REJECT_INVALID: String = "INVALID_TARGET"
const REJECT_BUSY: String = "SWAP_IN_PROGRESS"

# --- GAME MODES ---
enum GameMode {
	COLOR_HUNT = 0,
	CHROMA_SPRINT = 1,
	PUZZLE_DRIVE = 2,
	CHAMPIONSHIP = 3
}

const MODE_NAMES = {
	GameMode.COLOR_HUNT: "Color Hunt",
	GameMode.CHROMA_SPRINT: "Chroma Sprint",
	GameMode.PUZZLE_DRIVE: "Puzzle Drive",
	GameMode.CHAMPIONSHIP: "Chroma Championship"
}

# --- WORLDS ---
const WORLD_NEON_CITY: String = "neon_city"
const WORLD_COASTAL_RUSH: String = "coastal_rush"
const WORLD_PRISM_CANYON: String = "prism_canyon"
const WORLD_SKY_CIRCUIT: String = "sky_circuit"

const ALL_WORLDS = [
	WORLD_NEON_CITY,
	WORLD_COASTAL_RUSH,
	WORLD_PRISM_CANYON,
	WORLD_SKY_CIRCUIT
]

const WORLD_NAMES = {
	WORLD_NEON_CITY: "Neon City",
	WORLD_COASTAL_RUSH: "Coastal Rush",
	WORLD_PRISM_CANYON: "Prism Canyon",
	WORLD_SKY_CIRCUIT: "Sky Circuit"
}

# --- VEHICLES ---
const VEHICLE_APEX: String = "apex_striker"
const VEHICLE_VORTEX: String = "vortex_drift"
const VEHICLE_TITAN: String = "titan_vanguard"
const VEHICLE_PULSE: String = "pulse_cyber"
const VEHICLE_DUNE: String = "dune_nomad"
const VEHICLE_QUANTUM: String = "quantum_phantom"

const ALL_VEHICLES = [
	VEHICLE_APEX,
	VEHICLE_VORTEX,
	VEHICLE_TITAN,
	VEHICLE_PULSE,
	VEHICLE_DUNE,
	VEHICLE_QUANTUM
]

static func get_color_name(c: int) -> String:
	return COLOR_NAMES.get(c, "Unknown")

static func get_color_value(c: int) -> Color:
	return COLOR_VALUES.get(c, Color.WHITE)

static func get_color_symbol(c: int) -> String:
	return SYMBOLS.get(c, "?")

static func get_pattern_type(c: int) -> String:
	return PATTERN_TYPES.get(c, "smooth")

static func format_color_label(c: int) -> String:
	return "%s %s" % [get_color_symbol(c), get_color_name(c)]
