extends Node

var music_player : AudioStreamPlayer
var sfx_player : AudioStreamPlayer


func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)


func play_music(stream: AudioStream, volume_db := -10):
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()


func play_sfx(stream: AudioStream, volume_db := -5):
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	sfx_player.play()


func stop_music():
	music_player.stop()
