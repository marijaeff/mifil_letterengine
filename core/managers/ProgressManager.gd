extends Node

var completed_level: int = 0
var selected_level: int = 1

var save_path: String = "user://progress.save"


func load_progress() -> void:
	if not FileAccess.file_exists(save_path):
		return

	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var data: Dictionary = parsed as Dictionary

	completed_level = int(data.get("completed_level", 0))
	selected_level = int(data.get("selected_level", completed_level + 1))


func save_progress() -> void:
	var data := {
		"completed_level": completed_level,
		"selected_level": selected_level
	}

	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func complete_level(level_index: int) -> void:
	completed_level = max(completed_level, level_index)
	selected_level = completed_level + 1
	save_progress()


func select_level(level_index: int) -> void:
	selected_level = level_index
	save_progress()


func reset_progress() -> void:
	completed_level = 0
	selected_level = 1
	save_progress()
