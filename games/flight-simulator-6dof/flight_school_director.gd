class_name FlightSchoolDirector
extends Node3D

## Flight School & Mission Director for 6-DoF Aircraft Flight Simulator.
## Coordinates structured progressive flight training lessons, navigation checkpoints,
## flight evaluation metrics, scoring, and HUD instruction overlays.

signal lesson_started(lesson_id: String, title: String)
signal lesson_objective_completed(step_index: int, description: String)
signal lesson_completed(lesson_id: String, score: int, grade: String)
signal checkpoint_passed(cp_index: int, score_awarded: int)

enum LessonType {
	TAXI_TAKEOFF,
	LEVEL_FLIGHT_TRIM,
	COORDINATED_TURNS,
	STALL_RECOVERY,
	PATTERN_LANDING,
	FREE_FLIGHT
}

var aircraft: AircraftController
var current_lesson: LessonType = LessonType.TAXI_TAKEOFF
var current_step: int = 0
var current_score: int = 0
var flight_timer: float = 0.0
var lesson_active: bool = true

# Active navigation checkpoints
var waypoints: Array[Vector3] = []
var active_waypoint_index: int = 0
var waypoint_marker: MeshInstance3D

# Overlay UI
var instruction_panel: PanelContainer
var instruction_label: Label
var score_label: Label

func _ready() -> void:
	_setup_ui_overlay()
	_setup_waypoint_marker()
	start_lesson(current_lesson)

func _setup_ui_overlay() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "FlightSchoolCanvas"

	instruction_panel = PanelContainer.new()
	instruction_panel.anchors_preset = Control.PRESET_TOP_WIDE
	instruction_panel.offset_left = 280
	instruction_panel.offset_right = -280
	instruction_panel.offset_top = 18
	instruction_panel.offset_bottom = 90

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, 0.85)
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.8, 1.0, 0.85)
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	instruction_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	instruction_label = Label.new()
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.text = "FLIGHT SCHOOL: READY"
	instruction_label.add_theme_font_size_override("font_size", 16)
	instruction_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	vbox.add_child(instruction_label)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.text = "SCORE: 0  |  GRADE: PENDING"
	score_label.add_theme_font_size_override("font_size", 12)
	score_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.45, 0.9))
	vbox.add_child(score_label)

	instruction_panel.add_child(vbox)
	canvas.add_child(instruction_panel)
	add_child(canvas)

func _setup_waypoint_marker() -> void:
	waypoint_marker = MeshInstance3D.new()
	waypoint_marker.name = "WaypointRing"

	var torus = TorusMesh.new()
	torus.inner_radius = 28.0
	torus.outer_radius = 32.0
	waypoint_marker.mesh = torus

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.1, 0.9, 1.0, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	waypoint_marker.material_override = mat

	waypoint_marker.visible = false
	add_child(waypoint_marker)

func start_lesson(lesson: LessonType) -> void:
	current_lesson = lesson
	current_step = 0
	current_score = 0
	flight_timer = 0.0
	lesson_active = true
	active_waypoint_index = 0

	match lesson:
		LessonType.TAXI_TAKEOFF:
			waypoints = [
				Vector3(0, 150, -1200),
				Vector3(0, 300, -2500),
				Vector3(0, 500, -4200)
			]
			_set_instruction("LESSON 1: TAKEOFF & CLIMB\nAdvance Throttle [Shift] to 100%, track centerline with Rudder [Q/E]. Rotate at 65 KIAS.")
		LessonType.LEVEL_FLIGHT_TRIM:
			waypoints = [
				Vector3(0, 450, -2000),
				Vector3(600, 450, -3500),
				Vector3(1200, 450, -5000)
			]
			_set_instruction("LESSON 2: CRUISE & TRIM\nLevel wings, set throttle to 65%, maintain 1500 ft MSL and 110 KIAS.")
		LessonType.STALL_RECOVERY:
			waypoints = []
			_set_instruction("LESSON 3: STALL & RECOVERY\nReduce throttle to Idle. Raise nose gently until Stall Warning Horn sounds. Push stick forward and apply full power.")
		LessonType.PATTERN_LANDING:
			waypoints = [
				Vector3(-1200, 350, -1800), # Downwind
				Vector3(-1200, 250, 600),   # Base
				Vector3(0, 120, 800),       # Final approach
				Vector3(0, 5, -200)         # Touchdown
			]
			_set_instruction("LESSON 4: APPROACH & LANDING\nAlign with Runway 36. Flaps [F] 35 deg, maintain 65 KIAS on 3 deg glide slope.")
		_:
			waypoints = []
			_set_instruction("FREE FLIGHT\nExplore the 8000m airspace and mountain ranges. Press [V] to toggle cockpit view.")

	_update_waypoint_marker()
	_update_flight_director_cue()

## Configures flight difficulty: true for Assisted 6-DoF, false for Realistic 6-DoF
func set_difficulty(is_assisted: bool) -> void:
	if aircraft:
		aircraft.difficulty_mode = AircraftController.DifficultyMode.ASSISTED if is_assisted else AircraftController.DifficultyMode.REALISTIC
	if score_label:
		var mode_name = "ASSISTED" if is_assisted else "REALISTIC 6-DoF"
		score_label.text = "MODE: %s | SCORE: %d" % [mode_name, current_score]

