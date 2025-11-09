extends Node3D
# Elevator that moves between floors

@export var elevator_width: float = 2.0
@export var elevator_depth: float = 2.0
@export var elevator_height: float = 2.5
@export var shaft_height: float = 20.0
@export var move_speed: float = 2.0
@export var door_open_speed: float = 1.5
@export var door_panel_thickness: float = 0.05
@export var doorway_reveal_depth: float = 0.2

var _is_moving: bool = false
var _doors_open: bool = false
var _current_floor: int = 0
var _target_floor: int = 0
var _floors: Array[float] = [0.0, 10.0, 20.0]

var _elevator_car: Node3D
var _left_door: StaticBody3D
var _right_door: StaticBody3D
var _door_open_amount: float = 0.0
var _interaction_area: Area3D
var _player_inside: bool = false
var _player_camera: Camera3D
var _button_body: StaticBody3D
var _button_material: StandardMaterial3D
var _button_enabled: bool = false
var _button_focused: bool = false
var _button_emission_phase: float = 0.0
var _button_blink_speed: float = 1.2
var _button_interaction_area: Area3D
var _button_interaction_inside: bool = false

func setup(width: float, depth: float, height: float) -> void:
	elevator_width = width
	elevator_depth = depth
	elevator_height = height
	_rebuild()

func _ready() -> void:
	_rebuild()
	# Start with doors closed
	_doors_open = false
	_door_open_amount = 0.0
	GameState.play_sound_once("res://sound/Elevator sound.wav", 30.8-3.0)
	
	var tree := get_tree()
	if tree:
		await tree.create_timer(3.0).timeout
	call_deferred("_update_door_positions")
	
	# Only play welcome sound on the very first spawn of the game
	if GameState.is_first_spawn:
		print("🔊 First spawn - playing welcome sound!")
		GameState.play_sound_once("res://sound/welcome.wav", 0.0, 5.0)  # Play welcome.wav from the start, +5 dB louder
		GameState.is_first_spawn = false
	else:
		print("Not first spawn - skipping welcome sound (day %d)" % GameState.current_day)
	
	# Open doors after 1 second
	if tree:
		await tree.create_timer(1.0).timeout
	open_doors()
	call_deferred("_connect_to_game_state")

func _rebuild() -> void:
	_clear_children()
	_build_elevator_shaft()
	_build_elevator_car()

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _build_elevator_shaft() -> void:
	var shaft_mat := StandardMaterial3D.new()
	shaft_mat.albedo_color = Color(0.15, 0.15, 0.15)
	shaft_mat.roughness = 0.9
	
	# Back wall (visual only, no collision)
	var back_wall := _create_mesh_wall(
		Vector3(elevator_width, elevator_height, 0.1),
		shaft_mat,
		Vector3(0, elevator_height * 0.5, -elevator_depth * 0.5 - 0.05)
	)
	back_wall.name = "BackWall"
	add_child(back_wall)

