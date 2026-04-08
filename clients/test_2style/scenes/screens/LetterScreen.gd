extends Control

@onready var background: TextureRect = $Background
@onready var scroll: ScrollContainer = $VBox/Control/ScrollContainer
@onready var paper: NinePatchRect = $VBox/Control/ScrollContainer/Paper
@onready var text_label: RichTextLabel = $VBox/Control/ScrollContainer/Paper/MarginContainer/TextLabel
@onready var close_button: Button = $VBox/Control/CloseButton
@onready var heart: TextureRect = $VBox/Control/Heart
@onready var text_margin: MarginContainer = $VBox/Control/ScrollContainer/Paper/MarginContainer

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

var _ios_scroll_only_mode: bool = false
var _ios_scroll_speed: float = 52.0

func _ready() -> void:
	AudioManager.set_music_volume(0.04)
	AudioManager.play_music_by_key("final")

	_apply_ui_style()
	_apply_letter_visuals()
	await _load_text()
	_configure_scroll()
	_start_letter()
	ProgressManager.last_screen = "letter"
	ProgressManager.last_level_id = 0
	ProgressManager.save_progress()
	close_button.pressed.connect(_on_close_pressed)

	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE


		
func _load_text() -> void:
	var letter_data: Dictionary = DataLoader.texts.get("letter", {})
	text_label.text = str(letter_data.get("content", ""))

	text_label.visible_characters = -1
	await get_tree().process_frame

	_paper_height = text_label.get_content_height() + _paper_top_padding + 250.0
	paper.custom_minimum_size.y = _paper_height

	text_label.visible_characters = 0

func _apply_ui_style() -> void:
	var ui: Dictionary = DataLoader.config.get("ui", {}) as Dictionary
	var letter_cfg: Dictionary = DataLoader.config.get("screens", {}).get("letter", {}) as Dictionary
	var close_btn_cfg: Dictionary = letter_cfg.get("close_button", {}) as Dictionary

	var font_rel: String = str(ui.get("font", ""))
	if font_rel != "":
		var font_path: String = DataLoader.resolve_client_path(font_rel)
		var font: FontFile = load(font_path) as FontFile
		if font:
			text_label.add_theme_font_override("normal_font", font)
			close_button.add_theme_font_override("font", font)

	var letter_font_size: int = int(letter_cfg.get("letter_font_size", 55))
	var letter_text_color: String = str(letter_cfg.get("letter_text_color", "#29241C"))

	text_label.add_theme_font_size_override("normal_font_size", letter_font_size)
	text_label.add_theme_color_override("default_color", Color(letter_text_color))
	text_label.add_theme_constant_override("line_separation", 25)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	close_button.text = str(close_btn_cfg.get("text", "..."))
	close_button.add_theme_font_size_override("font_size", int(ui.get("button_font_size", 50)))
	var button_text_color: Color = Color(str(ui.get("button_text_color", "#E8D7B4")))
	close_button.add_theme_color_override("font_color", button_text_color)

	var icon_rel: String = str(close_btn_cfg.get("icon", ""))
	if icon_rel != "":
		var icon_path: String = DataLoader.resolve_client_path(icon_rel)
		var icon_tex: Texture2D = load(icon_path) as Texture2D
		if icon_tex:
			close_button.icon = icon_tex
			close_button.expand_icon = true

	text_margin.add_theme_constant_override("margin_top", int(_paper_top_padding))
	text_margin.add_theme_constant_override("margin_bottom", 0)

