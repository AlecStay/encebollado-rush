extends Node

const SAVE_PATH := "user://highscores_v2.json"

func save_score(level_idx: int, score: int, spondylus: int) -> void:
	var data := get_all_scores()
	var key := str(level_idx)
	var current: Dictionary = data.get(key, {"score": 0, "spondylus": 0})
	
	current["score"] = max(int(current.get("score", 0)), score)
	current["spondylus"] = max(int(current.get("spondylus", 0)), spondylus)
	data[key] = current
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func get_all_scores() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var result = JSON.parse_string(file.get_as_text())
	return result if result is Dictionary else {}
