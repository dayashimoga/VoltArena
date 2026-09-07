class_name RobotData
extends RefCounted

## RobotData: Data-driven Component Catalog & Stat Calculation System for RoboForge Arena.
## Defines Chassis, Locomotion, Power Cores, and Utility Modules with real physical parameters.

const CHASSIS = {
	"scout": {
		"id": "scout",
		"name": "Scout Mk-I",
		"desc": "Lightweight agile carbon chassis with high speed potential.",
		"mass": 140.0,
		"power_capacity": 120.0,
		"max_modules": 2,
		"durability": 150.0,
		"color": Color(0.2, 0.9, 1.0)
	},
	"combat": {
		"id": "combat",
		"name": "Enforcer Mk-II",
		"desc": "Balanced reinforced chassis for multipurpose engineering and transport.",
		"mass": 320.0,
		"power_capacity": 240.0,
		"max_modules": 3,
		"durability": 300.0,
		"color": Color(1.0, 0.6, 0.1)
	},
	"titan": {
		"id": "titan",
		"name": "Titan Hauler",
		"desc": "Ultra-heavy industrial frame with massive cargo stability.",
		"mass": 650.0,
		"power_capacity": 420.0,
		"max_modules": 4,
		"durability": 600.0,
		"color": Color(0.9, 0.2, 0.2)
	}
}

const LOCOMOTION = {
	"wheels": {
		"id": "wheels",
		"name": "High-Speed Wheels",
		"desc": "All-surface racing slicks with superior forward velocity on flat courses.",
		"mass": 80.0,
		"top_speed": 22.0,
		"acceleration": 28.0,
		"grip": 0.85,
		"turning_speed": 2.8,
		"jump_force": 0.0,
		"power_draw": 25.0
	},
	"tracks": {
		"id": "tracks",
		"name": "Reinforced Treads",
		"desc": "Heavy-duty caterpillar tracks with immense torque on steep inclines and debris.",
		"mass": 190.0,
		"top_speed": 14.0,
		"acceleration": 36.0,
		"grip": 1.45,
		"turning_speed": 2.2,
		"jump_force": 0.0,
		"power_draw": 45.0
	},
	"legs": {
		"id": "legs",
		"name": "Articulated Quad Legs",
		"desc": "Hydraulic multi-jointed walking legs with jumping and precision footing.",
		"mass": 140.0,
		"top_speed": 11.0,
		"acceleration": 22.0,
		"grip": 1.15,
		"turning_speed": 3.4,
		"jump_force": 10.5,
		"power_draw": 40.0
	}
}

const POWER_CORES = {
	"battery_pack": {
		"id": "battery_pack",
		"name": "Lithium Battery Pack",
		"desc": "Lightweight baseline energy storage.",
		"mass": 40.0,
		"power_capacity": 100.0,
		"recharge_rate": 12.0
	},
	"fission_cell": {
		"id": "fission_cell",
		"name": "Fission Micro-Cell",
		"desc": "High capacity cell for energy-hungry module suites.",
		"mass": 90.0,
		"power_capacity": 220.0,
		"recharge_rate": 24.0
	},
	"fusion_reactor": {
		"id": "fusion_reactor",
		"name": "Compact Fusion Core",
		"desc": "Heavy reactor with limitless sustained power delivery.",
		"mass": 170.0,
		"power_capacity": 420.0,
		"recharge_rate": 45.0
	}
}

const MODULES = {
	"hydraulic_grabber": {
		"id": "hydraulic_grabber",
		"name": "Hydraulic Grabber Claw",
		"desc": "Mechanical claw that grips and carries physics crates and energy cores.",
		"mass": 55.0,
		"power_draw": 20.0,
		"socket_type": "front"
	},
	"magnetic_arm": {
		"id": "magnetic_arm",
		"name": "Magnetic Crane Arm",
		"desc": "Powerful electromagnet pulling metal cargo objects from up to 5 meters.",
		"mass": 65.0,
		"power_draw": 35.0,
		"socket_type": "top"
	},
	"rocket_booster": {
		"id": "rocket_booster",
		"name": "Nitrous Rocket Booster",
		"desc": "Provides short supersonic forward thruster bursts.",
		"mass": 35.0,
		"power_draw": 45.0,
		"socket_type": "rear"
	},
	"cargo_bed": {
		"id": "cargo_bed",
		"name": "Heavy Cargo Mount",
		"desc": "Flatbed container socket for hauling heavy crates safely.",
		"mass": 40.0,
		"power_draw": 5.0,
		"socket_type": "rear"
	},
	"kinetic_shield": {
		"id": "kinetic_shield",
		"name": "Kinetic Deflector Shield",
		"desc": "Energy barrier deflecting physical impacts and hazard lasers.",
		"mass": 50.0,
		"power_draw": 40.0,
		"socket_type": "top"
	}
}

static func get_default_blueprint() -> Dictionary:
	return {
		"blueprint_name": "Standard Scout",
		"chassis": "scout",
		"locomotion": "wheels",
		"power_core": "battery_pack",
		"modules": ["hydraulic_grabber", "rocket_booster"]
	}

static func calculate_stats(blueprint: Dictionary) -> Dictionary:
	var ch_id = blueprint.get("chassis", "scout")
	var loc_id = blueprint.get("locomotion", "wheels")
	var pwr_id = blueprint.get("power_core", "battery_pack")
	var mod_list: Array = blueprint.get("modules", [])

	var ch = CHASSIS.get(ch_id, CHASSIS["scout"])
	var loc = LOCOMOTION.get(loc_id, LOCOMOTION["wheels"])
	var pwr = POWER_CORES.get(pwr_id, POWER_CORES["battery_pack"])

	var total_mass = ch.mass + loc.mass + pwr.mass
	var total_power_draw = loc.power_draw

	for m_id in mod_list:
		if MODULES.has(m_id):
			var m = MODULES[m_id]
			total_mass += m.mass
			total_power_draw += m.power_draw

	var mass_factor = 450.0 / (450.0 + total_mass * 0.45)
	var effective_speed = loc.top_speed * mass_factor
	var effective_accel = loc.acceleration * (350.0 / total_mass)
	var net_power = pwr.power_capacity - total_power_draw

	return {
		"total_mass": total_mass,
		"power_capacity": pwr.power_capacity,
		"power_draw": total_power_draw,
		"net_power": net_power,
		"recharge_rate": pwr.recharge_rate,
		"top_speed": effective_speed,
		"acceleration": effective_accel,
		"grip": loc.grip,
		"turning_speed": loc.turning_speed,
		"jump_force": loc.jump_force,
		"durability": ch.durability,
		"is_valid": net_power >= 0.0 and mod_list.size() <= ch.max_modules
	}
