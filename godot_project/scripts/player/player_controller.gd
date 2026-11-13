class_name PlayerController
extends CharacterBody3D

signal health_changed(current_hp: float, max_hp: float)
signal player_damaged(amount: float, source_pos: Vector3)
signal player_died
signal ads_toggled(is_ads: bool)
signal movement_state_changed(state_name: String)

@export_group("Movement")
@export var walk_speed: float = 5.4
@export var sprint_speed: float = 8.2
@export var crouch_speed: float = 2.9
@export var jump_velocity: float = 5.4
@export var gravity: float = 14.5
@export var ground_accel: float = 12.0
@export var air_accel: float = 4.2
@export var standing_height: float = 1.8
@export var crouch_height: float = 1.1

@export_group("Camera")
@export var base_fov: float = 75.0
@export var sprint_fov: float = 83.0
@export var bob_frequency: float = 2.1
@export var bob_amplitude: float = 0.045
@export var camera_smooth_speed: float = 18.0

@export_group("Vitality")
@export var max_health: float = 100.0

var health: float = 100.0
var is_dead: bool = false
var is_crouching: bool = false
var is_sprinting: bool = false
var is_ads: bool = false

# Touch inputs injected from TouchControls
var touch_move_vec: Vector2 = Vector2.ZERO
var touch_look_delta: Vector2 = Vector2.ZERO
var touch_sprint: bool = false
var touch_ads: bool = false
var touch_firing: bool = false

var _yaw: float = 0.0
var _pitch: float = 0.0
var _target_yaw: float = 0.0
var _target_pitch: float = 0.0
var _recoil_offset: Vector2 = Vector2.ZERO
var _bob_time: float = 0.0
var _landing_dip: float = 0.0
var _was_on_floor: bool = true
var _footstep_timer: float = 0.0
var _shake_intensity: float = 0.0
var _current_interactable: Node = null
var _head_base_y: float = 1.56

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var weapon_rig: WeaponRig = $Head/Camera3D/WeaponRig
@onready var ceiling_check: RayCast3D = $CeilingCheck
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var shoot_ray: RayCast3D = $Head/Camera3D/ShootRay
@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer

func _ready() -> void:
	add_to_group("player")
	GameManager.active_player = self
	health = max_health
	_yaw = rotation.y
	_target_yaw = _yaw
	_pitch = head.rotation.x
	_target_pitch = _pitch
	if SettingsManager:
		camera.far = SettingsManager.view_distance
		SettingsManager.settings_applied.connect(_on_settings_applied)
	if weapon_rig:
		weapon_rig.setup(self, camera, shoot_ray)
	health_changed.emit(health, max_health)

func _on_settings_applied() -> void:
	if camera and SettingsManager:
		camera.far = SettingsManager.view_distance

func _unhandled_input(event: InputEvent) -> void:
	if is_dead or GameManager.current_state != GameManager.GameState.PLAYING:
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var sens_mult: float = 1.0
		if is_ads and weapon_rig and weapon_rig.current_weapon:
			sens_mult = weapon_rig.current_weapon.ads_sensitivity_mult * SettingsManager.ads_sensitivity_multiplier
		var sx: float = 0.0022 * SettingsManager.look_sensitivity_x * sens_mult
		var sy: float = 0.0022 * SettingsManager.look_sensitivity_y * sens_mult
		var y_sign: float = -1.0 if SettingsManager.invert_y else 1.0
		_target_yaw -= event.relative.x * sx
		_target_pitch = clampf(_target_pitch - event.relative.y * sy * y_sign, deg_to_rad(-84.0), deg_to_rad(84.0))

	if event.is_action_pressed("pause"):
		GameManager.pause_game()
	elif event.is_action_pressed("reload"):
		request_reload()
	elif event.is_action_pressed("weapon_next"):
		WeaponManager.switch_next_weapon()
	elif event.is_action_pressed("inspect"):
		if weapon_rig:
			weapon_rig.play_inspect()
	elif event.is_action_pressed("interact"):
		trigger_interact()
	elif event.is_action_pressed("crouch"):
		toggle_crouch()

