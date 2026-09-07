class_name PhotographySystem
extends RefCounted

## PhotographySystem: Viewfinder & Rigorous Photo Scoring Engine for WildCircuit.
## Evaluates Framing, Line-of-Sight Visibility, Subject Distance, Behavior, and Species Rarity.

const AnimalDataScript = preload("res://games/wildcircuit/animals/animal_data.gd")

static func score_photograph(camera: Camera3D, animal: Node3D, space_state: PhysicsDirectSpaceState3D) -> Dictionary:
	if not is_instance_valid(camera) or not is_instance_valid(animal):
		return {"valid": false, "reason": "No subject in view"}

	var cam_pos = camera.global_position
	var animal_pos = animal.global_position + Vector3(0, 0.6, 0)
	var to_animal = animal_pos - cam_pos
	var distance = to_animal.length()

	# 1. Line-of-Sight Visibility Check (Reject obstructed photos)
	var ray_query = PhysicsRayQueryParameters3D.create(cam_pos, animal_pos)
	ray_query.collision_mask = GameConstants.LAYER_WORLD
	var hit = space_state.intersect_ray(ray_query)
	if not hit.is_empty() and hit.position.distance_to(animal_pos) > 1.2:
		return {
			"valid": false,
			"score": 0,
			"grade": "Obstructed",
			"reason": "Subject obstructed by terrain or vegetation"
		}

	# 2. Viewport Frustum & Framing Centering Score (0 to 30 pts)
	var screen_pos = camera.unproject_position(animal_pos)
	var vp_size = camera.get_viewport().get_visible_rect().size
	var center = vp_size * 0.5
	var dist_from_center = screen_pos.distance_to(center)
	var max_center_dist = vp_size.length() * 0.5
	var centering_factor = clampf(1.0 - (dist_from_center / max_center_dist), 0.0, 1.0)
	var framing_score = centering_factor * 30.0

	# 3. Distance & Clarity Score (0 to 35 pts)
	# Ideal distance: 5.0m to 14.0m
	var distance_score = 0.0
	if distance < 3.0:
		distance_score = 15.0 # Too close / startled
	elif distance >= 3.0 and distance <= 15.0:
		distance_score = 35.0 - abs(distance - 8.0) * 1.5
	elif distance <= 35.0:
		distance_score = maxf(5.0, 35.0 - (distance - 15.0) * 1.2)
	else:
		distance_score = 5.0 # Extremely far

	# 4. Species Rarity Multiplier
	var species_id = animal.get("species_id") if "species_id" in animal else "gazelle"
	var sp_info = AnimalDataScript.get_species(species_id)
	var rarity = sp_info.get("rarity", "common")
	var rarity_mult = 1.0
	match rarity:
		"uncommon": rarity_mult = 1.3
		"rare": rarity_mult = 1.7
		"legendary": rarity_mult = 2.2

	# 5. Behavior Multiplier
	var behavior_name = "Active"
	var behavior_mult = 1.0
	if animal.has_method("get_current_behavior_name"):
		behavior_name = animal.get_current_behavior_name()
	var state_val = animal.get("current_state") if "current_state" in animal else 0
	match state_val:
		2, 3: # Graze / Drink
			behavior_mult = 1.35
		4: # Sleep
			behavior_mult = 1.25
		6: # Investigate
			behavior_mult = 1.45
		7: # Flee / Leaping
			behavior_mult = 1.55

	var raw_score = (framing_score + distance_score) * rarity_mult * behavior_mult
	var final_score = mini(100, int(raw_score))

	var grade = "Bronze"
	if final_score >= 88:
		grade = "Platinum"
	elif final_score >= 72:
		grade = "Gold"
	elif final_score >= 50:
		grade = "Silver"

	return {
		"valid": true,
		"score": final_score,
		"grade": grade,
		"species_id": species_id,
		"species_name": sp_info.get("name", "Unknown"),
		"biome": sp_info.get("biome", "savannah"),
		"behavior": behavior_name,
		"distance": "%.1f m" % distance,
		"framing_score": int(framing_score),
		"distance_score": int(distance_score)
	}