func _build_elevator_car() -> void:
	_elevator_car = Node3D.new()
	_elevator_car.name = "ElevatorCar"
	_elevator_car.position = Vector3(0, 0, 0)
	add_child(_elevator_car)
	
	var wall_thickness := 0.1
	var wall_height := elevator_height
	
	# Materials
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.6, 0.6, 0.65)
	wall_mat.metallic = 0.3
	wall_mat.roughness = 0.4
	
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.5, 0.5, 0.55)
	door_mat.metallic = 0.5
	door_mat.roughness = 0.3
	
	# Floor (visual only, no collision needed)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "Floor"
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(elevator_width, 0.1, elevator_depth)
	floor_mesh.mesh = floor_box
	floor_mesh.material_override = wall_mat
	floor_mesh.position = Vector3(0, -0.05, 0)
	_elevator_car.add_child(floor_mesh)
	
	# Ceiling (visual only)
	var ceiling_mesh := MeshInstance3D.new()
	ceiling_mesh.name = "Ceiling"
	var ceiling_box := BoxMesh.new()
	ceiling_box.size = Vector3(elevator_width, 0.1, elevator_depth)
	ceiling_mesh.mesh = ceiling_box
	ceiling_mesh.material_override = wall_mat
	ceiling_mesh.position = Vector3(0, elevator_height, 0)
	_elevator_car.add_child(ceiling_mesh)
	
	# Left wall (StaticBody3D with mesh and collision)
	var left_wall := StaticBody3D.new()
	left_wall.name = "LeftWall"
	left_wall.position = Vector3(-elevator_width * 0.5 + wall_thickness * 0.5, wall_height * 0.5, 0)
	_elevator_car.add_child(left_wall)
	
	var left_wall_mesh := MeshInstance3D.new()
	var left_wall_box := BoxMesh.new()
	left_wall_box.size = Vector3(wall_thickness, wall_height, elevator_depth)
	left_wall_mesh.mesh = left_wall_box
	left_wall_mesh.material_override = wall_mat
	left_wall.add_child(left_wall_mesh)
	
	var left_wall_collision := CollisionShape3D.new()
	var left_wall_shape := BoxShape3D.new()
	left_wall_shape.size = Vector3(wall_thickness, wall_height, elevator_depth)
	left_wall_collision.shape = left_wall_shape
	left_wall.add_child(left_wall_collision)
	
	# Right wall (StaticBody3D with mesh and collision)
	var right_wall := StaticBody3D.new()
	right_wall.name = "RightWall"
	right_wall.position = Vector3(elevator_width * 0.5 - wall_thickness * 0.5, wall_height * 0.5, 0)
	_elevator_car.add_child(right_wall)
	
	var right_wall_mesh := MeshInstance3D.new()
	var right_wall_box := BoxMesh.new()
	right_wall_box.size = Vector3(wall_thickness, wall_height, elevator_depth)
	right_wall_mesh.mesh = right_wall_box
	right_wall_mesh.material_override = wall_mat
	right_wall.add_child(right_wall_mesh)
	
	var right_wall_collision := CollisionShape3D.new()
	var right_wall_shape := BoxShape3D.new()
	right_wall_shape.size = Vector3(wall_thickness, wall_height, elevator_depth)
	right_wall_collision.shape = right_wall_shape
	right_wall.add_child(right_wall_collision)
	
	# Back wall (StaticBody3D with mesh and collision)
	var back_wall := StaticBody3D.new()
	back_wall.name = "BackWall"
	back_wall.position = Vector3(0, wall_height * 0.5, -elevator_depth * 0.5 + wall_thickness * 0.5)
	_elevator_car.add_child(back_wall)
	
	var back_wall_mesh := MeshInstance3D.new()
	var back_wall_box := BoxMesh.new()
	back_wall_box.size = Vector3(elevator_width, wall_height, wall_thickness)
	back_wall_mesh.mesh = back_wall_box
	back_wall_mesh.material_override = wall_mat
	back_wall.add_child(back_wall_mesh)
	
	var back_wall_collision := CollisionShape3D.new()
	var back_wall_shape := BoxShape3D.new()
	back_wall_shape.size = Vector3(elevator_width, wall_height, wall_thickness)
	back_wall_collision.shape = back_wall_shape
	back_wall.add_child(back_wall_collision)
	
	# Left door (StaticBody3D with mesh and collision)
	var door_width: float = elevator_width * 0.5
	var door_height: float = wall_height - 0.15
	var door_thickness: float = clampf(door_panel_thickness, 0.02, 0.09)
	var door_offset: float = 0.06
	var door_lower_offset: float = 0.1
	
	_left_door = StaticBody3D.new()
	_left_door.name = "LeftDoor"
	_left_door.position = Vector3(-door_width * 0.5, wall_height * 0.5 - door_lower_offset, elevator_depth * 0.5 - door_thickness * 0.5 + door_offset)
	_elevator_car.add_child(_left_door)
	
	var left_door_mesh := MeshInstance3D.new()
	var left_door_box := BoxMesh.new()
	left_door_box.size = Vector3(door_width, door_height, door_thickness)
	left_door_mesh.mesh = left_door_box
	left_door_mesh.material_override = door_mat
	_left_door.add_child(left_door_mesh)
	
	var left_door_collision := CollisionShape3D.new()
	var left_door_shape := BoxShape3D.new()
	left_door_shape.size = Vector3(door_width, door_height, door_thickness)
	left_door_collision.shape = left_door_shape
	_left_door.add_child(left_door_collision)
	
	# Right door (StaticBody3D with mesh and collision)
	_right_door = StaticBody3D.new()
	_right_door.name = "RightDoor"
	_right_door.position = Vector3(door_width * 0.5, wall_height * 0.5 - door_lower_offset, elevator_depth * 0.5 - door_thickness * 0.5 + door_offset)
	_elevator_car.add_child(_right_door)
	
	var right_door_mesh := MeshInstance3D.new()
	var right_door_box := BoxMesh.new()
	right_door_box.size = Vector3(door_width, door_height, door_thickness)
	right_door_mesh.mesh = right_door_box
	right_door_mesh.material_override = door_mat
	_right_door.add_child(right_door_mesh)
	
	var right_door_collision := CollisionShape3D.new()
	var right_door_shape := BoxShape3D.new()
	right_door_shape.size = Vector3(door_width, door_height, door_thickness)
	right_door_collision.shape = right_door_shape
	_right_door.add_child(right_door_collision)
	
	var reveal_depth: float = maxf(doorway_reveal_depth - door_thickness, 0.0)
	if reveal_depth > 0.01:
		var side_width: float = minf(0.12, elevator_width * 0.25)
		var top_height: float = minf(0.18, wall_height * 0.2)
		var reveal_offset_z: float = elevator_depth * 0.5 + reveal_depth * 0.5
		var left_trim: MeshInstance3D = MeshInstance3D.new()
		left_trim.name = "DoorTrimLeft"
		var left_trim_box: BoxMesh = BoxMesh.new()
		left_trim_box.size = Vector3(side_width, wall_height, reveal_depth)
		left_trim.mesh = left_trim_box
		left_trim.material_override = wall_mat
		left_trim.position = Vector3(-elevator_width * 0.5 + side_width * 0.5, wall_height * 0.5, reveal_offset_z)
		_elevator_car.add_child(left_trim)

		var right_trim: MeshInstance3D = MeshInstance3D.new()
		right_trim.name = "DoorTrimRight"
		var right_trim_box: BoxMesh = BoxMesh.new()
		right_trim_box.size = Vector3(side_width, wall_height, reveal_depth)
		right_trim.mesh = right_trim_box
		right_trim.material_override = wall_mat
		right_trim.position = Vector3(elevator_width * 0.5 - side_width * 0.5, wall_height * 0.5, reveal_offset_z)
		_elevator_car.add_child(right_trim)

		var top_trim: MeshInstance3D = MeshInstance3D.new()
		top_trim.name = "DoorTrimTop"
		var top_trim_box: BoxMesh = BoxMesh.new()
		top_trim_box.size = Vector3(elevator_width, top_height, reveal_depth)
		top_trim.mesh = top_trim_box
		top_trim.material_override = wall_mat
		top_trim.position = Vector3(0.0, wall_height - top_height * 0.5, reveal_offset_z)
		_elevator_car.add_child(top_trim)

	# Ceiling light
	var light := OmniLight3D.new()
	light.name = "CeilingLight"
	light.light_color = Color(1.0, 0.95, 0.9)
	light.light_energy = 1.5
	light.omni_range = 8.0
	light.position = Vector3(0, elevator_height - 0.2, 0)
	_elevator_car.add_child(light)

	_create_interaction_area()
	_create_control_button()

