class_name UrbanVehicleCatalog
extends RefCounted

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")

## Vehicle archetypes catalog and performance specifications for Urban Legends.
## Defines physical dimensions, performance envelopes, mass, grip, and descriptive lore.

static func get_vehicle_ids() -> Array[String]:
	return [
		UrbanConstants.VEHICLE_VORTEX_GT,
		UrbanConstants.VEHICLE_THUNDERBOLT_V8,
		UrbanConstants.VEHICLE_SPECTER_R,
		UrbanConstants.VEHICLE_RIDGEBACK_4X4,
		UrbanConstants.VEHICLE_VALIANT_COUPE
	]

static func get_all_vehicle_ids() -> Array[String]:
	return [
		UrbanConstants.VEHICLE_VORTEX_GT,
		UrbanConstants.VEHICLE_THUNDERBOLT_V8,
		UrbanConstants.VEHICLE_SPECTER_R,
		UrbanConstants.VEHICLE_RIDGEBACK_4X4,
		UrbanConstants.VEHICLE_VALIANT_COUPE,
		UrbanConstants.VEHICLE_NYC_TAXI,
		UrbanConstants.VEHICLE_COMPACT_HATCH,
		UrbanConstants.VEHICLE_BOX_TRUCK,
		UrbanConstants.VEHICLE_POLICE_CRUISER
	]

