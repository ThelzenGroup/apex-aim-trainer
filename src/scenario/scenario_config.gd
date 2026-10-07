class_name ScenarioConfig
extends Resource
## One training scenario: the weapon, how many targets, their shields and where and how
## they move.

@export var id := ""
@export var title := ""
@export_multiline var description := ""
@export var weapon: WeaponStats
@export var target_count := 10
@export_enum("none", "white", "blue", "purple", "red") var shield_tier := "purple"
@export var distance_min := 8.0  ## metres
@export var distance_max := 15.0
@export var spread_degrees := 25.0  ## how far left or right of straight ahead targets appear
@export var sizes := PackedStringArray(["small", "medium", "large"])
@export var strafe_speed := 4.2  ## m/s, placeholder
@export var crouch_speed := 2.0
@export var strafe_width := 3.0
