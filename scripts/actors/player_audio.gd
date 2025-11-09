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
	if (!get_parent() || !get_parent().is_stressed_1()["voices"]):
		return
	
	delay -= delta
	if playing || delay > 0:
		return
	delay = 0

	if randf() <= 0.25:
		var index = randi() % sounds.size()
		stream = sounds[index]
		play()
		delay = 10
	else:
		delay = 2
