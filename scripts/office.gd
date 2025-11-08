extends Node3D
# High-level office builder that spawns cubicle rows and shared lighting.

const DropCeiling := preload("res://scripts/drop_ceiling.gd")
const Cubicle := preload("res://scripts/cubicle.gd")
const Elevator := preload("res://scripts/elevator.gd")
const ELEVATOR_WALL_NORTH := "north"
const ELEVATOR_WALL_EAST := "east"
const ELEVATOR_WALL_SOUTH := "south"
const ELEVATOR_WALL_WEST := "west"

@export var grid_rows: int = 3
@export var grid_columns: int = 5
@export var cubicle_width: float = 4.0
@export var cubicle_depth: float = 3.0
@export var aisle_width: float = 6.0
@export var wall_thickness: float = 0.06
@export var perimeter_wall_height: float = 2.8
@export var perimeter_wall_thickness: float = 0.2
@export var perimeter_wall_color: Color = Color(0.72, 0.74, 0.78)

var _is_ready := false

func _ready() -> void:
	_is_ready = true
	_rebuild_office()

func _rebuild_office() -> void:
	_clear_office()
	_build_environment()

	if grid_rows <= 0 or grid_columns <= 0:
		var fallback_length := 12.0
		var fallback_depth := 6.0
		var fallback_center := 0.0
		_create_drop_ceiling(fallback_length, fallback_depth, fallback_center)
		_create_perimeter_walls(fallback_length, fallback_depth, fallback_center, ELEVATOR_WALL_EAST, 0.0, 0.0)
		return

	# Calculate grid layout
	# Each "unit" is 2x2 cubicles: two facing forward, two facing backward
	var total_units := grid_rows * grid_columns
	var total_cubicles := total_units * 4
	var cubicle_id := 1
	
	# Create units in a grid
	var units: Array[Array] = []  # Array of rows, each containing units
	for row_idx in range(grid_rows):
		var row_units: Array[Array] = []  # Array of units in this row
		
		for col_idx in range(grid_columns):
			var unit_cubicles: Array[Node3D] = []
			
			# Create 2x2 cubicle arrangement:
			# [0: left-faces-left] [1: right-faces-right]
			# [2: left-faces-left] [3: right-faces-right]
			
			# Front-left cubicle (faces left/outward)
			var c0 := Cubicle.new()
			c0.name = "Cubicle_R%d_C%d_FL" % [row_idx, col_idx]
			c0.setup(cubicle_id, cubicle_depth, wall_thickness)
			c0.rotate_y(-PI / 2)  # Face left
			add_child(c0)
			unit_cubicles.append(c0)
			cubicle_id += 1
			
			# Front-right cubicle (faces right/outward)
			var c1 := Cubicle.new()
			c1.name = "Cubicle_R%d_C%d_FR" % [row_idx, col_idx]
			c1.setup(cubicle_id, cubicle_depth, wall_thickness)
			c1.rotate_y(PI / 2)  # Face right
			add_child(c1)
			unit_cubicles.append(c1)
			cubicle_id += 1
			
			# Back-left cubicle (faces left/outward)
			var c2 := Cubicle.new()
			c2.name = "Cubicle_R%d_C%d_BL" % [row_idx, col_idx]
			c2.setup(cubicle_id, cubicle_depth, wall_thickness)
			c2.rotate_y(-PI / 2)  # Face left
			add_child(c2)
			unit_cubicles.append(c2)
			cubicle_id += 1
			
			# Back-right cubicle (faces right/outward)
			var c3 := Cubicle.new()
			c3.name = "Cubicle_R%d_C%d_BR" % [row_idx, col_idx]
			c3.setup(cubicle_id, cubicle_depth, wall_thickness)
			c3.rotate_y(PI / 2)  # Face right
			add_child(c3)
			unit_cubicles.append(c3)
			cubicle_id += 1
			
			row_units.append(unit_cubicles)
		
		units.append(row_units)
	
	# Position cubicle units in grid
	if units.size() == 0 or units[0].size() == 0:
		return
	
	var sample_cubicle: Node3D = units[0][0][0]
	var sample_bounds: Dictionary = sample_cubicle.get_collision_bounds()
	var sample_min_x: float = float(sample_bounds.get("min_x", 0.0))
	var sample_max_x: float = float(sample_bounds.get("max_x", 0.0))
	var sample_min_z: float = float(sample_bounds.get("min_z", 0.0))
	var sample_max_z: float = float(sample_bounds.get("max_z", 0.0))
	var cubicle_half_depth: float = (sample_max_x - sample_min_x) * 0.5
	var cubicle_half_width: float = (sample_max_z - sample_min_z) * 0.5
	if cubicle_half_depth <= 0.0 or cubicle_half_width <= 0.0:
		return

	# Calculate unit dimensions (2 cubicles wide, 2 cubicles deep)
	var unit_width: float = cubicle_half_depth * 2.0
	var unit_depth: float = cubicle_half_width * 2.0
	
	# Calculate grid dimensions with aisle spacing between units
	var total_unit_width: float = unit_width + aisle_width
	var total_unit_depth: float = unit_depth + aisle_width
	var grid_width: float = total_unit_width * float(grid_columns) - aisle_width  # No aisle after last column
	var grid_depth: float = total_unit_depth * float(grid_rows) - aisle_width  # No aisle after last row
	var grid_start_x: float = -grid_width * 0.5
	var grid_start_z: float = -grid_depth * 0.5
	var elevator_column_index: float = min(float(grid_columns) - 1.0, 4.0)
	var elevator_center_x: float = grid_start_x + elevator_column_index * total_unit_width + unit_width * 0.5
	var elevator_row_index: float = clampf(floorf(float(grid_rows) * 0.5), 0.0, maxf(0.0, float(grid_rows) - 1.0))
	var elevator_center_z: float = grid_start_z + elevator_row_index * total_unit_depth + unit_depth * 0.5
	var elevator_wall: String = ELEVATOR_WALL_EAST if elevator_center_x >= 0.0 else ELEVATOR_WALL_WEST
	
	# Position each unit
	for row_idx in range(grid_rows):
		for col_idx in range(grid_columns):
			var unit: Array[Node3D] = units[row_idx][col_idx]
			
			# Calculate unit center position (with aisle spacing between units)
			var unit_center_x: float = grid_start_x + col_idx * total_unit_width + unit_width * 0.5
			var unit_center_z: float = grid_start_z + row_idx * total_unit_depth + unit_depth * 0.5
			
			# Position the 4 cubicles in this unit so backs and sides touch cleanly
			var front_z := unit_center_z - cubicle_half_width
			var back_z := unit_center_z + cubicle_half_width
			var left_x := unit_center_x - cubicle_half_depth
			var right_x := unit_center_x + cubicle_half_depth

			_place_cubicle(unit[0], Vector3(left_x, 0.0, front_z))
			_place_cubicle(unit[1], Vector3(right_x, 0.0, front_z))
			_place_cubicle(unit[2], Vector3(left_x, 0.0, back_z))
			_place_cubicle(unit[3], Vector3(right_x, 0.0, back_z))
	
	# Calculate bounds for ceiling
	var first_center_z: float = grid_start_z + unit_depth * 0.5
	var last_center_z: float = grid_start_z + (grid_rows - 1) * total_unit_depth + unit_depth * 0.5
	var min_z: float = first_center_z - cubicle_half_width
	var max_z: float = last_center_z + cubicle_half_width

	var floor_length: float = grid_width + 12.0
	var floor_depth: float = max(6.0, (max_z - min_z) + 12.0)
	var floor_center: float = (min_z + max_z) * 0.5
	
	_create_drop_ceiling(floor_length, floor_depth, floor_center)
	_create_perimeter_walls(floor_length, floor_depth, floor_center, elevator_wall, elevator_center_x, elevator_center_z)

	print("✅ Generated %dx%d unit grid (%d units, %d cubicles total)." % [grid_rows, grid_columns, total_units, total_cubicles])


