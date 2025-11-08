extends Node3D
# Elevator that moves between floors

@export var elevator_width: float = 2.0
@export var elevator_depth: float = 2.0
@export var elevator_height: float = 2.5
@export var shaft_height: float = 20.0
@export var move_speed: float = 2.0
@export var door_open_speed: float = 1.5

var _is_moving: bool = false
var _doors_open: bool = false
var _current_floor: int = 0
var _target_floor: int = 0
var _floors: Array[float] = [0.0, 10.0, 20.0]

var _elevator_car: Node3D
var _left_door: StaticBody3D
var _right_door: StaticBody3D
var _door_open_amount: float = 0.0

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
	call_deferred("_update_door_positions")
	# Open doors after 1 second
	await get_tree().create_timer(1.0).timeout
	open_doors()

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
	var door_width := elevator_width * 0.5
	var door_height := wall_height - 0.2
	var door_thickness := 0.1
	
	_left_door = StaticBody3D.new()
	_left_door.name = "LeftDoor"
	_left_door.position = Vector3(-door_width * 0.5, wall_height * 0.5, elevator_depth * 0.5)
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
	_right_door.position = Vector3(door_width * 0.5, wall_height * 0.5, elevator_depth * 0.5)
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
	
	# Ceiling light
	var light := OmniLight3D.new()
	light.name = "CeilingLight"
	light.light_color = Color(1.0, 0.95, 0.9)
	light.light_energy = 1.5
	light.omni_range = 8.0
	light.position = Vector3(0, elevator_height - 0.2, 0)
	_elevator_car.add_child(light)

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

func close_doors() -> void:
	_doors_open = false

func close_doors_slowly() -> void:
	close_doors()
	await get_tree().create_timer(1.0 / door_open_speed).timeout

func open_doors_slowly() -> void:
	open_doors()
	await get_tree().create_timer(1.0 / door_open_speed).timeout

func move_to_floor(floor: int) -> void:
	if floor < 0 or floor >= _floors.size():
		return
	if _is_moving:
		return
	
	_target_floor = floor
	if _target_floor != _current_floor:
		close_doors()
		await get_tree().create_timer(1.0).timeout
		_is_moving = true

func _create_mesh_wall(size: Vector3, material: StandardMaterial3D, pos: Vector3) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = pos
	return mesh_instance
