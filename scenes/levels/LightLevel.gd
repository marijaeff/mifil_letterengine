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

var current_id: int = 0

var word := ""
var slots := []
var found_letters := []

var time_left := 0.0
var timer_active := false

var light_active := false 
var is_game_over := false
var level_completed_once := false

var pointer_pos: Vector2 = Vector2.ZERO
var light_finger_offset: Vector2 = Vector2(0, -140)

var _light_dirty: bool = true
var _last_pointer_pos: Vector2 = Vector2(-99999, -99999)

# ---------------------------------------------------
# READY
# ---------------------------------------------------

func _ready():
	
	await get_tree().process_frame

	current_id = ProgressManager.selected_level
	var route_def: Dictionary = LevelRouter.get_level_def(current_id)

	if route_def.is_empty():
		push_error("Level def not found")
		return

	ProgressManager.last_screen = "level"
	ProgressManager.last_level_id = current_id
	ProgressManager.save_progress()

	var config: Dictionary = DataLoader.config
	var level_def: Dictionary = config.get("levels", {}).get("light", {})

	load_visuals(level_def)
	setup_word(level_def)
	start_timer()
	await get_tree().process_frame

	move_light()
	update_darkness()
	
	_light_dirty = false
	_last_pointer_pos = pointer_pos
	
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
	
	AudioManager.play_sfx_by_key("letter_found", -14)
	
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
	
	timer_label.add_theme_font_size_override("font_size", 100)
	
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
		ProgressManager.complete_level(current_id)
	
	AudioManager.play_sfx_by_key("correct", -14)
	
	show_result_overlay("win")


func game_over():

	if is_game_over:
		return

	is_game_over = true
	timer_active = false
	light_active = false

	AudioManager.play_sfx_by_key("wrong", -14)

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
	AudioManager.play_sfx_by_key("whoosh", -12)

	ProgressManager.last_screen = "level"
	ProgressManager.last_level_id = current_id
	ProgressManager.save_progress()

	_release_heavy_resources()
	await get_tree().process_frame

	SceneLoader.goto_scene("res://scenes/levels/LightLevel.tscn")

func _on_next_pressed():

	call_deferred("_go_to_map")

func _go_to_map():
	AudioManager.play_sfx_by_key("whoosh", -12)

	ProgressManager.last_screen = "map"
	ProgressManager.last_level_id = 0
	ProgressManager.save_progress()

	_release_heavy_resources()
	await get_tree().process_frame

	SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")

# ---------------------------------------------------
# INPUT
# ---------------------------------------------------

func _input(event):

	if event is InputEventScreenTouch:
		pointer_pos = event.position
		light_active = event.pressed
		_light_dirty = true

	elif event is InputEventScreenDrag:
		pointer_pos = event.position
		_light_dirty = true

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			pointer_pos = event.position
			light_active = event.pressed
			_light_dirty = true

	elif event is InputEventMouseMotion:
		pointer_pos = event.position
		_light_dirty = true

# ---------------------------------------------------
# PROCESS LOOP
# ---------------------------------------------------

func _process(delta):

	update_timer(delta)

	if light_active and _light_dirty:
		if pointer_pos != _last_pointer_pos:
			move_light()
			update_darkness()
			_last_pointer_pos = pointer_pos

		_light_dirty = false

# ---------------------------------------------------
# LIGHT MOVEMENT
# ---------------------------------------------------

func move_light():
	var offset := light_finger_offset

	if PlatformManager.is_low_memory_mode():
		offset = Vector2(0, -120)

	var local_pos: Vector2 = pointer_pos - darkness.global_position + offset
	candle.position = local_pos - (candle.size * candle.scale) / Vector2(2, 2)

func update_darkness():
	var mat := darkness.material as ShaderMaterial
	if mat == null:
		return

	var offset := light_finger_offset
	if PlatformManager.is_low_memory_mode():
		offset = Vector2(0, -120)

	var local_pos: Vector2 = pointer_pos - darkness.global_position + offset
	var uv_pos: Vector2 = local_pos / darkness.size

	mat.set_shader_parameter("light_pos", uv_pos)

	if PlatformManager.is_low_memory_mode():
		mat.set_shader_parameter("radius", 0.11)
	else:
		mat.set_shader_parameter("radius", 0.085)

func _release_heavy_resources() -> void:
	timer_active = false
	light_active = false

	if darkness:
		darkness.material = null

	if bg:
		bg.texture = null

	if candle:
		candle.texture = null

	if timer_circle:
		timer_circle.texture = null
