extends Node

const SETTINGS_PATH := "user://audio_settings.cfg"
const SETTINGS_SECTION := "audio"

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var heartbeat_player: AudioStreamPlayer
var heartbeat_timer: Timer

var _current_music_key: String = ""
var _fade_tween: Tween

var music_enabled: bool = true
var music_volume_linear: float = 1.0
var sfx_enabled: bool = true
var _web_audio_unlocked: bool = false


func _ready() -> void:
	_create_players()
	_load_settings()
	_apply_volume()


func _get_existing_bus(preferred: String, fallback: String = "Master") -> String:
	if AudioServer.get_bus_index(preferred) != -1:
		return preferred
	if AudioServer.get_bus_index(fallback) != -1:
		return fallback
	return "Master"


func _create_players() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = _get_existing_bus("Music", "Master")
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = _get_existing_bus("SFX", "Master")
	add_child(sfx_player)

	heartbeat_player = AudioStreamPlayer.new()
	heartbeat_player.bus = _get_existing_bus("SFX", "Master")
	heartbeat_player.volume_db = -18
	add_child(heartbeat_player)

	heartbeat_timer = Timer.new()
	heartbeat_timer.one_shot = false
	heartbeat_timer.wait_time = 1.2
	heartbeat_timer.timeout.connect(_on_heartbeat_timer_timeout)
	add_child(heartbeat_timer)


func unlock_web_audio() -> void:
	if not OS.has_feature("web"):
		return
	if _web_audio_unlocked:
		return
	if DataLoader.config.is_empty():
		return

	var sfx_config: Dictionary = DataLoader.config.get("audio", {}).get("sfx", {})
	var unlock_key := ""

	for key in ["button", "heartbeat", "whoosh"]:
		if sfx_config.has(key):
			unlock_key = key
			break

	if unlock_key == "":
		_web_audio_unlocked = true
		return

	var path: String = DataLoader.resolve_client_path(str(sfx_config[unlock_key]))
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return

	sfx_player.stream = stream
	sfx_player.volume_db = -80
	sfx_player.play()

	_web_audio_unlocked = true


func play_music_by_key(key: String, fade_duration: float = 1.0) -> void:
	if DataLoader.config.is_empty():
		return

	var audio_config: Dictionary = DataLoader.config.get("audio", {})
	var music_config: Dictionary = audio_config.get("music", {})

	if not music_config.has(key):
		push_warning("Music key not found: %s" % key)
		return

	if key == _current_music_key and music_player.stream != null:
		if music_enabled and not music_player.playing:
			music_player.play()
		return

	var path: String = DataLoader.resolve_client_path(str(music_config[key]))
	var stream: AudioStream = load(path) as AudioStream

	if stream == null:
		push_warning("Failed to load music: %s" % path)
		return

	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3:
		stream.loop = true

	_crossfade_to(stream, fade_duration)
	_current_music_key = key


func _crossfade_to(stream: AudioStream, duration: float) -> void:
	if _fade_tween:
		_fade_tween.kill()

	if not music_enabled:
		music_player.stop()
		music_player.stream = stream
		music_player.volume_db = _linear_to_db(music_volume_linear)
		return

	if not music_player.playing:
		music_player.stream = stream
		music_player.volume_db = _linear_to_db(music_volume_linear)
		music_player.play()
		return

	_fade_tween = create_tween()
	_fade_tween.tween_property(music_player, "volume_db", -40.0, duration)
	_fade_tween.tween_callback(func():
		music_player.stop()
		music_player.stream = stream
		music_player.volume_db = -40.0
		if music_enabled:
			music_player.play()
	)
	_fade_tween.tween_property(music_player, "volume_db", _linear_to_db(music_volume_linear), duration)


func stop_music(fade_duration: float = 0.5) -> void:
	if _fade_tween:
		_fade_tween.kill()

	if not music_player.playing:
		_current_music_key = ""
		return

	_fade_tween = create_tween()
	_fade_tween.tween_property(music_player, "volume_db", -40.0, fade_duration)
	_fade_tween.tween_callback(func():
		music_player.stop()
	)
	_current_music_key = ""


func play_sfx(stream: AudioStream, volume_db := -5.0) -> void:
	if not sfx_enabled:
		return
	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = _get_existing_bus("SFX", "Master")
	player.volume_db = volume_db
	add_child(player)

	player.finished.connect(func():
		if is_instance_valid(player):
			player.queue_free()
	)

	player.play()


func play_sfx_by_key(key: String, volume_db := -5.0) -> void:
	if DataLoader.config.is_empty():
		return

	var sfx_config: Dictionary = DataLoader.config.get("audio", {}).get("sfx", {})
	if not sfx_config.has(key):
		push_warning("SFX key not found: %s" % key)
		return

	var path: String = DataLoader.resolve_client_path(str(sfx_config[key]))
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_warning("Failed to load SFX: %s" % path)
		return

	if key == "correct":
		volume_db -= 20.0

	play_sfx(stream, volume_db)


func play_heartbeat_loop(interval: float = 1.2, volume_db: float = -18.0) -> void:
	if DataLoader.config.is_empty():
		return

	var sfx_config: Dictionary = DataLoader.config.get("audio", {}).get("sfx", {})
	if not sfx_config.has("heartbeat"):
		return

	var path: String = DataLoader.resolve_client_path(str(sfx_config["heartbeat"]))
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_warning("Failed to load heartbeat: %s" % path)
		return

	heartbeat_player.stream = stream
	heartbeat_player.bus = _get_existing_bus("SFX", "Master")
	heartbeat_player.volume_db = volume_db

	heartbeat_timer.stop()
	heartbeat_timer.wait_time = interval
	heartbeat_player.play()
	heartbeat_timer.start()


func stop_heartbeat_loop() -> void:
	heartbeat_timer.stop()
	heartbeat_player.stop()


func _on_heartbeat_timer_timeout() -> void:
	if heartbeat_player.stream == null:
		return
	heartbeat_player.play()


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if enabled:
		_apply_volume()
		if music_player.stream != null and not music_player.playing:
			music_player.play()
	else:
		music_player.stop()
	_save_settings()


func set_music_volume(linear: float) -> void:
	music_volume_linear = clamp(linear, 0.0, 1.0)
	_apply_volume()
	_save_settings()


func _apply_volume() -> void:
	if music_player == null:
		return
	music_player.volume_db = _linear_to_db(music_volume_linear)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SETTINGS_SECTION, "enabled", music_enabled)
	cfg.set_value(SETTINGS_SECTION, "volume", music_volume_linear)
	cfg.set_value(SETTINGS_SECTION, "sfx_enabled", sfx_enabled)
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return

	music_enabled = bool(cfg.get_value(SETTINGS_SECTION, "enabled", true))
	music_volume_linear = float(cfg.get_value(SETTINGS_SECTION, "volume", 1.0))
	sfx_enabled = bool(cfg.get_value(SETTINGS_SECTION, "sfx_enabled", true))

func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled

	if not sfx_enabled:
		if sfx_player != null:
			sfx_player.stop()
		if heartbeat_player != null:
			heartbeat_player.stop()
		if heartbeat_timer != null:
			heartbeat_timer.stop()

	_save_settings()

func _linear_to_db(value: float) -> float:
	if value <= 0.0:
		return -80.0
	return 20.0 * log(value) / log(10.0)
