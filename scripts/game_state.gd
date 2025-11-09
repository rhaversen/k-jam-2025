extends Node

const SPAWN_ELEVATOR := "elevator"
const SPAWN_DESK := "desk"

var current_day: int = 1
var next_spawn_location: String = SPAWN_ELEVATOR
var desk_spawn_position: Vector3 = Vector3.ZERO
var desk_spawn_ready: bool = false
var desk_spawn_basis: Basis = Basis.IDENTITY
var desk_focus_position: Vector3 = Vector3.ZERO
var desk_focus_basis: Basis = Basis.IDENTITY
var desk_focus_ready: bool = false
var desk_focus_duration: float = 1.0
var desk_minigame_map: Dictionary = {}
var completed_today: bool = false

var _day_music_player: AudioStreamPlayer
var _day_music_path: String = ""
var _minigame_music_player: AudioStreamPlayer
var _minigame_music_path: String = ""

signal desk_task_flagged
signal day_progressed(new_day: int)
signal day_completed(day: int)
signal minigame_started

func _ready() -> void:
	_setup_day_music()
	_setup_minigame_music()

func _setup_day_music() -> void:
	_day_music_player = AudioStreamPlayer.new()
	_day_music_player.name = "DayMusicPlayer"
	_day_music_player.bus = "Master"
	add_child(_day_music_player)
	
	# Set default day music
	set_day_music("res://sound/room-tone-office.mp3")
	print("GameState: Day music system initialized")

func _setup_minigame_music() -> void:
	_minigame_music_player = AudioStreamPlayer.new()
	_minigame_music_player.name = "MinigameMusicPlayer"
	_minigame_music_player.bus = "Master"
	add_child(_minigame_music_player)
	
	# Set default minigame boot sound
	set_minigame_music("res://sound/old-desktop-pc-booting.mp3")
	print("GameState: Minigame music system initialized")

func set_day_music(music_path: String) -> void:
	_day_music_path = music_path
	print("GameState: Loading day music from: %s" % music_path)
	if _day_music_path != "" and ResourceLoader.exists(_day_music_path):
		var stream: AudioStream = load(_day_music_path)
		if stream:
			_day_music_player.stream = stream
			# Enable looping for ambient office sound
			if stream is AudioStreamMP3:
				stream.loop = true
			print("GameState: Day music loaded successfully")
		else:
			push_warning("GameState: Failed to load day music stream")
	else:
		push_warning("GameState: Day music file not found: %s" % music_path)

func set_minigame_music(music_path: String) -> void:
	_minigame_music_path = music_path
	print("GameState: Loading minigame music from: %s" % music_path)
	if _minigame_music_path != "" and ResourceLoader.exists(_minigame_music_path):
		var stream: AudioStream = load(_minigame_music_path)
		if stream:
			_minigame_music_player.stream = stream
			# Minigame sound plays once (no loop)
			if stream is AudioStreamMP3:
				stream.loop = false
			print("GameState: Minigame music loaded successfully")
		else:
			push_warning("GameState: Failed to load minigame music stream")
	else:
		push_warning("GameState: Minigame music file not found: %s" % music_path)

func play_day_music() -> void:
	if _day_music_player and _day_music_player.stream:
		_day_music_player.play()
		print("GameState: Day music started playing: %s" % _day_music_path)
	else:
		push_warning("GameState: Cannot play day music - player or stream is null")

func stop_day_music() -> void:
	if _day_music_player:
		_day_music_player.stop()
		print("GameState: Day music stopped")

func play_minigame_music() -> void:
	if _minigame_music_player and _minigame_music_player.stream:
		_minigame_music_player.play()
		emit_signal("minigame_started")
		print("GameState: Minigame music started: %s" % _minigame_music_path)
	else:
		push_warning("GameState: Cannot play minigame music - player or stream is null")

func stop_minigame_music() -> void:
	if _minigame_music_player:
		_minigame_music_player.stop()

