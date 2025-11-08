extends Node3D

@export var ceiling_height: float = 1

@export var solid_plane_height: float = 1
@export var solid_plane_color: Color = Color(0.5, 0.5, 0.45)

@export var tile_height: float = 1
@export var tile_size: Vector2 = Vector2(2, 1)
@export var tile_gap: float = 0.1
@export var tile_color: Color = Color(0.6, 0.6, 0.55)
@export var tile_thickness: float = 0.01

@export var rod_height: float = 1
@export var rod_thickness: float = 0.03
@export var rod_color: Color = Color(0.9, 0.9, 0.9)

@export var light_height: float = 0.9
@export var light_spacing: Vector2 = Vector2(3.2, 3.0)
@export var light_range: float = 9.0
@export var light_energy: float = 1
@export var light_color: Color = Color(1.0, 0.98, 0.92)
@export var light_fixture_size: Vector2 = Vector2(1.1, 0.2)
@export var fixture_emission_energy: float = 1
@export var fixture_color: Color = Color(0.95, 0.96, 0.98)

func setup(total_length: float, total_depth: float, center_z: float) -> void:
	_clear_children()
	if total_length <= 0.0 or total_depth <= 0.0:
		return
	position = Vector3(0.0, ceiling_height, center_z)
	_create_solid_plane(total_length, total_depth)
	_create_ceiling_grid(total_length, total_depth)
	_create_lights(total_length, total_depth)

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _create_solid_plane(total_length: float, total_depth: float) -> void:
	var plane := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(total_length, total_depth)
	plane.mesh = plane_mesh
	
	var plane_mat := StandardMaterial3D.new()
	plane_mat.albedo_color = solid_plane_color
	plane_mat.roughness = 0.9
	plane.material_override = plane_mat
	
	plane.position = Vector3(0.0, solid_plane_height, 0.0)
	plane.rotation_degrees = Vector3(180, 0, 0)
	add_child(plane)

func _create_ceiling_grid(total_length: float, total_depth: float) -> void:
	var step_x: float = tile_size.x + tile_gap
	var step_z: float = tile_size.y + tile_gap
	
	var min_x := -total_length * 0.5
	var max_x := total_length * 0.5
	var min_z := -total_depth * 0.5
	var max_z := total_depth * 0.5
	
	var x := min_x + step_x * 0.5
	while x < max_x:
		var z := min_z + step_z * 0.5
		while z < max_z:
			_spawn_ceiling_tile(Vector3(x, 0.0, z))
			z += step_z
		x += step_x

func _spawn_ceiling_tile(local_position: Vector3) -> void:
	var tile := MeshInstance3D.new()
	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(tile_size.x, tile_thickness, tile_size.y)
	tile.mesh = tile_mesh
	
	var tile_mat := StandardMaterial3D.new()
	tile_mat.albedo_color = tile_color
	tile_mat.roughness = 0.8
	tile.material_override = tile_mat
	
	tile.position = local_position + Vector3(0.0, tile_height - tile_thickness * 0.5, 0.0)
	add_child(tile)

func _create_lights(total_length: float, total_depth: float) -> void:
	var step_x: float = max(light_spacing.x, 0.1)
	var step_z: float = max(light_spacing.y, 0.1)
	
	var min_x := -total_length * 0.5
	var max_x := total_length * 0.5
	var min_z := -total_depth * 0.5
	var max_z := total_depth * 0.5
	
	var epsilon := 0.001
	var x_positions: Array[float] = []
	var x := min_x + step_x * 0.5
	var x_limit := max_x - step_x * 0.5 + epsilon
	while x <= x_limit:
		x_positions.append(x)
		x += step_x
	if x_positions.is_empty():
		x_positions.append(0.0)
	
	var z_positions: Array[float] = []
	var z := min_z + step_z * 0.5
	var z_limit := max_z - step_z * 0.5 + epsilon
	while z <= z_limit:
		z_positions.append(z)
		z += step_z
	if z_positions.is_empty():
		z_positions.append(0.0)
	
	for x_pos in x_positions:
		for z_pos in z_positions:
			_spawn_fixture(Vector3(x_pos, light_height, z_pos))

