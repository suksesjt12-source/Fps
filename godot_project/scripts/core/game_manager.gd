extends Node

signal state_changed(new_state: int, previous_state: int)
signal mode_changed(new_mode: int)
signal score_changed(new_score: int)
signal wave_changed(wave_number: int, remaining_enemies: int)
signal player_stats_updated(kills: int, shots_fired: int, shots_hit: int)

enum GameState {
	MENU,
	LOADING,
	PLAYING,
	PAUSED,
	MISSION_COMPLETE,
	GAME_OVER
}

enum GameMode {
	CAMPAIGN,
	SURVIVAL,
	TRAINING,
	FREE_PRACTICE
}

enum Difficulty {
	RECRUIT = 0,
	OPERATIVE = 1,
	VETERAN = 2
}

var current_state: int = GameState.MENU
var current_mode: int = GameMode.CAMPAIGN
var current_difficulty: int = Difficulty.OPERATIVE
var selected_mission_index: int = 0
var selected_map_path: String = "res://scenes/environments/map_abandoned_city.tscn"

var score: int = 0
var kills: int = 0
var headshots: int = 0
var shots_fired: int = 0
var shots_hit: int = 0
var match_elapsed_time: float = 0.0
var survival_wave: int = 1
var survival_enemies_remaining: int = 0

var active_player: Node = null
var last_checkpoint_transform: Transform3D = Transform3D.IDENTITY
var has_checkpoint: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().set_auto_accept_quit(false)

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		match_elapsed_time += delta

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			if current_state == GameState.PLAYING:
				pause_game()
			if SaveManager:
				SaveManager.save_game()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if current_state == GameState.PLAYING:
				pause_game()
			elif current_state == GameState.PAUSED:
				resume_game()
		NOTIFICATION_WM_CLOSE_REQUEST:
			if SaveManager:
				SaveManager.save_game()
			get_tree().quit()
		NOTIFICATION_OS_MEMORY_WARNING:
			if AudioManager:
				AudioManager.trim_active_voices()

func set_state(new_state: int) -> void:
	if current_state == new_state:
		return
	var prev: int = current_state
	current_state = new_state
	match new_state:
		GameState.PAUSED:
			get_tree().paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GameState.PLAYING:
			get_tree().paused = false
			if not OS.has_feature("android"):
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		GameState.MENU, GameState.MISSION_COMPLETE, GameState.GAME_OVER:
			get_tree().paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	state_changed.emit(new_state, prev)

func start_campaign_mission(mission_idx: int) -> void:
	current_mode = GameMode.CAMPAIGN
	selected_mission_index = mission_idx
	mode_changed.emit(current_mode)
	_reset_match_stats()
	var mission: MissionData = MissionManager.get_mission(mission_idx)
	if mission == null:
		push_error("GameManager: Invalid mission index %d" % mission_idx)
		return
	selected_map_path = mission.map_scene_path
	MissionManager.prepare_mission(mission)
	set_state(GameState.LOADING)
	SceneManager.load_scene(selected_map_path)

func start_survival(map_path: String) -> void:
	current_mode = GameMode.SURVIVAL
	selected_map_path = map_path
	mode_changed.emit(current_mode)
	_reset_match_stats()
	MissionManager.clear_mission()
	set_state(GameState.LOADING)
	SceneManager.load_scene(map_path)

func start_training() -> void:
	current_mode = GameMode.TRAINING
	selected_map_path = "res://scenes/environments/map_training_range.tscn"
	mode_changed.emit(current_mode)
	_reset_match_stats()
	MissionManager.clear_mission()
	set_state(GameState.LOADING)
	SceneManager.load_scene(selected_map_path)

func start_free_practice(map_path: String) -> void:
	current_mode = GameMode.FREE_PRACTICE
	selected_map_path = map_path
	mode_changed.emit(current_mode)
	_reset_match_stats()
	MissionManager.clear_mission()
	set_state(GameState.LOADING)
	SceneManager.load_scene(map_path)

