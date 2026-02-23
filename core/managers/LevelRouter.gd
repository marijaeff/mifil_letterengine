extends Node

func get_level_def(level_id: int) -> Dictionary:
	var arr: Array = DataLoader.levels.get("levels", []) as Array
	
	for item in arr:
		var d: Dictionary = item as Dictionary
		if int(d.get("id", -1)) == level_id:
			return d
	
	return {}

func can_open(level_id: int) -> bool:
	return level_id <= ProgressManager.completed_level + 1

func start_level(level_id: int) -> void:
	if not can_open(level_id):
		return

	var def: Dictionary = get_level_def(level_id)
	if def.is_empty():
		push_error("Level definition not found for id: %s" % level_id)
		return

	var scene_path: String = str(def.get("scene", ""))
	if scene_path == "":
		push_error("Level scene missing for id: %s" % level_id)
		return

	ProgressManager.select_level(level_id)

	SceneLoader.goto_scene(scene_path)
