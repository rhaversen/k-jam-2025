extends "res://scripts/base_desktop.gd"
# Desktop with mail, notes, and browsable folders - but no mini-game mechanics

var folder_tree: Dictionary
var mail_window: PanelContainer
var notes_window: PanelContainer
var open_windows: Dictionary = {}
var file_icon_texture: Texture2D

# Coworker contacts for mail
var coworkers: Array = [
	{"name": "Alex Pendell", "title": "Project Manager", "status": "Online", "has_new_mail": false},
	{"name": "Sarah Chen", "title": "Software Developer", "status": "Away", "has_new_mail": false},
	{"name": "Marcus Johnson", "title": "UX Designer", "status": "Online", "has_new_mail": false},
	{"name": "Emma Williams", "title": "Product Owner", "status": "Offline", "has_new_mail": false}
]

var mail_window_default_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	super._ready()  # Call base desktop setup
	
	# Set clock to run from 8:00 to 16:00 slowly (for casual browsing)
	set_clock_parameters(8, 16, 300.0)  # 5 minutes for a full workday
	
	# Add mail and notes windows
	_create_mail_window()
	_create_notes_window()
	
	# Generate and show folders
	_generate_folder_tree()
	_show_desktop_folders(folder_tree["Desktop"], Vector2(80, 100))


# --- MAIL WINDOW ---

func _create_mail_window() -> void:
	mail_window = create_window("Mail", Vector2(get_viewport_rect().size.x - 500, 50), Vector2(450, 300), true)
	if mail_window and is_instance_valid(mail_window):
		mail_window_default_size = mail_window.custom_minimum_size
	_show_mail_contacts()
	add_child(mail_window)


func _show_mail_contacts() -> void:
	var content_area = find_child_by_name(mail_window, "content") if mail_window else null
	if not content_area:
		return
		
	var target_window_size := mail_window_default_size
	if mail_window and is_instance_valid(mail_window):
		if target_window_size == Vector2.ZERO:
			target_window_size = mail_window.custom_minimum_size
		mail_window.custom_minimum_size = target_window_size
		mail_window.size = target_window_size

	# Clear existing content
	for child in content_area.get_children():
		child.queue_free()
	
	# Create a VBox for contacts
	var contact_list := VBoxContainer.new()
	contact_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contact_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var target_height := target_window_size.y if target_window_size != Vector2.ZERO else 300.0
	contact_list.custom_minimum_size = Vector2(0, max(0.0, target_height - 40.0))
	contact_list.add_theme_constant_override("separation", 2)
	content_area.add_child(contact_list)

	var button_width := 420.0
	if target_window_size.x > 0.0:
		button_width = max(320.0, target_window_size.x - 30.0)
	
	# Add each coworker as a button
	for coworker in coworkers:
		var contact_button := Button.new()
		contact_button.flat = true
		contact_button.custom_minimum_size = Vector2(button_width, 50)
		
		var hbox := HBoxContainer.new()
		contact_button.add_child(hbox)
		
		# Status indicator
		var status := ColorRect.new()
		status.custom_minimum_size = Vector2(8, 8)
		status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		match coworker.status:
			"Online": status.color = Color(0.2, 0.9, 0.2)
			"Away": status.color = Color(0.9, 0.9, 0.2)
			"Offline": status.color = Color(0.5, 0.5, 0.5)
		
		var status_container := CenterContainer.new()
		status_container.custom_minimum_size = Vector2(30, 50)
		status_container.add_child(status)
		hbox.add_child(status_container)
		
		# Contact info
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var name_label := Label.new()
		name_label.text = coworker.name
		name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		info.add_child(name_label)
		
		var title_label := Label.new()
		title_label.text = coworker.title
		title_label.add_theme_font_size_override("font_size", 10)
		title_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info.add_child(title_label)
		
		hbox.add_child(info)
		
		# Notification indicator (if needed in future)
		if coworker.has_new_mail:
			var notif := ColorRect.new()
			notif.color = Color(0.9, 0.2, 0.2)
			notif.custom_minimum_size = Vector2(8, 8)
			notif.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			
			var notif_container := CenterContainer.new()
			notif_container.custom_minimum_size = Vector2(30, 50)
			notif_container.add_child(notif)
			hbox.add_child(notif_container)
		
		contact_list.add_child(contact_button)
		contact_button.connect("pressed", Callable(self, "_on_contact_clicked").bind(coworker.name))


