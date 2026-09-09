class_name TextureSynthesizer
extends RefCounted

## Procedural PBR Texture Synthesizer for VoltArena.
## Generates 100% original, legally clean, tileable PBR maps in-engine:
## Albedo, Normal, Roughness, and Emission maps for architectural surfaces.

static var _texture_cache: Dictionary = {}

static func get_texture(texture_id: String) -> ImageTexture:
	if _texture_cache.has(texture_id):
		return _texture_cache[texture_id]

	var tex: ImageTexture = null
	match texture_id:
		"sci_fi_metal_albedo":
			tex = _build_sci_fi_metal_albedo()
		"sci_fi_metal_normal":
			tex = _build_sci_fi_metal_normal()
		"dark_hull_albedo":
			tex = _build_dark_hull_albedo()
		"subway_tile_albedo":
			tex = _build_subway_tile_albedo()
		"subway_tile_normal":
			tex = _build_subway_tile_normal()
		"grimy_concrete_albedo":
			tex = _build_grimy_concrete_albedo()
		"asphalt_albedo":
			tex = _build_asphalt_albedo()
		"asphalt_normal":
			tex = _build_asphalt_normal()
		"stadium_pitch_albedo":
			tex = _build_stadium_pitch_albedo()
		"stadium_pitch_day":
			tex = _build_stadium_pitch_day()
		"stadium_pitch_cyber":
			tex = _build_stadium_pitch_cyber()
		"canyon_rock":
			tex = _build_canyon_rock()
		"canyon_rock_normal":
			tex = _build_canyon_rock_normal()
		"snow_ice":
			tex = _build_snow_ice()
		"subway_rust_metal":
			tex = _build_subway_rust_metal()
		"acid_pool":
			tex = _build_acid_pool()
		"ball_hex_glow":
			tex = _build_ball_hex_glow()
		"hazard_stripe_albedo":
			tex = _build_hazard_stripe_albedo()
		"curb_stripes_albedo":
			tex = _build_curb_stripes_albedo()
		"curb_stripes_blue_white":
			tex = _build_curb_stripes_blue_white()
		"curb_stripes_red_white":
			tex = _build_curb_stripes_red_white()
		"armco_barrier_albedo":
			tex = _build_armco_barrier_albedo()
		"racing_turf_albedo":
			tex = _build_racing_turf_albedo()
		"gravel_trap_albedo":
			tex = _build_gravel_trap_albedo()
		"tactile_bump_albedo":
			tex = _build_tactile_bump_albedo()
		"asphalt_lanes_albedo":
			tex = _build_asphalt_lanes_albedo()
		"hex_grid_cyan_albedo":
			tex = _build_hex_grid_cyan_albedo()
		"hex_grid_cyan_emission":
			tex = _build_hex_grid_cyan_emission()
		"checkered_flag_albedo":
			tex = _build_checkered_flag_albedo()
		"crowd_texture_albedo":
			tex = _build_crowd_texture_albedo()
		"turbo_kart_rush_banner":
			tex = _build_turbo_kart_rush_banner()
		"stadium_score_banner_orange":
			tex = _build_stadium_score_banner_orange()
		"stadium_score_banner_blue":
			tex = _build_stadium_score_banner_blue()
		"digital_signage_cyan":
			tex = _build_digital_signage_albedo(Color(0.0, 0.9, 1.0), "VOLTARENA")
		"digital_signage_orange":
			tex = _build_digital_signage_albedo(Color(1.0, 0.5, 0.0), "NITRO KICK")
		"stadium_spectators":
			tex = _build_stadium_spectators_albedo()
		_:
			tex = _build_fallback_texture()

	if tex:
		_texture_cache[texture_id] = tex
	return tex

