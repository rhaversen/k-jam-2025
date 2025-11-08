extends Node3D
# Self-contained cubicle builder for office rows.

@export var cubicle_depth: float = 3.0
@export var wall_thickness: float = 0.06
@export var employee_id: int = 1

const WALL_HEIGHT := 2.0
const HALF_WIDTH := 2.0

var _built := false

func setup(id_value: int, depth: float, thickness: float) -> void:
	employee_id = id_value
	cubicle_depth = depth
	wall_thickness = thickness
	_rebuild()

func _ready() -> void:
	if not _built:
		_rebuild()

func _rebuild() -> void:
	_clear_children()
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.75, 0.75, 0.82)
	wall_mat.roughness = 0.9
	wall_mat.metallic = 0.0

	var interior_depth: float = float(max(cubicle_depth, 1.5))
	var front_edge_z: float = wall_thickness
	var back_center_z: float = -interior_depth - wall_thickness * 0.5
	var side_length: float = float(max(0.2, front_edge_z - back_center_z))
	var side_center_z: float = (back_center_z + front_edge_z) * 0.5

	var back_wall_size := Vector3(HALF_WIDTH * 2.0, WALL_HEIGHT, wall_thickness)
	var back_wall := _create_static_mesh_body(self, back_wall_size, wall_mat, Vector3(0, 0, back_center_z))
	back_wall.name = "BackWall"

	var side_wall_size := Vector3(wall_thickness, WALL_HEIGHT, side_length)
	var left_wall := _create_static_mesh_body(self, side_wall_size, wall_mat, Vector3(-HALF_WIDTH, 0, side_center_z))
	left_wall.name = "LeftWall"

	var right_wall := _create_static_mesh_body(self, side_wall_size, wall_mat, Vector3(HALF_WIDTH, 0, side_center_z))
	right_wall.name = "RightWall"

	var front_wall_size := Vector3(HALF_WIDTH * 0.5, WALL_HEIGHT, wall_thickness)
	var front_wall_offset_x := -HALF_WIDTH + (front_wall_size.x * 0.5)
	var front_wall := _create_static_mesh_body(self, front_wall_size, wall_mat, Vector3(front_wall_offset_x, 0, wall_thickness * 0.5))
	front_wall.name = "FrontWall"
	_add_front_wall_id(front_wall, employee_id, front_wall_size)

	var desk := Node3D.new()
	desk.name = "Desk"
	var desk_depth := 1.0
	var desk_front_margin := 0.2
	var desk_back_margin := 0.2
	var min_center: float = -interior_depth + (desk_depth * 0.5) + desk_back_margin
	var max_center: float = front_edge_z - desk_front_margin - (desk_depth * 0.5)
	if min_center > max_center:
		var mid: float = (min_center + max_center) * 0.5
		min_center = mid
		max_center = mid
	var initial_center: float = -interior_depth + 1.0
	var desk_center_z: float = clampf(initial_center, min_center, max_center)
	var back_limit: float = -interior_depth + (desk_depth * 0.5)
	var front_limit: float = front_edge_z - (desk_depth * 0.5)
	var limit_min: float = float(min(back_limit, front_limit))
	var limit_max: float = float(max(back_limit, front_limit))
	desk_center_z = clampf(desk_center_z, limit_min, limit_max)
	desk.position = Vector3(0, 0, desk_center_z)
	add_child(desk)

	var desk_mat := StandardMaterial3D.new()
	desk_mat.albedo_color = Color(0.55, 0.45, 0.35)
	desk_mat.roughness = 0.6
	var desk_top := _create_static_mesh_body(desk, Vector3(2.2, 0.1, desk_depth), desk_mat, Vector3(0, -0.5, 0))
	desk_top.name = "DeskTop"

	var stand_mat := StandardMaterial3D.new()
	stand_mat.albedo_color = Color(0.05, 0.05, 0.05)
	stand_mat.roughness = 0.8

	var base_disc := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.25
	base_mesh.bottom_radius = 0.25
	base_mesh.height = 0.03
	base_disc.mesh = base_mesh
	base_disc.material_override = stand_mat
	base_disc.position = Vector3(0, -0.44, -0.25)
	desk.add_child(base_disc)

	var neck := MeshInstance3D.new()
	neck.mesh = BoxMesh.new()
	neck.mesh.size = Vector3(0.08, 0.28, 0.08)
	neck.material_override = stand_mat
	neck.position = Vector3(0, -0.29, -0.25)
	desk.add_child(neck)

	var monitor_body := MeshInstance3D.new()
	monitor_body.mesh = BoxMesh.new()
	monitor_body.mesh.size = Vector3(1.0, 0.6, 0.05)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.05, 0.05, 0.05)
	body_mat.roughness = 0.9
	monitor_body.material_override = body_mat
	monitor_body.position = Vector3(0, -0.02, -0.2)
	monitor_body.rotation_degrees = Vector3(0, 180, 0)
	desk.add_child(monitor_body)

	var screen := MeshInstance3D.new()
	screen.mesh = BoxMesh.new()
	screen.mesh.size = Vector3(0.9, 0.5, 0.01)
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.05, 0.1, 0.08)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.1, 0.8, 0.6)
	screen_mat.emission_energy_multiplier = 3.5
	screen.material_override = screen_mat
	screen.position = Vector3(0, 0, -0.03)
	monitor_body.add_child(screen)

	# Use a SpotLight3D to simulate the screen emitting light forward only
	var screen_light := SpotLight3D.new()
	screen_light.light_color = Color(0.3, 0.6, 0.6)
	screen_light.light_energy = 0.6
	screen_light.spot_range = 2.0
	screen_light.spot_angle = 90.0
	screen_light.spot_angle_attenuation = 0.5
	screen_light.position = Vector3(0, 0.0, -0.04)
	screen_light.rotation_degrees = Vector3(0, 0, 0)
	screen_light.shadow_enabled = true
	screen_light.shadow_opacity = 0.9
	screen_light.shadow_blur = 0.1
	screen_light.shadow_bias = 0.05
	screen_light.shadow_normal_bias = 1.0
	screen.add_child(screen_light)

	# Add monitor flicker script to screen - it will control both emission and light
	var flicker_script = load("res://scripts/monitor_flicker.gd")
	screen.set_script(flicker_script)
	screen.set("base_light_energy", 0.6)

	var mouse := MeshInstance3D.new()
	var mouse_mesh := BoxMesh.new()
	mouse_mesh.size = Vector3(0.1, 0.04, 0.15)
	mouse.mesh = mouse_mesh

	var mouse_mat := StandardMaterial3D.new()
	mouse_mat.albedo_color = Color(0.3, 0.3, 0.3)
	mouse_mat.roughness = 0.6
	mouse_mat.metallic = 0.05
	mouse.material_override = mouse_mat

	mouse.position = Vector3(0.45, -0.40, 0.25)
	desk.add_child(mouse)

	var mouse_line := MeshInstance3D.new()
	var line_mesh := BoxMesh.new()
	line_mesh.size = Vector3(0.01, 0.002, 0.09)
	mouse_line.mesh = line_mesh

	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.05, 0.05, 0.05)
	line_mat.roughness = 0.7
	mouse_line.material_override = line_mat

	mouse_line.position = Vector3(0, 0.022, -0.04)
	mouse.add_child(mouse_line)

	var mug := MeshInstance3D.new()
	var mug_mesh := CylinderMesh.new()
	mug_mesh.top_radius = 0.1
	mug_mesh.bottom_radius = 0.1
	mug_mesh.height = 0.25
	mug.mesh = mug_mesh

	var mug_mat := StandardMaterial3D.new()
	mug_mat.albedo_color = Color(0.9, 0.9, 0.9)
	mug_mat.roughness = 0.3
	mug.material_override = mug_mat

	mug.position = Vector3(0.8, -0.42, 0.25)
	desk.add_child(mug)

	var handle_mat := mug_mat

	var handle_top := MeshInstance3D.new()
	var mesh_top := CylinderMesh.new()
	mesh_top.top_radius = 0.02
	mesh_top.bottom_radius = 0.02
	mesh_top.height = 0.06
	handle_top.mesh = mesh_top
	handle_top.material_override = handle_mat
	handle_top.rotation_degrees = Vector3(0, 0, 90)
	handle_top.position = Vector3(0.12, 0.1, 0.0)
	mug.add_child(handle_top)

	var handle_mid := MeshInstance3D.new()
	var mesh_mid := CylinderMesh.new()
	mesh_mid.top_radius = 0.02
	mesh_mid.bottom_radius = 0.02
	mesh_mid.height = 0.08
	handle_mid.mesh = mesh_mid
	handle_mid.material_override = handle_mat
	handle_mid.rotation_degrees = Vector3(0, 0, 0)
	handle_mid.position = Vector3(0.14, 0.07, 0.0)
	mug.add_child(handle_mid)

	var handle_bottom := MeshInstance3D.new()
	var mesh_bottom := CylinderMesh.new()
	mesh_bottom.top_radius = 0.02
	mesh_bottom.bottom_radius = 0.02
	mesh_bottom.height = 0.06
	handle_bottom.mesh = mesh_bottom
	handle_bottom.material_override = handle_mat
	handle_bottom.rotation_degrees = Vector3(0, 0, 90)
	handle_bottom.position = Vector3(0.12, 0.02, 0.0)
	mug.add_child(handle_bottom)

	var coffee_surface := MeshInstance3D.new()
	var coffee_mesh := CylinderMesh.new()
	coffee_mesh.top_radius = 0.075
	coffee_mesh.bottom_radius = 0.075
	coffee_mesh.height = 0.001
	coffee_surface.mesh = coffee_mesh

	var coffee_mat := StandardMaterial3D.new()
	coffee_mat.albedo_color = Color(0.25, 0.12, 0.05)
	coffee_mat.roughness = 0.4
	coffee_surface.material_override = coffee_mat

	coffee_surface.position = Vector3(0.0, 0.125, 0.0)
	mug.add_child(coffee_surface)

	var keyboard_base := MeshInstance3D.new()
	var kb_mesh := BoxMesh.new()
	kb_mesh.size = Vector3(0.7, 0.05, 0.28)
	keyboard_base.mesh = kb_mesh

	var kb_mat := StandardMaterial3D.new()
	kb_mat.albedo_color = Color(0.3, 0.3, 0.3)
	kb_mat.roughness = 0.6
	kb_mat.metallic = 0.05
	keyboard_base.material_override = kb_mat

	keyboard_base.position = Vector3(-0.05, -0.43, 0.25)
	desk.add_child(keyboard_base)

	var key_mat := StandardMaterial3D.new()
	key_mat.albedo_color = Color(0.05, 0.05, 0.05)
	key_mat.roughness = 0.8

	var key_size := Vector3(0.05, 0.02, 0.05)
	var start_x := -0.35
	var start_z := 0.37

	for row in range(4):
		for col in range(11):
			var key := MeshInstance3D.new()
			var key_mesh := BoxMesh.new()
			key_mesh.size = key_size
			key.mesh = key_mesh
			key.material_override = key_mat

			var x := start_x + col * 0.06
			var y := -0.40
			var z := start_z - row * 0.06
			key.position = Vector3(x, y, z)
			desk.add_child(key)

	_add_posters(self, interior_depth)
	_center_layout()
	_built = true

