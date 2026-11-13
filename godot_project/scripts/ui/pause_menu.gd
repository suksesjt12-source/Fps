extends CanvasLayer

@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Panel/VBox/BtnResume.pressed.connect(func():
		AudioManager.play_ui("ui_click")
		GameManager.resume_game()
	)
	$Panel/VBox/BtnRestart.pressed.connect(func():
		AudioManager.play_ui("ui_click")
		UIManager.hide_pause_menu()
		GameManager.restart_current_match()
	)
	$Panel/VBox/BtnMainMenu.pressed.connect(func():
		AudioManager.play_ui("ui_click")
		UIManager.hide_pause_menu()
		GameManager.return_to_main_menu()
	)

func open_animated() -> void:
	if anim_player and anim_player.has_animation("open"):
		anim_player.play("open")
