extends "res://scripts/browsable_desktop.gd"
# Read Mail Mini-Game: Read all emails from your coworkers to complete the game

# Email data structure for each contact
var email_database: Dictionary = {}
var unread_emails: Array = []
var total_emails: int = 0
var emails_read: int = 0
var game_completed: bool = false
var instructions_window: PanelContainer = null


func _ready() -> void:
	super._ready()  # Call browsable desktop setup
	
	# Set clock to run from 8:00 to 16:00 (8 hours) over estimated task duration
	# Assuming ~2-3 minutes to read all emails
	set_clock_parameters(8, 16, 150.0)  # 150 seconds = 2.5 minutes
	
	# Generate emails for each contact
	_generate_emails()
	_update_mail_contacts_with_unread_count()
	
	# Show welcome message
	_show_game_instructions()


func _generate_emails() -> void:
	# Generate 3-4 emails for each coworker
	for coworker in coworkers:
		var contact_name: String = coworker.name
		var email_count: int = randi_range(3, 4)
		email_database[contact_name] = []
		
		for i in range(email_count):
			var email := {
				"subject": _generate_email_subject(contact_name, i),
				"body": _generate_email_body(contact_name, i),
				"read": false,
				"id": "%s_%d" % [contact_name, i]
			}
			email_database[contact_name].append(email)
			unread_emails.append(email["id"])
			total_emails += 1
	
	print("Generated %d emails total" % total_emails)


func _generate_email_subject(contact_name: String, index: int) -> String:
	var subjects := {
		"Alex Pendell": [
			"Weekly Team Sync",
			"Project Timeline Update",
			"Budget Approval Needed",
			"Client Feedback"
		],
		"Sarah Chen": [
			"Code Review Request",
			"Bug Fix Deployed",
			"New Feature Proposal",
			"Technical Documentation"
		],
		"Marcus Johnson": [
			"UI Mockups Ready",
			"User Testing Results",
			"Design System Update",
			"Accessibility Review"
		],
		"Emma Williams": [
			"Sprint Planning",
			"Stakeholder Meeting Notes",
			"Product Roadmap Q4",
			"User Story Priorities"
		]
	}
	
	if subjects.has(contact_name) and index < subjects[contact_name].size():
		return subjects[contact_name][index]
	return "Message %d" % (index + 1)


func _generate_email_body(contact_name: String, index: int) -> String:
	var bodies := {
		"Alex Pendell": [
			"Hi team,\n\nJust a reminder about our weekly sync tomorrow at 10 AM. Please come prepared with your updates.\n\nBest,\nAlex",
			"Team,\n\nThe project timeline has been adjusted. New deadline is end of month. Let's discuss priorities.\n\nRegards,\nAlex",
			"Hi,\n\nI need approval for the additional budget allocation. Please review the attached document.\n\nThanks,\nAlex",
			"Everyone,\n\nClient loved the latest demo! Great work. A few minor tweaks requested - see notes.\n\nAlex"
		],
		"Sarah Chen": [
			"Hey,\n\nCould you review my pull request when you get a chance? Added the new authentication flow.\n\nThanks!\nSarah",
			"Team,\n\nThe critical bug from yesterday has been fixed and deployed to production. Monitoring looks good.\n\nSarah",
			"Hi all,\n\nI have an idea for improving our data caching. Would love to discuss at the next tech meeting.\n\nCheers,\nSarah",
			"Everyone,\n\nUpdated the technical docs for the API. Let me know if anything needs clarification.\n\nSarah"
		],
		"Marcus Johnson": [
			"Hey team,\n\nNew UI mockups are ready for the dashboard redesign. Check them out and share feedback!\n\nMarcus",
			"Hi,\n\nUser testing showed great results! 87% approval rating. Some minor navigation tweaks suggested.\n\nBest,\nMarcus",
			"Team,\n\nUpdated our design system with new color palette and components. Please use these going forward.\n\nMarcus",
			"Everyone,\n\nCompleted accessibility audit. We're meeting WCAG 2.1 AA standards. Few recommendations attached.\n\nMarcus"
		],
		"Emma Williams": [
			"Team,\n\nSprint planning is scheduled for Friday 2 PM. Please review the backlog before then.\n\nEmma",
			"Hi all,\n\nSummary from yesterday's stakeholder meeting attached. Key action items highlighted.\n\nRegards,\nEmma",
			"Team,\n\nQ4 product roadmap is finalized. Focus areas: performance, new features, and user growth.\n\nEmma",
			"Everyone,\n\nUpdated user story priorities based on customer feedback. Epic-123 moved to top priority.\n\nEmma"
		]
	}
	
	if bodies.has(contact_name) and index < bodies[contact_name].size():
		return bodies[contact_name][index]
	return "This is message number %d from %s.\n\nThank you for reading!" % [(index + 1), contact_name]


