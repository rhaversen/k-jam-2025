extends RefCounted
class_name OfficePerimeterBuilder

const WALL_NORTH := "north"
const WALL_EAST := "east"
const WALL_SOUTH := "south"
const WALL_WEST := "west"

const WINDOW_CONTROLLER_SCRIPT := preload("res://scripts/window_day_night_controller.gd")
const WINDOW_DAY_COLOR := Color(0.75, 0.85, 1.0)
const WINDOW_DAY_EMISSION := 3.8
const WINDOW_NIGHT_COLOR := Color(0.08, 0.1, 0.22)
const WINDOW_NIGHT_EMISSION := 0.9
const WINDOW_SEGMENT_COUNT := 4
const WINDOW_MULLION_WIDTH := 0.14
const WINDOW_GLASS_INSET := 0.02
const DEFAULT_CEILING_EXTENSION := 0.5
const ELEVATOR_OPENING_TARGET_WIDTH := 2.0

var _elevator_script: Script

func _init(elevator_script: Script) -> void:
	_elevator_script = elevator_script

func create_perimeter(owner: Node3D, params: Dictionary) -> Node3D:
	var total_length: float = float(params.get("total_length", 0.0))
	var total_depth: float = float(params.get("total_depth", 0.0))
	var center_z: float = float(params.get("center_z", 0.0))
	var elevator_wall: String = String(params.get("elevator_wall", WALL_EAST))
	var elevator_center_x: float = float(params.get("elevator_center_x", 0.0))
	var elevator_center_z: float = float(params.get("elevator_center_z", 0.0))
	var wall_height: float = float(params.get("perimeter_wall_height", 0.0))
	var wall_thickness: float = float(params.get("perimeter_wall_thickness", 0.0))
	var wall_color: Color = params.get("perimeter_wall_color", Color(0.72, 0.74, 0.78))
	var ceiling_extension: float = float(params.get("perimeter_wall_ceiling_extension", DEFAULT_CEILING_EXTENSION))
	if ceiling_extension < 0.0:
		ceiling_extension = 0.0
	var full_wall_height := wall_height + ceiling_extension

	if wall_height <= 0.0:
		wall_height = full_wall_height

	if total_length <= 0.0 or total_depth <= 0.0:
		return null
	if full_wall_height <= 0.0 or wall_thickness <= 0.0:
		return null

	var half_length := total_length * 0.5
	var half_depth := total_depth * 0.5
	var wall_y := full_wall_height * 0.5 - 1.0

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = wall_color
	wall_mat.roughness = 0.85

	var window_wall_id := _get_adjacent_window_wall(elevator_wall)
	var elevator_ref: Node3D = null
	var north_center := Vector3(0.0, wall_y, center_z - half_depth - wall_thickness * 0.5)
	if elevator_wall == WALL_NORTH:
		elevator_ref = _spawn_wall_with_elevator(owner, "PerimeterWallNorth", north_center, total_length, WALL_NORTH, wall_mat, elevator_center_x, full_wall_height, wall_thickness, wall_height)
	elif window_wall_id == WALL_NORTH:
		if not _spawn_window_wall(owner, "PerimeterWallNorth", north_center, total_length, WALL_NORTH, full_wall_height, wall_thickness, wall_mat):
			_spawn_wall(owner, "PerimeterWallNorth", north_center, Vector3(total_length, full_wall_height, wall_thickness), wall_mat)
	else:
		_spawn_wall(owner, "PerimeterWallNorth", north_center, Vector3(total_length, full_wall_height, wall_thickness), wall_mat)

	var south_center := Vector3(0.0, wall_y, center_z + half_depth + wall_thickness * 0.5)
	if elevator_wall == WALL_SOUTH:
		elevator_ref = _spawn_wall_with_elevator(owner, "PerimeterWallSouth", south_center, total_length, WALL_SOUTH, wall_mat, elevator_center_x, full_wall_height, wall_thickness, wall_height)
	elif window_wall_id == WALL_SOUTH:
		if not _spawn_window_wall(owner, "PerimeterWallSouth", south_center, total_length, WALL_SOUTH, full_wall_height, wall_thickness, wall_mat):
			_spawn_wall(owner, "PerimeterWallSouth", south_center, Vector3(total_length, full_wall_height, wall_thickness), wall_mat)
	else:
		_spawn_wall(owner, "PerimeterWallSouth", south_center, Vector3(total_length, full_wall_height, wall_thickness), wall_mat)

	var west_center := Vector3(-half_length - wall_thickness * 0.5, wall_y, center_z)
	if elevator_wall == WALL_WEST:
		elevator_ref = _spawn_wall_with_elevator(owner, "PerimeterWallWest", west_center, total_depth, WALL_WEST, wall_mat, elevator_center_z, full_wall_height, wall_thickness, wall_height)
	elif window_wall_id == WALL_WEST:
		if not _spawn_window_wall(owner, "PerimeterWallWest", west_center, total_depth, WALL_WEST, full_wall_height, wall_thickness, wall_mat):
			_spawn_wall(owner, "PerimeterWallWest", west_center, Vector3(wall_thickness, full_wall_height, total_depth), wall_mat)
	else:
		_spawn_wall(owner, "PerimeterWallWest", west_center, Vector3(wall_thickness, full_wall_height, total_depth), wall_mat)

	var east_center := Vector3(half_length + wall_thickness * 0.5, wall_y, center_z)
	if elevator_wall == WALL_EAST:
		elevator_ref = _spawn_wall_with_elevator(owner, "PerimeterWallEast", east_center, total_depth, WALL_EAST, wall_mat, elevator_center_z, full_wall_height, wall_thickness, wall_height)
	elif window_wall_id == WALL_EAST:
		if not _spawn_window_wall(owner, "PerimeterWallEast", east_center, total_depth, WALL_EAST, full_wall_height, wall_thickness, wall_mat):
			_spawn_wall(owner, "PerimeterWallEast", east_center, Vector3(wall_thickness, full_wall_height, total_depth), wall_mat)
	else:
		_spawn_wall(owner, "PerimeterWallEast", east_center, Vector3(wall_thickness, full_wall_height, total_depth), wall_mat)

	return elevator_ref

