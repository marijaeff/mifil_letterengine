extends Node

var current_scene: Node = null
var is_transitioning := false
var fade_layer: ColorRect = null

func goto_scene(path: String) -> void:
	if is_transitioning:
		return

	if current_scene == null:
		current_scene = get_tree().current_scene

	is_transitioning = true
	call_deferred("_transition", path)

func _ensure_fade_layer() -> void:
	if fade_layer != null and is_instance_valid(fade_layer):
		return

	fade_layer = ColorRect.new()
	fade_layer.name = "SceneFadeLayer"
	fade_layer.color = Color("11261800")
	fade_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.offset_left = 0
	fade_layer.offset_top = 0
	fade_layer.offset_right = 0
	fade_layer.offset_bottom = 0
	fade_layer.z_index = 100

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

func _transition(path: String) -> void:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("SceneLoader: failed to load scene: %s" % path)
		is_transitioning = false
		return

	var old_scene := current_scene
	_ensure_fade_layer()
	_bring_fade_to_front()

	var fade_out_time := 0.15
	var black_hold_time := 0.003
	var fade_in_time := 0.15

	var fade_out := create_tween()
	fade_out.set_trans(Tween.TRANS_SINE)
	fade_out.set_ease(Tween.EASE_IN_OUT)
	fade_out.tween_property(fade_layer, "color:a", 0.99, fade_out_time)
	await fade_out.finished

	if black_hold_time > 0.0:
		await get_tree().create_timer(black_hold_time).timeout

	var new_scene: Node = packed.instantiate()
	if new_scene == null:
		push_error("SceneLoader: failed to instantiate scene: %s" % path)

		var fail_fade := create_tween()
		fail_fade.set_trans(Tween.TRANS_SINE)
		fail_fade.set_ease(Tween.EASE_IN_OUT)
		fail_fade.tween_property(fade_layer, "color:a", 0.0, fade_in_time)
		await fail_fade.finished

		is_transitioning = false
		return

	if old_scene != null and old_scene != new_scene and is_instance_valid(old_scene):
		old_scene.get_parent().remove_child(old_scene)
		old_scene.queue_free()

	if new_scene is CanvasItem:
		(new_scene as CanvasItem).modulate.a = 1.0

	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
	current_scene = new_scene

	_bring_fade_to_front()

	var fade_in := create_tween()
	fade_in.set_trans(Tween.TRANS_SINE)
	fade_in.set_ease(Tween.EASE_IN_OUT)
	fade_in.tween_property(fade_layer, "color:a", 0.0, fade_in_time)
	await fade_in.finished

	is_transitioning = false
