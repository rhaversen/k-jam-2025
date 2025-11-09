extends "res://scripts/base_desktop.gd"
# Folder race mini-game: Find and send the target file before time runs out

const TARGET_FILE := "Wells_Report.docx"
const TARGET_PATH := ["Projects", "Client_Phoenix", "Quarterly", "Drafts"]
const MAX_FOLDERS := 67
const FAIL_FADE_DURATION := 1.25
const FAIL_OVERLAY_BASE_COLOR := Color(0.95, 0.0, 0.0, 0.65)
const FAIL_OVERLAY_FINAL_COLOR := Color(0.95, 0.0, 0.0, 1.0)
const SUCCESS_HEART_AUDIO_PATH := "res://sound/fast_heart_beat_-_sound_effect.wav"
const MISSION_DURATION_SECONDS := 60

var folder_tree: Dictionary
var mail_window: PanelContainer
var notes_window: PanelContainer
var mail_message_window: PanelContainer
var mail_message_label: RichTextLabel
var mail_message_base_text: String = ""
var mission_timer: Timer
var mission_started: bool = false
var mission_completed: bool = false
var mission_failed: bool = false
var countdown_remaining: int = 0
var send_prompt_window: PanelContainer
var file_icon_texture: Texture2D
var ticker_player: AudioStreamPlayer
var tick_stream: AudioStreamWAV
var stress_overlay: ColorRect
var stress_intensity: float = 0.0
var stress_drone_player: AudioStreamPlayer
var drone_stream: AudioStreamWAV
var success_heart_player: AudioStreamPlayer
var success_heart_stream: AudioStream
var desktop_shake_amount: float = 0.0
var shake_timer: float = 0.0
var open_windows: Dictionary = {}
var fail_overlay: ColorRect
var fail_sequence_started: bool = false
var fail_fade_active: bool = false
var fail_fade_elapsed: float = 0.0
var fail_return_started: bool = false
var fail_delay_timer: SceneTreeTimer
var success_return_scheduled: bool = false
var success_window: PanelContainer

# Store mail states
var coworkers: Array = [
	{"name": "Alex Pendell", "title": "Project Manager", "status": "Online", "has_new_mail": false},
	{"name": "Sarah Chen", "title": "Software Developer", "status": "Away", "has_new_mail": false},
	{"name": "Marcus Johnson", "title": "UX Designer", "status": "Online", "has_new_mail": false},
	{"name": "Emma Williams", "title": "Product Owner", "status": "Offline", "has_new_mail": false}
]

var mail_window_default_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	super._ready()  # Call base desktop setup
	
	# Set clock to run from 8:00 to 20:00 (12 hours) over the mission duration
	set_clock_parameters(8, 20, MISSION_DURATION_SECONDS)
	
	_hide_exit_button()
	
	# Setup mini-game specific UI
	_create_mail_window()
	_create_notes_window()
	
	_generate_folder_tree()
	_show_desktop_folders(folder_tree["Desktop"], Vector2(80, 100))
	
	_cleanup_orphan_icons()
	_ensure_tick_player()
	_ensure_stress_overlay()
	_ensure_fail_overlay()
	_ensure_drone_player()
	_ensure_success_heart_player()
	
	# Setup shake metadata
	if desktop_container:
		desktop_container.set_meta("shake_last_offset", Vector2.ZERO)
		desktop_container.set_meta("shake_phase", randf() * TAU)
	
	# Schedule the new mail notification
	var timer := get_tree().create_timer(3.0)
	timer.timeout.connect(func(): 
		_trigger_new_mail()
	)


