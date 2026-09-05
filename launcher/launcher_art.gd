class_name LauncherArt
extends RefCounted

## Generates original procedural stylized artwork textures for launcher cards and UI banners
## Zero external copyrighted assets: 100% vector, gradient, and procedural generation.

static func create_game_banner(game_id: String, width: int = 360, height: int = 190) -> ImageTexture:
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)

	match game_id:
		"arena_fps", "iron_crucible":
			_paint_iron_crucible(image, width, height)
		"subway_survival", "metro_siege":
			_paint_metro_siege(image, width, height)
		"rocket_car", "nitro_kick":
			_paint_nitro_kick(image, width, height)
		"kart_racing", "drift_storm":
			_paint_drift_storm(image, width, height)
		_:
			_paint_default_banner(image, width, height)

	return ImageTexture.create_from_image(image)

static func _paint_iron_crucible(img: Image, w: int, h: int) -> void:
	# Cyberpunk deep navy to charcoal gradient with cyan & gold laser grid
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)
			var base_r = lerp(0.04, 0.08, v)
			var base_g = lerp(0.06, 0.12, v)
			var base_b = lerp(0.15, 0.22, v)

			# Grid lines
			var grid_x = (x % 30 == 0)
			var grid_y = (y % 30 == 0) and (y > h * 0.4)
			if grid_x or grid_y:
				base_r += 0.08
				base_g += 0.25
				base_b += 0.35

			# Neon cyan beam across center
			var dist_to_beam = abs(float(y) - float(h) * 0.45 - (u - 0.5) * 40.0)
			if dist_to_beam < 4.0:
				var glow = 1.0 - (dist_to_beam / 4.0)
				base_r += 0.2 * glow
				base_g += 0.8 * glow
				base_b += 1.0 * glow

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_metro_siege(img: Image, w: int, h: int) -> void:
	# Gritty dark subterranean tunnel with crimson emergency lights
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)
			var base_r = lerp(0.12, 0.03, v)
			var base_g = lerp(0.04, 0.02, v)
			var base_b = lerp(0.04, 0.02, v)

			# Tunnel arch perspective
			var dx = (u - 0.5) * 2.0
			var dy = (v - 0.5) * 2.0
			var dist = sqrt(dx * dx + dy * dy)
			if dist > 0.7:
				base_r *= 0.6
				base_g *= 0.6
				base_b *= 0.6

			# Crimson glowing eyes in distance
			var d_eye1 = Vector2(x - w * 0.48, y - h * 0.52).length()
			var d_eye2 = Vector2(x - w * 0.52, y - h * 0.52).length()
			if d_eye1 < 5.0 or d_eye2 < 5.0:
				base_r = 1.0
				base_g = 0.15
				base_b = 0.1

			# Platform edge warning stripe
			if y > h * 0.82 and y < h * 0.88:
				if (x + y) % 18 < 9:
					base_r = 0.85
					base_g = 0.65
					base_b = 0.05

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_nitro_kick(img: Image, w: int, h: int) -> void:
	# Vibrant electric cobalt stadium with luminous hexagonal energy dome
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)
			var base_r = lerp(0.02, 0.08, v)
			var base_g = lerp(0.12, 0.25, v)
			var base_b = lerp(0.35, 0.60, v)

			# Hex dome pattern
			var hx = (x % 24) - 12
			var hy = (y % 20) - 10
			if abs(hx) + abs(hy) == 12:
				base_r += 0.1
				base_g += 0.35
				base_b += 0.5

			# Glowing supersonic ball in center
			var dist_ball = Vector2(x - w * 0.5, y - h * 0.45).length()
			if dist_ball < 22.0:
				var ball_glow = 1.0 - (dist_ball / 22.0)
				base_r += 0.9 * ball_glow
				base_g += 0.7 * ball_glow
				base_b += 0.1 * ball_glow

			# Speed streak lines
			if y % 14 == 0 and x > w * 0.2 and x < w * 0.8:
				base_r += 0.2
				base_g += 0.4
				base_b += 0.6

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_drift_storm(img: Image, w: int, h: int) -> void:
	# Synthwave sunset magenta & violet highway with neon horizon
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)
			# Sky gradient (top half)
			var base_r: float
			var base_g: float
			var base_b: float

			if v < 0.55:
				base_r = lerp(0.15, 0.75, v / 0.55)
				base_g = lerp(0.05, 0.15, v / 0.55)
				base_b = lerp(0.35, 0.50, v / 0.55)
			else:
				# Track asphalt
				var tv = (v - 0.55) / 0.45
				base_r = lerp(0.10, 0.04, tv)
				base_g = lerp(0.08, 0.03, tv)
				base_b = lerp(0.18, 0.08, tv)

			# Horizon neon sun
			var dist_sun = Vector2(x - w * 0.5, y - h * 0.50).length()
			if dist_sun < 32.0 and v <= 0.55:
				# Sun slices
				if (y % 6) < 4:
					base_r = 1.0
					base_g = 0.8
					base_b = 0.2

			# Perspective road lines
			if v > 0.55:
				var center_x = float(w) * 0.5
				var road_spread = (v - 0.55) * float(w) * 0.8
				if abs(float(x) - center_x) < 4.0:
					base_r += 0.5
					base_g += 0.8
					base_b += 0.9
				if abs(abs(float(x) - center_x) - road_spread) < 3.0:
					base_r += 0.9
					base_g += 0.2
					base_b += 0.8

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_default_banner(img: Image, w: int, h: int) -> void:
	for y in range(h):
		for x in range(w):
			var r = float(x) / float(w) * 0.3
			var b = float(y) / float(h) * 0.5
			img.set_pixel(x, y, Color(r, 0.1, b))
