extends Node

var current_day: int = 1
var desk_task_ready: bool = false

signal desk_task_flagged
signal day_progressed(new_day: int)

func mark_desk_ready() -> void:
	if desk_task_ready:
		return
	desk_task_ready = true
	emit_signal("desk_task_flagged")
	print("GameState: Desk task ready for day %d." % current_day)

func can_start_new_day() -> bool:
	return desk_task_ready

func start_new_day() -> bool:
	if not desk_task_ready:
		return false
	desk_task_ready = false
	current_day += 1
	emit_signal("day_progressed", current_day)
	print("GameState: Advancing to day %d." % current_day)
	return true

func reset_progress() -> void:
	desk_task_ready = false
	current_day = 1
