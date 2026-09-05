class_name ArenaFPSHUD
extends HUDBase

var frags_label: Label
var target_kills: int = 20
var current_frags: int = 0
var objective_label: Label
var countdown_panel: PanelContainer
var countdown_label: Label
var onboarding_overlay: PanelContainer

func setup_hud_layout() -> void:
	super.setup_hud_layout()
	_setup_arena_extras()
	setup_onboarding_overlay()

func _setup_arena_extras() -> void:
	# Top Left Frags Badge
	var frag_panel = PanelContainer.new()
	frag_panel.position = Vector2(24, 24)
	frag_panel.custom_minimum_size = Vector2(170, 52)
	add_child(frag_panel)

	var frag_vbox = VBoxContainer.new()
	frag_panel.add_child(frag_vbox)

	var title_lbl = Label.new()
	title_lbl.text = "IRON CRUCIBLE // TDM"
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.modulate = Color(0.0, 0.9, 1.0, 0.8)
	frag_vbox.add_child(title_lbl)

	frags_label = Label.new()
	frags_label.text = "FRAGS: 0 / %d" % target_kills
	frags_label.add_theme_font_size_override("font_size", 16)
	frags_label.modulate = Color(1.0, 0.9, 0.3)
	frag_vbox.add_child(frags_label)

	# Top Center: Active Match Objective Banner
	var obj_panel = PanelContainer.new()
	obj_panel.anchor_left = 0.5
	obj_panel.anchor_right = 0.5
	obj_panel.offset_left = -210
	obj_panel.offset_top = 20
	obj_panel.offset_right = 210
	obj_panel.offset_bottom = 58
	add_child(obj_panel)

	objective_label = Label.new()
	objective_label.text = "OBJECTIVE: FIRST TO 20 FRAGS WINS"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 13)
	objective_label.modulate = Color(0.9, 0.95, 1.0)
	obj_panel.add_child(objective_label)

	# Center: 3-2-1 Countdown Panel
	countdown_panel = PanelContainer.new()
	countdown_panel.anchor_left = 0.5
	countdown_panel.anchor_top = 0.35
	countdown_panel.anchor_right = 0.5
	countdown_panel.anchor_bottom = 0.35
	countdown_panel.offset_left = -140
	countdown_panel.offset_top = -45
	countdown_panel.offset_right = 140
	countdown_panel.offset_bottom = 45
	countdown_panel.visible = false
	add_child(countdown_panel)

	countdown_label = Label.new()
	countdown_label.text = "3"
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 38)
	countdown_label.modulate = Color(1.0, 0.85, 0.1)
	countdown_panel.add_child(countdown_label)

func update_frags(frags: int, target: int = 20) -> void:
	current_frags = frags
	target_kills = target
	if frags_label:
		frags_label.text = "FRAGS: %d / %d" % [current_frags, target_kills]

func update_objective(p_frags: int, b_frags: int, target: int = 20) -> void:
	update_frags(p_frags, target)
	if objective_label:
		objective_label.text = "RACE TO %d FRAGS | YOU: %d  vs  ENEMIES: %d" % [target, p_frags, b_frags]

func show_countdown(seconds: int) -> void:
	if not countdown_panel:
		return
	if seconds > 0:
		countdown_panel.visible = true
		countdown_label.text = str(seconds)
	elif seconds == 0:
		countdown_panel.visible = true
		countdown_label.text = "FIGHT!"
		countdown_label.modulate = Color(0.0, 1.0, 0.5)
		var tween = create_tween()
		tween.tween_property(countdown_panel, "modulate:a", 0.0, 0.6).set_delay(0.4)
		tween.tween_callback(func():
			countdown_panel.visible = false
			countdown_panel.modulate.a = 1.0
		)
	else:
		countdown_panel.visible = false

func setup_onboarding_overlay() -> void:
	onboarding_overlay = PanelContainer.new()
	onboarding_overlay.name = "OnboardingOverlay"
	onboarding_overlay.anchor_left = 0.5
	onboarding_overlay.anchor_top = 0.5
	onboarding_overlay.anchor_right = 0.5
	onboarding_overlay.anchor_bottom = 0.5
	onboarding_overlay.offset_left = -320
	onboarding_overlay.offset_top = -180
	onboarding_overlay.offset_right = 320
	onboarding_overlay.offset_bottom = 180
	add_child(onboarding_overlay)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	onboarding_overlay.add_child(vbox)

	var title = Label.new()
	title.text = "IRON CRUCIBLE — TACTICAL ARENA TDM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(0.0, 0.9, 1.0)
	vbox.add_child(title)

	var sub = Label.new()
	sub.text = "CYBERNETIC GLADIATOR DEATHMATCH"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 15)
	sub.modulate = Color(0.8, 0.85, 0.95)
	vbox.add_child(sub)

	var obj_lbl = Label.new()
	obj_lbl.text = "OBJECTIVE: FIRST TO 20 FRAGS CLAIMS VICTORY!"
	obj_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	obj_lbl.add_theme_font_size_override("font_size", 14)
	obj_lbl.modulate = Color(1.0, 0.85, 0.2)
	vbox.add_child(obj_lbl)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var ctrl_grid = GridContainer.new()
	ctrl_grid.columns = 2
	ctrl_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(ctrl_grid)

	var controls_data = [
		["WASD", "Move & Strafe Locomotion"],
		["MOUSE", "Aim / Look & Recoil Control"],
		["LEFT CLICK", "Fire Equipped Weapon"],
		["RIGHT CLICK", "Aim Down Sights (ADS)"],
		["1 - 5 / WHEEL", "Switch Weapons (Pulse, Scatter, Rail, Grenade, Plasma)"],
		["SPACE / SHIFT", "Jump / Sprint Locomotion"],
		["C", "Tactical Crouch & Slide"]
	]
	for c in controls_data:
		var k = Label.new()
		k.text = c[0] + "  "
		k.modulate = Color(0.0, 1.0, 0.8)
		k.add_theme_font_size_override("font_size", 13)
		ctrl_grid.add_child(k)

		var a = Label.new()
		a.text = c[1]
		a.modulate = Color.WHITE
		a.add_theme_font_size_override("font_size", 13)
		ctrl_grid.add_child(a)

	var prompt_lbl = Label.new()
	prompt_lbl.text = "MATCH STARTING (PRESS ANY KEY OR SPACE TO START)"
	prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_lbl.add_theme_font_size_override("font_size", 12)
	prompt_lbl.modulate = Color(0.7, 0.85, 0.95)
	vbox.add_child(prompt_lbl)

func dismiss_onboarding() -> void:
	if not is_instance_valid(onboarding_overlay) or not onboarding_overlay.visible:
		return
	var tween = create_tween()
	tween.tween_property(onboarding_overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		onboarding_overlay.visible = false
	)

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(onboarding_overlay) and onboarding_overlay.visible:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			dismiss_onboarding()
