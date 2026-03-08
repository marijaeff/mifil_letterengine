extends BaseLevelUI

@export var result_overlay_scene: PackedScene


# ==================================================
#                    NODES
# ==================================================

@onready var bg: TextureRect = $Background
@onready var ground: TextureRect = $SafeArea/Main/BoxArea/Ground

@onready var question_label: Label = $SafeArea/Main/QuestionBlock/QuestionLabel
@onready var timer_circle: TextureRect = $SafeArea/Main/QuestionBlock/TimerCircle

@onready var answers_container: Control = $SafeArea/Main/Answers
@onready var answer_buttons = answers_container.get_children()

@onready var box_sprite: TextureRect = $SafeArea/Main/BoxArea/BoxSprite
@onready var lamps_container: Control = $SafeArea/Main/BoxArea/Lamps

@onready var hearts_container: HBoxContainer = $UI/HeartsContainer
@onready var pause_btn: TextureButton = $UI/PauseButton

@onready var question_timer: Timer = $QuestionTimer


# ==================================================
#                    DATA
# ==================================================

var questions: Array = []
var current_question: Dictionary

var current_index := 0
var correct_answers := 0
var needed_correct := 3

var lamps = []
var torch_off: Texture2D
var torch_on: Texture2D

var is_game_over := false
var level_completed_once := false

var time_left := 0
var timer_active := false
var time_per_question := 10


# ==================================================
#                    READY
# ==================================================

func _ready():

	if DataLoader.client_id.is_empty():
		DataLoader.load_client("vika")

	await get_tree().process_frame

	var config: Dictionary = DataLoader.config
	var levels_block: Dictionary = config.get("levels", {})
	var shared_def: Dictionary = levels_block.get("shared", {})
	var question_def: Dictionary = levels_block.get("question", {})

	load_shared_ui(shared_def)
	load_visuals(question_def)
	connect_buttons()
	apply_text_styles(question_def)

	question_timer.timeout.connect(_on_timer_tick)

	start_level()

	pause_btn.pressed.connect(show_pause)  

# ==================================================
#                    LOAD UI
# ==================================================

func load_shared_ui(def: Dictionary) -> void:

	var base_path := "res://clients/%s/" % DataLoader.client_id

	var hearts_def: Dictionary = def.get("hearts", {})
	var hearts_max: int = int(hearts_def.get("max", 3))

	var heart_path: String = hearts_def.get("icon", "")
	if heart_path != "":
		var heart_icon: Texture2D = load(base_path + heart_path)

		for c in hearts_container.get_children():
			c.queue_free()

		for i in range(hearts_max):
			var heart := TextureRect.new()
			heart.texture = heart_icon
			heart.custom_minimum_size = Vector2(64,64)
			heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hearts_container.add_child(heart)

	var pause_path: String = def.get("pause_icon", "")
	if pause_path != "":
		pause_btn.texture_normal = load(base_path + pause_path)


func load_visuals(def: Dictionary) -> void:

	var base_path := "res://clients/%s/" % DataLoader.client_id

	var bg_path: String = def.get("background", "")
	if bg_path != "":
		bg.texture = load(base_path + bg_path)

	var box_path: String = def.get("box", "")
	if box_path != "":
		box_sprite.texture = load(base_path + box_path)

	var timer_path: String = def.get("timer_circle", "")
	if timer_path != "":
		timer_circle.texture = load(base_path + timer_path)

	var torches_def: Dictionary = def.get("torches", {})

	var torch_off_path: String = torches_def.get("off", "")
	if torch_off_path != "":
		torch_off = load(base_path + torch_off_path)

	var torch_on_path: String = torches_def.get("on", "")
	if torch_on_path != "":
		torch_on = load(base_path + torch_on_path)

	var ground_path: String = def.get("ground", "")
	if ground_path != "":
		ground.texture = load(DataLoader.resolve_client_path(ground_path))

	var timer_def: Dictionary = def.get("timer", {})
	time_per_question = timer_def.get("time_per_question", 10)

	questions = def.get("questions", [])

	setup_lamps()
	setup_buttons(def)


# ==================================================
#                    TEXT STYLES
# ==================================================