func _physics_process(delta: float) -> void:
	if is_dead or GameManager.current_state != GameManager.GameState.PLAYING:
		return

	# Apply accumulated touch look delta
	if touch_look_delta.length_squared() > 0.0:
		var sens_mult: float = 1.0
		if is_ads and weapon_rig and weapon_rig.current_weapon:
			sens_mult = weapon_rig.current_weapon.ads_sensitivity_mult * SettingsManager.ads_sensitivity_multiplier
		var sx: float = 0.0034 * SettingsManager.look_sensitivity_x * sens_mult
		var sy: float = 0.0034 * SettingsManager.look_sensitivity_y * sens_mult
		var y_sign: float = -1.0 if SettingsManager.invert_y else 1.0
		_target_yaw -= touch_look_delta.x * sx
		_target_pitch = clampf(_target_pitch - touch_look_delta.y * sy * y_sign, deg_to_rad(-84.0), deg_to_rad(84.0))
		touch_look_delta = Vector2.ZERO

	# Smooth camera & recoil recovery
	_recoil_offset = _recoil_offset.lerp(Vector2.ZERO, delta * 9.5)
	_yaw = lerpf(_yaw, _target_yaw + _recoil_offset.y, clampf(delta * camera_smooth_speed, 0.0, 1.0))
	_pitch = lerpf(_pitch, clampf(_target_pitch + _recoil_offset.x, deg_to_rad(-85.0), deg_to_rad(85.0)), clampf(delta * camera_smooth_speed, 0.0, 1.0))
	rotation.y = _yaw
	head.rotation.x = _pitch

	# Crouch height interpolation
	_update_crouch_shape(delta)

	# Gather movement input (keyboard + touch joystick)
	var kb_input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_input := kb_input + touch_move_vec
	if move_input.length() > 1.0:
		move_input = move_input.normalized()

	var wants_ads: bool = Input.is_action_pressed("ads") or touch_ads
	if wants_ads != is_ads:
		is_ads = wants_ads
		ads_toggled.emit(is_ads)

	var wants_sprint: bool = (Input.is_action_pressed("sprint") or touch_sprint) and move_input.y < -0.25 and not is_crouching and not is_ads
	is_sprinting = wants_sprint and is_on_floor()

	# Gravity & Jump
	var on_floor := is_on_floor()
	if not on_floor:
		velocity.y -= gravity * delta
	else:
		if not _was_on_floor and velocity.y < -2.0:
			_landing_dip = clampf(absf(velocity.y) * 0.022, 0.04, 0.18)
			AudioManager.play_sfx_key_2d("land", -3.0)
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			if is_crouching and not ceiling_check.is_colliding():
				is_crouching = false
			AudioManager.play_sfx_key_2d("jump", -4.0)
	_was_on_floor = on_floor

	# Horizontal velocity
	var weapon_speed_mult: float = weapon_rig.current_weapon.move_speed_mult if (weapon_rig and weapon_rig.current_weapon) else 1.0
	var target_speed: float = walk_speed
	if is_crouching:
		target_speed = crouch_speed
	elif is_sprinting:
		target_speed = sprint_speed
	elif is_ads:
		target_speed = walk_speed * 0.72
	target_speed *= weapon_speed_mult

	var wish_dir: Vector3 = (transform.basis * Vector3(move_input.x, 0.0, move_input.y)).normalized()
	var accel: float = ground_accel if on_floor else air_accel
	velocity.x = lerpf(velocity.x, wish_dir.x * target_speed, clampf(accel * delta, 0.0, 1.0))
	velocity.z = lerpf(velocity.z, wish_dir.z * target_speed, clampf(accel * delta, 0.0, 1.0))

	move_and_slide()

	# Head bob, footsteps, FOV, screen shake
	_update_head_bob_and_footsteps(delta, on_floor)
	_update_camera_fov_and_shake(delta)
	_update_interactable_prompt()

	# Weapon fire polling
	var wants_fire: bool = Input.is_action_pressed("fire") or touch_firing
	var just_pressed_fire: bool = Input.is_action_just_pressed("fire")
	if weapon_rig:
		weapon_rig.process_weapon_input(delta, wants_fire, just_pressed_fire, is_ads, is_sprinting, velocity.length())

func _update_crouch_shape(delta: float) -> void:
	var cap := collision_shape.shape as CapsuleShape3D
	if cap == null:
		return
	var target_h: float = crouch_height if is_crouching else standing_height
	cap.height = lerpf(cap.height, target_h, clampf(delta * 12.0, 0.0, 1.0))
	collision_shape.position.y = cap.height * 0.5
	_head_base_y = cap.height - 0.22

