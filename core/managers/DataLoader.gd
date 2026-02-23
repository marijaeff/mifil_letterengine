extends Node

var client_id: String
var config: Dictionary
var texts: Dictionary
var levels: Dictionary

func load_client(id: String) -> void:
	client_id = id

	var base_path: String = "res://clients/%s/" % id

	var config_path: String = base_path + "config.json"

	if not FileAccess.file_exists(config_path):
		push_error("Config not found: " + config_path)
		return

	config = load_json(config_path)

	var texts_path: String = base_path + "texts.json"

	if FileAccess.file_exists(texts_path):
		texts = load_json(texts_path)
	else:
		texts = {}
		push_warning("Texts not found: " + texts_path)

	print("Client loaded:", client_id)
	
	var levels_path: String = base_path + "levels.json"
	if FileAccess.file_exists(levels_path):
		levels = load_json(levels_path)
	else:
		levels = {}
		push_warning("Levels not found: " + levels_path)

func load_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var content: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(content)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON format in: " + path)
		return {}

	return parsed as Dictionary