func on_gameplay_scene_ready() -> void:
	has_checkpoint = false
	set_state(GameState.PLAYING)
	AudioManager.play_music("combat")
	if current_mode == GameMode.CAMPAIGN:
		AudioManager.play_stinger("mission_start")

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		set_state(GameState.PAUSED)
		UIManager.show_pause_menu()

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		UIManager.hide_pause_menu()
		set_state(GameState.PLAYING)

func restart_current_match() -> void:
	get_tree().paused = false
	if current_mode == GameMode.CAMPAIGN:
		start_campaign_mission(selected_mission_index)
	elif current_mode == GameMode.SURVIVAL:
		start_survival(selected_map_path)
	elif current_mode == GameMode.TRAINING:
		start_training()
	else:
		start_free_practice(selected_map_path)

func return_to_main_menu() -> void:
	get_tree().paused = false
	MissionManager.clear_mission()
	set_state(GameState.MENU)
	AudioManager.play_music("menu")
	SceneManager.load_scene("res://scenes/menus/main_menu.tscn")

func trigger_victory(bonus_reward: int = 0) -> void:
	if current_state != GameState.PLAYING:
		return
	score += bonus_reward
	score_changed.emit(score)
	set_state(GameState.MISSION_COMPLETE)
	AudioManager.play_stinger("mission_complete")
	AudioManager.play_music("victory")
	if current_mode == GameMode.CAMPAIGN:
		SaveManager.record_mission_completion(selected_mission_index, score, match_elapsed_time, get_accuracy_percent())
	elif current_mode == GameMode.SURVIVAL:
		SaveManager.record_survival_highscore(score, survival_wave)
	UIManager.show_victory_screen({
		"score": score,
		"time": match_elapsed_time,
		"accuracy": get_accuracy_percent(),
		"kills": kills,
		"reward": bonus_reward
	})

func trigger_game_over(reason: String = "Eliminated in action") -> void:
	if current_state != GameState.PLAYING:
		return
	if current_mode == GameMode.SURVIVAL:
		SaveManager.record_survival_highscore(score, survival_wave)
	set_state(GameState.GAME_OVER)
	AudioManager.play_stinger("mission_failed")
	AudioManager.play_music("game_over")
	UIManager.show_game_over_screen(reason)

func register_shot(did_hit: bool) -> void:
	shots_fired += 1
	if did_hit:
		shots_hit += 1
	player_stats_updated.emit(kills, shots_fired, shots_hit)

func register_enemy_kill(points: int, is_headshot: bool = false) -> void:
	kills += 1
	if is_headshot:
		headshots += 1
		points += 50
	score += points
	score_changed.emit(score)
	player_stats_updated.emit(kills, shots_fired, shots_hit)
	UIManager.show_kill_notification(points, is_headshot)

func get_accuracy_percent() -> float:
	if shots_fired <= 0:
		return 0.0
	return clampf((float(shots_hit) / float(shots_fired)) * 100.0, 0.0, 100.0)

func get_difficulty_damage_multiplier() -> float:
	match current_difficulty:
		Difficulty.RECRUIT:
			return 0.75
		Difficulty.VETERAN:
			return 1.35
		_:
			return 1.0

func get_difficulty_ai_reaction_multiplier() -> float:
	match current_difficulty:
		Difficulty.RECRUIT:
			return 1.35
		Difficulty.VETERAN:
			return 0.72
		_:
			return 1.0

func set_checkpoint(xform: Transform3D) -> void:
	last_checkpoint_transform = xform
	has_checkpoint = true
	AudioManager.play_stinger("checkpoint")
	UIManager.show_toast("Checkpoint Activated")

func _reset_match_stats() -> void:
	score = 0
	kills = 0
	headshots = 0
	shots_fired = 0
	shots_hit = 0
	match_elapsed_time = 0.0
	survival_wave = 1
	survival_enemies_remaining = 0
	has_checkpoint = false
	score_changed.emit(0)
