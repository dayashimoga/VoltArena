class_name ResultsScreen
extends CanvasLayer

signal restart_pressed()
signal launcher_pressed()

var title_label: Label
var stats_vbox: VBoxContainer

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 105
	visible = false
	setup_ui()

func setup_ui() -> void:
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.04, 0.07, 0.12, 0.35)
	add_child(bg)

	var panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -240
	panel.offset_top = -220
	panel.offset_right = 240
	panel.offset_bottom = 220
	panel.theme = ThemeGenerator.get_theme()
	add_child(panel)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	title_label = Label.new()
	title_label.text = "MATCH COMPLETE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.modulate = Color(0.0, 1.0, 0.8)
	vbox.add_child(title_label)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	stats_vbox = VBoxContainer.new()
	vbox.add_child(stats_vbox)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var btn_box = HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_box)

	var btn_restart = Button.new()
	btn_restart.text = "PLAY AGAIN"
	btn_restart.pressed.connect(func():
		visible = false
		var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if tree:
			tree.paused = false
		restart_pressed.emit()
	)
	btn_box.add_child(btn_restart)

	var btn_launcher = Button.new()
	btn_launcher.text = "LAUNCHER"
	btn_launcher.pressed.connect(func():
		visible = false
		var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
		if tree:
			tree.paused = false
		launcher_pressed.emit()
	)
	btn_box.add_child(btn_launcher)

func display_results(won: bool, stats_dict: Dictionary) -> void:
	if not title_label or not stats_vbox:
		setup_ui()

	visible = true
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree:
		tree.paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if title_label:
		if won:
			title_label.text = "VICTORY!"
			title_label.modulate = Color(0.0, 1.0, 0.5)
		else:
			title_label.text = "DEFEAT"
			title_label.modulate = Color(1.0, 0.2, 0.3)

	# Clear old stats
	if stats_vbox:
		for child in stats_vbox.get_children():
			child.queue_free()

		for k in stats_dict.keys():
			var row = HBoxContainer.new()
			var lbl_name = Label.new()
			lbl_name.text = str(k).capitalize() + ":"
			lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var lbl_val = Label.new()
			lbl_val.text = str(stats_dict[k])
			lbl_val.modulate = Color(0.0, 0.9, 1.0)
			row.add_child(lbl_name)
			row.add_child(lbl_val)
			stats_vbox.add_child(row)