func _process(delta: float) -> void:
	super._process(delta)  # Call base cursor/window management
	
	# Mini-game specific processing
	if stress_overlay and is_instance_valid(stress_overlay) and stress_overlay.visible:
		var base_alpha: float = lerp(0.0, 0.25, stress_intensity)  # Reduced from 0.65
		if countdown_remaining <= 10 and mission_started:
			base_alpha = max(base_alpha, 0.35)  # Reduced from 0.5
		var pulse_speed: float = 150.0 if countdown_remaining <= 10 else 220.0  # Slower pulse
		var pulse_strength: float = 0.04 if countdown_remaining <= 10 else 0.02  # Reduced pulse strength
		var pulse: float = pulse_strength * sin(float(Time.get_ticks_msec()) / pulse_speed)
		var alpha: float = clamp(base_alpha + pulse, 0.0, 0.4)  # Reduced max from 0.7
		stress_overlay.color = Color(0.9, 0.1, 0.1, alpha)

	if mail_window and is_instance_valid(mail_window) and mail_window_default_size != Vector2.ZERO:
		var desired_size := mail_window_default_size
		if mail_window.size != desired_size:
			mail_window.custom_minimum_size = desired_size
			mail_window.size = desired_size

	if fail_sequence_started and fail_overlay and is_instance_valid(fail_overlay):
		fail_overlay.visible = true

	if fail_fade_active:
		fail_fade_elapsed += delta
		var t: float = clamp(fail_fade_elapsed / FAIL_FADE_DURATION, 0.0, 1.0)
		var eased_t: float = smoothstep(0.0, 1.0, t)
		if fail_overlay and is_instance_valid(fail_overlay):
			fail_overlay.color = FAIL_OVERLAY_BASE_COLOR.lerp(FAIL_OVERLAY_FINAL_COLOR, eased_t)
		if t >= 1.0 and not fail_return_started:
			fail_fade_active = false
			fail_return_started = true
			call_deferred("_begin_failure_return")

	shake_timer += delta
	var target_shake: float = 0.0
	if mission_started:
		target_shake = lerp(0.22, 1.6, stress_intensity)
	desktop_shake_amount = lerp(desktop_shake_amount, target_shake, clamp(delta * 2.4, 0.0, 1.0))
	var base_frequency: float = lerp(0.6, 2.8, stress_intensity)
	var secondary_freq: float = base_frequency * 0.6 + 0.25
	var wobble: Vector2 = Vector2(
		sin(shake_timer * base_frequency),
		sin(shake_timer * secondary_freq + PI / 4.0)
	)
	var noise_offset: Vector2 = Vector2.ZERO
	if desktop_shake_amount > 0.15:
		noise_offset = Vector2(
			randf_range(-0.45, 0.45),
			randf_range(-0.45, 0.45)
		) * desktop_shake_amount * 0.22
	var base_offset: Vector2 = (wobble * desktop_shake_amount * 0.52) + noise_offset
	_apply_shake_offsets(base_offset, desktop_shake_amount)


# --- MAIL SYSTEM ---

func _create_mail_window() -> void:
	mail_window = create_window("Mail", Vector2(get_viewport_rect().size.x - 500, 50), Vector2(450, 300), true)
	if mail_window and is_instance_valid(mail_window):
		mail_window_default_size = mail_window.custom_minimum_size
		mail_window.set_meta("shake_last_offset", Vector2.ZERO)
		mail_window.set_meta("shake_phase", randf() * TAU)
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
		
		# Create a horizontal layout for contact info
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
		
		# Notification indicator
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

	if mail_window and is_instance_valid(mail_window) and target_window_size != Vector2.ZERO:
		mail_window.custom_minimum_size = target_window_size
		mail_window.set_deferred("size", target_window_size)


func _on_contact_clicked(contact_name: String) -> void:
	if contact_name == "Alex Pendell":
		var urgent_text := "[b]From:[/b] Alex Pendell\n[b]Subject:[/b] URGENT: Missing report\n\nI need the [color=yellow]Wells report[/color] in the next minute. If I don't have it, I'm filing a complaint with the boss. Hop to it!".format([TARGET_FILE])
		_show_mail_message(urgent_text, true)
		var updated := false
		for coworker in coworkers:
			if coworker.name == "Alex Pendell":
				coworker.has_new_mail = false
				updated = true
				break
		if updated:
			_show_mail_contacts()
		if not mission_started and not mission_completed and not mission_failed:
			_start_mission_countdown()


func _trigger_new_mail() -> void:
	for coworker in coworkers:
		if coworker.name == "Alex Pendell":
			coworker.has_new_mail = true
			_show_mail_contacts()
			mission_started = false
			mission_completed = false
			mission_failed = false
			countdown_remaining = MISSION_DURATION_SECONDS
			mail_message_base_text = ""
			if mission_timer:
				mission_timer.stop()
			_close_send_prompt()
			_stop_tick()
			success_return_scheduled = false
			if success_window and is_instance_valid(success_window):
				success_window.queue_free()
			success_window = null
			_hide_exit_button()
			break


func _create_notes_window() -> void:
	notes_window = create_window("Notes", Vector2(get_viewport_rect().size.x - 500, 360), Vector2(400, 200), true)
	notes_window.set_meta("shake_last_offset", Vector2.ZERO)
	notes_window.set_meta("shake_phase", randf() * TAU)
	var content_area = find_child_by_name(notes_window, "content")
	var text := TextEdit.new()
	text.text = "• Find missing file\n• Reply to Alex\n• Don't delete the wrong folder!"
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	if content_area:
		content_area.add_child(text)
	else:
		notes_window.add_child(text)
	add_child(notes_window)


