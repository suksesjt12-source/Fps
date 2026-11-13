extends Node3D

@export var lifetime: float = 0.75
@export var auto_free: bool = true

@onready var particles: CPUParticles3D = get_node_or_null("CPUParticles3D")
@onready var flash_light: OmniLight3D = get_node_or_null("OmniLight3D")

func _ready() -> void:
	if particles:
		particles.emitting = true
	if flash_light:
		var tw := create_tween()
		tw.tween_property(flash_light, "light_energy", 0.0, minf(0.16, lifetime))
	if auto_free:
		await get_tree().create_timer(lifetime).timeout
		queue_free()
