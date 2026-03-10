extends Button

var _press_tween: Tween
var _last_sound_time_ms: int = -1000
const SOUND_COOLDOWN_MS: int = 160

func _ready() -> void:
	await get_tree().process_frame
	pivot_offset = size / 2

	button_down.connect(_on_down)
	button_up.connect(_on_up)
	mouse_exited.connect(_on_up)
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_sound_time_ms > SOUND_COOLDOWN_MS:
		_last_sound_time_ms = now
		AudioManager.play_sfx_by_key("button", -5)

func _on_down() -> void:
	if _press_tween:
		_press_tween.kill()

	_press_tween = create_tween()
	_press_tween.set_trans(Tween.TRANS_SINE)
	_press_tween.set_ease(Tween.EASE_OUT)
	_press_tween.tween_property(self, "scale", Vector2.ONE * 0.92, 0.18)

func _on_up() -> void:
	if _press_tween:
		_press_tween.kill()

	_press_tween = create_tween()
	_press_tween.set_trans(Tween.TRANS_BACK)
	_press_tween.set_ease(Tween.EASE_OUT)
	_press_tween.tween_property(self, "scale", Vector2.ONE, 0.28)
