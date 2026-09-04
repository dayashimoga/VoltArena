class_name GameConstants
extends Node

static func get_autoload(caller: Node, name: String) -> Node:
	var loop = Engine.get_main_loop()
	if loop is SceneTree and loop.root:
		return loop.root.get_node_or_null(name)
	if caller and caller.is_inside_tree():
		var tree = caller.get_tree()
		if tree and tree.root:
			return tree.root.get_node_or_null(name)
	return null

# Platform Game Identifiers
const GAME_ARENA_FPS: String = "arena_fps"
const GAME_SUBWAY_SURVIVAL: String = "subway_survival"
const GAME_ROCKET_CAR: String = "rocket_car"
const GAME_KART_RACING: String = "kart_racing"

# Game States
enum GameState {
	INITIALIZING,
	LOADING,
	MENU,
	COUNTDOWN,
	PLAYING,
	PAUSED,
	GAME_OVER,
	RESULTS
}

# Quality Presets
enum QualityPreset {
	LOW,
	MEDIUM,
	HIGH,
	ULTRA,
	AUTO
}

# Difficulty Levels
enum Difficulty {
	EASY,
	NORMAL,
	HARD,
	NIGHTMARE
}

# Collision Layers (3D Physics)
const LAYER_WORLD: int = 1         # 1 << 0: Static level geometry
const LAYER_PLAYER: int = 2        # 1 << 1: Player character / vehicle
const LAYER_ENEMIES: int = 4       # 1 << 2: AI opponents / bots / monsters
const LAYER_PROJECTILES: int = 8   # 1 << 3: Bullets, rockets, projectiles
const LAYER_PICKUPS: int = 16      # 1 << 4: Ammo, health, powerups
const LAYER_BALL: int = 32         # 1 << 5: Physics sports ball
const LAYER_GOALS: int = 64        # 1 << 6: Goal trigger zones
const LAYER_CHECKPOINTS: int = 128 # 1 << 7: Racing checkpoints

# Performance Budgets
const TARGET_FPS_DESKTOP: float = 60.0
const TARGET_FPS_WEB: float = 60.0
const TARGET_FPS_MOBILE: float = 60.0
const MAX_PHYSICS_TICKS_PER_SEC: int = 60

# Cloudflare & Asset Budgets
const MAX_CLOUDFLARE_FILE_BYTES: int = 25 * 1024 * 1024 # 25 MB