func _show_mail_message(text: String, show_countdown: bool = false) -> PanelContainer:
	if mail_message_window and is_instance_valid(mail_message_window):
		var existing_content = find_child_by_name(mail_message_window, "content")
		if existing_content:
			for c in existing_content.get_children():
				if c is RichTextLabel:
					mail_message_label = c
					mail_message_label.bbcode_enabled = true
					if show_countdown:
						mail_message_base_text = text
						_update_mail_message_text()
					else:
						mail_message_label.text = text
					bring_to_front(mail_message_window)
					return mail_message_window

	var base_position := Vector2(120, 80)
	if mail_window and is_instance_valid(mail_window):
		base_position = mail_window.position + Vector2(50, 50)

	mail_message_window = create_window("New Message", base_position, Vector2(450, 300), true)
	mail_message_window.set_meta("shake_last_offset", Vector2.ZERO)
	mail_message_window.set_meta("shake_phase", randf() * TAU)

	var content_area = find_child_by_name(mail_message_window, "content")
	if not content_area:
		content_area = mail_message_window

	mail_message_label = RichTextLabel.new()
	mail_message_label.bbcode_enabled = true
	mail_message_label.custom_minimum_size = Vector2(420, 260)
	mail_message_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	mail_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mail_message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.add_child(mail_message_label)

	if show_countdown:
		mail_message_base_text = text
		_update_mail_message_text()
	else:
		mail_message_label.text = text

	add_child(mail_message_window)
	bring_to_front(mail_message_window)
	
	return mail_message_window


func _update_mail_message_text() -> void:
	if not mail_message_label or mail_message_base_text == "":
		return
	var minutes := countdown_remaining / 60
	var seconds := countdown_remaining % 60
	var countdown_text := "%02d:%02d" % [minutes, seconds]
	if countdown_remaining <= 10:
		countdown_text = "[color=#ff4d4d]%s[/color]" % countdown_text
	var countdown_line := "\n\n[b]Time remaining:[/b] %s" % countdown_text
	mail_message_label.text = mail_message_base_text + countdown_line


# --- MISSION SYSTEM ---

func _start_mission_countdown() -> void:
	if mission_timer == null:
		mission_timer = Timer.new()
		mission_timer.wait_time = 1.0
		mission_timer.one_shot = false
		mission_timer.timeout.connect(Callable(self, "_on_mission_timer_timeout"))
		add_child(mission_timer)

	_reset_fail_state()
	if success_heart_player and is_instance_valid(success_heart_player):
		success_heart_player.stop()
	countdown_remaining = MISSION_DURATION_SECONDS
	mission_started = true
	mission_completed = false
	mission_failed = false
	mission_timer.start()
	_update_mail_message_text()
	_update_stress_effects()
	_play_tick()
	_start_stress_drone()


func _on_mission_timer_timeout() -> void:
	if mission_completed:
		mission_timer.stop()
		return

	countdown_remaining = max(countdown_remaining - 1, 0)
	_update_mail_message_text()
	_play_tick()
	_update_stress_effects()
	if countdown_remaining <= 5 and mission_started:
		var echo_timer: SceneTreeTimer = get_tree().create_timer(0.2)
		echo_timer.timeout.connect(_play_tick)

	if countdown_remaining <= 0:
		mission_timer.stop()
		mission_failed = true
		mission_started = false
		_handle_mission_failure()


func _complete_mission(success: bool) -> void:
	_reset_fail_state()
	mission_completed = success
	mission_started = false
	mission_failed = not success
	if mission_timer:
		mission_timer.stop()
	_stop_tick()
	_close_send_prompt()
	if success:
		mail_message_base_text = ""
		_play_success_heart_audio()
		_handle_mission_success()
	else:
		_handle_mission_failure()


func _handle_mission_failure() -> void:
	_close_send_prompt()
	mail_message_base_text = ""
	_stop_tick()
	_hide_exit_button()
	
	var failure_message_window := _show_mail_message("[b]From:[/b] Alex Pendell\n[b]Subject:[/b] Escalating to management\n\nYou missed the deadline. I'm looping in our boss. We'll talk about this later.")
	
	# Start red fade immediately - blend from pulsating countdown red
	_start_red_fade_failure(failure_message_window)


func _handle_mission_success() -> void:
	_hide_exit_button()
	_show_success_window()
	_schedule_success_return()


