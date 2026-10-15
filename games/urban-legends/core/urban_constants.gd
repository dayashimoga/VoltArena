class_name UrbanConstants
extends RefCounted

## Master architectural constants for Urban Legends open-world driving game.
## Covers collision layers, vehicle archetypes, districts, missions, weather, and physics tuning.

# --- Collision Layers (Godot 3D Physics Layers) ---
const LAYER_WORLD: int = 1         # Roads, terrain, buildings, barriers
const LAYER_PLAYER: int = 2        # Player drivable vehicle
const LAYER_ENEMIES: int = 4       # AI traffic & rival racing vehicles
const LAYER_PROJECTILES: int = 8   # Projectiles / dynamic physics props
const LAYER_PROPS: int = 1         # Street furniture, lamps, static barriers
const LAYER_PICKUPS: int = 16      # Collectibles / wrench repair icons
const LAYER_BALL: int = 32         # Physics stunt balls / beach balls
const LAYER_GOALS: int = 64        # Garages & trigger zones
const LAYER_CHECKPOINTS: int = 128 # Race & mission checkpoint gates

# --- Vehicle Archetype Identifiers ---
const VEHICLE_VORTEX_GT: String = "vortex_gt"          # Mid-engine exotic supercar (Reference car)
const VEHICLE_THUNDERBOLT_V8: String = "thunderbolt_v8" # Heavy torque American muscle car
const VEHICLE_SPECTER_R: String = "specter_r"          # High-grip street tuner / drift specialist
const VEHICLE_RIDGEBACK_4X4: String = "ridgeback_4x4"  # Rugged all-terrain SUV
const VEHICLE_VALIANT_COUPE: String = "valiant_coupe"  # Classic vintage cruiser

# --- World District Identifiers (8 Coherent Regions) ---
const DISTRICT_DOWNTOWN: String = "district_downtown"       # High-rise commercial core & plazas
const DISTRICT_COLINAS: String = "district_colinas"         # Steep hillside suburban residences & crests
const DISTRICT_GLEN: String = "district_glen"               # Verdant urban parkland & walking paths
const DISTRICT_VERDANT: String = "district_glen"            # Alias for Verdant Glen park
const DISTRICT_HARBORFLY: String = "district_harborfly"     # Multi-level highway flyovers & viaducts
const DISTRICT_BAYVIEW: String = "district_bayview"         # Coastal coastline, boardwalk & beaches
const DISTRICT_INDUSTRIAL: String = "district_industrial"   # Freight depot, cranes & rail corridors
const DISTRICT_RIDGECREST: String = "district_ridgecrest"   # Mountain switchbacks & radio towers
const DISTRICT_AIRPORT: String = "district_airport"         # Airport tarmac, runways & high-speed straight

# --- Mission / Activity Archetypes ---
const MISSION_FREE_ROAM: String = "mission_free_roam"
const MISSION_CIRCUIT_RACE: String = "mission_circuit_race"
const MISSION_DRIFT_TRIAL: String = "mission_drift_trial"
const MISSION_HILL_CLIMB: String = "mission_hill_climb"
const MISSION_COURIER: String = "mission_courier"
const MISSION_STUNT_LEAP: String = "mission_stunt_leap"
const MISSION_EXPLORER: String = "mission_explorer"

# --- Surface Friction & Ground Types ---
const SURFACE_ASPHALT: int = 0
const SURFACE_CONCRETE: int = 1
const SURFACE_GRASS: int = 2
const SURFACE_DIRT: int = 3
const SURFACE_SAND: int = 4

# --- Weather & Lighting Presets ---
const WEATHER_SUNNY: int = 0        # Crisp high-noon daylight
const WEATHER_GOLDEN_HOUR: int = 1  # Warm sunset amber glow (Reference vibe)
const WEATHER_OVERCAST: int = 2     # Soft diffused lighting
const WEATHER_RAIN: int = 3         # Wet asphalt reflections, rain spray
const WEATHER_NIGHT_NEON: int = 4   # City neon lights, dark blue sky, headlights

const WEATHER_CLEAR_NOON: String = "clear_noon"
const WEATHER_GOLDEN_SUNSET: String = "golden_sunset"
const WEATHER_NEON_NIGHT: String = "neon_night"
const WEATHER_OVERCAST_DRIZZLE: String = "overcast_drizzle"

# --- Camera Modes ---
const CAM_CHASE: int = 0
const CAM_FREE: int = 1
const CAM_BUMPER: int = 2
const CAM_STUNT: int = 3

# --- Stunt Type Identifiers ---
const STUNT_AIR_TIME: int = 1
const STUNT_LONG_JUMP: int = 2
const STUNT_BARREL_ROLL: int = 3
const STUNT_FLIP: int = 4
const STUNT_SPIN_360: int = 5
const STUNT_DRIFT_CHAIN: int = 6
const STUNT_NEAR_MISS: int = 7
const STUNT_DOUBLE_INSANE: int = 8

# --- Default Physics Constants ---
const DEFAULT_GRAVITY: float = 24.5
const REST_SUSPENSION_LENGTH: float = 0.65
const MAX_SUSPENSION_TRAVEL: float = 0.28
const TIRE_RADIUS: float = 0.36
const CHASSIS_HALF_WIDTH: float = 0.95
const CHASSIS_HALF_LENGTH: float = 2.25
