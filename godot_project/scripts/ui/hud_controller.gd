extends Control

@onready var health_bar: ProgressBar = $TopLeft/HealthBar
@onready var health_label: Label = $TopLeft/HealthLabel
@onready var objective_list: VBoxContainer = $TopLeft/ObjectivePanel/ObjectiveList
@onready var timer_label: Label = $TopCenter/TimerLabel
@onready var score_label: Label = $TopCenter/ScoreLabel
@onready var fps_label: Label = $TopCenter/FPSLabel
@onready var weapon_name_label: Label = $BottomRight/WeaponPanel/WeaponName
@onready var weapon_icon_label: Label = $BottomRight/WeaponPanel/WeaponIcon
@onready var ammo_label: Label = $BottomRight/WeaponPanel/AmmoLabel
@onready var interact_label: Label = $CenterPrompts/InteractLabel
@onready var toast_label: Label = $CenterPrompts/ToastLabel
@onready var kill_feed_label: Label = $CenterPrompts/KillFeedLabel
@onready var hit_marker: Control = $CrosshairRoot/HitMarker
@onready var crosshair_root: Control = $CrosshairRoot
@onready var vignette_rect: ColorRect = $DamageVignette
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var _damage_flash: float = 0.0
var _hit_marker_timer: float = 0.0
var _toast_timer: float = 0.0
var _kill_timer: float = 0.0
var _player: PlayerController = null

func _ready() -> void:
	UIManager.register_hud(self)
	_player = GameManager.active_player as PlayerController
	if _player:
		_player.health_changed.connect(_on_health_changed)
		_player.player_damaged.connect(_on_player_damaged)
		_player.ads_toggled.connect(_on_ads_toggled)
		if _player.weapon_rig:
			_player.weapon_rig.crosshair_spread_changed.connect(_on_spread_changed)
		_on_health_changed(_player.health, _player.max_health)

	WeaponManager.weapon_equipped.connect(_on_weapon_equipped)
	WeaponManager.ammo_changed.connect(_on_ammo_changed)
	MissionManager.objective_updated.connect(_on_objective_updated)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	UIManager.hud_toast_requested.connect(_on_toast_requested)
	UIManager.hit_marker_requested.connect(_on_hit_marker_requested)
	UIManager.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	UIManager.kill_feed_requested.connect(_on_kill_feed_requested)
	SettingsManager.settings_applied.connect(_apply_settings)

	var w := WeaponManager.get_active_weapon()
	if w:
		_on_weapon_equipped(w, WeaponManager.get_active_mag(), WeaponManager.get_active_reserve())
	_on_score_changed(GameManager.score)
	_rebuild_objectives()
	_apply_settings()
	hit_marker.visible = false
	toast_label.visible = false
	kill_feed_label.visible = false
	interact_label.visible = false
	if anim_player and anim_player.has_animation("fade_in"):
		anim_player.play("fade_in")

func _apply_settings() -> void:
	fps_label.visible = SettingsManager.show_fps

func _process(delta: float) -> void:
	var t: int = int(GameManager.match_elapsed_time)
	var mins: int = t / 60
	var secs: int = t % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	if fps_label.visible:
		fps_label.text = "%d FPS" % Engine.get_frames_per_second()

	if _damage_flash > 0.0:
		_damage_flash = maxf(0.0, _damage_flash - delta * 2.2)
	if vignette_rect and vignette_rect.material is ShaderMaterial:
		var mat := vignette_rect.material as ShaderMaterial
		var low_hp: float = 0.0
		if _player and _player.health < 35.0:
			low_hp = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
		mat.set_shader_parameter("damage_intensity", _damage_flash)
		mat.set_shader_parameter("low_health_pulse", low_hp)

	if _hit_marker_timer > 0.0:
		_hit_marker_timer -= delta
		if _hit_marker_timer <= 0.0:
			hit_marker.visible = false

	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			toast_label.visible = false

	if _kill_timer > 0.0:
		_kill_timer -= delta
		if _kill_timer <= 0.0:
			kill_feed_label.visible = false

