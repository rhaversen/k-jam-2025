extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 2
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75

static var stress_pressed = false

static var stressed_1_var = false
static var stressed_1 := {"blind": false, "color": false, "camera": false, "earthquake": false, "ground": false, "voices": false}
static var stressed_1_duration := {"blind": 0.0, "color": 0.0, "camera": 0.0, "earthquake": 0.0, "ground": 0.0, "voices": 0.0}
static var stressed_1_dict := {"blind": false, "color": false, "camera": false, "earthquake": false, "ground": false, "voices": false}
static func is_stressed_1() -> Dictionary:
	return stressed_1_dict
	
static var stressed_2_var = false
static var stressed_2 := {"blind": false, "color": false, "camera": false, "earthquake": false, "ground": false}
static var stressed_2_duration := {"blind": 0.0, "color": 0.0, "camera": 0.0, "earthquake": 0.0, "ground": 0.0}
static var stressed_2_dict := {"blind": false, "color": false, "camera": false, "earthquake": false, "ground": false}
static func is_stressed_2() -> Dictionary:
	return stressed_2_dict

var target_velocity = Vector3.ZERO

func check_dict(delta: float, event: String) -> void:
	if stressed_1_dict[event]:
		stressed_1_duration[event] -= delta
		if stressed_1_duration[event] <= 0:
			stressed_1_duration[event] = 0.0
			stressed_1_dict[event] = false
	
	if stressed_1[event] && !stressed_1_dict[event]:
		var roll_value = randi_range(0, 100)
		if roll_value == 0:
			stressed_1_dict[event] = true
			stressed_1_duration[event] = randf_range(1,10)
		
	
func _physics_process(delta: float) -> void:
	# We create a local variable to store the input direction.
	var direction = Vector3.ZERO
	
	# We check for each move input and update the direction accordingly.
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z -= 1
	if Input.is_action_pressed("move_forward"):
		direction.z += 1
		
	#if Input.is_action_just_pressed("stress"):
		#if !stressed_1_var && !stress_pressed:
			#stressed_1["blind"] = true
			#stressed_1["camera"] = true
			#stressed_1["color"] = true
			#stressed_1["earthquake"] = true
			#stressed_1["ground"] = true
			#stress_pressed = true
		#else:
			#stressed_2["blind"] = true
	
	var current_day = GameState.current_day;
	if GameState.completed_today:
		current_day += 1;
	
	if current_day >= 1:
		stressed_1["ground"] = true;
	if current_day >= 2:
		stressed_1["voices"] = true;
	if current_day >= 3:
		stressed_1["camera"] = true;
	if current_day >= 4:
		stressed_1["blind"] = true;
		stressed_1["color"] = true;
	
	check_dict(delta, "color")
	check_dict(delta, "blind")
	check_dict(delta, "camera")
	check_dict(delta, "earthquake")
	check_dict(delta, "ground")
	
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
