extends Control

@export var next_scene_path: String = "res://scenes/ComputerDesktop.tscn"

const BASE_LINE_DELAY := 0.01
const RANDOM_LINE_DELAY_RANGE := Vector2(0.02, 0.1)
const DEFAULT_MAX_LOG_LINES := 28
const LOADING_DURATION := 1
const HANDOFF_DELAY := 0.2
const LOADING_FRAME_DELAY := 0.18
const LOADING_FRAMES := ["|", "/", "—", "\\"]
const TERMINAL_MARGIN_LEFT := 0.0
const TERMINAL_MARGIN_RIGHT := 0.0
const TERMINAL_MARGIN_TOP := 32.0
const TERMINAL_MARGIN_BOTTOM := 64.0
const CURSOR_BLINK_INTERVAL := 0.45

var boot_lines = [
	"POST diagnostics: nominal, sarcasm module idle.",
	"Detecting CPU topology: 8 cores, threads gossiping.",
	"Mounting root filesystem (ext4) with optimism.",
	"Unlocking LUKS vault... passphrase remembered itself.",
	"Loading firmware blobs... 12 signed, 0 sticky.",
	"Syncing RTC via NTP... convinced server time is real.",
	"Negotiating DHCP lease... snagged IPv6 with style.",
	"Authenticating engineer profile... MFA approved your vibe.",
	"Warming shader cache... GPUs love preheated pipelines.",
	"Mounting workspace at /home/engineer... TODOs unchanged.",
	"Reviewing security policies... zero trust, full sass.",
	"Preparing UX hand-off... cursor warmed up.",
	"System ready for controlled chaos."
]

var current_line := 0
var terminal_label: Label
var boot_timer: Timer
var loading_timer: Timer
var loading_elapsed := 0.0
var loading_frame_index := 0
var loading_line_index := -1
var display_buffer: PackedStringArray = []
var cursor_timer: Timer
var cursor_visible := true
var max_log_lines := DEFAULT_MAX_LOG_LINES
var line_delay_timer: Timer
var background_rect: ColorRect

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# --- Background ---
	background_rect = ColorRect.new()
	background_rect.color = Color(0.18, 0.9, 0.72)
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_rect)
	_create_background_fade()

	# --- Terminal text ---
	terminal_label = Label.new()
	terminal_label.text = ""
	terminal_label.theme_type_variation = "Mono"
	terminal_label.add_theme_color_override("font_color", Color(0, 1, 0))
	var mono_font := SystemFont.new()
	mono_font.font_names = PackedStringArray(["Consolas", "Courier New", "Lucida Console", "monospace"])
	terminal_label.add_theme_font_override("font", mono_font)
	terminal_label.add_theme_font_size_override("font_size", 14)
	terminal_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	terminal_label.offset_left = TERMINAL_MARGIN_LEFT
	terminal_label.offset_top = TERMINAL_MARGIN_TOP
	terminal_label.offset_right = -TERMINAL_MARGIN_RIGHT
	terminal_label.offset_bottom = -TERMINAL_MARGIN_BOTTOM
	terminal_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terminal_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	terminal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	terminal_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	terminal_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	terminal_label.clip_text = false
	add_child(terminal_label)

	resized.connect(_on_resized)

	_init_cursor_timer()

	await get_tree().process_frame
	_ensure_layout_size()
	_recalculate_max_log_lines()
	_refresh_terminal_text()
	_start_boot_sequence()


func _create_background_fade() -> void:
	if background_rect == null:
		return
	var tween := create_tween()
	tween.tween_property(background_rect, "color", Color(0, 0, 0), 0.4)


func _start_boot_sequence() -> void:
	if line_delay_timer:
		line_delay_timer.queue_free()
	line_delay_timer = Timer.new()
	line_delay_timer.one_shot = true
	add_child(line_delay_timer)
	line_delay_timer.timeout.connect(_on_boot_tick)
	_schedule_next_line()


func _on_boot_tick() -> void:
	if current_line < boot_lines.size():
		_append_terminal_line(boot_lines[current_line])
		current_line += 1
		_schedule_next_line()
	else:
		if line_delay_timer:
			line_delay_timer.stop()
			line_delay_timer.queue_free()
			line_delay_timer = null
		_start_loading_animation()


func _schedule_next_line() -> void:
	if line_delay_timer == null:
		return
	var jitter := randf_range(RANDOM_LINE_DELAY_RANGE.x, RANDOM_LINE_DELAY_RANGE.y)
	line_delay_timer.wait_time = BASE_LINE_DELAY + jitter
	line_delay_timer.start()


