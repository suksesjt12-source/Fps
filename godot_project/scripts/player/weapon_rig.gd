class_name WeaponRig
extends Node3D

signal fired(weapon_data: WeaponData)
signal crosshair_spread_changed(spread_amount: float)

const IMPACT_SCENE := preload("res://scenes/effects/bullet_impact.tscn")
const EXPLOSION_SCENE := preload("res://scenes/effects/explosion_effect.tscn")

var current_weapon: WeaponData = null
var _player: PlayerController = null
var _camera: Camera3D = null
var _shoot_ray: RayCast3D = null

var _cooldown: float = 0.0
var _burst_remaining: int = 0
var _burst_timer: float = 0.0
var _reload_timer: float = 0.0
var _was_touch_firing: bool = false
var _sway_offset: Vector3 = Vector3.ZERO
var _recoil_kick: Vector3 = Vector3.ZERO
var _is_inspecting: bool = false

var _hip_pos: Vector3 = Vector3(0.24, -0.22, -0.44)
var _ads_pos: Vector3 = Vector3(0.0, -0.155, -0.34)
var _sprint_pos: Vector3 = Vector3(0.28, -0.28, -0.38)

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var model_root: Node3D = $ModelRoot
@onready var receiver_mesh: MeshInstance3D = $ModelRoot/ProceduralGun/Receiver
@onready var barrel_mesh: MeshInstance3D = $ModelRoot/ProceduralGun/Barrel
@onready var accent_mesh: MeshInstance3D = $ModelRoot/ProceduralGun/AccentStrip
@onready var magazine_mesh: MeshInstance3D = $ModelRoot/ProceduralGun/Magazine
@onready var muzzle_point: Marker3D = $ModelRoot/MuzzlePoint
@onready var muzzle_light: OmniLight3D = $ModelRoot/MuzzlePoint/MuzzleLight
@onready var muzzle_particles: CPUParticles3D = $ModelRoot/MuzzlePoint/MuzzleParticles
@onready var custom_model_anchor: Node3D = $ModelRoot/CustomModelAnchor

func _ready() -> void:
	WeaponManager.weapon_equipped.connect(_on_weapon_equipped)
	var active := WeaponManager.get_active_weapon()
	if active:
		_on_weapon_equipped(active, WeaponManager.get_active_mag(), WeaponManager.get_active_reserve())

func setup(player: PlayerController, camera: Camera3D, shoot_ray: RayCast3D) -> void:
	_player = player
	_camera = camera
	_shoot_ray = shoot_ray

func _on_weapon_equipped(weapon_data: WeaponData, _mag: int, _reserve: int) -> void:
	current_weapon = weapon_data
	_cooldown = 0.25
	_burst_remaining = 0
	_reload_timer = 0.0
	_is_inspecting = false
	_rebuild_weapon_visual(weapon_data)
	if anim_player and anim_player.has_animation("equip"):
		anim_player.play("equip")

func _rebuild_weapon_visual(weapon_data: WeaponData) -> void:
	for child in custom_model_anchor.get_children():
		child.queue_free()

	var procedural_gun := $ModelRoot/ProceduralGun as Node3D
	if not weapon_data.custom_glb_path.is_empty() and ResourceLoader.exists(weapon_data.custom_glb_path):
		var glb_scene := load(weapon_data.custom_glb_path) as PackedScene
		if glb_scene:
			procedural_gun.visible = false
			custom_model_anchor.add_child(glb_scene.instantiate())
			return

	procedural_gun.visible = true
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = weapon_data.body_color
	body_mat.metallic = 0.55
	body_mat.roughness = 0.42

	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = weapon_data.accent_color
	accent_mat.emission_enabled = true
	accent_mat.emission = weapon_data.accent_color
	accent_mat.emission_energy_multiplier = 1.6 if weapon_data.is_energy else 0.45

	receiver_mesh.material_override = body_mat
	barrel_mesh.material_override = body_mat
	magazine_mesh.material_override = body_mat
	accent_mesh.material_override = accent_mat

	receiver_mesh.scale = Vector3(1.0, 1.0, weapon_data.receiver_length / 0.44)
	barrel_mesh.scale = Vector3(1.0, 1.0, weapon_data.barrel_length / 0.54)
	barrel_mesh.position.z = -0.22 - (weapon_data.barrel_length * 0.45)
	muzzle_point.position.z = barrel_mesh.position.z - (weapon_data.barrel_length * 0.5)
	muzzle_light.light_color = weapon_data.accent_color

