extends Node3D
class_name WindowDayNightController

var sky_material: StandardMaterial3D
var day_emission_color: Color = Color(0.75, 0.85, 1.0)
var day_emission_energy: float = 3.5
var night_emission_color: Color = Color(0.08, 0.1, 0.22)
var night_emission_energy: float = 0.8

var _signals_connected: bool = false

func setup(
	material: StandardMaterial3D,
	day_color: Color,
	day_energy: float,
	night_color: Color,
	night_energy: float
	) -> void:
	sky_material = material
	day_emission_color = day_color
	day_emission_energy = day_energy
	night_emission_color = night_color
	night_emission_energy = night_energy

func _ready() -> void:
	_apply_current_state()
	_connect_game_state_signals()

func _exit_tree() -> void:
	_disconnect_game_state_signals()

func _apply_current_state() -> void:
	if sky_material == null:
		return
	var is_daytime := true
	if typeof(GameState) != TYPE_NIL and GameState:
		is_daytime = not GameState.is_day_complete()
	if is_daytime:
		_set_day_mode()
	else:
		_set_night_mode()

func _set_day_mode() -> void:
	if sky_material == null:
		return
	sky_material.emission_enabled = true
	sky_material.emission = day_emission_color
	sky_material.emission_energy = day_emission_energy
	sky_material.albedo_color = day_emission_color

func _set_night_mode() -> void:
	if sky_material == null:
		return
	sky_material.emission_enabled = true
	sky_material.emission = night_emission_color
	sky_material.emission_energy = night_emission_energy
	sky_material.albedo_color = night_emission_color

func _connect_game_state_signals() -> void:
	if _signals_connected:
		return
	if typeof(GameState) == TYPE_NIL or not GameState:
		return
	var day_callable: Callable = Callable(self, "_on_day_progressed")
	if not GameState.is_connected("day_progressed", day_callable):
		GameState.connect("day_progressed", day_callable)
	var complete_callable: Callable = Callable(self, "_on_day_completed")
	if GameState.has_signal("day_completed") and not GameState.is_connected("day_completed", complete_callable):
		GameState.connect("day_completed", complete_callable)
	_signals_connected = true

func _disconnect_game_state_signals() -> void:
	if not _signals_connected:
		return
	if typeof(GameState) == TYPE_NIL or not GameState:
		_signals_connected = false
		return
	var day_callable: Callable = Callable(self, "_on_day_progressed")
	if GameState.is_connected("day_progressed", day_callable):
		GameState.disconnect("day_progressed", day_callable)
	var complete_callable: Callable = Callable(self, "_on_day_completed")
	if GameState.has_signal("day_completed") and GameState.is_connected("day_completed", complete_callable):
		GameState.disconnect("day_completed", complete_callable)
	_signals_connected = false

func _on_day_progressed(_new_day: int) -> void:
	_set_day_mode()

func _on_day_completed(_day: int) -> void:
	_set_night_mode()
