extends "res://scripts/base_desktop.gd"
# Popup Hell Mini-Game: Close all the popup windows as fast as you can!

var popup_windows: Array = []
var popups_closed: int = 0
var game_started: bool = false
var game_completed: bool = false
var instructions_window: PanelContainer = null
var spawn_timer: Timer = null
var countdown_timer: Timer = null
var countdown_value: int = 5
var countdown_label: RichTextLabel = null
var game_timer: Timer = null
var time_remaining: int = 30  # 30 seconds
var timer_label: RichTextLabel = null
var heartbeat_sound: AudioStreamPlayer = null
var red_overlay: ColorRect = null
var tick_sound: AudioStreamPlayer = null
var beep_sound: AudioStreamPlayer = null
var popup_messages: Array = [
	"Click here for FREE money!",
	"Your computer has 1000 viruses!",
	"Congratulations! You won!",
	"Hot singles in your area!",
	"Download now!",
	"Act fast! Limited time offer!",
	"Your warranty has expired!",
	"Update required immediately!",
	"You are the 1,000,000th visitor!",
	"Claim your prize now!",
	"URGENT: Action needed!",
	"Click to continue...",
	"Warning: Security alert!",
	"Your files may be at risk!",
	"Subscribe for more content!"
]


func _ready() -> void:
	super._ready()  # Call base desktop setup
	
	# Set clock to run from 8:00 to 20:00 (12 hours) over the game duration (30 seconds)
	set_clock_parameters(8, 20, time_remaining)
	
	# Hide exit button immediately
	_hide_exit_button()
	
	_show_game_instructions()


func _show_game_instructions() -> void:
	var warning_text := "[center][b][color=red] WARNING [/color][/b]\n\n"
	warning_text += "[font_size=24]YOUR COMPUTER HAS BEEN HACKED![/font_size]\n\n"
	warning_text += "CLOSE THE POPUPS![/center]"
	
	var base_position := Vector2(get_viewport_rect().size.x / 2 - 250, get_viewport_rect().size.y / 2 - 200)
	
	instructions_window = create_window("SYSTEM ALERT", base_position, Vector2(500, 400), true)
	var content_area = find_child_by_name(instructions_window, "content")
	if not content_area:
		content_area = instructions_window

	var message_label := RichTextLabel.new()
	message_label.bbcode_enabled = true
	message_label.text = warning_text
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_label.custom_minimum_size = Vector2(0, 150)
	message_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	content_area.add_child(message_label)
	
	# Add countdown label
	countdown_label = RichTextLabel.new()
	countdown_label.bbcode_enabled = true
	countdown_label.text = "[center][font_size=72][color=red]5[/color][/font_size][/center]"
	countdown_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	countdown_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	countdown_label.custom_minimum_size = Vector2(0, 150)
	countdown_label.add_theme_color_override("font_color", Color(1, 0, 0))
	content_area.add_child(countdown_label)

	add_child(instructions_window)
	bring_to_front(instructions_window)
	
	# Start countdown immediately
	_start_countdown()


func _start_countdown() -> void:
	countdown_timer = Timer.new()
	countdown_timer.wait_time = 1.0
	countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(countdown_timer)
	countdown_timer.start()


func _on_countdown_tick() -> void:
	countdown_value -= 1
	
	if countdown_label and is_instance_valid(countdown_label):
		countdown_label.text = "[center][font_size=72][color=red]%d[/color][/font_size][/center]" % countdown_value
	
	if countdown_value <= 0:
		if countdown_timer and is_instance_valid(countdown_timer):
			countdown_timer.stop()
			countdown_timer.queue_free()
		_start_game()


func _start_game() -> void:
	game_started = true
	
	# Hide the exit button so player can't escape
	_hide_exit_button()
	
	# Close instructions window
	if instructions_window and is_instance_valid(instructions_window):
		instructions_window.queue_free()
	instructions_window = null
	
	# Create spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 1.0  # Spawn a popup every 1 second
	spawn_timer.timeout.connect(_spawn_popup)
	add_child(spawn_timer)
	spawn_timer.start()
	
	# Create game timer (60 seconds countdown)
	game_timer = Timer.new()
	game_timer.wait_time = 1.0
	game_timer.timeout.connect(_on_game_timer_tick)
	add_child(game_timer)
	game_timer.start()
	
	# Create timer display
	_create_timer_display()
	
	# Setup tick-tock sound
	_setup_tick_sound()
	
	# Spawn initial popups
	for i in range(3):
		_spawn_popup()
	
	print("🔥 Popup hell started! Close all popups in 30 seconds!")


