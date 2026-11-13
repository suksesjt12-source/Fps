extends CanvasLayer

func _ready() -> void:
	$Panel/VBox/BtnRetry.pressed.connect(func():
		AudioManager.play_ui("ui_click")
		queue_free()
		GameManager.restart_current_match()
	)
	$Panel/VBox/BtnMenu.pressed.connect(func():
		AudioManager.play_ui("ui_click")
		queue_free()
		GameManager.return_to_main_menu()
	)

func set_reason(reason: String) -> void:
	$Panel/VBox/ReasonLabel.text = reason
