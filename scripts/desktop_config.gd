extends Node
# Desktop Configuration - Controls which desktop mode is active
# Change DESKTOP_MODE to switch between different desktop experiences

enum DesktopMode {
	BROWSABLE,          # Browse folders, read mail, take notes (no game)
	READ_MAIL_GAME,     # Mini-game: Read all emails from coworkers
	FOLDER_RACE_GAME,   # Mini-game: Find file before time runs out
	ORGANIZE_FILES_GAME,# Mini-game: Drag files into folders to clean desktop
	POPUP_HELL_GAME     # Mini-game: Close all the popup windows!
}

# ⚙️ CHANGE THIS TO SWITCH DESKTOP MODES ⚙️
var current_mode: DesktopMode = DesktopMode.BROWSABLE
var day_schedule: Dictionary = {
	1: DesktopMode.FOLDER_RACE_GAME,
	2: DesktopMode.READ_MAIL_GAME,
	3: DesktopMode.POPUP_HELL_GAME,
	4: DesktopMode.ORGANIZE_FILES_GAME
}

func _ready() -> void:
	if typeof(GameState) == TYPE_NIL or GameState == null:
		return
	var schedule := {}
	for day in day_schedule.keys():
		var entry = day_schedule[day]
		if entry is int:
			schedule[day] = _mode_to_script_path(entry)
		elif entry is String:
			schedule[day] = entry
	if schedule.is_empty():
		return
	GameState.set_minigame_schedule(schedule)


func get_desktop_script_path() -> String:
	if typeof(GameState) != TYPE_NIL and GameState:
		var scheduled_path = GameState.get_desktop_script_for_day(GameState.current_day)
		if scheduled_path != "":
			return scheduled_path
	return _mode_to_script_path(current_mode)


func get_mode_name() -> String:
	match current_mode:
		DesktopMode.BROWSABLE:
			return "Browsable Desktop"
		DesktopMode.READ_MAIL_GAME:
			return "Read Mail Mini-Game"
		DesktopMode.FOLDER_RACE_GAME:
			return "Folder Race Mini-Game"
		DesktopMode.ORGANIZE_FILES_GAME:
			return "Organize Files Mini-Game"
		DesktopMode.POPUP_HELL_GAME:
			return "Popup Hell Mini-Game"
		_:
			return "Unknown"

func _mode_to_script_path(mode: DesktopMode) -> String:
	match mode:
		DesktopMode.BROWSABLE:
			return "res://scripts/browsable_desktop.gd"
		DesktopMode.READ_MAIL_GAME:
			return "res://scripts/read_mail_minigame.gd"
		DesktopMode.FOLDER_RACE_GAME:
			return "res://scripts/folder_race_minigame.gd"
		DesktopMode.ORGANIZE_FILES_GAME:
			return "res://scripts/organize_files_minigame.gd"
		DesktopMode.POPUP_HELL_GAME:
			return "res://scripts/pop_up_hell_minigame.gd"
		_:
			return "res://scripts/browsable_desktop.gd"
