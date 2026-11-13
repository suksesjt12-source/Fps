extends Control

var _dragging_btn: Button = null
var _drag_offset: Vector2 = Vector2.ZERO

@onready var btn_scale_slider: HSlider = $TopPanel/HBox/ScaleSlider
@onready var opacity_slider: HSlider = $TopPanel/HBox/OpacitySlider
@onready var joy_slider: HSlider = $TopPanel/HBox/JoySlider
@onready var preview_canvas: Control = $PreviewCanvas

func _ready() -> void:
	btn_scale_slider.value = SettingsManager.hud_button_scale
	opacity_slider.value = SettingsManager.hud_button_opacity
	joy_slider.value = SettingsManager.hud_joystick_size

	btn_scale_slider.value_changed.connect(func(v): SettingsManager.hud_button_scale = v; _refresh_preview())
	opacity_slider.value_changed.connect(func(v): SettingsManager.hud_button_opacity = v; _refresh_preview())
	joy_slider.value_changed.connect(func(v): SettingsManager.hud_joystick_size = v; _refresh_preview())

	$TopPanel/HBox/BtnReset.pressed.connect(func():
		SettingsManager.hud_custom_positions.clear()
		SettingsManager.hud_button_scale = 1.0
		SettingsManager.hud_button_opacity = 0.82
		SettingsManager.hud_joystick_size = 1.0
		SceneManager.load_scene("res://scenes/menus/hud_customizer.tscn")
	)
	$TopPanel/HBox/BtnSave.pressed.connect(func():
		_save_positions()
		SaveManager.save_game()
		SettingsManager.apply_all_settings()
		AudioManager.play_ui("ui_click")
		SceneManager.load_scene("res://scenes/menus/settings_menu.tscn")
	)

	for child in preview_canvas.get_children():
		if child is Button:
			var b := child as Button
			if SettingsManager.hud_custom_positions.has(b.name):
				var p = SettingsManager.hud_custom_positions[b.name]
				if typeof(p) == TYPE_DICTIONARY:
					b.position = Vector2(float(p.get("x", b.position.x)), float(p.get("y", b.position.y)))
			b.gui_input.connect(func(ev): _on_btn_gui_input(b, ev))

	_refresh_preview()

func _on_btn_gui_input(btn: Button, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging_btn = btn
			_drag_offset = event.position
		elif _dragging_btn == btn:
			_dragging_btn = null
	elif event is InputEventMouseMotion and _dragging_btn == btn:
		btn.position += event.relative

func _refresh_preview() -> void:
	preview_canvas.modulate.a = SettingsManager.hud_button_opacity
	for child in preview_canvas.get_children():
		if child is Button:
			(child as Button).scale = Vector2.ONE * SettingsManager.hud_button_scale
	$PreviewCanvas/JoystickPreview.scale = Vector2.ONE * SettingsManager.hud_joystick_size

func _save_positions() -> void:
	for child in preview_canvas.get_children():
		if child is Button:
			var b := child as Button
			SettingsManager.hud_custom_positions[b.name] = {
				"x": b.position.x,
				"y": b.position.y
			}
