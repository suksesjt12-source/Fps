extends Node

func _ready() -> void:
	AudioManager.play_music("menu")
	get_tree().change_scene_to_file.call_deferred("res://scenes/menus/main_menu.tscn")