func _apply_letter_visuals() -> void:
	var letter_cfg: Dictionary = DataLoader.config.get("screens", {}).get("letter", {}) as Dictionary

	var bg_rel: String = str(letter_cfg.get("background", ""))
	if bg_rel != "":
		var bg_path: String = DataLoader.resolve_client_path(bg_rel)
		var bg_tex: Texture2D = load(bg_path) as Texture2D
		if bg_tex:
			background.texture = bg_tex

	var paper_rel: String = str(letter_cfg.get("paper", ""))
	if paper_rel != "":
		var paper_path: String = DataLoader.resolve_client_path(paper_rel)
		var paper_tex: Texture2D = load(paper_path) as Texture2D
		if paper_tex:
			paper.texture = paper_tex

	var heart_rel: String = str(letter_cfg.get("heart", ""))
	if heart_rel != "":
		var heart_path: String = DataLoader.resolve_client_path(heart_rel)
		var heart_tex: Texture2D = load(heart_path) as Texture2D
		if heart_tex:
			heart.texture = heart_tex

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

		if t.pressed:
			_auto_scroll = false

		_resume_timer = _resume_delay

		if PlatformManager.is_ios_web() and not t.pressed:
			call_deferred("_check_ios_bottom_reached")

	elif event is InputEventScreenDrag:
		_auto_scroll = false
		_resume_timer = _resume_delay

		if PlatformManager.is_ios_web():
			call_deferred("_check_ios_bottom_reached")

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_auto_scroll = false
				_resume_timer = _resume_delay


func _start_letter() -> void:
	close_button.visible = false
	_button_shown = false
	_end_reached = false
	_auto_scroll = true
	_resume_timer = 0.0
	_auto_scroll_timer = _auto_scroll_delay
	_touch_down = false

	if PlatformManager.is_ios_web():
		_ios_scroll_only_mode = true
		text_label.visible_characters = -1
		_visible_chars = float(text_label.get_total_character_count())
		_is_animating = false
		set_process(true)
	else:
		_ios_scroll_only_mode = false
		text_label.visible_characters = 0
		_visible_chars = 0.0
		_is_animating = true
		set_process(true)

func _process_ios_scroll_only(delta: float, real_scrollable: float) -> void:
	if _auto_scroll and _auto_scroll_timer <= 0.0 and not _touch_down and not _end_reached:
		var next_scroll: float = float(scroll.scroll_vertical) + _ios_scroll_speed * delta
		scroll.scroll_vertical = int(round(min(next_scroll, real_scrollable)))

	if real_scrollable - float(scroll.scroll_vertical) <= 1.0:
		scroll.scroll_vertical = int(real_scrollable)
		_end_reached = true

	if _end_reached and not _button_shown:
		_button_shown = true
		_show_close_button()

	if _end_reached and _button_shown:
		set_process(false)

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

	var vbar: VScrollBar = scroll.get_v_scroll_bar()
	var real_scrollable: float = maxf(0.0, vbar.max_value - vbar.page)

	if _ios_scroll_only_mode:
		_process_ios_scroll_only(delta, real_scrollable)
		return

	if _is_animating:
		var progress: float = clamp(float(text_label.visible_characters) / float(total), 0.0, 1.0)

		var current_speed: float = lerp(_typing_speed, _min_typing_speed, progress)
		_visible_chars += current_speed * delta
		text_label.visible_characters = min(int(_visible_chars), total)

	if text_label.visible_characters >= total:
		text_label.visible_characters = total
		_is_animating = false
		_end_reached = true

	var visual_scrollable: float = maxf(0.0, _paper_height - scroll.size.y)

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

func _check_ios_bottom_reached() -> void:
	if not PlatformManager.is_ios_web():
		return

	var vbar: VScrollBar = scroll.get_v_scroll_bar()
	var real_scrollable: float = maxf(0.0, vbar.max_value - vbar.page)

	if real_scrollable - float(scroll.scroll_vertical) <= 1.0 and not _button_shown:
		_button_shown = true
		_show_close_button()

func _show_close_button() -> void:
	close_button.visible = true
	close_button.modulate.a = 0.0

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(close_button, "modulate:a", 1.0, 1.2)

func _on_close_pressed() -> void:
	AudioManager.play_sfx_by_key("whoosh", -12)

	ProgressManager.last_screen = "hug"
	ProgressManager.last_level_id = 0
	ProgressManager.save_progress()

	await get_tree().process_frame
	SceneLoader.goto_scene(DataLoader.resolve_scene_path("screens/HugScreen.tscn"))