func _show_success_window() -> void:
	if success_window and is_instance_valid(success_window):
		success_window.queue_free()
	success_window = null

	var base_position := Vector2(get_viewport_rect().size.x / 2 - 240, get_viewport_rect().size.y / 2 - 140)
	success_window = create_window("Report Sent", base_position, Vector2(480, 280), true)
	success_window.set_meta("shake_last_offset", Vector2.ZERO)
	success_window.set_meta("shake_phase", randf() * TAU)

	var content_area := find_child_by_name(success_window, "content")
	if not content_area:
		content_area = success_window

	for child in content_area.get_children():
		child.queue_free()

	var completion_text := "[b][color=green]Report Delivered![/color][/b]\n\n"
	completion_text += "You located the [color=yellow]%s[/color] in time.\n" % TARGET_FILE
	completion_text += "Alex is sending it up the chain right now."

	var completion_label := RichTextLabel.new()
	completion_label.bbcode_enabled = true
	completion_label.text = completion_text
	completion_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	completion_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	completion_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	completion_label.add_theme_font_size_override("font_size", 16)
	completion_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_area.add_child(completion_label)

	add_child(success_window)
	bring_to_front(success_window)


func _schedule_success_return() -> void:
	if success_return_scheduled:
		return
	success_return_scheduled = true
	var timer := get_tree().create_timer(2.5)
	timer.timeout.connect(Callable(self, "_begin_success_return"))


func _begin_success_return() -> void:
	if not mission_completed or mission_failed:
		return
	await _fade_to_black_and_exit()


func _start_red_fade_failure(failure_window: PanelContainer) -> void:
	# Hide the stress overlay
	if stress_overlay and is_instance_valid(stress_overlay):
		stress_overlay.visible = false
	
	# Create red overlay - instantly at full intensity
	var red_overlay := ColorRect.new()
	red_overlay.color = Color(1, 0, 0, 0.8)  # Instant red at 80% opacity
	red_overlay.size = get_viewport_rect().size
	red_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	red_overlay.z_index = 9999  # Very high to be above everything
	add_child(red_overlay)
	
	# Fade out the failure window
	if failure_window and is_instance_valid(failure_window):
		var tween := create_tween()
		tween.tween_property(failure_window, "modulate", Color(1, 1, 1, 0), 1.5)  # Fade out over 1.5 seconds
	
	print("💀 Red screen instantly active!")
	
	# Wait a moment, then cut to black and return to office
	await get_tree().create_timer(1.5).timeout
	await _fade_to_black_and_exit()


func _fade_to_black_and_exit() -> void:
	var overlay := ColorRect.new()
	overlay.name = "ReturnFadeOverlay"
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	add_child(overlay)

	var tween := create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.6)

	await tween.finished
	await get_tree().create_timer(0.4).timeout

	if success_window and is_instance_valid(success_window):
		success_window.queue_free()
	success_window = null

	if success_heart_player and is_instance_valid(success_heart_player):
		success_heart_player.stop()

	super._on_exit_computer_pressed()


# --- FOLDER SYSTEM ---

func _generate_folder_tree() -> void:
	randomize()
	folder_tree = {"Desktop": {}}
	var desktop: Dictionary = folder_tree["Desktop"] as Dictionary

	# Add decoy folders
	for i in range(3):
		var decoy_name := _random_folder_name()
		while desktop.has(decoy_name):
			decoy_name = _random_folder_name()
		desktop[decoy_name] = _make_subfolders(0, 0)

	# Create guaranteed path
	var current: Dictionary = desktop
	for level in range(TARGET_PATH.size()):
		var folder: String = TARGET_PATH[level]
		if not current.has(folder):
			current[folder] = {}
		var sibling_decoys: int = randi_range(1, 3)
		for _j in range(sibling_decoys):
			var sibling_name: String = _random_folder_name()
			while current.has(sibling_name):
				sibling_name = _random_folder_name()
			current[sibling_name] = _make_subfolders(level + 1, 0)
		current = current[folder] as Dictionary

	# Add extra folders inside final target folder
	var internal_decoys: int = randi_range(2, 4)
	for _k in range(internal_decoys):
		var inner_name: String = _random_folder_name()
		while current.has(inner_name):
			inner_name = _random_folder_name()
		current[inner_name] = _make_subfolders(TARGET_PATH.size(), 0)

	# Place target file
	current[TARGET_FILE] = null


func _make_subfolders(depth: int, counter: int) -> Dictionary:
	if depth > 3 or counter > MAX_FOLDERS:
		return {}
	var folder_count := randi_range(1, 4)
	var dict := {}
	for i in range(folder_count):
		dict[_random_folder_name()] = _make_subfolders(depth + 1, counter + 1)
	return dict


