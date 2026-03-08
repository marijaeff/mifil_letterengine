extends Control
class_name BaseLevelUI
@export var pause_popup_scene: PackedScene
var level_id: int = 0

func setup(level_def: Dictionary) -> void:
	level_id = int(level_def.get("id", 0))

func complete() -> void:
	ProgressManager.complete_level(level_id)
	SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")

func show_pause() -> void:

	if get_tree().paused:
		return

	if pause_popup_scene == null:
		push_error("Pause popup scene is not assigned")
		return

	var popup := pause_popup_scene.instantiate()
	popup.process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().root.add_child(popup)

	popup.show_from_config()

	popup.resume_pressed.connect(func():
		get_tree().paused = false
		popup.queue_free()
	)

	popup.restart_pressed.connect(func():
		get_tree().paused = false
		popup.queue_free()
		await get_tree().process_frame
		SceneLoader.goto_scene(scene_file_path)
	)

	popup.map_pressed.connect(func():
		get_tree().paused = false
		popup.queue_free()
		await get_tree().process_frame
		SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")
	)

	get_tree().paused = true
	
func _on_pause_resume() -> void:

	get_tree().paused = false
	
func _on_pause_map() -> void:

	get_tree().paused = false
	SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")
	
func _restart_level() -> void:

	var scene_path := get_tree().current_scene.scene_file_path
	SceneLoader.goto_scene(scene_path)
	
func _on_pause_restart() -> void:

	get_tree().paused = false
	call_deferred("_restart_level")
