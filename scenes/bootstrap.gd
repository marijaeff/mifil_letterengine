extends Node

@export var client_id: String = "test"

func _ready():
	DataLoader.load_client(client_id)

	# Для реального теста/релиза это должно быть выключено.
	PlatformManager.debug_force_profile = "ios_web"

	PlatformManager.detect()
	print("BOOT PROFILE:", PlatformManager.profile)

	ProgressManager.load_progress()
	UIManager.apply_theme()

	if _restore_level2_reload_checkpoint():
		return

	if ProgressManager.last_screen == "map":
		SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")
	elif ProgressManager.last_screen == "letter":
		SceneLoader.goto_scene("res://scenes/screens/LetterScreen.tscn")
	elif ProgressManager.last_screen == "hug":
		SceneLoader.goto_scene("res://scenes/screens/HugScreen.tscn")
	elif ProgressManager.last_screen == "level" and ProgressManager.last_level_id > 0:
		LevelRouter.start_level(ProgressManager.last_level_id)
	else:
		SceneLoader.goto_scene("res://scenes/screens/HeartScreen.tscn")

func _restore_level2_reload_checkpoint() -> bool:
	if not OS.has_feature("web"):
		return false

	var flag = str(JavaScriptBridge.eval(
		"window.sessionStorage.getItem('mifil_resume_after_level2') || ''",
		true
	))

	if flag != "1":
		return false

	var completed = int(str(JavaScriptBridge.eval(
		"window.sessionStorage.getItem('mifil_completed_level') || '0'",
		true
	)))
	var selected = int(str(JavaScriptBridge.eval(
		"window.sessionStorage.getItem('mifil_selected_level') || '0'",
		true
	)))
	var envelope = int(str(JavaScriptBridge.eval(
		"window.sessionStorage.getItem('mifil_envelope_stage') || '0'",
		true
	)))

	ProgressManager.completed_level = completed
	ProgressManager.selected_level = selected if selected > 0 else completed + 1
	ProgressManager.envelope_stage = envelope
	ProgressManager.last_screen = "map"
	ProgressManager.last_level_id = 0
	ProgressManager.save_progress()

	JavaScriptBridge.force_fs_sync()

	JavaScriptBridge.eval("""
window.sessionStorage.removeItem('mifil_resume_after_level2');
window.sessionStorage.removeItem('mifil_completed_level');
window.sessionStorage.removeItem('mifil_selected_level');
window.sessionStorage.removeItem('mifil_envelope_stage');
""", true)

	SceneLoader.goto_scene("res://scenes/screens/MapScreen.tscn")
	return true
