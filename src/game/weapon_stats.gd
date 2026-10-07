class_name WeaponStats
extends Resource
## One weapon's numbers. Weapons marked `placeholder` carry made-up values until they are
## measured from Apex (damage, fire rate and magazine from the Firing Range; recoil from
## recorded sprays).

@export var display_name := ""
@export var placeholder := true
@export var damage := 14.0
@export var fire_rate := 13.5  ## rounds per second
@export var magazine_size := 28
@export var reload_time := 2.4  ## seconds
@export var headshot_multiplier := 1.75
@export var limb_multiplier := 0.8
@export var bullet_speed := 600.0  ## m/s
@export var bullet_gravity := 9.81  ## m/s²
## Per-shot view kicks in degrees (x = right, y = up).
@export var recoil := PackedVector2Array([Vector2(0, 0.4)])
