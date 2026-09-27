class_name WorldSelectScreen
extends CanvasLayer

## World / City Selection Screen for Chroma Rush
## Interactive city selection with scenic previews, world lore, track stats,
## game mode selector (Color Hunt, Chroma Sprint, Puzzle Drive, Free Drive Practice),
## and instant mission launch.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")

signal world_mode_selected(world_id: String, mode_id: String)
signal back_pressed()

var worlds_data: Array[Dictionary] = [
	{
		"id": ChromaConstants.WORLD_NEON_CITY,
		"name": "NEON METROPOLIS",
		"tagline": "Dense Commercial District & Towering Skylines",
		"description": "High-density urban grid featuring realistic commercial architecture, modern asphalt roadways, street lighting, and tight city corners.",
		"difficulty": "BEGINNER - INTERMEDIATE",
		"track_length": "2.8 KM Circuit",
		"theme_color": Color(0.15, 0.75, 1.0)
	},
	{
		"id": ChromaConstants.WORLD_COASTAL_RUSH,
		"name": "COASTAL HIGHWAY",
		"tagline": "Ocean Cliffside & Great Suspension Bridge",
		"description": "Scenic seaside expressway skirting sparkling azure waters, lighthouse bluffs, long suspension bridge straights, and coastal safety barriers.",
		"difficulty": "INTERMEDIATE",
		"track_length": "3.5 KM Circuit",
		"theme_color": Color(0.20, 0.90, 0.70)
	},
	{
		"id": ChromaConstants.WORLD_PRISM_CANYON,
		"name": "PRISM CANYON",
		"tagline": "Sandstone Gorges & Natural Rock Arches",
		"description": "Dynamic elevation desert switchbacks carved through red sandstone cliffs, natural stone arches, and high-plateau mesa overlooks.",
		"difficulty": "ADVANCED",
		"track_length": "4.1 KM Circuit",
		"theme_color": Color(1.0, 0.55, 0.25)
	},
	{
		"id": ChromaConstants.WORLD_SKY_CIRCUIT,
		"name": "STRATOSPHERE SKYWAY",
		"tagline": "Multi-Tier Highway Suspended Above the Clouds",
		"description": "High-altitude multi-level energy skyway floating above a silver cloud deck, featuring spiral corkscrew ramps, steep banks, and velocity zones.",
		"difficulty": "EXPERT",
		"track_length": "4.8 KM Multi-Tier",
		"theme_color": Color(0.85, 0.35, 1.0)
	}
]

var selected_world_idx: int = 0
var selected_mode: String = "hunt" # "hunt", "sprint", "puzzle", "free_drive"

# UI Nodes
var world_title_label: Label
var tagline_label: Label
var desc_label: Label
var difficulty_label: Label
var length_label: Label
var preview_panel: PanelContainer
var mode_buttons: Dictionary = {}

func _ready() -> void:
	layer = 12
	_build_ui()
	_update_selection()

