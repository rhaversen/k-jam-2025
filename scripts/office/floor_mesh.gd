extends MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mat := material_override
	if not (mat is ShaderMaterial):
		return
	var player := get_node_or_null("../../../Player")
	if player == null:
		return
	var ground_intensity: float = float(player.is_stressed_1().get("ground", 0.0))
	(mat as ShaderMaterial).set_shader_parameter("stress_level_1", ground_intensity)
