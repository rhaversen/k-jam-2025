extends Camera3D

@export var keyboard_look_speed := 1.5
@export var mouse_sensitivity := 0.004

@export var frozen := false

const CROSSHAIR_SIZE := Vector2(6, 6)
const CROSSHAIR_COLOR_DEFAULT := Color(1.0, 1.0, 1.0, 0.9)
const CROSSHAIR_COLOR_HIGHLIGHT := Color(1.0, 0.68, 0.2, 0.95)

var _crosshair_layer: CanvasLayer
var _crosshair_rect: ColorRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_create_crosshair()
	set_interaction_hint(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * mouse_sensitivity
		rotation.x -= event.relative.y * mouse_sensitivity
		_clamp_pitch()

	#if event.is_action_pressed("ui_cancel"):
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#elif event.is_action_pressed("ui_accept"):
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

var drift = Vector2(0.0, 0.0);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var look_speed := keyboard_look_speed
	
	if frozen:
		return

	if get_parent().is_stressed_1()["camera"]:
		if randi_range(0, 100) < 15:
			drift.x += 0.1 * look_speed * delta
		if randi_range(0, 100) < 15:
			drift.y += 0.1 * look_speed * delta
		if randi_range(0, 100) < 15:
			drift.x -= 0.1 * look_speed * delta
		if randi_range(0, 100) < 15:
			drift.y -= 0.1 * look_speed * delta
			
		rotation.x += drift.x
		rotation.y += drift.y
		
		if abs(drift.x) > 1 || abs(drift.y) > 1:
			drift.x = 0
			drift.y = 0
	else:
		drift.x = 0
		drift.y = 0

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

func _create_crosshair() -> void:
	if _crosshair_layer != null:
		return
	_crosshair_layer = CanvasLayer.new()
	_crosshair_layer.layer = 50
	add_child(_crosshair_layer)

	var root := Control.new()
	root.name = "CrosshairRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair_layer.add_child(root)

	_crosshair_rect = ColorRect.new()
	_crosshair_rect.name = "Crosshair"
	_crosshair_rect.custom_minimum_size = CROSSHAIR_SIZE
	_crosshair_rect.color = CROSSHAIR_COLOR_DEFAULT
	_crosshair_rect.visible = false
	_crosshair_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair_rect.anchor_left = 0.5
	_crosshair_rect.anchor_right = 0.5
	_crosshair_rect.anchor_top = 0.5
	_crosshair_rect.anchor_bottom = 0.5
	_crosshair_rect.offset_left = -CROSSHAIR_SIZE.x * 0.5
	_crosshair_rect.offset_right = CROSSHAIR_SIZE.x * 0.5
	_crosshair_rect.offset_top = -CROSSHAIR_SIZE.y * 0.5
	_crosshair_rect.offset_bottom = CROSSHAIR_SIZE.y * 0.5
	root.add_child(_crosshair_rect)

func set_interaction_hint(active: bool, highlighted: bool = false) -> void:
	if _crosshair_rect == null:
		return
	_crosshair_rect.visible = active
	if not active:
		return
	_crosshair_rect.color = CROSSHAIR_COLOR_HIGHLIGHT if highlighted else CROSSHAIR_COLOR_DEFAULT
