class_name StrikeBossBase
extends CharacterBody3D

## Base boss entity for Strike Vector.
## Implements: TELEGRAPH -> ATTACK -> EVADE/COUNTER -> WEAKNESS EXPOSED -> PHASE TRANSITION -> DEFEATED.
## Multi-phase mechanics, dynamic weakpoint states, and phase transitions.

signal boss_health_changed(current: float, max_val: float, phase: int, total_phases: int)
signal phase_changed(new_phase: int)
signal weakness_exposed(is_exposed: bool)
signal boss_defeated(boss_name: String, score_reward: int)

enum BossState {
	INTRO,
	TELEGRAPH,
	ATTACK,
	EVADE_COUNTER,
	WEAKNESS_EXPOSED,
	PHASE_TRANSITION,
	DEFEATED
}

const WeaponProjectileScript = preload("res://games/strike-vector/weapons/weapon_projectile.gd")

@export var boss_id: String = "boss_base"
@export var boss_name: String = "Strike Boss"
@export var total_phases: int = 2
@export var max_health_per_phase: float = 500.0
@export var score_value: int = 5000

var current_phase: int = 1
var current_health: float = 500.0
var current_state: BossState = BossState.TELEGRAPH
var state_timer: float = 0.0
var is_alive: bool = true
var target_player: Node3D = null

# Weakpoint & Shield state
var is_shielded: bool = false
var is_weakness_vulnerable: bool = false
var weakness_timer: float = 0.0
const WEAKNESS_EXPOSED_DURATION: float = 6.0

# Visual nodes
var visual_root: Node3D
var telegraph_indicator: MeshInstance3D
var coolant_core: MeshInstance3D

func _init() -> void:
	_setup_boss_visual()
	_setup_collision()

func _ready() -> void:
	add_to_group("bosses")
	add_to_group("enemies")
	collision_layer = GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_PROJECTILES

	current_health = max_health_per_phase
	_setup_boss_visual()
	_setup_collision()

func _setup_boss_visual() -> void:
	if visual_root != null:
		return
	visual_root = Node3D.new()
	visual_root.name = "BossVisual"
	add_child(visual_root)

	# Telegraph warning laser / circle
	telegraph_indicator = MeshInstance3D.new()
	telegraph_indicator.name = "Telegraph"
	var cyl = CylinderMesh.new()
	cyl.top_radius = 4.0
	cyl.bottom_radius = 4.0
	cyl.height = 0.1
	telegraph_indicator.mesh = cyl
	var mat_tel = StandardMaterial3D.new()
	mat_tel.albedo_color = Color(1.0, 0.1, 0.1, 0.45)
	mat_tel.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_tel.emission_enabled = true
	mat_tel.emission = Color(1.0, 0.1, 0.1)
	telegraph_indicator.material_override = mat_tel
	telegraph_indicator.visible = false
	add_child(telegraph_indicator)

func _setup_collision() -> void:
	if has_node("CollisionShape"):
		return
	var col = CollisionShape3D.new()
	col.name = "CollisionShape"
	var box = BoxShape3D.new()
	box.size = Vector3(4.0, 4.0, 4.0)
	col.shape = box
	col.position = Vector3(0, 2.0, 0)
	add_child(col)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_find_player()
	state_timer += delta

	match current_state:
		BossState.TELEGRAPH:
			_process_telegraph(delta)
		BossState.ATTACK:
			_process_attack(delta)
		BossState.EVADE_COUNTER:
			_process_evade(delta)
		BossState.WEAKNESS_EXPOSED:
			_process_weakness_exposed(delta)
		BossState.PHASE_TRANSITION:
			_process_phase_transition(delta)

	move_and_slide()

func _find_player() -> void:
	if is_instance_valid(target_player):
		return
	var p_list = get_tree().get_nodes_in_group("players") if get_tree() else []
	if not p_list.is_empty() and is_instance_valid(p_list[0]):
		target_player = p_list[0]

