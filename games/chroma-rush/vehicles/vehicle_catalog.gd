class_name VehicleCatalog
extends RefCounted

## Vehicle definitions, physics parameters, and cosmetic unlocks for Chroma Rush

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")

static func get_vehicle_definition(vehicle_id: String) -> Dictionary:
	match vehicle_id:
		ChromaConstants.VEHICLE_VORTEX:
			return {
				"id": ChromaConstants.VEHICLE_VORTEX,
				"name": "Vortex Drift",
				"tagline": "Precision Drift Tuner",
				"top_speed": 34.0,       # m/s (~122 km/h)
				"acceleration": 3.0,     # m/s² (0-60 km/h: ~5.38 s)
				"steer_speed": 3.8,      # rad/s
				"brake_force": 34.0,     # m/s²
				"drift_factor": 5.2,     # lateral yaw multiplier during drift
				"suspension_stiffness": 12.0,
				"mass": 1050.0,
				"credit_cost": 0,        # Unlocked by default
				"body_style": "tuner",
				"desc": "High lateral grip and snappy counter-steer for technical street circuits."
			}
		ChromaConstants.VEHICLE_TITAN:
			return {
				"id": ChromaConstants.VEHICLE_TITAN,
				"name": "Titan Vanguard",
				"tagline": "Heavy Armored Interceptor",
				"top_speed": 31.0,       # m/s (~111 km/h)
				"acceleration": 2.4,     # m/s² (0-60 km/h: ~6.86 s)
				"steer_speed": 2.8,      # rad/s
				"brake_force": 42.0,     # m/s²
				"drift_factor": 3.2,
				"suspension_stiffness": 18.0,
				"mass": 1650.0,
				"credit_cost": 2500,
				"body_style": "heavy",
				"desc": "Unmatched impact resilience and wide alignment tolerance in heavy traffic."
			}
		ChromaConstants.VEHICLE_PULSE:
			return {
				"id": ChromaConstants.VEHICLE_PULSE,
				"name": "Pulse Cyber",
				"tagline": "Instant Electric Sprinter",
				"top_speed": 36.0,       # m/s (~130 km/h)
				"acceleration": 3.8,     # m/s² (0-60 km/h: ~4.19 s)
				"steer_speed": 3.6,      # rad/s
				"brake_force": 38.0,     # m/s²
				"drift_factor": 4.0,
				"suspension_stiffness": 15.0,
				"mass": 1250.0,
				"credit_cost": 5000,
				"body_style": "cyber",
				"desc": "Dual-motor electric torque delivering rapid acceleration out of corners."
			}
		ChromaConstants.VEHICLE_DUNE:
			return {
				"id": ChromaConstants.VEHICLE_DUNE,
				"name": "Dune Nomad",
				"tagline": "All-Terrain Trophy Cruiser",
				"top_speed": 32.0,       # m/s (~115 km/h)
				"acceleration": 2.7,     # m/s² (0-60 km/h: ~6.06 s)
				"steer_speed": 3.2,      # rad/s
				"brake_force": 32.0,     # m/s²
				"drift_factor": 3.8,
				"suspension_stiffness": 10.0,
				"mass": 1400.0,
				"credit_cost": 7500,
				"body_style": "offroad",
				"desc": "Long suspension travel absorbing uneven canyon terrain and curbs with ease."
			}
		ChromaConstants.VEHICLE_QUANTUM:
			return {
				"id": ChromaConstants.VEHICLE_QUANTUM,
				"name": "Quantum Phantom",
				"tagline": "Experimental Lev-Chassis",
				"top_speed": 40.0,       # m/s (~144 km/h)
				"acceleration": 3.9,     # m/s² (0-60 km/h: ~4.05 s)
				"steer_speed": 4.0,      # rad/s
				"brake_force": 40.0,     # m/s²
				"drift_factor": 4.6,
				"suspension_stiffness": 16.0,
				"mass": 980.0,
				"credit_cost": 12000,
				"body_style": "prototype",
				"desc": "Near-zero aerodynamic drag and magnetic road grounding for extreme speeds."
			}
		_: # ChromaConstants.VEHICLE_APEX (Default)
			return {
				"id": ChromaConstants.VEHICLE_APEX,
				"name": "Apex Striker",
				"tagline": "Hyper-Aerodynamic Interceptor",
				"top_speed": 38.0,       # m/s (~137 km/h)
				"acceleration": 3.2,     # m/s² (0-60 km/h: ~4.93 s)
				"steer_speed": 3.4,      # rad/s
				"brake_force": 36.0,     # m/s²
				"drift_factor": 4.2,
				"suspension_stiffness": 14.0,
				"mass": 1100.0,
				"credit_cost": 0,        # Unlocked by default
				"body_style": "supercar",
				"desc": "Balanced hypercar engineered for high-speed highway pursuits and rapid color trades."
			}

static func get_all_vehicle_ids() -> Array[String]:
	return [
		ChromaConstants.VEHICLE_APEX,
		ChromaConstants.VEHICLE_VORTEX,
		ChromaConstants.VEHICLE_TITAN,
		ChromaConstants.VEHICLE_PULSE,
		ChromaConstants.VEHICLE_DUNE,
		ChromaConstants.VEHICLE_QUANTUM
	]