func _create_timer_display() -> void:
	# Create a fixed timer display at the top of the screen
	timer_label = RichTextLabel.new()
	timer_label.bbcode_enabled = true
	timer_label.text = "[center][b][color=red]TIME: 30[/color][/b][/center]"
	timer_label.position = Vector2(get_viewport_rect().size.x / 2 - 100, 20)
	timer_label.size = Vector2(200, 50)
	timer_label.add_theme_color_override("font_color", Color(1, 0, 0))
	timer_label.add_theme_font_size_override("font_size", 24)
	timer_label.z_index = 1000  # Always on top
	add_child(timer_label)


func _on_game_timer_tick() -> void:
	time_remaining -= 1
	
	# Play tick sound with increasing volume
	_play_tick_sound()
	
	# Update timer display
	if timer_label and is_instance_valid(timer_label):
		var color := "red" if time_remaining <= 10 else "yellow"
		timer_label.text = "[center][b][color=%s]TIME: %d[/color][/b][/center]" % [color, time_remaining]
	
	# Start heartbeat sound at 10 seconds
	if time_remaining == 10:
		_start_heartbeat_sound()
	
	# Check if time ran out
	if time_remaining <= 0:
		_game_over()


func _game_over() -> void:
	game_completed = true
	game_started = false
	
	# Stop timers
	if spawn_timer and is_instance_valid(spawn_timer):
		spawn_timer.stop()
		spawn_timer.queue_free()
	if game_timer and is_instance_valid(game_timer):
		game_timer.stop()
		game_timer.queue_free()
	
	# Stop sounds
	_stop_heartbeat_sound()
	_stop_tick_sound()
	
	# Hide timer display
	if timer_label and is_instance_valid(timer_label):
		timer_label.queue_free()
	
	print("💀 Game over! Time ran out!")
	
	# Close all remaining popups
	for popup in popup_windows:
		if popup and is_instance_valid(popup):
			popup.queue_free()
	popup_windows.clear()
	
	# Show game over message
	var gameover_text := "[center][b][color=red]GAME OVER[/color][/b]\n\n"
	gameover_text += "you suck[/center]"
	
	var base_position := Vector2(get_viewport_rect().size.x / 2 - 250, get_viewport_rect().size.y / 2 - 150)
	
	var gameover_window := create_window("FAILED", base_position, Vector2(500, 300), true)
	var content_area = find_child_by_name(gameover_window, "content")
	if not content_area:
		content_area = gameover_window

	var gameover_label := RichTextLabel.new()
	gameover_label.bbcode_enabled = true
	gameover_label.text = gameover_text
	gameover_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gameover_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gameover_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	gameover_label.add_theme_font_size_override("font_size", 16)
	content_area.add_child(gameover_label)

	add_child(gameover_window)
	bring_to_front(gameover_window)
	
	# Start red fade after 1.0 seconds
	await get_tree().create_timer(1.5).timeout
	_start_red_fade(gameover_window)


func _start_red_fade(gameover_window: PanelContainer) -> void:
	# Create red overlay
	red_overlay = ColorRect.new()
	red_overlay.color = Color(1, 0, 0, 0)  # Red with 0 alpha (transparent)
	red_overlay.size = get_viewport_rect().size
	red_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	red_overlay.z_index = 9999  # Very high to be above everything except cursor
	add_child(red_overlay)
	
	# Start beep sound that gets louder
	_start_beep_sound()
	
	# Create tween to fade in red and fade out window simultaneously
	var tween := create_tween()
	tween.set_parallel(true)  # Run both animations at the same time
	tween.tween_property(red_overlay, "color", Color(1, 0, 0, 0.8), 2.0)  # Fade to 80% opacity over 2 seconds
	
	# Fade out the game over window
	if gameover_window and is_instance_valid(gameover_window):
		tween.tween_property(gameover_window, "modulate", Color(1, 1, 1, 0), 2.0)  # Fade out over 2 seconds
	
	print("💀 Red screen fade started...")
	
	# Wait for red fade to complete, then cut to black and return to office
	await tween.finished
	_cut_to_black_and_return_to_office()


