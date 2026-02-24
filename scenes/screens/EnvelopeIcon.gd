extends Control
class_name EnvelopeIcon

@export var total: int = 4

@onready var glow: TextureRect = $glow

var _pulse_tween: Tween


func setup_from_map_def(map_def: Dictionary) -> void:
	var env: Dictionary = map_def.get("envelope", {}) as Dictionary

	var bases_any: Array = env.get("bases", []) as Array
	var pieces_any: Array = env.get("pieces", []) as Array

	if bases_any.size() < total or pieces_any.size() < total:
		push_warning("EnvelopeIcon: not enough bases/pieces in config.")
		return

	for i: int in range(1, total + 1):
		var base_node: TextureRect = get_node("base%d" % i) as TextureRect
		var piece_node: TextureRect = get_node("piece%d" % i) as TextureRect

		var base_path: String = DataLoader.resolve_client_path(str(bases_any[i - 1]))
		var piece_path: String = DataLoader.resolve_client_path(str(pieces_any[i - 1]))

		base_node.texture = load(base_path) as Texture2D
		piece_node.texture = load(piece_path) as Texture2D

	var glow_rel: String = str(env.get("glow", ""))
	if glow_rel != "":
		var glow_path: String = DataLoader.resolve_client_path(glow_rel)
		glow.texture = load(glow_path) as Texture2D

	glow.visible = true
	glow.self_modulate.a = 1.0


func apply_progress(completed_level: int) -> void:
	var c: int = clamp(completed_level, 0, total)
	var stage: int = clamp(c + 1, 1, total)

	# Базы
	for i: int in range(1, total + 1):
		var base_item: CanvasItem = get_node("base%d" % i) as CanvasItem
		base_item.visible = (i == stage)
		base_item.self_modulate.a = 0.9  

	for i: int in range(1, total + 1):
		var piece: CanvasItem = get_node("piece%d" % i) as CanvasItem
		piece.visible = false
		piece.self_modulate = Color(1, 1, 1, 1)

	_stop_pulse()

	if c < total:
		var current_piece: CanvasItem = get_node("piece%d" % stage) as CanvasItem
		current_piece.visible = true
		_start_soft_pulse(current_piece)

func _start_soft_pulse(node: CanvasItem) -> void:
	node.self_modulate = Color(1, 1, 1, 1)

	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.set_trans(Tween.TRANS_SINE)
	_pulse_tween.set_ease(Tween.EASE_IN_OUT)

	_pulse_tween.tween_property(
		node,
		"self_modulate",
		Color(0.88, 1.0, 0.92, 0.95),
		1.8
	)

	_pulse_tween.tween_property(
		node,
		"self_modulate",
		Color(1, 1, 1, 1),
		1.8
	)

func _stop_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null
