extends Control

@onready var background = $Background
@onready var heart = $CenterContainer/HeartWrapper/Heart
@onready var animation = %AnimationPlayer

var config
var beats : int
var transitioning := false


func _ready():
	config = DataLoader.config["screens"]["heart"]

	load_visuals()
	setup_animation()

	beats = config.get("beats", 6)  # если вдруг не задано — по умолчанию 6

	wait_for_beats()


func wait_for_beats():
	var duration = animation.current_animation_length
	await get_tree().create_timer(duration * beats).timeout
	go_next()


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		go_next()

	if event is InputEventScreenTouch and event.pressed:
		go_next()


func load_visuals():
	var base_path = "res://clients/%s/" % DataLoader.client_id

	background.texture = load(base_path + config["background"])
	heart.texture = load(base_path + config["heart_texture"])


func setup_animation():
	animation.play("pulse")


func go_next():
	if transitioning:
		return

	transitioning = true

	animation.stop()  # останавливаем обычное биение
	
	var current_scale = heart.scale
	
	var tween = create_tween()
	tween.tween_property(
		heart,
		"scale",
		current_scale * 1.1,
		0.4
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(
		heart,
		"scale",
		Vector2.ONE,
		0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await tween.finished
	
	SceneLoader.goto_scene("res://scenes/screens/IntroScreen.tscn")
