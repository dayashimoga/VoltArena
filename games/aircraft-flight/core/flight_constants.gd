class_name FlightConstants
extends RefCounted

## FlightConstants: Physical constants, aerodynamic parameters, and flight modes
## for Apex Flight: Open Skies (VoltArena).

enum FlightMode {
	ARCADE,       ## Flight assists active, auto-trim, roll-to-yaw coordination, no stall spin
	SIMCADE,      ## Envelope protection (G-limiter, stall warning), realistic lift/drag
	SIMULATION    ## Raw 6-DOF aerodynamics, full stall/spin, engine spool, adverse yaw
}

enum AircraftType {
	FIGHTER_JET,      ## F/A-18 style supersonic twin-engine multi-role fighter
	STEALTH_FIGHTER,  ## F-22 style 5th-gen thrust-vectoring stealth air superiority
	AIRLINER,         ## A320 style twin-engine commercial airliner
	SPORT_PLANE,      ## Extra 330 style high-agility aerobatic monoplane
	HELICOPTER        ## UH-60 style multi-mission tactical transport rotorcraft
}

enum MissionType {
	FREE_FLIGHT,          ## Open sandbox across 8 biomes
	TAKEOFF_LANDING,      ## Runway certification with ILS and touchdown flare scoring
	URBAN_LOW_ALTITUDE,   ## Skyscraper canyon run below 100m AGL
	CHECKPOINT_AIR_RACE,  ## 3D aerial slalom rings with precision orientation scoring
	DEADSTICK_DESCENT,    ## Dual engine flameout glide to emergency landing
	MOUNTAIN_SLALOM,      ## High-G canyon carving through razor ridges
	LANDMARK_RECON,       ## Aerial reconnaissance and camera photo captures
	ROTORCRAFT_SAR        ## Precision helicopter hover, survivor hoist & helipad drop
}

enum CameraViewMode {
	CHASE,      ## Authoritative dynamic 3rd-person spring-arm camera
	COCKPIT,    ## 1st-person interior cockpit view with functional instruments
	AEROBATIC,  ## Rigid aerobatic chase camera locked 100% to aircraft axes
	FREE        ## Exterior cinematic orbit / fly-by camera
}

# Standard atmospheric constants
const AIR_DENSITY_SEA_LEVEL: float = 1.225 # kg/m^3
const GRAVITY: float = 9.81 # m/s^2
const CRITICAL_AOA_DEG: float = 16.0 # Critical Angle of Attack for wing stall
const CRITICAL_AOA_RAD: float = deg_to_rad(CRITICAL_AOA_DEG)
const SOUND_SPEED_SEA_LEVEL: float = 340.29 # m/s (Mach 1.0)

# Input action mappings
const ACTION_PITCH_UP: String = "pitch_up"
const ACTION_PITCH_DOWN: String = "pitch_down"
const ACTION_ROLL_LEFT: String = "roll_left"
const ACTION_ROLL_RIGHT: String = "roll_right"
const ACTION_YAW_LEFT: String = "yaw_left"
const ACTION_YAW_RIGHT: String = "yaw_right"
const ACTION_THROTTLE_UP: String = "throttle_up"
const ACTION_THROTTLE_DOWN: String = "throttle_down"
const ACTION_AIRBRAKE: String = "brake"
const ACTION_FLAPS: String = "flaps_cycle"
const ACTION_GEAR: String = "landing_gear"
const ACTION_CAMERA: String = "camera_toggle"
const ACTION_AUTOPILOT: String = "autopilot_toggle"
const ACTION_ASSIST: String = "flight_assist_toggle"
const ACTION_RECOVER: String = "reload"
