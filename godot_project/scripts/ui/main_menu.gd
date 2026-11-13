extends Control

const MAP_OPTIONS := [
	{"label": "Abandoned City", "path": "res://scenes/environments/map_abandoned_city.tscn"},
	{"label": "Desert Facility", "path": "res://scenes/environments/map_desert_facility.tscn"},
	{"label": "Frozen Research Base", "path": "res://scenes/environments/map_frozen_base.tscn"},
	{"label": "Underground Complex", "path": "res://scenes/environments/map_underground_complex.tscn"},
	{"label": "Industrial Harbor", "path": "res://scenes/environments/map_industrial_harbor.tscn"}
]

var _pending_mode: int = GameManager.GameMode.SURVIVAL

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var map_picker_panel: PanelContainer = $MapPickerOverlay
@onready var map_dropdown: OptionButton = $MapPickerOverlay/VBox/MapDropdown
@onready var survival_record_label: Label = $MainLayout/InfoPanel/VBox/SurvivalRecordLabel
@onready var progress_label: Label = $MainLayout/InfoPanel/VBox/CampaignProgressLabel

func _ready() -> void:
	UIManager.clear_overlays()
	AudioManager.play_music("menu")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	map_picker_panel.visible = false

	map_dropdown.clear()
	for m in MAP_OPTIONS:
		map_dropdown.add_item(m["label"])

	survival_record_label.text = "Survival Best: %d pts (Wave %d)" % [SaveManager.survival_high_score, SaveManager.survival_best_wave]
	progress_label.text = "Campaign Unlocked: Mission %d / 5  |  Credits: %d" % [SaveManager.unlocked_mission_index + 1, SaveManager.total_credits]

	$MainLayout/MenuButtons/BtnPlay.pressed.connect(_on_quick_play)
	$MainLayout/MenuButtons/BtnCampaign.pressed.connect(_on_campaign)
	$MainLayout/MenuButtons/BtnSurvival.pressed.connect(func(): _open_map_picker(GameManager.GameMode.SURVIVAL))
	$MainLayout/MenuButtons/BtnTraining.pressed.connect(_on_training)
	$MainLayout/MenuButtons/BtnFreePractice.pressed.connect(func(): _open_map_picker(GameManager.GameMode.FREE_PRACTICE))
	$MainLayout/MenuButtons/BtnSettings.pressed.connect(_on_settings)
	$MainLayout/MenuButtons/BtnCredits.pressed.connect(_on_credits)
	$MainLayout/MenuButtons/BtnExit.pressed.connect(_on_exit)
	$MapPickerOverlay/VBox/Row/BtnLaunch.pressed.connect(_on_launch_picked_map)
	$MapPickerOverlay/VBox/Row/BtnCancel.pressed.connect(func():
		AudioManager.play_ui("ui_click")
		map_picker_panel.visible = false
	)

	if anim_player and anim_player.has_animation("menu_intro"):
		anim_player.play("menu_intro")

func _on_quick_play() -> void:
	AudioManager.play_ui("ui_click")
	GameManager.start_campaign_mission(SaveManager.unlocked_mission_index)

func _on_campaign() -> void:
	AudioManager.play_ui("ui_click")
	SceneManager.load_scene("res://scenes/menus/mission_select.tscn")

func _on_training() -> void:
	AudioManager.play_ui("ui_click")
	GameManager.start_training()

func _open_map_picker(mode: int) -> void:
	AudioManager.play_ui("ui_click")
	_pending_mode = mode
	$MapPickerOverlay/VBox/Title.text = "Select Sector — Survival" if mode == GameManager.GameMode.SURVIVAL else "Select Sector — Free Practice"
	map_picker_panel.visible = true

func _on_launch_picked_map() -> void:
	AudioManager.play_ui("ui_click")
	var idx: int = clampi(map_dropdown.selected, 0, MAP_OPTIONS.size() - 1)
	var path: String = MAP_OPTIONS[idx]["path"]
	if _pending_mode == GameManager.GameMode.SURVIVAL:
		GameManager.start_survival(path)
	else:
		GameManager.start_free_practice(path)

func _on_settings() -> void:
	AudioManager.play_ui("ui_click")
	SceneManager.load_scene("res://scenes/menus/settings_menu.tscn")

func _on_credits() -> void:
	AudioManager.play_ui("ui_click")
	SceneManager.load_scene("res://scenes/menus/credits_screen.tscn")

func _on_exit() -> void:
	AudioManager.play_ui("ui_click")
	SaveManager.save_game()
	get_tree().quit()
