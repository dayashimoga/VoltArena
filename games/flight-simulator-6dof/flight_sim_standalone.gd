class_name FlightSimStandalone
extends Control

## Standalone launch entry point for AeroSim 6-DoF Aircraft Flight Simulator.
## Provides standalone main menu, aircraft hangar inspection, mission select,
## controls calibration, settings, and direct simulation launch.

const SAVE_DIR: String = "user://saves/flight_simulator_6dof/"
const SAVE_PATH: String = "user://saves/flight_simulator_6dof/save.json"

var main_menu_panel: PanelContainer
var mission_select_panel: PanelContainer
var controls_panel: PanelContainer
var world_container: SubViewportContainer
var world_viewport: SubViewport
var active_world: Node3D

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	_ensure_save_directory()
	_setup_ui()

func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("saves"):
			dir.make_dir("saves")
		if not dir.dir_exists("saves/flight_simulator_6dof"):
			dir.make_dir("saves/flight_simulator_6dof")

func _setup_ui() -> void:
	# Background 3D Viewport for live hangar/flight backdrop
	world_container = SubViewportContainer.new()
	world_container.anchors_preset = Control.PRESET_FULL_RECT
	world_container.stretch = true
	add_child(world_container)

	world_viewport = SubViewport.new()
	world_viewport.size = Vector2i(1280, 720)
	world_viewport.handle_input_locally = true
	world_container.add_child(world_viewport)

	# Main Menu Overlay
	main_menu_panel = PanelContainer.new()
	main_menu_panel.anchors_preset = Control.PRESET_FULL_RECT
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.04, 0.07, 0.1, 0.75)
	main_menu_panel.add_theme_stylebox_override("panel", bg_style)

	var center_box = CenterContainer.new()
	center_box.anchors_preset = Control.PRESET_FULL_RECT
	main_menu_panel.add_child(center_box)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(480, 0)
	vbox.add_theme_constant_override("separation", 16)

	var title_lbl = Label.new()
	title_lbl.text = "AEROSIM 6-DoF"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 42)
	title_lbl.add_theme_color_override("font_color", Color(0.15, 0.9, 1.0))
	vbox.add_child(title_lbl)

	var subtitle_lbl = Label.new()
	subtitle_lbl.text = "Professional 6-DoF Aerodynamics & Flight Simulator"
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", 14)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 0.95))
	vbox.add_child(subtitle_lbl)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Menu Buttons
	var btn_flight_school = _create_menu_button("FLIGHT SCHOOL", Callable(self, "_on_flight_school_pressed"))
	var btn_free_flight = _create_menu_button("FREE FLIGHT (RUNWAY 36)", Callable(self, "_on_free_flight_pressed"))
	var btn_controls = _create_menu_button("FLIGHT CONTROLS & CALIBRATION", Callable(self, "_on_controls_pressed"))
	var btn_exit = _create_menu_button("EXIT SIMULATOR", Callable(self, "_on_exit_pressed"))

	vbox.add_child(btn_flight_school)
	vbox.add_child(btn_free_flight)
	vbox.add_child(btn_controls)
	vbox.add_child(btn_exit)

	center_box.add_child(vbox)
	add_child(main_menu_panel)

func _create_menu_button(label_text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0, 48)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(callback)
	return btn

func _on_flight_school_pressed() -> void:
	_launch_simulation(0) # Lesson 1: Takeoff

func _on_free_flight_pressed() -> void:
	_launch_simulation(5) # Free flight

func _on_controls_pressed() -> void:
	if not controls_panel:
		_build_controls_dialog()
	controls_panel.visible = true

func _build_controls_dialog() -> void:
	controls_panel = PanelContainer.new()
	controls_panel.anchors_preset = Control.PRESET_CENTER
	controls_panel.custom_minimum_size = Vector2(560, 420)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.18, 0.95)
	style.border_color = Color(0.2, 0.8, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	controls_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)

	var heading = Label.new()
	heading.text = "6-DoF FLIGHT CONTROLS & BINDINGS"
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
	vbox.add_child(heading)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 8)

	var controls_map = [
		["Pitch (Elevator):", "W / S  |  Left Stick Y"],
		["Roll (Ailerons):", "A / D  |  Left Stick X"],
		["Yaw (Rudder & Taxi):", "Q / E  |  LB / RB"],
		["Throttle (+ / -):", "Shift / Ctrl  |  RT / LT"],
		["Wheel Brakes:", "Spacebar  |  A Button"],
		["Parking Brake:", "B / P  |  X Button"],
		["Flaps Cycle (0/15/35°):", "F  |  Y Button"],
		["Landing Gear Toggle:", "G  |  B Button"],
		["Camera Cockpit/Chase:", "V / C  |  Back / Select"],
		["Axis Deadzone:", "0.12 (Calibrated)"]
	]

	for item in controls_map:
		var l1 = Label.new()
		l1.text = item[0]
		l1.add_theme_font_size_override("font_size", 13)
		l1.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
		grid.add_child(l1)

		var l2 = Label.new()
		l2.text = item[1]
		l2.add_theme_font_size_override("font_size", 13)
		l2.add_theme_color_override("font_color", Color(1, 1, 1))
		grid.add_child(l2)

	vbox.add_child(grid)

	var close_btn = Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(0, 38)
	close_btn.pressed.connect(func(): controls_panel.visible = false)
	vbox.add_child(close_btn)

	margin.add_child(vbox)
	controls_panel.add_child(margin)
	add_child(controls_panel)

func _launch_simulation(lesson_id: int) -> void:
	main_menu_panel.visible = false
	if controls_panel:
		controls_panel.visible = false

	if active_world:
		active_world.queue_free()

	var world_scene = load("res://games/flight-simulator-6dof/world_main.tscn") as PackedScene
	if world_scene:
		active_world = world_scene.instantiate()
		world_viewport.add_child(active_world)

		var director = active_world.get_node_or_null("FlightSchoolDirector")
		if director and director.has_method("start_lesson"):
			director.start_lesson(lesson_id)

func _on_exit_pressed() -> void:
	if OS.has_feature("standalone"):
		get_tree().quit()
	else:
		# Return to suite launcher if running inside suite
		var bus = GameConstants.get_autoload(self, "EventBus")
		if bus:
			bus.return_to_launcher_requested.emit()
		get_tree().change_scene_to_file("res://launcher/launcher.tscn")
