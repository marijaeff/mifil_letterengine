extends Control

@onready var scroll: ScrollContainer = $VBox/Control/ScrollContainer
@onready var paper: NinePatchRect = $VBox/Control/ScrollContainer/Paper
@onready var text_label: RichTextLabel = $VBox/Control/ScrollContainer/Paper/MarginContainer/TextLabel
@onready var close_button: Button = $VBox/Control/CloseButton
@onready var heart: TextureRect = $VBox/Control/Heart
@onready var text_margin: MarginContainer = $VBox/Control/ScrollContainer/Paper/MarginContainer

var _heart_tween: Tween
var _is_animating: bool = false
var _visible_chars: float = 0.0
var _typing_speed: float = 15.0
var _min_typing_speed: float = 15.0
var _end_reached: bool = false

var _auto_scroll: bool = true
var _auto_scroll_delay: float = 1.2
var _auto_scroll_timer: float = 0.0
var _resume_delay: float = 1.0
var _resume_timer: float = 0.0
var _touch_down: bool = false
var _button_shown: bool = false
var _paper_height: float = 0.0
var _paper_top_padding: float = 260.0
var _paper_bottom_padding: float = 250.0

func _ready() -> void:
	AudioManager.set_music_volume(0.04)
	AudioManager.play_music_by_key("final")

	if DataLoader.client_id.is_empty():
		DataLoader.load_client("vika")

	_apply_ui_style()
	await _load_text()
	_configure_scroll()
	_start_heart_pulse()
	_start_letter()

	close_button.pressed.connect(_on_close_pressed)

	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _apply_ui_style() -> void:
	var ui: Dictionary = DataLoader.config.get("ui", {})
	var font_rel: String = str(ui.get("font", ""))

	if font_rel != "":
		var font_path: String = DataLoader.resolve_client_path(font_rel)
		var font: FontFile = load(font_path) as FontFile
		if font:
			text_label.add_theme_font_override("normal_font", font)

	text_label.add_theme_font_size_override("normal_font_size", 55)
	text_label.add_theme_color_override("default_color", Color(0.28, 0.20, 0.15))
	text_label.add_theme_constant_override("line_separation", 25)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	var letter_cfg: Dictionary = DataLoader.config.get("screens", {}).get("letter", {})
	var close_btn_cfg: Dictionary = letter_cfg.get("close_button", {})

	close_button.text = str(close_btn_cfg.get("text", "..."))
	close_button.add_theme_font_size_override("font_size", int(ui.get("button_font_size", 50)))

	if font_rel != "":
		var close_font_path: String = DataLoader.resolve_client_path(font_rel)
		var close_font: FontFile = load(close_font_path) as FontFile
		if close_font:
			close_button.add_theme_font_override("font", close_font)

	var icon_rel: String = str(close_btn_cfg.get("icon", ""))
	if icon_rel != "":
		var icon_path: String = DataLoader.resolve_client_path(icon_rel)
		var icon_tex: Texture2D = load(icon_path) as Texture2D
		if icon_tex:
			close_button.icon = icon_tex
			close_button.expand_icon = true
		text_margin.add_theme_constant_override("margin_top", int(_paper_top_padding))
		text_margin.add_theme_constant_override("margin_bottom", 0)
		
func _load_text() -> void:
	var letter_data: Dictionary = DataLoader.texts.get("letter", {})
	text_label.text = str(letter_data.get("content", ""))

	text_label.visible_characters = -1
	await get_tree().process_frame

	_paper_height = text_label.get_content_height() + _paper_top_padding + 250.0
	paper.custom_minimum_size.y = _paper_height

	text_label.visible_characters = 0

func _configure_scroll() -> void:
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	var vbar: VScrollBar = scroll.get_v_scroll_bar()
	vbar.visible = false
	vbar.modulate.a = 0.0
	vbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbar.custom_minimum_size = Vector2.ZERO
	vbar.size = Vector2.ZERO
	vbar.scale = Vector2.ZERO

	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	scroll.gui_input.connect(_on_scroll_gui_input)

