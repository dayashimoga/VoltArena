class_name StrikeCampaignMenu
extends Control

## Campaign Mission Selector and Loadout Menu for Strike Vector.

signal start_mission_requested(mission_index: int, difficulty_idx: int)
signal return_to_launcher_requested()

const ThemeGen = preload("res://shared/ui/theme_generator.gd")

var mission_cards_container: HBoxContainer
var difficulty_option: OptionButton
var selected_mission_idx: int = 1
var selected_difficulty: int = 1

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	theme = ThemeGen.get_theme()
	setup_ui()

func setup_ui() -> void:
	# Deep cyberpunk background
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.08, 0.10, 0.16, 0.95)
	add_child(bg)

	var main_vbox = VBoxContainer.new()
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0
	main_vbox.offset_left = 40
	main_vbox.offset_top = 30
	main_vbox.offset_right = -40
	main_vbox.offset_bottom = -30
	main_vbox.add_theme_constant_override("separation", 15)
	add_child(main_vbox)

	# Header Bar
	var header = HBoxContainer.new()
	main_vbox.add_child(header)

	var title = Label.new()
	title.text = "STRIKE VECTOR // CAMPAIGN MISSIONS"
	title.add_theme_font_size_override("font_size", 26)
	title.modulate = Color(1.0, 0.45, 0.1)
	header.add_child(title)

	var spacer = Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(spacer)

	var btn_back = Button.new()
	btn_back.text = "LAUNCHER"
	btn_back.pressed.connect(func(): return_to_launcher_requested.emit())
	header.add_child(btn_back)

	# Mission Scroll Container
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	mission_cards_container = HBoxContainer.new()
	mission_cards_container.add_theme_constant_override("separation", 18)
	scroll.add_child(mission_cards_container)

	_populate_mission_cards()

	# Bottom Controls: Difficulty & Start
	var bottom_bar = HBoxContainer.new()
	bottom_bar.add_theme_constant_override("separation", 20)
	main_vbox.add_child(bottom_bar)

	var diff_label = Label.new()
	diff_label.text = "DIFFICULTY:"
	diff_label.modulate = Color(0.8, 0.85, 0.9)
	bottom_bar.add_child(diff_label)

	difficulty_option = OptionButton.new()
	difficulty_option.add_item("CASUAL")
	difficulty_option.add_item("NORMAL")
	difficulty_option.add_item("VETERAN")
	difficulty_option.add_item("ELITE")
	difficulty_option.select(1)
	difficulty_option.item_selected.connect(func(idx): selected_difficulty = idx)
	bottom_bar.add_child(difficulty_option)

	var b_spacer = Control.new()
	b_spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	bottom_bar.add_child(b_spacer)

	var btn_deploy = Button.new()
	btn_deploy.text = "DEPLOY TO MISSION"
	btn_deploy.add_theme_font_size_override("font_size", 18)
	btn_deploy.custom_minimum_size = Vector2(220, 48)
	btn_deploy.pressed.connect(func():
		start_mission_requested.emit(selected_mission_idx, selected_difficulty)
	)
	bottom_bar.add_child(btn_deploy)

func _populate_mission_cards() -> void:
	var sm = GameConstants.get_autoload(self, "SaveManager")
	var stats = sm.get_strike_vector_stats() if sm and sm.has_method("get_strike_vector_stats") else {}
	var highest_unlocked = stats.get("highest_mission", 1)
	var grades = stats.get("best_grades", {})

	for i in range(1, 9):
		var meta = MissionDefinitions.get_mission_meta(i)
		var is_unlocked = (i <= highest_unlocked)
		var card = _create_card(meta, is_unlocked, grades.get(str(i), "-"))
		mission_cards_container.add_child(card)

func _create_card(meta: Dictionary, is_unlocked: bool, best_grade: String) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 320)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	var num_lbl = Label.new()
	num_lbl.text = "MISSION 0%d" % meta["index"]
	num_lbl.modulate = Color(1.0, 0.45, 0.1) if is_unlocked else Color(0.4, 0.4, 0.4)
	vbox.add_child(num_lbl)

	var name_lbl = Label.new()
	name_lbl.text = meta["name"].to_upper()
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.modulate = Color(0.9, 0.95, 1.0) if is_unlocked else Color(0.5, 0.5, 0.5)
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = meta["desc"]
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = SIZE_EXPAND_FILL
	desc_lbl.modulate = Color(0.7, 0.75, 0.8) if is_unlocked else Color(0.4, 0.4, 0.4)
	vbox.add_child(desc_lbl)

	var grade_lbl = Label.new()
	grade_lbl.text = "BEST GRADE: " + best_grade
	grade_lbl.modulate = Color(0.2, 1.0, 0.4) if best_grade != "-" else Color(0.5, 0.5, 0.5)
	vbox.add_child(grade_lbl)

	var btn_select = Button.new()
	btn_select.text = "SELECT" if is_unlocked else "LOCKED"
	btn_select.disabled = not is_unlocked
	btn_select.pressed.connect(func():
		selected_mission_idx = meta["index"]
	)
	vbox.add_child(btn_select)

	return card
