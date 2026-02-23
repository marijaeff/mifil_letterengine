extends BaseLevel

@onready var bg := $Background
@onready var done_btn := $DoneButton

func _ready() -> void:
	var def := LevelRouter.get_level_def(1)
	setup(def)

	var base_path: String = "res://clients/%s/" % DataLoader.client_id
	var bg_path: String = str(def.get("background", ""))
	if bg_path != "":
		bg.texture = load(base_path + bg_path)

	done_btn.pressed.connect(func(): complete())
