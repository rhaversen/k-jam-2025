extends Control
# Dynamic Desktop Loader - Loads the appropriate desktop based on DesktopConfig

var desktop_instance: Control = null


func _ready() -> void:
	# Get the script path from config
	var script_path := DesktopConfig.get_desktop_script_path()
	
	# Load and instantiate the desktop script
	if ResourceLoader.exists(script_path):
		var DesktopScript = load(script_path)
		desktop_instance = DesktopScript.new()
		desktop_instance.name = "Desktop"
		
		# Make it fill the entire control
		desktop_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		add_child(desktop_instance)
		
		print("✅ Loaded desktop mode: %s" % DesktopConfig.get_mode_name())
	else:
		push_error("Desktop script not found: %s" % script_path)
