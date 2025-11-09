extends Control
# Base desktop environment with UI elements, windows, and cursor
# Can be extended for specific applications/mini-games

const EXIT_SCENE_PATH := "res://node_3d.tscn"

var cursor: Sprite2D
var desktop_container: Control
var time_label: Label
var clock_start_hour: int = 8
var clock_end_hour: int = 16
var clock_current_time: float = 0.0  # In minutes (8:00 = 0, 16:00 = 480)
var clock_duration: float = 480.0  # Total minutes to simulate (8 hours = 480 minutes)


func _ready() -> void:
	# Hide the OS cursor so we can use our own
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	_create_background()
	_create_top_bar()
	_create_taskbar()

	# Create a dedicated desktop container for icons/elements
	desktop_container = Control.new()
	desktop_container.name = "desktop_container"
	desktop_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desktop_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(desktop_container)
	
	_create_exit_button()
	
	# Create cursor last to ensure it's on top
	_create_cursor()
	_mark_desk_task_complete()


# --- ENVIRONMENT SETUP ---

func _create_background() -> void:
	var bg := TextureRect.new()
	var wallpaper: Texture = load("res://textures/desktopwallpaper.jpg") as Texture
	if wallpaper:
		bg.texture = wallpaper
	else:
		push_warning("Failed to load wallpaper texture, using fallback color")
		bg.color = Color(0.1, 0.1, 0.2)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.custom_minimum_size = get_viewport_rect().size
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(bg)
	bg.z_index = -1


func _create_top_bar() -> void:
	var top_bar := ColorRect.new()
	top_bar.color = Color(0.05, 0.08, 0.12)
	top_bar.size = Vector2(get_viewport_rect().size.x, 40)
	add_child(top_bar)

	var apps_label := Label.new()
	apps_label.text = "APPLICATIONS"
	apps_label.position = Vector2(20, 10)
	apps_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1))
	top_bar.add_child(apps_label)

	time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.text = "08:00"
	time_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.8))
	time_label.position = Vector2(get_viewport_rect().size.x - 80, 10)
	top_bar.add_child(time_label)


func _create_taskbar() -> void:
	var taskbar := ColorRect.new()
	taskbar.color = Color(0.03, 0.06, 0.1)
	taskbar.size = Vector2(get_viewport_rect().size.x, 35)
	taskbar.position.y = get_viewport_rect().size.y - 35
	add_child(taskbar)

	var task_label := Label.new()
	task_label.text = "FILE EXPLORER   |   MAIL   |   NOTES"
	task_label.position = Vector2(20, 8)
	task_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1))
	taskbar.add_child(task_label)


# --- WINDOW CREATION UTILITY ---

func create_window(title: String, pos: Vector2, size: Vector2, is_dark: bool = false) -> PanelContainer:
	# Create the main window panel
	var panel := PanelContainer.new()
	panel.position = pos
	panel.custom_minimum_size = size
	panel.size = size
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.name = title

	# Create a VBox to hold header and content
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)

	# Window background style
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if is_dark:
		style.bg_color = Color(0.05, 0.08, 0.12)
		style.border_color = Color(0.15, 0.18, 0.25)
	else:
		style.bg_color = Color(0.96, 0.96, 0.96)
		style.border_color = Color(0.6, 0.6, 0.6)
	
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", style)

	# Title bar
	var header_bar := ColorRect.new()
	header_bar.color = Color(0.12, 0.18, 0.25)
	header_bar.custom_minimum_size = Vector2(size.x, 30)
	header_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	vbox.add_child(header_bar)

	# Make header draggable
	header_bar.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					panel.set_meta("drag_offset", panel.get_global_mouse_position() - panel.position)
					panel.set_meta("is_dragging", true)
				else:
					panel.set_meta("is_dragging", false)
		elif event is InputEventMouseMotion:
			if panel.get_meta("is_dragging", false):
				var drag_offset = panel.get_meta("drag_offset", Vector2.ZERO)
				panel.position = panel.get_global_mouse_position() - drag_offset
	)

	# Header layout
	var header_hbox := HBoxContainer.new()
	header_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.custom_minimum_size = Vector2(size.x, 30)
	header_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	header_bar.add_child(header_hbox)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(10, 0)
	header_hbox.add_child(spacer)

	# Title label
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.mouse_filter = Control.MOUSE_FILTER_PASS
	header_hbox.add_child(title_label)

	# Close button
	var header_close := Button.new()
	header_close.text = "X"
	header_close.custom_minimum_size = Vector2(22, 22)
	header_close.size_flags_horizontal = Control.SIZE_SHRINK_END
	header_close.connect("pressed", Callable(self, "_on_window_close_requested").bind(panel))
	header_hbox.add_child(header_close)

	# Content container
	var content := VBoxContainer.new()
	content.name = "content"
	content.custom_minimum_size = Vector2(size.x, max(0, size.y - 30))
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content)

	panel.set_meta("is_dark", is_dark)

	return panel


func _on_window_close_requested(window: PanelContainer) -> void:
	if window and is_instance_valid(window):
		window.queue_free()


