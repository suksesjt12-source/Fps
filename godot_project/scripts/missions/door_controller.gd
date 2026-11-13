class_name DoorController
extends StaticBody3D

@export var slide_offset: Vector3 = Vector3(2.4, 0.0, 0.0)
@export var open_duration: float = 0.45

var _is_open: bool = false
var _closed_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	_closed_pos = position

func get_interact_prompt() -> String:
	return "[USE] Close Door" if _is_open else "[USE] Open Door"

func interact(_player: Node) -> void:
	_is_open = not _is_open
	var target: Vector3 = _closed_pos + slide_offset if _is_open else _closed_pos
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", target, open_duration)
	AudioManager.play_sfx_3d_key("ui_click", global_position, -2.0)
