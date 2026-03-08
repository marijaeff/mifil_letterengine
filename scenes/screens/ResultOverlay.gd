extends Control

signal retry_pressed
signal next_pressed


@onready var fade: ColorRect = $DarkFade

@onready var panel: TextureRect = $CenterContainer/Panel
@onready var title: Label = $CenterContainer/Panel/Content/Title
@onready var subtitle: Label = $CenterContainer/Panel/Content/Subtitle
@onready var icon: TextureRect = $CenterContainer/Panel/Content/Icon

@onready var retry_btn: Button = $CenterContainer/Panel/Content/RetryBtn
@onready var next_btn: Button = $CenterContainer/Panel/Content/NextBtn

func _ready():

	retry_btn.pressed.connect(_on_retry_pressed)
	next_btn.pressed.connect(_on_next_pressed)

func _on_retry_pressed():

	AudioManager.play_sfx_by_key("whoosh", -12)  

	await get_tree().process_frame

	retry_pressed.emit()


func _on_next_pressed():

	AudioManager.play_sfx_by_key("whoosh", -12)  

	await get_tree().process_frame

	next_pressed.emit()

func show_from_config(type: String) -> void:

	var root_cfg: Dictionary = DataLoader.config.get("levels", {}).get("result", {})
	var cfg: Dictionary = root_cfg.get(type, {})
	var common: Dictionary = root_cfg.get("common", {})

	if cfg.is_empty():
		push_error("ResultOverlay: config not found for " + type)
		return

	title.text = cfg.get("title", "")
	subtitle.text = cfg.get("subtitle", "")

	var envelopes: Array = common.get("envelopes", [])

	var stage: int = ProgressManager.get_envelope_stage()

	stage = clamp(stage, 0, envelopes.size() - 1)

	icon.texture = load(DataLoader.resolve_client_path(envelopes[stage]))

	var icon_size: Array = common.get("icon_size", [220,160])
	icon.custom_minimum_size = Vector2(icon_size[0], icon_size[1])

	panel.texture = load(DataLoader.resolve_client_path(cfg.get("panel", "")))

	var buttons: Dictionary = cfg.get("buttons", {})

	setup_button(retry_btn, buttons.get("retry", {}))

	if buttons.has("next"):
		setup_button(next_btn, buttons.get("next", {}))
		next_btn.visible = true
	else:
		next_btn.visible = false

	apply_fonts(cfg, common)
	apply_colors(cfg)

	show()
	animate_in(common)

func setup_button(btn: Button, data: Dictionary) -> void:

	btn.text = data.get("text", "")

	var icon_path: String = data.get("icon", "")
	if icon_path != "":
		btn.icon = load(DataLoader.resolve_client_path(icon_path))

	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER

	btn.expand_icon = false

	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func apply_fonts(_cfg: Dictionary, common: Dictionary):

	var ui_cfg: Dictionary = DataLoader.config.get("ui", {})
	var font: FontFile = load(DataLoader.resolve_client_path(ui_cfg.get("font", "")))

	var fonts: Dictionary = common.get("fonts", {})

	title.add_theme_font_override("font", font)
	subtitle.add_theme_font_override("font", font)
	retry_btn.add_theme_font_override("font", font)
	next_btn.add_theme_font_override("font", font)

	title.add_theme_font_size_override("font_size", fonts.get("title_size", 100))
	subtitle.add_theme_font_size_override("font_size", fonts.get("subtitle_size", 50))
	retry_btn.add_theme_font_size_override("font_size", fonts.get("button_size", 50))
	next_btn.add_theme_font_size_override("font_size", fonts.get("button_size", 50))


func apply_colors(cfg: Dictionary):

	var colors: Dictionary = cfg.get("colors", {})

	title.add_theme_color_override("font_color", Color(colors.get("title", "#fff")))
	subtitle.add_theme_color_override("font_color", Color(colors.get("subtitle", "#fff")))

	var btn_color := Color(colors.get("buttons", "#fff"))

	retry_btn.add_theme_color_override("font_color", btn_color)
	next_btn.add_theme_color_override("font_color", btn_color)

func animate_in(common: Dictionary):

	modulate.a = 0
	fade.modulate.a = 0

	var scale_val: float = common.get("panel_scale", 0.92)
	$CenterContainer.scale = Vector2(scale_val, scale_val)

	var t := create_tween()

	t.tween_property(fade, "modulate:a", 0.55, 0.25)
	t.parallel().tween_property(self, "modulate:a", 1.0, 0.25)
	t.parallel().tween_property($CenterContainer, "scale", Vector2.ONE, 0.28)
