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
		"strike_vector":
			_paint_strike_vector(image, width, height)
		_:
			_paint_default_banner(image, width, height)

	return ImageTexture.create_from_image(image)

static func _paint_iron_crucible(img: Image, w: int, h: int) -> void:
	# Tactical Arena FPS: Bright twilight dusk sky with sci-fi catwalks & laser arcs
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)

			# Sky and arena gradient (rich dusk blue to steel gray)
			var base_r = lerp(0.20, 0.35, v)
			var base_g = lerp(0.35, 0.45, v)
			var base_b = lerp(0.55, 0.65, v)

			# Catwalk silhouette structure
			var is_catwalk = (y > h * 0.48 and y < h * 0.54)
			var is_catwalk_support = (x % 50 == 0 and y > h * 0.48)
			if is_catwalk or is_catwalk_support:
				base_r = 0.15
				base_g = 0.20
				base_b = 0.28

			# Floor platform
			if y > h * 0.75:
				base_r = 0.28
				base_g = 0.32
				base_b = 0.40
				if (x % 30 == 0) or (y % 15 == 0):
					base_r += 0.1
					base_g += 0.15
					base_b += 0.2

			# Neon Cyan Laser Beam across center
			var dist_to_beam = abs(float(y) - float(h) * 0.40 - (u - 0.5) * 45.0)
			if dist_to_beam < 5.0:
				var glow = 1.0 - (dist_to_beam / 5.0)
				base_r = lerp(base_r, 0.3, glow)
				base_g = lerp(base_g, 0.95, glow)
				base_b = lerp(base_b, 1.0, glow)

			# Crosshair reticle at center
			var dist_cross = Vector2(x - w * 0.5, y - h * 0.40).length()
			if (dist_cross >= 14.0 and dist_cross <= 16.0) or (abs(x - w * 0.5) < 2.0 and dist_cross < 22.0) or (abs(y - h * 0.40) < 2.0 and dist_cross < 22.0):
				base_r = 0.1
				base_g = 1.0
				base_b = 1.0

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_metro_siege(img: Image, w: int, h: int) -> void:
	# Metro Siege: High-contrast illuminated underground platform, vaulted ceiling & warning lines
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)

			# Tiled wall and arched ceiling gradient
			var base_r = lerp(0.40, 0.30, v)
			var base_g = lerp(0.44, 0.32, v)
			var base_b = lerp(0.50, 0.38, v)

			# Ceramic subway tile grout pattern
			if (x % 24 == 0 or y % 16 == 0) and y < h * 0.65:
				base_r *= 0.75
				base_g *= 0.75
				base_b *= 0.75

			# Overhead fluorescent light fixtures casting bright white beams
			if y > h * 0.08 and y < h * 0.14:
				if (x % 60) > 15:
					base_r = 0.98
					base_g = 0.98
					base_b = 1.0

			# Passenger Platform Floor (left side)
			if y > h * 0.65:
				if u < 0.65:
					base_r = 0.52
					base_g = 0.55
					base_b = 0.60
				else:
					# Sunken tracks
					base_r = 0.28
					base_g = 0.30
					base_b = 0.34

			# Platform Edge Hazard Stripe (Yellow/Black)
			if y > h * 0.64 and y < h * 0.68 and u >= 0.60 and u <= 0.66:
				var stripe = ((x + y) / 8) % 2 == 0
				base_r = 0.95 if stripe else 0.15
				base_g = 0.85 if stripe else 0.15
				base_b = 0.10 if stripe else 0.15

			# Red Emergency Beacon Light at right
			var dist_beacon = Vector2(x - w * 0.85, y - h * 0.45).length()
			if dist_beacon < 25.0:
				var glow = 1.0 - (dist_beacon / 25.0)
				base_r = lerp(base_r, 1.0, glow * 0.8)
				base_g = lerp(base_g, 0.2, glow * 0.8)
				base_b = lerp(base_b, 0.2, glow * 0.8)

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_nitro_kick(img: Image, w: int, h: int) -> void:
	# Nitro Kick: High-energy illuminated sports stadium, floodlights, turf & ball
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)

			# Deep indigo stadium sky to cobalt bowl
			var base_r = lerp(0.15, 0.25, v)
			var base_g = lerp(0.25, 0.45, v)
			var base_b = lerp(0.55, 0.75, v)

			# Floodlight illumination beams from top corners
			var dist_tl = Vector2(x - 20, y - 10).length()
			var dist_tr = Vector2(x - (w - 20), y - 10).length()
			if dist_tl < 120.0:
				var beam = (1.0 - dist_tl / 120.0) * 0.35
				base_r += beam
				base_g += beam
				base_b += beam
			if dist_tr < 120.0:
				var beam = (1.0 - dist_tr / 120.0) * 0.35
				base_r += beam
				base_g += beam
				base_b += beam

			# Green Stadium Turf Pitch (bottom half)
			if y > h * 0.58:
				var stripe = ((y / 18) % 2 == 0)
				base_r = 0.22 if stripe else 0.16
				base_g = 0.65 if stripe else 0.52
				base_b = 0.28 if stripe else 0.22

				# Center circle chalk line
				var dist_circle = Vector2(x - w * 0.5, (y - h * 0.75) * 2.5).length()
				if dist_circle >= 42.0 and dist_circle <= 46.0:
					base_r = 0.95
					base_g = 0.98
					base_b = 0.95

			# Glowing Energy Ball in midair
			var dist_ball = Vector2(x - w * 0.5, y - h * 0.48).length()
			if dist_ball < 22.0:
				var glow = 1.0 - (dist_ball / 22.0)
				base_r = lerp(base_r, 1.0, glow)
				base_g = lerp(base_g, 0.85, glow)
				base_b = lerp(base_b, 0.2, glow)

			# Rocket boost orange flame trail
			if x > w * 0.15 and x < w * 0.45 and abs(float(y) - float(h) * 0.55) < 8.0:
				var flame_factor = 1.0 - abs(float(y) - float(h) * 0.55) / 8.0
				base_r = lerp(base_r, 1.0, flame_factor * 0.85)
				base_g = lerp(base_g, 0.5, flame_factor * 0.85)
				base_b = lerp(base_b, 0.05, flame_factor * 0.85)

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_drift_storm(img: Image, w: int, h: int) -> void:
	# Drift Storm: Bright daylight coastal canyon circuit, red/white curbstones & sun
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)

			# Sky gradient (Azure blue to warm peach horizon)
			var base_r: float
			var base_g: float
			var base_b: float

			if v < 0.52:
				base_r = lerp(0.35, 0.85, v / 0.52)
				base_g = lerp(0.65, 0.80, v / 0.52)
				base_b = lerp(0.98, 0.82, v / 0.52)

				# Sun flare
				var dist_sun = Vector2(x - w * 0.65, y - h * 0.28).length()
				if dist_sun < 35.0:
					var sun_glow = 1.0 - (dist_sun / 35.0)
					base_r = lerp(base_r, 1.0, sun_glow)
					base_g = lerp(base_g, 0.95, sun_glow)
					base_b = lerp(base_b, 0.65, sun_glow)
			else:
				# Asphalt Track Surface
				base_r = 0.35
				base_g = 0.38
				base_b = 0.42

				# Center dashed line
				var center_dist = abs(float(x) - float(w) * 0.5 + (v - 0.52) * 60.0)
				if center_dist < 3.0 and (y % 20 < 12):
					base_r = 0.95
					base_g = 0.85
					base_b = 0.15

				# Red & White Rumble Curbstones on left edge
				var curb_dist = abs(float(x) - float(w) * 0.20 + (v - 0.52) * 40.0)
				if curb_dist < 8.0:
					var is_red = ((x + y) / 12) % 2 == 0
					base_r = 0.92 if is_red else 0.96
					base_g = 0.18 if is_red else 0.96
					base_b = 0.18 if is_red else 0.96

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_strike_vector(img: Image, w: int, h: int) -> void:
	# Strike Vector: High-speed forward-moving sci-fi run-and-gun perspective
	# Atmospheric twilight sky, high-tech urban skyscrapers, forward road vanishing point, and orange/cyan weapon tracers
	var vp_x = float(w) * 0.5
	var vp_y = float(h) * 0.42

	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)
			var base_r: float = 0.08
			var base_g: float = 0.09
			var base_b: float = 0.14

			if y < h * 0.42:
				# Sky gradient with atmospheric dusk haze
				base_r = lerp(0.12, 0.45, v / 0.42)
				base_g = lerp(0.10, 0.22, v / 0.42)
				base_b = lerp(0.25, 0.38, v / 0.42)

				# Skyscraper silhouettes on left and right flanks
				var flank_dist = abs(u - 0.5)
				if flank_dist > 0.28:
					var building_step = int(x / 24) * 24
					var building_height = (sin(building_step * 0.12) * 0.5 + 0.5) * h * 0.35
					if y > (h * 0.42 - building_height):
						base_r = 0.05
						base_g = 0.06
						base_b = 0.10
						if (x % 6 == 0) and (y % 8 == 0) and ((x + y) % 5 == 0):
							base_r += 0.4
							base_g += 0.5
							base_b += 0.7
			else:
				# Forward perspective road / combat corridor
				var road_t = (y - vp_y) / (h - vp_y)
				base_r = lerp(0.12, 0.20, road_t)
				base_g = lerp(0.13, 0.22, road_t)
				base_b = lerp(0.16, 0.28, road_t)

				# Road perspective lines receding to vanishing point
				var dx = (x - vp_x) / (road_t + 0.01)
				if abs(dx) < 180.0:
					# Road lane lines
					if abs(dx) < 8.0 and (y % 16 < 9):
						base_r = 1.0
						base_g = 0.75
						base_b = 0.15
					elif abs(abs(dx) - 80.0) < 6.0:
						base_r = 0.1
						base_g = 0.85
						base_b = 0.95
					elif abs(abs(dx) - 160.0) < 12.0:
						# Outer barrier
						base_r = 0.3
						base_g = 0.35
						base_b = 0.45

			# Forward Tracers / Laser Fire
			var tracer1 = abs((y - vp_y) * 1.6 - (x - vp_x))
			if tracer1 < 3.5 and y > vp_y + 15:
				var glow = 1.0 - (tracer1 / 3.5)
				base_r = lerp(base_r, 1.0, glow)
				base_g = lerp(base_g, 0.45, glow)
				base_b = lerp(base_b, 0.1, glow)

			var tracer2 = abs((y - vp_y) * -1.8 - (x - vp_x))
			if tracer2 < 3.0 and y > vp_y + 20:
				var glow2 = 1.0 - (tracer2 / 3.0)
				base_r = lerp(base_r, 0.1, glow2)
				base_g = lerp(base_g, 0.95, glow2)
				base_b = lerp(base_b, 1.0, glow2)

			# Central Holo Targeting Crosshair
			var center_d = Vector2(x - vp_x, y - (vp_y + 10)).length()
			if abs(center_d - 16.0) < 1.8 or (center_d < 3.0):
				base_r = lerp(base_r, 1.0, 0.9)
				base_g = lerp(base_g, 0.35, 0.9)
				base_b = lerp(base_b, 0.1, 0.9)

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_default_banner(img: Image, w: int, h: int) -> void:
	for y in range(h):
		for x in range(w):
			var r = float(x) / float(w) * 0.5 + 0.2
			var b = float(y) / float(h) * 0.5 + 0.3
			img.set_pixel(x, y, Color(r, 0.4, b))
