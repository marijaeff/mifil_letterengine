extends Node2D
class_name BaseLevel

@export var pause_popup_scene: PackedScene

var level_id: int = 0
var pause_popup: Control = null
var level_scene_path: String

func setup(level_def: Dictionary) -> void:
	level_id = int(level_def.get("id", 0))
	level_scene_path = scene_file_path


func complete() -> void:
	ProgressManager.complete_level(level_id)
	SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")


# show pause popup
func show_pause() -> void:

	if get_tree().paused:
		return

	if is_instance_valid(pause_popup):
		return

	if pause_popup_scene == null:
		push_error("Pause popup scene is not assigned")
		return

	var root := get_tree().root
	if root == null:
		return

	pause_popup = pause_popup_scene.instantiate()
	pause_popup.process_mode = Node.PROCESS_MODE_ALWAYS

	root.add_child(pause_popup)

	pause_popup.show_from_config()

	pause_popup.resume_pressed.connect(_on_pause_resume)
	pause_popup.restart_pressed.connect(_on_pause_restart)
	pause_popup.map_pressed.connect(_on_pause_map)

	get_tree().paused = true


func close_pause() -> void:

	get_tree().paused = false

	if is_instance_valid(pause_popup):
		pause_popup.queue_free()

	pause_popup = null


func _on_pause_resume() -> void:
	close_pause()


func _on_pause_restart() -> void:

	close_pause()

	await get_tree().process_frame

	SceneLoader.goto_scene(level_scene_path)

	var scene := get_tree().current_scene
	if scene == null:
		return

	SceneLoader.goto_scene(scene.scene_file_path)


func _on_pause_map() -> void:

	close_pause()
	SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")