func _process(delta: float) -> void:
	if _is_moving:
		var target_y: float = float(_floors[_target_floor])
		var current_y: float = _elevator_car.position.y
		var direction: float = float(sign(target_y - current_y))
		var move_amount: float = direction * move_speed * delta
		
		if abs(target_y - current_y) <= abs(move_amount):
			_elevator_car.position.y = target_y
			_is_moving = false
			_current_floor = _target_floor
			_update_floor_indicator()
			call_deferred("open_doors")
		else:
			_elevator_car.position.y += move_amount
	
	# Animate doors
	if _doors_open and _door_open_amount < 1.0:
		_door_open_amount = min(1.0, _door_open_amount + delta * door_open_speed)
		_update_door_positions()
	elif not _doors_open and _door_open_amount > 0.0:
		_door_open_amount = max(0.0, _door_open_amount - delta * door_open_speed)
		_update_door_positions()

	_update_button_focus()
	_update_button_emission(delta)

func _update_door_positions() -> void:
	if _left_door and _right_door:
		var door_width := elevator_width * 0.5
		var offset := _door_open_amount * door_width * 0.7
		_left_door.position.x = -door_width * 0.5 - offset
		_right_door.position.x = door_width * 0.5 + offset

func _update_floor_indicator() -> void:
	var indicator := get_node_or_null("FloorIndicator")
	if indicator and indicator is Label3D:
		indicator.text = "FLOOR %d" % (_current_floor + 1)

