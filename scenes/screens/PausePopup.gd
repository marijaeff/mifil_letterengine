extends Control

signal resume_pressed
signal restart_pressed
signal map_pressed


# ---------------------------------------------------
# NODES
# ---------------------------------------------------

@onready var fade: ColorRect = $DarkFade

# --- pause panel
@onready var panel: TextureRect = $CenterContainer/Panel
@onready var title: Label = $CenterContainer/Panel/Content/Title
@onready var icon: TextureRect = $CenterContainer/Panel/Content/Icon

@onready var resume_btn: Button = $CenterContainer/Panel/Content/Btn_1
@onready var restart_btn: Button = $CenterContainer/Panel/Content/Btn_2
@onready var settings_btn: Button = $CenterContainer/Panel/Content/Btn_3
@onready var map_btn: Button = $CenterContainer/Panel/Content/Btn_4

# --- settings panel
@onready var settings_panel: TextureRect = $CenterContainer/SettingsPanel
@onready var settings_title: Label = $CenterContainer/SettingsPanel/Content/Title

@onready var sound_label: Label = $CenterContainer/SettingsPanel/Content/SoundRow/Label
@onready var music_label: Label = $CenterContainer/SettingsPanel/Content/MusicRow/Label

@onready var sound_toggle: TextureButton = $CenterContainer/SettingsPanel/Content/SoundRow/CheckButton
@onready var music_toggle: TextureButton = $CenterContainer/SettingsPanel/Content/MusicRow/CheckButton

@onready var reset_btn_settings: Button = $CenterContainer/SettingsPanel/Content/Btn_3
@onready var back_btn_settings: Button = $CenterContainer/SettingsPanel/Content/Btn_4


var toggle_off_tex: Texture2D
var toggle_on_tex: Texture2D

# ---------------------------------------------------
# READY
# ---------------------------------------------------

func _ready():
	settings_panel.visible = false
	panel.visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	connect_buttons()

	back_btn_settings.pressed.connect(_on_settings_back)
	reset_btn_settings.pressed.connect(_on_reset_pressed)

	_load_toggle_textures()
	_setup_toggle(sound_toggle)
	_setup_toggle(music_toggle)

	sound_toggle.pressed.connect(_on_sound_toggle_pressed)
	music_toggle.pressed.connect(_on_music_toggle_pressed)
	
	sound_toggle.button_pressed = AudioManager.sfx_enabled
	music_toggle.button_pressed = AudioManager.music_enabled

	_update_toggle_visual(sound_toggle)
	_update_toggle_visual(music_toggle)

# ---------------------------------------------------
# PAUSE CONFIG
# ---------------------------------------------------

func _load_toggle_textures() -> void:
	toggle_off_tex = load("res://clients/vika/assets/ui/stick_off.png")
	toggle_on_tex = load("res://clients/vika/assets/ui/stick_on.png")


func _setup_toggle(btn: TextureButton) -> void:
	btn.toggle_mode = true
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.custom_minimum_size = Vector2(90, 46)
	btn.focus_mode = Control.FOCUS_NONE


func _update_toggle_visual(btn: TextureButton) -> void:
	if btn.button_pressed:
		btn.texture_normal = toggle_on_tex
	else:
		btn.texture_normal = toggle_off_tex

	btn.texture_pressed = btn.texture_normal
	btn.texture_hover = btn.texture_normal
	btn.texture_disabled = btn.texture_normal

func _on_sound_toggle_pressed() -> void:
	AudioManager.set_sfx_enabled(sound_toggle.button_pressed)
	_update_toggle_visual(sound_toggle)


func _on_music_toggle_pressed() -> void:
	AudioManager.set_music_enabled(music_toggle.button_pressed)
	_update_toggle_visual(music_toggle)

func show_from_config() -> void:

	if DataLoader.client_id.is_empty():
		DataLoader.load_client("vika")

	var cfg: Dictionary = DataLoader.config.get("levels", {}).get("pause", {})
	if cfg.is_empty():
		push_error("Pause config not found")
		return

	settings_panel.visible = false
	panel.visible = true

	title.text = cfg.get("title", "")

	var panel_path: String = cfg.get("panel", "")
	if panel_path != "":
		panel.texture = load(DataLoader.resolve_client_path(panel_path))

	var icon_path: String = cfg.get("icon", "")
	if icon_path != "":
		icon.texture = load(DataLoader.resolve_client_path(icon_path))

	var btn_cfg: Dictionary = cfg.get("buttons", {})

	resume_btn.text = btn_cfg.get("resume", {}).get("text", "")
	restart_btn.text = btn_cfg.get("restart", {}).get("text", "")
	settings_btn.text = btn_cfg.get("settings", {}).get("text", "")
	map_btn.text = btn_cfg.get("map", {}).get("text", "")

	apply_pause_styles(cfg)

	show()
	animate_in()