static func _build_sci_fi_metal_albedo() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var base_col = Color(0.32, 0.38, 0.46)
	var seam_col = Color(0.12, 0.15, 0.20)
	var bevel_col = Color(0.48, 0.56, 0.68)
	var rivet_col = Color(0.65, 0.72, 0.82)

	for y in range(h):
		for x in range(w):
			var is_edge = (x < 3 or x >= w - 3 or y < 3 or y >= h - 3)
			var is_inner_bevel = (x == 3 or x == w - 4 or y == 3 or y == h - 4)
			var is_sub_seam = (x == 64 or y == 64)
			var is_rivet = ((x == 12 or x == w - 13) and (y == 12 or y == h - 13)) or \
						   ((x == 64 and (y == 12 or y == h - 13)) or (y == 64 and (x == 12 or x == w - 13)))

			var noise = sin(float(x) * 0.4) * cos(float(y) * 0.4) * 0.04
			var col = base_col + Color(noise, noise, noise)

			if is_edge or is_sub_seam:
				col = seam_col
			elif is_inner_bevel:
				col = bevel_col
			elif is_rivet:
				col = rivet_col

			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

static func _build_sci_fi_metal_normal() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var flat_normal = Color(0.5, 0.5, 1.0)
	var bevel_left = Color(0.7, 0.5, 0.7)
	var bevel_right = Color(0.3, 0.5, 0.7)

	for y in range(h):
		for x in range(w):
			var col = flat_normal
			if x < 4 or (x >= 62 and x < 64):
				col = bevel_left
			elif x >= w - 4 or (x >= 64 and x < 66):
				col = bevel_right
			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

static func _build_dark_hull_albedo() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var col_a = Color(0.18, 0.22, 0.28)
	var col_b = Color(0.24, 0.28, 0.36)
	var seam = Color(0.10, 0.12, 0.16)

	for y in range(h):
		for x in range(w):
			var is_border = (x < 2 or x >= w - 2 or y < 2 or y >= h - 2)
			var checker = ((x / 16) + (y / 16)) % 2 == 0
			var col = col_a if checker else col_b
			if is_border:
				col = seam
			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

static func _build_subway_tile_albedo() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var tile_col = Color(0.68, 0.72, 0.76)
	var grout_col = Color(0.20, 0.22, 0.25)
	var grime_col = Color(0.45, 0.48, 0.50)

	for y in range(h):
		var row = y / 16
		var row_offset = 16 if (row % 2 == 1) else 0
		var is_grout_y = (y % 16 == 0 or y % 16 == 1)

		for x in range(w):
			var shifted_x = (x + row_offset) % w
			var is_grout_x = (shifted_x % 32 == 0 or shifted_x % 32 == 1)
			var is_edge_grime = (y % 16 == 2 or y % 16 == 15 or shifted_x % 32 == 2 or shifted_x % 32 == 31)

			var col = tile_col
			if is_grout_y or is_grout_x:
				col = grout_col
			elif is_edge_grime:
				col = grime_col
			else:
				var grain = (float((x * 7 + y * 13) % 19) / 19.0 - 0.5) * 0.06
				col += Color(grain, grain, grain)

			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

static func _build_subway_tile_normal() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var flat = Color(0.5, 0.5, 1.0)
	var edge_up = Color(0.5, 0.7, 0.7)
	var edge_down = Color(0.5, 0.3, 0.7)

	for y in range(h):
		for x in range(w):
			var mod_y = y % 16
			var col = flat
			if mod_y <= 1:
				col = edge_up
			elif mod_y >= 14:
				col = edge_down
			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

static func _build_grimy_concrete_albedo() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var base_col = Color(0.42, 0.44, 0.46)
	var stain_col = Color(0.28, 0.30, 0.32)

	for y in range(h):
		for x in range(w):
			var n1 = sin(float(x) * 0.25) * cos(float(y) * 0.25)
			var n2 = sin(float(x + y) * 0.6) * 0.5
			var combined = (n1 + n2) * 0.15
			var col = base_col.lerp(stain_col, abs(combined) * 2.0)
			if (x == 0 or x == w - 1 or y == 0 or y == h - 1):
				col = stain_col * 0.8
			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

