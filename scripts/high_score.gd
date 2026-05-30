extends Control

const _COLOR_NORMAL := Color(0.91, 0.91, 0.82)
const _COLOR_HOVER  := Color(1.00, 0.85, 0.00)
const _COLOR_ACCENT := Color(1.00, 0.42, 0.21)
const _COLOR_SHADOW := Color(0.10, 0.10, 0.18)

@onready var _score_list: VBoxContainer = $ScoreList
@onready var _btn_volver: Button        = $BtnVolver
@onready var _title: Label              = $Title

func _ready() -> void:
	_apply_theme()
	_populate_scores()
	_btn_volver.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)

func _apply_theme() -> void:
	var empty := StyleBoxEmpty.new()
	var btn_theme := Theme.new()
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn_theme.set_stylebox(state, "Button", empty)
	btn_theme.set_color("font_color", "Button", _COLOR_NORMAL)
	btn_theme.set_color("font_hover_color", "Button", _COLOR_HOVER)
	btn_theme.set_color("font_pressed_color", "Button", _COLOR_ACCENT)
	btn_theme.set_color("font_focus_color", "Button", _COLOR_HOVER)
	btn_theme.set_constant("outline_size", "Button", 2)
	btn_theme.set_color("font_outline_color", "Button", _COLOR_SHADOW)
	btn_theme.set_font_size("font_size", "Button", 13)
	_btn_volver.theme = btn_theme

	var lbl_theme := Theme.new()
	lbl_theme.set_color("font_color", "Label", _COLOR_NORMAL)
	lbl_theme.set_constant("outline_size", "Label", 2)
	lbl_theme.set_color("font_outline_color", "Label", _COLOR_SHADOW)
	lbl_theme.set_font_size("font_size", "Label", 14)
	_title.theme = lbl_theme

func _populate_scores() -> void:
	var scores := HighScoreManager.get_scores()

	var row_theme := Theme.new()
	row_theme.set_color("font_color", "Label", _COLOR_NORMAL)
	row_theme.set_constant("outline_size", "Label", 2)
	row_theme.set_color("font_outline_color", "Label", _COLOR_SHADOW)
	row_theme.set_font_size("font_size", "Label", 11)

	if scores.is_empty():
		var lbl := Label.new()
		lbl.text = "No hay puntajes aún. ¡Juega una partida!"
		lbl.theme = row_theme
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_score_list.add_child(lbl)
		return

	for i: int in range(scores.size()):
		var entry: Dictionary = scores[i]
		var row := HBoxContainer.new()
		row.theme = row_theme
		row.add_theme_constant_override("separation", 8)

		var rank := Label.new()
		rank.text = "#%d" % (i + 1)
		rank.custom_minimum_size = Vector2(28, 0)

		var score_lbl := Label.new()
		score_lbl.text = "%d pts" % int(entry.get("score", 0))
		score_lbl.custom_minimum_size = Vector2(60, 0)
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		var date_lbl := Label.new()
		date_lbl.text = entry.get("date", "")
		date_lbl.custom_minimum_size = Vector2(90, 0)
		date_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		date_lbl.modulate.a = 0.7

		var status_lbl := Label.new()
		var won: bool = entry.get("won", false)
		status_lbl.text = "GANÓ" if won else "PERDIÓ"
		status_lbl.modulate = _COLOR_HOVER if won else _COLOR_ACCENT

		row.add_child(rank)
		row.add_child(score_lbl)
		row.add_child(date_lbl)
		row.add_child(status_lbl)
		_score_list.add_child(row)
