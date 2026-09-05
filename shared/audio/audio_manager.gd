extends Node

## Centralized audio management and procedural sound/music synthesis engine
## Provides complete sound effects and adaptive music for all 4 games with zero external files.

var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_3d_pool: Array[AudioStreamPlayer3D] = []
var bgm_player: AudioStreamPlayer
var engine_sfx_player: AudioStreamPlayer

# Cache of generated procedural audio streams
var sound_cache: Dictionary = {}

const POOL_SIZE: int = 16
const POOL_3D_SIZE: int = 12

func _ready() -> void:
	setup_players()
	generate_all_procedural_sounds()

func setup_players() -> void:
	if not is_instance_valid(bgm_player):
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BGMPlayer"
		bgm_player.bus = "Master"
		add_child(bgm_player)

	if not is_instance_valid(engine_sfx_player):
		engine_sfx_player = AudioStreamPlayer.new()
		engine_sfx_player.name = "EngineSFXPlayer"
		engine_sfx_player.bus = "Master"
		add_child(engine_sfx_player)

	if sfx_pool.is_empty():
		for i in range(POOL_SIZE):
			var p = AudioStreamPlayer.new()
			p.name = "SFXPlayer_" + str(i)
			p.bus = "Master"
			add_child(p)
			sfx_pool.append(p)

	if sfx_3d_pool.is_empty():
		for i in range(POOL_3D_SIZE):
			var p3 = AudioStreamPlayer3D.new()
			p3.name = "SFX3DPlayer_" + str(i)
			p3.bus = "Master"
			p3.max_distance = 50.0
			p3.unit_size = 10.0
			add_child(p3)
			sfx_3d_pool.append(p3)

func generate_all_procedural_sounds() -> void:
	# Laser / Pulse fire: high pitch downwards sweep
	sound_cache["laser_fire"] = create_synth_sound(880.0, 220.0, 0.12, 0.7, "sine")
	# Plasma fire: sizzling frequency modulated burst
	sound_cache["plasma_fire"] = create_synth_sound(600.0, 150.0, 0.16, 0.8, "saw")
	# Shotgun blast: filtered noise with punchy transient
	sound_cache["shotgun_fire"] = create_noise_burst(0.25, 1.0, 0.8)
	# Railgun: intense charged beam
	sound_cache["railgun_fire"] = create_synth_sound(1200.0, 110.0, 0.35, 0.9, "saw")
	# Explosion: low noise decay
	sound_cache["explosion"] = create_noise_burst(0.65, 0.9, 0.3)
	# Jump: rising sine
	sound_cache["jump"] = create_synth_sound(220.0, 440.0, 0.15, 0.5, "sine")
	# Hit / Flinch: short punch
	sound_cache["hit"] = create_synth_sound(180.0, 60.0, 0.08, 0.8, "square")
	sound_cache["flinch"] = create_synth_sound(140.0, 50.0, 0.10, 0.7, "square")
	# Pickup: rising arpeggio
	sound_cache["pickup"] = create_two_tone_sound(523.25, 659.25, 0.16, 0.6)
	sound_cache["scrap_pickup"] = create_two_tone_sound(659.25, 783.99, 0.12, 0.7)
	# Reload: metallic dual click
	sound_cache["reload"] = create_click_sound(0.2)
	# Countdown beeps
	sound_cache["beep_low"] = create_synth_sound(440.0, 440.0, 0.12, 0.6, "sine")
	sound_cache["beep_high"] = create_synth_sound(880.0, 880.0, 0.25, 0.8, "sine")
	# Goal & Wave fanfare
	sound_cache["goal"] = create_two_tone_sound(659.25, 1046.5, 0.45, 0.9)
	sound_cache["wave_clear"] = create_two_tone_sound(587.33, 880.0, 0.35, 0.8)
	# Drift screech & boost
	sound_cache["drift_screech"] = create_noise_burst(0.3, 0.4, 0.9)
	sound_cache["boost"] = create_synth_sound(300.0, 600.0, 0.35, 0.8, "saw")

	# Generate all 4 game background music tracks
	sound_cache["music_iron_crucible"] = create_music_track("iron_crucible")
	sound_cache["music_metro_siege"] = create_music_track("metro_siege")
	sound_cache["music_nitro_kick"] = create_music_track("nitro_kick")
	sound_cache["music_drift_storm"] = create_music_track("drift_storm")