func process_weapon_input(delta: float, wants_fire: bool, just_pressed_fire: bool, is_ads: bool, is_sprinting: bool, move_speed: float) -> void:
	if current_weapon == null:
		return

	# Handle active reload timer
	if WeaponManager.is_reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			WeaponManager.complete_reload()
			if anim_player and anim_player.has_animation("idle"):
				anim_player.play("idle")
		_update_transform(delta, is_ads, is_sprinting, move_speed)
		return

	_cooldown = maxf(0.0, _cooldown - delta)

	var touch_just_pressed: bool = wants_fire and not _was_touch_firing
	_was_touch_firing = wants_fire
	var trigger_pulled: bool = just_pressed_fire or touch_just_pressed

	# Burst continuation
	if _burst_remaining > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_execute_shot(is_ads)
			_burst_remaining -= 1
			_burst_timer = 0.075
	elif _cooldown <= 0.0:
		var should_shoot := false
		match current_weapon.fire_mode:
			WeaponData.FireMode.AUTO:
				should_shoot = wants_fire
			WeaponData.FireMode.SINGLE:
				should_shoot = trigger_pulled
			WeaponData.FireMode.BURST:
				if trigger_pulled:
					should_shoot = true
					_burst_remaining = maxi(0, current_weapon.burst_count - 1)
					_burst_timer = 0.075

		if should_shoot:
			if WeaponManager.can_fire():
				_execute_shot(is_ads)
				_cooldown = 1.0 / maxf(0.1, current_weapon.fire_rate)
			elif trigger_pulled:
				AudioManager.play_sfx_key_2d("empty_mag")
				if anim_player and anim_player.has_animation("empty"):
					anim_player.play("empty")
				if WeaponManager.can_reload():
					start_reload()

	var spread_val: float = current_weapon.spread_ads if is_ads else current_weapon.spread_hip
	spread_val += clampf(move_speed * 0.004, 0.0, 0.04)
	crosshair_spread_changed.emit(spread_val)

	_update_transform(delta, is_ads, is_sprinting, move_speed)

func _update_transform(delta: float, is_ads: bool, is_sprinting: bool, move_speed: float) -> void:
	_recoil_kick = _recoil_kick.lerp(Vector3.ZERO, clampf(delta * 12.0, 0.0, 1.0))

	var target_pos: Vector3 = _hip_pos
	var target_rot: Vector3 = Vector3.ZERO
	if WeaponManager.is_reloading:
		target_pos = _hip_pos + Vector3(-0.04, -0.06, 0.04)
		target_rot = Vector3(0.28, 0.15, 0.32)
	elif is_ads:
		target_pos = _ads_pos
	elif is_sprinting and not _is_inspecting:
		target_pos = _sprint_pos
		target_rot = Vector3(-0.18, 0.48, -0.22)

	var sway_x: float = sin(Time.get_ticks_msec() * 0.004) * 0.004 * (0.2 if is_ads else 1.0)
	var sway_y: float = cos(Time.get_ticks_msec() * 0.008) * 0.003 * (0.2 if is_ads else 1.0)
	_sway_offset = Vector3(sway_x, sway_y, 0.0)

	position = position.lerp(target_pos + _sway_offset + _recoil_kick, clampf(delta * 14.0, 0.0, 1.0))
	rotation = rotation.lerp(target_rot, clampf(delta * 12.0, 0.0, 1.0))

func start_reload() -> void:
	if not WeaponManager.can_reload():
		return
	_burst_remaining = 0
	_is_inspecting = false
	_reload_timer = WeaponManager.begin_reload()
	if anim_player and anim_player.has_animation("reload"):
		anim_player.speed_scale = 1.6 / maxf(0.5, _reload_timer)
		anim_player.play("reload")

func play_inspect() -> void:
	if WeaponManager.is_reloading or _is_inspecting:
		return
	_is_inspecting = true
	if anim_player and anim_player.has_animation("inspect"):
		anim_player.speed_scale = 1.0
		anim_player.play("inspect")
		await anim_player.animation_finished
	_is_inspecting = false