func _process_telegraph(delta: float) -> void:
	telegraph_indicator.visible = true
	if is_instance_valid(target_player):
		telegraph_indicator.global_position = target_player.global_position + Vector3(0, 0.05, 0)
		_turn_toward(target_player.global_position, delta)

	if state_timer >= 1.6:
		telegraph_indicator.visible = false
		set_state(BossState.ATTACK)

func _process_attack(delta: float) -> void:
	if is_instance_valid(target_player):
		_turn_toward(target_player.global_position, delta)

	# Subclasses execute specific signature attacks here
	_execute_boss_attack_pattern(delta)

	if state_timer >= 4.0:
		set_state(BossState.EVADE_COUNTER)

func _process_evade(delta: float) -> void:
	# Retract, activate shields, spawn hazards
	is_shielded = true
	if state_timer >= 3.0:
		is_shielded = false
		set_state(BossState.WEAKNESS_EXPOSED)

func _process_weakness_exposed(delta: float) -> void:
	is_weakness_vulnerable = true
	weakness_timer += delta
	weakness_exposed.emit(true)

	if is_instance_valid(coolant_core):
		coolant_core.visible = true

	if weakness_timer >= WEAKNESS_EXPOSED_DURATION:
		is_weakness_vulnerable = false
		weakness_timer = 0.0
		weakness_exposed.emit(false)
		if is_instance_valid(coolant_core):
			coolant_core.visible = false
		set_state(BossState.TELEGRAPH)

func _process_phase_transition(delta: float) -> void:
	if delta > 0.0 and state_timer < delta:
		state_timer = delta
	# Invulnerable recovery & power up animation
	if state_timer >= 2.5:
		current_phase += 1
		current_health = max_health_per_phase
		phase_changed.emit(current_phase)
		boss_health_changed.emit(current_health, max_health_per_phase, current_phase, total_phases)
		set_state(BossState.TELEGRAPH)

func _execute_boss_attack_pattern(_delta: float) -> void:
	# Default barrage pattern (subclasses can override)
	if int(state_timer * 10) % 6 == 0 and is_instance_valid(target_player):
		var dir = (target_player.global_position + Vector3(0, 1.0, 0) - global_position).normalized()
		var proj = WeaponProjectileScript.new()
		proj.position = global_position + Vector3(0, 2.0, 0) + dir * 2.0
		proj.shooter = self
		proj.init_projectile(dir, 85.0, 18.0, Color(1.0, 0.4, 0.1), boss_name, true, 3.5)
		var scene_root = get_tree().current_scene if get_tree() else get_parent()
		if scene_root:
			scene_root.add_child(proj)

func take_damage(amount: float, _dealer_name: String = "", _weapon: String = "") -> void:
	if not is_alive or current_state == BossState.PHASE_TRANSITION:
		return

	if is_shielded:
		# Deflect attack
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am and am.has_method("play_sound"):
			am.play_sound("hit", 0.7)
		return

	var multiplier = 2.5 if is_weakness_vulnerable else 1.0
	current_health = maxf(0.0, current_health - amount * multiplier)
	boss_health_changed.emit(current_health, max_health_per_phase, current_phase, total_phases)

	var am = GameConstants.get_autoload(self, "AudioManager")
	if am and am.has_method("play_sound"):
		am.play_sound("hit", 1.2)

	if current_health <= 0.0:
		if current_phase < total_phases:
			set_state(BossState.PHASE_TRANSITION)
		else:
			_defeat()

func _defeat() -> void:
	is_alive = false
	current_state = BossState.DEFEATED
	boss_defeated.emit(boss_name, score_value)

	if is_instance_valid(target_player) and target_player.has_method("register_kill"):
		target_player.register_kill(score_value)

	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus:
		bus.enemy_died.emit(boss_name, score_value)

	# Victory explosion sequence
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func set_state(new_state: BossState) -> void:
	current_state = new_state
	state_timer = 0.0

func _turn_toward(target_pos: Vector3, delta: float) -> void:
	var look_pos = target_pos
	look_pos.y = global_position.y
	if global_position.distance_squared_to(look_pos) > 0.1:
		var target_basis = Basis.looking_at(look_pos - global_position, Vector3.UP)
		transform.basis = transform.basis.slerp(target_basis, 6.0 * delta)
