extends BaseLevelUI

@export var result_overlay_scene: PackedScene

@onready var bg: TextureRect = $BackgroundLayer/Background

@onready var question_label: Label = $GameLayer/QuestionLabel

@onready var box1: TextureButton = $BoxesContainer/Box1
@onready var box2: TextureButton = $BoxesContainer/Box2
@onready var box3: TextureButton = $BoxesContainer/Box3
@onready var table: TextureRect = $BoxesContainer/Table

@onready var reveal_layer: CanvasLayer = $RevealLayer
@onready var reveal_box: TextureRect = $RevealLayer/RevealBox

@onready var hearts_container: HBoxContainer = $UI/HeartsContainer
@onready var pause_btn: TextureButton = $UI/PauseButton


var questions: Array = []
var current_question: Dictionary

var correct_index: int = 0
var waiting_next_tap: bool = false

var hearts_max: int = 3
var current_hearts: int = 3
var heart_icon: Texture2D

var is_game_over := false

var box_closed: Texture2D
var box_open_empty: Texture2D
var box_open_letter: Texture2D

var rounds: Array = []
var current_round := 0
var rounds_total := 0

var level_completed_once := false

func _ready():

	if DataLoader.client_id.is_empty():
		DataLoader.load_client("vika")

	var current_id: int = ProgressManager.selected_level
	var def: Dictionary = LevelRouter.get_level_def(current_id)

	if def.is_empty():
		push_error("Level def not found")
		return

	setup(def)  

	var config: Dictionary = DataLoader.config
	var levels_block: Dictionary = config.get("levels", {})

	var shared_def: Dictionary = levels_block.get("shared", {})
	var intuition_def: Dictionary = levels_block.get("intuition", {})

	load_shared_ui(shared_def)
	load_visuals(intuition_def)

	connect_buttons()
	apply_question_style()

	start_round()

func load_shared_ui(def: Dictionary) -> void:

	var base_path := "res://clients/%s/" % DataLoader.client_id

	var hearts_def: Dictionary = def.get("hearts", {})
	hearts_max = int(hearts_def.get("max", 3))

	var heart_path: String = hearts_def.get("icon", "")
	if heart_path != "":
		heart_icon = load(base_path + heart_path)

	create_hearts()

	var pause_path: String = def.get("pause_icon", "")
	if pause_path != "":
		pause_btn.texture_normal = load(base_path + pause_path)


func load_visuals(def: Dictionary) -> void:

	var base_path := "res://clients/%s/" % DataLoader.client_id

	var bg_path: String = def.get("background", "")
	if bg_path != "":
		bg.texture = load(base_path + bg_path)

	questions = def.get("questions", [])
	
	rounds = def.get("rounds", [])
	rounds_total = def.get("rounds_total", rounds.size())

	box_closed = load(base_path + def.get("box_closed"))
	box_open_empty = load(base_path + def.get("box_empty"))
	box_open_letter = load(base_path + def.get("box_letter"))
	
	var table_path: String = def.get("table", "")
	if table_path != "":
		table.texture = load(base_path + table_path)

	setup_boxes()


func apply_question_style():

	var cfg: Dictionary = DataLoader.config.get("levels", {}).get("intuition", {})
	var style: Dictionary = cfg.get("question_style", {})

	var ui_cfg: Dictionary = DataLoader.config.get("ui", {})
	var base := "res://clients/%s/" % DataLoader.client_id

	var font_path: String = ui_cfg.get("font", "")
	if font_path != "":
		var font: FontFile = load(base + font_path)
		question_label.add_theme_font_override("font", font)

	question_label.add_theme_color_override("font_color", Color(style.get("color", "#B9A98B")))
	question_label.add_theme_font_size_override("font_size", style.get("size", 70))

func create_hearts():

	for c in hearts_container.get_children():
		c.queue_free()

	for i in range(hearts_max):
		var heart := TextureRect.new()
		heart.texture = heart_icon
		heart.custom_minimum_size = Vector2(64,64)
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts_container.add_child(heart)

	current_hearts = hearts_max


func lose_heart():

	if current_hearts <= 0:
		return

	current_hearts -= 1

	var hearts := hearts_container.get_children()
	if current_hearts < hearts.size():
		hearts[current_hearts].queue_free()

	if current_hearts <= 0:
		lose()

func start_round():

	if current_round >= rounds_total:
		win()
		return

	waiting_next_tap = false
	enable_boxes()

	reveal_layer.visible = false
	show_gameplay(true)

	var r: Dictionary = rounds[current_round]

	var q_index: int = r.get("question", 0)
	correct_index = r.get("correct", 0)

	q_index = clamp(q_index, 0, questions.size() - 1)
	current_question = questions[q_index]
	question_label.text = current_question.get("text", "")


func setup_boxes():

	for b in [box1, box2, box3]:
		b.texture_normal = box_closed
		b.texture_pressed = box_closed
		b.texture_hover = box_closed


func connect_buttons():

	box1.pressed.connect(func(): on_box_pressed(0))
	box2.pressed.connect(func(): on_box_pressed(1))
	box3.pressed.connect(func(): on_box_pressed(2))


func on_box_pressed(index: int):

	if waiting_next_tap or is_game_over:
		return

	disable_boxes()

	if index == correct_index:
		show_reveal(true)
	else:
		show_reveal(false)

func show_reveal(success: bool):

	waiting_next_tap = true

	show_gameplay(false)
	reveal_layer.visible = true

	if success:
		reveal_box.texture = box_open_letter
	else:
		reveal_box.texture = box_open_empty
		lose_heart()

	await get_tree().process_frame  

	reveal_box.pivot_offset = reveal_box.size / 2

	reveal_box.scale = Vector2(0.4,0.4)
	reveal_box.modulate.a = 0

	var t := create_tween()
	t.tween_property(reveal_box,"modulate:a",1,0.2)
	t.parallel().tween_property(reveal_box,"scale",Vector2.ONE,0.28)

func show_gameplay(show: bool):

	question_label.visible = show
	$BoxesContainer.visible = show

func _input(event):

	if waiting_next_tap and not is_game_over:
		if event is InputEventScreenTouch and event.pressed:
			next_round()
		if event is InputEventMouseButton and event.pressed:
			next_round()

func next_round():

	current_round += 1
	start_round()

func lose():

	is_game_over = true
	show_result_overlay("lose")


func win():

	is_game_over = true

	if not level_completed_once:
		level_completed_once = true

		ProgressManager.advance_envelope()
		ProgressManager.complete_level(level_id)

	show_result_overlay("win")

func show_result_overlay(type: String):

	var overlay := result_overlay_scene.instantiate()
	$UI.add_child(overlay)

	overlay.show_from_config(type)

	overlay.retry_pressed.connect(_on_retry_pressed)
	overlay.next_pressed.connect(_on_next_pressed.bind(type))

func _on_retry_pressed():

	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.35)

	SceneLoader.goto_scene("res://scenes/levels/IntuitionLevel.tscn")


func _on_next_pressed(type: String):

	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.35)

	SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")

func disable_boxes():
	box1.disabled = true
	box2.disabled = true
	box3.disabled = true


func enable_boxes():
	box1.disabled = false
	box2.disabled = false
	box3.disabled = false
