class_name EnemyHitbox
extends Area3D

@export var is_head: bool = false
@export var owner_enemy_path: NodePath = NodePath("..")

var _owner_enemy: Node = null

func _ready() -> void:
	_owner_enemy = get_node_or_null(owner_enemy_path)

func is_head_hitbox() -> bool:
	return is_head

func apply_bullet_damage(damage: float, hit_pos: Vector3, attacker_pos: Vector3) -> bool:
	if _owner_enemy and _owner_enemy.has_method("take_damage"):
		return _owner_enemy.take_damage(damage, attacker_pos, is_head)
	return false
