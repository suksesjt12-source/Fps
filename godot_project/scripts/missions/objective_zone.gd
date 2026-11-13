class_name ObjectiveZone
extends Area3D

@export var objective_id: String = ""
@export var require_area_clear: bool = false
@export var clear_radius: float = 22.0

var _completed: bool = false
var _player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if _completed or not _player_inside:
		return
	if GameManager.current_mode != GameManager.GameMode.CAMPAIGN:
		return
	if require_area_clear:
		if _count_nearby_enemies() == 0:
			_trigger_complete()
	else:
		_trigger_complete()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		if GameManager.current_mode == GameManager.GameMode.CAMPAIGN and require_area_clear and _count_nearby_enemies() > 0:
			UIManager.show_toast("Eliminate remaining hostiles to secure zone!")

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _count_nearby_enemies() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D and is_instance_valid(enemy):
			if (enemy as Node3D).global_position.distance_to(global_position) <= clear_radius:
				if enemy.get("current_state") != EnemyAI.AIState.DEFEATED:
					count += 1
	return count

func _trigger_complete() -> void:
	if _completed:
		return
	_completed = true
	if not objective_id.is_empty():
		MissionManager.complete_objective(objective_id)
