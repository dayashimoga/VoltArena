class_name CoverageRegistry
extends RefCounted

## Tracks which GDScript classes and functions are exercised by tests.
## At test-end, compares against a static inventory of all project functions
## to compute real function-level coverage.

# { "res://path/file.gd": { "func_name": true } }
var exercised: Dictionary = {}

# { "res://path/file.gd": ["func1", "func2", ...] }
var inventory: Dictionary = {}

# Directories to scan for production code (exclude tests themselves)
const SCAN_DIRS: Array[String] = [
	"res://shared/",
	"res://games/",
	"res://launcher/"
]

const EXCLUDE_PATTERNS: Array[String] = [
	"res://tests/"
]

func build_inventory() -> void:
	inventory.clear()
	for scan_dir in SCAN_DIRS:
		_scan_directory(scan_dir)

func _scan_directory(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		var full_path = path + entry
		if dir.current_is_dir():
			_scan_directory(full_path + "/")
		elif entry.ends_with(".gd"):
			_scan_script_file(full_path)
		entry = dir.get_next()
	dir.list_dir_end()

func _scan_script_file(file_path: String) -> void:
	for pattern in EXCLUDE_PATTERNS:
		if file_path.begins_with(pattern):
			return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return

	var funcs: Array[String] = []
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		# Match func declarations: "func name(" or "static func name("
		if line.begins_with("func ") or line.begins_with("static func "):
			var func_name = _extract_func_name(line)
			if func_name != "" and not func_name.begins_with("_"):
				# Include public functions; also include _ready, _process, _physics_process, _init, _input
				funcs.append(func_name)
			elif func_name in ["_ready", "_process", "_physics_process", "_init", "_input", "_unhandled_input", "_notification"]:
				funcs.append(func_name)
	file.close()

	if funcs.size() > 0:
		inventory[file_path] = funcs

func _extract_func_name(line: String) -> String:
	# "func foo_bar(args) -> type:" => "foo_bar"
	var start = line.find("func ") + 5
	if line.begins_with("static func "):
		start = line.find("func ") + 5
	var paren = line.find("(", start)
	if paren < 0:
		return ""
	return line.substr(start, paren - start).strip_edges()

func register_tested(script_path: String, func_name: String) -> void:
	if not exercised.has(script_path):
		exercised[script_path] = {}
	exercised[script_path][func_name] = true

func register_class_tested(script_path: String, func_names: Array) -> void:
	for fn in func_names:
		register_tested(script_path, fn)

func compute_coverage() -> Dictionary:
	var total_funcs: int = 0
	var tested_funcs: int = 0
	var per_file: Dictionary = {}

	for file_path in inventory.keys():
		var file_funcs: Array = inventory[file_path]
		var file_tested: int = 0
		var file_untested: Array[String] = []

		for fn in file_funcs:
			total_funcs += 1
			if exercised.has(file_path) and exercised[file_path].has(fn):
				file_tested += 1
				tested_funcs += 1
			else:
				file_untested.append(fn)

		per_file[file_path] = {
			"total": file_funcs.size(),
			"tested": file_tested,
			"coverage_pct": (float(file_tested) / float(file_funcs.size())) * 100.0 if file_funcs.size() > 0 else 100.0,
			"untested": file_untested
		}

	var overall_pct = (float(tested_funcs) / float(total_funcs)) * 100.0 if total_funcs > 0 else 0.0

	return {
		"total_functions": total_funcs,
		"tested_functions": tested_funcs,
		"overall_coverage_pct": overall_pct,
		"per_file": per_file
	}

func save_report(output_path: String) -> void:
	var report = compute_coverage()
	report["timestamp"] = Time.get_datetime_string_from_system(true)

	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists("artifacts"):
		dir.make_dir("artifacts")

	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
		print("[COVERAGE] Report saved to: %s" % output_path)
	else:
		push_error("[COVERAGE] Failed to write report to: %s" % output_path)

func print_summary() -> void:
	var report = compute_coverage()
	print("==================================================")
	print("       COVERAGE REPORT                            ")
	print("==================================================")
	print("  Total Functions:   %d" % report["total_functions"])
	print("  Tested Functions:  %d" % report["tested_functions"])
	print("  Overall Coverage:  %.1f%%" % report["overall_coverage_pct"])
	print("--------------------------------------------------")

	# Show files with < 100% coverage
	var per_file: Dictionary = report["per_file"]
	var low_coverage_files: Array = []
	for fp in per_file.keys():
		var info = per_file[fp]
		if info["coverage_pct"] < 100.0:
			low_coverage_files.append({"path": fp, "info": info})

	if low_coverage_files.size() > 0:
		print("  Files with gaps:")
		for entry in low_coverage_files:
			var info = entry["info"]
			print("    %s: %.0f%% (%d/%d) — untested: %s" % [
				entry["path"].get_file(),
				info["coverage_pct"],
				info["tested"],
				info["total"],
				", ".join(info["untested"])
			])
	print("==================================================")
