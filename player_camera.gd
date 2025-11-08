extends Camera3D

@export var keyboard_look_speed := 1.5
@export var mouse_sensitivity := 0.004

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * mouse_sensitivity
		rotation.x -= event.relative.y * mouse_sensitivity
		_clamp_pitch()

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event.is_action_pressed("ui_accept"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var look_speed := keyboard_look_speed

	# Horizontal rotation (yaw)
	if Input.is_action_pressed("look_right"):
		rotation.y -= look_speed * delta
	if Input.is_action_pressed("look_left"):
		rotation.y += look_speed * delta

	# Vertical rotation (pitch)
	if Input.is_action_pressed("look_down"):
		rotation.x -= look_speed * delta
	if Input.is_action_pressed("look_up"):
		rotation.x += look_speed * delta

	# Clamp pitch so camera doesn't flip
	_clamp_pitch()

func _clamp_pitch() -> void:
	rotation.x = clamp(rotation.x, deg_to_rad(-85), deg_to_rad(85))
