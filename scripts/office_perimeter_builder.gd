extends RefCounted
class_name OfficePerimeterBuilder

const WALL_NORTH := "north"
const WALL_EAST := "east"
const WALL_SOUTH := "south"
const WALL_WEST := "west"

var _elevator_script: Script

func _init(elevator_script: Script) -> void:
	_elevator_script = elevator_script

func create_perimeter(owner: Node3D, params: Dictionary) -> void:
	var total_length: float = float(params.get("total_length", 0.0))
	var total_depth: float = float(params.get("total_depth", 0.0))
	var center_z: float = float(params.get("center_z", 0.0))
	var elevator_wall: String = String(params.get("elevator_wall", WALL_EAST))
	var elevator_center_x: float = float(params.get("elevator_center_x", 0.0))
	var elevator_center_z: float = float(params.get("elevator_center_z", 0.0))
	var wall_height: float = float(params.get("perimeter_wall_height", 0.0))
	var wall_thickness: float = float(params.get("perimeter_wall_thickness", 0.0))
	var wall_color: Color = params.get("perimeter_wall_color", Color(0.72, 0.74, 0.78))

	if total_length <= 0.0 or total_depth <= 0.0:
		return
	if wall_height <= 0.0 or wall_thickness <= 0.0:
		return

	var half_length := total_length * 0.5
	var half_depth := total_depth * 0.5
	var wall_y := wall_height * 0.5 - 1.0

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = wall_color
	wall_mat.roughness = 0.85

	var north_center := Vector3(0.0, wall_y, center_z - half_depth - wall_thickness * 0.5)
	if elevator_wall == WALL_NORTH:
		_spawn_wall_with_elevator(owner, "PerimeterWallNorth", north_center, total_length, WALL_NORTH, wall_mat, elevator_center_x, wall_height, wall_thickness)
	else:
		_spawn_wall(owner, "PerimeterWallNorth", north_center, Vector3(total_length, wall_height, wall_thickness), wall_mat)

	var south_center := Vector3(0.0, wall_y, center_z + half_depth + wall_thickness * 0.5)
	if elevator_wall == WALL_SOUTH:
		_spawn_wall_with_elevator(owner, "PerimeterWallSouth", south_center, total_length, WALL_SOUTH, wall_mat, elevator_center_x, wall_height, wall_thickness)
	else:
		_spawn_wall(owner, "PerimeterWallSouth", south_center, Vector3(total_length, wall_height, wall_thickness), wall_mat)

	var west_center := Vector3(-half_length - wall_thickness * 0.5, wall_y, center_z)
	if elevator_wall == WALL_WEST:
		_spawn_wall_with_elevator(owner, "PerimeterWallWest", west_center, total_depth, WALL_WEST, wall_mat, elevator_center_z, wall_height, wall_thickness)
	else:
		_spawn_wall(owner, "PerimeterWallWest", west_center, Vector3(wall_thickness, wall_height, total_depth), wall_mat)

	var east_center := Vector3(half_length + wall_thickness * 0.5, wall_y, center_z)
	if elevator_wall == WALL_EAST:
		_spawn_wall_with_elevator(owner, "PerimeterWallEast", east_center, total_depth, WALL_EAST, wall_mat, elevator_center_z, wall_height, wall_thickness)
	else:
		_spawn_wall(owner, "PerimeterWallEast", east_center, Vector3(wall_thickness, wall_height, total_depth), wall_mat)

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
	wall_height: float,
	wall_thickness: float
) -> void:
	if span_length <= 0.0:
		return

	var opening_width: float = clampf(2.4, 0.0, maxf(0.0, span_length - 0.5))
	var half_opening: float = opening_width * 0.5
	var margin: float = maxf(0.25, wall_thickness)
	var start: float = -span_length * 0.5
	var end: float = span_length * 0.5
	var axis_origin: float = wall_center.x if wall_id == WALL_NORTH or wall_id == WALL_SOUTH else wall_center.z
	var local_axis_center: float = elevator_axis_center - axis_origin
	var min_center: float = start + half_opening + margin
	var max_center: float = end - half_opening - margin
	var clamped_center: float = (start + end) * 0.5 if min_center > max_center else clampf(local_axis_center, min_center, max_center)
	var left_end: float = clamped_center - half_opening
	var right_start: float = clamped_center + half_opening

	if left_end - start > 0.05:
		var left_length: float = left_end - start
		var left_center: float = (start + left_end) * 0.5
		var left_position := wall_center
		var left_size: Vector3
		if wall_id == WALL_NORTH or wall_id == WALL_SOUTH:
			left_position.x = wall_center.x + left_center
			left_size = Vector3(left_length, wall_height, wall_thickness)
		else:
			left_position.z = wall_center.z + left_center
			left_size = Vector3(wall_thickness, wall_height, left_length)
		_spawn_wall(owner, "%s_Left" % base_name, left_position, left_size, material)

	if end - right_start > 0.05:
		var right_length: float = end - right_start
		var right_center: float = (right_start + end) * 0.5
		var right_position := wall_center
		var right_size: Vector3
		if wall_id == WALL_NORTH or wall_id == WALL_SOUTH:
			right_position.x = wall_center.x + right_center
			right_size = Vector3(right_length, wall_height, wall_thickness)
		else:
			right_position.z = wall_center.z + right_center
			right_size = Vector3(wall_thickness, wall_height, right_length)
		_spawn_wall(owner, "%s_Right" % base_name, right_position, right_size, material)

	var header_height: float = minf(0.35, wall_height * 0.25)
	if header_height > 0.05 and opening_width > 0.2:
		var header_position := wall_center
		var header_size: Vector3
		if wall_id == WALL_NORTH or wall_id == WALL_SOUTH:
			header_position.x = wall_center.x + clamped_center
			header_size = Vector3(opening_width, header_height, wall_thickness)
		else:
			header_position.z = wall_center.z + clamped_center
			header_size = Vector3(wall_thickness, header_height, opening_width)
		header_position.y = wall_center.y + (wall_height - header_height) * 0.5
		_spawn_wall(owner, "%s_Header" % base_name, header_position, header_size, material)

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

	_create_elevator(owner, door_center, inward_normal, rotation, wall_height, wall_thickness)

