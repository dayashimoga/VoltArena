extends Node

# Audio buses
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
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Master"
	add_child(bgm_player)

	engine_sfx_player = AudioStreamPlayer.new()
	engine_sfx_player.name = "EngineSFXPlayer"
	engine_sfx_player.bus = "Master"
	add_child(engine_sfx_player)

	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_" + str(i)
		p.bus = "Master"
		add_child(p)
		sfx_pool.append(p)

	for i in range(POOL_3D_SIZE):
		var p3 = AudioStreamPlayer3D.new()
		p3.name = "SFX3DPlayer_" + str(i)
		p3.bus = "Master"
		p3.max_distance = 50.0
		p3.unit_size = 10.0
		add_child(p3)
		sfx_3d_pool.append(p3)

func generate_all_procedural_sounds() -> void:
	# Laser fire: high pitch downwards sweep
	sound_cache["laser_fire"] = create_synth_sound(880.0, 220.0, 0.12, 0.7, "sine")
	# Shotgun blast: filtered noise with punchy transient
	sound_cache["shotgun_fire"] = create_noise_burst(0.25, 1.0, 0.8)
	# Railgun: intense charged beam
	sound_cache["railgun_fire"] = create_synth_sound(1200.0, 110.0, 0.35, 0.9, "saw")
	# Explosion: low noise decay
	sound_cache["explosion"] = create_noise_burst(0.65, 0.9, 0.3)
	# Jump: rising sine
	sound_cache["jump"] = create_synth_sound(220.0, 440.0, 0.15, 0.5, "sine")
	# Hit: short punch
	sound_cache["hit"] = create_synth_sound(180.0, 60.0, 0.08, 0.8, "square")
	# Pickup: rising arpeggio
	sound_cache["pickup"] = create_two_tone_sound(523.25, 659.25, 0.16, 0.6)
	# Reload: metallic dual click
	sound_cache["reload"] = create_click_sound(0.2)
	# Countdown beep
	sound_cache["beep_low"] = create_synth_sound(440.0, 440.0, 0.12, 0.6, "sine")
	sound_cache["beep_high"] = create_synth_sound(880.0, 880.0, 0.25, 0.8, "sine")
	# Goal fanfare
	sound_cache["goal"] = create_two_tone_sound(659.25, 1046.5, 0.45, 0.9)
	# Drift screech
	sound_cache["drift_screech"] = create_noise_burst(0.3, 0.4, 0.9)

func play_sound(sound_name: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not sound_cache.has(sound_name):
		return
	var stream: AudioStreamWAV = sound_cache[sound_name]
	for p in sfx_pool:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = clampf(pitch_scale + randf_range(-0.04, 0.04), 0.5, 2.0)
			p.volume_db = volume_db
			p.play()
			return
	# If all busy, steal the first one
	var p = sfx_pool[0]
	p.stream = stream
	p.pitch_scale = pitch_scale
	p.volume_db = volume_db
	p.play()

func play_sound_3d(sound_name: String, global_pos: Vector3, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not sound_cache.has(sound_name):
		return
	var stream: AudioStreamWAV = sound_cache[sound_name]
	for p in sfx_3d_pool:
		if not p.playing:
			p.global_position = global_pos
			p.stream = stream
			p.pitch_scale = clampf(pitch_scale + randf_range(-0.04, 0.04), 0.5, 2.0)
			p.volume_db = volume_db
			p.play()
			return
	var p = sfx_3d_pool[0]
	p.global_position = global_pos
	p.stream = stream
	p.pitch_scale = pitch_scale
	p.volume_db = volume_db
	p.play()

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
		var t: float = float(i) / float(num_samples)
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