func _update_flight_director_cue() -> void:
	if not aircraft or not aircraft.hud_node or not aircraft.hud_node.has_method("set_ghost_director"):
		return
	var tgt_pitch = 0.0
	var tgt_roll = 0.0
	match current_lesson:
		LessonType.TAXI_TAKEOFF:
			tgt_pitch = 8.0 if current_step >= 1 else 0.0
		LessonType.LEVEL_FLIGHT_TRIM:
			tgt_pitch = 1.5
		LessonType.COORDINATED_TURNS:
			tgt_roll = 30.0
			tgt_pitch = 2.5
		LessonType.STALL_RECOVERY:
			tgt_pitch = -5.0 if current_step == 2 else 12.0
		LessonType.PATTERN_LANDING:
			tgt_pitch = -3.0
	aircraft.hud_node.set_ghost_director(lesson_active, tgt_pitch, tgt_roll)

func _physics_process(delta: float) -> void:
	if not lesson_active or not aircraft:
		return

	flight_timer += delta

	match current_lesson:
		LessonType.TAXI_TAKEOFF:
			_process_takeoff_lesson()
		LessonType.STALL_RECOVERY:
			_process_stall_lesson()
		LessonType.PATTERN_LANDING:
			_process_landing_lesson()
		_:
			_process_waypoint_navigation()

	# Rotate waypoint ring for visual appeal
	if waypoint_marker and waypoint_marker.visible:
		waypoint_marker.rotate_y(0.8 * delta)

func _process_takeoff_lesson() -> void:
	match current_step:
		0:
			# Waiting for takeoff roll
			if aircraft.throttle_input > 0.85 and aircraft.airspeed_kias > 30.0:
				current_step = 1
				current_score += 150
				_set_instruction("AIRSPEED ALIVE: 30 KIAS\nMaintain runway heading. Prepare to rotate at 65 KIAS.")
		1:
			# Rotation speed reached
			if aircraft.airspeed_kias >= 65.0 and aircraft.weight_on_wheels:
				_set_instruction("ROTATE!\nGently pull back stick [S] 5-8 degrees to establish positive climb.")
			elif not aircraft.weight_on_wheels and aircraft.altitude_agl > 10.0:
				current_step = 2
				current_score += 350
				_set_instruction("POSITIVE CLIMB CONFIRMED!\nMaintain pitch attitude for 75 KIAS. Climb through Waypoints.")
		2:
			_process_waypoint_navigation()
			if active_waypoint_index >= waypoints.size():
				_complete_current_lesson("ACE")

func _process_stall_lesson() -> void:
	match current_step:
		0:
			if aircraft.throttle_input < 0.2:
				current_step = 1
				_set_instruction("THROTTLE IDLE\nPitch nose up slowly (+10 to +15 deg) to bleed airspeed into stall.")
		1:
			if aircraft.stall_horn_active:
				current_step = 2
				current_score += 400
				_set_instruction("STALL WARNING ACTIVE!\nPush stick forward [W] to break AoA, advance throttle to 100%!")
		2:
			if not aircraft.stall_horn_active and aircraft.airspeed_kias > 65.0 and aircraft.vertical_speed_fpm > 0.0:
				current_score += 600
				_complete_current_lesson("GOLD")

func _process_landing_lesson() -> void:
	_process_waypoint_navigation()
	if active_waypoint_index >= waypoints.size() - 1:
		if aircraft.weight_on_wheels:
			var sink_rate = abs(aircraft.vertical_speed_fpm)
			var grade = "ACE" if sink_rate < 200.0 else "SILVER"
			current_score += int(1000.0 - sink_rate)
			_set_instruction("TOUCHDOWN CONFIRMED!\nSink rate: %.0f FPM. Apply Wheel Brakes [Space]." % sink_rate)
			if aircraft.airspeed_kias < 5.0:
				_complete_current_lesson(grade)

func _process_waypoint_navigation() -> void:
	if active_waypoint_index >= waypoints.size():
		return

	var target_wp = waypoints[active_waypoint_index]
	var dist = aircraft.global_position.distance_to(target_wp)

	if dist < 45.0:
		active_waypoint_index += 1
		current_score += 250
		checkpoint_passed.emit(active_waypoint_index, 250)
		_update_waypoint_marker()
		score_label.text = "SCORE: %d  |  WAYPOINT: %d/%d" % [current_score, active_waypoint_index, waypoints.size()]

func _update_waypoint_marker() -> void:
	if not waypoint_marker:
		return
	if active_waypoint_index < waypoints.size():
		waypoint_marker.visible = true
		waypoint_marker.global_position = waypoints[active_waypoint_index]
		# Orient ring along flight path
		waypoint_marker.look_at(waypoint_marker.global_position + Vector3(0, 0, -1), Vector3.UP)
	else:
		waypoint_marker.visible = false

func _set_instruction(text: String) -> void:
	if instruction_label:
		instruction_label.text = text

func _complete_current_lesson(grade: String) -> void:
	lesson_active = false
	var final_score = current_score + int(max(0.0, 300.0 - flight_timer) * 5.0)
	score_label.text = "LESSON COMPLETE!  SCORE: %d  |  GRADE: %s" % [final_score, grade]
	_set_instruction("EXCELLENT FLYING!\nLesson successfully passed with %s rating." % grade)
	lesson_completed.emit(str(current_lesson), final_score, grade)
