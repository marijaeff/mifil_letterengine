extends Button

var _press_tween: Tween

func _ready():
	await get_tree().process_frame
	pivot_offset = size / 2

	button_down.connect(_on_down)
	button_up.connect(_on_up)
	mouse_exited.connect(_on_up)

func _on_down():
	if _press_tween:
		_press_tween.kill()

	_press_tween = create_tween()
	_press_tween.set_trans(Tween.TRANS_SINE)
	_press_tween.set_ease(Tween.EASE_OUT)
	_press_tween.tween_property(self, "scale", Vector2.ONE * 0.92, 0.18)


func _on_up():
	if _press_tween:
		_press_tween.kill()

	_press_tween = create_tween()
	_press_tween.set_trans(Tween.TRANS_BACK)
	_press_tween.set_ease(Tween.EASE_OUT)
	_press_tween.tween_property(self, "scale", Vector2.ONE, 0.28)