func play_sound(sound_name: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not sound_cache.has(sound_name):
		return
	var stream: AudioStreamWAV = sound_cache[sound_name]
	for p in sfx_pool:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = clampf(pitch_scale + randf_range(-0.04, 0.04), 0.5, 2.0)
			p.volume_db = volume_db
			if p.is_inside_tree():
				p.play()
			return
	if not sfx_pool.is_empty():
		var p = sfx_pool[0]
		p.stream = stream
		p.pitch_scale = pitch_scale
		p.volume_db = volume_db
		if p.is_inside_tree():
			p.play()

func play_sound_3d(sound_name: String, global_pos: Vector3, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not sound_cache.has(sound_name):
		return
	var stream: AudioStreamWAV = sound_cache[sound_name]
	for p in sfx_3d_pool:
		if not p.playing:
			if p.is_inside_tree():
				p.global_position = global_pos
				p.play()
			p.stream = stream
			p.pitch_scale = clampf(pitch_scale + randf_range(-0.04, 0.04), 0.5, 2.0)
			p.volume_db = volume_db
			return
	if not sfx_3d_pool.is_empty():
		var p = sfx_3d_pool[0]
		if p.is_inside_tree():
			p.global_position = global_pos
			p.play()
		p.stream = stream
		p.pitch_scale = pitch_scale
		p.volume_db = volume_db

func play_music(track_name: String) -> void:
	if not is_instance_valid(bgm_player):
		return
	var key = "music_" + track_name
	var stream: AudioStreamWAV = null
	if sound_cache.has(key):
		stream = sound_cache[key]
	else:
		stream = create_music_track(track_name)
		sound_cache[key] = stream
	bgm_player.stream = stream
	if bgm_player.is_inside_tree():
		bgm_player.play()

func stop_music() -> void:
	if is_instance_valid(bgm_player) and bgm_player.playing:
		bgm_player.stop()

func set_bus_volume(bus_name: String, volume_linear: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		var db = linear_to_db(clampf(volume_linear, 0.0001, 1.0))
		AudioServer.set_bus_volume_db(idx, db)

func stop_all() -> void:
	if is_instance_valid(bgm_player) and bgm_player.playing:
		bgm_player.stop()
	if is_instance_valid(engine_sfx_player) and engine_sfx_player.playing:
		engine_sfx_player.stop()
	for p in sfx_pool:
		if is_instance_valid(p) and p.playing:
			p.stop()
	for p3 in sfx_3d_pool:
		if is_instance_valid(p3) and p3.playing:
			p3.stop()

# Procedural Sound Synthesis Utilities (Zero External Audio Files Required)
func create_synth_sound(start_freq: float, end_freq: float, duration: float, volume: float, waveform: String) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		var current_freq: float = lerpf(start_freq, end_freq, t)
		var env: float = (1.0 - t) * volume
		phase += current_freq / float(sample_rate)
		var val: float = 0.0
		if waveform == "sine":
			val = sin(phase * TAU)
		elif waveform == "saw":
			val = 2.0 * (phase - floor(phase + 0.5))
		elif waveform == "square":
			val = 1.0 if sin(phase * TAU) >= 0.0 else -1.0

		var sample_val: int = clampi(int(val * env * 127.0) + 128, 0, 255)
		data[i] = sample_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func create_noise_burst(duration: float, volume: float, high_freq_bias: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)

	var last_val: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		var env: float = pow(1.0 - t, 2.0) * volume
		var white: float = randf_range(-1.0, 1.0)
		last_val = lerpf(last_val, white, high_freq_bias)
		var sample_val: int = clampi(int(last_val * env * 127.0) + 128, 0, 255)
		data[i] = sample_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func create_two_tone_sound(freq1: float, freq2: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var half: int = num_samples / 2
	var data = PackedByteArray()
	data.resize(num_samples)

	var phase: float = 0.0
	for i in range(num_samples):
		var freq: float = freq1 if i < half else freq2
		var t: float = float(i) / float(num_samples)
		var env: float = (1.0 - (float(i % half) / float(half))) * volume
		phase += freq / float(sample_rate)
		var val: float = sin(phase * TAU)
		var sample_val: int = clampi(int(val * env * 127.0) + 128, 0, 255)
		data[i] = sample_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func create_click_sound(duration: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)

	for i in range(num_samples):
		var is_click = (i < 150) or (i > 800 and i < 950)
		var val: float = randf_range(-1.0, 1.0) if is_click else 0.0
		var sample_val: int = clampi(int(val * 0.7 * 127.0) + 128, 0, 255)
		data[i] = sample_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func create_music_track(track_name: String) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 2.4 # Seamless looping musical motif
	var num_samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)

	match track_name:
		"iron_crucible":
			var bass_notes = [110.0, 110.0, 130.8, 110.0, 98.0, 110.0, 130.8, 146.8]
			for i in range(num_samples):
				var t: float = float(i) / float(sample_rate)
				var step: int = int(t * 8.0) % bass_notes.size()
				var freq: float = bass_notes[step]
				var step_t: float = fmod(t * 8.0, 1.0)
				var env: float = maxf(0.0, 1.0 - step_t * 1.6) * 0.35
				var val: float = sin(t * freq * TAU) * env
				data[i] = clampi(int(val * 127.0) + 128, 0, 255)
		"metro_siege":
			for i in range(num_samples):
				var t: float = float(i) / float(sample_rate)
				var drone: float = sin(t * 55.0 * TAU) * 0.35 + sin(t * 82.5 * TAU) * 0.15
				var clang_env: float = maxf(0.0, 1.0 - fmod(t * 2.0, 1.0) * 4.0) * 0.12
				var clang: float = sin(t * 440.0 * TAU) * clang_env
				var val: float = drone + clang
				data[i] = clampi(int(val * 127.0) + 128, 0, 255)
		"nitro_kick":
			var lead_notes = [220.0, 261.6, 329.6, 392.0]
			for i in range(num_samples):
				var t: float = float(i) / float(sample_rate)
				var kick_t: float = fmod(t * 4.0, 1.0)
				var kick_freq: float = lerpf(110.0, 45.0, kick_t)
				var kick: float = sin(t * kick_freq * TAU) * maxf(0.0, 1.0 - kick_t * 2.5) * 0.45
				var step: int = int(t * 4.0) % lead_notes.size()
				var lead: float = (2.0 * fmod(t * lead_notes[step], 1.0) - 1.0) * 0.12
				var val: float = kick + lead
				data[i] = clampi(int(val * 127.0) + 128, 0, 255)
		"drift_storm":
			var arp = [330.0, 392.0, 493.88, 659.25, 493.88, 392.0, 330.0, 293.66]
			for i in range(num_samples):
				var t: float = float(i) / float(sample_rate)
				var step: int = int(t * 10.0) % arp.size()
				var saw: float = (2.0 * fmod(t * arp[step], 1.0) - 1.0) * 0.22
				data[i] = clampi(int(saw * 127.0) + 128, 0, 255)
		_:
			for i in range(num_samples):
				data[i] = 128

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	wav.data = data
	return wav
