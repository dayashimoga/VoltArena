class_name GraphicsProfile
extends RefCounted

const PlatformCapabilities = preload("res://shared/platform/platform_capabilities.gd")

## Adaptive graphics profile manager for cross-platform rendering scaling
## Ensures physics and gameplay logic remain strictly invariant across presets.

enum Preset {
	PRESET_LOW,
	PRESET_MEDIUM,
	PRESET_HIGH,
	PRESET_ULTRA,
	PRESET_AUTO
}

static func get_preset_name(preset: Preset) -> String:
	match preset:
		Preset.PRESET_LOW: return "Low (Performance)"
		Preset.PRESET_MEDIUM: return "Medium (Balanced)"
		Preset.PRESET_HIGH: return "High (Quality)"
		Preset.PRESET_ULTRA: return "Ultra (Maximum)"
		Preset.PRESET_AUTO: return "Auto (Hardware Scaled)"
		_: return "Medium"

static func get_settings_for_preset(preset: Preset) -> Dictionary:
	var effective_preset = preset
	if effective_preset == Preset.PRESET_AUTO:
		var tier = PlatformCapabilities.get_device_tier()
		match tier:
			PlatformCapabilities.DeviceTier.TIER_LOW: effective_preset = Preset.PRESET_LOW
			PlatformCapabilities.DeviceTier.TIER_MEDIUM: effective_preset = Preset.PRESET_MEDIUM
			PlatformCapabilities.DeviceTier.TIER_HIGH: effective_preset = Preset.PRESET_HIGH
			PlatformCapabilities.DeviceTier.TIER_ULTRA: effective_preset = Preset.PRESET_ULTRA
			_: effective_preset = Preset.PRESET_MEDIUM
	
	match effective_preset:
		Preset.PRESET_LOW:
			return {
				"render_scale": 0.75,
				"msaa_3d": RenderingServer.VIEWPORT_MSAA_DISABLED,
				"screen_space_aa": RenderingServer.VIEWPORT_SCREEN_SPACE_AA_DISABLED,
				"shadow_atlas_size": 512,
				"particle_multiplier": 0.5,
				"lod_bias": 0.6,
				"fog_enabled": false
			}
		Preset.PRESET_MEDIUM:
			return {
				"render_scale": 0.85,
				"msaa_3d": RenderingServer.VIEWPORT_MSAA_2X,
				"screen_space_aa": RenderingServer.VIEWPORT_SCREEN_SPACE_AA_FXAA,
				"shadow_atlas_size": 1024,
				"particle_multiplier": 0.75,
				"lod_bias": 0.8,
				"fog_enabled": true
			}
		Preset.PRESET_HIGH:
			return {
				"render_scale": 1.0,
				"msaa_3d": RenderingServer.VIEWPORT_MSAA_4X,
				"screen_space_aa": RenderingServer.VIEWPORT_SCREEN_SPACE_AA_FXAA,
				"shadow_atlas_size": 2048,
				"particle_multiplier": 1.0,
				"lod_bias": 1.0,
				"fog_enabled": true
			}
		Preset.PRESET_ULTRA, _:
			return {
				"render_scale": 1.0,
				"msaa_3d": RenderingServer.VIEWPORT_MSAA_8X,
				"screen_space_aa": RenderingServer.VIEWPORT_SCREEN_SPACE_AA_FXAA,
				"shadow_atlas_size": 4096,
				"particle_multiplier": 1.0,
				"lod_bias": 1.2,
				"fog_enabled": true
			}

static func apply_to_viewport(vp: Viewport, preset: Preset) -> void:
	if not vp:
		return
	var settings = get_settings_for_preset(preset)
	var rid = vp.get_viewport_rid()
	
	# Apply MSAA and Screen-Space AA
	RenderingServer.viewport_set_msaa_3d(rid, settings["msaa_3d"])
	RenderingServer.viewport_set_screen_space_aa(rid, settings["screen_space_aa"])
	
	# Apply Shadow atlas
	RenderingServer.directional_shadow_atlas_set_size(settings["shadow_atlas_size"], true)
	
	# In GL Compatibility / Mobile, render scale can be applied to viewport if supported
	if vp is Window:
		vp.scaling_3d_scale = settings["render_scale"]
	
	# Invariant check: Verify physics tick rate remains untouched (e.g. 60 Hz)
	assert(Engine.physics_ticks_per_second == 60, "Physics ticks per second must remain 60Hz regardless of graphics preset")
