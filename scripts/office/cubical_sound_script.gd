extends AudioStreamPlayer3D

# Node setup: AudioStreamPlayer3D -> this script

var min_distance = 2.0   # distance at which sound is at full volume

func _ready():
	stream = preload("res://sound/earthquake.wav")
	max_distance = 20.0
	

func _process(_delta):
	if playing:
		return

	var player := get_node_or_null("../../Player")
	if player == null:
		return
	var quake_intensity: float = maxf(float(player.is_stressed_1().get("earthquake", 0.0)), 0.0)
	if quake_intensity <= 0.0:
		return
	var trigger_probability: float = clampf(1.0 - exp(-quake_intensity), 0.0, 1.0)
	if randf() > trigger_probability:
		return
	var listener_pos = get_viewport().get_camera_3d().global_transform.origin
	var distance = global_transform.origin.distance_to(listener_pos)
	var volume_ratio = 1.0 - (clamp(distance, min_distance, max_distance) - min_distance) / (max_distance - min_distance)
	var volume_scale: float = clampf(quake_intensity, 0.0, 1.5)
	volume_ratio = clampf(volume_ratio * min(volume_scale, 1.0), 0.0, 1.0)
	volume_db = linear_to_db(volume_ratio)
	play()