func _spawn_fixture(local_position: Vector3) -> void:
	var fixture := Node3D.new()
	fixture.position = local_position
	add_child(fixture)

	var housing_height: float = 0.05
	var tube_radius: float = 0.02
	var tube_spacing: float = 0.05
	var casing_thickness: float = 0.01
	
	# Create thin casing frame (sides and top, open on bottom)
	var casing_mat := StandardMaterial3D.new()
	casing_mat.albedo_color = fixture_color
	casing_mat.roughness = 0.5
	casing_mat.metallic = 0.3
	
	# Top of casing
	var casing_top := MeshInstance3D.new()
	var casing_top_mesh := BoxMesh.new()
	casing_top_mesh.size = Vector3(light_fixture_size.x, casing_thickness, light_fixture_size.y)
	casing_top.mesh = casing_top_mesh
	casing_top.material_override = casing_mat
	casing_top.position = Vector3(0.0, casing_thickness * 0.5, 0.0)
	fixture.add_child(casing_top)
	
	# Left side of casing
	var casing_left := MeshInstance3D.new()
	var casing_left_mesh := BoxMesh.new()
	casing_left_mesh.size = Vector3(light_fixture_size.x, housing_height, casing_thickness)
	casing_left.mesh = casing_left_mesh
	casing_left.material_override = casing_mat
	casing_left.position = Vector3(0.0, -housing_height * 0.5, -light_fixture_size.y * 0.5 + casing_thickness * 0.5)
	fixture.add_child(casing_left)
	
	# Right side of casing
	var casing_right := MeshInstance3D.new()
	var casing_right_mesh := BoxMesh.new()
	casing_right_mesh.size = Vector3(light_fixture_size.x, housing_height, casing_thickness)
	casing_right.mesh = casing_right_mesh
	casing_right.material_override = casing_mat
	casing_right.position = Vector3(0.0, -housing_height * 0.5, light_fixture_size.y * 0.5 - casing_thickness * 0.5)
	fixture.add_child(casing_right)
	
	# Create two fluorescent tube cylinders going lengthwise (along X axis)
	var tube_length: float = light_fixture_size.x - 0.1
	var tube_offset_z: float = tube_spacing * 0.5
	
	# First tube
	var tube1 := MeshInstance3D.new()
	var tube1_mesh := CylinderMesh.new()
	tube1_mesh.top_radius = tube_radius
	tube1_mesh.bottom_radius = tube_radius
	tube1_mesh.height = tube_length
	tube1.mesh = tube1_mesh
	var tube1_mat := StandardMaterial3D.new()
	tube1_mat.albedo_color = light_color
	tube1_mat.emission_enabled = true
	tube1_mat.emission = light_color
	tube1_mat.emission_energy_multiplier = fixture_emission_energy * 2.0
	tube1.material_override = tube1_mat
	tube1.position = Vector3(0.0, -housing_height * 0.5, -tube_offset_z)
	tube1.rotation_degrees = Vector3(0, 0, 90)
	fixture.add_child(tube1)
	
	# Second tube
	var tube2 := MeshInstance3D.new()
	var tube2_mesh := CylinderMesh.new()
	tube2_mesh.top_radius = tube_radius
	tube2_mesh.bottom_radius = tube_radius
	tube2_mesh.height = tube_length
	tube2.mesh = tube2_mesh
	var tube2_mat := StandardMaterial3D.new()
	tube2_mat.albedo_color = light_color
	tube2_mat.emission_enabled = true
	tube2_mat.emission = light_color
	tube2_mat.emission_energy_multiplier = fixture_emission_energy * 2.0
	tube2.material_override = tube2_mat
	tube2.position = Vector3(0.0, -housing_height * 0.5, tube_offset_z)
	tube2.rotation_degrees = Vector3(0, 0, 90)
	fixture.add_child(tube2)
	
	# Add vertical rods at each end of the fixture
	var rod_offset_x := light_fixture_size.x * 0.5 - rod_thickness
	_spawn_rod(fixture, Vector3(rod_offset_x, 0.0, 0.0))
	_spawn_rod(fixture, Vector3(-rod_offset_x, 0.0, 0.0))

func _spawn_rod(parent: Node3D, local_position: Vector3) -> void:
	var rod := MeshInstance3D.new()
	var rod_mesh := CylinderMesh.new()
	rod_mesh.top_radius = rod_thickness
	rod_mesh.bottom_radius = rod_thickness
	rod_mesh.height = rod_height
	rod.mesh = rod_mesh
	
	var rod_mat := StandardMaterial3D.new()
	rod_mat.albedo_color = rod_color
	rod_mat.metallic = 0.7
	rod_mat.roughness = 0.4
	rod.material_override = rod_mat
	
	# Position rod to start from the top of the casing and go upward
	# The casing top is at y=0.01, so start the rod there
	rod.position = local_position + Vector3(0.0, 0.01 + rod_height * 0.5, 0.0)
	parent.add_child(rod)