func apply_text_styles(def: Dictionary):

	var styles: Dictionary = def.get("text_styles", {})
	if styles.is_empty():
		return

	var ui_cfg: Dictionary = DataLoader.config.get("ui", {})
	var font_path: String = ui_cfg.get("font", "")

	if font_path == "":
		return

	var font: FontFile = load(DataLoader.resolve_client_path(font_path))

	var q_style: Dictionary = styles.get("question", {})
	question_label.add_theme_font_override("font", font)
	question_label.add_theme_font_size_override("font_size", q_style.get("size", 70))
	question_label.add_theme_color_override("font_color", Color(q_style.get("color", "#ffffff")))

	var a_style: Dictionary = styles.get("answers", {})
	for b in answer_buttons:
		b.add_theme_font_override("font", font)
		b.add_theme_font_size_override("font_size", a_style.get("size", 70))
		b.add_theme_color_override("font_color", Color(a_style.get("color", "#ffffff")))

	var t_style: Dictionary = styles.get("timer", {})
	var timer_label: Label = $SafeArea/Main/QuestionBlock/TimerCircle/TimerLabel

	timer_label.add_theme_font_override("font", font)
	timer_label.add_theme_font_size_override("font_size", t_style.get("size", 100))
	timer_label.add_theme_color_override("font_color", Color(t_style.get("color", "#ffffff")))


# ==================================================
#                    LAMPS
# ==================================================

func setup_lamps():

	lamps = lamps_container.get_children()

	for l in lamps:
		l.texture = torch_off


func light_torch_for_current():

	if current_index >= lamps.size():
		return

	var torch: TextureRect = lamps[current_index]

	torch.texture = torch_on
	torch.modulate = Color(1,1,1,0)
	torch.scale = Vector2(0.85, 0.85)

	var t := create_tween()
	t.parallel().tween_property(torch, "modulate:a", 1.0, 0.35)
	t.parallel().tween_property(torch, "scale", Vector2(1.05,1.05), 0.25)

	await t.finished

	var t2 := create_tween()
	t2.tween_property(torch, "scale", Vector2.ONE, 0.2)

	breathe_torch(torch)


func breathe_torch(torch: TextureRect):

	var t := create_tween()
	t.set_loops()

	t.tween_property(torch, "modulate:a", 0.82, 1.4)
	t.tween_property(torch, "modulate:a", 1.0, 1.4)


# ==================================================
#                    BUTTONS
# ==================================================

func setup_buttons(def: Dictionary):

	var buttons_def: Dictionary = def.get("buttons", {})
	var btn_path: String = buttons_def.get("outline", "")

	if btn_path == "":
		return

	var tex: Texture2D = load(DataLoader.resolve_client_path(btn_path))

	for b in answer_buttons:
		b.icon = tex
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		b.focus_mode = Control.FOCUS_NONE


func connect_buttons():

	for i in range(answer_buttons.size()):
		answer_buttons[i].pressed.connect(_on_answer_pressed.bind(i))


# ==================================================
#                    GAME FLOW
# ==================================================

func start_level():
	show_question(0)


func show_question(index: int):

	current_index = index
	current_question = questions[index]

	question_label.text = current_question.get("text", "")

	var answers: Array = current_question.get("answers", [])
	for i in range(answer_buttons.size()):
		answer_buttons[i].text = answers[i]

	start_timer()


func next_question():

	current_index += 1

	if current_index >= questions.size():
		finish_level()
	else:
		show_question(current_index)


# ==================================================
#                    TIMER
# ==================================================

func start_timer():

	time_left = time_per_question
	timer_active = true
	update_timer_label()

	question_timer.start()


func stop_timer():

	timer_active = false
	question_timer.stop()


func _on_timer_tick():

	if not timer_active or is_game_over:
		return

	time_left -= 1

	if time_left <= 0:
		timer_active = false
		question_timer.stop()
		await on_time_up()
		return

	update_timer_label()


func update_timer_label():

	var timer_label: Label = $SafeArea/Main/QuestionBlock/TimerCircle/TimerLabel
	timer_label.text = str(time_left)

	if time_left <= 3:
		timer_label.add_theme_color_override("font_color", Color("#FF6B6B"))
	else:
		timer_label.add_theme_color_override("font_color", Color("#FFEDA5"))


# ==================================================
#                    ANSWERS
# ==================================================

func _on_answer_pressed(index: int):

	if is_game_over:
		return
		
	AudioManager.play_sfx_by_key("button", -16)
	
	stop_timer()

	if index == current_question.get("correct", 0):
		correct_answers += 1
		
		AudioManager.play_sfx_by_key("correct", -14)
		
		await light_torch_for_current()
		await show_correct_feedback()
	else:
		AudioManager.play_sfx_by_key("wrong", -14)
		
		await lose_heart()

		if is_game_over:
			return

		await show_wrong_feedback()

	if is_game_over:
		return

	await transition_to_next()


