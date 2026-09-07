class_name AnimalData
extends RefCounted

## AnimalData: Data-driven Species Catalog & Behavior Attributes for WildCircuit.
## Covers 5 distinct biomes with rarity, scoring weights, preferred hours, and behaviors.

const SPECIES = {
	"gazelle": {
		"id": "gazelle",
		"name": "Thomson's Gazelle",
		"biome": "savannah",
		"rarity": "common",
		"base_score": 50,
		"flee_dist": 8.0,
		"scale": Vector3(0.8, 0.8, 0.9),
		"color": Color(0.82, 0.58, 0.35),
		"horn_color": Color(0.15, 0.15, 0.15),
		"has_horns": true,
		"desc": "Agile herbivore frequently grazing across the golden savannah."
	},
	"lion": {
		"id": "lion",
		"name": "Savannah Lion",
		"biome": "savannah",
		"rarity": "rare",
		"base_score": 90,
		"flee_dist": 5.0,
		"scale": Vector3(1.3, 1.1, 1.6),
		"color": Color(0.85, 0.65, 0.32),
		"has_horns": false,
		"desc": "Apex predator often found resting on sun-warmed rocky kopjes."
	},
	"jaguar": {
		"id": "jaguar",
		"name": "Emerald Jaguar",
		"biome": "rainforest",
		"rarity": "rare",
		"base_score": 95,
		"flee_dist": 6.0,
		"scale": Vector3(1.1, 0.95, 1.4),
		"color": Color(0.92, 0.72, 0.28),
		"has_horns": false,
		"desc": "Stealthy prowler navigating deep rainforest canopies and riverbanks."
	},
	"macaw": {
		"id": "macaw",
		"name": "Scarlet Macaw",
		"biome": "rainforest",
		"rarity": "uncommon",
		"base_score": 70,
		"flee_dist": 7.0,
		"scale": Vector3(0.5, 0.5, 0.6),
		"color": Color(0.95, 0.15, 0.15),
		"has_horns": false,
		"desc": "Vibrant avian perching high in rainforest branches."
	},
	"snow_leopard": {
		"id": "snow_leopard",
		"name": "Ghost of the Peaks (Snow Leopard)",
		"biome": "alpine",
		"rarity": "legendary",
		"base_score": 120,
		"flee_dist": 10.0,
		"scale": Vector3(1.1, 0.9, 1.35),
		"color": Color(0.90, 0.92, 0.95),
		"has_horns": false,
		"desc": "Elusive legendary feline traversing freezing alpine crags."
	},
	"mountain_goat": {
		"id": "mountain_goat",
		"name": "Alpine Ibex",
		"biome": "alpine",
		"rarity": "common",
		"base_score": 55,
		"flee_dist": 7.5,
		"scale": Vector3(0.9, 0.95, 1.1),
		"color": Color(0.75, 0.76, 0.78),
		"has_horns": true,
		"desc": "Remarkably surefooted climber navigating near-vertical rock faces."
	},
	"sea_turtle": {
		"id": "sea_turtle",
		"name": "Green Sea Turtle",
		"biome": "coast",
		"rarity": "uncommon",
		"base_score": 75,
		"flee_dist": 4.0,
		"scale": Vector3(1.2, 0.45, 1.3),
		"color": Color(0.35, 0.55, 0.32),
		"has_horns": false,
		"desc": "Ancient marine reptile gliding through coastal shallows and resting on dunes."
	},
	"crocodile": {
		"id": "crocodile",
		"name": "Marshland Crocodile",
		"biome": "wetlands",
		"rarity": "uncommon",
		"base_score": 80,
		"flee_dist": 5.0,
		"scale": Vector3(1.1, 0.4, 2.2),
		"color": Color(0.32, 0.38, 0.28),
		"has_horns": false,
		"desc": "Armored wetland resident basking quietly along muddy banks."
	},
	"flamingo": {
		"id": "flamingo",
		"name": "Greater Flamingo",
		"biome": "wetlands",
		"rarity": "common",
		"base_score": 60,
		"flee_dist": 6.5,
		"scale": Vector3(0.6, 1.4, 0.8),
		"color": Color(0.98, 0.52, 0.65),
		"has_horns": false,
		"desc": "Graceful wading flock bird filtering minerals in shallow wetland pools."
	}
}

static func get_species(species_id: String) -> Dictionary:
	return SPECIES.get(species_id, SPECIES["gazelle"])

static func get_species_for_biome(biome_name: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for sp in SPECIES.values():
		if sp["biome"] == biome_name:
			result.append(sp)
	return result