func _on_health_changed(hp: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = hp
	health_label.text = "HP %d / %d" % [int(ceil(hp)), int(max_hp)]

func _on_player_damaged(_amt: float, _pos: Vector3) -> void:
	_damage_flash = 0.85

func _on_ads_toggled(is_ads: bool) -> void:
	crosshair_root.modulate.a = 0.35 if is_ads else 1.0

func _on_spread_changed(spread: float) -> void:
	var gap: float = clampf(spread * 450.0, 6.0, 34.0)
	$CrosshairRoot/Top.position.y = -gap - 10.0
	$CrosshairRoot/Bottom.position.y = gap
	$CrosshairRoot/Left.position.x = -gap - 10.0
	$CrosshairRoot/Right.position.x = gap

func _on_weapon_equipped(w: WeaponData, mag: int, reserve: int) -> void:
	weapon_name_label.text = w.display_name
	weapon_icon_label.text = w.icon_code
	_on_ammo_changed(mag, reserve)

func _on_ammo_changed(mag: int, reserve: int) -> void:
	ammo_label.text = "%02d / %03d" % [mag, reserve]

func _on_score_changed(val: int) -> void:
	score_label.text = "SCORE %d" % val

func _on_wave_changed(wave: int, rem: int) -> void:
	if GameManager.current_mode == GameManager.GameMode.SURVIVAL:
		for child in objective_list.get_children():
			child.queue_free()
		var lbl := Label.new()
		lbl.text = "Wave %d — Hostiles Remaining: %d" % [wave, rem]
		objective_list.add_child(lbl)

func _on_objective_updated(_id: String, _label: String, _done: bool, _sec: bool) -> void:
	_rebuild_objectives()

func _rebuild_objectives() -> void:
	for child in objective_list.get_children():
		child.queue_free()
	if GameManager.current_mode == GameManager.GameMode.TRAINING:
		var lbl := Label.new()
		lbl.text = "Training Range: Move, ADS, Reload, Hit Moving Targets"
		objective_list.add_child(lbl)
		return
	if GameManager.current_mode == GameManager.GameMode.FREE_PRACTICE:
		var lbl := Label.new()
		lbl.text = "Free Practice: Explore Sector & Test Weapons"
		objective_list.add_child(lbl)
		return
	if GameManager.current_mode == GameManager.GameMode.SURVIVAL:
		_on_wave_changed(GameManager.survival_wave, GameManager.survival_enemies_remaining)
		return

	var objs := MissionManager.get_ordered_objectives()
	for o in objs:
		var lbl := Label.new()
		var prefix: String = "[DONE] " if bool(o["completed"]) else ("[OPT] " if bool(o["secondary"]) else "[OBJ] ")
		lbl.text = prefix + str(o["label"])
		lbl.modulate = Color(0.4, 0.95, 0.55) if bool(o["completed"]) else Color(0.95, 0.96, 0.98)
		objective_list.add_child(lbl)

func _on_toast_requested(msg: String) -> void:
	toast_label.text = msg
	toast_label.visible = true
	_toast_timer = 2.6

func _on_hit_marker_requested(is_kill: bool, is_headshot: bool) -> void:
	hit_marker.visible = true
	hit_marker.modulate = Color(1.0, 0.28, 0.22) if is_kill else (Color(1.0, 0.8, 0.2) if is_headshot else Color.WHITE)
	_hit_marker_timer = 0.14

func _on_interaction_prompt_changed(prompt: String) -> void:
	interact_label.text = prompt
	interact_label.visible = not prompt.is_empty()

func _on_kill_feed_requested(points: int, is_headshot: bool) -> void:
	kill_feed_label.text = "+%d %s" % [points, "HEADSHOT ELIMINATION" if is_headshot else "HOSTILE NEUTRALIZED"]
	kill_feed_label.visible = true
	_kill_timer = 1.8
