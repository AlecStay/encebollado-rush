extends Control

const _COLOR_NORMAL := Color(0.91, 0.91, 0.82)
const _COLOR_HOVER  := Color(1.00, 0.85, 0.00)

@onready var _btn_volver: Button = $BtnVolver
@onready var _list: VBoxContainer = $ScrollContainer/List
@onready var _emeralds_label: Label = $EmeraldsLabel

const BOARDS = [
	{ "id": "standard", "name": "Estándar", "desc": "Sin buff", "price": 0 },
	{ "id": "corriente_nino", "name": "Corriente del Niño", "desc": "+30% Velocidad", "price": 5000 },
	{ "id": "caparazon_spondylus", "name": "Caparazón Spondylus", "desc": "-50% Daño Recibido", "price": 10000 },
	{ "id": "rugido_jaguar", "name": "Rugido del Jaguar", "desc": "Puntos x1.5", "price": 15000 },
	{ "id": "mistica_umina", "name": "Mística Umiña", "desc": "Duración Bonus +50%", "price": 20000 }
]

func _ready() -> void:
	_btn_volver.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	_update_ui()

func _update_ui() -> void:
	_emeralds_label.text = "Energía Ancestral: %d" % SettingsManager.ancestral_energy
	for child in _list.get_children():
		child.queue_free()
	
	for board in BOARDS:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 15)
		
		var name_lbl = Label.new()
		name_lbl.text = board.name
		name_lbl.custom_minimum_size = Vector2(160, 0)
		name_lbl.add_theme_color_override("font_color", _COLOR_NORMAL)
		
		var desc_lbl = Label.new()
		desc_lbl.text = board.desc
		desc_lbl.custom_minimum_size = Vector2(130, 0)
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 0)
		
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
		
		row.add_child(name_lbl)
		row.add_child(desc_lbl)
		row.add_child(btn)
		_list.add_child(row)
