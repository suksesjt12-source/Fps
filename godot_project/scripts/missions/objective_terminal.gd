class_name ObjectiveTerminal
extends StaticBody3D

@export var objective_id: String = ""
@export var prompt_text: String = "[USE] Activate Device"
@export var is_collectible: bool = false
@export var beacon_color: Color = Color(0.18, 0.85, 0.95, 1.0)

var _activated: bool = false

@onready var indicator_mesh: MeshInstance3D = get_node_or_null("Indicator")
@onready var omni_light: OmniLight3D = get_node_or_null("OmniLight3D")

func _ready() -> void:
	if GameManager.current_mode != GameManager.GameMode.CAMPAIGN:
		visible = false
		set_collision_layer_value(5, false)
		return
	_update_visual(false)

func get_interact_prompt() -> String:
	if _activated:
		return ""
	return prompt_text

func interact(_player: Node) -> void:
	if _activated or GameManager.current_mode != GameManager.GameMode.CAMPAIGN:
		return
	_activated = true
	_update_visual(true)
	AudioManager.play_sfx_3d_key("objective_updated", global_position)
	if not objective_id.is_empty():
		MissionManager.complete_objective(objective_id)
	if is_collectible:
		visible = false
		set_collision_layer_value(5, false)

func _update_visual(done: bool) -> void:
	var c := Color(0.2, 0.92, 0.45, 1.0) if done else beacon_color
	if indicator_mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = c
		mat.emission_enabled = true
		mat.emission = c
		mat.emission_energy_multiplier = 2.0
		indicator_mesh.material_override = mat
	if omni_light:
		omni_light.light_color = c
