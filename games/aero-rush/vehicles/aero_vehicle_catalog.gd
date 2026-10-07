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
				"class_title": "Rally Spec Performance",
				"top_speed": 52.0,                  # m/s (~187 km/h)
				"acceleration": 34.0,               # m/s²
				"steer_speed": 3.6,                 # rad/s
				"brake_force": 40.0,                # m/s²
				"drift_factor": 4.8,                # snappy counter-steer slip
				"mass": 1250.0,                     # kg
				"boost_force": 22.0,
				"suspension_stiffness": 14.0,
				"suspension_travel": 0.45,
				"air_control_pitch": 3.4,
				"air_control_yaw": 3.8,
				"air_control_roll": 4.2,
				"credit_cost": 3000,
				"glb_path": "res://assets/models/vehicles/car_sedan_sports.glb",
				"wheel_glb_path": "res://assets/models/vehicles/car_wheel_racing.glb",
				"default_color": Color(0.95, 0.42, 0.08), # Rally Orange
				"desc": "Wide-body rally stance with heavy torque and responsive counter-steer drift recovery."
			}

		AeroConstants.VEHICLE_DUNE:
			return {
				"id": AeroConstants.VEHICLE_DUNE,
				"name": "Vanguard Dune",
				"class_title": "Heavy Off-Road Buggy",
				"top_speed": 46.0,                  # m/s (~165 km/h)
				"acceleration": 32.0,               # m/s²
				"steer_speed": 3.1,                 # rad/s
				"brake_force": 38.0,                # m/s²
				"drift_factor": 3.4,
				"mass": 1500.0,                     # heavy mass absorbs jumps
				"boost_force": 18.0,
				"suspension_stiffness": 10.0,       # long plush travel
				"suspension_travel": 0.65,
				"air_control_pitch": 2.8,
				"air_control_yaw": 3.0,
				"air_control_roll": 3.2,
				"credit_cost": 6500,
				"glb_path": "res://assets/models/vehicles/car_suv_luxury.glb",
				"wheel_glb_path": "res://assets/models/vehicles/car_wheel_default.glb",
				"default_color": Color(0.18, 0.72, 0.35), # Emerald Dune
				"desc": "Armored trophy chassis with huge suspension travel that absorbs extreme landing shocks effortlessly."
			}

		AeroConstants.VEHICLE_QUANTUM:
			return {
				"id": AeroConstants.VEHICLE_QUANTUM,
				"name": "Quantum Phantom",
				"class_title": "Experimental Magnetic Prototype",
				"top_speed": 64.0,                  # m/s (~230 km/h)
				"acceleration": 42.0,               # m/s²
				"steer_speed": 4.2,                 # rad/s
				"brake_force": 46.0,                # m/s²
				"drift_factor": 4.5,
				"mass": 980.0,                      # ultralight carbon monocoque
				"boost_force": 28.0,
				"suspension_stiffness": 18.0,
				"suspension_travel": 0.35,
				"air_control_pitch": 4.8,           # extreme stunt agility
				"air_control_yaw": 5.0,
				"air_control_roll": 5.4,
				"credit_cost": 15000,
				"glb_path": "res://assets/models/vehicles/car_hatchback_sports.glb",
				"wheel_glb_path": "res://assets/models/vehicles/car_wheel_dark.glb",
				"default_color": Color(0.68, 0.15, 0.95), # Royal Violet / Cyber
				"desc": "Supersonic experimental prototype featuring magnetic track grounding and razor-sharp aerial trick authority."
			}

		_: # Default: AeroConstants.VEHICLE_APEX
			return {
				"id": AeroConstants.VEHICLE_APEX,
				"name": "Apex Zephyr",
				"class_title": "Hyper-Aerodynamic Interceptor",
				"top_speed": 58.0,                  # m/s (~208 km/h)
				"acceleration": 38.0,               # m/s²
				"steer_speed": 3.8,                 # rad/s
				"brake_force": 42.0,                # m/s²
				"drift_factor": 4.2,
				"mass": 1100.0,
				"boost_force": 24.0,
				"suspension_stiffness": 16.0,
				"suspension_travel": 0.40,
				"air_control_pitch": 3.8,
				"air_control_yaw": 4.0,
				"air_control_roll": 4.5,
				"credit_cost": 0,                   # Unlocked by default
				"glb_path": "res://assets/models/vehicles/car_race_future.glb",
				"wheel_glb_path": "res://assets/models/vehicles/car_wheel_racing.glb",
				"default_color": Color(0.08, 0.58, 0.95), # Electric Cyan
				"desc": "Sleek low-drag hypercar with active aerodynamic wings and exceptional loop stability."
			}

static func get_all_definitions() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for v_id in AeroConstants.ALL_VEHICLES:
		list.append(get_vehicle_definition(v_id))
	return list
