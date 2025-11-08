extends Node3D
# High-level office builder that spawns cubicle rows and shared lighting.

const DropCeiling := preload("res://scripts/drop_ceiling.gd")
const Cubicle := preload("res://scripts/cubicle.gd")
const Elevator := preload("res://scripts/elevator.gd")
const OfficeLayoutBuilderScript := preload("res://scripts/office_layout_builder.gd")
const OfficePerimeterBuilderScript := preload("res://scripts/office_perimeter_builder.gd")
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

func _rebuild_office() -> void:
	_clear_office()
	_build_environment()

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
	_build_perimeter(floor_length, floor_depth, floor_center, elevator_wall, elevator_center_x, elevator_center_z)

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

func _build_perimeter(total_length: float, total_depth: float, center_z: float, elevator_wall: String, elevator_center_x: float, elevator_center_z: float) -> void:
	if _perimeter_builder == null:
		return

	_perimeter_builder.create_perimeter(self, {
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
