class_name AeroVehicleCatalog
extends RefCounted

## Fictional vehicle specifications, physics parameters, and model bindings for AeroRush.
## Differentiates performance curves: Top Speed, Acceleration, Grip, Drift, Mass, Boost, and Air Control.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

static func get_vehicle_definition(vehicle_id: String) -> Dictionary:
	match vehicle_id:
		AeroConstants.VEHICLE_STRYKER:
			return {
				"id": AeroConstants.VEHICLE_STRYKER,
				"name": "Torque Stryker",
				"class_title": "High-Downforce LMP Circuit Racer",
				"top_speed": 58.0,                  # m/s (~209 km/h)
				"acceleration": 38.0,               # m/s²
				"steer_speed": 3.8,                 # rad/s
				"brake_force": 44.0,                # m/s²
				"drift_factor": 4.0,                # snappy counter-steer slip
				"mass": 1120.0,                     # kg (Prompt spec: 1,120 kg)
				"grip": 1.30,                       # grip multiplier (Prompt spec: 1.30)
				"boost_force": 24.0,
				"suspension_stiffness": 16.0,
				"suspension_travel": 0.38,
				"air_control_pitch": 3.2,
				"air_control_yaw": 4.0,
				"air_control_roll": 4.5,
				"credit_cost": 3000,
				"glb_path": "res://assets/models/vehicles/car_sedan_sports.glb",
				"wheel_glb_path": "res://assets/models/vehicles/car_wheel_racing.glb",
				"default_color": Color(0.95, 0.42, 0.08), # Rally Orange / LMP Livery
				"desc": "High-downforce LMP circuit racer with shark-fin stabilizer and immense cornering grip."
			}

		AeroConstants.VEHICLE_DUNE:
			return {
				"id": AeroConstants.VEHICLE_DUNE,
				"name": "Vanguard Dune",
				"class_title": "Long-Travel Rally Stunt Buggy",
				"top_speed": 52.0,                  # m/s (~187 km/h, Prompt spec: 52 m/s)
				"acceleration": 34.0,               # m/s²
				"steer_speed": 3.4,                 # rad/s
				"brake_force": 40.0,                # m/s²
				"drift_factor": 3.6,
				"mass": 1280.0,                     # kg (Prompt spec: 1,280 kg)
				"grip": 1.05,                       # grip multiplier (Prompt spec: 1.05)
				"boost_force": 20.0,
				"suspension_stiffness": 11.0,       # long plush travel
				"suspension_travel": 0.65,
				"air_control_pitch": 3.2,
				"air_control_yaw": 4.0,
				"air_control_roll": 4.5,
				"credit_cost": 6500,
				"glb_path": "res://assets/models/vehicles/car_suv_luxury.glb",
				"wheel_glb_path": "res://assets/models/vehicles/car_wheel_default.glb",
				"default_color": Color(0.18, 0.72, 0.35), # Emerald Dune
				"desc": "Long-travel independent suspension rally stunt buggy absorbing extreme landing shocks."
			}

		AeroConstants.VEHICLE_QUANTUM:
			return {
				"id": AeroConstants.VEHICLE_QUANTUM,
				"name": "Quantum Phantom",
				"class_title": "Maglev Stunt Prototype",
				"top_speed": 62.0,                  # m/s (~223 km/h, Prompt spec: 62 m/s)
				"acceleration": 42.0,               # m/s²
				"steer_speed": 4.2,                 # rad/s
				"brake_force": 46.0,                # m/s²
				"drift_factor": 4.2,
				"mass": 980.0,                      # kg (Prompt spec: 980 kg)
				"grip": 1.25,                       # grip multiplier (Prompt spec: 1.25)
				"boost_force": 28.0,
				"suspension_stiffness": 18.0,
				"suspension_travel": 0.35,
				"air_control_pitch": 3.2,
				"air_control_yaw": 4.0,
				"air_control_roll": 4.5,
				"credit_cost": 15000,
				"glb_path": "res://assets/models/vehicles/car_hatchback_sports.glb",
				"wheel_glb_path": "res://assets/models/vehicles/car_wheel_dark.glb",
				"default_color": Color(0.68, 0.15, 0.95), # Royal Violet / Cyber
				"desc": "Enclosed-cockpit magnetic levitation stunt prototype with active aero flaps and high agility."
			}

		_: # Default: AeroConstants.VEHICLE_APEX
			return {
				"id": AeroConstants.VEHICLE_APEX,
				"name": "Apex Zephyr",
				"class_title": "Aerodynamic Hypercar",
				"top_speed": 64.0,                  # m/s (~230 km/h, Prompt spec: 64 m/s)
				"acceleration": 40.0,               # m/s²
				"steer_speed": 3.8,                 # rad/s
				"brake_force": 42.0,                # m/s²
				"drift_factor": 4.2,
				"mass": 950.0,                      # kg (Prompt spec: 950 kg)
				"grip": 1.15,                       # grip multiplier (Prompt spec: 1.15)
				"boost_force": 26.0,
				"suspension_stiffness": 16.0,
				"suspension_travel": 0.40,
				"air_control_pitch": 3.2,
				"air_control_yaw": 4.0,
				"air_control_roll": 4.5,
				"credit_cost": 0,                   # Unlocked by default
				"glb_path": "res://assets/models/vehicles/car_race_future.glb",
				"wheel_glb_path": "res://assets/models/vehicles/car_wheel_racing.glb",
				"default_color": Color(0.08, 0.58, 0.95), # Electric Cyan
				"desc": "Sleek aerodynamic hypercar with active aerodynamic wings and exceptional loop stability."
			}

static func get_all_definitions() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for v_id in AeroConstants.ALL_VEHICLES:
		list.append(get_vehicle_definition(v_id))
	return list
