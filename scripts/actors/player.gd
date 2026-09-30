extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed: float = 2.0
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration: float = 75.0

var target_velocity: Vector3 = Vector3.ZERO

var _stress_system: StressEffectSystem
static var _stress_snapshot: Dictionary = {}

func _init() -> void:
	_initialize_stress_snapshot()

func _ready() -> void:
	_stress_system = StressEffectSystem.new()
	_stress_snapshot = _stress_system.snapshot()

func _physics_process(delta: float) -> void:
	_update_stress_effects(delta)

	# We create a local variable to store the input direction.
	var direction := Vector3.ZERO
	
	# We check for each move input and update the direction accordingly.
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z -= 1
	if Input.is_action_pressed("move_forward"):
		direction.z += 1
		
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		# Setting the basis property will affect the rotation of the node.
		# $Pivot.basis = Basis.looking_at(direction)

	var cam = $Camera3D
	# Rotate input direction by the player’s Y rotation (yaw)
	var forward = -cam.global_transform.basis.z
	forward.y = 0
	if forward.length_squared() > 0:
		forward = forward.normalized()
	var right = cam.global_transform.basis.x
	right.y = 0
	if right.length_squared() > 0:
		right = right.normalized()
	var move_dir = Vector3.ZERO
	if direction != Vector3.ZERO:
		# Use horizontal forward/right so look pitch doesn't affect speed.
		move_dir = (right * direction.x + forward * direction.z).normalized()

	# Ground Velocity
	target_velocity.x = move_dir.x * speed
	target_velocity.z = move_dir.z * speed

	# Vertical Velocity
	if is_on_floor():
		target_velocity.y = 0.0
	else:
		target_velocity.y -= fall_acceleration * delta

	# Moving the Character
	velocity = target_velocity
	move_and_slide()

func is_stressed_1() -> Dictionary:
	return _stress_snapshot

func get_stress_effect_intensity(effect_id: String) -> float:
	return _stress_snapshot.get(effect_id, 0.0)

func get_stress_effect_state(effect_id: String) -> Dictionary:
	if _stress_system == null:
		return {"intensity": 0.0, "activation": 0.0}
	return _stress_system.get_effect_state(effect_id)

func _update_stress_effects(delta: float) -> void:
	if _stress_system == null:
		return
	var day := 1
	var completed := false
	if typeof(GameState) != TYPE_NIL and GameState:
		day = GameState.current_day
		completed = GameState.completed_today
	_stress_system.update(delta, day, completed)
	_stress_snapshot = _stress_system.snapshot()

func _initialize_stress_snapshot() -> void:
	if _stress_snapshot.is_empty():
		for effect_id in StressEffectSystem.effect_ids():
			var config: Dictionary = StressEffectSystem.EFFECT_CONFIGS.get(effect_id, {})
			_stress_snapshot[effect_id] = float(config.get("min_value", 0.0))
