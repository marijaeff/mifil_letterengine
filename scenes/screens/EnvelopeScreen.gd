extends Control

@onready var background = $Background
@onready var envelope = $VBoxContainer/CenterContainer/Envelope
@onready var read_button = $VBoxContainer/ReadButton

var config
var transitioning := false


func _ready():
	config = DataLoader.config["screens"]["envelope"]

	load_content()
	setup_initial_state()

	await show_button()
	start_idle_animation()


func load_content():
	var base_path = "res://clients/%s/" % DataLoader.client_id

	background.texture = load(base_path + config["background"])
	envelope.texture = load(base_path + config["envelope_texture"])
	
	var envelope_texts: Dictionary = DataLoader.texts.get("envelope", {}) as Dictionary
	
	read_button.text = envelope_texts.get("button_text", "")
	read_button.icon = load(base_path + config["button_outline"])


func setup_initial_state():
	read_button.modulate.a = 0.0
	read_button.visible = false

	read_button.add_theme_font_size_override(
		"font_size",
		DataLoader.config["ui"]["button_font_size"]
	)


func show_button():
	await get_tree().create_timer(0.4).timeout

	read_button.visible = true

	var tween = create_tween()
	tween.tween_property(read_button, "modulate:a", 1.0, 0.6)
	await tween.finished

	read_button.pressed.connect(_on_read_pressed)


func start_idle_animation():
	envelope.pivot_offset = envelope.size * 0.5

	var tween = create_tween().set_loops()

	tween.tween_property(envelope, "scale", Vector2(1.02, 1.02), 2.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(envelope, "scale", Vector2.ONE, 2.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)


func _on_read_pressed():
	if transitioning:
		return

	transitioning = true

	var tween = create_tween()
	tween.tween_property(envelope, "scale", Vector2(1.08, 1.08), 0.4)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	await tween.finished

	SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")
