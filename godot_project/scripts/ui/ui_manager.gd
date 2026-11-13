extends Node

signal hud_toast_requested(message: String)
signal hit_marker_requested(is_kill: bool, is_headshot: bool)
signal damage_indicator_requested(source_world_pos: Vector3, amount: float)
signal interaction_prompt_changed(prompt_text: String)
signal kill_feed_requested(points: int, is_headshot: bool)

var active_hud: Node = null
var _pause_overlay: Control = null
var _victory_overlay: Control = null
var _gameover_overlay: Control = null

const PAUSE_SCENE := "res://scenes/menus/pause_menu.tscn"
const VICTORY_SCENE := "res://scenes/menus/victory_screen.tscn"
const GAME_OVER_SCENE := "res://scenes/menus/game_over_screen.tscn"

func register_hud(hud_node: Node) -> void:
	active_hud = hud_node

func show_toast(message: String) -> void:
	hud_toast_requested.emit(message)

func trigger_hit_marker(is_kill: bool, is_headshot: bool) -> void:
	hit_marker_requested.emit(is_kill, is_headshot)
	AudioManager.play_sfx_key_2d("hit_marker", 0.0, 1.18 if is_headshot else 1.0)

func trigger_damage_indicator(source_world_pos: Vector3, amount: float) -> void:
	damage_indicator_requested.emit(source_world_pos, amount)

func set_interaction_prompt(text: String) -> void:
	interaction_prompt_changed.emit(text)

func show_kill_notification(points: int, is_headshot: bool) -> void:
	kill_feed_requested.emit(points, is_headshot)

func show_pause_menu() -> void:
	if _pause_overlay == null and ResourceLoader.exists(PAUSE_SCENE):
		var packed := load(PAUSE_SCENE) as PackedScene
		if packed:
			_pause_overlay = packed.instantiate()
			get_tree().root.add_child(_pause_overlay)
	if _pause_overlay:
		_pause_overlay.visible = true
		if _pause_overlay.has_method("open_animated"):
			_pause_overlay.open_animated()

func hide_pause_menu() -> void:
	if _pause_overlay and is_instance_valid(_pause_overlay):
		_pause_overlay.visible = false

func show_victory_screen(summary: Dictionary) -> void:
	hide_pause_menu()
	if _victory_overlay and is_instance_valid(_victory_overlay):
		_victory_overlay.queue_free()
	if ResourceLoader.exists(VICTORY_SCENE):
		var packed := load(VICTORY_SCENE) as PackedScene
		if packed:
			_victory_overlay = packed.instantiate()
			get_tree().root.add_child(_victory_overlay)
			if _victory_overlay.has_method("set_summary"):
				_victory_overlay.set_summary(summary)

func show_game_over_screen(reason: String) -> void:
	hide_pause_menu()
	if _gameover_overlay and is_instance_valid(_gameover_overlay):
		_gameover_overlay.queue_free()
	if ResourceLoader.exists(GAME_OVER_SCENE):
		var packed := load(GAME_OVER_SCENE) as PackedScene
		if packed:
			_gameover_overlay = packed.instantiate()
			get_tree().root.add_child(_gameover_overlay)
			if _gameover_overlay.has_method("set_reason"):
				_gameover_overlay.set_reason(reason)

func clear_overlays() -> void:
	for overlay in [_pause_overlay, _victory_overlay, _gameover_overlay]:
		if overlay and is_instance_valid(overlay):
			overlay.queue_free()
	_pause_overlay = null
	_victory_overlay = null
	_gameover_overlay = null