func mark_desk_ready() -> void:
	if completed_today:
		return
	flag_day_complete()
	emit_signal("desk_task_flagged")
	print("GameState: Desk task ready for day %d." % current_day)

func can_start_new_day() -> bool:
	return completed_today

func play_sound_once(sound_path: String, start_time: float = 0.0):
	# Create an AudioStreamPlayer node
	var player := AudioStreamPlayer.new()
	
	# Load the sound
	player.stream = load(sound_path)
	
	# Add it as a child so it can play
	add_child(player)
	
	# Play the sound
	player.play(start_time)

	# Connect to "finished" signal to remove it when done
	player.finished.connect(func():
		player.queue_free()
	)
	
	return player

func play_sound_segment_3d(sound_path: String, position: Vector3, start_time: float = 0.0):
	var player := AudioStreamPlayer3D.new()
	player.stream = load(sound_path)
	player.transform.origin = position  # Set the 3D location
	add_child(player)

	player.play(start_time)
	
	# Connect to "finished" signal to remove it when done
	player.finished.connect(func():
		player.queue_free()
	)
	
	return player
	

func start_new_day() -> bool:
	if not completed_today:
		return false
	current_day += 1
	completed_today = false
	play_day_music()
	emit_signal("day_progressed", current_day)
	print("GameState: Advancing to day %d." % current_day)
	
	if (current_day == 1):
		print("Play sound")
		play_sound_once("res://sound/Elevator 1.wav")
	
	return true

func reset_progress() -> void:
	current_day = 1
	next_spawn_location = SPAWN_ELEVATOR
	completed_today = false
	clear_desk_spawn()

func set_desk_spawn(position: Vector3, target: Vector3) -> void:
	var forward := (target - position)
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var z_axis := -forward
	var x_axis := Vector3.UP.cross(z_axis)
	if x_axis.length_squared() <= 0.0001:
		x_axis = Vector3.RIGHT
	else:
		x_axis = x_axis.normalized()
	var y_axis := z_axis.cross(x_axis).normalized()
	var basis := Basis(x_axis, y_axis, z_axis)
	set_desk_spawn_transform(Transform3D(basis, position))

func set_desk_spawn_transform(transform: Transform3D) -> void:
	desk_spawn_position = transform.origin
	desk_spawn_basis = transform.basis.orthonormalized()
	desk_spawn_ready = true

func clear_desk_spawn() -> void:
	desk_spawn_ready = false
	desk_spawn_position = Vector3.ZERO
	desk_spawn_basis = Basis.IDENTITY
	clear_desk_focus()

func set_next_spawn(location: String) -> void:
	next_spawn_location = location

func should_spawn_at_desk() -> bool:
	return next_spawn_location == SPAWN_DESK and desk_spawn_ready

func set_desk_focus_transform(transform: Transform3D, duration: float) -> void:
	desk_focus_basis = transform.basis.orthonormalized()
	desk_focus_position = transform.origin
	desk_focus_ready = true
	desk_focus_duration = maxf(0.01, duration)

func has_desk_focus() -> bool:
	return desk_focus_ready

func clear_desk_focus() -> void:
	desk_focus_ready = false
	desk_focus_position = Vector3.ZERO
	desk_focus_basis = Basis.IDENTITY
	desk_focus_duration = 1.0

func is_day_complete() -> bool:
	return completed_today

func flag_day_complete() -> void:
	if completed_today:
		return
	completed_today = true
	emit_signal("day_completed", current_day)

func get_minigame_for_day(day: int) -> String:
	return desk_minigame_map.get(day, "")

func get_desktop_script_for_day(day: int) -> String:
	return get_minigame_for_day(day)

func set_minigame_schedule(schedule: Dictionary) -> void:
	desk_minigame_map.clear()
	for day in schedule.keys():
		var path = schedule[day]
		if path is String and path != "":
			desk_minigame_map[day] = path