func _create_elevator(
	owner: Node3D,
	door_center: Vector3,
	inward_normal: Vector3,
	rotation_degrees: Vector3,
	wall_height: float,
	wall_thickness: float
) -> void:
	if _elevator_script == null:
		return
	var elevator_instance: Object = _elevator_script.new()
	if elevator_instance == null:
		return
	var elevator: Node3D = elevator_instance as Node3D
	if elevator == null:
		return
	elevator.name = "Elevator"
	var elevator_height_value: float = maxf(wall_height, 2.5)
	elevator.set("elevator_width", 2.0)
	elevator.set("elevator_depth", 2.0)
	elevator.set("elevator_height", elevator_height_value)

	var elevator_depth: float = float(elevator.get("elevator_depth"))
	var normal: Vector3 = inward_normal.normalized()
	var inset: float = -elevator_depth * 0.5
	var depth_offset: Vector3 = normal * inset
	var base_y: float = door_center.y - wall_height * 0.5
	elevator.position = Vector3(door_center.x, base_y, door_center.z) + depth_offset
	elevator.rotation_degrees = rotation_degrees

	owner.add_child(elevator)
	_position_player(owner, elevator)

func _position_player(owner: Node3D, elevator: Node3D) -> void:
	var player: Node3D = owner.get_node_or_null("../Player")
	if player == null:
		player = owner.get_tree().get_root().find_child("Player", true, false)
	if player == null:
		return

	var spawn_point := elevator.global_transform.origin + elevator.global_transform.basis.z * 0.25
	var height_offset := player.global_position.y - owner.global_transform.origin.y
	spawn_point.y = owner.global_transform.origin.y + height_offset
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