static func _build_asphalt_albedo() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var asphalt_dark = Color(0.24, 0.25, 0.28)
	var asphalt_light = Color(0.34, 0.36, 0.40)
	var line_col = Color(0.95, 0.85, 0.15) # Yellow track line
	var tire_wear = Color(0.16, 0.17, 0.19)

	for y in range(h):
		for x in range(w):
			var grain = float((x * 17 + y * 23) % 31) / 31.0
			var col = asphalt_dark.lerp(asphalt_light, grain)

			# Racing line rubber groove in center lanes
			if (x >= 28 and x <= 44) or (x >= 84 and x <= 100):
				col = col.lerp(tire_wear, 0.6)

			# Dashed center line
			if x >= 62 and x <= 66 and (y % 32 < 18):
				col = line_col

			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

static func _build_asphalt_normal() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var nx = 0.5 + (float((x * 13 + y * 7) % 17) / 17.0 - 0.5) * 0.15
			var ny = 0.5 + (float((x * 11 + y * 19) % 17) / 17.0 - 0.5) * 0.15
			img.set_pixel(x, y, Color(nx, ny, 1.0))
	return ImageTexture.create_from_image(img)

static func _build_stadium_pitch_albedo() -> ImageTexture:
	var w = 256
	var h = 256
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var green_dark = Color(0.08, 0.28, 0.12)
	var green_light = Color(0.14, 0.38, 0.18)
	var chalk_line = Color(0.92, 0.95, 0.92)

	for y in range(h):
		# Mowing stripes every 32 pixels
		var stripe = (y / 32) % 2 == 0
		var base = green_light if stripe else green_dark

		for x in range(w):
			var fine_noise = (float((x * 19 + y * 29) % 23) / 23.0 - 0.5) * 0.03
			var col = base + Color(fine_noise, fine_noise, fine_noise)

			# Perimeter chalk touchlines
			var is_touchline = (x <= 4 or x >= w - 5 or y <= 4 or y >= h - 5)
			# Halfway line
			var is_halfway = (y >= 126 and y <= 130)
			# Center circle outline (radius ~40 centered at 128, 128)
			var dist_center = Vector2(x - 128, y - 128).length()
			var is_center_circle = (dist_center >= 38.0 and dist_center <= 42.0)
			# Center spot
			var is_center_spot = (dist_center <= 4.0)

			if is_touchline or is_halfway or is_center_circle or is_center_spot:
				col = chalk_line

			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

static func _build_hazard_stripe_albedo() -> ImageTexture:
	var w = 64
	var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var yellow = Color(1.0, 0.85, 0.0)
	var black = Color(0.12, 0.12, 0.14)

	for y in range(h):
		for x in range(w):
			var stripe = ((x + y) / 10) % 2 == 0
			img.set_pixel(x, y, yellow if stripe else black)

	return ImageTexture.create_from_image(img)

static func _build_curb_stripes_albedo() -> ImageTexture:
	var w = 64
	var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var red = Color(0.9, 0.15, 0.15)
	var white = Color(0.95, 0.95, 0.95)

	for y in range(h):
		for x in range(w):
			var stripe = (x / 16) % 2 == 0
			img.set_pixel(x, y, red if stripe else white)

	return ImageTexture.create_from_image(img)

static func _build_digital_signage_albedo(accent_col: Color, _tag: String) -> ImageTexture:
	var w = 128
	var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bg_dark = Color(0.05, 0.08, 0.12)
	var border = accent_col

	for y in range(h):
		for x in range(w):
			var is_border = (x < 3 or x >= w - 3 or y < 3 or y >= h - 3)
			var scanline = (y % 4 == 0)
			var col = bg_dark
			if is_border:
				col = border
			elif scanline:
				col = bg_dark.lerp(accent_col, 0.25)
			elif x > 20 and x < w - 20 and y > 24 and y < 40:
				col = accent_col * 0.9

			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