func _spawn_popup() -> void:
	if not game_started or game_completed:
		return
	
	# Don't spawn too many at once
	if popup_windows.size() >= 12:
		return
	
	var viewport_size := get_viewport_rect().size
	var popup_size := Vector2(300, 150)
	
	# Random position
	var pos := Vector2(
		randf_range(50, viewport_size.x - popup_size.x - 50),
		randf_range(50, viewport_size.y - popup_size.y - 50)
	)
	
	# Random message
	var message: String = popup_messages.pick_random()
	
	var popup := create_window(
		"Advertisement",
		pos,
		popup_size,
		false  # Light background to stand out
	)
	
	# Override the close button behavior
	_setup_popup_close_button(popup)
	
	# Add popup content
	var content_area = find_child_by_name(popup, "content")
	if content_area:
		var popup_label := RichTextLabel.new()
		popup_label.bbcode_enabled = true
		popup_label.text = "[center][b]%s[/b][/center]" % message
		popup_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		popup_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		popup_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		popup_label.add_theme_font_size_override("font_size", 14)
		content_area.add_child(popup_label)
		
		# Add annoying button
		var fake_button := Button.new()
		fake_button.text = "CLICK HERE!"
		fake_button.custom_minimum_size = Vector2(150, 40)
		fake_button.connect("pressed", Callable(self, "_on_fake_button_pressed"))
		content_area.add_child(fake_button)
	
	add_child(popup)
	bring_to_front(popup)
	popup_windows.append(popup)
	
	# Make popup randomly move occasionally
	_make_popup_move_randomly(popup)


func _setup_popup_close_button(popup: PanelContainer) -> void:
	# Find the close button in the window header
	for child in popup.get_children():
		if child is VBoxContainer:
			for vbox_child in child.get_children():
				if vbox_child is ColorRect:  # Header bar
					for header_child in vbox_child.get_children():
						if header_child is HBoxContainer:
							for hbox_child in header_child.get_children():
								if hbox_child is Button and hbox_child.text == "X":
									# Disconnect default close behavior
									for connection in hbox_child.pressed.get_connections():
										hbox_child.pressed.disconnect(connection.callable)
									# Connect to our custom close
									hbox_child.connect("pressed", Callable(self, "_close_popup").bind(popup))
									return


func _close_popup(popup: PanelContainer) -> void:
	if not popup or not is_instance_valid(popup):
		return
	
	popup_windows.erase(popup)
	popup.queue_free()
	popups_closed += 1
	
	print("Closed popup! Total closed: %d, Remaining: %d" % [popups_closed, popup_windows.size()])
	
	# Check if all popups are closed (win condition)
	if popup_windows.size() == 0 and game_started:
		_complete_game()


func _on_fake_button_pressed() -> void:
	# Clicking the button spawns MORE popups! (evil laugh)
	for i in range(2):
		_spawn_popup()
	print("😈 You clicked the button! More popups spawned!")


func _make_popup_move_randomly(popup: PanelContainer) -> void:
	# Make popup occasionally jump to a new position
	var move_timer := Timer.new()
	move_timer.wait_time = randf_range(2.0, 4.0)
	move_timer.one_shot = false
	move_timer.timeout.connect(func():
		if popup and is_instance_valid(popup) and not game_completed:
			var viewport_size := get_viewport_rect().size
			var popup_size := popup.size
			popup.position = Vector2(
				randf_range(50, viewport_size.x - popup_size.x - 50),
				randf_range(50, viewport_size.y - popup_size.y - 50)
			)
			bring_to_front(popup)
	)
	popup.add_child(move_timer)
	move_timer.start()


func _complete_game() -> void:
	game_completed = true
	game_started = false
	
	if spawn_timer and is_instance_valid(spawn_timer):
		spawn_timer.stop()
		spawn_timer.queue_free()
	if game_timer and is_instance_valid(game_timer):
		game_timer.stop()
		game_timer.queue_free()
	
	# Stop sounds
	_stop_heartbeat_sound()
	_stop_tick_sound()
	
	# Hide timer display
	if timer_label and is_instance_valid(timer_label):
		timer_label.queue_free()
	
	print("🎉 Game completed! All popups closed!")
	
	# Close all remaining popups
	for popup in popup_windows:
		if popup and is_instance_valid(popup):
			popup.queue_free()
	popup_windows.clear()
	
	# Show completion message
	var completion_text := "[b][color=green]You survived Popup Hell![/color][/b]\n\n"
	completion_text += "You closed [color=yellow]%d popups[/color]!\n\n" % popups_closed
	completion_text += "Time remaining: [color=cyan]%d seconds[/color]\n\n" % time_remaining
	completion_text += "Your desktop is finally clean again. "
	
	var base_position := Vector2(get_viewport_rect().size.x / 2 - 250, get_viewport_rect().size.y / 2 - 150)
	
	var completion_window := create_window("Victory!", base_position, Vector2(500, 300), true)
	var content_area = find_child_by_name(completion_window, "content")
	if not content_area:
		content_area = completion_window

	var completion_label := RichTextLabel.new()
	completion_label.bbcode_enabled = true
	completion_label.text = completion_text
	completion_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	completion_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	completion_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	completion_label.add_theme_font_size_override("font_size", 16)
	content_area.add_child(completion_label)

	add_child(completion_window)
	bring_to_front(completion_window)
	
	# Show exit button again
	_show_exit_button()


