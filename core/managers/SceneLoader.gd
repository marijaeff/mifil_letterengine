extends Node

var current_scene: Node
var is_transitioning := false


func goto_scene(path: String):

	if is_transitioning:
		return
	
	is_transitioning = true

	if current_scene == null:
		current_scene = get_tree().current_scene 

	call_deferred("_transition", path)


func _transition(path: String):

	var new_scene = load(path).instantiate()

	if new_scene is CanvasItem:
		new_scene.modulate.a = 0.0

	get_tree().root.add_child(new_scene)

	await get_tree().process_frame
	await get_tree().process_frame

	var tween = create_tween()

	if current_scene and current_scene is CanvasItem:
		tween.tween_property(current_scene, "modulate:a", 0.0, 0.4)

	if new_scene is CanvasItem:
		tween.parallel().tween_property(new_scene, "modulate:a", 1.0, 0.4)

	await tween.finished

	if current_scene:
		current_scene.queue_free()

	current_scene = new_scene
	is_transitioning = false
