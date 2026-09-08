class_name MissionDefinitions
extends RefCounted

## Data definitions and segment factory for all 8 campaign missions in Strike Vector.

static func get_mission_meta(mission_idx: int) -> Dictionary:
	match mission_idx:
		1:
			return {
				"index": 1,
				"name": "Urban Blackout",
				"biome": "urban",
				"tagline": "City streets, rooftops & plaza evacuation",
				"desc": "Advance through blackout city streets, commercial plazas, and rooftops under hostile drone surveillance.",
				"objective": "DESTROY JAMMER & REACH EXTRACTION",
				"segments": [
					"City Streets Entry", "Narrow Alleys", "Commercial Interior", "Rooftop Catwalks", "Evacuation Plaza"
				]
			}
		2:
			return {
				"index": 2,
				"name": "High-Speed Rail",
				"biome": "rail",
				"tagline": "Moving passenger train & bridge assault",
				"desc": "Infiltrate a moving passenger express, fight through carriage interiors and train roofs, and eliminate the VTOL gunship.",
				"objective": "DEFEND TRAIN ROOF & DESTROY ATTACK VTOL",
				"segments": [
					"Station Platform", "Passenger Carriages", "Train Roof Hazard", "Cargo Flats", "Rail Bridge Approach"
				]
			}
		3:
			return {
				"index": 3,
				"name": "Harbor Assault",
				"biome": "harbor",
				"tagline": "Shipping container port & shipyard drydock",
				"desc": "Clear vertical container labyrinths, operate gantry crane drop events, and seize the container vessel bridge.",
				"objective": "SEIZE HARBOR & ELIMINATE GANTRY TITAN",
				"segments": [
					"Container Port", "Warehouse Complex", "Crane Yard Gantries", "Drydock Shipyard", "Cargo Vessel Deck"
				]
			}
		4:
			return {
				"index": 4,
				"name": "Desert Convoy",
				"biome": "desert",
				"tagline": "Canyon ambush & armored convoy pursuit",
				"desc": "Battle through canyon settlements, pursue the armored convoy at high speed, and dismantle the refinery complex.",
				"objective": "INTERCEPT CONVOY & DESTROY BATTLE RIG",
				"segments": [
					"Outpost Settlement", "Canyon Pass", "Moving Convoy", "Refinery Yard", "Pipeline Terminal"
				]
			}
		5:
			return {
				"index": 5,
				"name": "Arctic Installation",
				"biome": "arctic",
				"tagline": "Sub-zero blizzard & subterranean research facility",
				"desc": "Endure whiteout blizzards across frozen lakes, breach the underground laboratory, and disable the sub-zero walker.",
				"objective": "BREACH RESEARCH BASE & DESTROY WALKER",
				"segments": [
					"Blizzard Snowfield", "Perimeter Gate", "Sub-Surface Research Lab", "Ice Cavern", "Radar Launch Facility"
				]
			}
		6:
			return {
				"index": 6,
				"name": "Megafactory",
				"biome": "factory",
				"tagline": "Automated assembly floor & smelting furnaces",
				"desc": "Navigate industrial crushers, automated robot conveyor belts, and molten metal vats in the defense robot core.",
				"objective": "OVERLOAD CORE & DESTROY APEX DEFENSE ROBOT",
				"segments": [
					"Loading Docks", "Automated Assembly Line", "Stamping Floor", "Smelting Furnace", "Core Control Center"
				]
			}
		7:
			return {
				"index": 7,
				"name": "Sky Fortress",
				"biome": "sky_fortress",
				"tagline": "High-altitude platforms & aerial hangar assault",
				"desc": "Air-drop onto high-altitude exterior platforms, cross wind-buffeted antenna arrays, and overload the aerial core.",
				"objective": "OVERLOAD AERIAL CORE & SURVIVE DROP",
				"segments": [
					"Insertion Drop Deck", "Exterior Catwalks", "Hangar Deck", "Reactor Conduits", "Command Spire"
				]
			}
		8:
			return {
				"index": 8,
				"name": "Final Citadel",
				"biome": "citadel",
				"tagline": "Fortress siege, 3-phase overlord & timed extraction",
				"desc": "Storm the fortified trenches, ascend the grand citadel towers, eliminate the command overlord, and extract.",
				"objective": "DEFEAT CITADEL OVERLORD & EXTRACT",
				"segments": [
					"Outer Siege Trenches", "Vehicle Gatehouse", "Grand Fortress Hall", "Ascension Tower Lifts", "Apex Rooftop Extraction"
				]
			}
		_:
			return get_mission_meta(1)

const SegmentManagerScript = preload("res://games/strike-vector/campaign/segment_manager.gd")

