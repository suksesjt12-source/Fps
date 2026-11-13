extends CanvasLayer

@onready var progress_bar: ProgressBar = $Panel/VBoxContainer/ProgressBar
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func set_progress(pct: float) -> void:
	if progress_bar:
		progress_bar.value = clampf(pct * 100.0, 0.0, 100.0)

func set_target_label(scene_path: String) -> void:
	if status_label:
		status_label.text = "Deploying Sector: %s" % scene_path.get_file().get_basename().replace("_", " ").capitalize()
	modulate_fade_in()

func modulate_fade_in() -> void:
	if anim_player and anim_player.has_animation("fade_in"):
		anim_player.play("fade_in")

func fade_out_and_hide() -> void:
	if anim_player and anim_player.has_animation("fade_out"):
		anim_player.play("fade_out")
		await anim_player.animation_finished
	visible = false