func _execute_shot(is_ads: bool) -> void:
	if not WeaponManager.consume_round():
		return
	_is_inspecting = false
	AudioManager.play_sfx_2d(current_weapon.fire_sfx_path, -1.0, randf_range(0.95, 1.05))
	_play_muzzle_flash()

	if anim_player and anim_player.has_animation("fire"):
		anim_player.speed_scale = 1.0
		anim_player.stop()
		anim_player.play("fire")

	_recoil_kick += Vector3(0.0, 0.008, 0.055)
	if _player:
		var recoil_scale: float = 0.65 if is_ads else 1.0
		_player.apply_recoil(current_weapon.recoil_pitch * recoil_scale, current_weapon.recoil_yaw * recoil_scale)

	var any_hit := false
	var any_kill := false
	var any_headshot := false
	var spread: float = current_weapon.spread_ads if is_ads else current_weapon.spread_hip

	for _p in range(current_weapon.pellets):
		var hit_info := _cast_pellet(spread)
		if not hit_info.is_empty():
			var hit_pos: Vector3 = hit_info["position"]
			var hit_normal: Vector3 = hit_info["normal"]
			var collider: Object = hit_info["collider"]
			_spawn_impact(hit_pos, hit_normal, current_weapon.is_explosive)

			if current_weapon.is_explosive and current_weapon.splash_radius > 0.0:
				_apply_splash_damage(hit_pos, current_weapon.splash_radius, current_weapon.damage)
				any_hit = true
			elif collider and collider.has_method("apply_bullet_damage"):
				var is_head: bool = collider.has_method("is_head_hitbox") and collider.is_head_hitbox()
				var dmg: float = current_weapon.damage * (1.85 if is_head else 1.0)
				var killed: bool = collider.apply_bullet_damage(dmg, hit_pos, _player.global_position if _player else Vector3.ZERO)
				any_hit = true
				if is_head:
					any_headshot = true
				if killed:
					any_kill = true

	GameManager.register_shot(any_hit)
	if any_hit:
		UIManager.trigger_hit_marker(any_kill, any_headshot)

func _cast_pellet(spread: float) -> Dictionary:
	if _camera == null:
		return {}
	var space_state := get_world_3d().direct_space_state
	var origin: Vector3 = _camera.global_position
	var forward: Vector3 = -_camera.global_transform.basis.z
	var right: Vector3 = _camera.global_transform.basis.x
	var up: Vector3 = _camera.global_transform.basis.y

	var spread_dir: Vector3 = (
		forward
		+ right * randf_range(-spread, spread)
		+ up * randf_range(-spread, spread)
	).normalized()

	var query := PhysicsRayQueryParameters3D.create(origin, origin + spread_dir * current_weapon.effective_range)
	query.collision_mask = 1 | 4 | 8 # World + Enemy + Projectile/Hitbox
	if _player:
		query.exclude = [_player.get_rid()]
	return space_state.intersect_ray(query)

func _apply_splash_damage(center: Vector3, radius: float, max_dmg: float) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D:
			var dist: float = (enemy as Node3D).global_position.distance_to(center)
			if dist <= radius and enemy.has_method("take_damage"):
				var falloff: float = clampf(1.0 - (dist / radius) * 0.65, 0.25, 1.0)
				enemy.take_damage(max_dmg * falloff, center, false)
	AudioManager.play_sfx_3d_key("explosion", center)

func _play_muzzle_flash() -> void:
	if muzzle_particles:
		muzzle_particles.restart()
		muzzle_particles.emitting = true
	if muzzle_light:
		muzzle_light.light_energy = 3.2
		var tw := create_tween()
		tw.tween_property(muzzle_light, "light_energy", 0.0, 0.07)

func _spawn_impact(pos: Vector3, normal: Vector3, explosive: bool) -> void:
	var scene: PackedScene = EXPLOSION_SCENE if explosive else IMPACT_SCENE
	if scene == null:
		return
	var fx := scene.instantiate() as Node3D
	get_tree().current_scene.add_child(fx)
	fx.global_position = pos + normal * 0.03
	if not explosive:
		AudioManager.play_sfx_3d_key("impact_metal", pos, -6.0)
