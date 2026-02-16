extends Node

@export var client_id : String = "vika"

func _ready():
	DataLoader.load_client("vika")  
	UIManager.apply_theme()
	SceneLoader.goto_scene("res://scenes/screens/HeartScreen.tscn")
