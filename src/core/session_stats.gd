class_name SessionStats
extends RefCounted
## Scoring for one training session: shots, hits by region, damage, and for every target
## the time from appearing to the first hit and to the knock.

var magazine_size: int
var shots := 0
var hits := {"head": 0, "body": 0, "limb": 0}
var damage := 0.0
var first_hit_times := PackedFloat32Array()
var knock_times := PackedFloat32Array()
var duration := 0.0


func _init(p_magazine_size: int) -> void:
	magazine_size = p_magazine_size


func record_shots(count: int) -> void:
	shots += count


func record_hit(region: String, damage_dealt: float) -> void:
	hits[region] += 1
	damage += damage_dealt


func record_first_hit(seconds_since_spawn: float) -> void:
	first_hit_times.append(seconds_since_spawn)


func record_knock(seconds_since_spawn: float) -> void:
	knock_times.append(seconds_since_spawn)


func hit_count() -> int:
	return hits["head"] + hits["body"] + hits["limb"]


func accuracy() -> float:
	return float(hit_count()) / shots if shots else 0.0


func headshot_rate() -> float:
	return float(hits["head"]) / hit_count() if hit_count() else 0.0


## Damage you would deal with one full magazine at this session's accuracy.
func damage_per_magazine() -> float:
	return damage * magazine_size / shots if shots else 0.0


static func mean(values: PackedFloat32Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += v
	return total / values.size()


func summary() -> Dictionary:
	return {
		"targets": knock_times.size(),
		"avg_time_to_knock": mean(knock_times),
		"best_time_to_knock": Array(knock_times).min() if not knock_times.is_empty() else 0.0,
		"avg_time_to_first_hit": mean(first_hit_times),
		"accuracy": accuracy(),
		"headshot_rate": headshot_rate(),
		"damage_per_magazine": damage_per_magazine(),
		"damage": damage,
		"shots": shots,
		"hits": hit_count(),
		"duration": duration,
	}
