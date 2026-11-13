class_name MissionData
extends Resource

@export var mission_id: String = "mission_01"
@export var mission_index: int = 0
@export var title: String = "Operation Silent District"
@export var location_name: String = "Abandoned City"
@export var environment_theme: String = "city"
@export var map_scene_path: String = "res://scenes/environments/map_abandoned_city.tscn"
@export_multiline var briefing: String = "Infiltrate the abandoned perimeter, recover the encrypted relay core, and secure the central plaza."
@export var primary_objective_ids: PackedStringArray = PackedStringArray(["obj_reach_plaza", "obj_collect_core", "obj_secure_zone"])
@export var primary_objective_labels: PackedStringArray = PackedStringArray(["Infiltrate Relay Street", "Recover Encrypted Relay Core", "Secure Extraction Plaza"])
@export var secondary_objective_ids: PackedStringArray = PackedStringArray(["obj_secondary_comms"])
@export var secondary_objective_labels: PackedStringArray = PackedStringArray(["Disable Rogue Comms Terminal"])
@export var reward_credits: int = 1000
@export var time_limit_sec: float = 0.0