static func _build_stadium_spectators_albedo() -> ImageTexture:
	var w = 128
	var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var seat_col = Color(0.15, 0.18, 0.24)

	var fan_colors = [
		Color(0.2, 0.6, 1.0),
		Color(1.0, 0.4, 0.1),
		Color(0.9, 0.9, 0.9),
		Color(0.2, 0.8, 0.4),
		Color(0.9, 0.8, 0.2)
	]

	for y in range(h):
		var tier = y / 16
		for x in range(w):
			var col = seat_col
			# Spectator heads and bodies
			var head_y = tier * 16 + 4
			var dist_to_fan = abs((x % 8) - 4) + abs((y % 16) - head_y)
			if dist_to_fan <= 3:
				var color_idx = (x / 8 + tier) % fan_colors.size()
				col = fan_colors[color_idx]
			img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

static func _build_stadium_pitch_day() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var green_light = Color(0.12, 0.36, 0.16)
	var green_dark = Color(0.08, 0.26, 0.10)
	var chalk = Color(0.92, 0.95, 0.92)
	for y in range(h):
		var stripe = (y / 16) % 2 == 0
		var base_col = green_light if stripe else green_dark
		for x in range(w):
			var noise = sin(float(x) * 0.8) * cos(float(y) * 0.8) * 0.015
			var col = base_col + Color(noise, noise * 1.2, noise)
			# Pitch perimeter chalk lines
			if x < 3 or x >= w - 3 or y < 3 or y >= h - 3 or x == 64:
				col = chalk
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _build_stadium_pitch_cyber() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var turf_base = Color(0.08, 0.12, 0.18)
	var grid_cyan = Color(0.0, 0.85, 1.0)
	var grid_sub = Color(0.12, 0.22, 0.32)
	for y in range(h):
		for x in range(w):
			var is_major = (x % 32 == 0 or y % 32 == 0)
			var is_minor = (x % 8 == 0 or y % 8 == 0)
			var col = turf_base
			if is_major:
				col = grid_cyan
			elif is_minor:
				col = grid_sub
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _build_canyon_rock() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rock_red = Color(0.72, 0.38, 0.24)
	var rock_tan = Color(0.82, 0.52, 0.32)
	var rock_strata = Color(0.55, 0.28, 0.18)
	for y in range(h):
		var band = sin(float(y) * 0.15 + sin(float(y) * 0.05) * 2.0)
		var base = rock_red.lerp(rock_tan, (band + 1.0) * 0.5)
		if (y % 16 < 2):
			base = rock_strata
		for x in range(w):
			var grain = (sin(float(x * 3)) + cos(float(y * 4))) * 0.03
			img.set_pixel(x, y, base + Color(grain, grain * 0.7, grain * 0.4))
	return ImageTexture.create_from_image(img)

static func _build_canyon_rock_normal() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var flat = Color(0.5, 0.5, 1.0)
	for y in range(h):
		for x in range(w):
			var nx = 0.5 + sin(float(x) * 0.5) * 0.15
			var ny = 0.5 + cos(float(y) * 0.3) * 0.2
			img.set_pixel(x, y, Color(nx, ny, 0.95))
	return ImageTexture.create_from_image(img)

