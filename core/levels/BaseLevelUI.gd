extends Control
class_name BaseLevelUI
@export var pause_popup_scene: PackedScene
var level_id: int = 0

func setup(level_def: Dictionary) -> void:
	level_id = int(level_def.get("id", 0))

func complete() -> void:
	ProgressManager.complete_level(level_id)
	SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")

var _pause_popup: Control = null

func show_pause() -> void:
	if _pause_popup != null and is_instance_valid(_pause_popup):
		return

	if get_tree().paused:
		return

	if pause_popup_scene == null:
		push_error("Pause popup scene is not assigned")
		return

	var hint_was_visible := false
	var hint_label: CanvasItem = null

	if has_node("UI/Label"):
		hint_label = get_node("UI/Label") as CanvasItem
		if hint_label != null:
			hint_was_visible = hint_label.visible
			hint_label.visible = false

	get_tree().paused = true

	var popup := pause_popup_scene.instantiate()
	_pause_popup = popup
	popup.process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().root.add_child(popup)
	popup.show_from_config()

	popup.resume_pressed.connect(func():
		if hint_label != null and hint_was_visible:
			hint_label.visible = true

		get_tree().paused = false
		_pause_popup = null
		popup.queue_free()
	)

	popup.restart_pressed.connect(func():
		get_tree().paused = false
		_pause_popup = null
		popup.queue_free()
		await get_tree().process_frame
		SceneLoader.goto_scene(scene_file_path)
	)

	popup.map_pressed.connect(func():
		get_tree().paused = false
		_pause_popup = null
		popup.queue_free()
		await get_tree().process_frame
		SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")
	)

	popup.tree_exited.connect(func():
		if _pause_popup == popup:
			_pause_popup = null
	)
	
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
