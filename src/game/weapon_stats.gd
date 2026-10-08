class_name WeaponStats
extends Resource
## One weapon's numbers, in the units Apex data is published in. `source` says where they
## came from; fields named in `placeholder_fields` are stand-ins until measured from Apex.

## Apex runs on Source-style units: one unit is one inch.
const METERS_PER_UNIT := 0.0254

@export var display_name := ""
@export_multiline var source := ""
@export var placeholder_fields := PackedStringArray()
## Damage per hit as Apex rounds it for each hitbox region.
@export var body_damage := 13.0
@export var head_damage := 23.0
@export var limb_damage := 10.0
@export var rpm := 810.0
## Magazine size with no magazine, then with level 1–3 magazines (0 = no such magazine).
@export var magazine_sizes := PackedInt32Array([18, 20, 25, 28])
@export var tactical_reload := 2.4  ## seconds, with rounds left
@export var empty_reload := 3.2  ## seconds, from empty
@export var bullet_speed_units := 29000.0  ## Apex units per second
@export var bullet_gravity := 9.81  ## m/s²
## Per-shot view kicks in degrees (x = right, y = up).
@export var recoil := PackedVector2Array([Vector2(0, 0.4)])


func damage_for(region: String) -> float:
	match region:
		"head":
			return head_damage
		"limb":
			return limb_damage
	return body_damage


func fire_rate() -> float:
	return rpm / 60.0


func bullet_speed() -> float:
	return bullet_speed_units * METERS_PER_UNIT


## Rounds in a magazine of the given level; weapons without that level fall back to base.
func magazine(level: int) -> int:
	var size := magazine_sizes[clampi(level, 0, magazine_sizes.size() - 1)]
	return size if size > 0 else magazine_sizes[0]


func placeholder_note() -> String:
	if placeholder_fields.is_empty():
		return ""
	return "Placeholders until measured from Apex: " + ", ".join(placeholder_fields) + "."
