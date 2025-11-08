extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 2
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75

static var blind = 0.0
static var stressed_1 := false
static func is_stressed_1() -> bool:
	return stressed_1

var target_velocity = Vector3.ZERO
	
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
		
	if Input.is_action_pressed("stress"):
		stressed_1 = true
		blind = 0.5
		
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
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# Moving the Character
	velocity = target_velocity
	move_and_slide()
