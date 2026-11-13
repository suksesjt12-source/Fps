class_name PickupItem
extends Area3D

enum PickupType {
	WEAPON,
	AMMO,
	MEDKIT
}

@export var pickup_type: PickupType = PickupType.WEAPON
@export var weapon_id: String = "k9_compact"
@export var heal_amount: float = 40.0
@export var respawn_time: float = 0.0

var _available: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _available:
		rotate_y(delta * 1.4)

func _on_body_entered(body: Node) -> void:
	if not _available or not body.is_in_group("player"):
		return
	match pickup_type:
		PickupType.WEAPON:
			if WeaponManager.pickup_weapon(weapon_id):
				UIManager.show_toast("Equipped: %s" % weapon_id.to_upper())
				_consume()
		PickupType.AMMO:
			WeaponManager.refill_all_ammo(0.5)
			UIManager.show_toast("Ammunition Replenished")
			_consume()
		PickupType.MEDKIT:
			if body is PlayerController and (body as PlayerController).health < (body as PlayerController).max_health:
				(body as PlayerController).heal(heal_amount)
				UIManager.show_toast("Medkit Applied (+%d HP)" % int(heal_amount))
				_consume()

func _consume() -> void:
	_available = false
	visible = false
	if respawn_time > 0.0:
		await get_tree().create_timer(respawn_time).timeout
		if is_instance_valid(self):
			_available = true
			visible = true
	else:
		queue_free()