func _on_contact_clicked(contact_name: String) -> void:
	# Simple message viewing without mini-game logic
	var message_text := "[b]From:[/b] %s\n[b]Subject:[/b] Hello!\n\nThis is a sample message from %s." % [contact_name, contact_name]
	_show_simple_message(contact_name, message_text)


func _show_simple_message(title: String, text: String) -> void:
	var base_position := Vector2(120, 80)
	if mail_window and is_instance_valid(mail_window):
		base_position = mail_window.position + Vector2(50, 50)

	var message_window := create_window(title, base_position, Vector2(450, 300), true)
	var content_area = find_child_by_name(message_window, "content")
	if not content_area:
		content_area = message_window

	var message_label := RichTextLabel.new()
	message_label.bbcode_enabled = true
	message_label.text = text
	message_label.custom_minimum_size = Vector2(420, 260)
	message_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.add_child(message_label)

	add_child(message_window)
	bring_to_front(message_window)


# --- NOTES WINDOW ---

func _create_notes_window() -> void:
	notes_window = create_window("Notes", Vector2(get_viewport_rect().size.x - 500, 360), Vector2(400, 200), true)
	var content_area = find_child_by_name(notes_window, "content")
	var text := TextEdit.new()
	text.text = "• Welcome to your desktop\n• Browse folders\n• Check mail from coworkers\n• Take notes here"
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	if content_area:
		content_area.add_child(text)
	else:
		notes_window.add_child(text)
	add_child(notes_window)


# --- FOLDER SYSTEM ---

func _generate_folder_tree() -> void:
	randomize()
	folder_tree = {"Desktop": {}}
	var desktop: Dictionary = folder_tree["Desktop"] as Dictionary

	# Add some folders with subfolders
	var folder_names := ["Projects", "Documents", "Downloads", "Pictures", "Work"]
	for folder_name in folder_names:
		desktop[folder_name] = _make_subfolders(0, 0)


func _make_subfolders(depth: int, counter: int) -> Dictionary:
	if depth > 2 or counter > 20:  # Simpler structure than mini-game
		return {}
	var folder_count := randi_range(2, 5)
	var dict := {}
	for i in range(folder_count):
		var name := _random_folder_name()
		# Sometimes add a file instead of folder
		if randf() > 0.6 and depth > 0:
			dict[name + ".txt"] = null  # File
		else:
			dict[name] = _make_subfolders(depth + 1, counter + 1)  # Folder
	return dict


func _random_folder_name() -> String:
	var words = ["Backup", "Docs", "Old", "Temp", "Misc", "Cases", "Data", "Ref", "Work", "Archive"]
	return words.pick_random() + "_" + str(randi_range(1, 99))


func _show_desktop_folders(tree: Dictionary, start_pos: Vector2) -> void:
	var x := start_pos.x
	var y := start_pos.y
	var spacing := 80

	for name: String in tree.keys():
		_create_folder_icon(name, Vector2(x, y), tree[name])
		y += spacing


func _create_folder_icon(name: String, pos: Vector2, content: Variant) -> void:
	var vbox := VBoxContainer.new()
	var container_size := Vector2(64, 80)
	vbox.position = pos
	vbox.custom_minimum_size = container_size

	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(container_size.x, 48)

	var folder := TextureButton.new()
	var icon_size := Vector2(40, 40)
	
	# Determine if it's a file or folder
	var is_file := content == null
	if is_file:
		folder.texture_normal = _get_file_icon_texture()
	else:
		folder.texture_normal = load("res://textures/folder_icon.png")
	
	folder.ignore_texture_size = true
	folder.custom_minimum_size = icon_size
	folder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	folder.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
	center.add_child(folder)

	vbox.add_child(center)

	var label := Label.new()
	label.text = name
	label.custom_minimum_size = Vector2(container_size.x, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.7, 0.9, 1))
	label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(label)

	if desktop_container:
		desktop_container.add_child(vbox)
	else:
		add_child(vbox)

	folder.connect("pressed", Callable(self, "_on_folder_opened").bind(name, content))