func _build_ui() -> void:
	var root = Control.new()
	root.name = "WorldSelectRoot"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	add_child(root)

	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.03, 0.05, 0.08, 0.96)
	root.add_child(bg)

	# Main Margin Container
	var main_margin = MarginContainer.new()
	main_margin.anchor_right = 1.0
	main_margin.anchor_bottom = 1.0
	main_margin.add_theme_constant_override("margin_left", 36)
	main_margin.add_theme_constant_override("margin_top", 24)
	main_margin.add_theme_constant_override("margin_right", 36)
	main_margin.add_theme_constant_override("margin_bottom", 24)
	root.add_child(main_margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 18)
	main_margin.add_child(main_vbox)

	# --- HEADER ---
	var header_hbox = HBoxContainer.new()
	main_vbox.add_child(header_hbox)

	var title = Label.new()
	title.text = "SELECT WORLD & DRIVING MODE"
	title.add_theme_font_size_override("font_size", 26)
	title.modulate = Color(0.0, 1.0, 0.85)
	header_hbox.add_child(title)

	var h_spacer = Control.new()
	h_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(h_spacer)

	var back_btn = Button.new()
	back_btn.text = "◀ BACK TO MENU"
	back_btn.custom_minimum_size = Vector2(140, 36)
	back_btn.pressed.connect(func(): back_pressed.emit())
	header_hbox.add_child(back_btn)

	# --- CONTENT SPLIT: LEFT (CARDS) & RIGHT (PREVIEW & LAUNCH) ---
	var split_hbox = HBoxContainer.new()
	split_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_hbox.add_theme_constant_override("separation", 24)
	main_vbox.add_child(split_hbox)

	# Left Column: World Selector Buttons
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(360, 0)
	left_vbox.add_theme_constant_override("separation", 12)
	split_hbox.add_child(left_vbox)

	for i in range(worlds_data.size()):
		var w = worlds_data[i]
		var card = Button.new()
		card.custom_minimum_size = Vector2(0, 80)
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var c_vbox = VBoxContainer.new()
		c_vbox.offset_left = 14
		c_vbox.offset_top = 8
		c_vbox.offset_right = -14
		c_vbox.offset_bottom = -8
		card.add_child(c_vbox)

		var c_title = Label.new()
		c_title.text = "%d. %s" % [i + 1, w["name"]]
		c_title.add_theme_font_size_override("font_size", 16)
		c_title.modulate = w["theme_color"]
		c_vbox.add_child(c_title)

		var c_tag = Label.new()
		c_tag.text = w["tagline"]
		c_tag.add_theme_font_size_override("font_size", 11)
		c_tag.modulate = Color(0.65, 0.72, 0.82)
		c_vbox.add_child(c_tag)

		card.pressed.connect(func(idx=i): _select_world(idx))
		left_vbox.add_child(card)

	# Right Column: Detailed World View, Mode Selection & Launch
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rp_style = StyleBoxFlat.new()
	rp_style.bg_color = Color(0.06, 0.08, 0.14, 0.85)
	rp_style.border_color = Color(0.18, 0.45, 0.75, 0.5)
	rp_style.set_border_width_all(1)
	rp_style.set_corner_radius_all(8)
	right_panel.add_theme_stylebox_override("panel", rp_style)
	split_hbox.add_child(right_panel)

	var right_vbox = VBoxContainer.new()
	right_vbox.offset_left = 24
	right_vbox.offset_top = 20
	right_vbox.offset_right = -24
	right_vbox.offset_bottom = -20
	right_vbox.add_theme_constant_override("separation", 16)
	right_panel.add_child(right_vbox)

	world_title_label = Label.new()
	world_title_label.text = "WORLD NAME"
	world_title_label.add_theme_font_size_override("font_size", 28)
	right_vbox.add_child(world_title_label)

	tagline_label = Label.new()
	tagline_label.text = "Tagline here"
	tagline_label.add_theme_font_size_override("font_size", 14)
	tagline_label.modulate = Color(0.7, 0.8, 0.9)
	right_vbox.add_child(tagline_label)

	desc_label = Label.new()
	desc_label.text = "Description here..."
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 13)
	right_vbox.add_child(desc_label)

	var stats_hbox = HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 30)
	right_vbox.add_child(stats_hbox)

	difficulty_label = Label.new()
	difficulty_label.text = "DIFFICULTY: BEGINNER"
	difficulty_label.add_theme_font_size_override("font_size", 13)
	difficulty_label.modulate = Color(1.0, 0.8, 0.2)
	stats_hbox.add_child(difficulty_label)

	length_label = Label.new()
	length_label.text = "TRACK LENGTH: 2.8 KM"
	length_label.add_theme_font_size_override("font_size", 13)
	length_label.modulate = Color(0.4, 0.9, 1.0)
	stats_hbox.add_child(length_label)

	var sep = HSeparator.new()
	right_vbox.add_child(sep)

	# Mode Selection Buttons
	var mode_hdr = Label.new()
	mode_hdr.text = "SELECT EVENT / DRIVING MODE:"
	mode_hdr.add_theme_font_size_override("font_size", 14)
	mode_hdr.modulate = Color(0.8, 0.9, 1.0)
	right_vbox.add_child(mode_hdr)

	var modes_grid = GridContainer.new()
	modes_grid.columns = 2
	modes_grid.add_theme_constant_override("h_separation", 12)
	modes_grid.add_theme_constant_override("v_separation", 10)
	right_vbox.add_child(modes_grid)

	_add_mode_button(modes_grid, "hunt", "🎯 COLOR HUNT", "Objective-based swap pursuit")
	_add_mode_button(modes_grid, "sprint", "⚡ CHROMA SPRINT", "High-speed gate time attack")
	_add_mode_button(modes_grid, "puzzle", "🧩 PUZZLE DRIVE", "Color sequence logic puzzles")
	_add_mode_button(modes_grid, "free_drive", "🏁 FREE DRIVE (PRACTICE)", "Untimed cruise & track exploration")

	var spacer_end = Control.new()
	spacer_end.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(spacer_end)

	var launch_btn = Button.new()
	launch_btn.text = "▶ START DRIVING"
	launch_btn.custom_minimum_size = Vector2(0, 48)
	launch_btn.add_theme_font_size_override("font_size", 18)
	launch_btn.modulate = Color(0.1, 1.0, 0.6)
	launch_btn.pressed.connect(_on_launch_pressed)
	right_vbox.add_child(launch_btn)

func _add_mode_button(parent: Control, m_id: String, m_title: String, m_desc: String) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(240, 52)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	var vb = VBoxContainer.new()
	vb.offset_left = 10
	vb.offset_top = 6
	vb.offset_right = -10
	vb.offset_bottom = -6
	btn.add_child(vb)

	var t = Label.new()
	t.text = m_title
	t.add_theme_font_size_override("font_size", 13)
	vb.add_child(t)

	var d = Label.new()
	d.text = m_desc
	d.add_theme_font_size_override("font_size", 10)
	d.modulate = Color(0.65, 0.70, 0.80)
	vb.add_child(d)

	btn.pressed.connect(func(): _select_mode(m_id))
	parent.add_child(btn)
	mode_buttons[m_id] = btn

func _select_world(idx: int) -> void:
	selected_world_idx = idx
	_update_selection()

func _select_mode(m_id: String) -> void:
	selected_mode = m_id
	for key in mode_buttons:
		var btn = mode_buttons[key] as Button
		if key == selected_mode:
			btn.modulate = Color(0.0, 1.0, 0.85)
		else:
			btn.modulate = Color.WHITE

func _update_selection() -> void:
	var w = worlds_data[selected_world_idx]
	if is_instance_valid(world_title_label):
		world_title_label.text = w["name"]
		world_title_label.modulate = w["theme_color"]
		tagline_label.text = w["tagline"]
		desc_label.text = w["description"]
		difficulty_label.text = "DIFFICULTY: " + w["difficulty"]
		length_label.text = "TRACK LENGTH: " + w["track_length"]
	_select_mode(selected_mode)

func _on_launch_pressed() -> void:
	var w = worlds_data[selected_world_idx]
	world_mode_selected.emit(w["id"], selected_mode)
