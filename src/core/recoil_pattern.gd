class_name RecoilPattern
extends RefCounted
## A weapon's recoil as per-shot view kicks in degrees (x = yaw to the right, y = pitch up).

var kicks: PackedVector2Array


func _init(p_kicks: PackedVector2Array) -> void:
	assert(not p_kicks.is_empty(), "a recoil pattern needs at least one kick")
	kicks = p_kicks


## Kick applied when shot `index` (0-based) fires. Sprays longer than the pattern repeat its last kick.
func kick(index: int) -> Vector2:
	return kicks[mini(index, kicks.size() - 1)]


## Total view offset after `count` shots if the player doesn't compensate.
func offset_after(count: int) -> Vector2:
	var total := Vector2.ZERO
	for i in count:
		total += kick(i)
	return total
