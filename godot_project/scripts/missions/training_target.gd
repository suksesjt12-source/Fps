class_name TrainingTarget
extends Area3D

@export var move_axis: Vector3 = Vector3(4.0, 0.0, 0.0)
@export var move_speed: float = 1.6
@export var max_hp: float = 60.0

var _hp: float = 60.0
var _origin: Vector3 = Vector3.ZERO
var _time: float = 0.0
var _down: bool = false

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	_origin = position
	_hp = max_hp

func _process(delta: float) -> void:
	if _down:
		return
	_time += delta * move_speed
	position = _origin + move_axis * sin(_time)

func is_head_hitbox() -> bool:
	return false

func apply_bullet_damage(damage: float, _hit_pos: Vector3, _attacker_pos: Vector3) -> bool:
	if _down:
		return false
	_hp -= damage
	if _hp <= 0.0:
		_down = true
		GameManager.register_enemy_kill(50, false)
		var tw := create_tween()
		tw.tween_property(mesh, "rotation_degrees:x", 90.0, 0.18)
		AudioManager.play_sfx_3d_key("impact_metal", global_position)
		_respawn_after_delay()
		return true
	return false

func _respawn_after_delay() -> void:
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(self):
		_hp = max_hp
		_down = false
		var tw := create_tween()
		tw.tween_property(mesh, "rotation_degrees:x", 0.0, 0.2)
