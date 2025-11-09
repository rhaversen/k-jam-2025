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

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_inside = false

func _process(delta):
	get_tree().root.get_node("./Main/Orb").position = camera_target_position
		
	if player_inside and not _is_transitioning and Input.is_action_just_pressed("ui_accept"):
		if camera == null:
			return
		_is_transitioning = true
		var tween = get_tree().create_tween()

		camera.frozen = true
		
		var target_transform = camera.global_transform.looking_at(camera_target_position, Vector3.UP)
		if typeof(GameState) != TYPE_NIL and GameState:
			var final_transform := Transform3D(target_transform.basis, camera_target_position)
			GameState.set_desk_focus_transform(final_transform, camera_move_duration)
		
		# Tween the camera's rotation (basis) over 1 second
		tween.tween_property(
			camera, "global_transform:basis",
			target_transform.basis, camera_move_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
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

func _on_tween_finished():
	_is_transitioning = false
	print("✅ switching sceens.")
	get_tree().change_scene_to_file(target_scene)