func _random_folder_name() -> String:
	var words = ["Backup", "Docs", "Old", "Temp", "Misc", "Cases", "Data", "Ref", "Work"]
	return words.pick_random() + "_" + str(randi_range(1, 999))


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
	if folder_name == TARGET_FILE:
		if not mission_started:
			return
		_show_send_prompt()
		return

	if not (content is Dictionary):
		return

	if open_windows.has(folder_name):
		bring_to_front(open_windows[folder_name])
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
	window.set_meta("shake_last_offset", Vector2.ZERO)
	window.set_meta("shake_phase", randf() * TAU)

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
	else:
		folder.texture_normal = null

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

	# Generate file icon
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


func _show_send_prompt() -> void:
	if mission_completed:
		_show_mail_message("[b]Alex Pendell:[/b]\nAlready got the file—thanks again!", false)
		return
	if mission_failed:
		_show_mail_message("[b]Alex Pendell:[/b]\nIt's too late—I'm already escalating this.", false)
		return

	if send_prompt_window and is_instance_valid(send_prompt_window):
		bring_to_front(send_prompt_window)
		return

	var base_position := Vector2(180, 140)
	if mail_message_window and is_instance_valid(mail_message_window):
		base_position = mail_message_window.position + Vector2(30, 30)

	send_prompt_window = create_window("Send File", base_position, Vector2(360, 220), true)
	send_prompt_window.set_meta("shake_last_offset", Vector2.ZERO)
	send_prompt_window.set_meta("shake_phase", randf() * TAU)
	
	var content_area := find_child_by_name(send_prompt_window, "content")
	if not content_area:
		content_area = send_prompt_window

	var instructions := RichTextLabel.new()
	instructions.bbcode_enabled = true
	instructions.text = "You located [color=yellow]%s[/color]. Should I send it to Alex now?" % TARGET_FILE
	instructions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	instructions.size_flags_vertical = Control.SIZE_EXPAND_FILL
	instructions.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_area.add_child(instructions)

	var button_row := HBoxContainer.new()
	button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_theme_constant_override("separation", 8)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_child(spacer)

	var send_button := Button.new()
	send_button.text = "Send to Alex"
	send_button.connect("pressed", Callable(self, "_on_send_file_pressed"))
	button_row.add_child(send_button)

	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.connect("pressed", Callable(self, "_on_cancel_send_file"))
	button_row.add_child(cancel_button)

	content_area.add_child(button_row)

	add_child(send_prompt_window)
	bring_to_front(send_prompt_window)


func _on_send_file_pressed() -> void:
	_show_mail_message("[b]From:[/b] Alex Pendell\n[b]Subject:[/b] Perfect timing\n\nThat was fast! I'm sending this up the chain right now. Appreciate it.", false)
	_complete_mission(true)
	_close_send_prompt()


func _on_cancel_send_file() -> void:
	_close_send_prompt()


func _close_send_prompt() -> void:
	if send_prompt_window and is_instance_valid(send_prompt_window):
		send_prompt_window.queue_free()
	send_prompt_window = null


# --- AUDIO & EFFECTS ---

func _ensure_tick_player() -> void:
	if ticker_player and is_instance_valid(ticker_player):
		return

	ticker_player = AudioStreamPlayer.new()
	ticker_player.name = "MissionTickPlayer"
	ticker_player.stream = _get_tick_stream()
	ticker_player.volume_db = -8.0
	ticker_player.bus = "Master"
	ticker_player.autoplay = false
	add_child(ticker_player)


func _get_tick_stream() -> AudioStreamWAV:
	if tick_stream:
		return tick_stream

	tick_stream = AudioStreamWAV.new()
	tick_stream.format = AudioStreamWAV.FORMAT_16_BITS
	tick_stream.stereo = false
	tick_stream.mix_rate = 44100
	tick_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED

	var duration: float = 0.08
	var total_samples: int = int(duration * tick_stream.mix_rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_samples * 2)
	var frequency_primary: float = 2100.0
	var frequency_secondary: float = 3400.0

	for i in range(total_samples):
		var t: float = float(i) / tick_stream.mix_rate
		var envelope: float = pow(max(0.0, 1.0 - (t / duration)), 1.6)
		var primary: float = sin(2.0 * PI * frequency_primary * t)
		var secondary: float = sin(2.0 * PI * frequency_secondary * t)
		var sample: float = (primary + 0.6 * secondary) * envelope
		var value: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		var lo: int = value & 0xFF
		var hi: int = (value >> 8) & 0xFF
		data[i * 2] = lo
		data[i * 2 + 1] = hi

	tick_stream.data = data
	return tick_stream


