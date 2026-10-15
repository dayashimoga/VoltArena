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

static func get_vehicle_def(vehicle_id: String) -> Dictionary:
	match vehicle_id:
		UrbanConstants.VEHICLE_VORTEX_GT:
			return {
				"id": UrbanConstants.VEHICLE_VORTEX_GT,
				"name": "Vortex GT",
				"category": "Exotic Supercar",
				"desc": "Mid-engine aerodynamic masterpiece with twin-turbo acceleration and razor-sharp cornering.",
				"top_speed": 68.0,          # ~245 km/h
				"acceleration": 32.0,        # m/s² (0-60 km/h in ~1.8s)
				"brake_force": 46.0,         # m/s²
				"steer_speed": 4.5,
				"max_steer_angle_deg": 33.0,
				"min_steer_angle_deg": 12.0,
				"mass": 1250.0,
				"drift_factor": 1.25,
				"suspension_stiffness": 22.0,
				"suspension_damping": 4.2,
				"rest_length": 0.62,
				"max_travel": 0.26,
				"nitro_force": 28.0,
				"nitro_duration": 4.0,
				"default_color": Color(0.08, 0.45, 0.95), # Reference electric blue
				"cost": 120000,
				"dimensions": Vector3(1.95, 1.15, 4.45)
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
				"suspension_stiffness": 18.0,
				"suspension_damping": 3.8,
				"rest_length": 0.65,
				"max_travel": 0.28,
				"nitro_force": 34.0,
				"nitro_duration": 3.5,
				"default_color": Color(0.92, 0.15, 0.12),
				"cost": 85000,
				"dimensions": Vector3(2.0, 1.28, 4.7)
			}

		UrbanConstants.VEHICLE_SPECTER_R:
			return {
				"id": UrbanConstants.VEHICLE_SPECTER_R,
				"name": "Specter R",
				"category": "Street Tuner",
				"desc": "Featherweight Japanese street tuner built for hairpins, precision drift, and high RPMs.",
				"top_speed": 61.0,          # ~220 km/h
				"acceleration": 29.0,
				"brake_force": 43.0,
				"steer_speed": 4.8,
				"max_steer_angle_deg": 35.0,
				"min_steer_angle_deg": 13.0,
				"mass": 1120.0,
				"drift_factor": 1.45,
				"suspension_stiffness": 24.0,
				"suspension_damping": 4.5,
				"rest_length": 0.60,
				"max_travel": 0.24,
				"nitro_force": 26.0,
				"nitro_duration": 4.2,
				"default_color": Color(0.96, 0.85, 0.1),
				"cost": 65000,
				"dimensions": Vector3(1.88, 1.22, 4.35)
			}

		UrbanConstants.VEHICLE_RIDGEBACK_4X4:
			return {
				"id": UrbanConstants.VEHICLE_RIDGEBACK_4X4,
				"name": "Ridgeback 4x4",
				"category": "All-Terrain SUV",
				"desc": "High ground clearance, heavy duty suspension, and unstoppable hill climb capability.",
				"top_speed": 53.0,          # ~190 km/h
				"acceleration": 25.0,
				"brake_force": 36.0,
				"steer_speed": 3.8,
				"max_steer_angle_deg": 31.0,
				"min_steer_angle_deg": 12.0,
				"mass": 2150.0,
				"drift_factor": 1.05,
				"suspension_stiffness": 15.0,
				"suspension_damping": 3.2,
				"rest_length": 0.78,
				"max_travel": 0.35,
				"nitro_force": 22.0,
				"nitro_duration": 4.5,
				"default_color": Color(0.22, 0.55, 0.26),
				"cost": 72000,
				"dimensions": Vector3(2.1, 1.65, 4.8)
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
				"suspension_stiffness": 16.0,
				"suspension_damping": 3.4,
				"rest_length": 0.68,
				"max_travel": 0.30,
				"nitro_force": 24.0,
				"nitro_duration": 3.8,
				"default_color": Color(0.85, 0.85, 0.88),
				"cost": 50000,
				"dimensions": Vector3(1.98, 1.32, 4.85)
			}

		_:
			# Fallback to Vortex GT
			return get_vehicle_def(UrbanConstants.VEHICLE_VORTEX_GT)
