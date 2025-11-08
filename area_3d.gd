extends Area3D

@export var target_scene : String = "res://Bootscreen.tscn"
var player_inside := false
@export var camera_node_path : NodePath = "../Player/Camera3D"  # Path from this node to the camera
@export var camera_target_position : Vector3 = Vector3(0, 2.9, -1.8)  # World position
@export var camera_move_duration : float = 1.0

@onready var camera : Camera3D = get_node(camera_node_path)

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
	if player_inside and Input.is_action_just_pressed("ui_accept"):
		var tween = get_tree().create_tween()

		tween.tween_property(
			camera,
			"global_transform:origin",
			camera_target_position,
			camera_move_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)   # easing direction

		tween.tween_callback(_on_tween_finished)
		#tween.finished.connect(Callable(self, "_on_tween_finished").bind(tween))
		# tween.finished.tween_callback(_on_tween_finished)
		# tween.finished.bind(Callable(self, "_on_tween_finished"))

func _on_tween_finished():
	print("✅ switching sceens.")
	get_tree().change_scene_to_file(target_scene)