func _ensure_stress_overlay() -> void:
	if stress_overlay and is_instance_valid(stress_overlay):
		return

	stress_overlay = ColorRect.new()
	stress_overlay.name = "StressOverlay"
	stress_overlay.color = Color(0.85, 0.1, 0.1, 0.0)
	stress_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stress_overlay.anchor_left = 0.0
	stress_overlay.anchor_top = 0.0
	stress_overlay.anchor_right = 1.0
	stress_overlay.anchor_bottom = 1.0
	stress_overlay.offset_left = 0.0
	stress_overlay.offset_top = 0.0
	stress_overlay.offset_right = 0.0
	stress_overlay.offset_bottom = 0.0
	stress_overlay.z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 2
	stress_overlay.visible = false
	add_child(stress_overlay)


func _ensure_fail_overlay() -> void:
	if fail_overlay and is_instance_valid(fail_overlay):
		return

	fail_overlay = ColorRect.new()
	fail_overlay.name = "FailOverlay"
	fail_overlay.color = Color(FAIL_OVERLAY_BASE_COLOR.r, FAIL_OVERLAY_BASE_COLOR.g, FAIL_OVERLAY_BASE_COLOR.b, 0.0)
	fail_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fail_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fail_overlay.visible = false
	fail_overlay.top_level = true
	add_child(fail_overlay)
	fail_overlay.z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 1


func _ensure_drone_player() -> void:
	if stress_drone_player and is_instance_valid(stress_drone_player):
		return

	stress_drone_player = AudioStreamPlayer.new()
	stress_drone_player.name = "StressDronePlayer"
	stress_drone_player.stream = _get_drone_stream()
	stress_drone_player.volume_db = -18.0
	stress_drone_player.bus = "Master"
	stress_drone_player.autoplay = false
	add_child(stress_drone_player)


func _ensure_success_heart_player() -> void:
	if success_heart_player and is_instance_valid(success_heart_player):
		return

	success_heart_player = AudioStreamPlayer.new()
	success_heart_player.name = "SuccessHeartPlayer"
	success_heart_player.bus = "Master"
	success_heart_player.autoplay = false
	success_heart_player.volume_db = -2.0
	success_heart_player.stream = _get_success_heart_stream()
	add_child(success_heart_player)


func _get_drone_stream() -> AudioStreamWAV:
	if drone_stream:
		return drone_stream

	drone_stream = AudioStreamWAV.new()
	drone_stream.format = AudioStreamWAV.FORMAT_16_BITS
	drone_stream.stereo = false
	drone_stream.mix_rate = 44100
	drone_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	var duration: float = 0.6
	var total_samples: int = int(duration * drone_stream.mix_rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_samples * 2)
	var frequency_low: float = 82.0
	var frequency_high: float = 146.0

	for i in range(total_samples):
		var t: float = float(i) / drone_stream.mix_rate
		var slow_mod: float = 0.55 + 0.45 * sin(2.0 * PI * t / duration)
		var low_wave: float = sin(2.0 * PI * frequency_low * t)
		var high_wave: float = sin(2.0 * PI * frequency_high * t)
		var sample: float = (0.65 * low_wave + 0.35 * high_wave) * slow_mod * 0.7
		var value: int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		var lo: int = value & 0xFF
		var hi: int = (value >> 8) & 0xFF
		data[i * 2] = lo
		data[i * 2 + 1] = hi

	drone_stream.data = data
	return drone_stream


func _get_success_heart_stream() -> AudioStream:
	if success_heart_stream:
		return success_heart_stream

	if ResourceLoader.exists(SUCCESS_HEART_AUDIO_PATH):
		success_heart_stream = ResourceLoader.load(SUCCESS_HEART_AUDIO_PATH) as AudioStream
		if not success_heart_stream:
			push_warning("Failed to load success audio asset: %s" % SUCCESS_HEART_AUDIO_PATH)
	else:
		push_warning("Missing success audio asset: %s" % SUCCESS_HEART_AUDIO_PATH)

	return success_heart_stream


func _start_stress_drone() -> void:
	_ensure_drone_player()
	if stress_drone_player.stream == null:
		stress_drone_player.stream = _get_drone_stream()
	stress_drone_player.pitch_scale = 1.0
	if not stress_drone_player.playing:
		stress_drone_player.play()


func _play_tick() -> void:
	if not mission_started:
		return
	_ensure_tick_player()
	if ticker_player.stream == null:
		ticker_player.stream = _get_tick_stream()
	if ticker_player.playing:
		ticker_player.stop()
	ticker_player.play()


func _play_success_heart_audio() -> void:
	_ensure_success_heart_player()
	if not (success_heart_player and is_instance_valid(success_heart_player)):
		return
	var stream := _get_success_heart_stream()
	if stream:
		success_heart_player.stream = stream
		success_heart_player.stop()
		success_heart_player.pitch_scale = 1.0
		success_heart_player.play()


