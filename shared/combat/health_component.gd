class_name HealthComponent
extends Node

signal health_changed(current_hp: float, max_hp: float)
signal armor_changed(current_armor: float, max_armor: float)
signal damage_taken(amount: float, from_source: Node)
signal healed(amount: float)
signal died(from_source: Node)

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var max_armor: float = 100.0
@export var current_armor: float = 50.0
@export var armor_absorption_ratio: float = 0.65

var is_dead: bool = false

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float, source: Node = null, is_headshot: bool = false) -> void:
	if is_dead or amount <= 0.0:
		return

	var final_dmg = amount * (2.0 if is_headshot else 1.0)
	if current_armor > 0.0:
		var absorbed = final_dmg * armor_absorption_ratio
		var to_armor = min(current_armor, absorbed)
		current_armor -= to_armor
		final_dmg -= to_armor
		armor_changed.emit(current_armor, max_armor)

	current_health = max(0.0, current_health - final_dmg)
	health_changed.emit(current_health, max_health)
	damage_taken.emit(final_dmg, source)

	if current_health <= 0.0:
		is_dead = true
		died.emit(source)

func heal(amount: float) -> void:
	if is_dead:
		return
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
	healed.emit(amount)

func add_armor(amount: float) -> void:
	if is_dead:
		return
	current_armor = min(max_armor, current_armor + amount)
	armor_changed.emit(current_armor, max_armor)

func reset() -> void:
	is_dead = false
	current_health = max_health
	current_armor = 50.0
	health_changed.emit(current_health, max_health)
	armor_changed.emit(current_armor, max_armor)