static func _build_snow_ice() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var snow_white = Color(0.92, 0.95, 0.98)
	var ice_cyan = Color(0.75, 0.88, 0.96)
	for y in range(h):
		for x in range(w):
			var sparkle = (sin(float(x * 5)) * cos(float(y * 7))) * 0.05
			var blend = sin(float(x) * 0.08) * cos(float(y) * 0.08)
			var col = snow_white.lerp(ice_cyan, abs(blend)) + Color(sparkle, sparkle, sparkle)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _build_subway_rust_metal() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var steel = Color(0.35, 0.38, 0.42)
	var rust = Color(0.55, 0.28, 0.15)
	for y in range(h):
		for x in range(w):
			var corrugation = sin(float(x) * 0.4) * 0.1
			var rust_patch = sin(float(x) * 0.12) * cos(float(y) * 0.15)
			var col = steel + Color(corrugation, corrugation, corrugation)
			if rust_patch > 0.3:
				col = col.lerp(rust, (rust_patch - 0.3) * 2.0)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _build_acid_pool() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var toxic_green = Color(0.3, 0.95, 0.1)
	var dark_slime = Color(0.1, 0.45, 0.05)
	for y in range(h):
		for x in range(w):
			var swirl = sin(float(x) * 0.2 + float(y) * 0.1) * cos(float(y) * 0.2 - float(x) * 0.1)
			var col = toxic_green.lerp(dark_slime, (swirl + 1.0) * 0.5)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _build_ball_hex_glow() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var hex_white = Color(0.95, 0.98, 1.0)
	var hex_core = Color(0.1, 0.8, 1.0)
	for y in range(h):
		for x in range(w):
			var q = (x % 32) - 16
			var r = (y % 32) - 16
			var d = sqrt(float(q * q + r * r))
			var col = hex_white
			if d < 5.0:
				col = hex_core
			elif d > 14.0:
				col = Color(0.15, 0.2, 0.25)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _build_curb_stripes_blue_white() -> ImageTexture:
	var w = 64
	var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var blue = Color(0.12, 0.45, 0.95)
	var white = Color(0.96, 0.96, 0.98)
	for y in range(h):
		for x in range(w):
			var stripe = ((x + y) / 16) % 2 == 0
			img.set_pixel(x, y, blue if stripe else white)
	return ImageTexture.create_from_image(img)

static func _build_curb_stripes_red_white() -> ImageTexture:
	var w = 64
	var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var red = Color(0.88, 0.12, 0.14)
	var white = Color(0.96, 0.96, 0.98)
	var shadow = Color(0.08, 0.08, 0.10, 0.3)
	for y in range(h):
		var edge_shade = 1.0 - (y / float(h)) * 0.2
		for x in range(w):
			var stripe = ((x + y) / 16) % 2 == 0
			var c = (red if stripe else white) * edge_shade
			# Slight bevel ridge
			if (x + y) % 16 == 0:
				c = c * 0.75
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

static func _build_armco_barrier_albedo() -> ImageTexture:
	var w = 128
	var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var steel_base = Color(0.68, 0.72, 0.76)
	var steel_dark = Color(0.38, 0.42, 0.46)
	var steel_bright = Color(0.88, 0.90, 0.94)
	var post_color = Color(0.28, 0.30, 0.34)
	var reflector_amber = Color(1.0, 0.65, 0.05)
	var reflector_red = Color(0.95, 0.15, 0.15)

	for y in range(h):
		# W-beam corrugation profile (two concave troughs and center ridge)
		var norm_y = float(y) / float(h)
		var w_wave = sin(norm_y * TAU * 2.0)
		var beam_col = steel_base.lerp(steel_bright, maxf(0.0, w_wave) * 0.4).lerp(steel_dark, maxf(0.0, -w_wave) * 0.5)

		# Top / Bottom lips
		if y < 4 or y >= h - 4:
			beam_col = steel_dark

		for x in range(w):
			var col = beam_col
			# Vertical I-beam post every 64 pixels
			if x % 64 < 4:
				col = post_color
			# Hex bolt rivets on posts
			elif (x % 64 >= 4 and x % 64 <= 6) and (y == 20 or y == 44):
				col = Color(0.18, 0.20, 0.22)
			# Safety Reflector Strip on center ridge
			if y >= 30 and y <= 34 and (x % 32 >= 12 and x % 32 <= 20):
				col = reflector_amber if (x / 32) % 2 == 0 else reflector_red
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _build_racing_turf_albedo() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var grass_dark = Color(0.16, 0.38, 0.14)
	var grass_light = Color(0.22, 0.48, 0.18)
	var earth = Color(0.28, 0.24, 0.16)
	for y in range(h):
		var stripe = ((y / 16) % 2) == 0
		var base = grass_light if stripe else grass_dark
		for x in range(w):
			var grain = (float((x * 37 + y * 43) % 47) / 47.0 - 0.5) * 0.08
			var col = base + Color(grain * 0.8, grain * 1.2, grain * 0.5)
			if (x * 13 + y * 17) % 73 == 0:
				col = col.lerp(earth, 0.4)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _build_gravel_trap_albedo() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var gravel_tan = Color(0.72, 0.58, 0.42)
	var gravel_red = Color(0.62, 0.42, 0.32)
	var gravel_dark = Color(0.40, 0.32, 0.26)
	for y in range(h):
		for x in range(w):
			var n = (x * 19 + y * 31) % 17
			var col = gravel_tan
			if n < 5:
				col = gravel_red
			elif n < 8:
				col = gravel_dark
			var grain = (float((x * 7 + y * 11) % 23) / 23.0 - 0.5) * 0.06
			img.set_pixel(x, y, col + Color(grain, grain, grain))
	return ImageTexture.create_from_image(img)

