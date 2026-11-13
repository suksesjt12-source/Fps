class_name WeaponData
extends Resource

enum Category {
	ASSAULT_RIFLE,
	COMPACT_RIFLE,
	PRECISION_RIFLE,
	ENERGY_WEAPON,
	SHOTGUN,
	SIDEARM,
	HEAVY_ENERGY
}

enum FireMode {
	SINGLE,
	BURST,
	AUTO
}

@export var weapon_id: String = "vx47_assault"
@export var display_name: String = "VX-47 Vanguard"
@export var category: Category = Category.ASSAULT_RIFLE
@export var category_label: String = "Assault Rifle"
@export var fire_mode: FireMode = FireMode.AUTO
@export var burst_count: int = 3

@export_group("Ballistics & Handling")
@export var damage: float = 28.0
@export var fire_rate: float = 9.5
@export var magazine_size: int = 30
@export var reserve_max: int = 150
@export var reload_duration: float = 1.75
@export var spread_hip: float = 0.032
@export var spread_ads: float = 0.007
@export var recoil_pitch: float = 1.65
@export var recoil_yaw: float = 0.55
@export var ads_fov: float = 55.0
@export var ads_sensitivity_mult: float = 0.62
@export var pellets: int = 1
@export var effective_range: float = 120.0
@export var is_energy: bool = false
@export var is_explosive: bool = false
@export var splash_radius: float = 0.0
@export var move_speed_mult: float = 1.0

@export_group("Visual & Audio")
@export var accent_color: Color = Color(0.95, 0.65, 0.15, 1.0)
@export var body_color: Color = Color(0.18, 0.21, 0.26, 1.0)
@export var barrel_length: float = 0.52
@export var receiver_length: float = 0.44
@export var custom_glb_path: String = ""
@export var fire_sfx_path: String = "res://assets/audio/sfx/fire_assault.wav"
@export var reload_sfx_path: String = "res://assets/audio/sfx/weapon_reload.wav"
@export var equip_sfx_path: String = "res://assets/audio/sfx/weapon_equip.wav"
@export var icon_code: String = "AR"
