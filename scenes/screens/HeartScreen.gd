extends Control

@onready var background = $Background
@onready var heart = $CenterContainer/HeartWrapper/Heart
@onready var animation = %AnimationPlayer

var config: Dictionary = {}
var beats: int = 4
var transitioning := false


func _ready() -> void:
	config = DataLoader.config.get("screens", {}).get("heart", {})
	load_visuals()
	setup_animation()
	beats = int(config.get("beats", 4))

	if not OS.has_feature("web"):
		AudioManager.play_heartbeat_loop(2.0, -10.0)

	wait_for_beats()


func wait_for_beats() -> void:
	var duration = animation.current_animation_length
	if duration <= 0.0:
		duration = 1.0
	await get_tree().create_timer(duration * beats).timeout
	go_next()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			go_next()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			go_next()


func load_visuals() -> void:
	var base_path := "res://clients/%s/" % DataLoader.client_id

	if config.has("background"):
		background.texture = load(base_path + str(config["background"]))

	if config.has("heart_texture"):
		heart.texture = load(base_path + str(config["heart_texture"]))


func setup_animation() -> void:
	animation.play("pulse")


func go_next() -> void:
	if transitioning:
		return

	transitioning = true

	if AudioManager.has_method("unlock_web_audio"):
		AudioManager.unlock_web_audio()

	AudioManager.stop_heartbeat_loop()
	animation.stop()

	var current_scale = heart.scale
	var tween := create_tween()
	tween.tween_property(heart, "scale", current_scale * 1.1, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(heart, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await tween.finished
	SceneLoader.goto_scene("res://scenes/screens/IntroScreen.tscn")
