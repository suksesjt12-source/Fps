class_name AlliedNPC
extends CharacterBody3D

@export var objective_id: String = "obj_frozen_protect"
@export var max_health: float = 180.0
@export var protect_duration: float = 18.0

var health: float = 180.0
var _active: bool = false
var _completed: bool = false
var _timer: float = 0.0

func _ready() -> void:
	if GameManager.current_mode != GameManager.GameMode.CAMPAIGN:
		visible = false
		return
	health = max_health
	add_to_group("allies")

func _process(delta: float) -> void:
	if not _active or _completed:
		return
	_timer += delta
	if _timer >= protect_duration:
		_completed = true
		MissionManager.complete_objective(objective_id)

func get_interact_prompt() -> String:
	if _active or _completed:
		return ""
	return "[USE] Secure Field Specialist"

func interact(_player: Node) -> void:
	if _active or _completed:
		return
	_active = true
	UIManager.show_toast("Defend Field Specialist for %ds!" % int(protect_duration))

func take_damage(amount: float) -> void:
	if _completed or GameManager.current_mode != GameManager.GameMode.CAMPAIGN:
		return
	health -= amount
	if health <= 0.0:
		MissionManager.fail_objective("Field Specialist was lost!")
