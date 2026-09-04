class_name VirtualJoystick
extends Control

signal joystick_vector_updated(vector: Vector2)

@export var max_radius: float = 64.0
@export var deadzone: float = 0.1

var touch_id: int = -1
var center_pos: Vector2 = Vector2.ZERO
var knob_pos: Vector2 = Vector2.ZERO
var current_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(max_radius * 2.5, max_radius * 2.5)
	center_pos = size * 0.5
	knob_pos = center_pos

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			touch_id = event.index
			center_pos = event.position
			update_knob(event.position)
		elif not event.pressed and event.index == touch_id:
			reset_joystick()
	elif event is InputEventScreenDrag and event.index == touch_id:
		update_knob(event.position)

func update_knob(touch_pos: Vector2) -> void:
	var delta: Vector2 = touch_pos - center_pos
	var dist: float = delta.length()
	if dist > max_radius:
		delta = delta.normalized() * max_radius
	knob_pos = center_pos + delta

	var norm: Vector2 = delta / max_radius
	if norm.length() < deadzone:
		current_vector = Vector2.ZERO
	else:
		current_vector = norm

	joystick_vector_updated.emit(current_vector)
	queue_redraw()

func reset_joystick() -> void:
	touch_id = -1
	knob_pos = center_pos
	current_vector = Vector2.ZERO
	joystick_vector_updated.emit(current_vector)
	queue_redraw()

func _draw() -> void:
	# Outer ring
	draw_circle(center_pos, max_radius, Color(0.1, 0.15, 0.25, 0.4))
	draw_arc(center_pos, max_radius, 0.0, TAU, 32, Color(0.0, 0.9, 1.0, 0.6), 2.0)
	# Inner knob
	draw_circle(knob_pos, max_radius * 0.45, Color(0.0, 0.9, 1.0, 0.7))
	draw_circle(knob_pos, max_radius * 0.2, Color(1.0, 1.0, 1.0, 0.9))
