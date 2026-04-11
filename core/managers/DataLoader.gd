extends Node

var client_id: String
var locale: String = ""

var config: Dictionary
var texts: Dictionary
var levels: Dictionary

func load_client(id: String, p_locale: String = "") -> void:
	client_id = id
	locale = p_locale

	var base_path: String = "res://clients/%s/" % id

	var config_name := "config.json" if locale == "" else "config_%s.json" % locale
	var texts_name := "texts.json" if locale == "" else "texts_%s.json" % locale

	var config_path: String = base_path + config_name
	if not FileAccess.file_exists(config_path):
		config_path = base_path + "config.json"

	config = load_json(config_path)

	var texts_path: String = base_path + texts_name
	if FileAccess.file_exists(texts_path):
		texts = load_json(texts_path)
	else:
		var fallback_texts_path := base_path + "texts.json"
		if FileAccess.file_exists(fallback_texts_path):
			texts = load_json(fallback_texts_path)
		else:
			texts = {}
			push_warning("Texts not found: " + texts_path)

	var levels_path: String = base_path + "levels.json"
	if FileAccess.file_exists(levels_path):
		levels = load_json(levels_path)
	else:
		levels = {}
		push_warning("Levels not found: " + levels_path)

	print("Client loaded:", client_id, "locale:", locale)

func load_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open file: " + path)
		return {}

	var content: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON format in: " + path)
		return {}

	return parsed as Dictionary

func resolve_client_path(rel_path: String) -> String:
	if rel_path.begins_with("res://") or rel_path.begins_with("user://"):
		return rel_path

	if client_id.is_empty():
		push_error("DataLoader.resolve_client_path: client_id is empty. Call load_client() first.")
		return rel_path

	return "res://clients/%s/%s" % [client_id, rel_path]

func resolve_scene_path(rel_path: String) -> String:
	if rel_path.begins_with("res://") or rel_path.begins_with("user://"):
		return rel_path

	if client_id.is_empty():
		push_error("DataLoader.resolve_scene_path: client_id is empty. Call load_client() first.")
		return rel_path

	var client_scene_path := "res://clients/%s/scenes/%s" % [client_id, rel_path]
	if ResourceLoader.exists(client_scene_path):
		return client_scene_path

	var shared_scene_path := "res://scenes/%s" % rel_path
	if ResourceLoader.exists(shared_scene_path):
		return shared_scene_path

	push_error("Scene not found: " + rel_path)
	return shared_scene_path