static func get_vehicle_def(vehicle_id: String) -> Dictionary:
	match vehicle_id:
		UrbanConstants.VEHICLE_VORTEX_GT:
			return {
				"id": UrbanConstants.VEHICLE_VORTEX_GT,
				"name": "Apex GT",
				"category": "Player Sports Supercar",
				"desc": "Mid-engine aerodynamic masterpiece with fastback rear louvers, integrated wing, and quad circular taillights.",
				"top_speed": 68.0,          # ~245 km/h
				"acceleration": 34.0,        # m/s² (0-60 km/h in ~1.7s)
				"brake_force": 48.0,         # m/s²
				"steer_speed": 4.5,
				"max_steer_angle_deg": 34.0, # ±34° at low speed
				"min_steer_angle_deg": 10.0, # ±10° at 160 km/h
				"mass": 1250.0,
				"drift_factor": 1.30,
				"suspension_stiffness": 50.0,
				"suspension_damping": 4.5,
				"rest_length": 0.62,
				"max_travel": 0.22,
				"nitro_force": 30.0,
				"nitro_duration": 4.0,
				"default_color": Color(0.08, 0.45, 0.95), # Reference electric blue
				"cost": 120000,
				"dimensions": Vector3(1.95, 1.15, 4.45)
			}

		UrbanConstants.VEHICLE_SPECTER_R:
			return {
				"id": UrbanConstants.VEHICLE_SPECTER_R,
				"name": "Specter R",
				"category": "Sport Tuner Coupe",
				"desc": "Precision Japanese street tuner built for hairpins, high-RPM drift slides, and instant throttle response.",
				"top_speed": 62.0,          # ~223 km/h
				"acceleration": 30.0,
				"brake_force": 44.0,
				"steer_speed": 4.8,
				"max_steer_angle_deg": 34.0,
				"min_steer_angle_deg": 10.0,
				"mass": 1120.0,
				"drift_factor": 1.45,
				"suspension_stiffness": 50.0,
				"suspension_damping": 4.5,
				"rest_length": 0.60,
				"max_travel": 0.22,
				"nitro_force": 28.0,
				"nitro_duration": 4.2,
				"default_color": Color(0.96, 0.85, 0.1),
				"cost": 65000,
				"dimensions": Vector3(1.88, 1.22, 4.35)
			}

		UrbanConstants.VEHICLE_NYC_TAXI:
			return {
				"id": UrbanConstants.VEHICLE_NYC_TAXI,
				"name": "Empire Crown / NYC Taxi",
				"category": "4-Door Executive Sedan",
				"desc": "Iconic yellow metropolitan taxicab and executive sedan with durable V6 drivetrain and plush suspension.",
				"top_speed": 58.0,          # ~208 km/h
				"acceleration": 27.0,
				"brake_force": 39.0,
				"steer_speed": 4.0,
				"max_steer_angle_deg": 32.0,
				"min_steer_angle_deg": 11.0,
				"mass": 1620.0,
				"drift_factor": 1.15,
				"suspension_stiffness": 48.0,
				"suspension_damping": 4.8,
				"rest_length": 0.68,
				"max_travel": 0.28,
				"nitro_force": 22.0,
				"nitro_duration": 3.8,
				"default_color": Color(0.98, 0.78, 0.08), # NYC Yellow Cab
				"cost": 45000,
				"dimensions": Vector3(2.0, 1.35, 4.75)
			}

		UrbanConstants.VEHICLE_COMPACT_HATCH:
			return {
				"id": UrbanConstants.VEHICLE_COMPACT_HATCH,
				"name": "Pulse GT",
				"category": "Compact Hatchback",
				"desc": "Nimble urban hot hatch built for darting through traffic gaps and tight alley maneuvers.",
				"top_speed": 55.0,          # ~198 km/h
				"acceleration": 28.0,
				"brake_force": 42.0,
				"steer_speed": 4.6,
				"max_steer_angle_deg": 34.0,
				"min_steer_angle_deg": 12.0,
				"mass": 1080.0,
				"drift_factor": 1.25,
				"suspension_stiffness": 50.0,
				"suspension_damping": 4.5,
				"rest_length": 0.60,
				"max_travel": 0.24,
				"nitro_force": 24.0,
				"nitro_duration": 4.0,
				"default_color": Color(0.15, 0.75, 0.85),
				"cost": 38000,
				"dimensions": Vector3(1.85, 1.25, 4.15)
			}

		UrbanConstants.VEHICLE_RIDGEBACK_4X4:
			return {
				"id": UrbanConstants.VEHICLE_RIDGEBACK_4X4,
				"name": "Ridgeback 4x4",
				"category": "Full-Size SUV",
				"desc": "High ground clearance, heavy-duty suspension travel, and unstoppable curb-mounting power.",
				"top_speed": 54.0,          # ~194 km/h
				"acceleration": 26.0,
				"brake_force": 38.0,
				"steer_speed": 3.8,
				"max_steer_angle_deg": 30.0,
				"min_steer_angle_deg": 10.0,
				"mass": 2250.0,
				"drift_factor": 1.05,
				"suspension_stiffness": 50.0,
				"suspension_damping": 5.0,
				"rest_length": 0.78,
				"max_travel": 0.36,
				"nitro_force": 24.0,
				"nitro_duration": 4.5,
				"default_color": Color(0.22, 0.55, 0.26),
				"cost": 72000,
				"dimensions": Vector3(2.1, 1.65, 4.8)
			}

		UrbanConstants.VEHICLE_BOX_TRUCK:
			return {
				"id": UrbanConstants.VEHICLE_BOX_TRUCK,
				"name": "HaulMaster Cargo",
				"category": "Box Delivery Truck",
				"desc": "Heavy commercial logistics vehicle with high torque diesel engine and cavernous cargo bay.",
				"top_speed": 46.0,          # ~165 km/h
				"acceleration": 20.0,
				"brake_force": 34.0,
				"steer_speed": 3.2,
				"max_steer_angle_deg": 28.0,
				"min_steer_angle_deg": 9.0,
				"mass": 3600.0,
				"drift_factor": 0.85,
				"suspension_stiffness": 50.0,
				"suspension_damping": 5.0,
				"rest_length": 0.82,
				"max_travel": 0.36,
				"nitro_force": 20.0,
				"nitro_duration": 5.0,
				"default_color": Color(0.92, 0.55, 0.12),
				"cost": 55000,
				"dimensions": Vector3(2.35, 2.75, 6.4)
			}

		UrbanConstants.VEHICLE_POLICE_CRUISER:
			return {
				"id": UrbanConstants.VEHICLE_POLICE_CRUISER,
				"name": "Interceptor V8",
				"category": "Police Cruiser / Transit",
				"desc": "High-output law enforcement interceptor with flashing red/blue lightbars, push-bumper, and pursuit tune.",
				"top_speed": 66.0,          # ~238 km/h
				"acceleration": 32.0,
				"brake_force": 46.0,
				"steer_speed": 4.4,
				"max_steer_angle_deg": 33.0,
				"min_steer_angle_deg": 11.0,
				"mass": 1750.0,
				"drift_factor": 1.25,
				"suspension_stiffness": 50.0,
				"suspension_damping": 4.8,
				"rest_length": 0.65,
				"max_travel": 0.28,
				"nitro_force": 30.0,
				"nitro_duration": 4.0,
				"default_color": Color(0.10, 0.10, 0.12), # Black & White
				"cost": 90000,
				"dimensions": Vector3(2.05, 1.40, 4.85)
			}

		UrbanConstants.VEHICLE_THUNDERBOLT_V8:
			return {
				"id": UrbanConstants.VEHICLE_THUNDERBOLT_V8,
				"name": "Thunderbolt V8",
				"category": "American Muscle",
				"desc": "Raw rear-wheel torque, roaring big-block exhaust, and long sweeping drift power.",
				"top_speed": 63.0,          # ~227 km/h
				"acceleration": 30.0,
				"brake_force": 38.0,
				"steer_speed": 4.0,
				"max_steer_angle_deg": 30.0,
				"min_steer_angle_deg": 11.0,
				"mass": 1580.0,
				"drift_factor": 1.60,
				"suspension_stiffness": 50.0,
				"suspension_damping": 4.6,
				"rest_length": 0.65,
				"max_travel": 0.28,
				"nitro_force": 34.0,
				"nitro_duration": 3.5,
				"default_color": Color(0.92, 0.15, 0.12),
				"cost": 85000,
				"dimensions": Vector3(2.0, 1.28, 4.7)
			}

		UrbanConstants.VEHICLE_VALIANT_COUPE:
			return {
				"id": UrbanConstants.VEHICLE_VALIANT_COUPE,
				"name": "Valiant Coupe",
				"category": "Classic Cruiser",
				"desc": "Plush 1970s luxury touring coupe with smooth road glide and iconic chrome lines.",
				"top_speed": 56.0,          # ~200 km/h
				"acceleration": 26.0,
				"brake_force": 35.0,
				"steer_speed": 3.6,
				"max_steer_angle_deg": 29.0,
				"min_steer_angle_deg": 11.0,
				"mass": 1460.0,
				"drift_factor": 1.20,
				"suspension_stiffness": 50.0,
				"suspension_damping": 4.5,
				"rest_length": 0.68,
				"max_travel": 0.30,
				"nitro_force": 24.0,
				"nitro_duration": 3.8,
				"default_color": Color(0.85, 0.85, 0.88),
				"cost": 50000,
				"dimensions": Vector3(1.98, 1.32, 4.85)
			}

		_:
			# Fallback to Apex GT
			return get_vehicle_def(UrbanConstants.VEHICLE_VORTEX_GT)
