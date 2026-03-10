extends BaseLevel

@export var falling_item_scene: PackedScene
@export var result_overlay_scene: PackedScene

@onready var bg: TextureRect = $BackgroundLayer/Background
@onready var hands: Sprite2D = $PlantRoot/Hands
@onready var plant: Sprite2D = $PlantRoot/Plant
@onready var hearts_container: HBoxContainer = $UI/HeartsContainer
@onready var pause_btn: TextureButton = $UI/PauseButton
@onready var spawn_timer: Timer = $SpawnTimer
@onready var hint_label: Label = $UI/Label

var plant_stages: Array[Texture2D] = []
var hearts_max: int = 3
var heart_icon: Texture2D = null

var good_items: Array[Texture2D] = []
var bad_items: Array[Texture2D] = []
var good_caught: int = 0
var total_needed: int = 40

var is_touching: bool = false
var last_spawn_zone: int = -1

var difficulty_time: float = 0.0
var base_spawn_time: float = 1.35
var min_spawn_time: float = 1.0

var base_speed_min: float = 170.0
var base_speed_max: float = 240.0

var base_bad_chance: float = 0.45
var max_bad_chance: float = 0.75

var difficulty_factor: float = 0.0

var current_hearts: int = 0
var is_game_over: bool = false


func _ready() -> void:
	
	AudioManager.set_music_volume(0.06) 
	AudioManager.play_music_by_key("level")
	
	if DataLoader.client_id.is_empty():
		DataLoader.load_client("vika")

	var current_id: int = ProgressManager.selected_level
	var def: Dictionary = LevelRouter.get_level_def(current_id)

	if def.is_empty():
		push_error("Level def not found")
		return

	setup(def)

	var config: Dictionary = DataLoader.config
	var levels_block: Dictionary = config.get("levels", {}) as Dictionary
	var shared_def: Dictionary = levels_block.get("shared", {}) as Dictionary
	var catch_def: Dictionary = levels_block.get("catch", {}) as Dictionary
	
	randomize()

	if catch_def.is_empty():
		push_error("Catch level config not found")
		return

	load_shared_ui(shared_def) 
	load_visuals(catch_def)
	load_items(catch_def)
	setup_hint(catch_def)
	
	$PlantRoot/CatchArea.area_entered.connect(_on_item_caught)
	pause_btn.pressed.connect(show_pause)

	await show_intro_hint(catch_def)

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func load_visuals(def: Dictionary) -> void:
	var base_path: String = "res://clients/%s/" % DataLoader.client_id

	var bg_path: String = def.get("background", "")
	if bg_path != "":
		bg.texture = load(base_path + bg_path) as Texture2D

	var hands_path: String = def.get("hands", "")
	if hands_path != "":
		hands.texture = load(base_path + hands_path) as Texture2D

	var stages: Array = def.get("plant_stages", []) as Array
	for p in stages:
		var stage_path: String = String(p)
		var tex: Texture2D = load(base_path + stage_path) as Texture2D
		if tex != null:
			plant_stages.append(tex)

	if plant_stages.size() > 0:
		plant.texture = plant_stages[0]
		plant.modulate.a = 0.25
		plant.scale = Vector2(0.9, 0.9)

	var hearts_def: Dictionary = def.get("hearts", {}) as Dictionary
	hearts_max = int(hearts_def.get("max", 3))

	var heart_path: String = hearts_def.get("icon", "")
	if heart_path != "":
		heart_icon = load(base_path + heart_path) as Texture2D

	create_hearts()

	var pause_path: String = def.get("pause_icon", "")
	if pause_path != "":
		pause_btn.texture_normal = load(base_path + pause_path) as Texture2D

func show_intro_hint(def: Dictionary) -> void:
	var hint_def: Dictionary = def.get("hint", {}) as Dictionary

	var text: String = str(hint_def.get("text", ""))
	if text == "":
		hint_label.visible = false
		return

	hint_label.visible = true
	hint_label.text = text
	hint_label.modulate.a = 0.0

	var ui_cfg: Dictionary = DataLoader.config.get("ui", {}) as Dictionary
	var base_path: String = "res://clients/%s/" % DataLoader.client_id
	var font_path: String = str(ui_cfg.get("font", ""))

	if font_path != "":
		var font: FontFile = load(base_path + font_path) as FontFile
		if font:
			hint_label.add_theme_font_override("font", font)

	hint_label.add_theme_font_size_override("font_size", int(hint_def.get("size", 48)))
	hint_label.add_theme_color_override("font_color", Color(str(hint_def.get("color", "#FFE9AC"))))

	var show_time: float = float(hint_def.get("show_time", 1.8))

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(hint_label, "modulate:a", 1.0, 0.4)
	t.tween_interval(show_time)
	t.tween_property(hint_label, "modulate:a", 0.0, 0.5)

	await t.finished
	hint_label.visible = false

