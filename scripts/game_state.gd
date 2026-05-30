extends Node

var current_level := 0

const LEVELS: Array = [
	{
		"name":           "Amanecer",
		"water_modulate": Color(0.78, 0.88, 1.00),
		"sand_modulate":  Color(1.00, 0.80, 0.58),
		"ambient":        Color(1.00, 0.85, 0.70),
		"sun_x":          80.0,
		"sun_y":          22.0,
		"is_night":       false,
	},
	{
		"name":           "Tarde",
		"water_modulate": Color(1.00, 1.00, 1.00),
		"sand_modulate":  Color(1.00, 0.96, 0.80),
		"ambient":        Color(1.00, 1.00, 0.97),
		"sun_x":          240.0,
		"sun_y":          12.0,
		"is_night":       false,
	},
	{
		"name":           "Atardecer",
		"water_modulate": Color(1.00, 0.68, 0.44),
		"sand_modulate":  Color(1.00, 0.58, 0.35),
		"ambient":        Color(1.00, 0.72, 0.50),
		"sun_x":          400.0,
		"sun_y":          24.0,
		"is_night":       false,
	},
	{
		"name":           "Anochecer",
		"water_modulate": Color(0.18, 0.24, 0.55),
		"sand_modulate":  Color(0.32, 0.35, 0.50),
		"ambient":        Color(0.45, 0.50, 0.75),
		"sun_x":          390.0,
		"sun_y":          16.0,
		"is_night":       true,
	},
]
