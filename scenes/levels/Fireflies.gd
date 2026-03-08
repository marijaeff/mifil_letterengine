extends Node2D

@export var count := 9
@export var area := Vector2(1080, 1920)

var lights := []

func _ready():

	randomize()

	for i in count:

		var l := Sprite2D.new()
		l.texture = preload("res://clients/vika/assets/objects/question/firefly.png")

		reset_firefly(l, false)   # ← ВОТ ГЛАВНОЕ

		add_child(l)
		lights.append(l)


func reset_firefly(l: Sprite2D, instant=false):

	l.position = Vector2(
		randf_range(0, area.x),
		randf_range(0, area.y)
	)

	var s = randf_range(0.25, 0.7)
	l.scale = Vector2.ONE * s

	l.modulate = Color(1,0.9,0.6,0)

	if not instant:
		animate_firefly(l)


func animate_firefly(l: Sprite2D):

	var life_time = randf_range(3.5, 6.0)

	var t := create_tween()

	t.tween_property(l, "modulate:a", randf_range(0.6,0.9), 0.8)

	var drift = Vector2(
		randf_range(-40,40),
		randf_range(-60,-20)
	)

	t.parallel().tween_property(l, "position", l.position + drift, life_time)

	t.parallel().tween_property(l, "scale", l.scale * 1.15, life_time/2)
	t.parallel().tween_property(l, "scale", l.scale, life_time/2)

	t.tween_property(l, "modulate:a", 0, 1.0)

	await t.finished

	reset_firefly(l)
