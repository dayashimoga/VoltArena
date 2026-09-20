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

	var btn_settings = Button.new()
	btn_settings.text = "SETTINGS"
	btn_settings.pressed.connect(_show_settings_modal)
	vbox.add_child(btn_settings)

	var btn_controls = Button.new()
	btn_controls.text = "CONTROLS"
	btn_controls.pressed.connect(_show_controls_modal)
	vbox.add_child(btn_controls)

	var btn_launcher = Button.new()
	btn_launcher.text = "QUIT TO LAUNCHER"
	btn_launcher.pressed.connect(func():
		hide_pause()
		quit_to_launcher_requested.emit()
	)
	vbox.add_child(btn_launcher)

	_setup_settings_modal()
	_setup_controls_modal()

var _settings_panel: PanelContainer
var _controls_panel: PanelContainer

func _setup_settings_modal() -> void:
	_settings_panel = PanelContainer.new()
	_settings_panel.anchor_left = 0.5
	_settings_panel.anchor_top = 0.5
	_settings_panel.anchor_right = 0.5
	_settings_panel.anchor_bottom = 0.5
	_settings_panel.offset_left = -200
	_settings_panel.offset_top = -180
	_settings_panel.offset_right = 200
	_settings_panel.offset_bottom = 180
	_settings_panel.theme = ThemeGenerator.get_theme()
	_settings_panel.visible = false
	add_child(_settings_panel)

	var svbox = VBoxContainer.new()
	svbox.add_theme_constant_override("separation", 10)
	_settings_panel.add_child(svbox)

	var stitle = Label.new()
	stitle.text = "SETTINGS"
	stitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stitle.modulate = Color(0.0, 1.0, 1.0)
	svbox.add_child(stitle)

	var lbl_vol = Label.new()
	lbl_vol.text = "Master Volume"
	svbox.add_child(lbl_vol)

	var slider_vol = HSlider.new()
	slider_vol.min_value = 0.0
	slider_vol.max_value = 1.0
	slider_vol.step = 0.05
	slider_vol.value = 0.8
	slider_vol.value_changed.connect(func(v):
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am and am.has_method("set_master_volume"):
			am.set_master_volume(v)
	)
	svbox.add_child(slider_vol)

	var lbl_sfx = Label.new()
	lbl_sfx.text = "SFX Volume"
	svbox.add_child(lbl_sfx)

	var slider_sfx = HSlider.new()
	slider_sfx.min_value = 0.0
	slider_sfx.max_value = 1.0
	slider_sfx.step = 0.05
	slider_sfx.value = 0.85
	svbox.add_child(slider_sfx)

	var btn_close_set = Button.new()
	btn_close_set.text = "CLOSE"
	btn_close_set.pressed.connect(func():
		_settings_panel.visible = false
		panel.visible = true
	)
	svbox.add_child(btn_close_set)

func _setup_controls_modal() -> void:
	_controls_panel = PanelContainer.new()
	_controls_panel.anchor_left = 0.5
	_controls_panel.anchor_top = 0.5
	_controls_panel.anchor_right = 0.5
	_controls_panel.anchor_bottom = 0.5
	_controls_panel.offset_left = -220
	_controls_panel.offset_top = -200
	_controls_panel.offset_right = 220
	_controls_panel.offset_bottom = 200
	_controls_panel.theme = ThemeGenerator.get_theme()
	_controls_panel.visible = false
	add_child(_controls_panel)

	var cvbox = VBoxContainer.new()
	cvbox.add_theme_constant_override("separation", 8)
	_controls_panel.add_child(cvbox)

	var ctitle = Label.new()
	ctitle.text = "CONTROLS"
	ctitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ctitle.modulate = Color(0.0, 1.0, 1.0)
	cvbox.add_child(ctitle)

	var bindings = [
		"WASD / Arrows: Move / Steer",
		"Space: Jump / Handbrake Drift",
		"Shift: Sprint / Boost",
		"Left Click: Fire / Accelerate",
		"Right Click: ADS / Reverse / Brake",
		"R: Reload",
		"1-9: Weapon Select",
		"Esc / P: Pause Menu"
	]
	for b in bindings:
		var lbl = Label.new()
		lbl.text = b
		lbl.add_theme_font_size_override("font_size", 13)
		cvbox.add_child(lbl)

	var btn_close_ctrl = Button.new()
	btn_close_ctrl.text = "CLOSE"
	btn_close_ctrl.pressed.connect(func():
		_controls_panel.visible = false
		panel.visible = true
	)
	cvbox.add_child(btn_close_ctrl)

func _show_settings_modal() -> void:
	panel.visible = false
	if is_instance_valid(_settings_panel):
		_settings_panel.visible = true

func _show_controls_modal() -> void:
	panel.visible = false
	if is_instance_valid(_controls_panel):
		_controls_panel.visible = true

func show_pause() -> void:
	visible = true
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func hide_pause() -> void:
	visible = false
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.paused = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			hide_pause()
			resume_requested.emit()
		else:
			show_pause()
		get_viewport().set_input_as_handled()
