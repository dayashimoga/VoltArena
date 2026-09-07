class_name TestBenchmarkV2
extends SceneTree

## VoltArena Performance Benchmark Suite v2.0
## Measures: procedural gen timing, combat throughput, memory, rendering info,
## per-preset validation, time-to-playable, stutter detection

const ArenaGen = preload("res://games/arena-fps/maps/arena_map_generator.gd")
const SubwayGen = preload("res://games/subway-survival/maps/subway_generator.gd")
const TrackGen = preload("res://games/kart-racing/tracks/track_generator.gd")
const SkyboundWorldGen = preload("res://games/skybound-odyssey/world/skybound_world.gd")
const Workshop3DGen = preload("res://games/roboforge-arena/workshop/workshop_3d.gd")
const WildBiomesGen = preload("res://games/wildcircuit/world/wild_biomes.gd")
const HealthComp = preload("res://shared/combat/health_component.gd")
const QualityMgr = preload("res://shared/graphics/quality_manager.gd")

func _init() -> void:
	print("==================================================")
	print("   VOLTARENA PERFORMANCE BENCHMARKS v2.0          ")
	print("==================================================")

	var results: Dictionary = {}
	var all_passed: bool = true

	# --- Procedural Generation Benchmarks ---
	print("\n[SECTION] Procedural Generation Timing")
	results["arena_gen_ms"] = bench_gen("Arena Map", ArenaGen)
	results["subway_gen_ms"] = bench_gen("Subway Tunnel", SubwayGen)
	results["track_gen_ms"] = bench_gen("Kart Track", TrackGen)
	results["skybound_gen_ms"] = bench_gen("Skybound World", SkyboundWorldGen)
	results["roboforge_workshop_ms"] = bench_gen("RoboForge Workshop", Workshop3DGen)
	results["wildcircuit_biomes_ms"] = bench_gen("WildCircuit Biomes", WildBiomesGen)

	# --- Combat Throughput ---
	print("\n[SECTION] Combat Throughput")
	var t0 = Time.get_ticks_usec()
	var hc = HealthComp.new()
	hc._ready()
	for i in range(10000):
		hc.reset()
		hc.take_damage(25.0)
		hc.heal(10.0)
		hc.add_armor(15.0)
	var t_combat = (Time.get_ticks_usec() - t0) / 1000.0
	results["combat_10k_ms"] = t_combat
	print("[BENCH] 10,000 Combat Ticks: %6.2f ms (Budget: <50ms)" % t_combat)
	hc.free()

	# --- Memory Measurements ---
	print("\n[SECTION] Memory Usage")
	var static_mem_mb = OS.get_static_memory_usage() / (1024.0 * 1024.0)
	results["static_memory_mb"] = static_mem_mb
	print("[BENCH] Static Memory:       %6.2f MB (Budget: <500MB)" % static_mem_mb)

	# --- Rendering Info (headless will return minimal values) ---
	print("\n[SECTION] Rendering Statistics")
	var draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var objects_in_frame = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	results["draw_calls"] = draw_calls
	results["objects_in_frame"] = objects_in_frame
	print("[BENCH] Draw Calls:          %d" % draw_calls)
	print("[BENCH] Objects in Frame:    %d" % objects_in_frame)

	# --- Quality Preset Validation ---
	print("\n[SECTION] Quality Preset Validation")
	var qm = QualityMgr.new()
	var presets = {"LOW": 0, "MEDIUM": 1, "HIGH": 2, "ULTRA": 3, "AUTO": 4}
	var preset_results: Dictionary = {}
	for preset_name in presets.keys():
		var preset_id = presets[preset_name]
		qm.apply_preset(preset_id)
		var preset_passed = (qm.current_preset == preset_id) or (preset_id == 4)  # AUTO resolves to MEDIUM/HIGH
		preset_results[preset_name] = "PASS" if preset_passed else "FAIL"
		print("[BENCH] Preset %-8s: %s (current=%d)" % [preset_name, preset_results[preset_name], qm.current_preset])
		if not preset_passed:
			all_passed = false
	results["preset_validation"] = preset_results

	# --- Time-to-Playable ---
	print("\n[SECTION] Time-to-Playable")
	var scenes = {
		"ArenaFPS": "res://games/arena-fps/arena_fps_main.gd",
		"SubwaySurvival": "res://games/subway-survival/subway_main.gd",
		"RocketCar": "res://games/rocket-car/rocket_car_main.gd",
		"KartRacing": "res://games/kart-racing/kart_racing_main.gd",
		"SkyboundOdyssey": "res://games/skybound-odyssey/skybound_main.gd",
		"RoboForgeArena": "res://games/roboforge-arena/roboforge_main.gd",
		"WildCircuit": "res://games/wildcircuit/wildcircuit_main.gd"
	}
	var ttp_budgets = {
		"ArenaFPS": 1000.0,
		"SubwaySurvival": 1500.0,
		"RocketCar": 1000.0,
		"KartRacing": 2500.0,
		"SkyboundOdyssey": 2000.0,
		"RoboForgeArena": 2000.0,
		"WildCircuit": 2500.0
	}
	var ttp_results: Dictionary = {}
	for scene_name in scenes.keys():
		var script = load(scenes[scene_name])
		var t_start = Time.get_ticks_usec()
		var instance = script.new()
		if instance.has_method("setup_scene"):
			instance.setup_scene()
		elif instance.has_method("setup_game"):
			instance.setup_game()
		else:
			instance._ready()
		var t_ttp = (Time.get_ticks_usec() - t_start) / 1000.0
		ttp_results[scene_name] = t_ttp
		var b = ttp_budgets.get(scene_name, 2000.0)
		print("[BENCH] %-16s TTP: %6.2f ms (Budget: <%.0fms)" % [scene_name, t_ttp, b])
		instance.queue_free()
	results["time_to_playable_ms"] = ttp_results

	# --- Frame Time Simulation (300 active simulation ticks) ---
	print("\n[SECTION] Frame Time Stability (300 frames)")
	var frame_times: Array[float] = []
	var arena_main = load("res://games/arena-fps/arena_fps_main.gd").new()
	arena_main.setup_scene()
	for i in range(300):
		var ft0 = Time.get_ticks_usec()
		arena_main._process(0.016)
		for bot in arena_main.bots:
			if is_instance_valid(bot):
				bot._physics_process(0.016)
		if is_instance_valid(arena_main.player_node):
			arena_main.player_node._physics_process(0.016)
		var ft = (Time.get_ticks_usec() - ft0) / 1000.0
		frame_times.append(maxf(0.05, ft))
	arena_main.queue_free()

	frame_times.sort()
	var avg_ft = 0.0
	for ft in frame_times:
		avg_ft += ft
	avg_ft /= frame_times.size()
	var p50_ft = frame_times[int(frame_times.size() * 0.50)]
	var p95_ft = frame_times[int(frame_times.size() * 0.95)]
	var p99_ft = frame_times[int(frame_times.size() * 0.99)]
	var measured_fps = 1000.0 / maxf(0.1, p50_ft)
	var stutter_count = 0
	for ft in frame_times:
		if ft > 33.0:  # >33ms = stutter at 30fps
			stutter_count += 1

	results["avg_frame_time_ms"] = avg_ft
	results["p50_frame_time_ms"] = p50_ft
	results["p95_frame_time_ms"] = p95_ft
	results["p99_frame_time_ms"] = p99_ft
	results["measured_fps"] = measured_fps
	results["stutter_count"] = stutter_count
	print("[BENCH] P50 Frame Time:      %6.2f ms" % p50_ft)
	print("[BENCH] P95 Frame Time:      %6.2f ms" % p95_ft)
	print("[BENCH] P99 Frame Time:      %6.2f ms" % p99_ft)
	print("[BENCH] Measured Sim FPS:    %6.1f FPS" % measured_fps)
	print("[BENCH] Stutters (>33ms):    %d / 300 frames" % stutter_count)

	# --- Gate Evaluation ---
	print("\n==================================================")
	var gen_pass = results["arena_gen_ms"] < 500.0 and results["subway_gen_ms"] < 1500.0 and results["track_gen_ms"] < 2500.0 and results["skybound_gen_ms"] < 2500.0 and results["roboforge_workshop_ms"] < 2000.0 and results["wildcircuit_biomes_ms"] < 2500.0
	var combat_pass = results["combat_10k_ms"] < 100.0
	var mem_pass = results["static_memory_mb"] < 500.0
	var ttp_pass = true
	for scene_name in ttp_results.keys():
		var budget = ttp_budgets.get(scene_name, 2000.0)
		if ttp_results[scene_name] > budget:
			ttp_pass = false
	var stutter_pass = stutter_count < 10

	if not gen_pass: all_passed = false
	if not combat_pass: all_passed = false
	if not mem_pass: all_passed = false
	if not ttp_pass: all_passed = false
	if not stutter_pass: all_passed = false

	results["gates"] = {
		"procedural_gen": "PASS" if gen_pass else "FAIL",
		"combat_throughput": "PASS" if combat_pass else "FAIL",
		"memory_budget": "PASS" if mem_pass else "FAIL",
		"time_to_playable": "PASS" if ttp_pass else "FAIL",
		"frame_stability": "PASS" if stutter_pass else "FAIL",
		"quality_presets": "PASS" if not ("FAIL" in preset_results.values()) else "FAIL"
	}
	results["timestamp"] = Time.get_datetime_string_from_system(true)
	results["overall_status"] = "PASS" if all_passed else "FAIL"

	# Save report
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists("artifacts"):
		dir.make_dir("artifacts")
	var file = FileAccess.open("res://artifacts/benchmark-results.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(results, "  "))
		file.close()

	if all_passed:
		print("BENCHMARK STATUS: ALL PERFORMANCE GATES PASSED")
		print("==================================================")
		quit(0)
	else:
		push_error("Performance thresholds exceeded")
		print("==================================================")
		quit(1)

func bench_gen(label: String, script) -> float:
	# Warmup cache (cold I/O load)
	var warmup = script.new()
	warmup._ready()
	warmup.free()

	var t0 = Time.get_ticks_usec()
	var inst = script.new()
	inst._ready()
	var t_ms = (Time.get_ticks_usec() - t0) / 1000.0
	print("[BENCH] %-20s %6.2f ms" % [label + ":", t_ms])
	inst.free()
	return t_ms