func _on_scroll_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		_touch_down = t.pressed

	elif event is InputEventScreenDrag:
		_auto_scroll = false
		_resume_timer = _resume_delay

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_auto_scroll = false
				_resume_timer = _resume_delay

func _start_heart_pulse() -> void:
	var base_scale: Vector2 = heart.scale

	_heart_tween = create_tween()
	_heart_tween.set_loops()
	_heart_tween.set_trans(Tween.TRANS_SINE)
	_heart_tween.set_ease(Tween.EASE_IN_OUT)
	_heart_tween.tween_property(heart, "scale", base_scale * 1.004, 1.2)
	_heart_tween.tween_property(heart, "scale", base_scale, 1.2)
	_heart_tween.tween_interval(1.4)

func _start_letter() -> void:
	close_button.visible = false
	await get_tree().create_timer(0.2).timeout

	if not OS.has_feature("web"):
		AudioManager.play_writing_loop(1, -10)

	_auto_scroll_timer = _auto_scroll_delay
	_is_animating = true
	set_process(true)

func _process(delta: float) -> void:
	var total: int = text_label.get_total_character_count()
	if total <= 0:
		return

	if _auto_scroll_timer > 0.0:
		_auto_scroll_timer -= delta

	if _resume_timer > 0.0:
		_resume_timer -= delta
		if _resume_timer <= 0.0 and not _touch_down:
			_auto_scroll = true

	if _is_animating:
		var progress: float = clamp(float(text_label.visible_characters) / float(total), 0.0, 1.0)

		var current_speed: float = lerp(_typing_speed, _min_typing_speed, progress)
		_visible_chars += current_speed * delta
		text_label.visible_characters = min(int(_visible_chars), total)

		if text_label.visible_characters >= total:
			text_label.visible_characters = total
			_is_animating = false
			_end_reached = true
			AudioManager.stop_writing_loop()

	var visual_scrollable: float = maxf(0.0, _paper_height - scroll.size.y)

	var vbar: VScrollBar = scroll.get_v_scroll_bar()
	var real_scrollable: float = maxf(0.0, vbar.max_value - vbar.page)

	var text_progress: float = 0.0
	if total > 0:
		text_progress = clamp(float(text_label.visible_characters) / float(total), 0.0, 1.0)

	var center_hold_offset: float = scroll.size.y * 0.32
	var target_scroll: float = visual_scrollable * text_progress - center_hold_offset
	target_scroll = clamp(target_scroll, 0.0, visual_scrollable)

	if _auto_scroll and _auto_scroll_timer <= 0.0 and not _touch_down and not _end_reached:
		scroll.scroll_vertical = int(round(lerpf(
			float(scroll.scroll_vertical),
			target_scroll,
			clamp(delta * 4.0, 0.0, 1.0)
		)))

	if _end_reached:
		var next_end: float = lerpf(
			float(scroll.scroll_vertical),
			real_scrollable,
			clamp(delta * 6.0, 0.0, 1.0)
		)
		scroll.scroll_vertical = int(round(next_end))

		if real_scrollable - float(scroll.scroll_vertical) <= 12.0:
			scroll.scroll_vertical = int(real_scrollable)

	if _end_reached and not _button_shown:
		if real_scrollable - float(scroll.scroll_vertical) <= 1.0:
			_button_shown = true
			_show_close_button()

	if _end_reached and _button_shown:
		if real_scrollable - float(scroll.scroll_vertical) <= 1.0:
			set_process(false)

func _show_close_button() -> void:
	close_button.visible = true
	close_button.modulate.a = 0.0

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(close_button, "modulate:a", 1.0, 1.2)

func _on_close_pressed() -> void:
	AudioManager.stop_writing_loop()
	AudioManager.play_sfx_by_key("whoosh", -12)
	await get_tree().process_frame
	SceneLoader.goto_scene("res://scenes/screens/HugScreen.tscn")
