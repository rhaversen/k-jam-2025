extends Area3D

@export var target_scene : String = "res://scenes/Bootscreen.tscn"
var player_inside := false
@export var camera_node_path : NodePath = "../Player/Camera3D"  # Path from this node to the camera
@export var camera_target_position : Vector3 = Vector3(0, 0, 0)  # World position
@export var camera_target_rotation : Vector3 = Vector3(0, 0, 0)  # World position
@export var camera_move_duration : float = 1.0
@export var marks_task_ready: bool = false

@onready var camera : Camera3D = get_node(camera_node_path)
var _is_transitioning: bool = false

func _ready():
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_inside = true
		var day_locked := typeof(GameState) != TYPE_NIL and GameState and GameState.is_day_complete()
		_set_crosshair(not day_locked, false)

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_inside = false
		_set_crosshair(false, false)

func _process(delta):
	var orb := get_tree().root.get_node_or_null("./Main/Orb")
	if orb:
		orb.position = camera_target_position

	var day_locked := typeof(GameState) != TYPE_NIL and GameState and GameState.is_day_complete()
	if not player_inside:
		return
	if _is_transitioning or day_locked:
		_set_crosshair(false, false)
	else:
		_set_crosshair(true, _can_start_transition())

func _unhandled_input(event: InputEvent) -> void:
	if not _can_start_transition():
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	_start_transition()

func _on_tween_finished():
	_is_transitioning = false
	print("✅ switching sceens.")
	get_tree().change_scene_to_file(target_scene)

func _can_start_transition() -> bool:
	if not player_inside or _is_transitioning:
		return false
	if camera == null:
		return false
	if typeof(GameState) != TYPE_NIL and GameState and GameState.is_day_complete():
		return false
	var forward := -camera.global_transform.basis.z
	if forward.length_squared() <= 0.0001:
		return false
	var to_target := camera_target_position - camera.global_transform.origin
	if to_target.length_squared() <= 0.0001:
		return false
	forward = forward.normalized()
	to_target = to_target.normalized()
	return forward.dot(to_target) >= 0.75

func _start_transition() -> void:
	if typeof(GameState) != TYPE_NIL and GameState and GameState.is_day_complete():
		return
	_is_transitioning = true
	if camera == null:
		return
	_set_crosshair(false, false)
	var tween := get_tree().create_tween()
	camera.frozen = true
	var target_transform := camera.global_transform.looking_at(camera_target_position, Vector3.UP)
	if typeof(GameState) != TYPE_NIL and GameState:
		var final_transform := Transform3D(target_transform.basis, camera_target_position)
		GameState.set_desk_focus_transform(final_transform, camera_move_duration)
	tween.tween_property(
		camera,
		"global_transform:basis",
		target_transform.basis,
		camera_move_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel()
	tween.tween_property(
		camera,
		"global_transform:origin",
		camera_target_position,
		camera_move_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel()
	tween.tween_property(
		camera,
		"rotation_degrees",
		camera_target_rotation,
		camera_move_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_on_tween_finished)

func _set_crosshair(active: bool, highlighted: bool) -> void:
	if camera and camera.has_method("set_interaction_hint"):
		camera.set_interaction_hint(active, highlighted)
