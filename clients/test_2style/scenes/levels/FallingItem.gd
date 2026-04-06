extends Area2D
class_name FallingItem

var item_type: String = "good" 
var fall_speed: float = 200.0
var sway_amplitude: float = 10.0
var sway_speed: float = 2.0
var time_passed: float = 0.0

func setup(data: Dictionary) -> void:
	item_type = data.get("type", "good")
	$Sprite2D.texture = data.get("texture")

func _process(delta: float) -> void:
	time_passed += delta
	
	position.y += fall_speed * delta
	position.x += sin(time_passed * sway_speed) * sway_amplitude * delta
