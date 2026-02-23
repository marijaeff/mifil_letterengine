extends BaseLevel

@onready var bg: TextureRect = $Background
@onready var title_label: Label = $Label
@onready var done_btn: Button = $DoneButton

func _ready() -> void:
	var current_id: int = ProgressManager.selected_level
	var def: Dictionary = LevelRouter.get_level_def(current_id)

	if def.is_empty():
		push_error("Level def not found")
		return

	setup(def)
	
	var bg_path: String = str(def.get("background", ""))
	if bg_path != "":
		var full_path: String
		if bg_path.begins_with("res://"):
			full_path = bg_path
		else:
			full_path = "res://clients/%s/%s" % [DataLoader.client_id, bg_path]

		var tex: Texture2D = load(full_path) as Texture2D
		if tex != null:
			bg.texture = tex

	title_label.text = str(def.get("title", "Level"))

	done_btn.pressed.connect(_on_done_pressed)

func _on_done_pressed() -> void:
	complete()