func setup_hint(def: Dictionary) -> void:
	var hint_def: Dictionary = def.get("hint", {}) as Dictionary

	hint_label.text = str(hint_def.get("text", ""))
	hint_label.visible = hint_label.text != ""
	hint_label.modulate.a = 0.0

	var ui_cfg: Dictionary = DataLoader.config.get("ui", {}) as Dictionary
	var base_path: String = "res://clients/%s/" % DataLoader.client_id
	var font_path: String = str(ui_cfg.get("font", ""))

	if font_path != "":
		var font: FontFile = load(base_path + font_path) as FontFile
		if font:
			hint_label.add_theme_font_override("font", font)

	hint_label.add_theme_font_size_override("font_size", int(hint_def.get("size", 48)))
	hint_label.add_theme_color_override("font_color", Color(str(hint_def.get("color", "#FFE9AC"))))

	if hint_label.visible:
		var t := create_tween()
		t.set_trans(Tween.TRANS_SINE)
		t.set_ease(Tween.EASE_IN_OUT)
		t.tween_property(hint_label, "modulate:a", 1.0, 0.5)
		t.tween_interval(1.8)
		t.tween_property(hint_label, "modulate:a", 0.0, 0.7)
		t.tween_callback(func():
			if is_instance_valid(hint_label):
				hint_label.visible = false
		)

func load_shared_ui(def: Dictionary) -> void:

	var base_path: String = "res://clients/%s/" % DataLoader.client_id

	var hearts_def: Dictionary = def.get("hearts", {}) as Dictionary
	hearts_max = int(hearts_def.get("max", 3))

	var heart_path: String = hearts_def.get("icon", "")
	if heart_path != "":
		heart_icon = load(base_path + heart_path) as Texture2D

	create_hearts()

	var pause_path: String = def.get("pause_icon", "")
	if pause_path != "":
		pause_btn.texture_normal = load(base_path + pause_path) as Texture2D

func create_hearts() -> void:
	for child in hearts_container.get_children():
		child.queue_free()

	if heart_icon == null:
		return

	for i in range(hearts_max):
		var heart: TextureRect = TextureRect.new()
		heart.texture = heart_icon
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = Vector2(64, 64)
		hearts_container.add_child(heart)

	current_hearts = hearts_max

func load_items(def: Dictionary) -> void:
	var base_path: String = "res://clients/%s/" % DataLoader.client_id

	var items_def: Dictionary = def.get("items", {}) as Dictionary

	var good_list: Array = items_def.get("good", []) as Array
	for p in good_list:
		var path: String = String(p)
		var tex: Texture2D = load(base_path + path) as Texture2D
		if tex != null:
			good_items.append(tex)

	var bad_list: Array = items_def.get("bad", []) as Array
	for p in bad_list:
		var path: String = String(p)
		var tex: Texture2D = load(base_path + path) as Texture2D
		if tex != null:
			bad_items.append(tex)


func spawn_test_item() -> void:
	if falling_item_scene == null:
		push_error("FallingItem scene not assigned!")
		return

	if good_items.is_empty():
		push_error("No good items loaded!")
		return

	var item: FallingItem = falling_item_scene.instantiate()
	item.position = Vector2(400, -50)

	item.setup({
		"type": "good",
		"texture": good_items[0]
	})

	add_child(item)


func _on_item_caught(area: Area2D) -> void:
	if not (area is FallingItem):
		return
		
	if is_game_over:
		return

	var item: FallingItem = area

	if item.item_type == "bad":
		lose_heart()
	else:
		catch_good()

	area.queue_free()

func lose_heart() -> void:
	if current_hearts <= 0:
		return

	AudioManager.play_sfx_by_key("heart_loss", -12)

	current_hearts -= 1

	var hearts := hearts_container.get_children()
	if current_hearts < hearts.size():
		hearts[current_hearts].queue_free()

	if current_hearts <= 0:
		lose()

func catch_good() -> void:
	if is_game_over:
		return

	AudioManager.play_sfx_by_key("pickup", -14)

	good_caught += 1
	update_plant_growth()

	if good_caught >= total_needed:
		win()

func update_plant_growth() -> void:
	if plant_stages.is_empty():
		return

	var progress: float = float(good_caught) / float(total_needed)
	progress = clamp(progress, 0.0, 1.0)

	var stages_count: int = plant_stages.size()

	var scaled_progress: float = progress * stages_count
	var stage_index: int = int(scaled_progress)
	stage_index = clamp(stage_index, 0, stages_count - 1)

	var local_progress: float = scaled_progress - float(stage_index)

	if plant.texture != plant_stages[stage_index]:
		plant.texture = plant_stages[stage_index]

	plant.modulate.a = lerp(0.25, 1.0, local_progress)

	var scale_value: float = lerp(0.9, 1.25, progress)
	plant.scale = Vector2(scale_value, scale_value)

