extends Node

func load_day(day: int) -> void:
	print("Making map")
	var main = preload("res://node_3d.tscn")
	var level_scene = main.instantiate() as Node3D
	level_scene.is_task_solved = false
	level_scene.day = day   
	get_tree().current_scene.add_child(level_scene)
	
	print("Loading day: ", day)
	match day:
		0:
			pass
		_:
			pass
	
# Optionally unload a level
func unload_day(day: int) -> void:
	#if level_instance:
		#level_instance.queue_free()
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_day(0)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
