class_name TouchControls
extends Control

@export var player_path: NodePath

var _player: PlayerController = null
var _joystick_touch_id: int = -1
var _look_touch_id: int = -1
var _joystick_origin: Vector2 = Vector2.ZERO
var _joystick_radius: float = 82.0
var _ads_locked: bool = false
var _sprint_locked: bool = false

@onready var joystick_area: Control = $JoystickArea
@onready var joystick_base: Control = $JoystickArea/JoystickBase
@onready var joystick_knob: Control = $JoystickArea/JoystickBase/JoystickKnob
@onready var look_area: Control = $LookArea

@onready var btn_fire: Button = $ActionButtons/BtnFire
@onready var btn_ads: Button = $ActionButtons/BtnADS
@onready var btn_reload: Button = $ActionButtons/BtnReload
@onready var btn_jump: Button = $ActionButtons/BtnJump
@onready var btn_crouch: Button = $ActionButtons/BtnCrouch
@onready var btn_sprint: Button = $ActionButtons/BtnSprint
@onready var btn_interact: Button = $ActionButtons/BtnInteract
@onready var btn_switch: Button = $ActionButtons/BtnSwitch
@onready var btn_inspect: Button = $ActionButtons/BtnInspect
@onready var btn_pause: Button = $TopRight/BtnPause

func _ready() -> void:
	_resolve_player()
	_apply_layout_settings()
	SettingsManager.settings_applied.connect(_apply_layout_settings)
	UIManager.interaction_prompt_changed.connect(_on_interaction_prompt_changed)

	btn_fire.button_down.connect(func(): _set_firing(true))
	btn_fire.button_up.connect(func(): _set_firing(false))
	btn_ads.pressed.connect(_on_ads_pressed)
	btn_reload.pressed.connect(func():
		if _player: _player.request_reload()
	)
	btn_jump.pressed.connect(func():
		if _player: _player.request_jump()
	)
	btn_crouch.pressed.connect(func():
		if _player: _player.toggle_crouch()
	)
	btn_sprint.pressed.connect(_on_sprint_pressed)
	btn_interact.pressed.connect(func():
		if _player: _player.trigger_interact()
	)
	btn_switch.pressed.connect(func(): WeaponManager.switch_next_weapon())
	btn_inspect.pressed.connect(func():
		if _player and _player.weapon_rig: _player.weapon_rig.play_inspect()
	)
	btn_pause.pressed.connect(func(): GameManager.pause_game())
	btn_interact.visible = false

func _resolve_player() -> void:
	if not player_path.is_empty():
		_player = get_node_or_null(player_path) as PlayerController
	if _player == null:
		_player = GameManager.active_player as PlayerController

func _apply_layout_settings() -> void:
	var opacity: float = SettingsManager.hud_button_opacity
	modulate.a = opacity
	var joy_scale: float = SettingsManager.hud_joystick_size
	if joystick_base:
		joystick_base.scale = Vector2(joy_scale, joy_scale)
		_joystick_radius = 82.0 * joy_scale

	var btn_scale: float = SettingsManager.hud_button_scale
	var button_map := {
		"BtnFire": btn_fire,
		"BtnADS": btn_ads,
		"BtnReload": btn_reload,
		"BtnJump": btn_jump,
		"BtnCrouch": btn_crouch,
		"BtnSprint": btn_sprint,
		"BtnSwitch": btn_switch,
		"BtnInspect": btn_inspect
	}
	for key in button_map.keys():
		var b: Button = button_map[key]
		if b:
			b.scale = Vector2(btn_scale, btn_scale)
			if SettingsManager.hud_custom_positions.has(key):
				var p = SettingsManager.hud_custom_positions[key]
				if typeof(p) == TYPE_DICTIONARY:
					b.position = Vector2(float(p.get("x", b.position.x)), float(p.get("y", b.position.y)))

func _input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	if _player == null:
		_resolve_player()
		if _player == null:
			return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _joystick_touch_id == -1 and joystick_area.get_global_rect().has_point(touch.position):
				_joystick_touch_id = touch.index
				_joystick_origin = joystick_base.global_position + (joystick_base.size * joystick_base.scale * 0.5)
				_update_joystick(touch.position)
			elif _look_touch_id == -1 and look_area.get_global_rect().has_point(touch.position):
				if not _is_point_on_action_button(touch.position):
					_look_touch_id = touch.index
		else:
			if touch.index == _joystick_touch_id:
				_joystick_touch_id = -1
				_reset_joystick()
			elif touch.index == _look_touch_id:
				_look_touch_id = -1

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _joystick_touch_id:
			_update_joystick(drag.position)
		elif drag.index == _look_touch_id:
			_player.touch_look_delta += drag.relative

func _is_point_on_action_button(pos: Vector2) -> bool:
	for child in $ActionButtons.get_children():
		if child is Control and (child as Control).visible:
			if (child as Control).get_global_rect().has_point(pos):
				return true
	return btn_pause.get_global_rect().has_point(pos)

func _update_joystick(touch_pos: Vector2) -> void:
	var delta: Vector2 = touch_pos - _joystick_origin
	var clamped: Vector2 = delta.limit_length(_joystick_radius)
	var center := joystick_base.size * 0.5
	joystick_knob.position = center + (clamped / maxf(0.1, joystick_base.scale.x)) - (joystick_knob.size * 0.5)
	var norm: Vector2 = clamped / maxf(1.0, _joystick_radius)
	if norm.length() < 0.14:
		norm = Vector2.ZERO
	if _player:
		_player.touch_move_vec = norm
		if norm.y < -0.88:
			_player.touch_sprint = true
		elif not _sprint_locked:
			_player.touch_sprint = false

func _reset_joystick() -> void:
	joystick_knob.position = (joystick_base.size * 0.5) - (joystick_knob.size * 0.5)
	if _player:
		_player.touch_move_vec = Vector2.ZERO
		if not _sprint_locked:
			_player.touch_sprint = false

func _set_firing(active: bool) -> void:
	if _player == null:
		_resolve_player()
	if _player:
		_player.touch_firing = active

func _on_ads_pressed() -> void:
	_ads_locked = not _ads_locked
	if _player:
		_player.touch_ads = _ads_locked
	btn_ads.text = "ADS [ON]" if _ads_locked else "ADS"

func _on_sprint_pressed() -> void:
	_sprint_locked = not _sprint_locked
	if _player:
		_player.touch_sprint = _sprint_locked
	btn_sprint.text = "SPR [ON]" if _sprint_locked else "SPRINT"

func _on_interaction_prompt_changed(prompt_text: String) -> void:
	btn_interact.visible = not prompt_text.is_empty()
	btn_interact.text = "USE" if prompt_text.is_empty() else "USE"
