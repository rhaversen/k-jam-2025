extends OmniLight3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var flicker_time = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# light_color = Color((9*light_color.r + randf())/10, (9*light_color.g + randf())/10, (9*light_color.b + randf())/10)
	# light_color = Color.from_hsv(1, 1, fmod(light_color.v + randf() / 100, 1.0))
	#light_color = Color.from_hsv(fmod(light_color.h + randf() / 100, 1.0), 1, 1)
	#light_color = Color.from_hsv(fmod(light_color.h + randf() / 100, 1.0), 1, 1)
	flicker_time += delta
	if flicker_time > 0.1:
		var weight = .1
		var g = (1-weight) + weight * randf()
		light_color = Color(g, g, g) # Red
		flicker_time = 0
