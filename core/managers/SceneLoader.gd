extends Node

var current_scene : Node

func goto_scene(path: String):

	call_deferred("_load_scene", path)


func _load_scene(path: String):

	if current_scene:
		current_scene.queue_free()

	var scene_resource = load(path)
	current_scene = scene_resource.instantiate()

	get_tree().root.add_child(current_scene)

	print("Scene loaded:", path)