func _show_game_instructions() -> void:
	var instruction_text := "[b]Mini-Game: Read All Emails[/b]\n\n"
	instruction_text += "Welcome! You have [color=yellow]%d unread emails[/color] from your coworkers.\n\n" % total_emails
	instruction_text += "Your task: Read all emails to complete the game.\n\n"
	instruction_text += "[color=#888888]Check your Mail window and click on contacts to read their messages.[/color]"
	
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


# Override the contact click to show email list instead of single message
func _on_contact_clicked(contact_name: String) -> void:
	if not email_database.has(contact_name):
		return
	
	_show_email_list(contact_name)


func _show_email_list(contact_name: String) -> void:
	var base_position := Vector2(120, 80)
	if mail_window and is_instance_valid(mail_window):
		base_position = mail_window.position + Vector2(50, 50)

	var email_list_window := create_window(contact_name + " - Inbox", base_position, Vector2(500, 400), true)
	var content_area = find_child_by_name(email_list_window, "content")
	if not content_area:
		content_area = email_list_window

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.add_child(scroll)

	var email_list := VBoxContainer.new()
	email_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	email_list.add_theme_constant_override("separation", 5)
	scroll.add_child(email_list)

	var emails: Array = email_database[contact_name]
	for email in emails:
		var email_button := Button.new()
		email_button.custom_minimum_size = Vector2(460, 60)
		email_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var vbox := VBoxContainer.new()
		email_button.add_child(vbox)
		
		var subject_label := Label.new()
		var subject_text: String = email.subject
		if not email.read:
			subject_text = "• " + subject_text + " [UNREAD]"
		subject_label.text = subject_text
		subject_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95) if not email.read else Color(0.7, 0.7, 0.7))
		subject_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(subject_label)
		
		var status_label := Label.new()
		status_label.text = "Read" if email.read else "Unread"
		status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5) if email.read else Color(0.9, 0.6, 0.2))
		status_label.add_theme_font_size_override("font_size", 10)
		vbox.add_child(status_label)
		
		email_list.add_child(email_button)
		email_button.connect("pressed", Callable(self, "_on_email_clicked").bind(contact_name, email, email_list_window))

	add_child(email_list_window)
	bring_to_front(email_list_window)


func _on_email_clicked(contact_name: String, email: Dictionary, inbox_window: PanelContainer) -> void:
	var base_position := Vector2(180, 140)
	
	var email_window := create_window("Email: " + email.subject, base_position, Vector2(550, 400), true)
	var content_area = find_child_by_name(email_window, "content")
	if not content_area:
		content_area = email_window

	# Email content
	var email_content := RichTextLabel.new()
	email_content.bbcode_enabled = true
	email_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	email_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	email_content.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	
	var email_text := "[b]From:[/b] %s\n" % contact_name
	email_text += "[b]Subject:[/b] %s\n" % email.subject
	email_text += "[b]Status:[/b] %s\n\n" % ("Read" if email.read else "[color=orange]Unread[/color]")
	email_text += "%s" % email.body
	
	email_content.text = email_text
	content_area.add_child(email_content)

	# Add "Mark as Read" button at the bottom if unread
	if not email.read:
		var button_container := HBoxContainer.new()
		button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button_container.add_theme_constant_override("separation", 8)
		
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button_container.add_child(spacer)
		
		var mark_read_button := Button.new()
		mark_read_button.text = "Mark as Read"
		mark_read_button.custom_minimum_size = Vector2(150, 40)
		mark_read_button.connect("pressed", Callable(self, "_on_mark_email_read").bind(email, email_window, email_content, contact_name, inbox_window))
		button_container.add_child(mark_read_button)
		
		content_area.add_child(button_container)

	add_child(email_window)
	bring_to_front(email_window)