static func _build_tactile_bump_albedo() -> ImageTexture:
	var w = 64
	var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var yellow_base = Color(0.98, 0.85, 0.05)
	var yellow_bump = Color(0.85, 0.72, 0.02)
	for y in range(h):
		for x in range(w):
			var cx = (x % 16) - 8
			var cy = (y % 16) - 8
			var dist = sqrt(float(cx * cx + cy * cy))
			var col = yellow_bump if dist < 4.0 else yellow_base
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _build_asphalt_lanes_albedo() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var base_asphalt = Color(0.20, 0.22, 0.24)
	var rubber_groove = Color(0.11, 0.12, 0.13) # Heavy tire wear groove on racing line
	var white_line = Color(0.96, 0.96, 0.98)

	for y in range(h):
		var dashed = (y % 32) < 20
		for x in range(w):
			var grain = (float((x * 19 + y * 23) % 29) / 29.0 - 0.5) * 0.035
			var col = base_asphalt + Color(grain, grain, grain)

			# Rubbered-in racing groove along left lane (x: 24-44) and right lane (x: 84-104)
			var in_left_groove = (x >= 24 and x <= 44)
			var in_right_groove = (x >= 84 and x <= 104)
			if in_left_groove or in_right_groove:
				col = col.lerp(rubber_groove, 0.75)

			# Crisp White Outer boundary edge lines
			if x < 4 or x >= w - 4:
				col = white_line
			# Center dashed racing dividing line
			elif x >= 62 and x <= 66 and dashed:
				col = white_line

			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _build_hex_grid_cyan_albedo() -> ImageTexture:
	var w = 256
	var h = 256
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var dark_metal = Color(0.06, 0.09, 0.14)
	var cyan_edge = Color(0.12, 0.95, 1.0)
	var cyan_core = Color(0.0, 0.65, 0.92)

	# Hexagon geometry: period along X is 3 * R, period along Y is sqrt(3) * R
	var radius = 28.0
	var h_step = radius * 1.5 # 42.0
	var v_step = radius * 1.73205 # 48.497

	for y in range(h):
		var fy = float(y)
		var approx_row = int(fy / v_step)
		for x in range(w):
			var fx = float(x)
			var approx_col = int(fx / h_step)
			var min_edge_dist = 999.0

			for c_offset in [-1, 0, 1]:
				var col = approx_col + c_offset
				var cx = float(col) * h_step
				var is_odd = posmod(col, 2) != 0
				for r_offset in [-1, 0, 1]:
					var row = approx_row + r_offset
					var cy = float(row) * v_step + (v_step * 0.5 if is_odd else 0.0)
					var dx = absf(fx - cx)
					var dy = absf(fy - cy)
					# Distance to boundary of regular hexagon with radius R:
					# Boundary plane is at distance R * sqrt(3) / 2 = radius * 0.866025
					var edge_dist = 24.25 - maxf(dx * 0.866025, dx * 0.433013 + dy * 0.75)
					if edge_dist >= -1.0 and edge_dist < min_edge_dist:
						min_edge_dist = edge_dist

			var col = dark_metal
			if min_edge_dist >= 0.0 and min_edge_dist < 2.2:
				col = cyan_edge
			elif min_edge_dist >= 2.2 and min_edge_dist < 4.2:
				col = cyan_core
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _build_hex_grid_cyan_emission() -> ImageTexture:
	var w = 256
	var h = 256
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var black = Color(0.0, 0.0, 0.0)
	var cyan_glow = Color(0.0, 0.95, 1.0)
	var soft_glow = Color(0.0, 0.50, 0.80)

	var radius = 28.0
	var h_step = radius * 1.5
	var v_step = radius * 1.73205

	for y in range(h):
		var fy = float(y)
		var approx_row = int(fy / v_step)
		for x in range(w):
			var fx = float(x)
			var approx_col = int(fx / h_step)
			var min_edge_dist = 999.0

			for c_offset in [-1, 0, 1]:
				var col = approx_col + c_offset
				var cx = float(col) * h_step
				var is_odd = posmod(col, 2) != 0
				for r_offset in [-1, 0, 1]:
					var row = approx_row + r_offset
					var cy = float(row) * v_step + (v_step * 0.5 if is_odd else 0.0)
					var dx = absf(fx - cx)
					var dy = absf(fy - cy)
					var edge_dist = 24.25 - maxf(dx * 0.866025, dx * 0.433013 + dy * 0.75)
					if edge_dist >= -1.0 and edge_dist < min_edge_dist:
						min_edge_dist = edge_dist

			var col = black
			if min_edge_dist >= 0.0 and min_edge_dist < 2.2:
				col = cyan_glow
			elif min_edge_dist >= 2.2 and min_edge_dist < 4.2:
				col = soft_glow
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

