class_name WeaponState
extends RefCounted
## Fire rate, magazine and reload for an automatic weapon, independent of frame rate.
## Call trigger() once per frame; it returns how many shots fire this frame.

var fire_interval: float
var magazine_size: int
var reload_time: float
var ammo: int
var reload_left := 0.0
var _cooldown := 0.0


func _init(fire_rate: float, p_magazine_size: int, p_reload_time: float) -> void:
	fire_interval = 1.0 / fire_rate
	magazine_size = p_magazine_size
	reload_time = p_reload_time
	ammo = magazine_size


func is_reloading() -> bool:
	return reload_left > 0.0


func start_reload() -> void:
	if ammo < magazine_size and not is_reloading():
		reload_left = reload_time


## Advances `delta` seconds with the trigger held or released. Firing on an empty
## magazine starts a reload, as in Apex.
func trigger(held: bool, delta: float) -> int:
	if is_reloading():
		reload_left -= delta
		if reload_left <= 0.0:
			reload_left = 0.0
			ammo = magazine_size
			_cooldown = 0.0
		return 0
	# While the trigger is held, a long frame fires every shot that fell inside it, so the
	# fire rate is exact at any frame rate.
	_cooldown -= delta
	if not held:
		_cooldown = maxf(_cooldown, 0.0)
		return 0
	if ammo == 0:
		start_reload()
		return 0
	var shots := 0
	while _cooldown <= 0.0 and ammo > 0:
		_cooldown += fire_interval
		ammo -= 1
		shots += 1
	return shots