func on_time_up():

	await lose_heart()

	if is_game_over:
		return

	await show_time_feedback()
	await transition_to_next()


# ==================================================
#                    TRANSITIONS
# ==================================================

func transition_to_next():

	if is_game_over:
		return

	stop_timer()

	var nodes = [
		question_label,
		timer_circle,
		$SafeArea/Main/QuestionBlock/TimerCircle/TimerLabel,
		answers_container
	]

	var t := create_tween()

	for n in nodes:
		t.parallel().tween_property(n, "modulate:a", 0, 0.25)

	await get_tree().create_timer(0.3).timeout

	if is_game_over:
		return

	next_question()

	for n in nodes:
		n.modulate = Color(1, 1, 1, 0)

	for b in answer_buttons:
		b.modulate = Color(1, 1, 1, 0)

	var t2 := create_tween()

	for n in nodes:
		t2.parallel().tween_property(n, "modulate:a", 1, 0.35)

	for b in answer_buttons:
		t2.parallel().tween_property(b, "modulate:a", 1, 0.35)


# ==================================================
#                    FEEDBACK
# ==================================================

func show_wrong_feedback():

	var nodes = [
		question_label,
		timer_circle,
		$SafeArea/Main/QuestionBlock/TimerCircle/TimerLabel,
		answers_container
	]

	var t := create_tween()

	for n in nodes:
		t.parallel().tween_property(n, "modulate", Color(0.7, 0.7, 0.7, 1.0), 0.22)

	await get_tree().create_timer(0.22).timeout

	for n in nodes:
		n.modulate = Color.WHITE


func show_time_feedback():

	var nodes = [
		question_label,
		timer_circle,
		$SafeArea/Main/QuestionBlock/TimerCircle/TimerLabel,
		answers_container
	]

	var t := create_tween()

	for n in nodes:
		t.parallel().tween_property(n, "modulate", Color(0.78, 0.74, 0.74, 1.0), 0.22)

	await get_tree().create_timer(0.22).timeout

	for n in nodes:
		n.modulate = Color.WHITE


func show_correct_feedback():

	var t := create_tween()

	for b in answer_buttons:
		t.parallel().tween_property(b, "modulate", Color("#D2FFCA"), 0.2)

	await get_tree().create_timer(0.25).timeout

	for b in answer_buttons:
		b.modulate = Color.WHITE

# ==================================================
#                    FINISH
# ==================================================

func finish_level():

	if is_game_over:
		return

	is_game_over = true
	stop_timer()

	if correct_answers >= needed_correct:

		if not level_completed_once:
			level_completed_once = true
			ProgressManager.advance_envelope()
			ProgressManager.complete_level(3)

		show_result_overlay("win")

	else:
		show_result_overlay("lose")


# ==================================================
#                    HEARTS
# ==================================================

func lose_heart():
	AudioManager.play_sfx_by_key("heart_loss", -12)
	
	var hearts := hearts_container.get_children()

	var target: TextureRect = null

	for i in range(hearts.size() - 1, -1, -1):
		var h: TextureRect = hearts[i]
		if h.modulate.a > 0.05:
			target = h
			break

	if target == null:
		return

	var t := create_tween()
	t.tween_property(target, "modulate:a", 0.0, 0.25)

	await t.finished

	if get_alive_hearts_count() == 0:
		game_over()

func get_alive_hearts_count() -> int:

	var count := 0

	for h in hearts_container.get_children():
		if h.modulate.a > 0.05:
			count += 1

	return count


func game_over():

	if is_game_over:
		return

	is_game_over = true
	stop_timer()

	show_result_overlay("lose")


# ==================================================
#                    RESULT
# ==================================================

func show_result_overlay(type: String):

	var overlay := result_overlay_scene.instantiate()
	$UI.add_child(overlay)

	overlay.show_from_config(type)

	overlay.retry_pressed.connect(_on_retry_pressed)
	overlay.next_pressed.connect(_on_next_pressed)

func _on_retry_pressed():
	queue_free()
	SceneLoader.goto_scene("res://scenes/levels/QuestionLevel.tscn")


func _on_next_pressed():
	queue_free()
	SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")
