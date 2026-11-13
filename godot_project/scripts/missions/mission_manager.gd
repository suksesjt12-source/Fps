extends Node

signal mission_prepared(mission: MissionData)
signal objective_updated(obj_id: String, label: String, completed: bool, is_secondary: bool)
signal all_primary_completed

const MISSION_RESOURCES := [
	"res://resources/missions/mission_01_abandoned_city.tres",
	"res://resources/missions/mission_02_desert_facility.tres",
	"res://resources/missions/mission_03_frozen_base.tres",
	"res://resources/missions/mission_04_underground_complex.tres",
	"res://resources/missions/mission_05_industrial_harbor.tres"
]

var missions: Array[MissionData] = []
var current_mission: MissionData = null
var objectives_state: Dictionary = {}

func _ready() -> void:
	_load_missions()

func _load_missions() -> void:
	missions.clear()
	for path in MISSION_RESOURCES:
		if ResourceLoader.exists(path):
			var m := load(path) as MissionData
			if m:
				missions.append(m)

func get_mission(idx: int) -> MissionData:
	if idx < 0 or idx >= missions.size():
		return null
	return missions[idx]

func get_all_missions() -> Array[MissionData]:
	return missions

func prepare_mission(mission: MissionData) -> void:
	current_mission = mission
	objectives_state.clear()
	for i in range(mission.primary_objective_ids.size()):
		var oid: String = mission.primary_objective_ids[i]
		var lbl: String = mission.primary_objective_labels[i] if i < mission.primary_objective_labels.size() else oid
		objectives_state[oid] = {
			"label": lbl,
			"completed": false,
			"secondary": false
		}
	for i in range(mission.secondary_objective_ids.size()):
		var soid: String = mission.secondary_objective_ids[i]
		var slbl: String = mission.secondary_objective_labels[i] if i < mission.secondary_objective_labels.size() else soid
		objectives_state[soid] = {
			"label": slbl,
			"completed": false,
			"secondary": true
		}
	mission_prepared.emit(mission)

func clear_mission() -> void:
	current_mission = null
	objectives_state.clear()

func complete_objective(obj_id: String) -> void:
	if not objectives_state.has(obj_id):
		return
	var entry: Dictionary = objectives_state[obj_id]
	if bool(entry["completed"]):
		return
	entry["completed"] = true
	var is_sec: bool = bool(entry["secondary"])
	objective_updated.emit(obj_id, str(entry["label"]), true, is_sec)
	AudioManager.play_stinger("objective_updated")
	UIManager.show_toast("Objective Complete: %s" % str(entry["label"]))

	if is_sec:
		GameManager.score += 250
		GameManager.score_changed.emit(GameManager.score)

	if _are_all_primary_complete():
		all_primary_completed.emit()
		var bonus: int = current_mission.reward_credits if current_mission else 500
		# Slight delay so toast and stinger breathe before victory modal
		await get_tree().create_timer(1.0).timeout
		if GameManager.current_state == GameManager.GameState.PLAYING:
			GameManager.trigger_victory(bonus)

func fail_objective(reason: String) -> void:
	GameManager.trigger_game_over(reason)

func _are_all_primary_complete() -> bool:
	if current_mission == null:
		return false
	var any_primary := false
	for oid in objectives_state.keys():
		var entry: Dictionary = objectives_state[oid]
		if not bool(entry["secondary"]):
			any_primary = true
			if not bool(entry["completed"]):
				return false
	return any_primary

func get_ordered_objectives() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if current_mission == null:
		return out
	for oid in current_mission.primary_objective_ids:
		if objectives_state.has(oid):
			var d: Dictionary = objectives_state[oid].duplicate()
			d["id"] = oid
			out.append(d)
	for soid in current_mission.secondary_objective_ids:
		if objectives_state.has(soid):
			var d2: Dictionary = objectives_state[soid].duplicate()
			d2["id"] = soid
			out.append(d2)
	return out
