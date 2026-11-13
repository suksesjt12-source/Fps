class_name EnemyAI
extends CharacterBody3D

signal enemy_defeated(enemy: EnemyAI)

enum AIState {
	IDLE,
	PATROL,
	INVESTIGATE,
	SEARCH,
	ALERT,
	CHASE,
	ATTACK,
	RETREAT,
	STUNNED,
	DEFEATED
}

@export var enemy_data: EnemyData = preload("res://resources/enemies/rifleman.tres")
@export var patrol_points: Array[NodePath] = []
@export var is_objective_target: bool = false
@export var objective_id_on_defeat: String = ""

var current_state: AIState = AIState.PATROL
var health: float = 100.0
var _player: Node3D = null
var _patrol_index: int = 0
var _last_known_player_pos: Vector3 = Vector3.ZERO
var _state_timer: float = 0.0
var _fire_cooldown: float = 0.0
var _burst_left: int = 0
var _gravity: float = 14.5
var _playback: AnimationNodeStateMachinePlayback = null

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var los_ray: RayCast3D = $LOSRay
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var audio_3d: AudioStreamPlayer3D = $Audio3D
@onready var rig_root: Node3D = $RigRoot
@onready var muzzle_flash_mesh: MeshInstance3D = $RigRoot/WeaponMesh/MuzzleFlash

func _ready() -> void:
	add_to_group("enemies")
	if enemy_data == null:
		enemy_data = load("res://resources/enemies/rifleman.tres") as EnemyData
	health = enemy_data.max_health
	scale = Vector3.ONE * enemy_data.body_scale
	_apply_archetype_visuals()
	_setup_animation_tree()

	nav_agent.path_desired_distance = 0.8
	nav_agent.target_desired_distance = 1.2
	_state_timer = randf_range(0.4, 1.4)

	if patrol_points.is_empty():
		current_state = AIState.IDLE
	else:
		current_state = AIState.PATROL
		_move_to_next_patrol_point()

func _apply_archetype_visuals() -> void:
	var custom_anchor := get_node_or_null("RigRoot/CustomGLBAnchor")
	var proc_body := get_node_or_null("RigRoot/ProceduralBody")
	if not enemy_data.custom_glb_path.is_empty() and ResourceLoader.exists(enemy_data.custom_glb_path):
		var glb := load(enemy_data.custom_glb_path) as PackedScene
		if glb and custom_anchor and proc_body:
			proc_body.visible = false
			custom_anchor.add_child(glb.instantiate())
			return

	var armor_mat := StandardMaterial3D.new()
	armor_mat.albedo_color = enemy_data.armor_color
	armor_mat.roughness = 0.55

	var visor_mat := StandardMaterial3D.new()
	visor_mat.albedo_color = enemy_data.visor_color
	visor_mat.emission_enabled = true
	visor_mat.emission = enemy_data.visor_color
	visor_mat.emission_energy_multiplier = 1.5

	for node_name in ["Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"]:
		var mesh := get_node_or_null("RigRoot/ProceduralBody/%s" % node_name) as MeshInstance3D
		if mesh:
			mesh.material_override = armor_mat
	var visor := get_node_or_null("RigRoot/ProceduralBody/Head/Visor") as MeshInstance3D
	if visor:
		visor.material_override = visor_mat

func _setup_animation_tree() -> void:
	if anim_tree:
		anim_tree.active = true
		_playback = anim_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback

func _physics_process(delta: float) -> void:
	if current_state == AIState.DEFEATED:
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta

	if _player == null:
		_player = GameManager.active_player as Node3D
		if _player == null:
			var players := get_tree().get_nodes_in_group("player")
			if not players.is_empty():
				_player = players[0] as Node3D

	_state_timer = maxf(0.0, _state_timer - delta)
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)

	var can_see_player := _check_line_of_sight()
	if can_see_player and _player:
		_last_known_player_pos = _player.global_position

	match current_state:
		AIState.IDLE:
			_process_idle(can_see_player)
		AIState.PATROL:
			_process_patrol(delta, can_see_player)
		AIState.INVESTIGATE:
			_process_investigate(delta, can_see_player)
		AIState.SEARCH:
			_process_search(delta, can_see_player)
		AIState.ALERT:
			_process_alert(can_see_player)
		AIState.CHASE:
			_process_chase(delta, can_see_player)
		AIState.ATTACK:
			_process_attack(delta, can_see_player)
		AIState.RETREAT:
			_process_retreat(delta, can_see_player)
		AIState.STUNNED:
			velocity.x = lerpf(velocity.x, 0.0, delta * 8.0)
			velocity.z = lerpf(velocity.z, 0.0, delta * 8.0)
			if _state_timer <= 0.0:
				_transition_to(AIState.CHASE if can_see_player else AIState.SEARCH)

	move_and_slide()
	_update_animation_state()

func _process_idle(can_see: bool) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if can_see:
		_on_player_spotted()
	elif _state_timer <= 0.0 and not patrol_points.is_empty():
		_transition_to(AIState.PATROL)

