extends Node

var profile: String = "desktop_web"
var debug_force_profile: String = ""

func detect() -> void:
	if debug_force_profile != "":
		profile = debug_force_profile
		print("Platform profile (forced):", profile)
		return

	if OS.has_feature("web_ios"):
		profile = "ios_web"
	elif OS.has_feature("web_android"):
		profile = "android_web"
	else:
		profile = "desktop_web"

	print("Platform profile:", profile)

func is_ios_web() -> bool:
	return profile == "ios_web"

func is_android_web() -> bool:
	return profile == "android_web"

func is_desktop_web() -> bool:
	return profile == "desktop_web"

func is_mobile_web() -> bool:
	return profile == "ios_web" or profile == "android_web"
	
func is_low_memory_mode() -> bool:
	return profile == "ios_web"
