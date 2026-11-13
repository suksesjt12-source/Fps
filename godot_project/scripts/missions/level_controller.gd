class_name LevelController
extends Node3D

@export var environment_theme: String = "city"
@export var spawn_point_path: NodePath = NodePath("PlayerSpawn")

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy_soldier.tscn")

var _wave_active: bool = false
var _wave_spawn_points: Array[Node3D] = []
var _wave_enemies_alive: int = 0
var _player_ref: PlayerController = null

func _ready() -> void:
	_ensure_navigation_baked()
	_spawn_player_and_hud()
	AudioManager.play_ambience(environment_theme)
	_apply_environment_quality()
	SettingsManager.settings_applied.connect(_apply_environment_quality)

	match GameManager.current_mode:
		GameManager.GameMode.CAMPAIGN:
			WeaponManager.reset_loadout_for_mode(GameManager.GameMode.CAMPAIGN)
		GameManager.GameMode.SURVIVAL:
			WeaponManager.reset_loadout_for_mode(GameManager.GameMode.SURVIVAL)
			_clear_campaign_enemies()
			_setup_survival_waves()
		GameManager.GameMode.FREE_PRACTICE:
			WeaponManager.reset_loadout_for_mode(GameManager.GameMode.FREE_PRACTICE)
			_clear_campaign_enemies()
		GameManager.GameMode.TRAINING:
			WeaponManager.reset_loadout_for_mode(GameManager.GameMode.TRAINING)

	GameManager.on_gameplay_scene_ready()

func _spawn_player_and_hud() -> void:
	var spawn := get_node_or_null(spawn_point_path) as Node3D
	var existing_player := get_tree().get_first_node_in_group("player") as PlayerController
	if existing_player:
		_player_ref = existing_player
	else:
		_player_ref = PLAYER_SCENE.instantiate() as PlayerController
		add_child(_player_ref)
	if spawn:
		_player_ref.global_transform = spawn.global_transform
	GameManager.set_checkpoint(_player_ref.global_transform)

	if _player_ref.weapon_rig:
		_player_ref.weapon_rig.fired.connect(_on_player_weapon_fired)

	var hud := HUD_SCENE.instantiate()
	add_child(hud)

func _on_player_weapon_fired(_w: WeaponData) -> void:
	if _player_ref == null:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is EnemyAI:
			(enemy as EnemyAI).hear_noise(_player_ref.global_position, 24.0)

func _clear_campaign_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()

func _setup_survival_waves() -> void:
	_wave_spawn_points.clear()
	for node in get_tree().get_nodes_in_group("enemy_spawns"):
		if node is Node3D:
			_wave_spawn_points.append(node as Node3D)
	if _wave_spawn_points.is_empty():
		var fallback := Marker3D.new()
		fallback.position = Vector3(0.0, 0.5, -18.0)
		add_child(fallback)
		_wave_spawn_points.append(fallback)
	_start_next_survival_wave()

func _start_next_survival_wave() -> void:
	_wave_active = true
	var wave: int = GameManager.survival_wave
	var enemy_count: int = mini(14, 3 + wave * 2)
	_wave_enemies_alive = enemy_count
	GameManager.survival_enemies_remaining = enemy_count
	GameManager.wave_changed.emit(wave, enemy_count)
	UIManager.show_toast("Survival Wave %d Inbound (%d Hostiles)" % [wave, enemy_count])

	for i in range(enemy_count):
		var sp: Node3D = _wave_spawn_points[i % _wave_spawn_points.size()]
		var enemy := ENEMY_SCENE.instantiate() as EnemyAI
		var archetype_path := "res://resources/enemies/rifleman.tres"
		if wave >= 3 and i % 4 == 0:
			archetype_path = "res://resources/enemies/enforcer.tres"
		if wave >= 5 and i == 0:
			archetype_path = "res://resources/enemies/commander.tres"
		enemy.enemy_data = load(archetype_path) as EnemyData
		add_child(enemy)
		enemy.global_position = sp.global_position + Vector3(randf_range(-1.5, 1.5), 0.0, randf_range(-1.5, 1.5))
		enemy.enemy_defeated.connect(_on_survival_enemy_defeated)
		if _player_ref:
			enemy.receive_squad_alert(_player_ref.global_position)

func _on_survival_enemy_defeated(_enemy: EnemyAI) -> void:
	_wave_enemies_alive = maxi(0, _wave_enemies_alive - 1)
	GameManager.survival_enemies_remaining = _wave_enemies_alive
	GameManager.wave_changed.emit(GameManager.survival_wave, _wave_enemies_alive)
	if _wave_enemies_alive <= 0 and _wave_active:
		_wave_active = false
		GameManager.survival_wave += 1
		WeaponManager.refill_all_ammo(0.45)
		if _player_ref:
			_player_ref.heal(25.0)
		await get_tree().create_timer(3.0).timeout
		if GameManager.current_state == GameManager.GameState.PLAYING:
			_start_next_survival_wave()

func _apply_environment_quality() -> void:
	var world_env := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_env and world_env.environment:
		world_env.environment.fog_enabled = SettingsManager.effects_quality >= 1
	var sun := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if sun:
		sun.shadow_enabled = SettingsManager.shadow_quality >= 1

func _ensure_navigation_baked() -> void:
	for child in get_children():
		if child is NavigationRegion3D:
			var nav := child as NavigationRegion3D
			if nav.navigation_mesh and nav.navigation_mesh.get_polygon_count() == 0:
				nav.bake_navigation_mesh(false)
