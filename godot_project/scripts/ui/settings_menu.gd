extends Control

@onready var master_slider: HSlider = $Layout/Tabs/Audio/VBox/MasterRow/Slider
@onready var music_slider: HSlider = $Layout/Tabs/Audio/VBox/MusicRow/Slider
@onready var sfx_slider: HSlider = $Layout/Tabs/Audio/VBox/SFXRow/Slider
@onready var ambience_slider: HSlider = $Layout/Tabs/Audio/VBox/AmbienceRow/Slider

@onready var sens_x_slider: HSlider = $Layout/Tabs/Controls/VBox/SensXRow/Slider
@onready var sens_y_slider: HSlider = $Layout/Tabs/Controls/VBox/SensYRow/Slider
@onready var ads_sens_slider: HSlider = $Layout/Tabs/Controls/VBox/ADSSensRow/Slider
@onready var invert_y_check: CheckButton = $Layout/Tabs/Controls/VBox/InvertYCheck

@onready var preset_option: OptionButton = $Layout/Tabs/Graphics/VBox/PresetRow/Option
@onready var render_scale_slider: HSlider = $Layout/Tabs/Graphics/VBox/ScaleRow/Slider
@onready var shadow_option: OptionButton = $Layout/Tabs/Graphics/VBox/ShadowRow/Option
@onready var msaa_option: OptionButton = $Layout/Tabs/Graphics/VBox/MSAARow/Option
@onready var effects_option: OptionButton = $Layout/Tabs/Graphics/VBox/EffectsRow/Option
@onready var view_dist_slider: HSlider = $Layout/Tabs/Graphics/VBox/DistRow/Slider
@onready var fps_option: OptionButton = $Layout/Tabs/Graphics/VBox/FPSRow/Option
@onready var vsync_check: CheckButton = $Layout/Tabs/Graphics/VBox/VSyncCheck
@onready var show_fps_check: CheckButton = $Layout/Tabs/Graphics/VBox/ShowFPSCheck
@onready var confirm_reset_dialog: ConfirmationDialog = $ResetConfirmDialog

func _ready() -> void:
	_populate_dropdowns()
	_sync_from_settings()
	_connect_signals()

func _populate_dropdowns() -> void:
	preset_option.clear()
	preset_option.add_item("Low")
	preset_option.add_item("Medium")
	preset_option.add_item("High")
	preset_option.add_item("Custom")

	shadow_option.clear()
	shadow_option.add_item("Off")
	shadow_option.add_item("Low")
	shadow_option.add_item("High")

	msaa_option.clear()
	msaa_option.add_item("Off")
	msaa_option.add_item("2x MSAA")
	msaa_option.add_item("4x MSAA")

	effects_option.clear()
	effects_option.add_item("Low")
	effects_option.add_item("Medium")
	effects_option.add_item("High")

	fps_option.clear()
	fps_option.add_item("30 FPS")
	fps_option.add_item("60 FPS")

func _sync_from_settings() -> void:
	master_slider.value = SettingsManager.master_volume
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume
	ambience_slider.value = SettingsManager.ambience_volume

	sens_x_slider.value = SettingsManager.look_sensitivity_x
	sens_y_slider.value = SettingsManager.look_sensitivity_y
	ads_sens_slider.value = SettingsManager.ads_sensitivity_multiplier
	invert_y_check.button_pressed = SettingsManager.invert_y

	preset_option.selected = SettingsManager.graphics_preset
	render_scale_slider.value = SettingsManager.render_scale
	shadow_option.selected = SettingsManager.shadow_quality
	msaa_option.selected = SettingsManager.msaa_level
	effects_option.selected = SettingsManager.effects_quality
	view_dist_slider.value = SettingsManager.view_distance
	fps_option.selected = 0 if SettingsManager.fps_limit <= 30 else 1
	vsync_check.button_pressed = SettingsManager.vsync_enabled
	show_fps_check.button_pressed = SettingsManager.show_fps

func _connect_signals() -> void:
	master_slider.value_changed.connect(func(v): SettingsManager.master_volume = v; SettingsManager.apply_audio_settings())
	music_slider.value_changed.connect(func(v): SettingsManager.music_volume = v; SettingsManager.apply_audio_settings())
	sfx_slider.value_changed.connect(func(v): SettingsManager.sfx_volume = v; SettingsManager.apply_audio_settings())
	ambience_slider.value_changed.connect(func(v): SettingsManager.ambience_volume = v; SettingsManager.apply_audio_settings())

	sens_x_slider.value_changed.connect(func(v): SettingsManager.look_sensitivity_x = v)
	sens_y_slider.value_changed.connect(func(v): SettingsManager.look_sensitivity_y = v)
	ads_sens_slider.value_changed.connect(func(v): SettingsManager.ads_sensitivity_multiplier = v)
	invert_y_check.toggled.connect(func(b): SettingsManager.invert_y = b)

	preset_option.item_selected.connect(func(idx: int):
		if idx < 3:
			SettingsManager.apply_preset(idx)
			_sync_from_settings()
		else:
			SettingsManager.graphics_preset = SettingsManager.GraphicsPreset.CUSTOM
	)
	render_scale_slider.value_changed.connect(func(v): SettingsManager.render_scale = v; SettingsManager.graphics_preset = 3; SettingsManager.apply_graphics_settings())
	shadow_option.item_selected.connect(func(i): SettingsManager.shadow_quality = i; SettingsManager.graphics_preset = 3; SettingsManager.apply_graphics_settings())
	msaa_option.item_selected.connect(func(i): SettingsManager.msaa_level = i; SettingsManager.graphics_preset = 3; SettingsManager.apply_graphics_settings())
	effects_option.item_selected.connect(func(i): SettingsManager.effects_quality = i; SettingsManager.graphics_preset = 3; SettingsManager.apply_graphics_settings())
	view_dist_slider.value_changed.connect(func(v): SettingsManager.view_distance = v; SettingsManager.graphics_preset = 3; SettingsManager.apply_all_settings())
	fps_option.item_selected.connect(func(i): SettingsManager.fps_limit = 30 if i == 0 else 60; SettingsManager.apply_graphics_settings())
	vsync_check.toggled.connect(func(b): SettingsManager.vsync_enabled = b; SettingsManager.apply_graphics_settings())
	show_fps_check.toggled.connect(func(b): SettingsManager.show_fps = b; SettingsManager.apply_all_settings())

	$Layout/Tabs/Controls/VBox/BtnCustomizeHUD.pressed.connect(func():
		AudioManager.play_ui("ui_click")
		SaveManager.save_game()
		SceneManager.load_scene("res://scenes/menus/hud_customizer.tscn")
	)
	$Layout/Tabs/Controls/VBox/BtnResetProgress.pressed.connect(func():
		AudioManager.play_ui("ui_click")
		confirm_reset_dialog.popup_centered()
	)
	confirm_reset_dialog.confirmed.connect(func():
		SaveManager.reset_all_progress(true)
		AudioManager.play_ui("ui_click")
	)
	$Layout/Header/BtnSaveBack.pressed.connect(func():
		AudioManager.play_ui("ui_click")
		SaveManager.save_game()
		SceneManager.load_scene("res://scenes/menus/main_menu.tscn")
	)
