extends RefCounted
class_name StressEffectSystem

# Ordered list keeps update loops and snapshots deterministic; dictionaries do not guarantee iteration order.
const EFFECT_ORDER := [
	"ground",
	"voices",
	"camera",
	"earthquake",
	"blind",
	"color"
]

# Each effect defines a numeric range and oscillation behaviour that the controller will map to.
const EFFECT_CONFIGS := {
	"ground": {
		"min_value": 0.0,
		"max_value": 1.25,
		"frequency": 0.04,
		"phase": 0.0,
		"curve": 1.0,
		"fade_in": 3.5,
		"fade_out": 1.8
	},
	"voices": {
		"min_value": 0.0,
		"max_value": 1.0,
		"frequency": 0.065,
		"phase": 0.85,
		"curve": 1.1,
		"fade_in": 4.2,
		"fade_out": 1.6
	},
	"camera": {
		"min_value": 0.0,
		"max_value": 0.2,
		"frequency": 0.075,
		"phase": 1.7,
		"curve": 1.25,
		"fade_in": 3.8,
		"fade_out": 1.4
	},
	"earthquake": {
		"min_value": 0.0,
		"max_value": 1.0,
		"frequency": 0.092,
		"phase": 2.55,
		"curve": 1.35,
		"fade_in": 4.6,
		"fade_out": 1.2
	},
	"blind": {
		"min_value": 0.0,
		"max_value": 1.0,
		"frequency": 0.11,
		"phase": 3.4,
		"curve": 1.4,
		"fade_in": 5.0,
		"fade_out": 1.1
	},
	"color": {
		"min_value": 0.0,
		"max_value": 1.0,
		"frequency": 0.12,
		"phase": 4.25,
		"curve": 1.2,
		"fade_in": 5.2,
		"fade_out": 1.0
	}
}

# Day schedule toggles effects on/off. Adjust values here without touching effect scripts.
const DAY_SCHEDULE := {
	1: {
		"ground": true,
		"voices": false,
		"camera": false,
		"earthquake": false,
		"blind": false,
		"color": false
	},
	2: {
		"ground": true,
		"voices": true,
		"camera": false,
		"earthquake": false,
		"blind": false,
		"color": false
	},
	3: {
		"ground": true,
		"voices": true,
		"camera": true,
		"earthquake": false,
		"blind": false,
		"color": false
	},
	4: {
		"ground": true,
		"voices": true,
		"camera": true,
		"earthquake": true,
		"blind": false,
		"color": false
	},
	5: {
		"ground": true,
		"voices": true,
		"camera": true,
		"earthquake": true,
		"blind": true,
		"color": true
	}
}

static func effect_ids() -> Array[String]:
	var ids: Array[String] = []
	for effect_id in EFFECT_ORDER:
		ids.append(effect_id)
	return ids

static func total_effects() -> int:
	return EFFECT_ORDER.size()

static func effects_for_day(day: int, completed_today: bool = false) -> Array[String]:
	var active_schedule := _resolve_day_schedule(day, completed_today)
	var result: Array[String] = []
	for effect_id in EFFECT_ORDER:
		if active_schedule.get(effect_id, false):
			result.append(effect_id)
	return result

var _time: float = 0.0
var _states: Dictionary = {}
var _snapshot: Dictionary = {}

func _init() -> void:
	for effect_id in EFFECT_ORDER:
		var config: Dictionary = EFFECT_CONFIGS.get(effect_id, {})
		var min_value: float = float(config.get("min_value", 0.0))
		_states[effect_id] = {
			"config": config,
			"activation": 0.0,
			"intensity": min_value
		}
		_snapshot[effect_id] = min_value

func update(delta: float, day: int, completed_today: bool) -> void:
	_time += delta
	var active_effects: Array[String] = _get_active_effects(day, completed_today)
	for effect_id in EFFECT_ORDER:
		var state: Dictionary = _states[effect_id]
		var config: Dictionary = state["config"]
		var activation: float = state["activation"]
		var target_activation: float = 1.0 if active_effects.has(effect_id) else 0.0
		var fade_in := maxf(float(config.get("fade_in", 1.0)), 0.001)
		var fade_out := maxf(float(config.get("fade_out", 1.0)), 0.001)
		var step: float = delta / (fade_in if target_activation > activation else fade_out)
		activation = move_toward(activation, target_activation, step)
		var normalized_wave: float = _evaluate_wave(config)
		var min_value: float = float(config.get("min_value", 0.0))
		var max_value: float = float(config.get("max_value", min_value))
		var wave_target: float = lerpf(min_value, max_value, normalized_wave)
		var intensity: float = lerpf(min_value, wave_target, activation)
		state["activation"] = activation
		state["intensity"] = intensity
		_snapshot[effect_id] = intensity

func snapshot() -> Dictionary:
	return _snapshot.duplicate(true)

func get_effect_state(effect_id: String) -> Dictionary:
	if _states.has(effect_id):
		var state: Dictionary = _states[effect_id]
		return {
			"intensity": _snapshot.get(effect_id, 0.0),
			"activation": state["activation"]
		}
	return {"intensity": 0.0, "activation": 0.0}

func _get_active_effects(day: int, completed_today: bool) -> Array[String]:
	var active_schedule := _resolve_day_schedule(day, completed_today)
	var result: Array[String] = []
	for effect_id in EFFECT_ORDER:
		if active_schedule.get(effect_id, false):
			result.append(effect_id)
	return result

static func _resolve_day_schedule(day: int, completed_today: bool) -> Dictionary:
	var effective_day: int = maxi(day, 1)
	if completed_today:
		effective_day += 1
	return DAY_SCHEDULE.get(effective_day, {})

func _evaluate_wave(config: Dictionary) -> float:
	var frequency: float = float(config.get("frequency", 0.0))
	if frequency <= 0.0:
		return 1.0
	var phase: float = float(config.get("phase", 0.0))
	var curve := maxf(float(config.get("curve", 1.0)), 0.001)
	var normalized := 0.5 + 0.5 * sin((_time * TAU * frequency) + phase)
	if abs(curve - 1.0) > 0.001:
		normalized = pow(normalized, curve)
	return clampf(normalized, 0.0, 1.0)
