extends MeshInstance3D
# Pulses the emission on the screen material to simulate CRT/office monitor flicker.

@export var min_energy: float = 0.6
@export var max_energy: float = 1.2
@export var speed: float = 8.0

var t: float = 0.0

func _process(delta: float) -> void:
	t += delta * speed
	var energy: float = lerp(min_energy, max_energy, 0.5 + 0.5 * sin(t))
	var mat: StandardMaterial3D = get_active_material(0) as StandardMaterial3D
	if mat:
		mat.emission_enabled = true
		mat.emission_energy_multiplier = energy
