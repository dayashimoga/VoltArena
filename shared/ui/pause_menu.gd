class_name PauseMenu
extends CanvasLayer

signal resume_requested()
signal restart_requested()
signal restart_checkpoint_requested()
signal restart_event_requested()
signal main_menu_requested()
signal quit_to_launcher_requested()
signal quit_to_desktop_requested()

var panel: PanelContainer
var settings_dialog: Control

var _controls_panel: PanelContainer
var _audio_panel: PanelContainer
var _graphics_panel: PanelContainer
var _accessibility_panel: PanelContainer
var _settings_panel: PanelContainer

var btn_resume: Button
var btn_restart_checkpoint: Button
var btn_restart_event: Button
var btn_controls: Button
var btn_audio: Button
var btn_graphics: Button
var btn_accessibility: Button
var btn_main_menu: Button
var btn_launcher: Button
var btn_quit_desktop: Button

var is_standalone: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 100
	visible = false
	_detect_environment()
	setup_ui()

func _detect_environment() -> void:
	# Standalone vs Suite detection: check if launcher scene exists and is not standalone binary
	var has_launcher = ResourceLoader.exists("res://launcher/launcher_main.tscn")
	var cmd_args = OS.get_cmdline_user_args()
	is_standalone = ("--standalone" in cmd_args) or not has_launcher

func setup_ui() -> void:
	var bg = ColorRect.new()
	bg.name = "PauseBackground"
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.01, 0.02, 0.05, 0.85)
	add_child(bg)

	panel = PanelContainer.new()
	panel.name = "MainPausePanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -210
	panel.offset_top = -260
	panel.offset_right = 210
	panel.offset_bottom = 260
	panel.theme = ThemeGenerator.get_theme()
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.0, 1.0, 1.0)
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "VOLTARENA SYSTEM"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.6, 0.7, 0.8, 0.7)
	subtitle.add_theme_font_size_override("font_size", 11)
	vbox.add_child(subtitle)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# 1. Resume
	btn_resume = Button.new()
	btn_resume.text = "RESUME"
	btn_resume.pressed.connect(_on_resume_pressed)
	vbox.add_child(btn_resume)

	# 2. Restart Checkpoint
	btn_restart_checkpoint = Button.new()
	btn_restart_checkpoint.text = "RESTART CHECKPOINT"
	btn_restart_checkpoint.pressed.connect(_on_restart_checkpoint_pressed)
	vbox.add_child(btn_restart_checkpoint)

	# 3. Restart Event
	btn_restart_event = Button.new()
	btn_restart_event.text = "RESTART EVENT"
	btn_restart_event.pressed.connect(_on_restart_event_pressed)
	vbox.add_child(btn_restart_event)

	# 4. Controls
	btn_controls = Button.new()
	btn_controls.text = "CONTROLS"
	btn_controls.pressed.connect(_show_controls_modal)
	vbox.add_child(btn_controls)

	# 5. Audio
	btn_audio = Button.new()
	btn_audio.text = "AUDIO"
	btn_audio.pressed.connect(_show_audio_modal)
	vbox.add_child(btn_audio)

	# 6. Graphics
	btn_graphics = Button.new()
	btn_graphics.text = "GRAPHICS"
	btn_graphics.pressed.connect(_show_graphics_modal)
	vbox.add_child(btn_graphics)

	# 7. Accessibility
	btn_accessibility = Button.new()
	btn_accessibility.text = "ACCESSIBILITY"
	btn_accessibility.pressed.connect(_show_accessibility_modal)
	vbox.add_child(btn_accessibility)

	# 8. Main Menu
	btn_main_menu = Button.new()
	btn_main_menu.text = "MAIN MENU"
	btn_main_menu.pressed.connect(_on_main_menu_pressed)
	vbox.add_child(btn_main_menu)

	# 9. Launcher (if suite) or Quit Desktop
	if not is_standalone:
		btn_launcher = Button.new()
		btn_launcher.text = "VOLTARENA LAUNCHER"
		btn_launcher.pressed.connect(_on_launcher_pressed)
		vbox.add_child(btn_launcher)

	# 10. Quit Game / Desktop
	btn_quit_desktop = Button.new()
	btn_quit_desktop.text = "QUIT TO DESKTOP" if not is_standalone else "QUIT GAME"
	btn_quit_desktop.pressed.connect(_on_quit_desktop_pressed)
	vbox.add_child(btn_quit_desktop)

	_setup_controls_modal()
	_setup_audio_modal()
	_setup_graphics_modal()
	_setup_accessibility_modal()
	_setup_settings_modal()

