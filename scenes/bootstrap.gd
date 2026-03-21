extends Node

@export var client_id: String = "test"

func _ready():
	DataLoader.load_client(client_id)
	ProgressManager.load_progress()
	UIManager.apply_theme()
	SceneLoader.goto_scene("res://scenes/screens/HeartScreen.tscn")
