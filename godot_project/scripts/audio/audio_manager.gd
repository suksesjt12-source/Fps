extends Node

const MAX_3D_VOICES := 14
const MAX_2D_SFX := 6

var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer
var _sfx_2d_pool: Array[AudioStreamPlayer] = []
var _sfx_3d_pool: Array[AudioStreamPlayer3D] = []
var _stream_cache: Dictionary = {}
var _duck_tween: Tween = null
var _current_music_key: String = ""

const MUSIC_PATHS := {
	"menu": "res://assets/audio/music/main_menu_theme.wav",
	"combat": "res://assets/audio/music/combat_tension_loop.wav",
	"victory": "res://assets/audio/music/victory_theme.wav",
	"game_over": "res://assets/audio/music/game_over_theme.wav"
}

const AMBIENCE_PATHS := {
	"city": "res://assets/audio/ambience/city_wind_ambience.wav",
	"desert": "res://assets/audio/ambience/desert_wind_ambience.wav",
	"frozen": "res://assets/audio/ambience/arctic_storm_ambience.wav",
	"underground": "res://assets/audio/ambience/underground_machinery_ambience.wav",
	"harbor": "res://assets/audio/ambience/harbor_rain_ambience.wav"
}

const SFX_PATHS := {
	"ui_click": "res://assets/audio/sfx/ui_click.wav",
	"ui_hover": "res://assets/audio/sfx/ui_hover.wav",
	"hit_marker": "res://assets/audio/sfx/hit_marker.wav",
	"player_hurt": "res://assets/audio/sfx/player_hurt.wav",
	"footstep_concrete": "res://assets/audio/sfx/footstep_concrete.wav",
	"footstep_sprint": "res://assets/audio/sfx/footstep_sprint.wav",
	"jump": "res://assets/audio/sfx/player_jump.wav",
	"land": "res://assets/audio/sfx/player_land.wav",
	"crouch": "res://assets/audio/sfx/player_crouch.wav",
	"impact_metal": "res://assets/audio/sfx/impact_metal.wav",
	"impact_concrete": "res://assets/audio/sfx/impact_concrete.wav",
	"explosion": "res://assets/audio/sfx/explosion.wav",
	"enemy_alert": "res://assets/audio/sfx/enemy_alert.wav",
	"enemy_defeated": "res://assets/audio/sfx/enemy_defeated.wav",
	"mission_start": "res://assets/audio/sfx/mission_start.wav",
	"mission_complete": "res://assets/audio/sfx/mission_complete.wav",
	"mission_failed": "res://assets/audio/sfx/mission_failed.wav",
	"objective_updated": "res://assets/audio/sfx/objective_updated.wav",
	"checkpoint": "res://assets/audio/sfx/checkpoint_activated.wav",
	"warning": "res://assets/audio/sfx/warning_alert.wav",
	"pickup": "res://assets/audio/sfx/weapon_pickup.wav",
	"empty_mag": "res://assets/audio/sfx/weapon_empty.wav"
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = "Ambience"
	add_child(_ambience_player)

	_ui_player = AudioStreamPlayer.new()
	_ui_player.bus = "UI"
	add_child(_ui_player)

	for i in range(MAX_2D_SFX):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_2d_pool.append(p)

	for i in range(MAX_3D_VOICES):
		var p3 := AudioStreamPlayer3D.new()
		p3.bus = "SFX"
		p3.max_distance = 48.0
		p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(p3)
		_sfx_3d_pool.append(p3)

func _get_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if _stream_cache.has(path):
		return _stream_cache[path]
	if ResourceLoader.exists(path):
		var loaded := load(path) as AudioStream
		if loaded:
			_stream_cache[path] = loaded
			return loaded
	return null

func play_music(key: String) -> void:
	if _current_music_key == key and _music_player.playing:
		return
	var path: String = MUSIC_PATHS.get(key, "")
	var stream := _get_stream(path)
	if stream == null:
		return
	_current_music_key = key
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD if (key == "menu" or key == "combat") else AudioStreamWAV.LOOP_DISABLED
	_music_player.stream = stream
	_music_player.volume_db = 0.0
	_music_player.play()

func stop_music() -> void:
	_current_music_key = ""
	_music_player.stop()

func play_ambience(theme_key: String) -> void:
	var path: String = AMBIENCE_PATHS.get(theme_key, AMBIENCE_PATHS["city"])
	var stream := _get_stream(path)
	if stream == null:
		return
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_ambience_player.stream = stream
	_ambience_player.play()

func stop_ambience() -> void:
	_ambience_player.stop()

func play_ui(sfx_key: String, pitch_jitter: float = 0.04) -> void:
	var stream := _get_stream(SFX_PATHS.get(sfx_key, ""))
	if stream == null:
		return
	_ui_player.stream = stream
	_ui_player.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	_ui_player.play()

func play_stinger(sfx_key: String) -> void:
	play_sfx_2d(SFX_PATHS.get(sfx_key, ""), 0.0, 1.0)
	_duck_music_temporarily(1.2, -9.0)

func play_sfx_key_2d(sfx_key: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	play_sfx_2d(SFX_PATHS.get(sfx_key, ""), volume_db, pitch)

func play_sfx_2d(path: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream := _get_stream(path)
	if stream == null:
		return
	for player in _sfx_2d_pool:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.pitch_scale = pitch
			player.play()
			return

func play_sfx_3d_key(sfx_key: String, world_pos: Vector3, volume_db: float = 0.0, pitch_jitter: float = 0.08) -> void:
	play_sfx_3d(SFX_PATHS.get(sfx_key, ""), world_pos, volume_db, randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter))

func play_sfx_3d(path: String, world_pos: Vector3, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream := _get_stream(path)
	if stream == null:
		return
	var free_player: AudioStreamPlayer3D = null
	for player in _sfx_3d_pool:
		if not player.playing:
			free_player = player
			break
	if free_player == null:
		free_player = _sfx_3d_pool[0]
		free_player.stop()
	free_player.global_position = world_pos
	free_player.stream = stream
	free_player.volume_db = volume_db
	free_player.pitch_scale = pitch
	free_player.play()

func trim_active_voices() -> void:
	var count := 0
	for p in _sfx_3d_pool:
		if p.playing:
			count += 1
			if count > 6:
				p.stop()

func _duck_music_temporarily(duration: float, duck_db: float) -> void:
	if not _music_player.playing:
		return
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(_music_player, "volume_db", duck_db, 0.12)
	_duck_tween.tween_interval(duration)
	_duck_tween.tween_property(_music_player, "volume_db", 0.0, 0.45)
