extends BaseLevelUI


# ---------------------------------------------------
# NODES
# ---------------------------------------------------
@export var result_overlay_scene: PackedScene

@onready var bg: TextureRect = $Background
@onready var darkness: ColorRect = $Darkness
@onready var candle: TextureRect = $CandleLight

@onready var top_word: Control = $TopWord
@onready var light_area: Area2D = $CandleLight/LightArea
@onready var letters_world: Node = $LettersWorld
@onready var timer_circle: TextureRect = $UI/TimerCircle
@onready var timer_label: Label = $UI/TimerCircle/TimerLabel
@onready var pause_btn: TextureButton = $UI/PauseButton


# ---------------------------------------------------
# STATE
# ---------------------------------------------------

var word := ""
var slots := []
var found_letters := []

var time_left := 0.0
var timer_active := false

var light_active := false 
var is_game_over := false
var level_completed_once := false

# ---------------------------------------------------
# READY
# ---------------------------------------------------

func _ready():

	if DataLoader.client_id.is_empty():
		DataLoader.load_client("vika")

	await get_tree().process_frame

	var config: Dictionary = DataLoader.config
	var level_def: Dictionary = config.get("levels", {}).get("light", {})

	load_visuals(level_def)
	setup_word(level_def)
	start_timer()
	await get_tree().process_frame

	move_light()
	update_darkness()
	light_area.area_entered.connect(_on_letter_entered)
	pause_btn.pressed.connect(show_pause)

# ---------------------------------------------------
# LOAD VISUALS
# ---------------------------------------------------

func load_visuals(def: Dictionary):

	var base_path := "res://clients/%s/" % DataLoader.client_id

	var bg_path: String = def.get("background", "")
	if bg_path != "":
		bg.texture = load(base_path + bg_path)

	var light_def: Dictionary = def.get("light", {})
	var light_path: String = light_def.get("texture", "")

	if light_path != "":
		candle.texture = load(base_path + light_path)

	var scale_val = light_def.get("scale", 0.7)
	candle.scale = Vector2.ONE * scale_val

	var ui_def: Dictionary = def.get("ui", {})

	var timer_path: String = ui_def.get("timer_circle", "")
	if timer_path != "":
		timer_circle.texture = load(DataLoader.resolve_client_path(timer_path))

	var pause_path: String = ui_def.get("pause_icon", "")
	if pause_path != "":
		pause_btn.texture_normal = load(DataLoader.resolve_client_path(pause_path))

# ---------------------------------------------------
# WORD SETUP
# ---------------------------------------------------

func setup_word(def: Dictionary):

	var base_path := "res://clients/%s/" % DataLoader.client_id

	var letters_def: Dictionary = def.get("letters", {})
	word = letters_def.get("word", "").to_upper()

	var ui_def: Dictionary = def.get("word_ui", {})
	var line_path: String = ui_def.get("line_texture", "")

	var line_tex: Texture2D = null
	if line_path != "":
		line_tex = load(base_path + line_path)

	slots = top_word.get_children()
	found_letters.clear()

	for i in range(slots.size()):

		var slot = slots[i]

		var label: Label = slot.get_node("Letter")
		label.text = ""

		var line = slot.get_node("Line")

		if line_tex and line is TextureRect:
			line.texture = line_tex

# ---------------------------------------------------
# LETTER DETECTION
# ---------------------------------------------------

func _on_letter_entered(area: Area2D):

	if not light_active:
		return

	if area.name in found_letters:
		return

	on_letter_found(area.name, area)


func on_letter_found(letter_node_name: String, area: Area2D):

	found_letters.append(letter_node_name)

	var label: Label = area.get_node("Label")

	var t := create_tween()

	t.tween_property(label, "modulate", Color(1.4,1.4,1.2,1), 0.15)
	t.tween_property(label, "modulate", Color(1,1,1,1), 0.15)

	await get_tree().create_timer(0.35).timeout 

	var t2 := create_tween()
	t2.tween_property(area, "modulate:a", 0.0, 0.25)

	await t2.finished

	area.visible = false
	area.set_deferred("monitoring", false)

	reveal_letter(letter_node_name)

	check_word_complete()