func _on_mark_email_read(email: Dictionary, email_window: PanelContainer, email_content: RichTextLabel, contact_name: String, inbox_window: PanelContainer) -> void:
	if email.read:
		return  # Already read
	
	# Validate windows are still valid
	if not email_window or not is_instance_valid(email_window):
		return
	if not inbox_window or not is_instance_valid(inbox_window):
		return
	
	# Mark as read
	email.read = true
	unread_emails.erase(email.id)
	emails_read += 1
	
	print("Read email: %s (Progress: %d/%d)" % [email.id, emails_read, total_emails])
	
	# Update the email content to show it's now read
	var email_text := "[b]From:[/b] %s\n" % contact_name
	email_text += "[b]Subject:[/b] %s\n" % email.subject
	email_text += "[b]Status:[/b] [color=green]Read[/color]\n\n"
	email_text += "%s" % email.body
	email_content.text = email_text
	
	# Remove the button from the window
	var content_area = find_child_by_name(email_window, "content")
	if content_area:
		for child in content_area.get_children():
			if child is HBoxContainer:
				child.queue_free()
	
	# Update the inbox list instantly
	_refresh_inbox_list(contact_name, inbox_window)
	
	# Update mail window to show new read status
	_update_mail_contacts_with_unread_count()
	
	# Check if game is complete
	if emails_read >= total_emails and not game_completed:
		_complete_game()


func _refresh_inbox_list(contact_name: String, inbox_window: PanelContainer) -> void:
	# Find the email list container in the inbox window
	if not inbox_window or not is_instance_valid(inbox_window):
		return
	
	var content_area = find_child_by_name(inbox_window, "content")
	if not content_area:
		return
	
	# Find the ScrollContainer
	var scroll: ScrollContainer = null
	for child in content_area.get_children():
		if child is ScrollContainer:
			scroll = child
			break
	
	if not scroll:
		return
	
	# Find the VBoxContainer with the email list
	var email_list: VBoxContainer = null
	for child in scroll.get_children():
		if child is VBoxContainer:
			email_list = child
			break
	
	if not email_list:
		return
	
	# Clear and rebuild the email list
	for child in email_list.get_children():
		child.queue_free()
	
	var emails: Array = email_database[contact_name]
	for email in emails:
		var email_button := Button.new()
		email_button.custom_minimum_size = Vector2(460, 60)
		email_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var vbox := VBoxContainer.new()
		email_button.add_child(vbox)
		
		var subject_label := Label.new()
		var subject_text: String = email.subject
		if not email.read:
			subject_text = "• " + subject_text + " [UNREAD]"
		subject_label.text = subject_text
		subject_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95) if not email.read else Color(0.7, 0.7, 0.7))
		subject_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(subject_label)
		
		var status_label := Label.new()
		status_label.text = "Read" if email.read else "Unread"
		status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5) if email.read else Color(0.9, 0.6, 0.2))
		status_label.add_theme_font_size_override("font_size", 10)
		vbox.add_child(status_label)
		
		email_list.add_child(email_button)
		email_button.connect("pressed", Callable(self, "_on_email_clicked").bind(contact_name, email, inbox_window))


func _update_mail_contacts_with_unread_count() -> void:
	# Update coworker has_new_mail based on unread emails
	for coworker in coworkers:
		var contact_name: String = coworker.name
		var has_unread := false
		
		if email_database.has(contact_name):
			for email in email_database[contact_name]:
				if not email.read:
					has_unread = true
					break
		
		coworker.has_new_mail = has_unread
	
	# Refresh the mail contacts display
	_show_mail_contacts()


func _complete_game() -> void:
	game_completed = true
	print(" Game completed! All emails read!")
	
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
						label.text = "Mission Complete!"
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
	var completion_text := "[b][color=green]Congratulations![/color][/b]\n\n"
	completion_text += "You've read all [color=yellow]%d emails[/color] from your coworkers!\n\n" % total_emails
	completion_text += "Task complete. Great job staying on top of your inbox! "
	
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
