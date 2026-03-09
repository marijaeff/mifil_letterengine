extends Node

var current_scene: Node = null
var is_transitioning := false


func goto_scene(path: String) -> void:
	if is_transitioning:
		return

	if current_scene == null:
		current_scene = get_tree().current_scene

	is_transitioning = true
	call_deferred("_transition", path)


func _transition(path: String) -> void:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("SceneLoader: failed to load scene: %s" % path)
		is_transitioning = false
		return

	var new_scene: Node = packed.instantiate()
	if new_scene == null:
		push_error("SceneLoader: failed to instantiate scene: %s" % path)
		is_transitioning = false
		return

	if new_scene is CanvasItem:
		(new_scene as CanvasItem).modulate.a = 0.0

	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene

	await get_tree().process_frame
	await get_tree().process_frame

	var tween := create_tween()

	if current_scene != null and is_instance_valid(current_scene) and current_scene is CanvasItem:
		tween.tween_property(current_scene, "modulate:a", 0.0, 0.4)

	if new_scene is CanvasItem:
		tween.parallel().tween_property(new_scene, "modulate:a", 1.0, 0.4)

	await tween.finished

	if current_scene != null and current_scene != new_scene and is_instance_valid(current_scene):
		current_scene.queue_free()

	current_scene = new_scene
	is_transitioning = false
