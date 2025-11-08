extends Control


const FOOTSTEPS_IN_PATH := "res://sound/boss_walk_in.wav"
const BOSS_SCOLD_PATH := "res://sound/boss_scold.wav"
const FOOTSTEPS_OUT_PATH := "res://sound/boss_walk_out.wav"

@onready var red_backdrop: ColorRect = $RedBackdrop
@onready var footsteps_in_player: AudioStreamPlayer = $Audio/BossFootstepsIn
@onready var boss_scold_player: AudioStreamPlayer = $Audio/BossScold
@onready var footsteps_out_player: AudioStreamPlayer = $Audio/BossFootstepsOut


func _ready() -> void:
	if red_backdrop:
		red_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		red_backdrop.color = Color(0.95, 0.0, 0.0, 1.0)
		var tween := create_tween()
		if tween:
			tween.tween_property(red_backdrop, "color", Color(0.0, 0.0, 0.0, 1.0), 2.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	_setup_audio_players()
	_play_failure_sequence()


func _setup_audio_players() -> void:
	_assign_stream(footsteps_in_player, FOOTSTEPS_IN_PATH)
	_assign_stream(boss_scold_player, BOSS_SCOLD_PATH)
	_assign_stream(footsteps_out_player, FOOTSTEPS_OUT_PATH)


func _assign_stream(player: AudioStreamPlayer, resource_path: String) -> void:
	if not player:
		return
	if ResourceLoader.exists(resource_path):
		var stream: AudioStream = ResourceLoader.load(resource_path)
		if stream:
			player.stream = stream
		else:
			push_warning("Failed to load audio asset: %s" % resource_path)
	else:
		push_warning("Missing audio asset: %s" % resource_path)


func _play_failure_sequence() -> void:
	var tree: SceneTree = get_tree()
	if not tree:
		_start_boss_scold()
		return
	var delay_timer := tree.create_timer(0.25)
	delay_timer.timeout.connect(Callable(self, "_start_footsteps_in"), Object.CONNECT_ONE_SHOT)


func _start_footsteps_in() -> void:
	if footsteps_in_player and footsteps_in_player.stream:
		_connect_finished_signal(footsteps_in_player, "_on_footsteps_in_finished")
		footsteps_in_player.play()
	else:
		_on_footsteps_in_finished()


func _on_footsteps_in_finished() -> void:
	_start_boss_scold()


func _start_boss_scold() -> void:
	if boss_scold_player and boss_scold_player.stream:
		_connect_finished_signal(boss_scold_player, "_on_boss_scold_finished")
		boss_scold_player.play()
	else:
		_on_boss_scold_finished()


func _on_boss_scold_finished() -> void:
	_start_footsteps_out()


func _start_footsteps_out() -> void:
	if footsteps_out_player and footsteps_out_player.stream:
		footsteps_out_player.play()
	else:
		push_warning("Missing boss exit footsteps audio; sequence ended without playback.")


func _connect_finished_signal(player: AudioStreamPlayer, method_name: String) -> void:
	if not player:
		return
	var callable := Callable(self, method_name)
	if player.finished.is_connected(callable):
		player.finished.disconnect(callable)
	player.finished.connect(callable, Object.CONNECT_ONE_SHOT)