func _stop_tick() -> void:
	if ticker_player and is_instance_valid(ticker_player):
		ticker_player.stop()
		ticker_player.pitch_scale = 1.0
		ticker_player.volume_db = -8.0
	if stress_drone_player and is_instance_valid(stress_drone_player):
		stress_drone_player.stop()
		stress_drone_player.pitch_scale = 1.0
		stress_drone_player.volume_db = -18.0
	if stress_overlay and is_instance_valid(stress_overlay):
		stress_overlay.visible = false
		stress_overlay.color = Color(stress_overlay.color.r, stress_overlay.color.g, stress_overlay.color.b, 0.0)
	stress_intensity = 0.0
	_reset_shake_offsets()
	shake_timer = 0.0


func _update_stress_effects() -> void:
	if not mission_started:
		_stop_tick()
		return

	_ensure_stress_overlay()
	stress_overlay.visible = true

	var total_time := float(MISSION_DURATION_SECONDS)
	if total_time <= 0.0:
		total_time = 1.0
	var progress := 1.0 - float(countdown_remaining) / total_time
	stress_intensity = clamp(progress, 0.0, 1.0)
	stress_intensity = max(stress_intensity, 0.25)
	if countdown_remaining <= 60:
		stress_intensity = max(stress_intensity, 0.55)
	if countdown_remaining <= 20:
		stress_intensity = max(stress_intensity, 0.75)
	if countdown_remaining <= 10:
		stress_intensity = 1.0

	if ticker_player and is_instance_valid(ticker_player):
		var pitch_target: float = 1.15 + stress_intensity * 0.65
		if countdown_remaining <= 30:
			pitch_target = 1.5 + stress_intensity * 0.7
		if countdown_remaining <= 10:
			pitch_target = 2.3
		ticker_player.pitch_scale = clamp(pitch_target, 0.8, 3.0)
		var volume_progress: float = clamp(1.0 - float(countdown_remaining) / 60.0, 0.0, 1.0)
		var tick_volume: float = lerp(-12.0, 1.0, volume_progress)
		if countdown_remaining <= 10:
			tick_volume = max(tick_volume, 1.5)
		ticker_player.volume_db = tick_volume

	if stress_drone_player and is_instance_valid(stress_drone_player):
		var drone_volume: float = lerp(-24.0, -4.0, stress_intensity)
		if countdown_remaining <= 15:
			drone_volume = lerp(drone_volume, -2.0, 0.6)
		stress_drone_player.volume_db = drone_volume
		var drone_pitch: float = lerp(1.0, 1.35, stress_intensity)
		if countdown_remaining <= 10:
			drone_pitch = 1.5
		stress_drone_player.pitch_scale = drone_pitch


# --- SHAKE EFFECTS ---

func _collect_shake_targets() -> Array[Control]:
	var targets: Array[Control] = []
	if desktop_container and is_instance_valid(desktop_container):
		targets.append(desktop_container)
	if mail_window and is_instance_valid(mail_window):
		targets.append(mail_window)
	if notes_window and is_instance_valid(notes_window):
		targets.append(notes_window)
	if mail_message_window and is_instance_valid(mail_message_window):
		targets.append(mail_message_window)
	if send_prompt_window and is_instance_valid(send_prompt_window):
		targets.append(send_prompt_window)
	var invalid_keys: Array = []
	for window_key in open_windows.keys():
		var window_value = open_windows[window_key]
		if not is_instance_valid(window_value):
			invalid_keys.append(window_key)
			continue
		var control_window := window_value as Control
		if control_window:
			targets.append(control_window)
		else:
			invalid_keys.append(window_key)
	for key in invalid_keys:
		open_windows.erase(key)
	return targets


func _apply_shake_offsets(base_offset: Vector2, amplitude: float) -> void:
	var targets := _collect_shake_targets()
	for target in targets:
		var per_node_offset := _calculate_node_shake_offset(target, base_offset, amplitude)
		_set_shake_offset(target, per_node_offset)


func _calculate_node_shake_offset(target: Control, base_offset: Vector2, amplitude: float) -> Vector2:
	if amplitude <= 0.01:
		return Vector2.ZERO
	var phase: float = target.get_meta("shake_phase", randf() * TAU)
	target.set_meta("shake_phase", phase)
	var variation_amount: float = amplitude * 0.24
	var node_offset := Vector2(
		sin(shake_timer * 1.25 + phase) * variation_amount,
		sin(shake_timer * 1.7 + phase * 1.35 + PI / 5.0) * variation_amount
	)
	return base_offset + node_offset


