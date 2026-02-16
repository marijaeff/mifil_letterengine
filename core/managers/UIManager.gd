extends Node

func apply_theme():
	var config = DataLoader.config
	
	if not config.has("ui"):
		return
	
	var ui_config = config["ui"]
	
	var font_relative_path = ui_config.get("font", "")
	var font_size = ui_config.get("font_size", 32)
	var button_font_size = ui_config.get("button_font_size", font_size)
	
	if font_relative_path == "":
		return
	
	var base_path = "res://clients/%s/" % DataLoader.client_id
	var full_path = base_path + font_relative_path
	
	var font = load(full_path)
	
	var theme = Theme.new()
	
	theme.set_font("font", "Label", font)
	theme.set_font_size("font_size", "Label", font_size)

	theme.set_font("font", "Button", font)
	
	theme.set_font_size("font_size", "Button", button_font_size)
	
	get_tree().root.theme = theme
