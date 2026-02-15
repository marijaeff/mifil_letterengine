extends Node

var client_id : String
var config : Dictionary

func load_client(id: String):
	client_id = id
	
	var path = "res://clients/%s/config.json" % id
	
	if not FileAccess.file_exists(path):
		push_error("Config not found: " + path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	
	config = JSON.parse_string(content)
	
	print("Client loaded:", client_id)