func open_doors() -> void:
	_doors_open = true
	GameState.play_sound_segment_3d("res://sound/Elevator ding.wav", _elevator_car.position)
	GameState.play_sound_segment_3d("res://sound/Elevator dør.wav", _elevator_car.position)

func close_doors() -> void:
	_doors_open = false
	GameState.play_sound_segment_3d("res://sound/Elevator dør.wav", _elevator_car.position)

func close_doors_slowly() -> void:
	close_doors()
	var tree := get_tree()
	if tree:
		await tree.create_timer(1.0 / door_open_speed).timeout

func open_doors_slowly() -> void:
	open_doors()
	var tree := get_tree()
	if tree:
		await tree.create_timer(1.0 / door_open_speed).timeout

func move_to_floor(floor_num: int) -> void:
	if floor_num < 0 or floor_num >= _floors.size():
		return
	if _is_moving:
		return
	
	_target_floor = floor_num
	if _target_floor != _current_floor:
		close_doors()
		var tree := get_tree()
		if tree:
			await tree.create_timer(1.0).timeout
		_is_moving = true

func _create_mesh_wall(size: Vector3, material: StandardMaterial3D, pos: Vector3) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = pos
	return mesh_instance

func _create_interaction_area() -> void:
	_interaction_area = Area3D.new()
	_interaction_area.name = "InteractionArea"
	_interaction_area.position = Vector3(0, elevator_height * 0.5, 0)
	_interaction_area.monitoring = true
	_interaction_area.monitorable = true
	_interaction_area.collision_layer = 1
	_interaction_area.collision_mask = 1

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(elevator_width * 1.6, elevator_height, elevator_depth * 1.6)
	shape.shape = box
	shape.position = Vector3.ZERO
	_interaction_area.add_child(shape)

	_interaction_area.body_entered.connect(_on_interaction_body_entered)
	_interaction_area.body_exited.connect(_on_interaction_body_exited)
	_elevator_car.add_child(_interaction_area)

func _on_interaction_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	_player_inside = true
	print("Elevator ready for new day check.")

	_set_crosshair(true, _button_enabled and _button_focused)

func _on_interaction_body_exited(body: Node) -> void:
	if body.name != "Player":
		return
	_player_inside = false
	print("Elevator interaction cleared.")
	
	var day_ready := typeof(GameState) != TYPE_NIL and GameState and GameState.can_start_new_day()
	if not day_ready:
		close_doors()
		print("Elevator doors closing until desk work is complete.")
	if _button_focused:
		_button_focused = false
		_update_button_visual()
	_set_crosshair(false, false)

