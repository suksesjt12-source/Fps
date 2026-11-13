extends Control

func _ready() -> void:
	$VBox/BtnBack.pressed.connect(func():
		AudioManager.play_ui("ui_click")
		SceneManager.load_scene("res://scenes/menus/main_menu.tscn")
	)
