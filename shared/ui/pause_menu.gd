class_name PauseMenu
extends CanvasLayer

signal resume_requested()
signal restart_requested()
signal quit_to_launcher_requested()

var panel: PanelContainer
var settings_dialog: Control

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 100
	visible = false
	setup_ui()

func setup_ui() -> void:
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.02, 0.04, 0.08, 0.8)
	add_child(bg)

	panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -180
	panel.offset_top = -200
	panel.offset_right = 180
	panel.offset_bottom = 200
	panel.theme = ThemeGenerator.get_theme()
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.0, 1.0, 1.0)
	vbox.add_child(title)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var btn_resume = Button.new()
	btn_resume.text = "RESUME"
	btn_resume.pressed.connect(func():
		hide_pause()
		resume_requested.emit()
	)
	vbox.add_child(btn_resume)

	var btn_restart = Button.new()
	btn_restart.text = "RESTART"
	btn_restart.pressed.connect(func():
		hide_pause()
		restart_requested.emit()
	)
	vbox.add_child(btn_restart)

	var btn_launcher = Button.new()
	btn_launcher.text = "RETURN TO LAUNCHER"
	btn_launcher.pressed.connect(func():
		hide_pause()
		quit_to_launcher_requested.emit()
	)
	vbox.add_child(btn_launcher)

func show_pause() -> void:
	visible = true
	if get_tree():
		get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func hide_pause() -> void:
	visible = false
	if get_tree():
		get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			hide_pause()
			resume_requested.emit()
		else:
			show_pause()
		get_viewport().set_input_as_handled()
