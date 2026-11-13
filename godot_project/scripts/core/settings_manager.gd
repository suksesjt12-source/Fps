extends Node

signal settings_applied

enum GraphicsPreset {
	LOW = 0,
	MEDIUM = 1,
	HIGH = 2,
	CUSTOM = 3
}

# Audio settings (0.0 to 1.0)
var master_volume: float = 0.9
var music_volume: float = 0.65
var sfx_volume: float = 0.9
var ambience_volume: float = 0.75

# Control sensitivity settings
var look_sensitivity_x: float = 1.0
var look_sensitivity_y: float = 1.0
var ads_sensitivity_multiplier: float = 0.6
var invert_y: bool = false

# Graphics settings
var graphics_preset: int = GraphicsPreset.MEDIUM
var render_scale: float = 0.85
var shadow_quality: int = 1 # 0: Off, 1: Low, 2: High
var msaa_level: int = 0 # 0: Off, 1: 2x, 2: 4x
var texture_quality: int = 1 # 0: Low, 1: Medium, 2: High
var effects_quality: int = 1 # 0: Low, 1: Medium, 2: High
var view_distance: float = 90.0
var environment_detail: int = 1 # 0: Minimal, 1: Standard, 2: Full
var vsync_enabled: bool = true
var fps_limit: int = 60 # 30 or 60
var show_fps: bool = false

# Android Touch HUD layout settings
var hud_joystick_size: float = 1.0
var hud_button_scale: float = 1.0
var hud_button_opacity: float = 0.82
var hud_custom_positions: Dictionary = {}

func _ready() -> void:
	apply_all_settings()

func apply_preset(preset: int) -> void:
	graphics_preset = preset
	match preset:
		GraphicsPreset.LOW:
			render_scale = 0.70
			shadow_quality = 0
			msaa_level = 0
			texture_quality = 0
			effects_quality = 0
			view_distance = 60.0
			environment_detail = 0
			fps_limit = 30
		GraphicsPreset.MEDIUM:
			render_scale = 0.85
			shadow_quality = 1
			msaa_level = 0
			texture_quality = 1
			effects_quality = 1
			view_distance = 90.0
			environment_detail = 1
			fps_limit = 60
		GraphicsPreset.HIGH:
			render_scale = 1.0
			shadow_quality = 2
			msaa_level = 1
			texture_quality = 2
			effects_quality = 2
			view_distance = 135.0
			environment_detail = 2
			fps_limit = 60
	apply_all_settings()

func apply_all_settings() -> void:
	apply_audio_settings()
	apply_graphics_settings()
	settings_applied.emit()

func apply_audio_settings() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)
	_set_bus_volume("Ambience", ambience_volume)

func _set_bus_volume(bus_name: String, linear_val: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var clamped: float = clampf(linear_val, 0.0, 1.0)
	if clamped <= 0.001:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(clamped))

func apply_graphics_settings() -> void:
	var viewport: Viewport = get_viewport()
	if viewport:
		viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		viewport.scaling_3d_scale = clampf(render_scale, 0.5, 1.0)
		match msaa_level:
			1:
				viewport.msaa_3d = Viewport.MSAA_2X
			2:
				viewport.msaa_3d = Viewport.MSAA_4X
			_:
				viewport.msaa_3d = Viewport.MSAA_DISABLED

		var shadow_sizes: Array[int] = [512, 1024, 2048]
		var s_idx: int = clampi(shadow_quality, 0, 2)
		viewport.positional_shadow_atlas_size = shadow_sizes[s_idx]

	RenderingServer.directional_shadow_atlas_set_size(1024 if shadow_quality <= 1 else 2048, true)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)
	Engine.max_fps = clampi(fps_limit, 30, 120)

func to_dict() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"ambience_volume": ambience_volume,
		"look_sensitivity_x": look_sensitivity_x,
		"look_sensitivity_y": look_sensitivity_y,
		"ads_sensitivity_multiplier": ads_sensitivity_multiplier,
		"invert_y": invert_y,
		"graphics_preset": graphics_preset,
		"render_scale": render_scale,
		"shadow_quality": shadow_quality,
		"msaa_level": msaa_level,
		"texture_quality": texture_quality,
		"effects_quality": effects_quality,
		"view_distance": view_distance,
		"environment_detail": environment_detail,
		"vsync_enabled": vsync_enabled,
		"fps_limit": fps_limit,
		"show_fps": show_fps,
		"hud_joystick_size": hud_joystick_size,
		"hud_button_scale": hud_button_scale,
		"hud_button_opacity": hud_button_opacity,
		"hud_custom_positions": hud_custom_positions
	}

func from_dict(data: Dictionary) -> void:
	master_volume = float(data.get("master_volume", 0.9))
	music_volume = float(data.get("music_volume", 0.65))
	sfx_volume = float(data.get("sfx_volume", 0.9))
	ambience_volume = float(data.get("ambience_volume", 0.75))
	look_sensitivity_x = float(data.get("look_sensitivity_x", 1.0))
	look_sensitivity_y = float(data.get("look_sensitivity_y", 1.0))
	ads_sensitivity_multiplier = float(data.get("ads_sensitivity_multiplier", 0.6))
	invert_y = bool(data.get("invert_y", false))
	graphics_preset = int(data.get("graphics_preset", GraphicsPreset.MEDIUM))
	render_scale = clampf(float(data.get("render_scale", 0.85)), 0.5, 1.0)
	shadow_quality = clampi(int(data.get("shadow_quality", 1)), 0, 2)
	msaa_level = clampi(int(data.get("msaa_level", 0)), 0, 2)
	texture_quality = clampi(int(data.get("texture_quality", 1)), 0, 2)
	effects_quality = clampi(int(data.get("effects_quality", 1)), 0, 2)
	view_distance = clampf(float(data.get("view_distance", 90.0)), 45.0, 180.0)
	environment_detail = clampi(int(data.get("environment_detail", 1)), 0, 2)
	vsync_enabled = bool(data.get("vsync_enabled", true))
	fps_limit = clampi(int(data.get("fps_limit", 60)), 30, 120)
	show_fps = bool(data.get("show_fps", false))
	hud_joystick_size = clampf(float(data.get("hud_joystick_size", 1.0)), 0.7, 1.5)
	hud_button_scale = clampf(float(data.get("hud_button_scale", 1.0)), 0.7, 1.5)
	hud_button_opacity = clampf(float(data.get("hud_button_opacity", 0.82)), 0.3, 1.0)
	var pos_dict = data.get("hud_custom_positions", {})
	if typeof(pos_dict) == TYPE_DICTIONARY:
		hud_custom_positions = pos_dict.duplicate(true)
	apply_all_settings()
