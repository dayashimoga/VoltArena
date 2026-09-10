class_name InputProfile
extends RefCounted

const PlatformCapabilities = preload("res://shared/platform/platform_capabilities.gd")

## Manages input abstraction profiles, dynamic device prompt resolution,
## and platform-appropriate control schemes.

enum ProfileType {
	DESKTOP_KEYBOARD_MOUSE,
	DESKTOP_CONTROLLER,
	TOUCH_PHONE,
	TOUCH_TABLET
}

enum GenreType {
	GENRE_GENERIC,
	GENRE_FPS,
	GENRE_RACING,
	GENRE_ROCKET_CAR,
	GENRE_PLATFORMER
}

static var _current_profile: ProfileType = ProfileType.DESKTOP_KEYBOARD_MOUSE
static var _active_genre: GenreType = GenreType.GENRE_GENERIC

static func get_active_profile() -> ProfileType:
	# If mobile or web touch active, use touch profile
	if PlatformCapabilities.is_mobile():
		var vp_size = DisplayServer.screen_get_size()
		if vp_size.x > 0 and vp_size.y > 0:
			var aspect = float(vp_size.x) / float(vp_size.y)
			if aspect < 1.5 and aspect > 0.66: # Tablet aspect ratio
				return ProfileType.TOUCH_TABLET
		return ProfileType.TOUCH_PHONE
	
	if PlatformCapabilities.has_gamepad() and _current_profile == ProfileType.DESKTOP_CONTROLLER:
		return ProfileType.DESKTOP_CONTROLLER
		
	return _current_profile

static func set_active_profile(profile: ProfileType) -> void:
	_current_profile = profile

static func set_active_genre(genre: GenreType) -> void:
	_active_genre = genre

static func get_active_genre() -> GenreType:
	return _active_genre

static func is_touch_active() -> bool:
	var prof = get_active_profile()
	return prof == ProfileType.TOUCH_PHONE or prof == ProfileType.TOUCH_TABLET

static func get_action_prompt(action: String, profile: int = -1) -> String:
	var prof: int = profile if profile >= 0 else int(get_active_profile())
	
	match prof:
		ProfileType.TOUCH_PHONE, ProfileType.TOUCH_TABLET:
			match action:
				"move_forward", "move_back", "move_left", "move_right":
					return "JOYSTICK"
				"fire": return "TAP FIRE"
				"alt_fire": return "ADS"
				"jump": return "TAP JUMP"
				"boost": return "TAP BOOST"
				"drift": return "TAP DRIFT"
				"reload": return "TAP RELOAD"
				"sprint": return "SPRINT"
				"crouch": return "CROUCH"
				"pause": return "PAUSE"
				_: return action.to_upper()

		ProfileType.DESKTOP_CONTROLLER:
			match action:
				"move_forward", "move_back", "move_left", "move_right":
					return "L-STICK"
				"fire": return "RT"
				"alt_fire": return "LT"
				"jump": return "(A)"
				"boost": return "(B)"
				"drift": return "(X)"
				"reload": return "(X)"
				"sprint": return "L3"
				"crouch": return "(B)"
				"pause": return "START"
				_: return "BTN"

		ProfileType.DESKTOP_KEYBOARD_MOUSE, _:
			match action:
				"move_forward": return "W / UP"
				"move_back": return "S / DOWN"
				"move_left": return "A / LEFT"
				"move_right": return "D / RIGHT"
				"fire": return "LMB"
				"alt_fire": return "RMB"
				"jump": return "SPACE"
				"boost": return "SPACE"
				"drift": return "SHIFT"
				"reload": return "R"
				"sprint": return "SHIFT"
				"crouch": return "C"
				"pause": return "ESC"
				_:
					if InputMap.has_action(action):
						var evs = InputMap.action_get_events(action)
						if not evs.is_empty():
							return evs[0].as_text()
					return action.to_upper()
