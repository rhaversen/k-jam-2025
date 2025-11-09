extends MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mat = material_override
	if mat is ShaderMaterial:
		mat.set_shader_parameter("stress_level_1", get_node("../../../Player").is_stressed_1()["ground"])