func _attempt_start_new_day() -> void:
	if _is_moving:
		return
	if typeof(GameState) == TYPE_NIL or GameState == null:
		print("Elevator: GameState singleton unavailable.")
		return
	if not GameState.can_start_new_day():
		print("Elevator: finish your desk work before leaving.")
		return
	if GameState.start_new_day():
		close_doors()
		GameState.play_sound_segment_3d("res://sound/Elevator sound.wav", _elevator_car.position, 30.8-10.0)
		if (GameState.current_day == 2):
			print("Play sound 1")
			GameState.play_sound_once("res://sound/Elevator 1.wav")

		if (GameState.current_day == 3):
			print("Play sound 2")
			GameState.play_sound_once("res://sound/Elevator 2.wav")
		
		var tree := get_tree()
		if tree:
			await tree.create_timer(10.0).timeout
		print("Elevator departing for day %d." % GameState.current_day)


		_set_button_enabled(false)
		_set_crosshair(false, false)
		GameState.set_next_spawn(GameState.SPAWN_ELEVATOR)
		_schedule_door_reopen()

func _connect_to_game_state() -> void:
	if typeof(GameState) == TYPE_NIL or GameState == null:
		return
	var ready_callable := Callable(self, "_on_desk_task_ready")
	if not GameState.desk_task_flagged.is_connected(ready_callable):
		GameState.desk_task_flagged.connect(ready_callable)
	var day_callable := Callable(self, "_on_day_progressed")
	if not GameState.day_progressed.is_connected(day_callable):
		GameState.day_progressed.connect(day_callable)
	var day_ready := GameState.can_start_new_day()
	_set_button_enabled(day_ready)
	if day_ready:
		open_doors()

func _on_desk_task_ready() -> void:
	open_doors()
	_set_button_enabled(true)
	print("Elevator doors opening. Desk work complete.")

func _on_day_progressed(new_day: int) -> void:
	print("Elevator prep for day %d." % new_day)
	_set_button_enabled(false)

func _schedule_door_reopen(delay: float = 1.0) -> void:
	if delay <= 0.0:
		open_doors()
		return
	var tree := get_tree()
	if not tree:
		open_doors()
		return
	var timer := tree.create_timer(delay)
	timer.timeout.connect(Callable(self, "_on_reopen_timer_timeout"))

func _on_reopen_timer_timeout() -> void:
	open_doors()

func _create_control_button() -> void:
	var panel := StaticBody3D.new()
	panel.name = "ControlPanel"
	panel.position = Vector3(elevator_width * 0.5 - 0.1, elevator_height * 0.5, 0.0)
	panel.rotation_degrees = Vector3(0, -90, 0)
	_elevator_car.add_child(panel)

	var panel_mesh := MeshInstance3D.new()
	var panel_cylinder := CylinderMesh.new()
	panel_cylinder.top_radius = 0.18
	panel_cylinder.bottom_radius = 0.18
	panel_cylinder.height = 0.04
	panel_cylinder.radial_segments = 32
	panel_mesh.rotation_degrees = Vector3(90, 0, 0)
	panel_mesh.mesh = panel_cylinder
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.25, 0.25, 0.28)
	panel_mat.metallic = 0.8
	panel_mat.roughness = 0.2
	panel_mat.clearcoat = 0.6
	panel_mat.clearcoat_gloss = 0.8
	panel_mesh.material_override = panel_mat
	panel.add_child(panel_mesh)

	_button_body = StaticBody3D.new()
	_button_body.name = "StartButton"
	_button_body.position = Vector3(0.0, 0.0, 0.032)
	panel.add_child(_button_body)

	var button_mesh := MeshInstance3D.new()
	var button_cylinder := CylinderMesh.new()
	button_cylinder.top_radius = 0.08
	button_cylinder.bottom_radius = 0.08
	button_cylinder.height = 0.045
	button_cylinder.radial_segments = 32
	button_mesh.mesh = button_cylinder
	button_mesh.rotation_degrees = Vector3(90, 0, 0)
	_button_material = StandardMaterial3D.new()
	_button_material.albedo_color = Color(0.05, 0.05, 0.07)
	_button_material.metallic = 1.0
	_button_material.roughness = 0.08
	_button_material.emission_enabled = true
	_button_material.emission = Color(0.8, 0.05, 0.1)
	_button_material.emission_energy_multiplier = 0.0
	button_mesh.material_override = _button_material
	_button_body.add_child(button_mesh)

	var button_shape := CollisionShape3D.new()
	var button_plate := CylinderShape3D.new()
	button_plate.radius = 0.2
	button_plate.height = 0.08
	button_shape.shape = button_plate
	_button_body.add_child(button_shape)

	_button_interaction_area = Area3D.new()
	_button_interaction_area.name = "ButtonArea"
	_button_interaction_area.monitoring = true
	_button_interaction_area.monitorable = true
	_button_interaction_area.collision_layer = 1
	_button_interaction_area.collision_mask = 1
	var area_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 1.4, 0.8)
	area_shape.shape = box
	area_shape.position = Vector3(0.0, 0.0, 0.0)
	_button_interaction_area.add_child(area_shape)
	_button_interaction_area.body_entered.connect(_on_button_area_entered)
	_button_interaction_area.body_exited.connect(_on_button_area_exited)
	_button_body.add_child(_button_interaction_area)

	_update_button_visual()

