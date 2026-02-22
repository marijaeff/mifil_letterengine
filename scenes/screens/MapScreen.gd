extends Control

@onready var background = $Background
@onready var title_label = $CenterWrap/Canvas/TitleLabel

@onready var envelope_root = $CenterWrap/Canvas/EnvelopeIcon
@onready var envelope_base = $CenterWrap/Canvas/EnvelopeIcon/EnvelopeIcon

@onready var path_line = $CenterWrap/Canvas/PathLayer/PathLine
@onready var lights_container = $CenterWrap/Canvas/PathLayer/LightsContainer

@onready var start_button = $CenterWrap/Canvas/StartButton

var config

var selected_level: int = 1

var DEBUG_RESET_PROGRESS: bool = true

var cached_raw_points: Array = []

func _ready():

	config = DataLoader.config["screens"]["map"]
	
	if DEBUG_RESET_PROGRESS:
		ProgressManager.reset_progress()
	
	ProgressManager.load_progress()
	selected_level = ProgressManager.selected_level
	
	load_content()
	build_path()
	show_button()
	
func load_content():
	var base_path = "res://clients/%s/" % DataLoader.client_id

	background.texture = load(base_path + config["background"])

	var map_texts: Dictionary = DataLoader.texts.get("map", {}) as Dictionary

	title_label.text = map_texts.get("title", "")
	
	start_button.text = map_texts.get("button", "")
	start_button.icon = load(base_path + config["button"]["texture"])

	envelope_base.texture = load(base_path + config["envelope"]["base"])

	var piece = TextureRect.new()
	piece.texture = load(base_path + config["envelope"]["piece"])
	envelope_root.add_child(piece)
	
func show_button():
	start_button.visible = true
	
	var tween = create_tween()
	tween.tween_property(start_button, "modulate:a", 1.0, 0.8)
	
func build_path() -> void:

	var path_data: Dictionary = config["path"] as Dictionary
	var curve: Curve2D = Curve2D.new()

	cached_raw_points.clear()

	for p in path_data["points"]:
		cached_raw_points.append(Vector2(p[0], p[1]))

	for point in cached_raw_points:
		curve.add_point(point)

	for i in range(curve.point_count):
		if i == 0 or i == curve.point_count - 1:
			continue

		var prev: Vector2 = curve.get_point_position(i - 1)
		var next: Vector2 = curve.get_point_position(i + 1)

		var dir: Vector2 = (next - prev).normalized()
		var distance: float = prev.distance_to(next) * 0.18

		curve.set_point_in(i, -dir * distance)
		curve.set_point_out(i, dir * distance)

	curve.bake_interval = 2.0
	var baked: Array = curve.get_baked_points()

	var width_curve: Curve = Curve.new()
	width_curve.add_point(Vector2(0.0, path_data["width_start"]))
	width_curve.add_point(Vector2(1.0, path_data["width_end"]))
	path_line.width_curve = width_curve

	build_dashed_line(baked, path_data)
	build_levels(cached_raw_points)
	
