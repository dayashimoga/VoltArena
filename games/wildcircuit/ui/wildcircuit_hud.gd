class_name WildCircuitHUD
extends Control

## WildCircuitHUD: Responsive Viewfinder Camera UI & Conservation Ranger Mission Tracker.
## Features camera reticle, zoom focal length indicator, photo flash, and journal popup.

signal shutter_pressed()
signal journal_toggled()

var viewfinder_overlay: Control
var focus_reticle: Control
var zoom_label: Label
var subject_label: Label
var biome_label: Label
var time_label: Label
var mission_label: Label
var photo_popup: PanelContainer
var photo_result_label: Label

var is_viewfinder_active: bool = false
var current_focal_length: float = 70.0 # 24mm to 300mm

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_ui()

func setup_ui() -> void:
	# 1. Standard Exploration Header
	var top_left = VBoxContainer.new()
	top_left.position = Vector2(24, 20)
	top_left.add_theme_constant_override("separation", 4)
	add_child(top_left)

	biome_label = Label.new()
	biome_label.text = "SAVANNAH BIOME"
	biome_label.modulate = Color(1.0, 0.85, 0.2)
	biome_label.add_theme_font_size_override("font_size", 18)
	top_left.add_child(biome_label)

	time_label = Label.new()
	time_label.text = "TIME: 12:00 PM"
	time_label.add_theme_font_size_override("font_size", 13)
	top_left.add_child(time_label)

	# Top-Right: Ranger Mission
	var top_right = PanelContainer.new()
	top_right.anchor_left = 1.0
	top_right.anchor_right = 1.0
	top_right.offset_left = -280
	top_right.offset_top = 20
	top_right.offset_right = -24
	top_right.offset_bottom = 100

	var tr_vbox = VBoxContainer.new()
	top_right.add_child(tr_vbox)

	var r_header = Label.new()
	r_header.text = "RANGER MISSION"
	r_header.modulate = Color(0.2, 0.9, 1.0)
	r_header.add_theme_font_size_override("font_size", 12)
	tr_vbox.add_child(r_header)

	mission_label = Label.new()
	mission_label.text = "Photograph Gazelle Grazing"
	mission_label.add_theme_font_size_override("font_size", 14)
	tr_vbox.add_child(mission_label)
	add_child(top_right)

	# 2. Viewfinder Overlay (Shown when camera mode is active)
	viewfinder_overlay = Control.new()
	viewfinder_overlay.anchor_right = 1.0
	viewfinder_overlay.anchor_bottom = 1.0
	viewfinder_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewfinder_overlay.visible = false
	add_child(viewfinder_overlay)

	# Center Crosshairs & Brackets
	focus_reticle = Control.new()
	focus_reticle.anchor_left = 0.5
	focus_reticle.anchor_top = 0.5
	focus_reticle.anchor_right = 0.5
	focus_reticle.anchor_bottom = 0.5
	focus_reticle.offset_left = -40
	focus_reticle.offset_top = -40
	focus_reticle.offset_right = 40
	focus_reticle.offset_bottom = 40

	var ret_label = Label.new()
	ret_label.text = "[   +   ]"
	ret_label.modulate = Color(0.2, 1.0, 0.4)
	ret_label.add_theme_font_size_override("font_size", 24)
	ret_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	focus_reticle.add_child(ret_label)
	viewfinder_overlay.add_child(focus_reticle)

	# Bottom Telemetry: Focal Length & Detected Subject
	var vf_bottom = VBoxContainer.new()
	vf_bottom.anchor_top = 1.0
	vf_bottom.anchor_bottom = 1.0
	vf_bottom.anchor_right = 1.0
	vf_bottom.offset_top = -90
	vf_bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	viewfinder_overlay.add_child(vf_bottom)

	subject_label = Label.new()
	subject_label.text = "Subject: Scanning..."
	subject_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subject_label.add_theme_font_size_override("font_size", 16)
	subject_label.modulate = Color(1.0, 0.95, 0.3)
	vf_bottom.add_child(subject_label)

	zoom_label = Label.new()
	zoom_label.text = "FOCAL LENGTH: 70mm  |  [LMB] CAPTURE  |  [RMB] EXIT VIEW"
	zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zoom_label.add_theme_font_size_override("font_size", 13)
	vf_bottom.add_child(zoom_label)

	# 3. Photo Captured Rating Popup
	photo_popup = PanelContainer.new()
	photo_popup.anchor_left = 0.5
	photo_popup.anchor_top = 0.5
	photo_popup.anchor_right = 0.5
	photo_popup.anchor_bottom = 0.5
	photo_popup.offset_left = -160
	photo_popup.offset_top = -80
	photo_popup.offset_right = 160
	photo_popup.offset_bottom = 80
	photo_popup.visible = false

	var pop_vbox = VBoxContainer.new()
	pop_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	photo_popup.add_child(pop_vbox)

	var snap_title = Label.new()
	snap_title.text = "PHOTO LOGGED!"
	snap_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	snap_title.modulate = Color(0.2, 1.0, 0.4)
	snap_title.add_theme_font_size_override("font_size", 18)
	pop_vbox.add_child(snap_title)

	photo_result_label = Label.new()
	photo_result_label.text = "Score: 92  •  PLATINUM ★★★★\nThomson's Gazelle (Grazing)"
	photo_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	photo_result_label.add_theme_font_size_override("font_size", 14)
	pop_vbox.add_child(photo_result_label)

	add_child(photo_popup)

func toggle_viewfinder(active: bool) -> void:
	is_viewfinder_active = active
	if viewfinder_overlay:
		viewfinder_overlay.visible = active

func update_subject_info(species_name: String, distance_text: String, behavior: String) -> void:
	if subject_label:
		subject_label.text = "%s (%s) — %s" % [species_name, distance_text, behavior]

func update_zoom(focal_mm: float) -> void:
	current_focal_length = focal_mm
	if zoom_label:
		zoom_label.text = "FOCAL LENGTH: %dmm  |  [LMB] CAPTURE  |  [RMB] EXIT VIEW" % int(focal_mm)

func update_biome(b_name: String) -> void:
	if biome_label:
		biome_label.text = (b_name + " BIOME").to_upper()

func update_time_display(hour: int, minute: int) -> void:
	if time_label:
		var am_pm = "AM" if hour < 12 else "PM"
		var h = hour if hour <= 12 else hour - 12
		if h == 0: h = 12
		time_label.text = "TIME: %02d:%02d %s" % [h, minute, am_pm]

func show_photo_result(photo_record: Dictionary) -> void:
	if photo_popup and photo_result_label:
		var score = photo_record.get("score", 0)
		var grade = photo_record.get("grade", "Bronze")
		var sp_name = photo_record.get("species_name", "Animal")
		var beh = photo_record.get("behavior", "")
		photo_result_label.text = "Score: %d  •  %s\n%s (%s)" % [score, grade.to_upper(), sp_name, beh]
		photo_popup.visible = true

		var tree = get_tree()
		if tree:
			tree.create_timer(2.5).timeout.connect(func():
				photo_popup.visible = false
			)
