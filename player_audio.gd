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

var delay = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	delay -= delta
	if playing || delay > 0:
		return
	delay = 0

	if randf() <= 0.25:
		var index = randi() % sounds.size()
		stream = sounds[index]
		play()
	else:
		delay = 2
