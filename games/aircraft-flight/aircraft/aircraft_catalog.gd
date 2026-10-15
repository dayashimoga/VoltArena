class_name AircraftCatalog
extends RefCounted

## AircraftCatalog: Comprehensive Aircraft Specifications & Roster for Apex Flight.
## Defines realistic flight envelopes, physical dimensions, engine thrust,
## aerodynamic coefficients, and handling dynamics for all 5 flyable aircraft.

const FlightConst = preload("res://games/aircraft-flight/core/flight_constants.gd")

static var AIRCRAFT_ROSTER: Dictionary = {
	"fa18_hornet": {
		"id": "fa18_hornet",
		"name": "F/A-18C Hornet",
		"category": "Carrier Strike Fighter",
		"type": FlightConst.AircraftType.FIGHTER_JET,
		"description": "Twin-turbofan supersonic carrier-capable multirole fighter with leading-edge extensions and high Angle-of-Attack agility.",
		"mass_kg": 11200.0,
		"wing_area": 38.0,
		"wingspan": 12.3,
		"aspect_ratio": 4.0,
		"oswald_efficiency": 0.85,
		"cd0": 0.021,
		"max_thrust_n": 105000.0,
		"afterburner_multiplier": 1.68,
		"has_afterburner": true,
		"is_rotorcraft": false,
		"stall_speed_ms": 38.0, # ~137 km/h with flaps
		"max_speed_ms": 530.0, # ~1,910 km/h (Mach 1.8)
		"max_g_rating": 9.0,
		"pitch_authority": 2.6,
		"roll_authority": 4.8,
		"yaw_authority": 1.6,
		"ceiling_m": 15200.0,
		"primary_color": Color(0.45, 0.48, 0.52), # Naval Tactical Gray
		"accent_color": Color(0.1, 0.65, 1.0),
		"unlocked_by_default": true
	},
	"f22_raptor": {
		"id": "f22_raptor",
		"name": "F-22A Raptor",
		"category": "5th-Gen Stealth Air Superiority",
		"type": FlightConst.AircraftType.STEALTH_FIGHTER,
		"description": "Stealth air superiority fighter with thrust-vectoring twin engines, supercruise capability, and unmatched post-stall combat maneuvering.",
		"mass_kg": 14500.0,
		"wing_area": 78.0,
		"wingspan": 13.6,
		"aspect_ratio": 2.36,
		"oswald_efficiency": 0.88,
		"cd0": 0.016, # Extreme low parasite drag
		"max_thrust_n": 140000.0,
		"afterburner_multiplier": 1.55,
		"has_afterburner": true,
		"is_rotorcraft": false,
		"stall_speed_ms": 34.0,
		"max_speed_ms": 680.0, # ~2,450 km/h (Mach 2.25)
		"max_g_rating": 9.5,
		"pitch_authority": 3.2,
		"roll_authority": 5.2,
		"yaw_authority": 2.2,
		"ceiling_m": 19800.0,
		"primary_color": Color(0.25, 0.28, 0.32), # Radar-absorbent dark composite
		"accent_color": Color(0.9, 0.3, 0.1),
		"unlocked_by_default": false,
		"unlock_cost_hours": 2.0
	},
	"a320_airliner": {
		"id": "a320_airliner",
		"name": "A320 SkyLiner",
		"category": "Commercial Twin-Jet Airliner",
		"type": FlightConst.AircraftType.AIRLINER,
		"description": "High-efficiency commercial airliner with high-bypass CFM turbofans, supercritical swept wings, multi-wheel bogies, and passenger cabin.",
		"mass_kg": 42000.0,
		"wing_area": 122.0,
		"wingspan": 34.1,
		"aspect_ratio": 9.5, # High aspect ratio for fuel efficiency
		"oswald_efficiency": 0.82,
		"cd0": 0.024,
		"max_thrust_n": 120000.0,
		"afterburner_multiplier": 1.0,
		"has_afterburner": false,
		"is_rotorcraft": false,
		"stall_speed_ms": 46.0, # ~165 km/h landing config
		"max_speed_ms": 255.0, # ~920 km/h (Mach 0.82)
		"max_g_rating": 2.5,
		"pitch_authority": 1.1,
		"roll_authority": 1.5,
		"yaw_authority": 0.8,
		"ceiling_m": 12500.0,
		"primary_color": Color(0.92, 0.94, 0.96), # Gloss white livery
		"accent_color": Color(0.12, 0.35, 0.85),
		"unlocked_by_default": true
	},
	"extra330_sport": {
		"id": "extra330_sport",
		"name": "Extra 330SC Aerobatic",
		"category": "Unlimited Aerobatic Monoplane",
		"type": FlightConst.AircraftType.SPORT_PLANE,
		"description": "Unlimited competition aerobatic monoplane with 315 HP Lycoming engine, lightweight carbon frame, and lightning-fast 400 deg/s roll rate.",
		"mass_kg": 660.0,
		"wing_area": 10.8,
		"wingspan": 7.5,
		"aspect_ratio": 5.2,
		"oswald_efficiency": 0.90,
		"cd0": 0.028,
		"max_thrust_n": 7800.0,
		"afterburner_multiplier": 1.0,
		"has_afterburner": false,
		"is_rotorcraft": false,
		"stall_speed_ms": 26.0, # ~95 km/h
		"max_speed_ms": 115.0, # ~415 km/h
		"max_g_rating": 10.0,
		"pitch_authority": 4.2,
		"roll_authority": 7.0, # Extreme aerobatic roll rate
		"yaw_authority": 3.0,
		"ceiling_m": 4800.0,
		"primary_color": Color(0.9, 0.15, 0.15), # Racing Red
		"accent_color": Color(1.0, 0.9, 0.1),
		"unlocked_by_default": true
	},
	"uh60_helicopter": {
		"id": "uh60_helicopter",
		"name": "UH-60 BlackHawk",
		"category": "Tactical Multi-Mission Rotorcraft",
		"type": FlightConst.AircraftType.HELICOPTER,
		"description": "Twin-engine tactical utility rotorcraft with 4-blade articulated main rotor, canted tail rotor, and precision search & rescue hoist.",
		"mass_kg": 6800.0,
		"wing_area": 22.0, # Rotor disc equivalent reference area
		"wingspan": 16.36, # Main rotor disc diameter
		"aspect_ratio": 4.0,
		"oswald_efficiency": 0.75,
		"cd0": 0.065, # High parasite rotorcraft drag
		"max_thrust_n": 85000.0,
		"afterburner_multiplier": 1.0,
		"has_afterburner": false,
		"is_rotorcraft": true,
		"stall_speed_ms": 0.0, # Zero stall speed (can hover in place)
		"max_speed_ms": 82.0, # ~295 km/h maximum forward airspeed
		"max_g_rating": 3.5,
		"pitch_authority": 1.8,
		"roll_authority": 2.2,
		"yaw_authority": 2.8,
		"ceiling_m": 5800.0,
		"primary_color": Color(0.18, 0.22, 0.19), # Matte Olive Drab
		"accent_color": Color(0.85, 0.65, 0.15),
		"unlocked_by_default": true
	}
}

static func get_aircraft_spec(id: String) -> Dictionary:
	if AIRCRAFT_ROSTER.has(id):
		return AIRCRAFT_ROSTER[id]
	return AIRCRAFT_ROSTER["fa18_hornet"]

static func get_all_aircraft() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for k in AIRCRAFT_ROSTER.keys():
		list.append(AIRCRAFT_ROSTER[k])
	return list
