extends RefCounted
class_name OfficeLayoutBuilder

func build(owner: Node3D, config: Dictionary) -> Dictionary:
	var grid_rows: int = config.get("grid_rows", 0)
	var grid_columns: int = config.get("grid_columns", 0)
	if grid_rows <= 0 or grid_columns <= 0:
		return {}

	var aisle_width: float = float(config.get("aisle_width", 6.0))
	var wall_thickness: float = float(config.get("wall_thickness", 0.06))
	var cubicle_depth: float = float(config.get("cubicle_depth", 3.0))
	var cubicle_script = config.get("cubicle_script")
	if cubicle_script == null:
		return {}

	var total_units := grid_rows * grid_columns
	var total_cubicles := total_units * 4
	var cubicle_id := 1

	var units: Array = []
	for row_idx in range(grid_rows):
		var row_units: Array = []
		for col_idx in range(grid_columns):
			var unit_cubicles: Array = []

			var c0 := _create_cubicle(
				cubicle_script,
				owner,
				"Cubicle_R%d_C%d_FL" % [row_idx, col_idx],
				cubicle_id,
				cubicle_depth,
				wall_thickness,
				-PI * 0.5
			)
			cubicle_id += 1
			unit_cubicles.append(c0)

			var c1 := _create_cubicle(
				cubicle_script,
				owner,
				"Cubicle_R%d_C%d_FR" % [row_idx, col_idx],
				cubicle_id,
				cubicle_depth,
				wall_thickness,
				PI * 0.5
			)
			cubicle_id += 1
			unit_cubicles.append(c1)

			var c2 := _create_cubicle(
				cubicle_script,
				owner,
				"Cubicle_R%d_C%d_BL" % [row_idx, col_idx],
				cubicle_id,
				cubicle_depth,
				wall_thickness,
				-PI * 0.5
			)
			cubicle_id += 1
			unit_cubicles.append(c2)

			var c3 := _create_cubicle(
				cubicle_script,
				owner,
				"Cubicle_R%d_C%d_BR" % [row_idx, col_idx],
				cubicle_id,
				cubicle_depth,
				wall_thickness,
				PI * 0.5
			)
			cubicle_id += 1
			unit_cubicles.append(c3)

			row_units.append(unit_cubicles)
		units.append(row_units)

	if units.size() == 0 or units[0].size() == 0:
		return {}

	var sample_cubicle: Node3D = units[0][0][0]
	var sample_bounds: Dictionary = sample_cubicle.get_collision_bounds()
	var sample_min_x: float = float(sample_bounds.get("min_x", 0.0))
	var sample_max_x: float = float(sample_bounds.get("max_x", 0.0))
	var sample_min_z: float = float(sample_bounds.get("min_z", 0.0))
	var sample_max_z: float = float(sample_bounds.get("max_z", 0.0))
	var cubicle_half_depth: float = (sample_max_x - sample_min_x) * 0.5
	var cubicle_half_width: float = (sample_max_z - sample_min_z) * 0.5
	if cubicle_half_depth <= 0.0 or cubicle_half_width <= 0.0:
		return {}

	var unit_width: float = cubicle_half_depth * 2.0
	var unit_depth: float = cubicle_half_width * 2.0
	var total_unit_width: float = unit_width + aisle_width
	var total_unit_depth: float = unit_depth + aisle_width
	var grid_width: float = total_unit_width * float(grid_columns) - aisle_width
	var grid_depth: float = total_unit_depth * float(grid_rows) - aisle_width
	var grid_start_x: float = -grid_width * 0.5
	var grid_start_z: float = -grid_depth * 0.5
	var elevator_column_index: float = min(float(grid_columns) - 1.0, 4.0)
	var elevator_center_x: float = grid_start_x + elevator_column_index * total_unit_width + unit_width * 0.5
	var elevator_row_index: float = clampf(floorf(float(grid_rows) * 0.5), 0.0, maxf(0.0, float(grid_rows) - 1.0))
	var elevator_center_z: float = grid_start_z + elevator_row_index * total_unit_depth + unit_depth * 0.5
	var elevator_wall: String = "east" if elevator_center_x >= 0.0 else "west"

	for row_idx in range(grid_rows):
		for col_idx in range(grid_columns):
			var unit: Array = units[row_idx][col_idx]
			var unit_center_x: float = grid_start_x + col_idx * total_unit_width + unit_width * 0.5
			var unit_center_z: float = grid_start_z + row_idx * total_unit_depth + unit_depth * 0.5

			var front_z: float = unit_center_z - cubicle_half_width
			var back_z: float = unit_center_z + cubicle_half_width
			var left_x: float = unit_center_x - cubicle_half_depth
			var right_x: float = unit_center_x + cubicle_half_depth

			_place_cubicle(unit[0], Vector3(left_x, 0.0, front_z))
			_place_cubicle(unit[1], Vector3(right_x, 0.0, front_z))
			_place_cubicle(unit[2], Vector3(left_x, 0.0, back_z))
			_place_cubicle(unit[3], Vector3(right_x, 0.0, back_z))

	var first_center_z: float = grid_start_z + unit_depth * 0.5
	var last_center_z: float = grid_start_z + (grid_rows - 1) * total_unit_depth + unit_depth * 0.5
	var min_z: float = first_center_z - cubicle_half_width
	var max_z: float = last_center_z + cubicle_half_width
	var floor_length: float = grid_width + 12.0
	var floor_depth: float = maxf(6.0, (max_z - min_z) + 12.0)
	var floor_center: float = (min_z + max_z) * 0.5

	return {
		"floor_length": floor_length,
		"floor_depth": floor_depth,
		"floor_center": floor_center,
		"elevator_wall": elevator_wall,
		"elevator_center_x": elevator_center_x,
		"elevator_center_z": elevator_center_z,
		"total_units": total_units,
		"total_cubicles": total_cubicles
	}

func _create_cubicle(
	cubicle_script,
	owner: Node3D,
	name: String,
	cubicle_id: int,
	cubicle_depth: float,
	wall_thickness: float,
	rotation_radians: float
) -> Node3D:
	var cubicle: Node3D = cubicle_script.new()
	cubicle.name = name
	cubicle.setup(cubicle_id, cubicle_depth, wall_thickness)
	cubicle.rotate_y(rotation_radians)
	owner.add_child(cubicle)
	return cubicle

func _place_cubicle(cubicle: Node3D, target_center: Vector3) -> void:
	var bounds: Dictionary = cubicle.get_collision_bounds()
	var center_x: float = (float(bounds.get("min_x", 0.0)) + float(bounds.get("max_x", 0.0))) * 0.5
	var center_z: float = (float(bounds.get("min_z", 0.0)) + float(bounds.get("max_z", 0.0))) * 0.5
	cubicle.position = Vector3(target_center.x - center_x, 0.0, target_center.z - center_z)