func _center_layout() -> void:
	var bounds := get_collision_bounds()
	var center_x := (float(bounds.get("min_x", 0.0)) + float(bounds.get("max_x", 0.0))) * 0.5
	var center_z := (float(bounds.get("min_z", 0.0)) + float(bounds.get("max_z", 0.0))) * 0.5
	if abs(center_x) < 0.0001 and abs(center_z) < 0.0001:
		return
	var offset := Vector3(center_x, 0.0, center_z)
	for child in get_children():
		if child is Node3D:
			child.position -= offset

func get_collision_bounds() -> Dictionary:
	var bounds := {
		"min_x": INF,
		"max_x": -INF,
		"min_z": INF,
		"max_z": -INF
	}
	_gather_collision_bounds(self, Transform3D.IDENTITY, bounds)
	if bounds["min_x"] == INF or bounds["max_x"] == -INF:
		bounds["min_x"] = 0.0
		bounds["max_x"] = 0.0
	if bounds["min_z"] == INF or bounds["max_z"] == -INF:
		bounds["min_z"] = 0.0
		bounds["max_z"] = 0.0
	bounds["width"] = bounds["max_x"] - bounds["min_x"]
	bounds["depth"] = bounds["max_z"] - bounds["min_z"]
	return bounds

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func make_poster_material(texture_path: String, poster_size) -> StandardMaterial3D:
	var tex := load(texture_path)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex

	var poster_w := 1.0
	var poster_h := 1.0
	if poster_size is Vector2:
		poster_w = poster_size.x
		poster_h = poster_size.y
	elif poster_size is Vector3:
		poster_w = poster_size.x
		poster_h = poster_size.y

	if tex is Texture2D and poster_h != 0.0:
		var img_size: Vector2i = tex.get_size()
		var img_aspect := float(img_size.x) / float(img_size.y)
		var poster_aspect := poster_w / poster_h

		var scale_x := 1.0
		var scale_y := 1.0
		if img_aspect > poster_aspect:
			scale_x = poster_aspect / img_aspect
		else:
			scale_y = img_aspect / poster_aspect

		mat.uv1_scale = Vector3(scale_x, scale_y, 1.0)
		mat.uv1_offset = Vector3((1.0 - scale_x) * 0.5, (1.0 - scale_y) * 0.5, 0.0)
	else:
		mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
		mat.uv1_offset = Vector3(0.0, 0.0, 0.0)

	mat.roughness = 0.4
	mat.albedo_color = Color(1, 1, 1)
	return mat

