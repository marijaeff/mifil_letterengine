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


func _ready() -> void:
	_create_players()
	_load_settings()
	_apply_volume()


# -------------------------------------------------------------------
# INIT
# -------------------------------------------------------------------

func _create_players() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)

	heartbeat_player = AudioStreamPlayer.new()
	heartbeat_player.bus = "SFX"
	heartbeat_player.volume_db = -18
	add_child(heartbeat_player)

	heartbeat_timer = Timer.new()
	heartbeat_timer.one_shot = false
	heartbeat_timer.wait_time = 1.2
	heartbeat_timer.timeout.connect(_on_heartbeat_timer_timeout)
	add_child(heartbeat_timer)


# -------------------------------------------------------------------
# MUSIC (CONFIG-DRIVEN)
# -------------------------------------------------------------------

func play_music_by_key(key: String, fade_duration: float = 1.0) -> void:
	if key == _current_music_key:
		return

	if DataLoader.config.is_empty():
		return

	var audio_config: Dictionary = DataLoader.config.get("audio", {})
	var music_config: Dictionary = audio_config.get("music", {})

	if not music_config.has(key):
		push_warning("Music key not found: %s" % key)
		return

	var path: String = DataLoader.resolve_client_path(music_config[key])
	var stream: AudioStream = load(path)

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

	_fade_tween = create_tween()

	if music_player.playing:
		_fade_tween.tween_property(music_player, "volume_db", -40, duration)

	_fade_tween.tween_callback(func():
		music_player.stream = stream
		music_player.volume_db = -40
		if music_enabled:
			music_player.play()
	)

	_fade_tween.tween_property(
	music_player,
	"volume_db",
	_linear_to_db(music_volume_linear),
	duration
)


func stop_music(fade_duration: float = 0.5) -> void:
	if _fade_tween:
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(music_player, "volume_db", -40, fade_duration)
	_fade_tween.tween_callback(func(): music_player.stop())

	_current_music_key = ""


# -------------------------------------------------------------------
# SFX
# -------------------------------------------------------------------

func play_sfx(stream: AudioStream, volume_db := -5) -> void:
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	sfx_player.play()


func play_sfx_by_key(key: String, volume_db := -5) -> void:

	if DataLoader.config.is_empty():
		return

	var sfx_config: Dictionary = DataLoader.config.get("audio", {}).get("sfx", {})

	if not sfx_config.has(key):
		push_warning("SFX key not found: %s" % key)
		return

	var path: String = DataLoader.resolve_client_path(sfx_config[key])
	var stream: AudioStream = load(path)

	if stream == null:
		push_warning("Failed to load SFX: %s" % path)
		return

	if key == "correct":
		volume_db -= 20 

	play_sfx(stream, volume_db)


# -------------------------------------------------------------------
# HEARTBEAT
# -------------------------------------------------------------------

func play_heartbeat_loop(interval: float = 1.2, volume_db: float = -18) -> void:

	print("HEART START")

	if DataLoader.config.is_empty():
		print("NO CONFIG")
		return

	var sfx_config: Dictionary = DataLoader.config.get("audio", {}).get("sfx", {})

	if not sfx_config.has("heartbeat"):
		print("NO HEART IN CONFIG")
		return

	var path: String = DataLoader.resolve_client_path(sfx_config["heartbeat"])
	print("PATH:", path)

	var stream: AudioStream = load(path)
	print("STREAM:", stream)

	if stream == null:
		print("FAILED LOAD")
		return

	heartbeat_player.stream = stream
	heartbeat_player.bus = "SFX"
	heartbeat_player.volume_db = -10

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


# -------------------------------------------------------------------
# SETTINGS
# -------------------------------------------------------------------

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled

	if enabled:
		_apply_volume()
		if music_player.stream:
			music_player.play()
	else:
		music_player.stop()

	_save_settings()


func set_music_volume(linear: float) -> void:
	music_volume_linear = clamp(linear, 0.0, 1.0)
	_apply_volume()
	_save_settings()


func _apply_volume() -> void:
	music_player.volume_db = _linear_to_db(music_volume_linear)


# -------------------------------------------------------------------
# SAVE / LOAD
# -------------------------------------------------------------------

func _save_settings() -> void:
	var cfg := ConfigFile.new()

	cfg.set_value(SETTINGS_SECTION, "enabled", music_enabled)
	cfg.set_value(SETTINGS_SECTION, "volume", music_volume_linear)

	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()

	if cfg.load(SETTINGS_PATH) != OK:
		return

	music_enabled = cfg.get_value(SETTINGS_SECTION, "enabled", true)
	music_volume_linear = cfg.get_value(SETTINGS_SECTION, "volume", 1.0)


# -------------------------------------------------------------------
# UTILS
# -------------------------------------------------------------------

func _linear_to_db(value: float) -> float:
	if value <= 0:
		return -80
	return 20 * log(value) / log(10)


func play_writing_loop(interval: float = 1.1, volume_db: float = -22) -> void:

	if DataLoader.config.is_empty():
		return

	var sfx_config: Dictionary = DataLoader.config.get("audio", {}).get("sfx", {})
	if not sfx_config.has("paper"):
		push_warning("Paper key not found")
		return

	var path: String = DataLoader.resolve_client_path(sfx_config["paper"])
	var stream: AudioStream = load(path)

	if stream == null:
		push_warning("Paper not loaded")
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	player.volume_db = volume_db

	add_child(player)

	var timer := Timer.new()
	timer.wait_time = interval
	timer.autostart = true
	timer.one_shot = false

	timer.timeout.connect(func():
		if is_instance_valid(player):
			player.play()
	)

	add_child(timer)

	set_meta("writing_player", player)
	set_meta("writing_timer", timer)


func stop_writing_loop() -> void:

	if has_meta("writing_timer"):
		var t: Timer = get_meta("writing_timer")
		if is_instance_valid(t):
			t.stop()
			t.queue_free()

	if has_meta("writing_player"):
		var p: AudioStreamPlayer = get_meta("writing_player")
		if is_instance_valid(p):
			p.stop()
			p.queue_free()
