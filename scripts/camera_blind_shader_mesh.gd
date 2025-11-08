extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mat = material_override
	if mat is ShaderMaterial:
		mat.set_shader_parameter("blind", 0.5 if get_node("../Player").is_stressed_1()["blind"] else 0.0)
