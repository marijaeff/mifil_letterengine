extends Control

@onready var background = $Background
@onready var label = $SafeArea/MainLayout/TextBlock/Label

@onready var rope = $SafeArea/MainLayout/TopDecoration/Rope
@onready var ground = $SafeArea/MainLayout/BottomWorld/Ground

@onready var girl = $SafeArea/MainLayout/BottomWorld/Girl
@onready var baby = $SafeArea/MainLayout/BottomWorld/Baby
@onready var cat = $SafeArea/MainLayout/BottomWorld/Cat

@onready var buttons = $SafeArea/MainLayout/BottomWorld/Buttons
@onready var button_yes = $SafeArea/MainLayout/BottomWorld/Buttons/ButtonYes
@onready var button_no = $SafeArea/MainLayout/BottomWorld/Buttons/ButtonNo

var config
var transitioning := false
var _no_button_tween: Tween
var _no_escape_margin: float = 40.0

# --------------------------------------------------
func _ready():

	AudioManager.set_music_volume(0.25)  
	AudioManager.play_music_by_key("map") 

	config = DataLoader.config["screens"]["intro"]
	
	apply_individual_button_styles()
	load_content()
	setup_initial_state()
	
	await type_text()
	await show_buttons()


# --------------------------------------------------
func load_content():
	var base_path = "res://clients/%s/" % DataLoader.client_id

	background.texture = load(base_path + config["background"])

	label.text = DataLoader.texts["intro"]["text"]



	rope.texture = load(base_path + config["decor"]["top_line"])
	ground.texture = load(base_path + config["decor"]["ground"])

	girl.texture = load(base_path + config["characters"]["girl"])
	baby.texture = load(base_path + config["characters"]["baby"])
	cat.texture = load(base_path + config["characters"]["cat"])
	
	button_yes.text = DataLoader.texts["intro"]["buttons"]["yes"]
	button_no.text = DataLoader.texts["intro"]["buttons"]["no"]
	
	button_yes.icon = load(base_path + config["buttons"]["yes"]["outline"])
	button_no.icon = load(base_path + config["buttons"]["no"]["outline"])
	
	apply_colors_from_config()

func setup_initial_state():
	label.visible_characters = 0
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	button_yes.modulate.a = 0.0
	button_no.modulate.a = 0.0
	
	button_yes.visible = false
	button_no.visible = false

func type_text():
	var total_chars = label.text.length()
	
	for i in total_chars:
		label.visible_characters = i + 1
		await get_tree().create_timer(0.04).timeout
	
	await get_tree().create_timer(0.2).timeout
	

func show_buttons():
	await get_tree().create_timer(0.2).timeout

	button_yes.visible = true
	
	var tween_yes = create_tween()
	tween_yes.tween_property(button_yes, "modulate:a", 1.0, 0.6)
	await tween_yes.finished
	
	await get_tree().create_timer(0.2).timeout
	
	button_no.visible = true
	
	await get_tree().process_frame  
	apply_transforms_from_config()  
	
	var tween_no = create_tween()
	tween_no.tween_property(button_no, "modulate:a", 1.0, 0.6)
	await tween_no.finished
	
	connect_buttons()

func connect_buttons():
	button_yes.pressed.connect(_on_yes_pressed)
	button_no.pressed.connect(_on_no_pressed)

func _on_yes_pressed():
	if transitioning:
		return
	
	transitioning = true
	AudioManager.play_sfx_by_key("whoosh", -12)
	await get_tree().process_frame
	SceneLoader.goto_scene("res://scenes/screens/EnvelopeScreen.tscn")


func _on_no_pressed() -> void:
	_move_no_button_somewhere_else()

func _move_no_button_somewhere_else() -> void:
	if _no_button_tween:
		_no_button_tween.kill()

	var parent_control := button_no.get_parent() as Control
	if parent_control == null:
		return

	var area_size: Vector2 = parent_control.size
	var btn_size: Vector2 = button_no.size
	var yes_size: Vector2 = button_yes.size

	if btn_size == Vector2.ZERO:
		btn_size = button_no.get_combined_minimum_size()

	if yes_size == Vector2.ZERO:
		yes_size = button_yes.get_combined_minimum_size()

	var min_x: float = _no_escape_margin
	var min_y: float = _no_escape_margin
	var max_x: float = max(min_x, area_size.x - btn_size.x - _no_escape_margin)
	var max_y: float = max(min_y, area_size.y - btn_size.y - _no_escape_margin)

	var padding: float = 20.0
	var yes_rect := Rect2(
		button_yes.position - Vector2(padding, padding),
		yes_size + Vector2(padding * 2.0, padding * 2.0)
	)

	var new_pos: Vector2 = button_no.position
	var attempts: int = 0

	while attempts < 30:
		new_pos = Vector2(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y)
		)

		var no_rect := Rect2(new_pos, btn_size)

		var far_enough: bool = button_no.position.distance_to(new_pos) >= 140.0
		var not_overlapping_yes: bool = not no_rect.intersects(yes_rect)

		if far_enough and not_overlapping_yes:
			break

		attempts += 1

	_no_button_tween = create_tween()
	_no_button_tween.set_trans(Tween.TRANS_BACK)
	_no_button_tween.set_ease(Tween.EASE_OUT)
	_no_button_tween.tween_property(button_no, "position", new_pos, 0.35)


func _color_from_config(value, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		var s := (value as String).strip_edges()
		if s == "":
			return fallback
		if not s.begins_with("#"):
			s = "#" + s
		return Color.html(s)
	return fallback


func apply_colors_from_config():
	if not config.has("colors"):
		return

	var colors: Dictionary = config["colors"]

	if colors.has("text"):
		label.add_theme_color_override("font_color", _color_from_config(colors["text"], Color.WHITE))

	if colors.has("button_yes"):
		button_yes.add_theme_color_override("font_color", _color_from_config(colors["button_yes"], Color.WHITE))

	if colors.has("button_no"):
		button_no.add_theme_color_override("font_color", _color_from_config(colors["button_no"], Color.WHITE))


func apply_transforms_from_config():
	if config.has("button_no_rotation"):
		button_no.pivot_offset = button_no.size * 0.5
		button_no.rotation_degrees = float(config["button_no_rotation"])

func apply_individual_button_styles():
	var ui = DataLoader.config.get("ui", {})
	
	if ui.has("button_no_font_size"):
		button_no.add_theme_font_size_override(
			"font_size",
			ui["button_no_font_size"]
		)
