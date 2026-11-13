extends Node

signal inventory_updated(slots: Array, active_index: int)
signal weapon_equipped(weapon_data: WeaponData, mag_ammo: int, reserve_ammo: int)
signal ammo_changed(mag_ammo: int, reserve_ammo: int)
signal reload_started(duration: float)
signal reload_finished
signal fire_cooldown_reset

const DEFAULT_WEAPONS := [
	"res://resources/weapons/vx47_assault_rifle.tres",
	"res://resources/weapons/k9_compact_carbine.tres",
	"res://resources/weapons/sr8_precision_rifle.tres",
	"res://resources/weapons/arc_pulse_rifle.tres",
	"res://resources/weapons/m12_tactical_shotgun.tres",
	"res://resources/weapons/p90_tactical_sidearm.tres",
	"res://resources/weapons/helion_heavy_cannon.tres"
]

const MAX_SLOTS := 3

var catalog: Dictionary = {}
var inventory: Array[Dictionary] = []
var active_slot: int = 0
var is_reloading: bool = false
var is_switching: bool = false

func _ready() -> void:
	_load_weapon_catalog()
	reset_loadout_for_mode(GameManager.GameMode.CAMPAIGN)

func _load_weapon_catalog() -> void:
	catalog.clear()
	for path in DEFAULT_WEAPONS:
		if ResourceLoader.exists(path):
			var w := load(path) as WeaponData
			if w:
				catalog[w.weapon_id] = w

func reset_loadout_for_mode(mode: int) -> void:
	inventory.clear()
	is_reloading = false
	is_switching = false
	if mode == GameManager.GameMode.FREE_PRACTICE or mode == GameManager.GameMode.TRAINING:
		# Equip Assault Rifle, Energy Rifle, and Sidearm by default; racks allow swapping all 7
		_add_slot("vx47_assault")
		_add_slot("arc_pulse")
		_add_slot("p90_sidearm")
	else:
		_add_slot("vx47_assault")
		_add_slot("p90_sidearm")
	active_slot = 0
	_emit_active_state()

func _add_slot(weapon_id: String) -> void:
	var data: WeaponData = catalog.get(weapon_id, null)
	if data == null:
		return
	inventory.append({
		"data": data,
		"mag": data.magazine_size,
		"reserve": data.reserve_max
	})

func get_active_weapon() -> WeaponData:
	if inventory.is_empty() or active_slot < 0 or active_slot >= inventory.size():
		return null
	return inventory[active_slot]["data"] as WeaponData

func get_active_mag() -> int:
	if inventory.is_empty():
		return 0
	return int(inventory[active_slot]["mag"])

func get_active_reserve() -> int:
	if inventory.is_empty():
		return 0
	return int(inventory[active_slot]["reserve"])

func can_fire() -> bool:
	if is_reloading or is_switching or inventory.is_empty():
		return false
	return get_active_mag() > 0

func consume_round() -> bool:
	if not can_fire():
		return false
	inventory[active_slot]["mag"] = maxi(0, int(inventory[active_slot]["mag"]) - 1)
	ammo_changed.emit(get_active_mag(), get_active_reserve())
	return true

func can_reload() -> bool:
	if is_reloading or is_switching or inventory.is_empty():
		return false
	var w := get_active_weapon()
	if w == null:
		return false
	return get_active_mag() < w.magazine_size and get_active_reserve() > 0

func begin_reload() -> float:
	if not can_reload():
		return 0.0
	var w := get_active_weapon()
	is_reloading = true
	reload_started.emit(w.reload_duration)
	AudioManager.play_sfx_2d(w.reload_sfx_path)
	return w.reload_duration

func complete_reload() -> void:
	if not is_reloading or inventory.is_empty():
		is_reloading = false
		return
	var w := get_active_weapon()
	var current_mag: int = get_active_mag()
	var current_reserve: int = get_active_reserve()
	var needed: int = w.magazine_size - current_mag
	var transfer: int = mini(needed, current_reserve)
	inventory[active_slot]["mag"] = current_mag + transfer
	inventory[active_slot]["reserve"] = current_reserve - transfer
	is_reloading = false
	reload_finished.emit()
	ammo_changed.emit(get_active_mag(), get_active_reserve())

func cancel_reload() -> void:
	is_reloading = false

func switch_next_weapon() -> void:
	if inventory.size() <= 1 or is_switching:
		return
	var next_idx: int = (active_slot + 1) % inventory.size()
	switch_to_slot(next_idx)

func switch_to_slot(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= inventory.size() or slot_idx == active_slot:
		return
	cancel_reload()
	active_slot = slot_idx
	_emit_active_state()

func pickup_weapon(weapon_id: String) -> bool:
	var data: WeaponData = catalog.get(weapon_id, null)
	if data == null:
		return false
	# If already owned, refill ammo
	for i in range(inventory.size()):
		if (inventory[i]["data"] as WeaponData).weapon_id == weapon_id:
			inventory[i]["reserve"] = data.reserve_max
			if i == active_slot:
				ammo_changed.emit(get_active_mag(), get_active_reserve())
			AudioManager.play_sfx_key_2d("pickup")
			return true

	cancel_reload()
	var new_entry := {
		"data": data,
		"mag": data.magazine_size,
		"reserve": data.reserve_max
	}
	if inventory.size() < MAX_SLOTS:
		inventory.append(new_entry)
		active_slot = inventory.size() - 1
	else:
		inventory[active_slot] = new_entry
	AudioManager.play_sfx_key_2d("pickup")
	_emit_active_state()
	return true

func refill_all_ammo(fraction: float = 0.5) -> void:
	for entry in inventory:
		var data := entry["data"] as WeaponData
		var add_amt: int = maxi(data.magazine_size, int(ceil(data.reserve_max * fraction)))
		entry["reserve"] = mini(data.reserve_max, int(entry["reserve"]) + add_amt)
	ammo_changed.emit(get_active_mag(), get_active_reserve())
	AudioManager.play_sfx_key_2d("pickup")

func _emit_active_state() -> void:
	var w := get_active_weapon()
	if w:
		AudioManager.play_sfx_2d(w.equip_sfx_path)
		weapon_equipped.emit(w, get_active_mag(), get_active_reserve())
	inventory_updated.emit(inventory, active_slot)
