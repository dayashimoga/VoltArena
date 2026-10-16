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
		"skybound_odyssey":
			_paint_skybound_odyssey(image, width, height)
		"roboforge_arena":
			_paint_roboforge_arena(image, width, height)
		"wildcircuit":
			_paint_wildcircuit(image, width, height)
		"strike_vector":
			_paint_strike_vector(image, width, height)
		"chroma_rush":
			_paint_chroma_rush(image, width, height)
		"aero_rush":
			_paint_aero_rush(image, width, height)
		"aircraft_flight", "apex_flight":
			_paint_apex_flight(image, width, height)
		"urban_legends":
			_paint_urban_legends(image, width, height)
		"flight_simulator_6dof", "aerosim_6dof":
			_paint_flight_simulator_6dof(image, width, height)
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

static func _paint_aero_rush(img: Image, w: int, h: int) -> void:
	# AeroRush: High-speed impossible loop with glowing cyan borders and speed streaks
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)

			# Twilight stratosphere sky gradient (deep indigo to cyan-glow horizon)
			var base_r = lerp(0.04, 0.08, v)
			var base_g = lerp(0.12, 0.35, v)
			var base_b = lerp(0.28, 0.65, v)

			# Dynamic 3D Loop Arc in center
			var loop_cx = w * 0.52
			var loop_cy = h * 0.48
			var dist_loop = Vector2(x - loop_cx, y - loop_cy).length()

			if abs(dist_loop - 48.0) < 6.0:
				var glow = 1.0 - (abs(dist_loop - 48.0) / 6.0)
				# Glowing Cyan Neon Outer Track Border
				base_r = lerp(base_r, 0.08, glow)
				base_g = lerp(base_g, 0.90, glow)
				base_b = lerp(base_b, 1.0, glow)
			elif abs(dist_loop - 42.0) < 4.0:
				# Asphalt Track Surface
				base_r = 0.15
				base_g = 0.18
				base_b = 0.22
			elif abs(dist_loop - 36.0) < 2.5:
				# High-contrast orange curb
				base_r = 1.0
				base_g = 0.45
				base_b = 0.1

			# High-speed horizontal light trails across bottom half
			if y > h * 0.65:
				var streak = fmod(float(x) * 0.25 + float(y) * 1.5, 30.0)
				if streak < 3.0:
					base_r = lerp(base_r, 0.1, 0.8)
					base_g = lerp(base_g, 0.85, 0.8)
					base_b = lerp(base_b, 1.0, 0.8)

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_apex_flight(img: Image, w: int, h: int) -> void:
	# Apex Flight: Golden sunset sky with high skyscraper silhouettes & twin jet contrails
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)

			# Sunset gradient: Rich orange-gold to twilight violet
			var base_r = lerp(0.85, 0.22, v)
			var base_g = lerp(0.55, 0.15, v)
			var base_b = lerp(0.20, 0.45, v)

			# Skyscraper skyline silhouettes in lower half
			if y > int(float(h) * 0.65):
				var building_slot = int(float(x) / 28.0)
				var b_height = (0.65 - float((building_slot * 17) % 25) * 0.01) * float(h)
				if float(y) > b_height:
					base_r = 0.08
					base_g = 0.10
					base_b = 0.15
					# Golden illuminated windows
					if (x % 6 < 3) and (y % 8 < 4) and y > int(b_height + 15):
						base_r = 0.95
						base_g = 0.82
						base_b = 0.35

			# Twin Jet Contrails climbing across sky
			var trail_y1 = float(h) * 0.70 - u * float(h) * 0.55
			var trail_y2 = trail_y1 + 4.0
			if absf(float(y) - trail_y1) < 2.5 or absf(float(y) - trail_y2) < 2.5:
				base_r = minf(1.0, base_r + 0.6)
				base_g = minf(1.0, base_g + 0.6)
				base_b = minf(1.0, base_b + 0.7)

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_urban_legends(img: Image, w: int, h: int) -> void:
	# Urban Legends: Dramatic California Golden Hour sunset over city skyline & elevated freeway viaduct
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)

			# Golden Hour Sunset Sky (Deep indigo at top -> fiery amber/crimson -> warm gold at horizon)
			var base_r: float = 0.0
			var base_g: float = 0.0
			var base_b: float = 0.0

			if v < 0.45:
				var sv = v / 0.45
				base_r = lerpf(0.18, 0.88, sv)
				base_g = lerpf(0.12, 0.45, sv)
				base_b = lerpf(0.42, 0.18, sv)
			else:
				var hv = (v - 0.45) / 0.55
				base_r = lerpf(0.88, 0.98, hv)
				base_g = lerpf(0.45, 0.72, hv)
				base_b = lerpf(0.18, 0.28, hv)

			# Low-lying setting sun orb at horizon
			var sun_cx = float(w) * 0.45
			var sun_cy = float(h) * 0.48
			var s_dist = Vector2(x - sun_cx, y - sun_cy).length()
			if s_dist < 32.0:
				var s_glow = 1.0 - (s_dist / 32.0)
				base_r += s_glow * 0.4
				base_g += s_glow * 0.35
				base_b += s_glow * 0.1

			# Downtown Skyscrapers silhouette along horizon
			if v > 0.32 and v < 0.65:
				var b_idx = int(u * 14.0)
				var b_height = float(h) * (0.35 + sin(float(b_idx) * 2.3) * 0.12 + (float(b_idx % 3) * 0.04))
				if y > int(b_height):
					base_r = 0.10
					base_g = 0.08
					base_b = 0.14
					# Window lights
					if (x % 5 < 2) and (y % 7 < 3) and y > int(b_height + 10):
						base_r = 0.95
						base_g = 0.85
						base_b = 0.40

			# Elevated Freeway Flyover Viaduct curving across lower-third
			var road_y = float(h) * (0.68 + sin(u * PI * 0.8) * 0.12)
			var road_thick = 16.0
			if absf(float(y) - road_y) < road_thick * 0.5:
				base_r = 0.14
				base_g = 0.15
				base_b = 0.18
				# Neon yellow double center divider line
				if absf(float(y) - road_y) < 1.5:
					base_r = 1.0
					base_g = 0.85
					base_b = 0.1

			# Palm Tree silhouettes in foreground
			for palm_x in [int(w * 0.12), int(w * 0.88)]:
				if abs(x - palm_x) < 3 and y > int(h * 0.50):
					base_r = 0.05
					base_g = 0.04
					base_b = 0.06
				# Fronds
				var p_dist = Vector2(x - palm_x, y - int(h * 0.50)).length()
				if p_dist < 18.0 and y <= int(h * 0.52):
					base_r = 0.06
					base_g = 0.05
					base_b = 0.07

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_skybound_odyssey(img: Image, w: int, h: int) -> void:
	# Floating Sky Realms: Celestial azure gradient, stylized cumulus decks, floating monolithic islands, glider contrail
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)

			# Ethereal celestial atmosphere gradient (deep sapphire at top to bright cyan-teal to sunset gold at horizon)
			var base_r = lerp(0.08, 0.22, v)
			var base_g = lerp(0.35, 0.70, v)
			var base_b = lerp(0.68, 0.88, v)

			# Distant cumulus cloud layers
			var cloud_val = sin(u * 12.0 + 1.2) * cos(v * 8.0) * 0.5 + sin(u * 24.0) * 0.25
			if v > 0.42 and v < 0.75 and cloud_val > 0.15:
				var c_bright = clampf((cloud_val - 0.15) * 1.8, 0.0, 0.45)
				base_r += c_bright * 0.95
				base_g += c_bright * 0.98
				base_b += c_bright * 1.0

			# Floating monolithic sky island (center-left)
			var island_cx = float(w) * 0.42
			var island_cy = float(h) * 0.56
			var dx = (float(x) - island_cx) / (float(w) * 0.22)
			var dy = (float(y) - island_cy) / (float(h) * 0.16)
			var is_island_top = (dx * dx + dy * dy < 1.0) and y < int(island_cy + 5.0)
			var is_island_keel = abs(dx) < (1.0 - (float(y) - island_cy) / (float(h) * 0.25)) and y >= int(island_cy + 5.0) and y < int(island_cy + h * 0.25)
			if is_island_top or is_island_keel:
				base_r = 0.16
				base_g = 0.26
				base_b = 0.24
				# Grass/foliage plateau
				if y < int(island_cy - 4.0):
					base_r = 0.25
					base_g = 0.75
					base_b = 0.45
				# Ancient runic monument on plateau
				if abs(x - int(island_cx)) < 4 and y < int(island_cy - 4.0) and y > int(island_cy - 28.0):
					base_r = 0.90
					base_g = 0.92
					base_b = 0.95

			# Sweeping cyan glider trail arc
			var arc_y = float(h) * (0.35 + sin(u * PI * 1.2) * 0.18)
			var arc_dist = abs(float(y) - arc_y)
			if arc_dist < 3.5:
				var glow = 1.0 - (arc_dist / 3.5)
				base_r = lerp(base_r, 0.2, glow)
				base_g = lerp(base_g, 0.95, glow)
				base_b = lerp(base_b, 1.0, glow)

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_roboforge_arena(img: Image, w: int, h: int) -> void:
	# Modular Robotics Engineering: Dark carbon-fiber floor, amber/gold isometric grid, robot chassis silhouette & welding sparks
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)

			# Industrial hangar atmosphere (deep charcoal to dark bronze gradient)
			var base_r = lerp(0.12, 0.22, v)
			var base_g = lerp(0.14, 0.20, v)
			var base_b = lerp(0.18, 0.22, v)

			# Engineering blueprint grid lines (upper half)
			if v < 0.60:
				if (x % 28 == 0) or (y % 28 == 0):
					base_r += 0.08
					base_g += 0.12
					base_b += 0.16

			# Industrial floor platform (lower 40%)
			if v >= 0.60:
				base_r = 0.15
				base_g = 0.16
				base_b = 0.18
				# Amber test-bay perspective floor lines
				if (int(float(x) + (v - 0.6) * 120.0) % 36 == 0) or (int(y) % 18 == 0):
					base_r = 0.85
					base_g = 0.65
					base_b = 0.12

			# Robotic Chassis silhouette in center
			var dist_robot = Vector2(x - w * 0.5, y - h * 0.58).length()
			if dist_robot < 32.0:
				base_r = 0.22
				base_g = 0.24
				base_b = 0.28
				# Articulated tool arm
				if abs(x - w * 0.5 + 18) < 4 and y < h * 0.58 and y > h * 0.42:
					base_r = 0.35
					base_g = 0.38
					base_b = 0.42

			# Welding spark burst with radiant bloom (near robot arm tip)
			var spark_origin = Vector2(w * 0.5 - 18, h * 0.42)
			var spark_dist = (Vector2(x, y) - spark_origin).length()
			if spark_dist < 18.0:
				var s_glow = 1.0 - (spark_dist / 18.0)
				base_r = lerp(base_r, 1.0, s_glow)
				base_g = lerp(base_g, 0.88, s_glow)
				base_b = lerp(base_b, 0.35, s_glow)

			# Warning chevron stripes along bottom border
			if y > h - 8:
				if (x + y) % 16 < 8:
					base_r = 0.95
					base_g = 0.75
					base_b = 0.10
				else:
					base_r = 0.10
					base_g = 0.10
					base_b = 0.10

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_wildcircuit(img: Image, w: int, h: int) -> void:
	# Wildlife Photography & Conservation: Golden hour sunset, layered savannah horizons, acacia silhouette & viewfinder HUD
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)

			# Warm radiant sunset gradient (golden amber to crimson peach to deep violet)
			var base_r = lerp(0.85, 0.35, v)
			var base_g = lerp(0.52, 0.22, v)
			var base_b = lerp(0.22, 0.35, v)

			# Setting sun orb
			var sun_dist = (Vector2(x, y) - Vector2(w * 0.32, h * 0.38)).length()
			if sun_dist < 28.0:
				var s_int = 1.0 - (sun_dist / 28.0)
				base_r = lerp(base_r, 1.0, s_int)
				base_g = lerp(base_g, 0.95, s_int)
				base_b = lerp(base_b, 0.65, s_int)

			# Layered distant mountain ridges
			var mtn1_y = float(h) * (0.50 + sin(u * 5.0) * 0.06 + sin(u * 11.0) * 0.03)
			if y > int(mtn1_y) and y < int(h * 0.68):
				base_r = 0.38
				base_g = 0.22
				base_b = 0.28

			# Savannah plain plateau (foreground)
			if y >= int(h * 0.66):
				base_r = 0.18
				base_g = 0.12
				base_b = 0.10
				if y % 12 == 0:
					base_r += 0.04
					base_g += 0.03

			# Acacia tree silhouette on right
			var tree_x = int(w * 0.76)
			var tree_root_y = int(h * 0.66)
			if abs(x - tree_x) < 4 and y > int(h * 0.42) and y <= tree_root_y:
				base_r = 0.08
				base_g = 0.06
				base_b = 0.05
			# Canopy umbrella
			var c_dx = (float(x) - float(tree_x)) / 36.0
			var c_dy = (float(y) - float(h) * 0.42) / 10.0
			if (c_dx * c_dx + c_dy * c_dy < 1.0) and y <= int(h * 0.44):
				base_r = 0.07
				base_g = 0.06
				base_b = 0.05

			# Viewfinder HUD Overlay (corner reticles & focal indicator)
			var is_corner = false
			var m = 14
			if (x >= m and x <= m + 14 and (y == m or y == h - m)) or (y >= m and y <= m + 14 and (x == m or x == w - m)):
				is_corner = true
			if (x >= w - m - 14 and x <= w - m and (y == m or y == h - m)) or (y >= h - m - 14 and y <= h - m and (x == m or x == w - m)):
				is_corner = true
			# Center autofocus brackets
			var center_dist = (Vector2(x, y) - Vector2(w * 0.5, h * 0.48)).length()
			if (center_dist >= 14.0 and center_dist <= 16.0) and ((abs(x - w * 0.5) > 6.0) or (abs(y - h * 0.48) > 6.0)):
				is_corner = true

			if is_corner:
				base_r = 0.95
				base_g = 0.95
				base_b = 0.95

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_chroma_rush(img: Image, w: int, h: int) -> void:
	# The Color Chase: Synthwave chromatic split highway (magenta / cyan), neon perspective lines, distant glowing portal
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)

			# Deep neon space void gradient
			var base_r = lerp(0.12, 0.05, v)
			var base_g = lerp(0.04, 0.02, v)
			var base_b = lerp(0.25, 0.12, v)

			# Horizon at v = 0.45
			if v > 0.45:
				# Perspective chromatic track
				var v_track = (v - 0.45) / 0.55
				var track_half_w = (v_track * 0.48 + 0.02) * float(w)
				var center_x = float(w) * 0.5
				var track_dx = float(x) - center_x

				if abs(track_dx) < track_half_w:
					# Split color lane: Left side hot magenta (#FF1493), Right side cyan (#00FFFF)
					if track_dx < 0.0:
						base_r = 0.85
						base_g = 0.10
						base_b = 0.55
					else:
						base_r = 0.05
						base_g = 0.85
						base_b = 0.95

					# Track grid scanlines
					if int(v_track * 40.0) % 4 == 0:
						base_r *= 0.65
						base_g *= 0.65
						base_b *= 0.65

					# White center line
					if abs(track_dx) < 2.5:
						base_r = 1.0
						base_g = 1.0
						base_b = 1.0
				elif abs(abs(track_dx) - track_half_w) < 4.0:
					# Neon track barrier rails
					base_r = 1.0
					base_g = 0.95
					base_b = 0.20

			# Distant glowing chromatic portal / sun at horizon
			var portal_dist = (Vector2(x, y) - Vector2(w * 0.5, h * 0.45)).length()
			if portal_dist < 24.0:
				var p_glow = 1.0 - (portal_dist / 24.0)
				base_r = lerp(base_r, 1.0, p_glow)
				base_g = lerp(base_g, 0.85, p_glow * 0.5)
				base_b = lerp(base_b, 1.0, p_glow)

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_flight_simulator_6dof(img: Image, w: int, h: int) -> void:
	# AeroSim 6-DoF: Runway perspective centerline, PAPI 3.0 deg light array, green threshold lights, glass cockpit HUD pitch ladder
	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)

			# Twilight atmospheric sky (deep navy blue to twilight amber gradient at horizon)
			var base_r = lerp(0.06, 0.28, v) if v < 0.50 else 0.08
			var base_g = lerp(0.12, 0.32, v) if v < 0.50 else 0.10
			var base_b = lerp(0.32, 0.42, v) if v < 0.50 else 0.12

			# Horizon line at v = 0.50
			if v >= 0.50:
				# Dark airfield ground
				base_r = 0.06
				base_g = 0.08
				base_b = 0.07

				# Perspective Runway 09L tapering to horizon
				var r_v = (v - 0.50) / 0.50
				var r_half_w = (r_v * 0.28 + 0.01) * float(w)
				var r_center_x = float(w) * 0.5
				var r_dx = float(x) - r_center_x

				if abs(r_dx) < r_half_w:
					# Asphalt surface
					base_r = 0.16
					base_g = 0.18
					base_b = 0.20

					# Dashed white centerline stripes
					if abs(r_dx) < 2.0 and int(r_v * 30.0) % 2 == 0:
						base_r = 0.95
						base_g = 0.95
						base_b = 0.95

				# Runway Edge Lights (white pearls)
				if abs(abs(r_dx) - r_half_w) < 1.5 and int(r_v * 24.0) % 2 == 0:
					base_r = 0.95
					base_g = 0.95
					base_b = 0.80

				# Green Threshold Lights near horizon
				if v >= 0.50 and v <= 0.52 and abs(r_dx) < r_half_w + 5.0:
					base_r = 0.1
					base_g = 1.0
					base_b = 0.2

				# PAPI 4-Light Array (Port side of runway: 2 White, 2 Red on-glidepath)
				var papi_y = int(h * 0.56)
				var papi_x_start = int(r_center_x - r_half_w - 22.0)
				if y >= papi_y - 1 and y <= papi_y + 1:
					for p_idx in range(4):
						var p_x = papi_x_start + p_idx * 5
						if abs(x - p_x) <= 1:
							if p_idx < 2:
								# White lights
								base_r = 1.0; base_g = 1.0; base_b = 0.9
							else:
								# Red lights
								base_r = 1.0; base_g = 0.15; base_b = 0.15

			# HUD Flight Director & Pitch Ladder Overlay (Glowing Green #00FF66)
			var hud_cx = w * 0.5
			var hud_cy = h * 0.42
			# Aircraft boresight symbol (circle + wings)
			var dist_bore = Vector2(x - hud_cx, y - hud_cy).length()
			var is_hud_pixel = false
			if (dist_bore >= 5.0 and dist_bore <= 7.0) or (abs(y - hud_cy) < 1.5 and abs(x - hud_cx) >= 7.0 and abs(x - hud_cx) <= 18.0):
				is_hud_pixel = true
			# +10 deg pitch ladder bar
			var pitch_10_y = hud_cy - 18.0
			if abs(y - pitch_10_y) < 1.0 and abs(x - hud_cx) >= 12.0 and abs(x - hud_cx) <= 28.0:
				is_hud_pixel = true
			# -10 deg pitch ladder dashed bar
			var pitch_neg10_y = hud_cy + 18.0
			if abs(y - pitch_neg10_y) < 1.0 and abs(x - hud_cx) >= 12.0 and abs(x - hud_cx) <= 28.0 and (int(x) % 4 < 2):
				is_hud_pixel = true

			if is_hud_pixel:
				base_r = 0.1
				base_g = 1.0
				base_b = 0.35

			img.set_pixel(x, y, Color(clampf(base_r, 0.0, 1.0), clampf(base_g, 0.0, 1.0), clampf(base_b, 0.0, 1.0)))

static func _paint_default_banner(img: Image, w: int, h: int) -> void:
	for y in range(h):
		for x in range(w):
			var r = float(x) / float(w) * 0.5 + 0.2
			var b = float(y) / float(h) * 0.5 + 0.3
			img.set_pixel(x, y, Color(r, 0.4, b))
