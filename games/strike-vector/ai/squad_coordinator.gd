class_name SquadCoordinator
extends Node

## Squad coordination manager for Strike Vector encounters.
## Manages attack slot tokens to prevent overwhelming bullet spam,
## assigns flanking vectors, and broadcasts player alerts across squad members.

@export var max_simultaneous_shooters: int = 3
var active_shooters: Array[Node] = []
var squad_members: Array[Node] = []

func register_member(member: Node) -> void:
	if not member in squad_members:
		squad_members.append(member)
		if member.has_signal("died"):
			member.died.connect(func(_type, _score): unregister_member(member))

func unregister_member(member: Node) -> void:
	squad_members.erase(member)
	active_shooters.erase(member)

func request_attack_slot(member: Node) -> bool:
	if member in active_shooters:
		return true
	_cleanup_shooters()
	if active_shooters.size() < max_simultaneous_shooters:
		active_shooters.append(member)
		return true
	return false

func release_attack_slot(member: Node) -> void:
	active_shooters.erase(member)

func _cleanup_shooters() -> void:
	var valid: Array[Node] = []
	for s in active_shooters:
		if is_instance_valid(s) and s.get("is_alive") == true:
			valid.append(s)
	active_shooters = valid

func broadcast_alert(alerting_member: Node, player_pos: Vector3) -> void:
	for member in squad_members:
		if is_instance_valid(member) and member != alerting_member:
			if member.has_method("set_state"):
				member.last_known_player_pos = player_pos
				if member.current_state in [StrikeAIBase.AIState.IDLE, StrikeAIBase.AIState.PATROL]:
					member.set_state(StrikeAIBase.AIState.ALERT)
