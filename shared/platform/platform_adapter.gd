extends Node

enum PlatformType {
	WEB,
	ANDROID,
	WINDOWS,
	LINUX,
	MACOS,
	IOS
}

var current_platform: PlatformType = PlatformType.WINDOWS
var is_mobile: bool = false
var has_touchscreen: bool = false
var has_gamepad: bool = false

func _ready() -> void:
	detect_platform()
	detect_inputs()

func detect_platform() -> void:
	var os_name: String = OS.get_name().to_lower()
	if OS.has_feature("web"):
		current_platform = PlatformType.WEB
		is_mobile = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	elif os_name == "android":
		current_platform = PlatformType.ANDROID
		is_mobile = true
	elif os_name == "ios":
		current_platform = PlatformType.IOS
		is_mobile = true
	elif os_name == "windows":
		current_platform = PlatformType.WINDOWS
		is_mobile = false
	elif os_name == "macos":
		current_platform = PlatformType.MACOS
		is_mobile = false
	elif os_name == "linux" or os_name == "freebsd" or os_name == "netbsd":
		current_platform = PlatformType.LINUX
		is_mobile = false

func detect_inputs() -> void:
	has_touchscreen = DisplayServer.is_touchscreen_available() or is_mobile
	var connected_joypads = Input.get_connected_joypads()
	has_gamepad = connected_joypads.size() > 0

func is_touch_active() -> bool:
	return has_touchscreen

func get_safe_area_margins() -> Rect2:
	return DisplayServer.get_display_safe_area()

func trigger_haptic(duration_ms: int = 40, weak_magnitude: float = 0.5, strong_magnitude: float = 0.5) -> void:
	if has_gamepad:
		Input.start_joy_vibration(0, weak_magnitude, strong_magnitude, float(duration_ms) / 1000.0)
	elif is_mobile and current_platform == PlatformType.ANDROID:
		Input.vibrate_handheld(duration_ms)

func get_platform_name_string() -> String:
	match current_platform:
		PlatformType.WEB: return "Web (WASM/WebGL2)"
		PlatformType.ANDROID: return "Android"
		PlatformType.WINDOWS: return "Windows"
		PlatformType.LINUX: return "Linux"
		PlatformType.MACOS: return "macOS"
		PlatformType.IOS: return "iOS"
		_: return "Desktop"
