extends Node

var current_scene: Node = null
var is_transitioning := false
var fade_layer: ColorRect = null

const FADE_OUT_TIME := 0.25
const BLACK_HOLD_TIME := 0.003
const FADE_IN_TIME := 0.15
const FADE_COLOR := Color("11261800")
const FADE_Z_INDEX := 100

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func goto_scene(path: String) -> void:
	if is_transitioning:
		return
	if path.is_empty():
		push_error("SceneLoader: empty path")
		return

	is_transitioning = true
	call_deferred("_transition", path)

func _transition(path: String) -> void:
	_ensure_fade_layer()
	_bring_fade_to_front()

	var fade_out := create_tween()
	fade_out.set_trans(Tween.TRANS_SINE)
	fade_out.set_ease(Tween.EASE_IN_OUT)
	fade_out.tween_property(fade_layer, "color:a", 0.99, FADE_OUT_TIME)
	await fade_out.finished

	if BLACK_HOLD_TIME > 0.0:
		await get_tree().create_timer(BLACK_HOLD_TIME, true).timeout

	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneLoader: failed to change scene: %s (err=%s)" % [path, err])

		_ensure_fade_layer()
		_bring_fade_to_front()

		var fail_fade := create_tween()
		fail_fade.set_trans(Tween.TRANS_SINE)
		fail_fade.set_ease(Tween.EASE_IN_OUT)
		fail_fade.tween_property(fade_layer, "color:a", 0.0, FADE_IN_TIME)
		await fail_fade.finished

		is_transitioning = false
		return

	await get_tree().process_frame

	current_scene = get_tree().current_scene

	_ensure_fade_layer()
	_bring_fade_to_front()

	var fade_in := create_tween()
	fade_in.set_trans(Tween.TRANS_SINE)
	fade_in.set_ease(Tween.EASE_IN_OUT)
	fade_in.tween_property(fade_layer, "color:a", 0.0, FADE_IN_TIME)
	await fade_in.finished

	is_transitioning = false

func _ensure_fade_layer() -> void:
	if fade_layer != null and is_instance_valid(fade_layer):
		return

	fade_layer = ColorRect.new()
	fade_layer.name = "SceneFadeLayer"
	fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	fade_layer.color = FADE_COLOR
	fade_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.offset_left = 0
	fade_layer.offset_top = 0
	fade_layer.offset_right = 0
	fade_layer.offset_bottom = 0
	fade_layer.z_index = FADE_Z_INDEX
	get_tree().root.add_child(fade_layer)

func _bring_fade_to_front() -> void:
	if fade_layer == null or not is_instance_valid(fade_layer):
		return

	var root := get_tree().root
	if fade_layer.get_parent() != root:
		if fade_layer.get_parent() != null:
			fade_layer.get_parent().remove_child(fade_layer)
		root.add_child(fade_layer)
	else:
		root.move_child(fade_layer, root.get_child_count() - 1)
