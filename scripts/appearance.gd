extends Control

const _COLOR_NORMAL := Color(0.91, 0.91, 0.82)
const _COLOR_HOVER  := Color(1.00, 0.85, 0.00)
const _COLOR_ACCENT := Color(1.00, 0.42, 0.21)
const _COLOR_SHADOW := Color(0.10, 0.10, 0.18)

@onready var _cards: HBoxContainer = $CardsRow
@onready var _btn_volver: Button   = $BtnVolver
@onready var _title: Label         = $Title
@onready var _energy: Label        = $Energy

func _ready() -> void:
	_title.add_theme_color_override("font_color", _COLOR_NORMAL)
	_title.add_theme_color_override("font_outline_color", _COLOR_SHADOW)
	_title.add_theme_constant_override("outline_size", 3)
	_title.add_theme_font_size_override("font_size", 16)
	_energy.add_theme_color_override("font_color", _COLOR_HOVER)
	_energy.add_theme_color_override("font_outline_color", _COLOR_SHADOW)
	_energy.add_theme_constant_override("outline_size", 2)
	_energy.add_theme_font_size_override("font_size", 10)
	_style_button(_btn_volver)
	_btn_volver.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	_build()

func _build() -> void:
	for c in _cards.get_children():
		c.queue_free()

	_energy.text = "Energía Ancestral: %d" % SettingsManager.ancestral_energy

	for id: String in SettingsManager.SKIN_ORDER:
		var info: Dictionary = SettingsManager.SKINS[id]
		var unlocked: bool = id in SettingsManager.unlocked_skins
		var equipped: bool = (SettingsManager.equipped_skin == id)
		var price: int = info.get("price", 0)

		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(104, 0)
		card.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_theme_constant_override("separation", 6)

		var frame := PanelContainer.new()
		frame.custom_minimum_size = Vector2(72, 72)
		frame.add_theme_stylebox_override("panel", _card_style(equipped))

		var preview := TextureRect.new()
		preview.custom_minimum_size = Vector2(64, 64)
		preview.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.modulate = Color(1, 1, 1, 1) if unlocked else Color(1, 1, 1, 0.35)
		if ResourceLoader.exists(info.preview):
			preview.texture = load(info.preview)
		frame.add_child(preview)

		var name_lbl := Label.new()
		name_lbl.text = info.name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_color_override("font_color", _COLOR_HOVER if equipped else _COLOR_NORMAL)
		name_lbl.add_theme_color_override("font_outline_color", _COLOR_SHADOW)
		name_lbl.add_theme_constant_override("outline_size", 2)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(92, 26)
		_style_button(btn)
		if equipped:
			btn.text = "EQUIPADO"
			btn.disabled = true
			btn.add_theme_color_override("font_disabled_color", _COLOR_HOVER)
		elif unlocked:
			btn.text = "EQUIPAR"
			btn.pressed.connect(func() -> void:
				SettingsManager.equipped_skin = id
				SettingsManager.save_settings()
				_build())
		else:
			btn.text = "COMPRAR (%d)" % price
			if SettingsManager.ancestral_energy >= price:
				btn.pressed.connect(func() -> void:
					SettingsManager.ancestral_energy -= price
					SettingsManager.unlocked_skins.append(id)
					SettingsManager.save_settings()
					_build())
			else:
				btn.disabled = true

		card.add_child(frame)
		card.add_child(name_lbl)
		card.add_child(btn)
		_cards.add_child(card)

func _card_style(equipped: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.20, 0.85)
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(2)
	sb.border_color = _COLOR_HOVER if equipped else Color(0.30, 0.34, 0.46)
	sb.set_content_margin_all(4)
	return sb

func _style_button(btn: Button) -> void:
	var t := Theme.new()
	var empty := StyleBoxEmpty.new()
	for s: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		t.set_stylebox(s, "Button", empty)
	t.set_color("font_color",         "Button", _COLOR_NORMAL)
	t.set_color("font_hover_color",   "Button", _COLOR_HOVER)
	t.set_color("font_pressed_color", "Button", _COLOR_ACCENT)
	t.set_constant("outline_size",    "Button", 2)
	t.set_color("font_outline_color", "Button", _COLOR_SHADOW)
	t.set_font_size("font_size",      "Button", 12)
	btn.theme = t

func debug_refresh() -> void:
	_build()