static func _build_checkered_flag_albedo() -> ImageTexture:
	var size = 64
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var square = 8
	var white = Color(0.96, 0.96, 0.98)
	var black = Color(0.08, 0.08, 0.10)
	for y in range(size):
		var y_idx = int(y / square)
		for x in range(size):
			var x_idx = int(x / square)
			var is_white = (x_idx + y_idx) % 2 == 0
			img.set_pixel(x, y, white if is_white else black)
	return ImageTexture.create_from_image(img)

static func _build_crowd_texture_albedo() -> ImageTexture:
	var w = 128
	var h = 128
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bench_color = Color(0.18, 0.22, 0.26)
	img.fill(bench_color)

	var palette = [
		Color(0.88, 0.22, 0.20),
		Color(0.20, 0.45, 0.90),
		Color(0.95, 0.80, 0.15),
		Color(0.25, 0.80, 0.35),
		Color(0.95, 0.50, 0.10),
		Color(0.92, 0.92, 0.95),
		Color(0.50, 0.20, 0.70),
		Color(0.25, 0.28, 0.32)
	]
	var skin_tones = [
		Color(0.95, 0.80, 0.70),
		Color(0.85, 0.65, 0.50),
		Color(0.60, 0.40, 0.25),
		Color(0.40, 0.25, 0.15)
	]

	for row in range(10):
		var base_y = 6 + row * 12
		if base_y + 8 >= h:
			break
		for col in range(18):
			var base_x = 4 + col * 7
			if base_x + 5 >= w:
				break
			var hash_val = (row * 37 + col * 19 + 7)
			var shirt_col = palette[hash_val % palette.size()]
			var skin_col = skin_tones[(hash_val / 3) % skin_tones.size()]

			for hy in range(3):
				for hx in range(3):
					img.set_pixel(base_x + 1 + hx, base_y + hy, skin_col)

			for by in range(3, 8):
				for bx in range(5):
					img.set_pixel(base_x + bx, base_y + by, shirt_col)

	return ImageTexture.create_from_image(img)

