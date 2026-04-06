extends Control

@onready var background: TextureRect = $Background
@onready var duo: Sprite2D = $Characters/Duo
@onready var heart: Sprite2D = $Heart
@onready var buttons: Control = $ButtonsContainer
@onready var download_button: Button = $ButtonsContainer/DownloadButton
@onready var map_button: Button = $ButtonsContainer/MapButton
@onready var finish_button: Button = $ButtonsContainer/FinishButton


var tex_hug: Texture2D
var tex_heart: Texture2D

var center_position: Vector2
var heart_base_scale: Vector2 = Vector2(0.6, 0.6)
var heart_pulse_scale: Vector2 = Vector2(0.65, 0.65)


func _ready() -> void:
	_apply_visuals()
	_load_textures()
	center_position = get_viewport_rect().size / 2.0
	_prepare_scene()
	_setup_buttons()
	
	ProgressManager.last_screen = "hug"
	ProgressManager.last_level_id = 0
	ProgressManager.save_progress()
	
	await _frame_hug()
	await _finish_sequence()


func _load_textures() -> void:
	var hug_cfg: Dictionary = DataLoader.config.get("screens", {}).get("hug", {}) as Dictionary

	var duo_rel: String = str(hug_cfg.get("duo", "assets/characters/hug.png"))
	var heart_rel: String = str(hug_cfg.get("heart", "assets/objects/heart_hug.png"))

	tex_hug = load(DataLoader.resolve_client_path(duo_rel)) as Texture2D
	tex_heart = load(DataLoader.resolve_client_path(heart_rel)) as Texture2D


func _prepare_scene() -> void:
	heart.texture = tex_heart

	duo.texture = tex_hug
	duo.global_position = center_position
	duo.visible = true
	duo.modulate.a = 0.0

	heart.modulate.a = 0.0
	buttons.modulate.a = 0.0
	heart.global_position = center_position + Vector2(0, -500)
	heart.scale = heart_base_scale

func _apply_visuals() -> void:
	var hug_cfg: Dictionary = DataLoader.config.get("screens", {}).get("hug", {}) as Dictionary

	var bg_rel: String = str(hug_cfg.get("background", ""))
	if bg_rel != "":
		var bg_path: String = DataLoader.resolve_client_path(bg_rel)
		var bg_tex: Texture2D = load(bg_path) as Texture2D
		if bg_tex:
			background.texture = bg_tex

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

	var button_text_color: Color = Color(str(ui_cfg.get("button_text_color", "#E8D7B4")))

	for b in [download_button, map_button, finish_button]:
		if font:
			b.add_theme_font_override("font", font)
		b.add_theme_font_size_override("font_size", button_font_size)
		b.add_theme_color_override("font_color", button_text_color)

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

	if not FileAccess.file_exists(pdf_path):
		pdf_path = "res://clients/vika/assets/files/letter.pdf"

	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(pdf_path)

	if bytes.is_empty():
		push_error("HugScreen: failed to read pdf bytes: " + pdf_path)
		return

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
	heart.scale = heart_base_scale

	var t := create_tween()
	t.set_loops()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(heart, "scale", heart_pulse_scale, 3.0)
	t.tween_property(heart, "scale", heart_base_scale, 3.0)
	
func _pause(time: float) -> void:
	await get_tree().create_timer(time).timeout

func _frame_hug() -> void:
	duo.texture = tex_hug
	duo.global_position = center_position + Vector2(0, -25)
	duo.scale = Vector2(1, 1)
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