func _add_posters(parent: Node3D, depth: float) -> void:
	var target_h := 0.8
	var poster_z := -depth + 0.05

	var poster_back_left := MeshInstance3D.new()
	var poster_mesh_left := PlaneMesh.new()
	var tex_left := load("res://textures/poster1.png")
	var size_left := Vector2(1.0, 0.7)
	if tex_left is Texture2D and target_h > 0.0:
		var img_size_left: Vector2i = tex_left.get_size()
		if img_size_left.y != 0:
			var aspect_left := float(img_size_left.x) / float(img_size_left.y)
			size_left = Vector2(aspect_left * target_h, target_h)
	poster_mesh_left.size = size_left
	poster_back_left.mesh = poster_mesh_left
	poster_back_left.material_override = make_poster_material("res://textures/poster1.png", poster_mesh_left.size)
	poster_back_left.position = Vector3(-0.8, 0.4, poster_z)
	poster_back_left.rotation_degrees = Vector3(90, 0, 0)
	parent.add_child(poster_back_left)

	var poster_back_right := MeshInstance3D.new()
	var poster_mesh_right := PlaneMesh.new()
	var tex_right := load("res://textures/poster2.png")
	var size_right := Vector2(1.0, 0.7)
	if tex_right is Texture2D and target_h > 0.0:
		var img_size_right: Vector2i = tex_right.get_size()
		if img_size_right.y != 0:
			var aspect_right := float(img_size_right.x) / float(img_size_right.y)
			size_right = Vector2(aspect_right * target_h, target_h)
	poster_mesh_right.size = size_right
	poster_back_right.mesh = poster_mesh_right
	poster_back_right.material_override = make_poster_material("res://textures/poster2.png", poster_mesh_right.size)
	poster_back_right.position = Vector3(0.8, 0.4, poster_z)
	poster_back_right.rotation_degrees = Vector3(90, 0, 0)
	parent.add_child(poster_back_right)