func _process_patrol(delta: float, can_see: bool) -> void:
	if can_see:
		_on_player_spotted()
		return
	if nav_agent.is_navigation_finished():
		_move_to_next_patrol_point()
		_transition_to(AIState.IDLE)
		_state_timer = randf_range(1.0, 2.2)
		return
	_steer_towards_next_nav_point(enemy_data.move_speed, delta)

func _process_investigate(delta: float, can_see: bool) -> void:
	if can_see:
		_on_player_spotted()
		return
	if nav_agent.is_navigation_finished() or _state_timer <= 0.0:
		_transition_to(AIState.SEARCH)
		_state_timer = 4.0
		return
	_steer_towards_next_nav_point(enemy_data.move_speed, delta)

func _process_search(delta: float, can_see: bool) -> void:
	if can_see:
		_on_player_spotted()
		return
	rotate_y(delta * 1.4)
	if _state_timer <= 0.0:
		_transition_to(AIState.PATROL if not patrol_points.is_empty() else AIState.IDLE)

func _process_alert(can_see: bool) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if _player:
		_face_position(_player.global_position, 0.12)
	if _state_timer <= 0.0:
		_transition_to(AIState.ATTACK if can_see else AIState.CHASE)

func _process_chase(delta: float, can_see: bool) -> void:
	if can_see and _player:
		var dist: float = global_position.distance_to(_player.global_position)
		if dist <= enemy_data.attack_range:
			_transition_to(AIState.ATTACK)
			return
		nav_agent.target_position = _player.global_position
	else:
		nav_agent.target_position = _last_known_player_pos
		if nav_agent.is_navigation_finished():
			_transition_to(AIState.SEARCH)
			_state_timer = 4.5
			return
	_steer_towards_next_nav_point(enemy_data.chase_speed, delta)

func _process_attack(delta: float, can_see: bool) -> void:
	velocity.x = lerpf(velocity.x, 0.0, delta * 8.0)
	velocity.z = lerpf(velocity.z, 0.0, delta * 8.0)
	if not can_see or _player == null:
		_transition_to(AIState.CHASE)
		return
	if health < enemy_data.max_health * 0.32 and _find_nearest_cover_point() != Vector3.INF:
		_transition_to(AIState.RETREAT)
		return

	var dist: float = global_position.distance_to(_player.global_position)
	if dist > enemy_data.attack_range * 1.25:
		_transition_to(AIState.CHASE)
		return

	_face_position(_player.global_position, delta * 8.0)
	if _fire_cooldown <= 0.0:
		_fire_at_player()

func _process_retreat(delta: float, can_see: bool) -> void:
	if nav_agent.is_navigation_finished() or _state_timer <= 0.0:
		_transition_to(AIState.ATTACK if can_see else AIState.SEARCH)
		_state_timer = 3.5
		return
	_steer_towards_next_nav_point(enemy_data.chase_speed, delta)

func _transition_to(next_state: AIState) -> void:
	if current_state == AIState.DEFEATED:
		return
	current_state = next_state
	if next_state == AIState.RETREAT:
		var cover := _find_nearest_cover_point()
		if cover != Vector3.INF:
			nav_agent.target_position = cover
			_state_timer = 3.5
	elif next_state == AIState.ALERT:
		_state_timer = 0.35 * GameManager.get_difficulty_ai_reaction_multiplier()

func _on_player_spotted() -> void:
	if current_state == AIState.ALERT or current_state == AIState.ATTACK or current_state == AIState.CHASE:
		return
	_transition_to(AIState.ALERT)
	AudioManager.play_sfx_3d_key("enemy_alert", global_position, -2.0)
	_alert_nearby_squad()

func _alert_nearby_squad() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node != self and node is EnemyAI:
			var ally := node as EnemyAI
			if ally.current_state in [AIState.IDLE, AIState.PATROL, AIState.SEARCH]:
				if ally.global_position.distance_to(global_position) <= 22.0:
					ally.receive_squad_alert(_last_known_player_pos)

func receive_squad_alert(target_pos: Vector3) -> void:
	if current_state == AIState.DEFEATED:
		return
	_last_known_player_pos = target_pos
	nav_agent.target_position = target_pos
	_state_timer = 5.0
	_transition_to(AIState.INVESTIGATE)

func hear_noise(noise_pos: Vector3, radius: float) -> void:
	if current_state in [AIState.DEFEATED, AIState.ATTACK, AIState.CHASE]:
		return
	if global_position.distance_to(noise_pos) <= minf(radius, enemy_data.hearing_range):
		_last_known_player_pos = noise_pos
		nav_agent.target_position = noise_pos
		_state_timer = 5.0
		_transition_to(AIState.INVESTIGATE)