func _on_resume_pressed() -> void:
	hide_pause()
	resume_requested.emit()

func _on_restart_checkpoint_pressed() -> void:
	hide_pause()
	restart_checkpoint_requested.emit()

func _on_restart_event_pressed() -> void:
	hide_pause()
	restart_event_requested.emit()
	restart_requested.emit()

func _on_main_menu_pressed() -> void:
	hide_pause()
	main_menu_requested.emit()

func _on_launcher_pressed() -> void:
	hide_pause()
	quit_to_launcher_requested.emit()

func _on_quit_desktop_pressed() -> void:
	hide_pause()
	quit_to_desktop_requested.emit()
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree and OS.get_name() != "Web":
		tree.quit()

# =========================================================================
# Sub-Modals
# =========================================================================

func _show_controls_modal() -> void:
	_hide_all_modals()
	panel.visible = false
	if is_instance_valid(_controls_panel):
		_controls_panel.visible = true

func _show_audio_modal() -> void:
	_hide_all_modals()
	panel.visible = false
	if is_instance_valid(_audio_panel):
		_audio_panel.visible = true

func _show_graphics_modal() -> void:
	_hide_all_modals()
	panel.visible = false
	if is_instance_valid(_graphics_panel):
		_graphics_panel.visible = true

func _show_accessibility_modal() -> void:
	_hide_all_modals()
	panel.visible = false
	if is_instance_valid(_accessibility_panel):
		_accessibility_panel.visible = true

func _show_settings_modal() -> void:
	_show_audio_modal()

func _return_to_main_pause() -> void:
	_hide_all_modals()
	panel.visible = true
	if is_inside_tree() and is_instance_valid(btn_resume):
		btn_resume.grab_focus()

func _hide_all_modals() -> void:
	if is_instance_valid(_controls_panel): _controls_panel.visible = false
	if is_instance_valid(_audio_panel): _audio_panel.visible = false
	if is_instance_valid(_graphics_panel): _graphics_panel.visible = false
	if is_instance_valid(_accessibility_panel): _accessibility_panel.visible = false
	if is_instance_valid(_settings_panel): _settings_panel.visible = false

func _has_any_modal_visible() -> bool:
	return ((is_instance_valid(_controls_panel) and _controls_panel.visible) or
		(is_instance_valid(_audio_panel) and _audio_panel.visible) or
		(is_instance_valid(_graphics_panel) and _graphics_panel.visible) or
		(is_instance_valid(_accessibility_panel) and _accessibility_panel.visible) or
		(is_instance_valid(_settings_panel) and _settings_panel.visible))

# ---------------- Controls Modal ----------------
func _setup_controls_modal() -> void:
	_controls_panel = PanelContainer.new()
	_controls_panel.name = "ControlsModal"
	_controls_panel.anchor_left = 0.5
	_controls_panel.anchor_top = 0.5
	_controls_panel.anchor_right = 0.5
	_controls_panel.anchor_bottom = 0.5
	_controls_panel.offset_left = -240
	_controls_panel.offset_top = -220
	_controls_panel.offset_right = 240
	_controls_panel.offset_bottom = 220
	_controls_panel.theme = ThemeGenerator.get_theme()
	_controls_panel.visible = false
	add_child(_controls_panel)

	var cvbox = VBoxContainer.new()
	cvbox.add_theme_constant_override("separation", 6)
	_controls_panel.add_child(cvbox)

	var ctitle = Label.new()
	ctitle.text = "CONTROLS & INPUT"
	ctitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ctitle.modulate = Color(0.0, 1.0, 1.0)
	ctitle.add_theme_font_size_override("font_size", 18)
	cvbox.add_child(ctitle)

	var bindings = [
		"WASD / Left Stick: Steer / Drive / Move",
		"Space / Button A: Handbrake Drift / Jump",
		"Shift / Button X: Nitro Boost / Sprint",
		"W / Up / Right Trigger: Accelerate",
		"S / Down / Left Trigger: Brake / Reverse",
		"Air Pitch: W / S or Left Stick Up / Down",
		"Air Roll / Spin: A / D or Left Stick Left / Right",
		"R / Button Y: Recover / Reset Vehicle",
		"ESC / Start / Select: Pause Menu"
	]
	for b in bindings:
		var lbl = Label.new()
		lbl.text = b
		lbl.add_theme_font_size_override("font_size", 12)
		cvbox.add_child(lbl)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	cvbox.add_child(spacer)

	var btn_close = Button.new()
	btn_close.text = "BACK TO PAUSE MENU"
	btn_close.pressed.connect(_return_to_main_pause)
	cvbox.add_child(btn_close)

