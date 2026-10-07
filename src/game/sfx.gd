class_name Sfx
extends Node
## Short synthesized feedback sounds (hits, headshots, shield breaks, knocks), so hits can
## be heard without any audio assets. Plays through a small pool so sounds can overlap.

const MIX_RATE := 44100
const VOICES := 6

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	_sounds = {
		"hit": tone(1900.0, 0.035, 0.35),
		"head": tone(2600.0, 0.06, 0.45, 1.25),
		"shield_break": tone(900.0, 0.16, 0.5, 0.45, 0.6),
		"knock": tone(140.0, 0.22, 0.7, 0.6, 0.3),
	}
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(sound: String) -> void:
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _sounds[sound]
	player.play()


## A decaying sine (pitch multiplied by `sweep` over its length) mixed with some noise.
static func tone(frequency: float, duration: float, volume: float, sweep: float = 1.0, noise: float = 0.0) -> AudioStreamWAV:
	var count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(frequency)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		phase += TAU * frequency * lerpf(1.0, sweep, t) / MIX_RATE
		var envelope := (1.0 - t) * (1.0 - t) * minf(1.0, i / 40.0)
		var sample := (sin(phase) * (1.0 - noise) + rng.randf_range(-1.0, 1.0) * noise) * envelope * volume
		data.encode_s16(i * 2, clampi(int(sample * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.data = data
	return stream
