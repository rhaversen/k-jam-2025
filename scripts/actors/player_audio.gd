extends AudioStreamPlayer3D

var sounds = []

# Called when the node enters the scene tree for the first time.
func _ready():
	sounds = [
		preload("res://sound/get_back_to_work.wav"),
		preload("res://sound/better.wav"),
		preload("res://sound/more.wav")
	]
	volume_db = -15

var delay = 10

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:	
	var parent_player := get_parent()
	if parent_player == null:
		return
	var voices_intensity: float = maxf(float(parent_player.is_stressed_1().get("voices", 0.0)), 0.0)
	if voices_intensity <= 0.0:
		return
	
	delay -= delta
	if playing || delay > 0:
		return
	delay = 0

	var rate: float = maxf(voices_intensity, 0.0)
	var trigger_probability: float = clampf(1.0 - exp(-rate), 0.0, 0.98)
	if randf() <= trigger_probability:
		var index = randi() % sounds.size()
		stream = sounds[index]
		play()
		delay = maxf(0.4, 10.0 / (1.0 + rate * 3.0))
	else:
		delay = maxf(0.2, 4.0 / (1.0 + rate))