# ---------------- Audio Modal ----------------
func _setup_audio_modal() -> void:
	_audio_panel = PanelContainer.new()
	_audio_panel.name = "AudioModal"
	_audio_panel.anchor_left = 0.5
	_audio_panel.anchor_top = 0.5
	_audio_panel.anchor_right = 0.5
	_audio_panel.anchor_bottom = 0.5
	_audio_panel.offset_left = -220
	_audio_panel.offset_top = -200
	_audio_panel.offset_right = 220
	_audio_panel.offset_bottom = 200
	_audio_panel.theme = ThemeGenerator.get_theme()
	_audio_panel.visible = false
	add_child(_audio_panel)

	var avbox = VBoxContainer.new()
	avbox.add_theme_constant_override("separation", 8)
	_audio_panel.add_child(avbox)

	var atitle = Label.new()
	atitle.text = "AUDIO SETTINGS"
	atitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atitle.modulate = Color(0.0, 1.0, 1.0)
	atitle.add_theme_font_size_override("font_size", 18)
	avbox.add_child(atitle)

	var lbl_vol = Label.new()
	lbl_vol.text = "Master Volume"
	avbox.add_child(lbl_vol)

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
	avbox.add_child(slider_vol)

	var lbl_sfx = Label.new()
	lbl_sfx.text = "SFX Volume"
	avbox.add_child(lbl_sfx)

	var slider_sfx = HSlider.new()
	slider_sfx.min_value = 0.0
	slider_sfx.max_value = 1.0
	slider_sfx.step = 0.05
	slider_sfx.value = 0.85
	slider_sfx.value_changed.connect(func(v):
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am and am.has_method("set_sfx_volume"):
			am.set_sfx_volume(v)
	)
	avbox.add_child(slider_sfx)

	var lbl_mus = Label.new()
	lbl_mus.text = "Music Volume"
	avbox.add_child(lbl_mus)

	var slider_mus = HSlider.new()
	slider_mus.min_value = 0.0
	slider_mus.max_value = 1.0
	slider_mus.step = 0.05
	slider_mus.value = 0.75
	slider_mus.value_changed.connect(func(v):
		var am = GameConstants.get_autoload(self, "AudioManager")
		if am and am.has_method("set_music_volume"):
			am.set_music_volume(v)
	)
	avbox.add_child(slider_mus)

	var btn_close = Button.new()
	btn_close.text = "BACK TO PAUSE MENU"
	btn_close.pressed.connect(_return_to_main_pause)
	avbox.add_child(btn_close)

# ---------------- Graphics Modal ----------------
func _setup_graphics_modal() -> void:
	_graphics_panel = PanelContainer.new()
	_graphics_panel.name = "GraphicsModal"
	_graphics_panel.anchor_left = 0.5
	_graphics_panel.anchor_top = 0.5
	_graphics_panel.anchor_right = 0.5
	_graphics_panel.anchor_bottom = 0.5
	_graphics_panel.offset_left = -220
	_graphics_panel.offset_top = -210
	_graphics_panel.offset_right = 220
	_graphics_panel.offset_bottom = 210
	_graphics_panel.theme = ThemeGenerator.get_theme()
	_graphics_panel.visible = false
	add_child(_graphics_panel)

	var gvbox = VBoxContainer.new()
	gvbox.add_theme_constant_override("separation", 8)
	_graphics_panel.add_child(gvbox)

	var gtitle = Label.new()
	gtitle.text = "GRAPHICS SETTINGS"
	gtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gtitle.modulate = Color(0.0, 1.0, 1.0)
	gtitle.add_theme_font_size_override("font_size", 18)
	gvbox.add_child(gtitle)

	var lbl_preset = Label.new()
	lbl_preset.text = "Quality Preset"
	gvbox.add_child(lbl_preset)

	var opt_preset = OptionButton.new()
	opt_preset.add_item("Low")
	opt_preset.add_item("Medium")
	opt_preset.add_item("High")
	opt_preset.add_item("Ultra")
	opt_preset.select(2)
	opt_preset.item_selected.connect(func(idx):
		var qm = GameConstants.get_autoload(self, "QualityManager")
		if qm and qm.has_method("set_preset"):
			qm.set_preset(idx)
	)
	gvbox.add_child(opt_preset)

	var check_fullscreen = CheckBox.new()
	check_fullscreen.text = "Fullscreen"
	check_fullscreen.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	check_fullscreen.toggled.connect(func(pressed):
		if pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	)
	gvbox.add_child(check_fullscreen)

	var check_vsync = CheckBox.new()
	check_vsync.text = "V-Sync"
	check_vsync.button_pressed = (DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_ENABLED)
	check_vsync.toggled.connect(func(pressed):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if pressed else DisplayServer.VSYNC_DISABLED)
	)
	gvbox.add_child(check_vsync)

	var btn_close = Button.new()
	btn_close.text = "BACK TO PAUSE MENU"
	btn_close.pressed.connect(_return_to_main_pause)
	gvbox.add_child(btn_close)

