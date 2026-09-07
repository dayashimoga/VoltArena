class_name InteractionArea3D
extends Area3D

## Reusable 3D Interaction Trigger Area for NPCs, chests, terminals, and puzzle objects.

signal player_entered(player: Node3D)
signal player_exited(player: Node3D)
signal interacted(player: Node3D)

@export var prompt_message: String = "Press E to Interact"
@export var interaction_distance: float = 2.5
@export var is_enabled: bool = true

var active_player: Node3D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = GameConstants.LAYER_PLAYER

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if not is_enabled:
		return
	if body.is_in_group("players") or body.name == "Player":
		active_player = body
		player_entered.emit(body)
		var bus = GameConstants.get_autoload(self, "EventBus")
		if bus:
			bus.show_toast_requested.emit(prompt_message, Color(1.0, 0.9, 0.4))

func _on_body_exited(body: Node3D) -> void:
	if body == active_player:
		active_player = null
		player_exited.emit(body)

func _unhandled_input(event: InputEvent) -> void:
	if not is_enabled or not active_player:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		interact(active_player)

func interact(interactor: Node3D) -> void:
	if not is_enabled:
		return
	interacted.emit(interactor)
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("pickup_health", 1.1, 1.0)
