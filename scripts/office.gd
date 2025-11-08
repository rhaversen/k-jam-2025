extends Node3D
# High-level office builder that spawns cubicle rows and shared lighting.

const DropCeiling := preload("res://scripts/drop_ceiling.gd")
const Cubicle := preload("res://scripts/cubicle.gd")

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
	var floor_length: float = max(12.0, spacing * float(max(cubicle_count, 1)) + 6.0)
	var floor_depth: float = max(6.0, (max_z - min_z) + 6.0)
	var floor_center: float = (min_z + max_z) * 0.5
	_create_floor(floor_length, floor_depth, floor_center)
	_create_drop_ceiling(floor_length, floor_depth, floor_center)

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
