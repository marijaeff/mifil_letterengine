extends Control
class_name BaseLevel

var level_id: int = 0

func setup(level_def: Dictionary) -> void:
	level_id = int(level_def.get("id", 0))

func complete() -> void:
	ProgressManager.complete_level(level_id)

	if level_id >= 4:
		SceneLoader.goto_scene("res://scenes/screens/LetterScreen.tscn")
	else:
		SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")
