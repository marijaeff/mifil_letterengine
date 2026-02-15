extends Node

@export var client_id : String = "vika"

func _ready():
	print("Bootstrap started")
	DataLoader.load_client(client_id)
	SceneLoader.goto_scene("res://scenes/screens/HeartScreen.tscn")