func _unhandled_input(event: InputEvent) -> void:
	if not _button_enabled or not _button_focused or not _button_interaction_inside:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_attempt_start_new_day()

func _update_button_focus() -> void:
	var focused := false
	if _button_enabled and _player_inside and _button_body:
		var camera := _get_player_camera()
		if camera and _button_interaction_inside:
			var from := camera.global_transform.origin
			var forward := -camera.global_transform.basis.z
			var to := from + forward * 4.0
			var query := PhysicsRayQueryParameters3D.new()
			query.from = from
			query.to = to
			var exclude: Array = [camera]
			var parent := camera.get_parent()
			if parent:
				exclude.append(parent)
			query.exclude = exclude
			query.collide_with_areas = true
			query.collide_with_bodies = true
			var result := get_world_3d().direct_space_state.intersect_ray(query)
			if result:
				var collider: Object = result.get("collider")
				if collider == _button_body:
					focused = true
	if focused != _button_focused:
		_button_focused = focused
		_update_button_visual()
	_set_crosshair(_player_inside, focused and _button_enabled)

func _update_button_visual() -> void:
	if _button_material == null:
		return
	var color := Color(0.1, 0.1, 0.12)
	if _button_enabled:
		color = Color(0.12, 0.12, 0.16)
		if _button_focused:
			color = Color(0.18, 0.2, 0.26)
	_button_material.albedo_color = color

func _set_button_enabled(enabled: bool) -> void:
	_button_enabled = enabled
	if not enabled and _button_focused:
		_button_focused = false
	if not enabled:
		_button_emission_phase = 0.0
	_update_button_visual()
	if not _player_inside:
		return
	_set_crosshair(_button_enabled, _button_focused and _button_enabled)

func _get_player_camera() -> Camera3D:
	if _player_camera and is_instance_valid(_player_camera):
		return _player_camera
	var player := get_tree().root.find_child("Player", true, false)
	if player and player.has_node("Camera3D"):
		_player_camera = player.get_node("Camera3D") as Camera3D
	return _player_camera

func _update_button_emission(delta: float) -> void:
	if _button_material == null:
		return
	var intensity := 0.0
	if _button_enabled:
		if _button_focused:
			intensity = 1.0
		else:
			_button_emission_phase = fmod(_button_emission_phase + delta * _button_blink_speed * TAU, TAU)
			intensity = 0.5 + 0.5 * sin(_button_emission_phase)
	else:
		_button_emission_phase = 0.0
	_button_material.emission_energy_multiplier = intensity * 3.5

func _set_crosshair(active: bool, highlighted: bool) -> void:
	var camera := _get_player_camera()
	if camera and camera.has_method("set_interaction_hint"):
		camera.set_interaction_hint(active and _button_enabled, highlighted and _button_enabled)

func _on_button_area_entered(body: Node) -> void:
	if body.name != "Player":
		return
	_button_interaction_inside = true
	_set_crosshair(_button_enabled, _button_focused and _button_enabled)

func _on_button_area_exited(body: Node) -> void:
	if body.name != "Player":
		return
	_button_interaction_inside = false
	_button_focused = false
	_update_button_visual()
	_set_crosshair(false, false)
