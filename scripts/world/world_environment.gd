extends WorldEnvironment

@export_group("Ambient Light")
@export var ambient_light_color: Color = Color(0.8, 0.8, 0.8)
@export var ambient_light_energy: float = 1.0
@export var contrast: float = 1.5

func _ready() -> void:
	_setup_environment()
	_setup_viewport_settings()

func _setup_environment() -> void:
	var env := Environment.new()
	
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.1)

	env.contrast = contrast
	
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient_light_color
	env.ambient_light_energy = ambient_light_energy
	
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	
	environment = env

func _setup_viewport_settings() -> void:
	var viewport := get_viewport()
	if viewport:
		viewport.msaa_3d = Viewport.MSAA_4X
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