# ------------------------------------------------------------
# HELPER FUNCTIONS  (these go AFTER _ready(), not indented)
# ------------------------------------------------------------

func _clear_office() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.ambient_light_color = Color(0.15, 0.18, 0.22)
	environment.ambient_light_energy = 0.15
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.9
	environment.ssao_enabled = true
	environment.ssao_radius = 2.0
	environment.ssao_intensity = 1.5
	env.environment = environment
	add_child(env)

func _create_drop_ceiling(total_length: float, total_depth: float, center_z: float) -> void:
	if DropCeiling == null:
		return
	var ceiling := DropCeiling.new()
	add_child(ceiling)
	ceiling.setup(total_length, total_depth, center_z)

func _create_perimeter_walls(total_length: float, total_depth: float, center_z: float, elevator_wall: String, elevator_center_x: float, elevator_center_z: float) -> void:
	if total_length <= 0.0 or total_depth <= 0.0:
		return
	if perimeter_wall_height <= 0.0 or perimeter_wall_thickness <= 0.0:
		return

	var half_length := total_length * 0.5
	var half_depth := total_depth * 0.5
	var wall_y := perimeter_wall_height * 0.5 - 1.0

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = perimeter_wall_color
	wall_mat.roughness = 0.85

	var north_center := Vector3(0.0, wall_y, center_z - half_depth - perimeter_wall_thickness * 0.5)
	if elevator_wall == ELEVATOR_WALL_NORTH:
		_spawn_perimeter_wall_with_elevator("PerimeterWallNorth", north_center, total_length, ELEVATOR_WALL_NORTH, wall_mat, elevator_center_x)
	else:
		_spawn_perimeter_wall("PerimeterWallNorth", north_center, Vector3(total_length, perimeter_wall_height, perimeter_wall_thickness), wall_mat)

	var south_center := Vector3(0.0, wall_y, center_z + half_depth + perimeter_wall_thickness * 0.5)
	if elevator_wall == ELEVATOR_WALL_SOUTH:
		_spawn_perimeter_wall_with_elevator("PerimeterWallSouth", south_center, total_length, ELEVATOR_WALL_SOUTH, wall_mat, elevator_center_x)
	else:
		_spawn_perimeter_wall("PerimeterWallSouth", south_center, Vector3(total_length, perimeter_wall_height, perimeter_wall_thickness), wall_mat)

	var west_center := Vector3(-half_length - perimeter_wall_thickness * 0.5, wall_y, center_z)
	if elevator_wall == ELEVATOR_WALL_WEST:
		_spawn_perimeter_wall_with_elevator("PerimeterWallWest", west_center, total_depth, ELEVATOR_WALL_WEST, wall_mat, elevator_center_z)
	else:
		_spawn_perimeter_wall("PerimeterWallWest", west_center, Vector3(perimeter_wall_thickness, perimeter_wall_height, total_depth), wall_mat)

	var east_center := Vector3(half_length + perimeter_wall_thickness * 0.5, wall_y, center_z)
	if elevator_wall == ELEVATOR_WALL_EAST:
		_spawn_perimeter_wall_with_elevator("PerimeterWallEast", east_center, total_depth, ELEVATOR_WALL_EAST, wall_mat, elevator_center_z)
	else:
		_spawn_perimeter_wall("PerimeterWallEast", east_center, Vector3(perimeter_wall_thickness, perimeter_wall_height, total_depth), wall_mat)

