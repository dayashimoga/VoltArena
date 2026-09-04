extends Node

const PRESET_LOW: int = 0
const PRESET_MEDIUM: int = 1
const PRESET_HIGH: int = 2
const PRESET_ULTRA: int = 3
const PRESET_AUTO: int = 4

var current_preset: int = PRESET_HIGH

func _ready() -> void:
	apply_preset(current_preset)

func apply_preset(preset: int) -> void:
	current_preset = preset
	var vp = get_viewport()
	if not vp:
		return

	match preset:
		PRESET_LOW:
			RenderingServer.viewport_set_msaa_3d(vp.get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_DISABLED)
			RenderingServer.viewport_set_screen_space_aa(vp.get_viewport_rid(), RenderingServer.VIEWPORT_SCREEN_SPACE_AA_DISABLED)
			RenderingServer.directional_shadow_atlas_set_size(1024, true)
		PRESET_MEDIUM:
			RenderingServer.viewport_set_msaa_3d(vp.get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_2X)
			RenderingServer.viewport_set_screen_space_aa(vp.get_viewport_rid(), RenderingServer.VIEWPORT_SCREEN_SPACE_AA_FXAA)
			RenderingServer.directional_shadow_atlas_set_size(2048, true)
		PRESET_HIGH:
			RenderingServer.viewport_set_msaa_3d(vp.get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_4X)
			RenderingServer.viewport_set_screen_space_aa(vp.get_viewport_rid(), RenderingServer.VIEWPORT_SCREEN_SPACE_AA_FXAA)
			RenderingServer.directional_shadow_atlas_set_size(4096, true)
		PRESET_ULTRA:
			RenderingServer.viewport_set_msaa_3d(vp.get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_8X)
			RenderingServer.viewport_set_screen_space_aa(vp.get_viewport_rid(), RenderingServer.VIEWPORT_SCREEN_SPACE_AA_FXAA)
			RenderingServer.directional_shadow_atlas_set_size(4096, true)
		PRESET_AUTO:
			auto_detect_and_apply()

func auto_detect_and_apply() -> void:
	if OS.has_feature("web") or OS.has_feature("mobile"):
		apply_preset(PRESET_MEDIUM)
	else:
		apply_preset(PRESET_HIGH)