func change_plant_stage_smooth(new_texture: Texture2D) -> void:
	var tween := create_tween()

	tween.tween_property(plant, "modulate:a", 0.0, 0.18)

	tween.tween_callback(func():
		plant.texture = new_texture
	)

	tween.tween_property(plant, "modulate:a", 1.0, 0.22)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		is_touching = event.pressed
		if is_touching:
			move_hands(event.position)

	elif event is InputEventScreenDrag:
		if is_touching:
			move_hands(event.position)

	elif event is InputEventMouseButton:
		is_touching = event.pressed

	elif event is InputEventMouseMotion:
		if is_touching:
			move_hands(event.position)


func move_hands(pos: Vector2) -> void:
	var new_pos: Vector2 = $PlantRoot.position
	new_pos.x = pos.x
	$PlantRoot.position = new_pos
	

func spawn_random_item() -> void:
	if falling_item_scene == null:
		return

	if good_items.is_empty() and bad_items.is_empty():
		return

	var item: FallingItem = falling_item_scene.instantiate()

	var screen_width: float = get_viewport_rect().size.x
	
	var zone_count: int = 3
	var zone_width: float = screen_width / float(zone_count)

	var spawn_zone: int = randi() % zone_count
	
	if spawn_zone == last_spawn_zone:
		spawn_zone = (spawn_zone + 1) % zone_count
	
	last_spawn_zone = spawn_zone

	var min_x: float = spawn_zone * zone_width
	var max_x: float = min_x + zone_width

	var x_pos: float = randf_range(min_x + 40.0, max_x - 40.0)
	item.position = Vector2(x_pos, -50)

	var size_scale: float = randf_range(0.85, 1.15)
	item.scale = Vector2(size_scale, size_scale)

	difficulty_factor = difficulty_time / 25.0
	var speed_roll: float = randf()

	var base_speed: float

	if speed_roll < 0.25:
		base_speed = randf_range(240.0, 320.0) + difficulty_factor * 40.0
	elif speed_roll < 0.75:
		base_speed = randf_range(330.0, 430.0) + difficulty_factor * 55.0
	else:
		base_speed = randf_range(400.0, 500.0) + difficulty_factor * 45.0

	item.fall_speed = base_speed * size_scale

	var spawn_bad: bool = false

	if not bad_items.is_empty():
		var bad_difficulty: float = difficulty_time / 40.0
		var current_bad_chance: float = base_bad_chance + bad_difficulty * 0.3
		current_bad_chance = clamp(current_bad_chance, base_bad_chance, max_bad_chance)
		
		spawn_bad = randf() < current_bad_chance

	if spawn_bad:
		var tex: Texture2D = bad_items.pick_random()
		item.setup({
			"type": "bad",
			"texture": tex
		})
	else:
		var tex: Texture2D = good_items.pick_random()
		item.setup({
			"type": "good",
			"texture": tex
		})

	$FallingItemsLayer.add_child(item)

func _on_spawn_timer_timeout() -> void:
	spawn_random_item()

	if randf() < 0.3:
		spawn_random_item()

func _process(delta: float) -> void:
	difficulty_time += delta

	difficulty_factor = difficulty_time / 20.0

	var new_spawn_time: float = base_spawn_time - difficulty_factor * 0.2
	new_spawn_time = clamp(new_spawn_time, min_spawn_time, base_spawn_time)
	
	spawn_timer.wait_time = new_spawn_time

func show_result_overlay(type: String):

	var overlay := result_overlay_scene.instantiate()
	$UI.add_child(overlay)

	overlay.show_from_config(type)

	overlay.retry_pressed.connect(_on_retry_pressed)
	overlay.next_pressed.connect(_on_next_pressed.bind(type))
	
func _on_retry_pressed():

	AudioManager.play_sfx_by_key("whoosh", -12)
	await get_tree().process_frame
	queue_free()

	SceneLoader.goto_scene("res://scenes/levels/CatchLevel.tscn")

func _on_next_pressed(_type: String):
	
	AudioManager.play_sfx_by_key("whoosh", -12)
	await get_tree().process_frame
	
	queue_free()

	SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")

func lose():

	is_game_over = true
	spawn_timer.stop()
	
	AudioManager.play_sfx_by_key("wrong", -12)
	
	show_result_overlay("lose")

func win() -> void:

	is_game_over = true
	spawn_timer.stop()

	AudioManager.play_sfx_by_key("correct", -12)

	ProgressManager.advance_envelope()
	ProgressManager.complete_level(level_id)

	show_result_overlay("win")