func _on_folder_opened(folder_name: String, content: Variant) -> void:
	# If it's a file, just show a message
	if content == null:
		_show_simple_message("File: " + folder_name, "This is a file: [b]%s[/b]\n\nYou can view it here." % folder_name)
		return

	# If it's a folder, open it
	if not (content is Dictionary):
		return

	if open_windows.has(folder_name):
		var existing_window: PanelContainer = open_windows[folder_name]
		if existing_window and is_instance_valid(existing_window):
			bring_to_front(existing_window)
		else:
			open_windows.erase(folder_name)
		return

	var window := create_window(
		folder_name,
		Vector2(
			randf_range(100, get_viewport_rect().size.x - 400),
			randf_range(100, get_viewport_rect().size.y - 300)
		),
		Vector2(350, 300),
		true
	)

	var content_area := find_child_by_name(window, "content")
	if not content_area:
		content_area = window

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	var folder_dict: Dictionary = content
	for item_name in folder_dict.keys():
		var item_content = folder_dict[item_name]
		var icon := _create_window_folder_icon(item_name, item_content)
		grid.add_child(icon)

	add_child(window)
	open_windows[folder_name] = window
	
	# Clean up the reference when window is closed/freed
	window.tree_exiting.connect(func():
		if open_windows.has(folder_name):
			open_windows.erase(folder_name)
	)


func _create_window_folder_icon(name: String, content: Variant) -> Control:
	var container_size := Vector2(64, 80)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = container_size
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(container_size.x, 48)
	vbox.add_child(center)

	var folder := TextureButton.new()
	folder.ignore_texture_size = true
	folder.custom_minimum_size = Vector2(40, 40)
	folder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	folder.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
	folder.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var icon_texture: Texture2D = null
	if content is Dictionary:
		var folder_icon_path := "res://textures/folder_icon.png"
		if ResourceLoader.exists(folder_icon_path):
			icon_texture = load(folder_icon_path) as Texture2D
	else:
		icon_texture = _get_file_icon_texture()

	if icon_texture:
		folder.texture_normal = icon_texture

	folder.modulate = Color(0.9, 0.9, 0.9)
	folder.connect("mouse_entered", func(): folder.modulate = Color(1, 1, 1))
	folder.connect("mouse_exited", func(): folder.modulate = Color(0.9, 0.9, 0.9))
	center.add_child(folder)

	var label := Label.new()
	label.text = name
	label.custom_minimum_size = Vector2(container_size.x, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.7, 0.9, 1))
	label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(label)

	folder.connect("pressed", Callable(self, "_on_folder_opened").bind(name, content))

	return vbox


func _get_file_icon_texture() -> Texture2D:
	if file_icon_texture:
		return file_icon_texture

	var icon_path := "res://textures/file_icon.png"
	if ResourceLoader.exists(icon_path):
		var loaded := load(icon_path) as Texture2D
		if loaded:
			file_icon_texture = loaded
			return file_icon_texture

	# Generate simple file icon
	var width := 40
	var height := 40
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var paper_color := Color(0.96, 0.97, 1.0)
	for x in range(4, width - 4):
		for y in range(4, height - 4):
			img.set_pixel(x, y, paper_color)

	var border_color := Color(0.2, 0.2, 0.35)
	for x in range(4, width - 4):
		img.set_pixel(x, 4, border_color)
		img.set_pixel(x, height - 5, border_color)
	for y in range(4, height - 4):
		img.set_pixel(4, y, border_color)
		img.set_pixel(width - 5, y, border_color)

	file_icon_texture = ImageTexture.create_from_image(img)
	return file_icon_texture