func _append_terminal_line(line: String) -> void:
	display_buffer.append(line)
	_apply_log_limit()
	_refresh_terminal_text()


func _refresh_terminal_text() -> void:
	var lines := PackedStringArray()
	for existing_line in display_buffer:
		lines.append(existing_line)
	lines.append(_build_cursor_line())
	terminal_label.text = "\n".join(lines)


func _init_cursor_timer() -> void:
	if cursor_timer:
		return
	cursor_timer = Timer.new()
	cursor_timer.wait_time = CURSOR_BLINK_INTERVAL
	cursor_timer.one_shot = false
	cursor_timer.autostart = true
	add_child(cursor_timer)
	cursor_timer.timeout.connect(_on_cursor_blink)
	cursor_timer.start()


func _on_cursor_blink() -> void:
	cursor_visible = !cursor_visible
	_refresh_terminal_text()


func _build_cursor_line() -> String:
	return "_" if cursor_visible else " "


func _apply_log_limit() -> void:
	while display_buffer.size() > max_log_lines:
		display_buffer.remove_at(0)
		if loading_line_index > -1:
			loading_line_index -= 1
			if loading_line_index < 0:
				loading_line_index = -1


func _recalculate_max_log_lines() -> void:
	var font := terminal_label.get_theme_font("font", "Label")
	var font_size := terminal_label.get_theme_font_size("font_size", "Label")
	if font == null or font_size <= 0:
		max_log_lines = DEFAULT_MAX_LOG_LINES
		return
	var line_height := font.get_height(font_size)
	if line_height <= 0:
		max_log_lines = DEFAULT_MAX_LOG_LINES
		return
	var available_height := terminal_label.get_global_rect().size.y
	if available_height <= 0.0:
		available_height = get_viewport_rect().size.y - (TERMINAL_MARGIN_TOP + TERMINAL_MARGIN_BOTTOM)
	if available_height <= 0.0:
		max_log_lines = DEFAULT_MAX_LOG_LINES
		return
	var calculated := int(floor(available_height / line_height)) - 2
	max_log_lines = clamp(calculated, 1, DEFAULT_MAX_LOG_LINES)
	_apply_log_limit()


func _on_resized() -> void:
	_ensure_layout_size()
	_recalculate_max_log_lines()
	_refresh_terminal_text()


func _ensure_layout_size() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return
	set_size(viewport_size)


func _start_loading_animation() -> void:
	if loading_timer:
		return
	_append_terminal_line("")
	_append_terminal_line("Initiating hand-off to desktop orchestrator...")
	_append_terminal_line("Negotiating desktop channel... latency bribed with cookies.")
	_append_terminal_line("Preloading widgets and witty tooltips...")
	loading_elapsed = 0.0
	loading_frame_index = 0
	_append_terminal_line(_build_loading_line())
	loading_line_index = display_buffer.size() - 1
	loading_timer = Timer.new()
	loading_timer.wait_time = LOADING_FRAME_DELAY
	loading_timer.one_shot = false
	add_child(loading_timer)
	loading_timer.timeout.connect(_update_loading_animation)
	loading_timer.start()


func _update_loading_animation() -> void:
	loading_elapsed += LOADING_FRAME_DELAY
	_set_loading_line(_build_loading_line())
	loading_frame_index = (loading_frame_index + 1) % LOADING_FRAMES.size()
	if loading_elapsed >= LOADING_DURATION:
		if loading_timer:
			loading_timer.stop()
			loading_timer.queue_free()
			loading_timer = null
		_append_terminal_line("Hand-off complete; try not to break prod.")
		var end_timer := Timer.new()
		end_timer.wait_time = HANDOFF_DELAY
		end_timer.one_shot = true
		add_child(end_timer)
		end_timer.timeout.connect(_load_desktop)
		end_timer.start()


func _build_loading_line() -> String:
	var dots := ""
	var dot_count := int((loading_elapsed / LOADING_FRAME_DELAY)) % 4
	for _i in range(dot_count):
		dots += "."
	return "Loading engineer workspace %s%s" % [LOADING_FRAMES[loading_frame_index], dots]


func _set_loading_line(line: String) -> void:
	if loading_line_index == -1:
		_append_terminal_line(line)
		loading_line_index = display_buffer.size() - 1
		return
	if loading_line_index >= display_buffer.size():
		loading_line_index = display_buffer.size() - 1
	if loading_line_index > -1:
		display_buffer[loading_line_index] = line
		_refresh_terminal_text()


func _load_desktop() -> void:
	get_tree().change_scene_to_file(next_scene_path)
