class_name ApexDamage
## Apex's health model: 100 health behind armour (levels 1–4 add 50, 75, 100 and 125;
## since 2024 the armour is built in and levels up with EVO points). Armour absorbs damage
## first, and the rest of a shot that breaks it carries through to health. Helmets and
## legend perks are not modelled yet.

const HEALTH := 100.0
const SHIELDS := {"none": 0.0, "white": 50.0, "blue": 75.0, "purple": 100.0, "red": 125.0}
const SHIELD_COLORS := {
	"none": Color(0.9, 0.9, 0.9),
	"white": Color(0.9, 0.9, 0.9),
	"blue": Color(0.25, 0.6, 1.0),
	"purple": Color(0.7, 0.35, 1.0),
	"red": Color(1.0, 0.3, 0.3),
}


## Shield and health after `damage`: Vector2(shield, health).
static func apply(shield: float, health: float, damage: float) -> Vector2:
	var to_shield := minf(shield, damage)
	return Vector2(shield - to_shield, maxf(health - (damage - to_shield), 0.0))


## Body shots needed to knock a full-health target.
static func shots_to_knock(damage_per_shot: float, shield: float) -> int:
	return ceili((HEALTH + shield) / damage_per_shot)
