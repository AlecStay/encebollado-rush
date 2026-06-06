extends Control

const _COLOR_NORMAL := Color(0.91, 0.91, 0.82)
const _COLOR_HOVER  := Color(1.00, 0.85, 0.00)
const _COLOR_ACCENT := Color(1.00, 0.42, 0.21)
const _COLOR_SHADOW := Color(0.10, 0.10, 0.18)

@onready var _score_list: VBoxContainer = $ScoreList
@onready var _btn_volver: Button        = $BtnVolver

func _ready() -> void:
	MusicManager.play_menu()
	_style_volver()
	_populate_scores()
	_btn_volver.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

func _style_volver() -> void:
	var empty := StyleBoxEmpty.new()
	var t := Theme.new()
	for s: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		t.set_stylebox(s, "Button", empty)
	t.set_color("font_color", "Button", _COLOR_NORMAL)
	t.set_color("font_hover_color", "Button", _COLOR_HOVER)
	t.set_color("font_pressed_color", "Button", _COLOR_ACCENT)
	t.set_constant("outline_size", "Button", 3)
	t.set_color("font_outline_color", "Button", _COLOR_SHADOW)
	t.set_font_size("font_size", "Button", 13)
	_btn_volver.theme = t

func _populate_scores() -> void:
	var scores := HighScoreManager.get_all_scores()
	for i in range(GameState.LEVELS.size()):
		var lvl_name: String = GameState.LEVELS[i].name
		var data: Dictionary = scores.get(str(i), {"score": 0, "spondylus": 0})

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var name_lbl := Label.new()
		name_lbl.text = "%d. %s" % [i + 1, lvl_name]
		name_lbl.custom_minimum_size = Vector2(132, 0)
		name_lbl.clip_text = true
		_style_row_label(name_lbl, _COLOR_NORMAL)

		var score_lbl := Label.new()
		score_lbl.text = _commas(int(data.get("score", 0)))
		score_lbl.custom_minimum_size = Vector2(44, 0)
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_style_row_label(score_lbl, _COLOR_HOVER)

		row.add_child(name_lbl)
		row.add_child(score_lbl)
		_score_list.add_child(row)

func _style_row_label(lbl: Label, color: Color) -> void:
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", _COLOR_SHADOW)
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_font_size_override("font_size", 12)

func _commas(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return out