# ---------------- Accessibility Modal ----------------
func _setup_accessibility_modal() -> void:
	_accessibility_panel = PanelContainer.new()
	_accessibility_panel.name = "AccessibilityModal"
	_accessibility_panel.anchor_left = 0.5
	_accessibility_panel.anchor_top = 0.5
	_accessibility_panel.anchor_right = 0.5
	_accessibility_panel.anchor_bottom = 0.5
	_accessibility_panel.offset_left = -220
	_accessibility_panel.offset_top = -200
	_accessibility_panel.offset_right = 220
	_accessibility_panel.offset_bottom = 200
	_accessibility_panel.theme = ThemeGenerator.get_theme()
	_accessibility_panel.visible = false
	add_child(_accessibility_panel)

	var xvbox = VBoxContainer.new()
	xvbox.add_theme_constant_override("separation", 8)
	_accessibility_panel.add_child(xvbox)

	var xtitle = Label.new()
	xtitle.text = "ACCESSIBILITY"
	xtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xtitle.modulate = Color(0.0, 1.0, 1.0)
	xtitle.add_theme_font_size_override("font_size", 18)
	xvbox.add_child(xtitle)

	var check_contrast = CheckBox.new()
	check_contrast.text = "High Contrast HUD Elements"
	check_contrast.button_pressed = false
	xvbox.add_child(check_contrast)

	var check_shake = CheckBox.new()
	check_shake.text = "Enable Camera Screen Shake"
	check_shake.button_pressed = true
	xvbox.add_child(check_shake)

	var lbl_colorblind = Label.new()
	lbl_colorblind.text = "Color Correction Mode"
	xvbox.add_child(lbl_colorblind)

	var opt_cb = OptionButton.new()
	opt_cb.add_item("Standard (None)")
	opt_cb.add_item("Protanopia (Red-Green)")
	opt_cb.add_item("Deuteranopia (Green-Red)")
	opt_cb.add_item("Tritanopia (Blue-Yellow)")
	opt_cb.select(0)
	xvbox.add_child(opt_cb)

	var btn_close = Button.new()
	btn_close.text = "BACK TO PAUSE MENU"
	btn_close.pressed.connect(_return_to_main_pause)
	xvbox.add_child(btn_close)

# ---------------- Legacy Settings Modal for Backwards Compatibility ----------------
func _setup_settings_modal() -> void:
	_settings_panel = PanelContainer.new()
	_settings_panel.name = "SettingsModal"
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

# =========================================================================
# State & Input Management
# =========================================================================

func show_pause() -> void:
	visible = true
	_return_to_main_pause()
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func hide_pause() -> void:
	_hide_all_modals()
	visible = false
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.paused = false

func _unhandled_input(event: InputEvent) -> void:
	var is_pause_trigger = false

	if (InputMap.has_action("pause") and event.is_action_pressed("pause")) or (InputMap.has_action("ui_cancel") and event.is_action_pressed("ui_cancel")):
		is_pause_trigger = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			is_pause_trigger = true
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_START or event.button_index == JOY_BUTTON_BACK:
			is_pause_trigger = true

	if not is_pause_trigger:
		return

	if visible:
		if _has_any_modal_visible():
			_return_to_main_pause()
		else:
			hide_pause()
			resume_requested.emit()
	else:
		show_pause()

	var vp = get_viewport()
	if vp:
		vp.set_input_as_handled()
