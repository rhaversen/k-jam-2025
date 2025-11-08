extends Control

@export var next_scene_path: String = "res://scenes/ComputerDesktop.tscn"

var boot_lines = [
	"Initializing system BIOS...",
	"Loading kernel modules...",
	"Mounting root filesystem...",
	"Starting network services...",
	"Checking disk integrity...",
	"Launching user session...",
	"Loading desktop environment...",
	"Initializing mail client...",
	"Starting background daemons...",
	"System ready."
]

var current_line := 0
var terminal_label: Label

func _ready() -> void:
	# --- Background ---
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(bg)

	# --- Terminal text ---
	terminal_label = Label.new()
	terminal_label.text = ""
	terminal_label.theme_type_variation = "Mono"  # Monospace font if available
	terminal_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green text
	terminal_label.position = Vector2(40, 40)
	terminal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	terminal_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	terminal_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(terminal_label)

	# Start booting simulation
	_start_boot_sequence()


func _start_boot_sequence() -> void:
	var timer := Timer.new()
	timer.wait_time = 0.05  # speed between lines
	timer.autostart = true
	timer.one_shot = false
	add_child(timer)
	timer.timeout.connect(_on_boot_tick)


func _on_boot_tick() -> void:
	if current_line < boot_lines.size():
		terminal_label.text += boot_lines[current_line] + "\n"
		current_line += 1
	else:
		# After all lines printed, delay then load desktop
		var end_timer := Timer.new()
		end_timer.wait_time = 1.5
		end_timer.one_shot = true
		add_child(end_timer)
		end_timer.timeout.connect(_load_desktop)
		end_timer.start()
		$Timer.queue_free() # stop the main timer


func _load_desktop() -> void:
	get_tree().change_scene_to_file(next_scene_path)
