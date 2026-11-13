extends CanvasLayer

func _ready() -> void:
	$Panel/VBox/BtnContinue.pressed.connect(func():
		AudioManager.play_ui("ui_click")
		queue_free()
		var next_idx: int = GameManager.selected_mission_index + 1
		if GameManager.current_mode == GameManager.GameMode.CAMPAIGN and next_idx < 5:
			GameManager.start_campaign_mission(next_idx)
		else:
			GameManager.return_to_main_menu()
	)
	$Panel/VBox/BtnMenu.pressed.connect(func():
		AudioManager.play_ui("ui_click")
		queue_free()
		GameManager.return_to_main_menu()
	)

func set_summary(data: Dictionary) -> void:
	var t: int = int(data.get("time", 0.0))
	$Panel/VBox/ScoreLabel.text = "Score: %d" % int(data.get("score", 0))
	$Panel/VBox/TimeLabel.text = "Completion Time: %02d:%02d" % [t / 60, t % 60]
	$Panel/VBox/AccuracyLabel.text = "Accuracy: %.1f%%  |  Hostiles Defeated: %d" % [float(data.get("accuracy", 0.0)), int(data.get("kills", 0))]
	$Panel/VBox/RewardLabel.text = "Mission Reward: +%d Credits" % int(data.get("reward", 0))
