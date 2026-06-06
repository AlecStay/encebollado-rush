extends Node
## Música persistente entre escenas. Como autoload sobrevive a change_scene, así
## la pista del menú no se reinicia al navegar entre menús: play() ignora si ya
## suena ese mismo stream. Loop manual (finished → replay) sirve para mp3 y wav.

const MENU_PATH := "res://music/mus_menu.mp3"

var _player: AudioStreamPlayer
var _current: AudioStream = null

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.finished.connect(_on_finished)

func play(stream: AudioStream) -> void:
	if stream == null:
		return
	if stream == _current and _player.playing:
		return
	_current = stream
	_player.stream    = stream
	_player.volume_db = SettingsManager.get_music_db()
	_player.play()

func play_path(path: String) -> void:
	if ResourceLoader.exists(path):
		play(load(path))

func play_menu() -> void:
	play_path(MENU_PATH)

func set_volume_db(db: float) -> void:
	if _player:
		_player.volume_db = db

func stop() -> void:
	_current = null
	if _player:
		_player.stop()

func _on_finished() -> void:
	if _current and _player.stream == _current:
		_player.play()
