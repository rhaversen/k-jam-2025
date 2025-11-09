extends MeshInstance3D
# Pulses the emission on the screen material to simulate CRT/office monitor flicker.

@export var min_energy: float = 0.85
@export var max_energy: float = 1.08
@export var speed: float = 3.0
@export var base_light_energy: float = 0.6
@export var random_variation: bool = true

var t: float = 0.0
var screen_light: Light3D = null
var noise_offset: float = 0.0

func _ready() -> void:
	# Find the light child node
	for child in get_children():
		if child is Light3D:
			screen_light = child
			break
	
	# Random offset for variation between monitors
	noise_offset = randf() * 100.0

func _process(delta: float) -> void:
	t += delta * speed
	
	# Combine sine wave with random noise for more organic flicker
	var base_flicker: float = 0.5 + 0.5 * sin(t + noise_offset)
	var energy: float
	
	if random_variation:
		var noise: float = (sin(t * 3.7) * 0.3 + cos(t * 5.3) * 0.2) * 0.15
		energy = lerp(min_energy, max_energy, base_flicker + noise)
	else:
		energy = lerp(min_energy, max_energy, base_flicker)
	
	# Update screen emission
	var mat: StandardMaterial3D = get_active_material(0) as StandardMaterial3D
	if mat:
		mat.emission_enabled = true
		mat.emission_energy_multiplier = energy * 3.5
	
	# Update light energy to match
	if screen_light:
		screen_light.light_energy = base_light_energy * energy
