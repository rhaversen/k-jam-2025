extends Node3D
# Simple static player controller (for sitting view).
# Compatible with Godot 4.5.1.

@onready var cam: Camera3D = get_node_or_null("Camera3D")

func _ready() -> void:
	if cam:
		print("PlayerController: Camera found and initialized.")
	else:
		push_warning("⚠️ PlayerController: Camera3D not found under Player node. Check your scene hierarchy.")

func _unhandled_input(event: InputEvent) -> void:
	# Disable movement — only allow looking around if we have a camera
	if not cam:
		return

	# Optional: enable mouse look if you want to test it later
	if event is InputEventMouseMotion and Input.is_action_pressed("ui_focus_next"):
		rotate_y(deg_to_rad(-event.relative.x * 0.1))
		cam.rotate_x(deg_to_rad(-event.relative.y * 0.1))
		cam.rotation_degrees.x = clamp(cam.rotation_degrees.x, -60, 60)