func _check_line_of_sight() -> bool:
	if _player == null or los_ray == null:
		return false
	var target_pos: Vector3 = _player.global_position + Vector3(0.0, 1.35, 0.0)
	var dist: float = global_position.distance_to(target_pos)
	if dist > enemy_data.detection_range:
		return false
	var to_player: Vector3 = (target_pos - los_ray.global_position)
	los_ray.target_position = los_ray.to_local(target_pos)
	los_ray.force_raycast_update()
	if los_ray.is_colliding():
		var col := los_ray.get_collider()
		return col == _player or (col is Node and (col as Node).is_in_group("player"))
	return false

func _steer_towards_next_nav_point(speed: float, delta: float) -> void:
	if nav_agent.is_navigation_finished():
		return
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var dir: Vector3 = (next_pos - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		dir = dir.normalized()
		velocity.x = lerpf(velocity.x, dir.x * speed, clampf(delta * 8.0, 0.0, 1.0))
		velocity.z = lerpf(velocity.z, dir.z * speed, clampf(delta * 8.0, 0.0, 1.0))
		_face_position(next_pos, delta * 9.0)

func _face_position(target_pos: Vector3, weight: float) -> void:
	var flat := Vector3(target_pos.x, global_position.y, target_pos.z)
	if flat.distance_squared_to(global_position) > 0.01:
		var desired_yaw: float = atan2(global_position.x - flat.x, global_position.z - flat.z)
		rotation.y = lerp_angle(rotation.y, desired_yaw, clampf(weight, 0.0, 1.0))

func _move_to_next_patrol_point() -> void:
	if patrol_points.is_empty():
		return
	var node := get_node_or_null(patrol_points[_patrol_index]) as Node3D
	_patrol_index = (_patrol_index + 1) % patrol_points.size()
	if node:
		nav_agent.target_position = node.global_position

func _find_nearest_cover_point() -> Vector3:
	var points := get_tree().get_nodes_in_group("cover_points")
	var best_pos := Vector3.INF
	var best_score := 99999.0
	for p in points:
		if p is Node3D:
			var d: float = global_position.distance_to((p as Node3D).global_position)
			if d < 22.0 and d < best_score:
				best_score = d
				best_pos = (p as Node3D).global_position
	return best_pos

func _fire_at_player() -> void:
	_fire_cooldown = enemy_data.fire_interval * GameManager.get_difficulty_ai_reaction_multiplier()
	if _playback:
		_playback.travel("attack")
	AudioManager.play_sfx_3d("res://assets/audio/sfx/fire_assault.wav", global_position, -5.0, randf_range(0.9, 1.05))
	if muzzle_flash_mesh:
		muzzle_flash_mesh.visible = true
		get_tree().create_timer(0.06).timeout.connect(func():
			if is_instance_valid(muzzle_flash_mesh):
				muzzle_flash_mesh.visible = false
		)

	if _player and _player.has_method("take_damage"):
		var hit_chance: float = clampf(1.0 - enemy_data.accuracy_spread * 3.5, 0.35, 0.88)
		if randf() <= hit_chance and _check_line_of_sight():
			_player.take_damage(enemy_data.attack_damage, global_position)

func take_damage(amount: float, attacker_pos: Vector3, is_headshot: bool = false) -> bool:
	if current_state == AIState.DEFEATED:
		return false
	health -= amount
	_last_known_player_pos = attacker_pos
	if health <= 0.0:
		_die(is_headshot)
		return true

	if amount >= 45.0:
		_transition_to(AIState.STUNNED)
		_state_timer = 0.55
		if _playback:
			_playback.travel("hit")
	elif current_state in [AIState.IDLE, AIState.PATROL, AIState.SEARCH, AIState.INVESTIGATE]:
		nav_agent.target_position = attacker_pos
		_transition_to(AIState.CHASE)
		_alert_nearby_squad()
	return false

func apply_bullet_damage(damage: float, _hit_pos: Vector3, attacker_pos: Vector3) -> bool:
	return take_damage(damage, attacker_pos, false)

func _die(is_headshot: bool) -> void:
	current_state = AIState.DEFEATED
	velocity = Vector3.ZERO
	set_physics_process(false)
	if _playback:
		_playback.travel("defeated")
	AudioManager.play_sfx_3d_key("enemy_defeated", global_position, -2.0)
	GameManager.register_enemy_kill(enemy_data.score_value, is_headshot)
	enemy_defeated.emit(self)

	if is_objective_target and not objective_id_on_defeat.is_empty():
		MissionManager.complete_objective(objective_id_on_defeat)

	for child in get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = true

	await get_tree().create_timer(2.4).timeout
	queue_free()

func _update_animation_state() -> void:
	if _playback == null or anim_tree == null:
		return
	var horiz_speed: float = Vector2(velocity.x, velocity.z).length()
	var blend_val: float = clampf(horiz_speed / maxf(1.0, enemy_data.chase_speed), 0.0, 1.0)
	anim_tree.set("parameters/locomotion/blend_position", blend_val)
	if current_state in [AIState.IDLE, AIState.PATROL, AIState.INVESTIGATE, AIState.SEARCH, AIState.CHASE, AIState.RETREAT]:
		_playback.travel("locomotion")
	elif current_state == AIState.ALERT:
		_playback.travel("alert")
