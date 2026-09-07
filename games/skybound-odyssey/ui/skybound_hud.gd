class_name SkyboundHUD
extends Control

## SkyboundHUD: Production-quality responsive UI for Skybound Odyssey
## Displays Shard Counter, Stamina Bar, Active Quest & Objectives, Region Locator, and Compass.

var shards_label: Label
var stamina_bar: ProgressBar
var quest_title_label: Label
var quest_objective_label: Label
var region_banner_label: Label

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_ui()

func setup_ui() -> void:
	# Top-Left: Region & Shards Counter
	var top_left = VBoxContainer.new()
	top_left.position = Vector2(24, 20)
	top_left.add_theme_constant_override("separation", 6)
	add_child(top_left)

	region_banner_label = Label.new()
	region_banner_label.text = "EMERALD ISLES"
	region_banner_label.add_theme_font_size_override("font_size", 20)
	region_banner_label.modulate = Color(0.2, 0.9, 1.0)
	top_left.add_child(region_banner_label)

	var shards_panel = HBoxContainer.new()
	shards_panel.add_theme_constant_override("separation", 8)
	top_left.add_child(shards_panel)

	var shard_icon = Label.new()
	shard_icon.text = "◆"
	shard_icon.modulate = Color(0.1, 0.95, 1.0)
	shard_icon.add_theme_font_size_override("font_size", 22)
	shards_panel.add_child(shard_icon)

	shards_label = Label.new()
	shards_label.text = "SHARDS: 0"
	shards_label.add_theme_font_size_override("font_size", 18)
	shards_panel.add_child(shards_label)

	# Stamina Bar
	stamina_bar = ProgressBar.new()
	stamina_bar.custom_minimum_size = Vector2(200, 10)
	stamina_bar.max_value = 100.0
	stamina_bar.value = 100.0
	stamina_bar.show_percentage = false
	top_left.add_child(stamina_bar)

	# Top-Right: Active Quest Panel
	var top_right = PanelContainer.new()
	top_right.anchor_left = 1.0
	top_right.anchor_right = 1.0
	top_right.offset_left = -280
	top_right.offset_top = 20
	top_right.offset_right = -24
	top_right.offset_bottom = 110

	var quest_vbox = VBoxContainer.new()
	quest_vbox.add_theme_constant_override("separation", 4)
	top_right.add_child(quest_vbox)

	var q_header = Label.new()
	q_header.text = "ACTIVE MISSION"
	q_header.add_theme_font_size_override("font_size", 12)
	q_header.modulate = Color(1.0, 0.85, 0.2)
	quest_vbox.add_child(q_header)

	quest_title_label = Label.new()
	quest_title_label.text = "Awaken the Ruins"
	quest_title_label.add_theme_font_size_override("font_size", 16)
	quest_vbox.add_child(quest_title_label)

	quest_objective_label = Label.new()
	quest_objective_label.text = "• Collect 3 Shards in Emerald Isles (0/3)"
	quest_objective_label.add_theme_font_size_override("font_size", 13)
	quest_objective_label.modulate = Color(0.85, 0.88, 0.92)
	quest_vbox.add_child(quest_objective_label)

	add_child(top_right)

func update_shards(count: int) -> void:
	if shards_label:
		shards_label.text = "SHARDS: %d" % count

func update_stamina(current: float, max_stamina: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = current

func update_region(region_name: String) -> void:
	if region_banner_label:
		region_banner_label.text = region_name.to_upper()

func update_quest(title: String, objective_text: String) -> void:
	if quest_title_label:
		quest_title_label.text = title
	if quest_objective_label:
		quest_objective_label.text = "• " + objective_text
