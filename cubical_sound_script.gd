extends AudioStreamPlayer3D

# Node setup: AudioStreamPlayer3D -> this script

var min_distance = 2.0   # distance at which sound is at full volume

func _ready():
	stream = preload("res://sound/earthquake.wav")
	max_distance = 20.0

func _process(delta):
	if playing:
		return

	var listener_pos = get_viewport().get_camera_3d().global_transform.origin
	var distance = global_transform.origin.distance_to(listener_pos)
	
	# Calculate volume_db manually
	var volume_ratio = 1-(clamp(distance, min_distance, max_distance)-min_distance)/(max_distance-min_distance)
	volume_db = linear_to_db(volume_ratio)
	# volume_db = -15 * volume_ratio
	# dddwplay()
	play()
		#wait_time = 0
