extends Node

signal save_loaded
signal progress_reset

const SAVE_PATH := "user://tactical_strike_save.json"
const SAVE_VERSION := 1

var unlocked_mission_index: int = 0
var completed_missions: Dictionary = {}
var survival_high_score: int = 0
var survival_best_wave: int = 1
var total_credits: int = 0
var selected_difficulty: int = 1

func _ready() -> void:
	load_game()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_game()
		save_loaded.emit()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: Unable to open save file, restoring defaults.")
		save_game()
		return

	var raw_text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err: int = json.parse(raw_text)
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_warning("SaveManager: Corrupted save detected, restoring defaults.")
		reset_all_progress(false)
		return

	var data: Dictionary = json.data
	if int(data.get("version", 0)) != SAVE_VERSION:
		push_warning("SaveManager: Save version mismatch, migrating defaults.")

	unlocked_mission_index = clampi(int(data.get("unlocked_mission_index", 0)), 0, 4)
	var missions_raw = data.get("completed_missions", {})
	completed_missions = missions_raw.duplicate(true) if typeof(missions_raw) == TYPE_DICTIONARY else {}
	survival_high_score = maxi(0, int(data.get("survival_high_score", 0)))
	survival_best_wave = maxi(1, int(data.get("survival_best_wave", 1)))
	total_credits = maxi(0, int(data.get("total_credits", 0)))
	selected_difficulty = clampi(int(data.get("selected_difficulty", 1)), 0, 2)
	GameManager.current_difficulty = selected_difficulty

	var settings_raw = data.get("settings", {})
	if typeof(settings_raw) == TYPE_DICTIONARY:
		SettingsManager.from_dict(settings_raw)

	save_loaded.emit()

func save_game() -> void:
	var payload: Dictionary = {
		"version": SAVE_VERSION,
		"unlocked_mission_index": unlocked_mission_index,
		"completed_missions": completed_missions,
		"survival_high_score": survival_high_score,
		"survival_best_wave": survival_best_wave,
		"total_credits": total_credits,
		"selected_difficulty": GameManager.current_difficulty,
		"settings": SettingsManager.to_dict()
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to write save file to %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

func record_mission_completion(mission_idx: int, score_val: int, elapsed_sec: float, accuracy: float) -> void:
	var key := str(mission_idx)
	var prev: Dictionary = completed_missions.get(key, {})
	var best_score: int = maxi(score_val, int(prev.get("best_score", 0)))
	var prev_time: float = float(prev.get("best_time", 999999.0))
	var best_time: float = minf(elapsed_sec, prev_time)
	completed_missions[key] = {
		"completed": true,
		"best_score": best_score,
		"best_time": best_time,
		"best_accuracy": maxf(accuracy, float(prev.get("best_accuracy", 0.0)))
	}
	if mission_idx >= unlocked_mission_index and mission_idx < 4:
		unlocked_mission_index = mission_idx + 1
	total_credits += int(score_val * 0.2)
	save_game()

func record_survival_highscore(score_val: int, wave_val: int) -> void:
	if score_val > survival_high_score:
		survival_high_score = score_val
	if wave_val > survival_best_wave:
		survival_best_wave = wave_val
	save_game()

func is_mission_unlocked(mission_idx: int) -> bool:
	return mission_idx <= unlocked_mission_index

func is_mission_completed(mission_idx: int) -> bool:
	var entry: Dictionary = completed_missions.get(str(mission_idx), {})
	return bool(entry.get("completed", false))

func get_mission_record(mission_idx: int) -> Dictionary:
	return completed_missions.get(str(mission_idx), {})

func reset_all_progress(keep_settings: bool = true) -> void:
	unlocked_mission_index = 0
	completed_missions.clear()
	survival_high_score = 0
	survival_best_wave = 1
	total_credits = 0
	if not keep_settings:
		SettingsManager.from_dict({})
	save_game()
	progress_reset.emit()
