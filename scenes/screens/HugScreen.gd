extends Control

@onready var duo: Sprite2D = $Characters/Duo
@onready var heart: Sprite2D = $Heart
@onready var buttons: Control = $ButtonsContainer
@onready var download_button: Button = $ButtonsContainer/DownloadButton
@onready var map_button: Button = $ButtonsContainer/MapButton
@onready var finish_button: Button = $ButtonsContainer/FinishButton


var tex_hug: Texture2D
var tex_heart: Texture2D

var center_position: Vector2


func _ready() -> void:
	_load_textures()
	center_position = get_viewport_rect().size / 2.0
	_prepare_scene()
	_setup_buttons()

	await _frame_hug()
	await _finish_sequence()


func _load_textures() -> void:
	tex_hug = load("res://clients/vika/assets/characters/hug.png")
	tex_heart = load("res://clients/vika/assets/objects/heart_hug.png")


func _prepare_scene() -> void:
	heart.texture = tex_heart

	duo.texture = tex_hug
	duo.global_position = center_position
	duo.visible = true
	duo.modulate.a = 0.0

	heart.modulate.a = 0.0
	buttons.modulate.a = 0.0
	heart.global_position = center_position + Vector2(0, -400)
	heart.scale = Vector2(1.6, 1.6)
	
func _setup_buttons() -> void:
	var ui_cfg: Dictionary = DataLoader.config.get("ui", {})
	var hug_cfg: Dictionary = DataLoader.config.get("screens", {}).get("hug", {})
	var buttons_cfg: Dictionary = hug_cfg.get("buttons", {})

	var font_rel: String = str(ui_cfg.get("font", ""))
	var font: FontFile = null
	if font_rel != "":
		var font_path: String = DataLoader.resolve_client_path(font_rel)
		font = load(font_path) as FontFile

	var button_font_size: int = int(ui_cfg.get("button_font_size", 50))

	for b in [download_button, map_button, finish_button]:
		if font:
			b.add_theme_font_override("font", font)
		b.add_theme_font_size_override("font_size", button_font_size)

	download_button.text = str(buttons_cfg.get("save", {}).get("text", "Сохранить"))
	map_button.text = str(buttons_cfg.get("map", {}).get("text", "На карту"))
	finish_button.text = str(buttons_cfg.get("finish", {}).get("text", "Завершить"))

	download_button.pressed.connect(_on_download_pressed)
	map_button.pressed.connect(_on_map_pressed)
	finish_button.pressed.connect(_on_finish_pressed)

func _on_download_pressed() -> void:

	var hug_cfg: Dictionary = DataLoader.config.get("screens", {}).get("hug", {})
	var pdf_rel: String = str(hug_cfg.get("pdf", ""))

	if pdf_rel == "":
		push_error("HugScreen: pdf path not set in config")
		return

	var pdf_path: String = DataLoader.resolve_client_path(pdf_rel)
	var file := FileAccess.open(pdf_path, FileAccess.READ)

	if file == null:
		push_error("HugScreen: failed to open pdf: " + pdf_path)
		return

	var bytes: PackedByteArray = file.get_buffer(file.get_length())
	file.close()

	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(bytes, "letter.pdf", "application/pdf")
	else:
		var out := FileAccess.open("user://letter.pdf", FileAccess.WRITE)
		if out == null:
			push_error("HugScreen: failed to save local pdf")
			return
		out.store_buffer(bytes)
		out.close()


func _on_map_pressed() -> void:
	AudioManager.play_sfx_by_key("whoosh", -12)
	SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")


func _on_finish_pressed() -> void:
	AudioManager.play_sfx_by_key("whoosh", -12)

	ProgressManager.reset_progress()

	await get_tree().process_frame

	SceneLoader.goto_scene("res://scenes/screens/HeartScreen.tscn")

func _start_heart_pulse() -> void:
	heart.scale = Vector2(1.4, 1.4)

	var t := create_tween()
	t.set_loops()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(heart, "scale", Vector2(1.45, 1.45), 3.0)
	t.tween_property(heart, "scale", Vector2(1.4, 1.4), 3.0)
	
func _pause(time: float) -> void:
	await get_tree().create_timer(time).timeout

func _frame_hug() -> void:
	duo.texture = tex_hug
	duo.global_position = center_position
	duo.visible = true
	duo.modulate.a = 0.0

	var fade_in := create_tween()
	fade_in.set_trans(Tween.TRANS_SINE)
	fade_in.set_ease(Tween.EASE_IN_OUT)
	fade_in.tween_property(duo, "modulate:a", 1.0, 2.4)
	await fade_in.finished

	await _pause(0.5)

	_start_heart_pulse()

	var heart_fade := create_tween()
	heart_fade.set_trans(Tween.TRANS_SINE)
	heart_fade.set_ease(Tween.EASE_IN_OUT)
	heart_fade.tween_property(heart, "modulate:a", 0.85, 2.0)

	await _pause(1.2)


func _finish_sequence() -> void:
	var fade_in := create_tween()
	fade_in.set_trans(Tween.TRANS_SINE)
	fade_in.set_ease(Tween.EASE_IN_OUT)
	fade_in.tween_property(heart, "modulate:a", 0.85, 3.5)
	await fade_in.finished

	var buttons_tween := create_tween()
	buttons_tween.set_trans(Tween.TRANS_SINE)
	buttons_tween.set_ease(Tween.EASE_IN_OUT)
	buttons_tween.tween_property(buttons, "modulate:a", 1.0, 3.0)
