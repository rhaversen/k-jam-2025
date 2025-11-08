extends Node3D
# High-level office builder that spawns cubicle rows and shared lighting.

const DropCeiling := preload("res://scripts/drop_ceiling.gd")
const Cubicle := preload("res://scripts/cubicle.gd")
const Elevator := preload("res://scripts/elevator.gd")

@export var grid_rows: int = 2
@export var grid_columns: int = 10
@export var cubicle_width: float = 4.0
@export var cubicle_depth: float = 3.0
@export var aisle_width: float = 6.0
@export var wall_thickness: float = 0.06

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
	
	# Create aisle wall with elevator (if grid is large enough)
	if grid_columns > 4:
		_create_aisle_wall(grid_start_x, total_unit_width, unit_width, unit_depth)

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

func _create_aisle_wall(grid_start_x: float, total_unit_width: float, unit_width: float, unit_depth: float) -> void:
	# Create a wall down the aisle
	var wall_height := 2.5
	var wall_thickness := 0.15
	var wall_length := unit_depth  # Spans two cubicles
	
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.75, 0.75, 0.8)
	wall_mat.roughness = 0.85
	
	# Position the wall at a reasonable spot (near middle of grid)
	var wall_column_index: float = min(float(grid_columns) - 1.0, 4.0)
	var wall_x: float = grid_start_x + total_unit_width * wall_column_index + unit_width * 0.5
	
	# Create wall with hole for elevator (aligned with elevator door position)
	var elevator_z_position := -1.5  # This matches the elevator position
	var elevator_opening_z := elevator_z_position  # Center of elevator opening
	var elevator_opening_width := 2.2  # Slightly larger than elevator width for clearance
	
	# Left section of wall (negative Z side)
	var left_wall_end := elevator_opening_z - elevator_opening_width * 0.5
	var left_wall_start := -wall_length * 0.5
	var left_wall_length := left_wall_end - left_wall_start
	if left_wall_length > 0.1:
		var left_wall_z := (left_wall_start + left_wall_end) * 0.5
		var left_wall := StaticBody3D.new()
		left_wall.name = "AisleWallLeft"
		left_wall.position = Vector3(wall_x, wall_height * 0.5 - 1.0, left_wall_z)
		add_child(left_wall)
		
		var left_mesh := MeshInstance3D.new()
		var left_box := BoxMesh.new()
		left_box.size = Vector3(wall_thickness, wall_height, left_wall_length)
		left_mesh.mesh = left_box
		left_mesh.material_override = wall_mat
		left_wall.add_child(left_mesh)
		
		var left_collision := CollisionShape3D.new()
		var left_shape := BoxShape3D.new()
		left_shape.size = Vector3(wall_thickness, wall_height, left_wall_length)
		left_collision.shape = left_shape
		left_wall.add_child(left_collision)
	
	# Right section of wall (positive Z side)
	var right_wall_start := elevator_opening_z + elevator_opening_width * 0.5
	var right_wall_end := wall_length * 0.5
	var right_wall_length := right_wall_end - right_wall_start
	if right_wall_length > 0.1:
		var right_wall_z := (right_wall_start + right_wall_end) * 0.5
		var right_wall := StaticBody3D.new()
		right_wall.name = "AisleWallRight"
		right_wall.position = Vector3(wall_x, wall_height * 0.5 - 1.0, right_wall_z)
		add_child(right_wall)
		
		var right_mesh := MeshInstance3D.new()
		var right_box := BoxMesh.new()
		right_box.size = Vector3(wall_thickness, wall_height, right_wall_length)
		right_mesh.mesh = right_box
		right_mesh.material_override = wall_mat
		right_wall.add_child(right_mesh)
		
		var right_collision := CollisionShape3D.new()
		var right_shape := BoxShape3D.new()
		right_shape.size = Vector3(wall_thickness, wall_height, right_wall_length)
		right_collision.shape = right_shape
		right_wall.add_child(right_collision)
	
	# Add elevator to the aisle wall
	_create_elevator_on_wall(wall_x, unit_width)

func _place_cubicle(cubicle: Node3D, target_center: Vector3) -> void:
	var bounds: Dictionary = cubicle.get_collision_bounds()
	var center_x: float = (float(bounds.get("min_x", 0.0)) + float(bounds.get("max_x", 0.0))) * 0.5
	var center_z: float = (float(bounds.get("min_z", 0.0)) + float(bounds.get("max_z", 0.0))) * 0.5
	cubicle.position = Vector3(target_center.x - center_x, 0.0, target_center.z - center_z)

func _create_elevator_on_wall(wall_x: float, unit_width: float) -> void:
	if Elevator == null:
		return
	
	var elevator := Elevator.new()
	elevator.name = "Elevator"
	
	# Set elevator dimensions
	elevator.elevator_width = 2.0
	elevator.elevator_depth = 2.0
	elevator.elevator_height = 2.5
	
	# Position elevator attached to the wall
	# Offset by half the elevator depth so it's flush against the wall
	var elevator_offset := elevator.elevator_depth * 0.5
	var elevator_x := wall_x + elevator_offset - unit_width * 0.5 + elevator.elevator_width * 0.5 - 0.5
	var elevator_z := -1.5
	elevator.position = Vector3(elevator_x, -1.0, elevator_z)  # Y = -1.0 to match floor level
	elevator.rotation_degrees = Vector3(0, 90, 0)  # Rotate so doors face positive X (into the aisle)
	
	add_child(elevator)
