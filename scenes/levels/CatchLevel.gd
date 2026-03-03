extends BaseLevel

@export var falling_item_scene: PackedScene

@onready var bg: TextureRect = $BackgroundLayer/Background
@onready var hands: Sprite2D = $PlantRoot/Hands
@onready var plant: Sprite2D = $PlantRoot/Plant
@onready var hearts_container: HBoxContainer = $UI/HeartsContainer
@onready var pause_btn: TextureButton = $UI/PauseButton
@onready var spawn_timer: Timer = $SpawnTimer

var plant_stages: Array[Texture2D] = []
var hearts_max: int = 3
var heart_icon: Texture2D = null

var good_items: Array[Texture2D] = []
var bad_items: Array[Texture2D] = []

var is_touching: bool = false
var last_spawn_zone: int = -1

var difficulty_time: float = 0.0
var base_spawn_time: float = 1.2
var min_spawn_time: float = 0.6

var base_speed_min: float = 170.0
var base_speed_max: float = 240.0

var base_bad_chance: float = 0.45
var max_bad_chance: float = 0.75

var difficulty_factor: float = 0.0


func _ready() -> void:
	if DataLoader.client_id.is_empty():
		DataLoader.load_client("vika") 

	var config: Dictionary = DataLoader.config
	var levels_block: Dictionary = config.get("levels", {}) as Dictionary
	var catch_def: Dictionary = levels_block.get("catch", {}) as Dictionary
	
	randomize()
	
	if catch_def.is_empty():
		push_error("Catch level config not found")
		return

	load_visuals(catch_def)
	load_items(catch_def)
	
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

	$PlantRoot/CatchArea.area_entered.connect(_on_item_caught)

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
	if area is FallingItem:
		print("Поймали: ", area.item_type)
		area.queue_free()


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

	var difficulty_factor: float = difficulty_time / 25.0
	var speed_roll: float = randf()

	var base_speed: float

	if speed_roll < 0.3:
		base_speed = randf_range(130.0, 180.0) + difficulty_factor * 20.0
	elif speed_roll < 0.75:
		base_speed = randf_range(200.0, 260.0) + difficulty_factor * 40.0
	else:
		base_speed = randf_range(300.0, 380.0) + difficulty_factor * 60.0

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