func check_word_complete():

	if is_game_over:
		return

	if found_letters.size() != word.length():
		return

	timer_active = false
	light_active = false

	await get_tree().create_timer(0.4).timeout

	finish_level()
	
func on_time_up():

	if is_game_over:
		return

	timer_active = false
	light_active = false

	game_over()
# ---------------------------------------------------
# LETTER REVEAL
# ---------------------------------------------------

func reveal_letter(letter_node_name: String):

	var letter_map := {
		"Letter_O": {"slot": 0, "char": "О"},
		"Letter_L": {"slot": 1, "char": "Л"},
		"Letter_I": {"slot": 2, "char": "И"},
		"Letter_V": {"slot": 3, "char": "В"},
		"Letter_E": {"slot": 4, "char": "Е"},
		"Letter_R": {"slot": 5, "char": "Р"}
	}

	if not letter_map.has(letter_node_name):
		return

	var data = letter_map[letter_node_name]
	var slot_index: int = data["slot"]
	var char: String = data["char"]

	var slot = slots[slot_index]
	var label: Label = slot.get_node("Letter")

	label.text = char
	label.scale = Vector2(0.5, 0.5)

	var t := create_tween()
	t.tween_property(label, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

# ---------------------------------------------------
# TIMER
# ---------------------------------------------------

func start_timer():

	var config: Dictionary = DataLoader.config
	var level_def: Dictionary = config.get("levels", {}).get("light", {})
	
	timer_label.add_theme_font_size_override("font_size", 70)
	
	time_left = level_def.get("timer", {}).get("time", 20)
	timer_active = true

	update_timer_label()


func update_timer(delta):

	if not timer_active:
		return

	time_left -= delta

	if time_left <= 0:
		time_left = 0
		timer_active = false
		on_time_up()
		return

	update_timer_label()

func update_timer_label():

	timer_label.text = str(int(ceil(time_left)))

	if time_left <= 3:
		timer_label.add_theme_color_override("font_color", Color("#FF6B6B"))
	else:
		timer_label.add_theme_color_override("font_color", Color("#FFEDA5"))

func finish_level():

	if is_game_over:
		return

	is_game_over = true
	timer_active = false
	light_active = false

	if not level_completed_once:
		level_completed_once = true
		ProgressManager.advance_envelope()
		ProgressManager.complete_level(4) # поставь ID своего уровня

	show_result_overlay("win")


func game_over():

	if is_game_over:
		return

	is_game_over = true
	timer_active = false
	light_active = false

	show_result_overlay("lose")

func show_result_overlay(type: String):

	var overlay = result_overlay_scene.instantiate()
	$UI.add_child(overlay)

	overlay.show_from_config(type)

	overlay.retry_pressed.connect(_on_retry_pressed)
	overlay.next_pressed.connect(_on_next_pressed)
	
func _on_retry_pressed():

	call_deferred("_restart_level")


func _restart_level():
	queue_free()
	SceneLoader.goto_scene("res://scenes/levels/LightLevel.tscn")

func _on_next_pressed():

	call_deferred("_go_to_map")

func _go_to_map():
	queue_free()
	SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")

# ---------------------------------------------------
# INPUT
# ---------------------------------------------------

func _input(event):

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT:
			light_active = event.pressed


# ---------------------------------------------------
# PROCESS LOOP
# ---------------------------------------------------

func _process(delta):

	update_timer(delta)

	if light_active:
		move_light()
		update_darkness()

# ---------------------------------------------------
# LIGHT MOVEMENT
# ---------------------------------------------------

func move_light():

	var pos = darkness.get_local_mouse_position()

	candle.position = pos - candle.size * candle.scale / 2


func update_darkness():

	var mat := darkness.material as ShaderMaterial
	if mat == null:
		return

	var local_mouse = darkness.get_local_mouse_position()
	var uv_mouse = local_mouse / darkness.size

	mat.set_shader_parameter("light_pos", uv_mouse)

	mat.set_shader_parameter("radius", 0.08)
	
