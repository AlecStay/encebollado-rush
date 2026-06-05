extends Control

const _COLOR_NORMAL := Color(0.91, 0.91, 0.82)
const _COLOR_HOVER  := Color(1.00, 0.85, 0.00)
const _COLOR_ACCENT := Color(1.00, 0.42, 0.21)
const _COLOR_DESC   := Color(0.80, 0.76, 0.64)
const _COLOR_SHADOW := Color(0.10, 0.10, 0.18)

@onready var _btn_volver: Button = $BtnVolver
@onready var _list: VBoxContainer = $ScrollContainer/List
@onready var _emeralds_label: Label = $EmeraldsLabel

const BOARDS = [
	{ "id": "standard", "name": "Estándar", "desc": "Sin buff", "price": 0 },
	{ "id": "corriente_nino", "name": "Corriente del Niño", "desc": "+30% Velocidad", "price": 5000 },
	{ "id": "caparazon_spondylus", "name": "Caparazón Spondylus", "desc": "-50% Daño", "price": 10000 },
	{ "id": "rugido_jaguar", "name": "Rugido del Jaguar", "desc": "Puntos x1.5", "price": 15000 },
	{ "id": "mistica_umina", "name": "Mística Umiña", "desc": "Bonus +50%", "price": 20000 }
]

func _ready() -> void:
	_style_back_button(_btn_volver)
	_btn_volver.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	_update_ui()

# Invisible hotspot over the baked "VOLVER" art: no default gray hover box,
# just a soft gold glow on hover so the button still gives feedback.
func _style_back_button(btn: Button) -> void:
	var empty := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1.0, 0.85, 0.0, 0.22)
	hover.set_corner_radius_all(6)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(1.0, 0.85, 0.0, 0.34)
	pressed.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_stylebox_override("disabled", empty)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)

func _update_ui() -> void:
	_emeralds_label.text = "Energía Ancestral: %d" % SettingsManager.ancestral_energy
	for child in _list.get_children():
		child.queue_free()

	for board in BOARDS:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)

		var name_lbl = _make_label(board.name, 112, _COLOR_NORMAL)
		var desc_lbl = _make_label(board.desc, 86, _COLOR_DESC)

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(72, 0)
		_style_flat_button(btn)

		var is_unlocked = board.id in SettingsManager.unlocked_boards
		var is_equipped = (SettingsManager.equipped_board == board.id)

		if is_equipped:
			btn.text = "EQUIPADO"
			btn.disabled = true
			btn.add_theme_color_override("font_disabled_color", _COLOR_HOVER)
		elif is_unlocked:
			btn.text = "EQUIPAR"
			btn.pressed.connect(func():
				SettingsManager.equipped_board = board.id
				SettingsManager.save_settings()
				_update_ui()
			)
		else:
			btn.text = "COMPRAR (%d)" % board.price
			if SettingsManager.ancestral_energy >= board.price:
				btn.pressed.connect(func():
					SettingsManager.ancestral_energy -= board.price
					SettingsManager.unlocked_boards.append(board.id)
					SettingsManager.save_settings()
					_update_ui()
				)
			else:
				btn.disabled = true
				btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.5, 0.45))

		row.add_child(name_lbl)
		row.add_child(desc_lbl)
		row.add_child(btn)
		_list.add_child(row)

func _make_label(txt: String, w: int, color: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.custom_minimum_size = Vector2(w, 0)
	l.clip_text = true
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", _COLOR_SHADOW)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_font_size_override("font_size", 11)
	return l

func _style_flat_button(btn: Button) -> void:
	var t := Theme.new()
	var empty := StyleBoxEmpty.new()
	for s: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		t.set_stylebox(s, "Button", empty)
	t.set_color("font_color", "Button", _COLOR_HOVER)
	t.set_color("font_hover_color", "Button", Color(1, 1, 0.6))
	t.set_color("font_pressed_color", "Button", _COLOR_ACCENT)
	t.set_constant("outline_size", "Button", 3)
	t.set_color("font_outline_color", "Button", _COLOR_SHADOW)
	t.set_font_size("font_size", "Button", 10)
	btn.theme = t

func debug_refresh() -> void:
	_update_ui()