func _spawn_perimeter_wall_with_elevator(base_name: String, wall_center: Vector3, span_length: float, wall_id: String, material: StandardMaterial3D, elevator_axis_center: float) -> void:
	if span_length <= 0.0:
		return

	var opening_width: float = 2.4
	opening_width = clampf(opening_width, 0.0, maxf(0.0, span_length - 0.5))
	var half_opening: float = opening_width * 0.5
	var margin: float = maxf(0.25, perimeter_wall_thickness)
	var start := -span_length * 0.5
	var end := span_length * 0.5
	var axis_origin := wall_center.x if wall_id == ELEVATOR_WALL_NORTH or wall_id == ELEVATOR_WALL_SOUTH else wall_center.z
	var local_axis_center := elevator_axis_center - axis_origin
	var min_center := start + half_opening + margin
	var max_center := end - half_opening - margin
	var clamped_center: float
	if min_center > max_center:
		clamped_center = (start + end) * 0.5
	else:
		clamped_center = clampf(local_axis_center, min_center, max_center)
	var left_end := clamped_center - half_opening
	var right_start := clamped_center + half_opening

	if left_end - start > 0.05:
		var left_length: float = left_end - start
		var left_center := (start + left_end) * 0.5
		var left_position := wall_center
		var left_size: Vector3
		if wall_id == ELEVATOR_WALL_NORTH or wall_id == ELEVATOR_WALL_SOUTH:
			left_position.x = wall_center.x + left_center
			left_size = Vector3(left_length, perimeter_wall_height, perimeter_wall_thickness)
		else:
			left_position.z = wall_center.z + left_center
			left_size = Vector3(perimeter_wall_thickness, perimeter_wall_height, left_length)
		_spawn_perimeter_wall("%s_Left" % base_name, left_position, left_size, material)

	if end - right_start > 0.05:
		var right_length: float = end - right_start
		var right_center := (right_start + end) * 0.5
		var right_position := wall_center
		var right_size: Vector3
		if wall_id == ELEVATOR_WALL_NORTH or wall_id == ELEVATOR_WALL_SOUTH:
			right_position.x = wall_center.x + right_center
			right_size = Vector3(right_length, perimeter_wall_height, perimeter_wall_thickness)
		else:
			right_position.z = wall_center.z + right_center
			right_size = Vector3(perimeter_wall_thickness, perimeter_wall_height, right_length)
		_spawn_perimeter_wall("%s_Right" % base_name, right_position, right_size, material)

	var header_height: float = minf(0.35, perimeter_wall_height * 0.25)
	if header_height > 0.05 and opening_width > 0.2:
		var header_position := wall_center
		var header_size: Vector3
		if wall_id == ELEVATOR_WALL_NORTH or wall_id == ELEVATOR_WALL_SOUTH:
			header_position.x = wall_center.x + clamped_center
			header_size = Vector3(opening_width, header_height, perimeter_wall_thickness)
		else:
			header_position.z = wall_center.z + clamped_center
			header_size = Vector3(perimeter_wall_thickness, header_height, opening_width)
		header_position.y = wall_center.y + (perimeter_wall_height - header_height) * 0.5
		_spawn_perimeter_wall("%s_Header" % base_name, header_position, header_size, material)

	var door_center := wall_center
	var inward_normal := Vector3.ZERO
	var rotation := Vector3.ZERO
	if wall_id == ELEVATOR_WALL_NORTH:
		door_center.x = wall_center.x + clamped_center
		door_center.z = wall_center.z + perimeter_wall_thickness * 0.5
		inward_normal = Vector3(0.0, 0.0, 1.0)
		rotation = Vector3.ZERO
	elif wall_id == ELEVATOR_WALL_SOUTH:
		door_center.x = wall_center.x + clamped_center
		door_center.z = wall_center.z - perimeter_wall_thickness * 0.5
		inward_normal = Vector3(0.0, 0.0, -1.0)
		rotation = Vector3(0.0, 180.0, 0.0)
	elif wall_id == ELEVATOR_WALL_EAST:
		door_center.z = wall_center.z + clamped_center
		door_center.x = wall_center.x - perimeter_wall_thickness * 0.5
		inward_normal = Vector3(-1.0, 0.0, 0.0)
		rotation = Vector3(0.0, -90.0, 0.0)
	else:
		door_center.z = wall_center.z + clamped_center
		door_center.x = wall_center.x + perimeter_wall_thickness * 0.5
		inward_normal = Vector3(1.0, 0.0, 0.0)
		rotation = Vector3(0.0, 90.0, 0.0)

	_create_elevator_on_perimeter(door_center, inward_normal, rotation)