func _spawn_wall(owner: Node3D, name: String, position: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	var wall_body := StaticBody3D.new()
	wall_body.name = name
	wall_body.position = position
	owner.add_child(wall_body)

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

func _spawn_wall_with_elevator(
	owner: Node3D,
	base_name: String,
	wall_center: Vector3,
	span_length: float,
	wall_id: String,
	material: StandardMaterial3D,
	elevator_axis_center: float,
	full_wall_height: float,
	wall_thickness: float,
	door_height: float
	) -> Node3D:
	if span_length <= 0.0 or full_wall_height <= 0.0:
		return null

	var margin: float = maxf(0.25, wall_thickness)
	var available_opening: float = maxf(0.0, span_length - margin * 2.0)
	var target_opening: float = minf(ELEVATOR_OPENING_TARGET_WIDTH, available_opening)
	if target_opening <= 0.0:
		target_opening = available_opening
	var opening_width: float = target_opening
	var half_opening: float = opening_width * 0.5
	var start: float = -span_length * 0.5
	var end: float = span_length * 0.5
	var axis_origin: float = wall_center.x if wall_id == WALL_NORTH or wall_id == WALL_SOUTH else wall_center.z
	var local_axis_center: float = elevator_axis_center - axis_origin
	var min_center: float = start + half_opening + margin
	var max_center: float = end - half_opening - margin
	var clamped_center: float = (start + end) * 0.5 if min_center > max_center else clampf(local_axis_center, min_center, max_center)
	var left_end: float = clamped_center - half_opening
	var right_start: float = clamped_center + half_opening
	var wall_is_ns := wall_id == WALL_NORTH or wall_id == WALL_SOUTH
	var effective_door_height: float = maxf(door_height, 2.2)
	if effective_door_height > full_wall_height:
		effective_door_height = full_wall_height
	var wall_bottom := wall_center.y - full_wall_height * 0.5
	var door_bottom := wall_bottom
	var door_top := door_bottom + effective_door_height

	if left_end - start > 0.05:
		var left_length: float = left_end - start
		var left_center: float = (start + left_end) * 0.5
		var left_position := wall_center
		var left_size: Vector3
		if wall_is_ns:
			left_position.x = wall_center.x + left_center
			left_size = Vector3(left_length, full_wall_height, wall_thickness)
		else:
			left_position.z = wall_center.z + left_center
			left_size = Vector3(wall_thickness, full_wall_height, left_length)
		_spawn_wall(owner, "%s_Left" % base_name, left_position, left_size, material)

	if end - right_start > 0.05:
		var right_length: float = end - right_start
		var right_center: float = (right_start + end) * 0.5
		var right_position := wall_center
		var right_size: Vector3
		if wall_is_ns:
			right_position.x = wall_center.x + right_center
			right_size = Vector3(right_length, full_wall_height, wall_thickness)
		else:
			right_position.z = wall_center.z + right_center
			right_size = Vector3(wall_thickness, full_wall_height, right_length)
		_spawn_wall(owner, "%s_Right" % base_name, right_position, right_size, material)

	var header_height: float = minf(0.35, effective_door_height * 0.25)
	if header_height > 0.05 and opening_width > 0.2:
		var header_position := wall_center
		var header_size: Vector3
		if wall_is_ns:
			header_position.x = wall_center.x + clamped_center
			header_size = Vector3(opening_width, header_height, wall_thickness)
		else:
			header_position.z = wall_center.z + clamped_center
			header_size = Vector3(wall_thickness, header_height, opening_width)
		header_position.y = door_top - header_height * 0.5
		_spawn_wall(owner, "%s_Header" % base_name, header_position, header_size, material)

	var upper_extension: float = full_wall_height - effective_door_height
	if upper_extension > 0.05 and opening_width > 0.2:
		var fill_position := wall_center
		var fill_size: Vector3
		if wall_is_ns:
			fill_position.x = wall_center.x + clamped_center
			fill_size = Vector3(opening_width, upper_extension, wall_thickness)
		else:
			fill_position.z = wall_center.z + clamped_center
			fill_size = Vector3(wall_thickness, upper_extension, opening_width)
		fill_position.y = door_top + upper_extension * 0.5
		_spawn_wall(owner, "%s_TopFill" % base_name, fill_position, fill_size, material)

	var door_center := wall_center
	var inward_normal := Vector3.ZERO
	var rotation := Vector3.ZERO
	if wall_id == WALL_NORTH:
		door_center.x = wall_center.x + clamped_center
		door_center.z = wall_center.z + wall_thickness * 0.5
		inward_normal = Vector3(0.0, 0.0, 1.0)
		rotation = Vector3.ZERO
	elif wall_id == WALL_SOUTH:
		door_center.x = wall_center.x + clamped_center
		door_center.z = wall_center.z - wall_thickness * 0.5
		inward_normal = Vector3(0.0, 0.0, -1.0)
		rotation = Vector3(0.0, 180.0, 0.0)
	elif wall_id == WALL_EAST:
		door_center.z = wall_center.z + clamped_center
		door_center.x = wall_center.x - wall_thickness * 0.5
		inward_normal = Vector3(-1.0, 0.0, 0.0)
		rotation = Vector3(0.0, -90.0, 0.0)
	else:
		door_center.z = wall_center.z + clamped_center
		door_center.x = wall_center.x + wall_thickness * 0.5
		inward_normal = Vector3(1.0, 0.0, 0.0)
		rotation = Vector3(0.0, 90.0, 0.0)
	door_center.y = door_bottom + effective_door_height * 0.5

	return _create_elevator(owner, door_center, inward_normal, rotation, effective_door_height, wall_thickness)

func _spawn_window_wall(
	owner: Node3D,
	name: String,
	wall_center: Vector3,
	span_length: float,
	wall_id: String,
	full_wall_height: float,
	wall_thickness: float,
	material: StandardMaterial3D
	) -> bool:
	if span_length <= 0.0 or full_wall_height <= 0.0 or wall_thickness <= 0.0:
		return false
	var side_span := span_length
	var frame_width := maxf(0.2, wall_thickness)
	if frame_width * 2.0 >= side_span:
		return false
	var usable_span := side_span - frame_width * 2.0
	if usable_span <= 0.4:
		return false
	var segment_count: int = int(max(2, WINDOW_SEGMENT_COUNT))
	var mullion_width: float = 0.0
	var glass_width: float = 0.0
	while segment_count > 1:
		mullion_width = clampf(WINDOW_MULLION_WIDTH, 0.05, usable_span / (float(segment_count) * 3.0))
		var total_mullion := mullion_width * float(segment_count - 1)
		glass_width = (usable_span - total_mullion) / float(segment_count)
		if glass_width > 0.2:
			break
		segment_count -= 1
	if segment_count <= 1 or glass_width <= 0.2:
		return false
	var step: float = glass_width + mullion_width
	var wall_root: Node3D = Node3D.new()
	wall_root.name = name
	wall_root.position = wall_center
	owner.add_child(wall_root)

	var collision_body: StaticBody3D = StaticBody3D.new()
	collision_body.name = "%sCollision" % name
	wall_root.add_child(collision_body)

	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	var collision_box: BoxShape3D = BoxShape3D.new()
	var is_north_south := wall_id == WALL_NORTH or wall_id == WALL_SOUTH
	var outward_normal := _get_wall_normal(wall_id)
	var glass_offset_distance := maxf(0.0, wall_thickness * 0.5 - WINDOW_GLASS_INSET)
	if is_north_south:
		collision_box.size = Vector3(side_span, full_wall_height, wall_thickness)
	else:
		collision_box.size = Vector3(wall_thickness, full_wall_height, side_span)
	collision_shape.shape = collision_box
	collision_body.add_child(collision_shape)

	var frame_material := material
	var left_frame: MeshInstance3D = MeshInstance3D.new()
	var left_mesh: BoxMesh = BoxMesh.new()
	if is_north_south:
		left_mesh.size = Vector3(frame_width, full_wall_height, wall_thickness)
		left_frame.position = Vector3(-side_span * 0.5 + frame_width * 0.5, 0.0, 0.0)
	else:
		left_mesh.size = Vector3(wall_thickness, full_wall_height, frame_width)
		left_frame.position = Vector3(0.0, 0.0, -side_span * 0.5 + frame_width * 0.5)
	left_frame.mesh = left_mesh
	left_frame.material_override = frame_material
	wall_root.add_child(left_frame)

	var right_frame: MeshInstance3D = MeshInstance3D.new()
	var right_mesh: BoxMesh = BoxMesh.new()
	if is_north_south:
		right_mesh.size = Vector3(frame_width, full_wall_height, wall_thickness)
		right_frame.position = Vector3(side_span * 0.5 - frame_width * 0.5, 0.0, 0.0)
	else:
		right_mesh.size = Vector3(wall_thickness, full_wall_height, frame_width)
		right_frame.position = Vector3(0.0, 0.0, side_span * 0.5 - frame_width * 0.5)
	right_frame.mesh = right_mesh
	right_frame.material_override = frame_material
	wall_root.add_child(right_frame)

	var glass_material: StandardMaterial3D = _create_glass_material()
	var base_offset: float = -side_span * 0.5 + frame_width + glass_width * 0.5
	for segment in range(segment_count):
		var glass: MeshInstance3D = MeshInstance3D.new()
		glass.name = "%sGlass_%d" % [name, segment]
		var glass_mesh: QuadMesh = QuadMesh.new()
		glass_mesh.size = Vector2(glass_width, full_wall_height)
		glass.mesh = glass_mesh
		glass.material_override = glass_material
		glass.rotation_degrees = _get_wall_rotation_degrees(wall_id)
		var segment_position := Vector3.ZERO
		if is_north_south:
			segment_position.x = base_offset + step * float(segment)
		else:
			segment_position.z = base_offset + step * float(segment)
		segment_position += outward_normal * glass_offset_distance
		glass.position = segment_position
		glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wall_root.add_child(glass)

	if segment_count > 1:
		for mullion_index in range(segment_count - 1):
			var mullion: MeshInstance3D = MeshInstance3D.new()
			var mullion_mesh: BoxMesh = BoxMesh.new()
			if is_north_south:
				mullion_mesh.size = Vector3(mullion_width, full_wall_height, wall_thickness)
			else:
				mullion_mesh.size = Vector3(wall_thickness, full_wall_height, mullion_width)
			mullion.mesh = mullion_mesh
			mullion.material_override = frame_material
			var mullion_position := Vector3.ZERO
			var mullion_offset := base_offset + step * float(mullion_index) + glass_width * 0.5 + mullion_width * 0.5
			if is_north_south:
				mullion_position.x = mullion_offset
			else:
				mullion_position.z = mullion_offset
			wall_root.add_child(mullion)
			mullion.position = mullion_position

	var outside_plane: MeshInstance3D = MeshInstance3D.new()
	outside_plane.name = "%sOutside" % name
	var outside_mesh: QuadMesh = QuadMesh.new()
	outside_mesh.size = Vector2(maxf(usable_span, glass_width), full_wall_height * 1.02)
	outside_plane.mesh = outside_mesh
	outside_plane.rotation_degrees = _get_wall_rotation_degrees(wall_id)
	var outside_offset_distance := glass_offset_distance + WINDOW_GLASS_INSET * 1.2
	var outside_position := outward_normal * outside_offset_distance
	outside_plane.position = outside_position
	var outside_material: StandardMaterial3D = StandardMaterial3D.new()
	outside_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outside_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	outside_material.albedo_color = WINDOW_DAY_COLOR
	outside_material.emission_enabled = true
	outside_material.emission = WINDOW_DAY_COLOR
	outside_material.emission_energy = WINDOW_DAY_EMISSION
	outside_plane.material_override = outside_material
	outside_plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wall_root.add_child(outside_plane)

	if WINDOW_CONTROLLER_SCRIPT != null:
		var controller: WindowDayNightController = WINDOW_CONTROLLER_SCRIPT.new()
		if controller:
			controller.name = "%sDayNight" % name
			controller.setup(outside_material, WINDOW_DAY_COLOR, WINDOW_DAY_EMISSION, WINDOW_NIGHT_COLOR, WINDOW_NIGHT_EMISSION)
			wall_root.add_child(controller)

	return true

func _get_adjacent_window_wall(elevator_wall: String) -> String:
	match elevator_wall:
		WALL_NORTH:
			return WALL_WEST
		WALL_EAST:
			return WALL_NORTH
		WALL_SOUTH:
			return WALL_EAST
		WALL_WEST:
			return WALL_SOUTH
		_:
			return WALL_NORTH

func _get_wall_normal(wall_id: String) -> Vector3:
	match wall_id:
		WALL_NORTH:
			return Vector3(0.0, 0.0, -1.0)
		WALL_SOUTH:
			return Vector3(0.0, 0.0, 1.0)
		WALL_EAST:
			return Vector3(1.0, 0.0, 0.0)
		WALL_WEST:
			return Vector3(-1.0, 0.0, 0.0)
		_:
			return Vector3.ZERO

func _get_wall_rotation_degrees(wall_id: String) -> Vector3:
	match wall_id:
		WALL_NORTH:
			return Vector3(0.0, 180.0, 0.0)
		WALL_SOUTH:
			return Vector3.ZERO
		WALL_EAST:
			return Vector3(0.0, -90.0, 0.0)
		WALL_WEST:
			return Vector3(0.0, 90.0, 0.0)
		_:
			return Vector3.ZERO

func _create_glass_material() -> StandardMaterial3D:
	var glass_material := StandardMaterial3D.new()
	glass_material.albedo_color = Color(0.78, 0.86, 0.95, 0.2)
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_material.roughness = 0.25
	glass_material.specular = 0.8
	glass_material.refraction_enabled = true
	glass_material.refraction_scale = 0.02
	glass_material.emission_enabled = true
	glass_material.emission = Color(0.12, 0.18, 0.22, 0.2)
	glass_material.emission_energy = 0.3
	return glass_material

func _create_elevator(
	owner: Node3D,
	door_center: Vector3,
	inward_normal: Vector3,
	rotation_degrees: Vector3,
	wall_height: float,
	wall_thickness: float
	) -> Node3D:
	if _elevator_script == null:
		return null
	var elevator_instance: Object = _elevator_script.new()
	if elevator_instance == null:
		return null
	var elevator: Node3D = elevator_instance as Node3D
	if elevator == null:
		return null
	elevator.name = "Elevator"
	var elevator_height_value: float = maxf(wall_height, 2.5) - 0.32
	elevator.set("elevator_width", 2.0)
	elevator.set("elevator_depth", 2.0)
	elevator.set("elevator_height", elevator_height_value)
	var desired_door_thickness: float = clampf(wall_thickness * 0.5, 0.03, 0.06)
	elevator.set("door_panel_thickness", desired_door_thickness)
	var reveal_depth: float = wall_thickness + 0.2
	elevator.set("doorway_reveal_depth", reveal_depth)

	var elevator_depth: float = float(elevator.get("elevator_depth"))
	var normal: Vector3 = inward_normal.normalized()
	var clearance: float = wall_thickness * 0.5 + 0.02
	var inset: float = -elevator_depth * 0.5 - clearance
	var depth_offset: Vector3 = normal * inset
	var base_y: float = door_center.y - wall_height * 0.5
	elevator.position = Vector3(door_center.x, base_y, door_center.z) + depth_offset
	elevator.rotation_degrees = rotation_degrees

	owner.add_child(elevator)
	return elevator