func bring_to_front(win: Node) -> void:
	if not (win and win is CanvasItem):
		return
	var parent = win.get_parent()
	if not parent:
		return
	var max_z := 0
	for c_base in parent.get_children():
		var c: CanvasItem = c_base as CanvasItem
		if c:
			max_z = max(max_z, c.z_index)
	var allowed_max: int = RenderingServer.CANVAS_ITEM_Z_MAX
	var next_z: int = min(max_z + 1, allowed_max)
	win.z_index = next_z
	
	# Ensure cursor stays above
	if cursor and is_instance_valid(cursor):
		cursor.z_index = allowed_max


func find_child_by_name(root: Node, name: String) -> Node:
	if not root:
		return null
	
	for child in root.get_children():
		if child.name == name:
			return child
		var res := find_child_by_name(child, name)
		if res:
			return res
	
	return null


# --- CUSTOM CURSOR ---

func _create_cursor() -> void:
	cursor = Sprite2D.new()
	var texture_path := "res://textures/cursor.png"
	var cursor_tex: Texture2D = null
	if ResourceLoader.exists(texture_path):
		cursor_tex = load(texture_path) as Texture2D
	if cursor_tex:
		cursor.texture = cursor_tex
		cursor.scale = Vector2(0.02, 0.02)
	else:
		# Create a default cursor if texture fails to load
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		var tex := ImageTexture.create_from_image(img)
		cursor.texture = tex
	cursor.position = Vector2(100, 100)
	add_child(cursor)
	cursor.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	move_child(cursor, get_child_count() - 1)


func _process(delta: float) -> void:
	if cursor:
		cursor.global_position = get_viewport().get_mouse_position()
		var max_z := RenderingServer.CANVAS_ITEM_Z_MAX
		if cursor.z_index != max_z:
			cursor.z_index = max_z
		# Ensure cursor stays on top
		if cursor.get_index() != get_child_count() - 1:
			move_child(cursor, get_child_count() - 1)
	
	# Update clock
	_update_clock(delta)


func _create_exit_button() -> void:
	if has_node("ExitComputerButton"):
		return

	var exit_button := Button.new()
	exit_button.name = "ExitComputerButton"
	exit_button.text = "Exit Computer"
	exit_button.anchor_left = 1.0
	exit_button.anchor_right = 1.0
	exit_button.anchor_top = 1.0
	exit_button.anchor_bottom = 1.0
	exit_button.offset_left = -220.0
	exit_button.offset_right = -40.0
	exit_button.offset_top = -70.0
	exit_button.offset_bottom = -20.0
	exit_button.custom_minimum_size = Vector2(180, 44)
	exit_button.focus_mode = Control.FOCUS_ALL
	exit_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	exit_button.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	exit_button.top_level = true

	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.16, 0.24, 0.32)
	normal_style.border_color = Color(0.3, 0.55, 0.8)
	normal_style.border_width_bottom = 2
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	exit_button.add_theme_stylebox_override("normal", normal_style)

	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.22, 0.34, 0.44)
	exit_button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.12, 0.18, 0.26)
	pressed_style.border_color = Color(0.45, 0.7, 0.95)
	exit_button.add_theme_stylebox_override("pressed", pressed_style)

	exit_button.add_theme_color_override("font_color", Color(0.9, 0.97, 1))

	exit_button.connect("pressed", Callable(self, "_on_exit_computer_pressed"))
	add_child(exit_button)


func _on_exit_computer_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not ResourceLoader.exists(EXIT_SCENE_PATH):
		push_error("Exit scene not found: %s" % EXIT_SCENE_PATH)
		return
	get_tree().change_scene_to_file(EXIT_SCENE_PATH)


func _mark_desk_task_complete() -> void:
	# Placeholder for future game state management
	pass


# --- CLOCK SYSTEM ---

func set_clock_parameters(start_hour: int, end_hour: int, task_duration_seconds: float) -> void:
	"""Set the clock to run from start_hour to end_hour over the task duration"""
	clock_start_hour = start_hour
	clock_end_hour = end_hour
	clock_current_time = 0.0
	
	# Calculate total minutes to simulate
	var hours_to_simulate := end_hour - start_hour
	clock_duration = hours_to_simulate * 60.0  # Convert to minutes
	
	# Set initial time display
	_update_clock_display()


func _update_clock(delta: float) -> void:
	if not time_label or not is_instance_valid(time_label):
		return
	
	# Progress clock based on delta time
	# We want clock_duration minutes to pass over the task duration
	# Assuming average task is 60 seconds, we scale appropriately
	var time_scale := clock_duration / 60.0  # How many in-game minutes per real second
	clock_current_time += delta * time_scale
	
	# Clamp to max duration
	if clock_current_time > clock_duration:
		clock_current_time = clock_duration
	
	_update_clock_display()


func _update_clock_display() -> void:
	if not time_label or not is_instance_valid(time_label):
		return
	
	# Convert current time to hours and minutes
	var total_minutes := int(clock_current_time)
	var hours := clock_start_hour + (total_minutes / 60)
	var minutes := total_minutes % 60
	
	# Round minutes to nearest 5
	minutes = int(minutes / 5) * 5
	
	# Format as HH:MM
	time_label.text = "%02d:%02d" % [hours, minutes]
