extends Node

@export var client_id: String = "test_2style"
@export var locale: String = "en" 

func _ready():
	DataLoader.load_client(client_id, locale)

	PlatformManager.debug_force_profile = "ios_web"
	PlatformManager.detect()
	print("BOOT PROFILE:", PlatformManager.profile)

	ProgressManager.load_progress()
	UIManager.apply_theme()

	if _restore_level2_reload_checkpoint():
		return

	if ProgressManager.last_screen == "map":
		print("BOOT client_id =", client_id)
		print("BOOT DataLoader.client_id =", DataLoader.client_id)
		print("BOOT last_screen =", ProgressManager.last_screen)
		print("BOOT map path =", DataLoader.resolve_scene_path("screens/MapScreen.tscn"))
		SceneLoader.goto_scene(DataLoader.resolve_scene_path("screens/MapScreen.tscn"))

	elif ProgressManager.last_screen == "letter":
		print("BOOT client_id =", client_id)
		print("BOOT DataLoader.client_id =", DataLoader.client_id)
		print("BOOT last_screen =", ProgressManager.last_screen)
		print("BOOT map path =", DataLoader.resolve_scene_path("screens/MapScreen.tscn"))
		SceneLoader.goto_scene(DataLoader.resolve_scene_path("screens/LetterScreen.tscn"))

	elif ProgressManager.last_screen == "hug":
		print("BOOT client_id =", client_id)
		print("BOOT DataLoader.client_id =", DataLoader.client_id)
		print("BOOT last_screen =", ProgressManager.last_screen)
		print("BOOT map path =", DataLoader.resolve_scene_path("screens/MapScreen.tscn"))
		SceneLoader.goto_scene(DataLoader.resolve_scene_path("screens/HugScreen.tscn"))

	elif ProgressManager.last_screen == "level" and ProgressManager.last_level_id > 0:
		LevelRouter.start_level(ProgressManager.last_level_id)

	else:
		print("BOOT client_id =", client_id)
		print("BOOT DataLoader.client_id =", DataLoader.client_id)
		print("BOOT last_screen =", ProgressManager.last_screen)
		print("BOOT map path =", DataLoader.resolve_scene_path("screens/MapScreen.tscn"))
		SceneLoader.goto_scene(DataLoader.resolve_scene_path("screens/HeartScreen.tscn"))

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

	SceneLoader.goto_scene(DataLoader.resolve_scene_path("screens/MapScreen.tscn"))
	return true
