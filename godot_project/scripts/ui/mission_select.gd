extends Control

var _selected_idx: int = 0

@onready var mission_list: VBoxContainer = $Layout/Body/MissionListScroll/MissionList
@onready var title_label: Label = $Layout/Body/DetailsPanel/VBox/MissionTitle
@onready var location_label: Label = $Layout/Body/DetailsPanel/VBox/LocationLabel
@onready var briefing_label: Label = $Layout/Body/DetailsPanel/VBox/BriefingLabel
@onready var status_label: Label = $Layout/Body/DetailsPanel/VBox/StatusLabel
@onready var difficulty_option: OptionButton = $Layout/Body/DetailsPanel/VBox/DifficultyRow/DifficultyOption
@onready var btn_start: Button = $Layout/Body/DetailsPanel/VBox/BtnStartMission

func _ready() -> void:
	difficulty_option.clear()
	difficulty_option.add_item("Recruit")
	difficulty_option.add_item("Operative")
	difficulty_option.add_item("Veteran")
	difficulty_option.selected = GameManager.current_difficulty
	difficulty_option.item_selected.connect(func(idx: int):
		GameManager.current_difficulty = idx
		SaveManager.save_game()
	)

	$Layout/Header/BtnBack.pressed.connect(func():
		AudioManager.play_ui("ui_click")
		SceneManager.load_scene("res://scenes/menus/main_menu.tscn")
	)
	btn_start.pressed.connect(_on_start_mission)

	_populate_missions()
	_select_mission(SaveManager.unlocked_mission_index)

func _populate_missions() -> void:
	for child in mission_list.get_children():
		child.queue_free()
	var missions := MissionManager.get_all_missions()
	for i in range(missions.size()):
		var m := missions[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 48)
		var unlocked := SaveManager.is_mission_unlocked(i)
		var completed := SaveManager.is_mission_completed(i)
		var badge := " [DONE]" if completed else (" [LOCKED]" if not unlocked else "")
		btn.text = "0%d. %s%s" % [i + 1, m.title, badge]
		btn.disabled = false
		btn.pressed.connect(func():
			AudioManager.play_ui("ui_click")
			_select_mission(i)
		)
		mission_list.add_child(btn)

func _select_mission(idx: int) -> void:
	var m := MissionManager.get_mission(idx)
	if m == null:
		return
	_selected_idx = idx
	title_label.text = m.title
	location_label.text = "Sector: %s  |  Reward: %d Credits" % [m.location_name, m.reward_credits]
	briefing_label.text = m.briefing

	var unlocked := SaveManager.is_mission_unlocked(idx)
	var rec := SaveManager.get_mission_record(idx)
	if not unlocked:
		status_label.text = "Status: Locked — Complete previous mission to unlock."
		btn_start.disabled = true
	elif bool(rec.get("completed", false)):
		status_label.text = "Status: Completed  |  Best Score: %d  |  Best Accuracy: %.1f%%" % [int(rec.get("best_score", 0)), float(rec.get("best_accuracy", 0.0))]
		btn_start.disabled = false
	else:
		status_label.text = "Status: Ready for Deployment"
		btn_start.disabled = false

func _on_start_mission() -> void:
	AudioManager.play_ui("ui_click")
	GameManager.start_campaign_mission(_selected_idx)