func _hide_exit_button() -> void:
	var exit_button := get_node_or_null("ExitComputerButton")
	if exit_button:
		exit_button.visible = false


func _show_exit_button() -> void:
	var exit_button := get_node_or_null("ExitComputerButton")
	if exit_button:
		exit_button.visible = true


func _start_heartbeat_sound() -> void:
	if heartbeat_sound and is_instance_valid(heartbeat_sound):
		return  # Already playing
	
	heartbeat_sound = AudioStreamPlayer.new()
	var sound_path := "res://sound/fast_heart_beat_-_sound_effect.wav"
	
	if ResourceLoader.exists(sound_path):
		var stream: AudioStream = load(sound_path)
		heartbeat_sound.stream = stream
		heartbeat_sound.volume_db = -5.0  # Slightly lower volume
		add_child(heartbeat_sound)
		heartbeat_sound.play()
		print("🫀 Heartbeat sound started!")
	else:
		push_warning("Heartbeat sound not found at: %s" % sound_path)


func _stop_heartbeat_sound() -> void:
	if heartbeat_sound and is_instance_valid(heartbeat_sound):
		heartbeat_sound.stop()
		heartbeat_sound.queue_free()
		heartbeat_sound = null


func _setup_tick_sound() -> void:
	tick_sound = AudioStreamPlayer.new()
	var sound_path := "res://sound/untitled.wav"  # Replace with your tick-tock sound file
	
	if ResourceLoader.exists(sound_path):
		var stream: AudioStream = load(sound_path)
		tick_sound.stream = stream
		tick_sound.volume_db = -30.0  # Start very quiet
		add_child(tick_sound)
		print("⏰ Tick sound loaded!")
	else:
		push_warning("Tick sound not found at: %s" % sound_path)


func _play_tick_sound() -> void:
	if not tick_sound or not is_instance_valid(tick_sound):
		return
	
	# Calculate volume based on time remaining (gets louder as time runs out)
	# Start at -30dB and go up to 0dB
	var progress: float = 1.0 - (float(time_remaining) / 30.0)  # 0.0 at start, 1.0 at end
	var volume_db: float = lerp(-30.0, 0.0, progress)
	
	tick_sound.volume_db = volume_db
	tick_sound.play()
	
	print("⏰ Tick! Volume: %.1f dB (Time: %d)" % [volume_db, time_remaining])


func _stop_tick_sound() -> void:
	if tick_sound and is_instance_valid(tick_sound):
		tick_sound.stop()
		tick_sound.queue_free()
		tick_sound = null


func _start_beep_sound() -> void:
	beep_sound = AudioStreamPlayer.new()
	var sound_path := "res://sound/untitled.wav"  # Replace with your beep sound file
	
	if ResourceLoader.exists(sound_path):
		var stream: AudioStream = load(sound_path)
		beep_sound.stream = stream
		beep_sound.volume_db = -40.0  # Start very quiet
		add_child(beep_sound)
		beep_sound.play()
		
		# Create tween to increase volume over 2 seconds
		var tween := create_tween()
		tween.tween_property(beep_sound, "volume_db", 5.0, 2.0)  # Fade from -40dB to +5dB over 2 seconds
		
		print("📢 Beep sound started with volume fade!")
	else:
		push_warning("Beep sound not found at: %s" % sound_path)


func _cut_to_black_and_return_to_office() -> void:
	print("⚫ Cutting to black screen...")
	
	# Create black overlay
	var black_overlay := ColorRect.new()
	black_overlay.color = Color(0, 0, 0, 0)  # Black with 0 alpha
	black_overlay.size = get_viewport_rect().size
	black_overlay.z_index = 10000  # Above everything
	add_child(black_overlay)
	
	# Quick fade to black (0.5 seconds)
	var fade_tween := create_tween()
	fade_tween.tween_property(black_overlay, "color", Color(0, 0, 0, 1), 0.5)
	
	await fade_tween.finished
	
	# Wait a moment in black
	await get_tree().create_timer(0.5).timeout
	
	# Return to office scene
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	const EXIT_SCENE_PATH := "res://node_3d.tscn"
	
	if ResourceLoader.exists(EXIT_SCENE_PATH):
		get_tree().change_scene_to_file(EXIT_SCENE_PATH)
		print("🏢 Returning to office...")
	else:
		push_error("Office scene not found: %s" % EXIT_SCENE_PATH)