static func build_mission_segments(mission_idx: int) -> Array:
	var meta = get_mission_meta(mission_idx)
	var biome: String = meta["biome"]
	var seg_names: Array = meta["segments"]
	var segments: Array = []

	var seg_length = 40.0
	for i in range(seg_names.size()):
		var seg = SegmentManagerScript.new()
		seg.name = "Segment_" + str(i + 1)
		seg.segment_name = seg_names[i]
		seg.segment_index = i
		seg.is_boss_segment = (i == seg_names.size() - 1)
		seg.is_setpiece_segment = (i == 1 or i == 3)

		# Position segments sequentially along -Z axis
		seg.position = Vector3(0, 0, -float(i) * seg_length)

		# Build modular environment geometry
		var env = StrikeEnvironmentBuilder.build_segment_environment(biome, i, seg_length, 14.0)
		seg.add_child(env)

		# Add Encounter Director
		var enc = EncounterDirector.new()
		enc.name = "EncounterDirector"
		enc.encounter_id = "enc_m%d_s%d" % [mission_idx, i + 1]
		enc.objective_text = meta["objective"]
		enc.score_reward = 800 * (i + 1)

		# Configure enemy spawns
		if seg.is_boss_segment:
			# Boss Encounter in Segment 5
			var boss = BossArchetypes.create_boss_by_mission(mission_idx)
			boss.position = Vector3(0, 0, -seg_length * 0.5)
			seg.add_child(boss)
		else:
			# Standard Forward Encounter
			enc.enemy_spawns = _get_default_spawns(mission_idx, i, seg_length)
			enc.reinforcement_waves = _get_reinforcement_spawns(mission_idx, i)

		seg.add_child(enc)
		seg.encounter_director = enc

		# Add Checkpoint trigger at segment entry
		seg.checkpoint_pos = seg.position + Vector3(0, 0.5, 0)

		# Add Destructible Props & World Pickups
		_populate_props_and_pickups(seg, seg_length)

		segments.append(seg)

	return segments

static func _get_default_spawns(m_idx: int, s_idx: int, len: float) -> Array[Dictionary]:
	var spawns: Array[Dictionary] = []
	var z_half = -len * 0.4
	match s_idx:
		0:
			spawns.append({"archetype": "rifle_trooper", "pos": Vector3(-3, 0, z_half)})
			spawns.append({"archetype": "rifle_trooper", "pos": Vector3(3, 0, z_half)})
		1:
			spawns.append({"archetype": "assault_rusher", "pos": Vector3(-2, 0, z_half)})
			spawns.append({"archetype": "combat_drone", "pos": Vector3(0, 2.0, z_half - 4)})
			spawns.append({"archetype": "rifle_trooper", "pos": Vector3(3, 0, z_half)})
		2:
			spawns.append({"archetype": "heavy", "pos": Vector3(0, 0, z_half)})
			spawns.append({"archetype": "marksman", "pos": Vector3(4, 0, z_half - 6)})
			spawns.append({"archetype": "shield_unit", "pos": Vector3(-3, 0, z_half)})
		3:
			spawns.append({"archetype": "grenadier", "pos": Vector3(-3, 0, z_half - 4)})
			spawns.append({"archetype": "turret", "pos": Vector3(3, 0, z_half - 6)})
			spawns.append({"archetype": "elite", "pos": Vector3(0, 0, z_half)})
		_:
			spawns.append({"archetype": "commander", "pos": Vector3(0, 0, z_half)})
			spawns.append({"archetype": "rifle_trooper", "pos": Vector3(-3, 0, z_half)})
			spawns.append({"archetype": "rifle_trooper", "pos": Vector3(3, 0, z_half)})
	return spawns

static func _get_reinforcement_spawns(m_idx: int, s_idx: int) -> Array[Array]:
	var waves: Array[Array] = []
	if s_idx >= 1:
		waves.append([
			{"archetype": "combat_drone", "pos": Vector3(-2, 1.8, -25)},
			{"archetype": "assault_rusher", "pos": Vector3(2, 0, -22)}
		])
	return waves

static func _populate_props_and_pickups(seg: SegmentManager, len: float) -> void:
	# Add Destructible Crate & Barrel
	var crate = DestructibleProp.new()
	crate.name = "Crate"
	crate.prop_type = DestructibleProp.PropType.CRATE
	crate.position = Vector3(-3.5, 0, -len * 0.25)
	seg.add_child(crate)

	var barrel = DestructibleProp.new()
	barrel.name = "ExplosiveBarrel"
	barrel.prop_type = DestructibleProp.PropType.EXPLOSIVE_BARREL
	barrel.position = Vector3(3.5, 0, -len * 0.45)
	seg.add_child(barrel)

	# Add Ammo / Health Pickup
	var pickup = StrikePickup.new()
	pickup.name = "Pickup_Ammo"
	pickup.pickup_category = StrikePickup.PickupCategory.AMMO
	pickup.pickup_type = "ammo_pack"
	pickup.pickup_value = 40
	pickup.position = Vector3(0, 0.5, -len * 0.3)
	seg.add_child(pickup)
