extends Node

@export var client_id: String = "test"

func _ready():
	DataLoader.load_client(client_id)
	PlatformManager.debug_force_profile = "ios_web"
	PlatformManager.detect()
	print("BOOT PROFILE:", PlatformManager.profile)
	ProgressManager.load_progress()
	UIManager.apply_theme()

	if ProgressManager.last_screen == "map":
		SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")
	elif ProgressManager.last_screen == "letter":
		SceneLoader.goto_scene("res://scenes/screens/LetterScreen.tscn")
	elif ProgressManager.last_screen == "level" and ProgressManager.last_level_id > 0:
		LevelRouter.start_level(ProgressManager.last_level_id)
	else:
		SceneLoader.goto_scene("res://scenes/screens/HeartScreen.tscn")
