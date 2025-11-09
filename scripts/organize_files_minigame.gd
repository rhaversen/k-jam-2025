extends "res://scripts/browsable_desktop.gd"
# Organize Files Mini-Game: Clean up the desktop by moving files into folders

var loose_files: Array = []  # Files that need to be organized
var total_files: int = 0
var organized_files: int = 0
var game_completed: bool = false
var instructions_window: PanelContainer = null
var dragging_file: Control = null
var drag_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	super._ready()  # Call browsable desktop setup
	
	# Set clock to run from 8:00 to 16:00 (8 hours) over estimated task duration
	# Assuming ~1-2 minutes to organize files
	set_clock_parameters(8, 16, 90.0)  # 90 seconds = 1.5 minutes
	
	# Generate loose files on desktop after folders are created
	await get_tree().process_frame  # Wait for desktop to finish setup
	_generate_loose_files()
	_show_game_instructions()


func _generate_loose_files() -> void:
	# File names that look like clutter
	var file_names := [
		"untitled.txt",
		"document_copy.docx",
		"image_final_FINAL.jpg",
		"old_backup_v3.zip",
		"screenshot_2023.png",
		"notes_temp.txt",
		"draft_old.pdf",
		"download (1).exe",
		"meeting_notes_2022.txt",
		"presentation_backup.pptx",
		"random_file.dat",
		"todo_list_old.txt",
		"budget_draft.xlsx",
		"photo_vacation.jpg",
		"archive_old.zip"
	]
	
	# Randomly pick 8-12 files
	var file_count := randi_range(8, 12)
	file_names.shuffle()
	
	# Starting position for files (to the right of folders)
	var start_x := 350.0
	var start_y := 100.0
	var spacing_x := 90.0
	var spacing_y := 90.0
	var files_per_row := 4
	
	for i in range(file_count):
		var file_name: String = file_names[i]
		var row := i / files_per_row
		var col := i % files_per_row
		var pos := Vector2(start_x + col * spacing_x, start_y + row * spacing_y)
		
		_create_loose_file(file_name, pos)
		total_files += 1
	
	print("Generated %d loose files to organize" % total_files)


func _create_loose_file(file_name: String, pos: Vector2) -> void:
	var vbox := VBoxContainer.new()
	var container_size := Vector2(64, 80)
	vbox.position = pos
	vbox.custom_minimum_size = container_size
	vbox.set_meta("file_name", file_name)
	vbox.set_meta("is_loose_file", true)

	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(container_size.x, 48)

	var file_button := TextureButton.new()
	file_button.texture_normal = _get_file_icon_texture()
	file_button.ignore_texture_size = true
	file_button.custom_minimum_size = Vector2(40, 40)
	file_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	file_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
	file_button.mouse_default_cursor_shape = Control.CURSOR_DRAG
	center.add_child(file_button)
	vbox.add_child(center)

	var label := Label.new()
	label.text = file_name
	label.custom_minimum_size = Vector2(container_size.x, 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.7, 0.9, 1))
	label.add_theme_font_size_override("font_size", 9)
	vbox.add_child(label)

	if desktop_container:
		desktop_container.add_child(vbox)
	else:
		add_child(vbox)
	
	loose_files.append(vbox)
	
	# Connect mouse events for dragging
	file_button.connect("gui_input", Callable(self, "_on_file_gui_input").bind(vbox))


func _on_file_gui_input(event: InputEvent, file_node: Control) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging
				dragging_file = file_node
				drag_offset = file_node.get_global_mouse_position() - file_node.global_position
				file_node.z_index = 100  # Bring to front
			else:
				# Stop dragging
				if dragging_file == file_node:
					_check_drop_on_folder(file_node)
					dragging_file = null
					file_node.z_index = 0


func _process(delta: float) -> void:
	super._process(delta)
	
	# Update dragging file position
	if dragging_file and is_instance_valid(dragging_file):
		dragging_file.global_position = get_global_mouse_position() - drag_offset