func _update_head_bob_and_footsteps(delta: float, on_floor: bool) -> void:
	var horiz_speed: float = Vector2(velocity.x, velocity.z).length()
	_landing_dip = lerpf(_landing_dip, 0.0, clampf(delta * 10.0, 0.0, 1.0))

	if on_floor and horiz_speed > 0.6:
		var bob_mult: float = 1.35 if is_sprinting else (0.6 if is_crouching else 1.0)
		_bob_time += delta * horiz_speed * bob_frequency * bob_mult * 0.45
		var bob_offset := Vector3(
			cos(_bob_time * 0.5) * bob_amplitude * 0.6,
			sin(_bob_time) * bob_amplitude,
			0.0
		)
		head.position = head.position.lerp(Vector3(0.0, _head_base_y - _landing_dip, 0.0) + bob_offset, clampf(delta * 14.0, 0.0, 1.0))

		_footstep_timer -= delta * (1.45 if is_sprinting else (0.72 if is_crouching else 1.0))
		if _footstep_timer <= 0.0:
			_footstep_timer = 0.46
			var key := "footstep_sprint" if is_sprinting else ("crouch" if is_crouching else "footstep_concrete")
			AudioManager.play_sfx_key_2d(key, -6.0 if is_crouching else -2.0, randf_range(0.92, 1.08))
	else:
		head.position = head.position.lerp(Vector3(0.0, _head_base_y - _landing_dip, 0.0), clampf(delta * 12.0, 0.0, 1.0))

func _update_camera_fov_and_shake(delta: float) -> void:
	var target_fov: float = base_fov
	if is_ads and weapon_rig and weapon_rig.current_weapon:
		target_fov = weapon_rig.current_weapon.ads_fov
	elif is_sprinting:
		target_fov = sprint_fov
	camera.fov = lerpf(camera.fov, target_fov, clampf(delta * 11.0, 0.0, 1.0))

	if _shake_intensity > 0.001:
		camera.h_offset = randf_range(-_shake_intensity, _shake_intensity)
		camera.v_offset = randf_range(-_shake_intensity, _shake_intensity)
		_shake_intensity = lerpf(_shake_intensity, 0.0, clampf(delta * 12.0, 0.0, 1.0))
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0

func _update_interactable_prompt() -> void:
	if interact_ray and interact_ray.is_colliding():
		var collider := interact_ray.get_collider()
		if collider and collider.has_method("get_interact_prompt"):
			_current_interactable = collider
			UIManager.set_interaction_prompt(collider.get_interact_prompt())
			return
	if _current_interactable != null:
		_current_interactable = null
		UIManager.set_interaction_prompt("")

func apply_recoil(pitch_deg: float, yaw_deg: float) -> void:
	_recoil_offset.x += deg_to_rad(pitch_deg)
	_recoil_offset.y += deg_to_rad(randf_range(-yaw_deg, yaw_deg))
	add_camera_shake(0.012)

func add_camera_shake(amount: float) -> void:
	_shake_intensity = minf(0.08, _shake_intensity + amount)

func toggle_crouch() -> void:
	if is_crouching and ceiling_check.is_colliding():
		return
	is_crouching = not is_crouching
	AudioManager.play_sfx_key_2d("crouch", -4.0)

func request_jump() -> void:
	if is_on_floor() and not is_dead:
		velocity.y = jump_velocity
		if is_crouching and not ceiling_check.is_colliding():
			is_crouching = false
		AudioManager.play_sfx_key_2d("jump", -4.0)

func request_reload() -> void:
	if weapon_rig:
		weapon_rig.start_reload()

func trigger_interact() -> void:
	if _current_interactable and _current_interactable.has_method("interact"):
		_current_interactable.interact(self)

func take_damage(amount: float, source_pos: Vector3 = Vector3.ZERO) -> void:
	if is_dead or GameManager.current_state != GameManager.GameState.PLAYING:
		return
	if GameManager.current_mode == GameManager.GameMode.FREE_PRACTICE:
		return
	var scaled_dmg: float = amount * GameManager.get_difficulty_damage_multiplier()
	health = maxf(0.0, health - scaled_dmg)
	health_changed.emit(health, max_health)
	player_damaged.emit(scaled_dmg, source_pos)
	UIManager.trigger_damage_indicator(source_pos, scaled_dmg)
	AudioManager.play_sfx_key_2d("player_hurt", 0.0, randf_range(0.95, 1.05))
	add_camera_shake(0.032)

	if health <= 0.0:
		_handle_death()

func heal(amount: float) -> void:
	if is_dead:
		return
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)
	AudioManager.play_sfx_key_2d("pickup")

func _handle_death() -> void:
	is_dead = true
	player_died.emit()
	if GameManager.current_mode == GameManager.GameMode.CAMPAIGN and GameManager.has_checkpoint:
		UIManager.show_toast("Respawning at last checkpoint...")
		await get_tree().create_timer(1.5).timeout
		respawn_at_checkpoint()
	else:
		GameManager.trigger_game_over("Operative incapacitated")

func respawn_at_checkpoint() -> void:
	if not GameManager.has_checkpoint:
		return
	global_transform = GameManager.last_checkpoint_transform
	velocity = Vector3.ZERO
	health = max_health
	is_dead = false
	health_changed.emit(health, max_health)
	WeaponManager.refill_all_ammo(0.6)