func _set_shake_offset(target: Control, offset: Vector2) -> void:
	if not (target and is_instance_valid(target)):
		return
	var last_offset: Vector2 = target.get_meta("shake_last_offset", Vector2.ZERO)
	target.position -= last_offset
	target.position += offset
	target.set_meta("shake_last_offset", offset)


func _reset_shake_offsets() -> void:
	for target in _collect_shake_targets():
		_set_shake_offset(target, Vector2.ZERO)
	desktop_shake_amount = 0.0


# --- FAIL SEQUENCE ---

func _start_fail_sequence() -> void:
	if fail_sequence_started:
		return

	_ensure_fail_overlay()
	fail_sequence_started = true
	fail_fade_active = false
	fail_fade_elapsed = 0.0
	fail_return_started = false
	var fade_callable := Callable(self, "_begin_fail_fade")
	if fail_delay_timer and is_instance_valid(fail_delay_timer):
		if fail_delay_timer.timeout.is_connected(fade_callable):
			fail_delay_timer.timeout.disconnect(fade_callable)
	fail_delay_timer = null
	if fail_overlay and is_instance_valid(fail_overlay):
		fail_overlay.visible = true
		fail_overlay.color = FAIL_OVERLAY_BASE_COLOR
	var delay := randf_range(4.0, 5.0)
	fail_delay_timer = get_tree().create_timer(delay)
	fail_delay_timer.timeout.connect(fade_callable)


func _begin_fail_fade() -> void:
	fail_delay_timer = null
	fail_fade_active = true
	fail_fade_elapsed = 0.0
	_ensure_fail_overlay()
	if fail_overlay and is_instance_valid(fail_overlay):
		fail_overlay.visible = true
		fail_overlay.color = FAIL_OVERLAY_BASE_COLOR


func _reset_fail_state() -> void:
	var fade_callable := Callable(self, "_begin_fail_fade")
	if fail_delay_timer:
		if is_instance_valid(fail_delay_timer) and fail_delay_timer.timeout.is_connected(fade_callable):
			fail_delay_timer.timeout.disconnect(fade_callable)
	fail_delay_timer = null
	fail_sequence_started = false
	fail_fade_active = false
	fail_fade_elapsed = 0.0
	fail_return_started = false
	if fail_overlay and is_instance_valid(fail_overlay):
		fail_overlay.visible = false
		fail_overlay.color = Color(FAIL_OVERLAY_BASE_COLOR.r, FAIL_OVERLAY_BASE_COLOR.g, FAIL_OVERLAY_BASE_COLOR.b, 0.0)


# --- CLEANUP ---

func _cleanup_orphan_icons() -> void:
	# Cleanup any stray folder icons not in desktop_container
	var to_clean: Array[Node] = []
	var to_check: Array[Node] = [self]
	
	while not to_check.is_empty():
		var node: Node = to_check.pop_front() as Node
		
		if node == desktop_container or _is_in_desktop_container(node):
			continue
			
		if _has_folder_icon(node):
			to_clean.append(node)
		elif node is VBoxContainer or node is GridContainer:
			for child in node.get_children():
				if child is CenterContainer or child is VBoxContainer:
					var has_icon := false
					for grandchild in child.get_children():
						if _has_folder_icon(grandchild):
							has_icon = true
							break
					if has_icon:
						to_clean.append(child)
		
		to_check.append_array(node.get_children())
	
	for node in to_clean:
		node.queue_free()


func _is_in_desktop_container(node: Node) -> bool:
	var parent := node.get_parent()
	while parent:
		if parent == desktop_container:
			return true
		parent = parent.get_parent()
	return false


func _has_folder_icon(node: Node) -> bool:
	if node is TextureButton:
		var tex: Texture2D = node.texture_normal
		return tex != null and tex.resource_path.find("folder_icon.png") != -1
	elif node is TextureRect:
		var tex: Texture2D = node.texture
		return tex != null and tex.resource_path.find("folder_icon.png") != -1
	return false


func _hide_exit_button() -> void:
	var exit_button := get_node_or_null("ExitComputerButton") as Button
	if exit_button:
		exit_button.disabled = true
		exit_button.visible = false


func _show_exit_button() -> void:
	var exit_button := get_node_or_null("ExitComputerButton") as Button
	if exit_button:
		exit_button.disabled = false
		exit_button.visible = true


# Override base exit to handle mission cleanup
func _on_exit_computer_pressed() -> void:
	if not (mission_completed or mission_failed):
		return
	if mission_timer and not mission_timer.is_stopped():
		mission_timer.stop()
	_stop_tick()
	if success_heart_player and is_instance_valid(success_heart_player) and success_heart_player.playing:
		success_heart_player.stop()
	super._on_exit_computer_pressed()