func _check_drop_on_folder(file_node: Control) -> void:
	if not file_node or not is_instance_valid(file_node):
		return
	
	var file_name: String = file_node.get_meta("file_name", "")
	
	# Check all desktop icons to see if we dropped on a folder
	if not desktop_container:
		return
	
	for child in desktop_container.get_children():
		# Skip if it's the file itself
		if child == file_node:
			continue
		
		# Check if it's a folder (not a loose file)
		if child.get_meta("is_loose_file", false):
			continue
		
		# Check if the file overlaps with this folder
		var folder_rect := Rect2(child.global_position, child.size)
		var file_rect := Rect2(file_node.global_position, file_node.size)
		
		if folder_rect.intersects(file_rect):
			# Successfully dropped into folder!
			_organize_file(file_node, child)
			return


func _organize_file(file_node: Control, folder_node: Control) -> void:
	var file_name: String = file_node.get_meta("file_name", "")
	print("Organized: %s" % file_name)
	
	# Remove the file from desktop
	loose_files.erase(file_node)
	file_node.queue_free()
	
	organized_files += 1
	
	# Check if game is complete
	if organized_files >= total_files and not game_completed:
		_complete_game()


func _show_game_instructions() -> void:
	var instruction_text := "[b]Mini-Game: Organize Files[/b]\n\n"
	instruction_text += "Your desktop is a mess! You have [color=yellow]%d files[/color] scattered around.\n\n" % total_files
	instruction_text += "Your task: Drag and drop each file into a folder.\n\n"
	instruction_text += "[color=#888888]It is really important that you choose the right folder - clean up your desktop![/color]"
	
	var base_position := Vector2(get_viewport_rect().size.x / 2 - 250, get_viewport_rect().size.y / 2 - 150)
	
	instructions_window = create_window("Welcome", base_position, Vector2(500, 300), true)
	var content_area = find_child_by_name(instructions_window, "content")
	if not content_area:
		content_area = instructions_window

	var message_label := RichTextLabel.new()
	message_label.bbcode_enabled = true
	message_label.text = instruction_text
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	content_area.add_child(message_label)

	add_child(instructions_window)
	bring_to_front(instructions_window)


func _complete_game() -> void:
	game_completed = true
	print("🎉 Game completed! All files organized!")
	
	# Mark task complete (non-time-based game)
	_mark_desk_task_complete()
	
	# Update the welcome/instructions window with completion message
	if not instructions_window or not is_instance_valid(instructions_window):
		return
	
	# Update window title
	var header_bar = _find_window_header(instructions_window)
	if header_bar:
		for child in header_bar.get_children():
			if child is HBoxContainer:
				for label in child.get_children():
					if label is Label:
						label.text = "Desktop Organized!"
						break
				break
	
	# Update content
	var content_area = find_child_by_name(instructions_window, "content")
	if not content_area:
		return
	
	# Clear existing content
	for child in content_area.get_children():
		child.queue_free()
	
	# Add completion message
	var completion_text := "[b][color=green]Excellent Work![/color][/b]\n\n"
	completion_text += "You organized all [color=yellow]%d files[/color]!\n\n" % total_files
	completion_text += "Your desktop is now clean and tidy. Great job! 📁✨"
	
	var completion_label := RichTextLabel.new()
	completion_label.bbcode_enabled = true
	completion_label.text = completion_text
	completion_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	completion_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	completion_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	completion_label.add_theme_font_size_override("font_size", 16)
	content_area.add_child(completion_label)
	
	# Bring window to front
	bring_to_front(instructions_window)


func _find_window_header(window: PanelContainer) -> Node:
	# Find the ColorRect header in the window
	for child in window.get_children():
		if child is VBoxContainer:
			for vbox_child in child.get_children():
				if vbox_child is ColorRect:
					return vbox_child
	return null
