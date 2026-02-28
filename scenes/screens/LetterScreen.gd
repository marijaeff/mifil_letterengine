extends Control

@onready var background: TextureRect = $Background
@onready var heart: TextureRect = $VBox/Control/Heart
@onready var paper: NinePatchRect = $VBox/Control/ScrollContainer/Paper
@onready var text_label: RichTextLabel = $VBox/Control/ScrollContainer/Paper/MarginContainer/TextLabel
@onready var scroll: ScrollContainer = $VBox/Control/ScrollContainer

@onready var close_button: Button = $VBox/Control/CloseButton


var config: Dictionary


func _ready() -> void:
	config = DataLoader.config["screens"]["letter"] as Dictionary
	
	_load_assets()
	_load_text()
	_configure_scroll()
	_apply_ui_style()
	_update_paper_height()
	
	close_button.pressed.connect(_on_close_button_pressed)


func _load_assets() -> void:
	var base_path: String = "res://clients/%s/" % DataLoader.client_id
	
	background.texture = load(base_path + config.get("background", "")) as Texture2D
	heart.texture = load(base_path + config.get("heart", "")) as Texture2D
	paper.texture = load(base_path + config.get("paper", "")) as Texture2D


func _load_text() -> void:
	var letter_data: Dictionary = DataLoader.texts.get("letter", {}) as Dictionary
	var content: String = letter_data.get("content", "")
	
	text_label.text = content


func _configure_scroll() -> void:
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	
	scroll.get_v_scroll_bar().visible = false


#func _on_close_pressed() -> void:
	#SceneLoader.goto_scene("res://scenes/screens/HugScreen.tscn")

func _update_paper_height() -> void:
	await get_tree().process_frame
	
	var text_height: float = text_label.get_content_height()
	
	var padding: float = 250
	
	paper.custom_minimum_size.y = text_height + padding

func _apply_ui_style() -> void:
	var ui: Dictionary = DataLoader.config.get("ui", {}) as Dictionary
	
	var font_rel: String = str(ui.get("font", ""))
	if font_rel != "":
		var font_path: String = DataLoader.resolve_client_path(font_rel)
		var font: FontFile = load(font_path) as FontFile
		if font:
			text_label.add_theme_font_override("normal_font", font)
	
	var letter_font_size: int = int(ui.get("button_font_size", 50))
	text_label.add_theme_font_size_override("normal_font_size", 55)

	text_label.add_theme_color_override(
		"default_color",
		Color(0.28, 0.20, 0.15)
	)
	text_label.bbcode_enabled = true
	text_label.add_theme_constant_override("line_separation", 25)

func _on_close_button_pressed() -> void:
	ProgressManager.reset_progress()
	
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 1.0)
	await t.finished
	
	SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")
