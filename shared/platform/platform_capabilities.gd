class_name PlatformCapabilities
extends RefCounted

## Universal platform and hardware capability detector
## Provides display metrics, safe area insets, device tiers, and input detection

enum DeviceTier {
	TIER_LOW,
	TIER_MEDIUM,
	TIER_HIGH,
	TIER_ULTRA
}

enum PlatformCategory {
	WEB,
	ANDROID,
	WINDOWS,
	LINUX,
	MACOS,
	IOS
}

static func get_platform_category() -> PlatformCategory:
	if OS.has_feature("web"):
		return PlatformCategory.WEB
	var os_name = OS.get_name().to_lower()
	match os_name:
		"android": return PlatformCategory.ANDROID
		"ios": return PlatformCategory.IOS
		"windows": return PlatformCategory.WINDOWS
		"macos": return PlatformCategory.MACOS
		"linux", "freebsd", "netbsd": return PlatformCategory.LINUX
		_: return PlatformCategory.WINDOWS

static func is_mobile() -> bool:
	var cat = get_platform_category()
	if cat == PlatformCategory.ANDROID or cat == PlatformCategory.IOS:
		return true
	if cat == PlatformCategory.WEB:
		return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	return false

static func is_desktop() -> bool:
	return not is_mobile()

static func is_web() -> bool:
	return get_platform_category() == PlatformCategory.WEB

static func has_touchscreen() -> bool:
	return DisplayServer.is_touchscreen_available() or is_mobile()

static func has_gamepad() -> bool:
	return Input.get_connected_joypads().size() > 0

static func get_safe_area() -> Rect2:
	return DisplayServer.get_display_safe_area()

static func get_safe_area_margins(viewport_size: Vector2) -> Dictionary:
	var safe = get_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0:
		return {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
	
	# If safe area is full screen, margins are 0
	var screen_size = DisplayServer.screen_get_size()
	if screen_size.x <= 0 or screen_size.y <= 0:
		return {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
	
	var scale_x = viewport_size.x / float(screen_size.x)
	var scale_y = viewport_size.y / float(screen_size.y)
	
	var left = safe.position.x * scale_x
	var top = safe.position.y * scale_y
	var right = (screen_size.x - (safe.position.x + safe.size.x)) * scale_x
	var bottom = (screen_size.y - (safe.position.y + safe.size.y)) * scale_y
	
	return {
		"left": maxf(0.0, left),
		"top": maxf(0.0, top),
		"right": maxf(0.0, right),
		"bottom": maxf(0.0, bottom)
	}

static func apply_safe_area_margins(control: Control) -> void:
	if not control:
		return
	var vp = control.get_viewport()
	var vp_size = vp.get_visible_rect().size if vp else control.size
	var margins = get_safe_area_margins(vp_size)
	control.offset_left = margins["left"]
	control.offset_top = margins["top"]
	control.offset_right = -margins["right"]
	control.offset_bottom = -margins["bottom"]

static func get_aspect_ratio_category(viewport_size: Vector2) -> String:
	if viewport_size.y <= 0:
		return "16:9"
	var aspect: float = viewport_size.x / viewport_size.y
	if aspect < 1.0:
		# Portrait aspect ratio inverse
		aspect = 1.0 / aspect
	
	if is_equal_approx(aspect, 16.0 / 9.0) or absf(aspect - 1.777) < 0.05:
		return "16:9"
	elif is_equal_approx(aspect, 16.0 / 10.0) or absf(aspect - 1.6) < 0.05:
		return "16:10"
	elif is_equal_approx(aspect, 18.0 / 9.0) or absf(aspect - 2.0) < 0.05:
		return "18:9"
	elif is_equal_approx(aspect, 19.5 / 9.0) or absf(aspect - 2.166) < 0.05:
		return "19.5:9"
	elif is_equal_approx(aspect, 20.0 / 9.0) or absf(aspect - 2.222) < 0.05:
		return "20:9"
	elif aspect < 1.5:
		return "tablet_4:3"
	else:
		return "ultrawide_21:9"

static func get_device_tier() -> DeviceTier:
	if OS.has_feature("web"):
		# Web typically runs best on medium tier for consistent 60fps
		return DeviceTier.TIER_MEDIUM
	elif OS.has_feature("mobile") or is_mobile():
		var processors = OS.get_processor_count()
		if processors <= 4:
			return DeviceTier.TIER_LOW
		elif processors <= 6:
			return DeviceTier.TIER_MEDIUM
		else:
			return DeviceTier.TIER_HIGH
	else:
		# Desktop default
		var processors = OS.get_processor_count()
		if processors >= 8:
			return DeviceTier.TIER_ULTRA
		elif processors >= 4:
			return DeviceTier.TIER_HIGH
		else:
			return DeviceTier.TIER_MEDIUM

static func get_min_touch_target_size() -> Vector2:
	# Material Design & Apple HIG standard: 48dp / 44pt minimum
	# In scaled canvas 1280x720, 48px provides comfortable touch accuracy
	return Vector2(48.0, 48.0)

static func supports_haptics() -> bool:
	return has_gamepad() or (is_mobile() and get_platform_category() == PlatformCategory.ANDROID)