func _spawn_perimeter_wall(name: String, position: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	var wall_body := StaticBody3D.new()
	wall_body.name = name
	wall_body.position = position
	add_child(wall_body)

	var wall_mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	wall_mesh.mesh = box_mesh
	wall_mesh.material_override = material
	wall_body.add_child(wall_mesh)

	var wall_collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	wall_collision.shape = box_shape
	wall_body.add_child(wall_collision)

func _create_elevator_on_perimeter(door_center: Vector3, inward_normal: Vector3, rotation_degrees: Vector3) -> void:
	if Elevator == null:
		return

	var elevator := Elevator.new()
	elevator.name = "Elevator"

	elevator.elevator_width = 2.0
	elevator.elevator_depth = 2.0
	elevator.elevator_height = max(perimeter_wall_height, 2.5)

	var normal := inward_normal.normalized()
	var inset := - elevator.elevator_depth * 0.5
	var depth_offset := normal * inset
	var base_y := door_center.y - perimeter_wall_height * 0.5
	elevator.position = Vector3(door_center.x, base_y, door_center.z) + depth_offset
	elevator.rotation_degrees = rotation_degrees

	add_child(elevator)
	_position_player_in_elevator(elevator)

func _position_player_in_elevator(elevator: Node3D) -> void:
	var player: Node3D = get_node_or_null("../Player")
	if player == null:
		player = get_tree().get_root().find_child("Player", true, false)
	if player == null:
		return

	var spawn_point := elevator.global_transform.origin + elevator.global_transform.basis.z * 0.25
	var height_offset := player.global_position.y - global_transform.origin.y
	spawn_point.y = global_transform.origin.y + height_offset
	player.global_position = spawn_point

	var forward_dir := elevator.global_transform.basis.z
	forward_dir.y = 0.0
	if forward_dir.length_squared() > 0.0001:
		forward_dir = forward_dir.normalized()
		player.look_at(spawn_point + forward_dir, Vector3.UP)

	if player is CharacterBody3D:
		var body := player as CharacterBody3D
		body.velocity = Vector3.ZERO
		body.set("target_velocity", Vector3.ZERO)

func _place_cubicle(cubicle: Node3D, target_center: Vector3) -> void:
	var bounds: Dictionary = cubicle.get_collision_bounds()
	var center_x: float = (float(bounds.get("min_x", 0.0)) + float(bounds.get("max_x", 0.0))) * 0.5
	var center_z: float = (float(bounds.get("min_z", 0.0)) + float(bounds.get("max_z", 0.0))) * 0.5
	cubicle.position = Vector3(target_center.x - center_x, 0.0, target_center.z - center_z)
