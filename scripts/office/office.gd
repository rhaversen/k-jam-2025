extends Node3D
# High-level office builder that spawns cubicle rows and shared lighting.

const DropCeiling := preload("res://scripts/office/drop_ceiling.gd")
const Cubicle := preload("res://scripts/office/cubicle.gd")
const Elevator := preload("res://scripts/office/elevator.gd")
const OfficeLayoutBuilderScript := preload("res://scripts/office/office_layout_builder.gd")
const OfficePerimeterBuilderScript := preload("res://scripts/office/office_perimeter_builder.gd")
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
var _layout_builder: OfficeLayoutBuilder = OfficeLayoutBuilderScript.new()
var _perimeter_builder: OfficePerimeterBuilder = OfficePerimeterBuilderScript.new(Elevator)

func _ready() -> void:
	_is_ready = true
	_rebuild_office()
	
	# Start day music when office loads (for day 1)
	if typeof(GameState) != TYPE_NIL and GameState:
		GameState.play_day_music()
		if not GameState.disrepair_level_changed.is_connected(_on_game_state_disrepair_changed):
			GameState.disrepair_level_changed.connect(_on_game_state_disrepair_changed)

func _rebuild_office() -> void:
	_clear_office()

	if grid_rows <= 0 or grid_columns <= 0:
		var fallback_length := 12.0
		var fallback_depth := 6.0
		var fallback_center := 0.0
		_create_drop_ceiling(fallback_length, fallback_depth, fallback_center)
		_build_perimeter(fallback_length, fallback_depth, fallback_center, ELEVATOR_WALL_EAST, 0.0, 0.0)
		return

	var layout_data := _layout_builder.build(self, {
		"grid_rows": grid_rows,
		"grid_columns": grid_columns,
		"aisle_width": aisle_width,
		"wall_thickness": wall_thickness,
		"cubicle_depth": cubicle_depth,
		"cubicle_script": Cubicle
	})
	if layout_data.is_empty():
		return

	var floor_length: float = float(layout_data.get("floor_length", 0.0))
	var floor_depth: float = float(layout_data.get("floor_depth", 0.0))
	var floor_center: float = float(layout_data.get("floor_center", 0.0))
	var elevator_wall: String = String(layout_data.get("elevator_wall", ELEVATOR_WALL_EAST))
	var elevator_center_x: float = float(layout_data.get("elevator_center_x", 0.0))
	var elevator_center_z: float = float(layout_data.get("elevator_center_z", 0.0))
	var total_units: int = int(layout_data.get("total_units", 0))
	var total_cubicles: int = int(layout_data.get("total_cubicles", 0))

	_create_drop_ceiling(floor_length, floor_depth, floor_center)
	var elevator := _build_perimeter(floor_length, floor_depth, floor_center, elevator_wall, elevator_center_x, elevator_center_z)
	_position_player(elevator)

	print("✅ Generated %dx%d unit grid (%d units, %d cubicles total)." % [grid_rows, grid_columns, total_units, total_cubicles])


# ------------------------------------------------------------
# HELPER FUNCTIONS  (these go AFTER _ready(), not indented)
# ------------------------------------------------------------

func _clear_office() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _create_drop_ceiling(total_length: float, total_depth: float, center_z: float) -> void:
	if DropCeiling == null:
		return
	var ceiling := DropCeiling.new()
	add_child(ceiling)
	ceiling.setup(total_length, total_depth, center_z)

func _build_perimeter(total_length: float, total_depth: float, center_z: float, elevator_wall: String, elevator_center_x: float, elevator_center_z: float) -> Node3D:
	if _perimeter_builder == null:
		return null

	return _perimeter_builder.create_perimeter(self, {
		"total_length": total_length,
		"total_depth": total_depth,
		"center_z": center_z,
		"elevator_wall": elevator_wall,
		"elevator_center_x": elevator_center_x,
		"elevator_center_z": elevator_center_z,
		"perimeter_wall_height": perimeter_wall_height,
		"perimeter_wall_thickness": perimeter_wall_thickness,
		"perimeter_wall_color": perimeter_wall_color
	})

func _position_player(elevator: Node3D) -> void:
	if elevator == null:
		return
	var player: Node3D = get_parent().get_node_or_null("Player")
	if player == null:
		player = get_tree().get_root().find_child("Player", true, false)
	if player == null:
		return

	var used_desk_spawn := false
	if typeof(GameState) != TYPE_NIL and GameState and GameState.should_spawn_at_desk():
		var spawn_transform := Transform3D(GameState.desk_spawn_basis, GameState.desk_spawn_position)
		player.global_transform = spawn_transform
		used_desk_spawn = true
		GameState.set_next_spawn(GameState.SPAWN_ELEVATOR)

	if used_desk_spawn:
		_reset_player_motion(player)
		_play_return_camera_tween(player)
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
		_reset_player_motion(player)

func _reset_player_motion(player: Node3D) -> void:
	if player is CharacterBody3D:
		var body := player as CharacterBody3D
		body.velocity = Vector3.ZERO
		body.set("target_velocity", Vector3.ZERO)

func _play_return_camera_tween(player: Node3D) -> void:
	var camera := player.get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		return
	var duration := 0.6
	var start_transform := camera.global_transform
	var used_focus := false
	if typeof(GameState) != TYPE_NIL and GameState and GameState.has_desk_focus():
		start_transform = Transform3D(GameState.desk_focus_basis, GameState.desk_focus_position)
		duration = maxf(0.2, GameState.desk_focus_duration)
		used_focus = true
	else:
		var desk_area := get_tree().root.get_node_or_null("./Main/Area3D")
		if desk_area and desk_area is Area3D:
			var area_node := desk_area as Area3D
			duration = maxf(0.2, area_node.camera_move_duration)
			var rotation_radians := Vector3(
				deg_to_rad(area_node.camera_target_rotation.x),
				deg_to_rad(area_node.camera_target_rotation.y),
				deg_to_rad(area_node.camera_target_rotation.z)
			)
			var start_basis := Basis.from_euler(rotation_radians)
			start_transform = Transform3D(start_basis, area_node.camera_target_position)
		else:
			camera.frozen = false
			return
	var local_camera_transform := camera.transform
	var final_transform := player.global_transform * local_camera_transform
	camera.global_transform = start_transform
	camera.frozen = true
	var tween := create_tween()
	tween.tween_property(camera, "global_transform:basis", final_transform.basis.orthonormalized(), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(camera, "global_transform:origin", final_transform.origin, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func():
		camera.transform = local_camera_transform
		camera.frozen = false
		if used_focus:
			GameState.clear_desk_focus()
	)

func _on_game_state_disrepair_changed(day: int, intensity: float) -> void:
	if not _is_ready:
		return
	_rebuild_office()
