class_name ArenaFPSHUD
extends HUDBase

var frags_label: Label
var target_kills: int = 20
var current_frags: int = 0

func setup_hud_layout() -> void:
	super.setup_hud_layout()
	_setup_arena_extras()

func _setup_arena_extras() -> void:
	# Top Left Frags Badge
	var frag_panel = PanelContainer.new()
	frag_panel.position = Vector2(24, 24)
	frag_panel.custom_minimum_size = Vector2(160, 48)
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

func update_frags(frags: int, target: int = 20) -> void:
	current_frags = frags
	target_kills = target
	if frags_label:
		frags_label.text = "FRAGS: %d / %d" % [current_frags, target_kills]
