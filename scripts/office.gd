extends Node3D
# High-level office builder that spawns cubicle rows and shared lighting.

const DropCeiling := preload("res://scripts/drop_ceiling.gd")
const Cubicle := preload("res://scripts/cubicle.gd")
const Elevator := preload("res://scripts/elevator.gd")

@export var cubicle_count: int = 20
@export var aisle_width: float = 6.0
@export var cubicle_depth: float = 3.0
@export var wall_thickness: float = 0.06

var _is_ready := false

func _ready() -> void:
	_is_ready = true
	_rebuild_office()

func set_cubicle_count(value: int) -> void:
	var sanitized: int = int(max(value, 0))
	if cubicle_count == sanitized:
		return
	cubicle_count = sanitized
	if _is_ready:
		_rebuild_office()

func _rebuild_office() -> void:
	_clear_office()
	_build_environment()

	if cubicle_count <= 0:
		var fallback_length := 12.0
		var fallback_depth := 6.0
		var fallback_center := 0.0
		_create_floor(fallback_length, fallback_depth, fallback_center)
		_create_drop_ceiling(fallback_length, fallback_depth, fallback_center)
		return

	var aisle_half: float = max(0.0, aisle_width * 0.5)

	var row_a: Array[Node3D] = []
	var row_a_bounds: Dictionary = {}
	var spacing: float = 0.0
	for i in range(cubicle_count):
		var cubicle := Cubicle.new()
		cubicle.name = "Cubicle_%02d" % i
		cubicle.setup(i + 1, cubicle_depth, wall_thickness)
		if i == 0:
			row_a_bounds = cubicle.get_collision_bounds()
			spacing = float(row_a_bounds.get("width", 0.0))
			if spacing <= 0.0:
				spacing = 4.0
		add_child(cubicle)
		row_a.append(cubicle)

	var row_b: Array[Node3D] = []
	var row_b_bounds: Dictionary = {}
	for i in range(cubicle_count):
		var cubicle := Cubicle.new()
		cubicle.name = "CubicleB_%02d" % i
		cubicle.setup(cubicle_count + i + 1, cubicle_depth, wall_thickness)
		cubicle.rotate_y(PI)
		if i == 0:
			row_b_bounds = cubicle.get_collision_bounds()
		add_child(cubicle)
		row_b.append(cubicle)

	if row_b_bounds.get("width", 0.0) <= 0.0:
		row_b_bounds = {
			"min_x": row_a_bounds.get("min_x", 0.0),
			"max_x": row_a_bounds.get("max_x", 0.0),
			"min_z": -row_a_bounds.get("max_z", 0.0),
			"max_z": -row_a_bounds.get("min_z", 0.0),
			"width": spacing,
			"depth": row_a_bounds.get("depth", cubicle_depth)
		}

	var half_span: float = spacing * 0.5 * float(max(cubicle_count - 1, 0))
	var center_offset := 0.0
	if cubicle_count % 2 == 0 and spacing > 0.0:
		center_offset = spacing * 0.5

	var row_a_front := float(row_a_bounds.get("max_z", 0.0))
	var row_a_back := float(row_a_bounds.get("min_z", 0.0))
	var row_b_front := float(row_b_bounds.get("max_z", 0.0))
	var row_b_back := float(row_b_bounds.get("min_z", 0.0))

	var row_a_z_offset: float = -aisle_half - row_a_front
	var row_b_z_offset: float = aisle_half - row_b_front

	for i in range(row_a.size()):
		var target_a := Vector3(-half_span + i * spacing + center_offset, 0, row_a_z_offset)
		row_a[i].position = target_a

	for i in range(row_b.size()):
		var target_b := Vector3(-half_span + i * spacing + center_offset, 0, row_b_z_offset)
		row_b[i].position = target_b

	var min_z: float = min(row_a_back + row_a_z_offset, row_b_back + row_b_z_offset)
	var max_z: float = max(row_a_front + row_a_z_offset, row_b_front + row_b_z_offset)
	# Extend floor to cover entire office area with extra margin to reach all walls
	# Calculate the extent needed to reach the aisle wall position
	var wall_x := -half_span + spacing + center_offset + spacing  # End of aisle wall
	var floor_length: float = max(12.0, abs(wall_x - (-half_span)) + abs(wall_x - half_span) + 12.0)
	var floor_depth: float = max(6.0, (max_z - min_z) + 12.0)
	var floor_center: float = (min_z + max_z) * 0.5
	_create_floor(floor_length, floor_depth, floor_center)
	_create_drop_ceiling(floor_length, floor_depth, floor_center)
	
	# Create aisle wall aligned with two cubicles
	_create_aisle_wall(spacing, center_offset, half_span)

	print("✅ Generated %d cubicle pairs at spacing %.2f with aisle %.2f." % [cubicle_count, spacing, aisle_width])


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
	environment.ambient_light_color = Color(1, 1, 1)
	environment.ambient_light_energy = 1.0
	env.environment = environment
	add_child(env)

func _create_floor(total_length: float, total_depth: float, center_z: float) -> void:
	var floor_mesh_instance := MeshInstance3D.new()
	floor_mesh_instance.name = "Floor"
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(total_length, total_depth)
	floor_mesh_instance.mesh = floor_mesh
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.25, 0.28, 0.3)
	floor_mat.roughness = 1.0
	floor_mesh_instance.material_override = floor_mat
	floor_mesh_instance.position = Vector3(0, -1.0, center_z)
	add_child(floor_mesh_instance)

func _create_drop_ceiling(total_length: float, total_depth: float, center_z: float) -> void:
	if DropCeiling == null:
		return
	var ceiling := DropCeiling.new()
	add_child(ceiling)
	ceiling.setup(total_length, total_depth, center_z)

func _create_aisle_wall(spacing: float, center_offset: float, half_span: float) -> void:
	# Create a wall down the aisle that spans two cubicles
	var wall_height := 2.5
	var wall_thickness := 0.15
	var wall_length := spacing * 2.0  # Spans two cubicles
	
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.75, 0.75, 0.8)
	wall_mat.roughness = 0.85
	
	# Position the wall between cubicles (at 4.5 cubicle position)
	# Wall now runs perpendicular to cubicles (along Z-axis)
	var wall_x := -half_span + spacing * 4.5 + center_offset  # Start at 4.5 cubicle position
	
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
	
	# Add elevator to the aisle wall (moved back half a cubicle)
	_create_elevator_on_wall(wall_x, spacing)

func _create_elevator_on_wall(wall_x: float, spacing: float) -> void:
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
	# Align elevator opening with the beginning of the wall
	var elevator_offset := elevator.elevator_depth * 0.5
	var elevator_x := wall_x + elevator_offset - (spacing * 0.5) + (elevator.elevator_width * 0.5) - 0.5  # Move back a bit
	var elevator_z := -1.5  # Move to the left
	elevator.position = Vector3(elevator_x, -1.0, elevator_z)  # Y = -1.0 to match floor level
	elevator.rotation_degrees = Vector3(0, 90, 0)  # Rotate so doors face positive X (into the aisle)
	
	add_child(elevator)
