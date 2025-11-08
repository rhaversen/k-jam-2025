extends Control

# Desktop folders, app windows etc.

func _ready() -> void:
	# --- Setup base desktop ---
	var wallpaper := TextureRect.new()
	wallpaper.texture = load("res://textures/desktopwallpaper.jpg")
	wallpaper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wallpaper.stretch_mode = TextureRect.STRETCH_SCALE
	wallpaper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wallpaper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(wallpaper)

	# --- Add folders (icons) ---
	_add_folder("Projects", Vector2(100, 100))
	_add_folder("Documents", Vector2(100, 200))

	# --- Add mail app (open window) ---
	var mail := _create_app_window("Mail", Vector2(600, 150), Vector2(400, 300))
	add_child(mail)

	# --- Add notes app (open in bottom-right) ---
	var notes := _create_app_window("Notes", Vector2(800, 500), Vector2(350, 200))
	var text := TextEdit.new()
	text.text = "Things to do:\n- Finish report\n- Reply to boss\n- Check meeting schedule"
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notes.add_child(text)
	add_child(notes)

	# --- Optional clock in top-right ---
	var clock := Label.new()
	clock.text = "10:42 AM"
	clock.position = Vector2(get_viewport_rect().size.x - 100, 10)
	add_child(clock)


func _add_folder(name: String, position: Vector2) -> void:
	var folder := TextureButton.new()
	folder.texture_normal = load("res://textures/folder_icon.png")
	folder.position = position
	folder.custom_minimum_size = Vector2(64, 64)

	var label := Label.new()
	label.text = name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, 68)
	folder.add_child(label)

	add_child(folder)


func _create_app_window(title: String, position: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.custom_minimum_size = size
	panel.add_theme_color_override("panel", Color(0.15, 0.15, 0.17))

	var header := Label.new()
	header.text = title
	header.add_theme_color_override("font_color", Color(1, 1, 1))
	header.add_theme_font_size_override("font_size", 18)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(header)

	return panel