func build_dashed_line(points, path_data):

	for child in path_line.get_children():
		child.queue_free()

	var style = path_data["style"]

	var line_color = Color(style["color"])
	var glow_color = Color(style["glow_color"])
	var glow_alpha = float(style["glow_alpha"])
	var glow_multiplier = float(style["glow_width_multiplier"])
	var perspective_power = float(style["perspective_power"])

	var width_start = float(path_data["width_start"])
	var width_end = float(path_data["width_end"])

	var total_length = 0.0
	for i in range(points.size() - 1):
		total_length += points[i].distance_to(points[i + 1])

	var traveled_global = 0.0
	var distance_accumulated = 0.0
	var drawing = true

	for i in range(points.size() - 1):

		var a = points[i]
		var b = points[i + 1]

		var segment_length = a.distance_to(b)
		var dir = (b - a).normalized()
		var segment_traveled = 0.0

		while segment_traveled < segment_length:

			var progress = traveled_global / total_length
			progress = pow(progress, perspective_power)

			var current_width = lerp(width_start, width_end, progress)

			var dash_length = lerp(float(path_data["dash_length"]), float(path_data["dash_length"]) * 0.5, progress)
			var gap_length = lerp(float(path_data["gap_length"]), float(path_data["gap_length"]) * 0.6, progress)
			var total_local = dash_length + gap_length

			var step = min(total_local - distance_accumulated, segment_length - segment_traveled)

			if drawing:

				var start = a + dir * segment_traveled
				var end = a + dir * (segment_traveled + step)

				var glow_line = Line2D.new()
				glow_line.width = current_width * glow_multiplier
				glow_line.default_color = Color(glow_color.r, glow_color.g, glow_color.b, glow_alpha)
				glow_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
				glow_line.end_cap_mode = Line2D.LINE_CAP_ROUND
				glow_line.add_point(start)
				glow_line.add_point(end)
				path_line.add_child(glow_line)

				var dash_line = Line2D.new()
				dash_line.width = current_width
				dash_line.default_color = line_color
				dash_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
				dash_line.end_cap_mode = Line2D.LINE_CAP_ROUND
				dash_line.add_point(start)
				dash_line.add_point(end)
				path_line.add_child(dash_line)

			segment_traveled += step
			traveled_global += step
			distance_accumulated += step

			if distance_accumulated >= total_local:
				distance_accumulated = 0.0
				drawing = not drawing

func create_level_point(position: Vector2, state: String, t: float, tex_paths: Dictionary, level_index: int) -> void:
	var level_node: Node2D = Node2D.new()
	level_node.position = position

	var perspective_power: float = 1.25
	var scale_bottom: float = 1.10
	var scale_top: float = 0.52
	var scale_t: float = lerp(scale_bottom, scale_top, pow(t, perspective_power))
	level_node.scale = Vector2.ONE * scale_t

	var base_path: String = "res://clients/%s/" % DataLoader.client_id

	var rel_path: String = tex_paths.get(state, "assets/ui/lvl_locked.png")
	var tex: Texture2D = load(base_path + rel_path) as Texture2D
	if tex == null:
		push_error("MapScreen: cannot load level texture: %s" % (base_path + rel_path))
		return

	var button: TextureButton = TextureButton.new()
	button.texture_normal = tex
	button.texture_hover = tex
	button.texture_pressed = tex
	button.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	
	button.position = -tex.get_size() / 2

	level_node.add_child(button)
	lights_container.add_child(level_node)

	if state == "locked":
		button.disabled = true
	else:
		button.connect("pressed", Callable(self, "_on_level_pressed").bind(level_index))

	if level_index == selected_level:
		var base_scale: Vector2 = level_node.scale

		var tween: Tween = level_node.create_tween()
		tween.set_loops()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)

		tween.tween_property(level_node, "scale", base_scale * 1.12, 1.4)
		tween.tween_property(level_node, "scale", base_scale, 1.4)


func build_levels(raw_points: Array) -> void:
	for child in lights_container.get_children():
		child.queue_free()

	var levels_data: Dictionary = config.get("levels", {}) as Dictionary

	var count: int = int(levels_data.get("count", 0))
	var completed: int = ProgressManager.completed_level
	var active: int = completed + 1

	var tex_paths: Dictionary = levels_data.get("textures", {}) as Dictionary

	count = min(count, raw_points.size())

	for i in range(count):
		var state: String = "locked"
		if i + 1 == active:
			state = "active"
		elif i + 1 <= completed:
			state = "completed"

		var t: float = 0.0
		if count > 1:
			t = float(i) / float(count - 1)

		create_level_point(raw_points[i] as Vector2, state, t, tex_paths, i + 1)

func rebuild_levels_only() -> void:
	build_levels(cached_raw_points)

func _on_level_pressed(level_index: int) -> void:

	if level_index == ProgressManager.completed_level + 1:
		ProgressManager.complete_level(level_index)
	else:
		ProgressManager.select_level(level_index)

	selected_level = ProgressManager.selected_level
	rebuild_levels_only()
