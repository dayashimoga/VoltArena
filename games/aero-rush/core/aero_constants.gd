class_name AeroConstants
extends RefCounted

## System constants, identifiers, enums, and physics parameters for AeroRush: Impossible Circuit

# --- Vehicle Identifiers ---
const VEHICLE_APEX: String = "apex_zephyr"
const VEHICLE_STRYKER: String = "torque_stryker"
const VEHICLE_DUNE: String = "vanguard_dune"
const VEHICLE_QUANTUM: String = "quantum_phantom"

const ALL_VEHICLES: Array[String] = [
	VEHICLE_APEX,
	VEHICLE_STRYKER,
	VEHICLE_DUNE,
	VEHICLE_QUANTUM
]

# --- Game Modes ---
enum GameMode {
	CIRCUIT,            # Multi-lap race against rivals or clock
	SPRINT,             # Point-to-point high-speed stunt sprint
	TIME_ATTACK,        # Clean precision lap with ghost racer
	STUNT_CHALLENGE,    # Score attack requiring trick combinations
	CHECKPOINT_RUSH,    # Timer extensions earned by reaching checkpoints
	HAZARD_RUN          # Navigate dense kinetic obstacle fields
}

# --- Environments (6 Distinct Biomes + Backward Compatible Aliases) ---
enum EnvironmentType {
	NEON_MEGACITY = 0,      # Legacy Neon Megacity (maps to Neon Afterdark)
	MOUNTAIN_CANYON = 1,    # Legacy Canyon (maps to Desert Extreme)
	TROPICAL_COASTAL = 2,   # Legacy Coastal (maps to Coastal Velocity)
	SKY_CIRCUIT = 3,         # Legacy Sky Circuit (Stratosphere Pylons)
	SNOWBOUND_PEAKS = 4,    # Snowbound Peaks: Alpine snow mountains, ice tracks, frozen lakes, snowfall
	WILD_FOREST = 5,        # Wild Forest: Realistic dense forests, waterfalls, rocks, rivers, greenery
	SKYLINE_RUSH = 6,       # Skyline Rush: Believable modern metropolis, rooftop routes, skyscrapers
	DESERT_EXTREME = 7,     # Desert Extreme: Red rock canyons, dunes, rock arches, dust effects
	NEON_AFTERDARK = 8,     # Neon Afterdark: Cyberpunk futuristic night, controlled neon, night tracks
	COASTAL_VELOCITY = 9,   # Coastal Velocity: Beaches, tropical vegetation, oceans, cliffs
	ALIEN_PLANET = 10,      # Alien Planet: Bioluminescent flora, exotic purple atmosphere, crystalline geology
	ORBITAL_SPACE = 11,     # Orbital Space: Cosmic void, starfield sky, earth horizon, orbital array stations
	VOLCANIC_UNDERWORLD = 12 # Volcanic Underworld: Molten magma seas, obsidian crags, volcanic ash, thermal glow
}

# Aliases for 10 Theme System
const BIOME_SNOWBOUND_PEAKS: int = EnvironmentType.SNOWBOUND_PEAKS
const BIOME_COASTAL_VELOCITY: int = EnvironmentType.TROPICAL_COASTAL
const BIOME_WILD_FOREST: int = EnvironmentType.WILD_FOREST
const BIOME_SKYLINE_RUSH: int = EnvironmentType.SKYLINE_RUSH
const BIOME_DESERT_EXTREME: int = EnvironmentType.MOUNTAIN_CANYON
const BIOME_NEON_AFTERDARK: int = EnvironmentType.NEON_MEGACITY
const BIOME_ALIEN_PLANET: int = EnvironmentType.ALIEN_PLANET
const BIOME_ORBITAL_SPACE: int = EnvironmentType.ORBITAL_SPACE
const BIOME_VOLCANIC_UNDERWORLD: int = EnvironmentType.VOLCANIC_UNDERWORLD

# --- Camera View Modes ---
enum CameraViewMode {
	CHASE,      # Dynamic 3rd person chase camera with airtime zoom & landing spring
	HOOD,       # 1st person front hood / bumper camera
	ORBIT       # Smooth orbiting exterior camera
}

# --- Stunt Types ---
enum StuntType {
	AIRTIME,
	LONG_JUMP,
	SPIN_360,
	SPIN_720,
	BARREL_ROLL,
	DOUBLE_ROLL,
	FRONTFLIP,
	BACKFLIP,
	DRIFT,
	WALL_RIDE,
	LOOP_CLEARED,
	NEAR_MISS,
	PERFECT_LANDING,
	BOOST_PAD
}

# --- Medals ---
enum Medal {
	NONE = 0,
	BRONZE = 1,
	SILVER = 2,
	GOLD = 3,
	PLATINUM = 4
}

# --- Physics & Gameplay Tolerances ---
const DEFAULT_GRAVITY: float = 28.0
const MIN_LOOP_SPEED: float = 16.0           # m/s required to maintain centrifugal loop adhesion
const WALL_RIDE_MIN_PITCH_DEG: float = 60.0  # Angle above horizontal considered a wall-ride
const PERFECT_LANDING_MAX_ANGLE_DEG: float = 22.0
const CLEAN_LANDING_MAX_ANGLE_DEG: float = 40.0
const CRASH_LANDING_MIN_ANGLE_DEG: float = 68.0

const COMBO_TIMEOUT_SECONDS: float = 2.6
const MAX_COMBO_MULTIPLIER: int = 10
const MIN_STUNT_SPEED: float = 10.0          # Anti-exploit: stationary trick attempts award 0

# --- Collision Layers (Matching Project Settings) ---
const LAYER_WORLD: int = 1
const LAYER_PLAYER: int = 2
const LAYER_ENEMIES: int = 4
const LAYER_PROJECTILES: int = 8
const LAYER_PICKUPS: int = 16
const LAYER_CHECKPOINTS: int = 128

# --- Audio BGM Identifiers ---
const BGM_TRACK_MEGACITY: String = "aero_rush"
const BGM_TRACK_CANYON: String = "drift_storm"
const BGM_TRACK_COASTAL: String = "chroma_rush"
const BGM_TRACK_SKY: String = "iron_crucible"