static func _build_turbo_kart_rush_banner() -> ImageTexture:
	var w = 256
	var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var red_banner = Color(0.85, 0.12, 0.16)
	img.fill(red_banner)

	var white = Color(0.98, 0.98, 0.98)
	var black = Color(0.06, 0.06, 0.08)
	for y in range(8):
		for x in range(w):
			var chk = (int(x / 8) + int(y / 4)) % 2 == 0
			img.set_pixel(x, y, white if chk else black)
			img.set_pixel(x, h - 1 - y, white if chk else black)

	for y in range(8, h - 8):
		for x in range(w):
			if (y == 9 or y == h - 10) and x > 12 and x < w - 12:
				img.set_pixel(x, y, white)
			if y >= 20 and y <= 44:
				var hash_x = x % 16
				if hash_x > 2 and hash_x < 14 and (x > 24 and x < w - 24):
					if (y < 25 or y > 39 or hash_x < 6 or hash_x > 10):
						img.set_pixel(x, y, white)

	return ImageTexture.create_from_image(img)

static func _build_stadium_score_banner_orange() -> ImageTexture:
	var w = 256
	var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bg = Color(0.12, 0.14, 0.18)
	var orange = Color(1.0, 0.55, 0.05)
	var white = Color(0.98, 0.98, 0.98)
	img.fill(bg)

	for y in range(h):
		for x in range(w):
			if x < 4 or x >= w - 4 or y < 4 or y >= h - 4:
				img.set_pixel(x, y, orange)
			elif (y == 8 or y == h - 9) and x > 8 and x < w - 8:
				img.set_pixel(x, y, orange)
			elif y >= 18 and y <= 46 and x >= 40 and x <= 216:
				var char_idx = int((x - 40) / 28)
				var char_x = (x - 40) % 28
				if char_x >= 4 and char_x <= 22:
					var is_px = false
					match char_idx:
						0:
							is_px = (y < 24 or y > 40 or char_x < 8 or char_x > 18)
						1:
							is_px = (char_x < 8 or y < 24 or (y > 30 and y < 35) or (char_x > 18 and y <= 32) or (char_x > 12 and y > 34))
						2:
							is_px = (char_x < 8 or char_x > 18 or y < 24 or (y >= 32 and y <= 36))
						3:
							is_px = (char_x < 8 or char_x > 18 or absf(float(char_x - 4) - float(y - 18) * 0.5) < 3.0)
						4:
							is_px = (char_x < 8 or y < 24 or y > 40 or (char_x > 18 and y >= 32) or (y >= 32 and y <= 36 and char_x >= 12))
						5:
							is_px = (char_x < 8 or y < 24 or y > 40 or (y >= 30 and y <= 34 and char_x < 18))
					if is_px:
						img.set_pixel(x, y, white)
	return ImageTexture.create_from_image(img)

static func _build_stadium_score_banner_blue() -> ImageTexture:
	var w = 256
	var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bg = Color(0.12, 0.14, 0.18)
	var cyan = Color(0.10, 0.75, 1.0)
	var white = Color(0.98, 0.98, 0.98)
	img.fill(bg)

	for y in range(h):
		for x in range(w):
			if x < 4 or x >= w - 4 or y < 4 or y >= h - 4:
				img.set_pixel(x, y, cyan)
			elif (y == 8 or y == h - 9) and x > 8 and x < w - 8:
				img.set_pixel(x, y, cyan)
			elif y >= 18 and y <= 46 and x >= 60 and x <= 196:
				var char_idx = int((x - 60) / 32)
				var char_x = (x - 60) % 32
				if char_x >= 4 and char_x <= 26:
					var is_px = false
					match char_idx:
						0:
							is_px = (char_x < 8 or y < 24 or y > 40 or (y >= 30 and y <= 34) or (char_x > 20))
						1:
							is_px = (char_x < 8 or y > 40)
						2:
							is_px = (char_x < 8 or char_x > 20 or y > 40)
						3:
							is_px = (char_x < 8 or y < 24 or y > 40 or (y >= 30 and y <= 34 and char_x < 20))
					if is_px:
						img.set_pixel(x, y, white)
	return ImageTexture.create_from_image(img)

static func _build_fallback_texture() -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.5, 0.5, 0.5))
	return ImageTexture.create_from_image(img)