func _add_front_wall_id(front_wall: StaticBody3D, id_value: int, wall_size: Vector3) -> void:
	if front_wall == null:
		return

	var header_label := Label3D.new()
	header_label.name = "EmployeeIDHeader"
	header_label.text = "EMPLOYEE"
	header_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	header_label.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
	header_label.pixel_size = 0.004
	header_label.font_size = 24
	header_label.modulate = Color(0.85, 0.7, 0.0)
	header_label.outline_size = 2
	header_label.outline_modulate = Color(0, 0, 0)
	header_label.position = Vector3(0, 0.2, wall_size.z * 0.5 + 0.01)
	header_label.rotation_degrees = Vector3.ZERO
	front_wall.add_child(header_label)

	var number_label := Label3D.new()
	number_label.name = "EmployeeID"
	number_label.text = "%02d" % id_value
	number_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	number_label.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
	number_label.pixel_size = 0.006
	number_label.font_size = 64
	number_label.modulate = Color(0.85, 0.7, 0.0)
	number_label.outline_size = 2
	number_label.outline_modulate = Color(0, 0, 0)
	number_label.position = Vector3(0, 0.0, wall_size.z * 0.5 + 0.01)
	number_label.rotation_degrees = Vector3.ZERO
	front_wall.add_child(number_label)

func _create_static_mesh_body(parent: Node3D, size: Vector3, material: StandardMaterial3D, local_offset: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = local_offset
	parent.add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	if material:
		mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var collision_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision_shape.shape = shape
	body.add_child(collision_shape)

	return body

func _gather_collision_bounds(node: Node3D, parent_transform: Transform3D, bounds: Dictionary) -> void:
	var current_transform := parent_transform * node.transform
	if node is CollisionShape3D:
		var shape := (node as CollisionShape3D).shape
		if shape is BoxShape3D:
			var half_extents: Vector3 = shape.size * 0.5
			for x_sign in [-1, 1]:
				for y_sign in [-1, 1]:
					for z_sign in [-1, 1]:
						var local_point := Vector3(half_extents.x * x_sign, half_extents.y * y_sign, half_extents.z * z_sign)
						var world_point := current_transform * local_point
						bounds["min_x"] = min(bounds["min_x"], world_point.x)
						bounds["max_x"] = max(bounds["max_x"], world_point.x)
						bounds["min_z"] = min(bounds["min_z"], world_point.z)
						bounds["max_z"] = max(bounds["max_z"], world_point.z)
	for child in node.get_children():
		if child is Node3D:
			_gather_collision_bounds(child, current_transform, bounds)
