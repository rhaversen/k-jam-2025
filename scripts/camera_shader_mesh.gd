extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mat = get_surface_override_material(0)
	mat.set_shader_parameter("stress_level_1", get_node("../Player").is_stressed_1())
	mat.set_shader_parameter("blind", get_node("../Player").blind)
