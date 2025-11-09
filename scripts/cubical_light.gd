extends Node
# Generic light flicker script that can be attached to any Light3D node.
# Works with OmniLight3D, SpotLight3D, DirectionalLight3D, etc.

@export var flicker_interval: float = 0.03
@export var flicker_weight: float = 0.05
@export var base_color: Color = Color(1.0, 1.0, 1.0)
@export var base_energy: float = 1.0
@export_range(0.0, 1.0, 0.01) var disrepair_factor: float:
	set(value):
		set_disrepair_factor(value)
	get:
		return _disrepair_factor

var flicker_time: float = 0.0
var light_node: Light3D = null
var blackout_time: float = 0.0
var is_blacked_out: bool = false
var next_blackout_in: float = 0.0
var blackout_duration: float = 0.0
var is_flickering: bool = false
var flicker_burst_time: float = 0.0
var flicker_burst_duration: float = 0.0
var next_flicker_burst_in: float = 0.0
var _disrepair_factor: float = 1.0
var _blackout_enabled: bool = true
var _flicker_enabled: bool = true
var _settings_dirty: bool = true
var _rng := RandomNumberGenerator.new()

func set_disrepair_factor(value: float) -> void:
	var clamped := clampf(value, 0.0, 1.0)
	if is_equal_approx(clamped, _disrepair_factor):
		_disrepair_factor = clamped
		return
	_disrepair_factor = clamped
	_settings_dirty = true
	if light_node:
		_apply_disrepair_settings()

func _ready() -> void:
	var parent = get_parent()
	if parent is Light3D:
		light_node = parent
		base_color = light_node.light_color
		base_energy = light_node.light_energy
		_seed_rng()
		_apply_disrepair_settings()
	else:
		push_error("cubical_light.gd must be a child of a Light3D node")

func _schedule_next_blackout() -> void:
	if not _blackout_enabled or _rng == null:
		next_blackout_in = INF
		blackout_duration = 0.0
		return
	var min_interval: float = lerp(14.0, 0.6, _disrepair_factor)
	var max_interval: float = lerp(32.0, 2.6, _disrepair_factor)
	if max_interval <= min_interval:
		max_interval = min_interval + 0.1
	next_blackout_in = _rng.randf_range(min_interval, max_interval)
	var min_duration: float = lerp(0.05, 0.5, _disrepair_factor)
	var max_duration: float = lerp(0.4, 3.0, _disrepair_factor)
	if max_duration <= min_duration:
		max_duration = min_duration + 0.05
	blackout_duration = _rng.randf_range(min_duration, max_duration)

func _schedule_next_flicker_burst() -> void:
	if not _flicker_enabled or _rng == null:
		next_flicker_burst_in = INF
		flicker_burst_duration = 0.0
		return
	var min_interval: float = lerp(5.0, 0.18, _disrepair_factor)
	var max_interval: float = lerp(11.0, 0.9, _disrepair_factor)
	if max_interval <= min_interval:
		max_interval = min_interval + 0.05
	next_flicker_burst_in = _rng.randf_range(min_interval, max_interval)
	var min_duration: float = lerp(0.4, 0.9, _disrepair_factor)
	var max_duration: float = lerp(1.5, 3.8, _disrepair_factor)
	if max_duration <= min_duration:
		max_duration = min_duration + 0.05
	flicker_burst_duration = _rng.randf_range(min_duration, max_duration)

func _process(delta: float) -> void:
	if not light_node:
		return

	if _settings_dirty:
		_apply_disrepair_settings()

	if _blackout_enabled and next_blackout_in < INF:
		next_blackout_in -= delta
	if _flicker_enabled and next_flicker_burst_in < INF:
		next_flicker_burst_in -= delta

	# Handle blackouts (complete light failure)
	if is_blacked_out:
		blackout_time += delta
		if blackout_time >= blackout_duration:
			is_blacked_out = false
			blackout_time = 0.0
			_schedule_next_blackout()
		else:
			light_node.light_energy = 0.0
			return
	elif _blackout_enabled and next_blackout_in <= 0.0:
		is_blacked_out = true
		blackout_time = 0.0
		return

	# Handle flicker bursts (intermittent flickering)
	if is_flickering:
		flicker_burst_time += delta
		if flicker_burst_time >= flicker_burst_duration:
			is_flickering = false
			flicker_burst_time = 0.0
			_schedule_next_flicker_burst()
			# Reset to steady light
			light_node.light_color = base_color
			light_node.light_energy = base_energy
		else:
			# Active flickering
			flicker_time += delta
			if flicker_time > flicker_interval:
				var g = (1.0 - flicker_weight) + flicker_weight * _rng.randf()
				light_node.light_color = Color(g, g, g)
				light_node.light_energy = base_energy * g
				flicker_time = 0.0
	elif _flicker_enabled and next_flicker_burst_in <= 0.0:
		is_flickering = true
		flicker_burst_time = 0.0
		if _should_emit_sound():
			var parent_node := get_parent()
			if parent_node:
				var grand_parent := parent_node.get_parent()
				if grand_parent is Node3D:
					GameState.play_sound_segment_3d("res://sound/Lysrør pling.wav", (grand_parent as Node3D).global_position, 23.0)
	else:
		# Steady light (no flickering)
		light_node.light_color = base_color
		light_node.light_energy = base_energy

func _apply_disrepair_settings() -> void:
	if not light_node:
		return
	_settings_dirty = false
	_flicker_enabled = _disrepair_factor > 0.02
	_blackout_enabled = _disrepair_factor > 0.35
	if _flicker_enabled:
		flicker_interval = float(lerp(0.03, 0.005, _disrepair_factor))
		flicker_weight = float(lerp(0.05, 0.65, _disrepair_factor))
		_schedule_next_flicker_burst()
	else:
		next_flicker_burst_in = INF
		is_flickering = false
		flicker_burst_time = 0.0
		light_node.light_color = base_color
		light_node.light_energy = base_energy
	if _blackout_enabled:
		_schedule_next_blackout()
	else:
		next_blackout_in = INF
		is_blacked_out = false
		blackout_time = 0.0
		light_node.light_color = base_color
		light_node.light_energy = base_energy

func _seed_rng() -> void:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
	var node_path := ""
	if light_node:
		node_path = String(light_node.get_path())
	var day := 1
	if typeof(GameState) != TYPE_NIL and GameState:
		day = GameState.current_day
	var seed_str := "%s|%d|%d" % [node_path, day, get_instance_id()]
	var hashed: int = abs(int(hash(seed_str)))
	if hashed == 0:
		hashed = 1
	_rng.seed = hashed

func _should_emit_sound() -> bool:
	if _disrepair_factor < 0.25:
		return false
	if typeof(GameState) == TYPE_NIL or not GameState:
		return false
	return true