# ---------------------------------------------------
# SETTINGS CONFIG
# ---------------------------------------------------

func show_settings_from_config() -> void:

	var cfg: Dictionary = DataLoader.config.get("levels", {}).get("settings", {})
	if cfg.is_empty():
		push_error("Settings config not found")
		return

	panel.visible = false
	settings_panel.visible = true

	settings_title.text = cfg.get("title", "")

	var panel_path: String = cfg.get("panel", "")
	if panel_path != "":
		settings_panel.texture = load(DataLoader.resolve_client_path(panel_path))

	var labels: Dictionary = cfg.get("labels", {})
	sound_label.text = labels.get("sound", "")
	music_label.text = labels.get("music", "")

	var btn_cfg: Dictionary = cfg.get("buttons", {})
	reset_btn_settings.text = btn_cfg.get("reset", {}).get("text", "")
	back_btn_settings.text = btn_cfg.get("back", {}).get("text", "")

	apply_settings_styles(cfg)


# ---------------------------------------------------
# STYLES
# ---------------------------------------------------

func apply_pause_styles(cfg: Dictionary) -> void:

	var ui_cfg: Dictionary = DataLoader.config.get("ui", {})
	var font: FontFile = load(DataLoader.resolve_client_path(ui_cfg.get("font", "")))

	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", ui_cfg.get("font_size", 80))

	for b in [resume_btn, restart_btn, settings_btn, map_btn]:
		b.add_theme_font_override("font", font)
		b.add_theme_font_size_override("font_size", ui_cfg.get("button_font_size", 50))

	var colors: Dictionary = cfg.get("colors", {})

	title.add_theme_color_override("font_color", Color(colors.get("title","#fff")))

	var btn_color: Color = Color(colors.get("buttons","#fff"))
	for b in [resume_btn, restart_btn, settings_btn, map_btn]:
		b.add_theme_color_override("font_color", btn_color)


func apply_settings_styles(cfg: Dictionary) -> void:

	var ui_cfg: Dictionary = DataLoader.config.get("ui", {})
	var font: FontFile = load(DataLoader.resolve_client_path(ui_cfg.get("font", "")))

	settings_title.add_theme_font_override("font", font)
	settings_title.add_theme_font_size_override("font_size", ui_cfg.get("font_size", 80))

	for b in [reset_btn_settings, back_btn_settings]:
		b.add_theme_font_override("font", font)
		b.add_theme_font_size_override("font_size", ui_cfg.get("button_font_size", 50))

	for l in [sound_label, music_label]:
		l.add_theme_font_override("font", font)
		l.add_theme_font_size_override("font_size", 42)

	var colors: Dictionary = cfg.get("colors", {})

	settings_title.add_theme_color_override("font_color", Color(colors.get("title","#fff")))

	var btn_color: Color = Color(colors.get("buttons","#fff"))
	for b in [reset_btn_settings, back_btn_settings]:
		b.add_theme_color_override("font_color", btn_color)

	var label_color: Color = Color(colors.get("labels","#fff"))
	for l in [sound_label, music_label]:
		l.add_theme_color_override("font_color", label_color)


# ---------------------------------------------------
# BUTTONS
# ---------------------------------------------------

func connect_buttons() -> void:

	for b in [resume_btn, restart_btn, settings_btn, map_btn]:
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	map_btn.pressed.connect(_on_map_pressed)


func _on_resume_pressed() -> void:
	resume_pressed.emit()


func _on_restart_pressed() -> void:
	restart_pressed.emit()


func _on_map_pressed() -> void:
	map_pressed.emit()


func _on_settings_pressed() -> void:
	show_settings_from_config()


func _on_settings_back() -> void:
	settings_panel.visible = false
	panel.visible = true


func _on_reset_pressed():

	get_tree().paused = false

	ProgressManager.reset_progress()

	await get_tree().process_frame

	SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")


# ---------------------------------------------------
# ANIMATION
# ---------------------------------------------------

func animate_in() -> void:

	modulate.a = 0
	fade.modulate.a = 0

	$CenterContainer.scale = Vector2(0.92, 0.92)

	var t := create_tween()

	t.tween_property(fade, "modulate:a", 0.55, 0.25)
	t.parallel().tween_property(self, "modulate:a", 1.0, 0.25)
	t.parallel().tween_property($CenterContainer, "scale", Vector2.ONE, 0.28)


# ---------------------------------------------------
# TOGGLE STYLE
# ---------------------------------------------------

func style_toggle(btn: CheckButton) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = ""

	btn.custom_minimum_size = Vector2(120, 70)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END

	btn.toggle_mode = true
	btn.flat = true

	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.expand_icon = true

	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover_pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
