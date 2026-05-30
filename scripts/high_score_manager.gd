extends Node

const SAVE_PATH := "user://highscores.json"
const MAX_SCORES := 10

func save_score(score: int, won: bool) -> void:
	var scores := get_scores()
	scores.append({"score": score, "won": won, "date": Time.get_date_string_from_system()})
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	if scores.size() > MAX_SCORES:
		scores = scores.slice(0, MAX_SCORES)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(scores))

func get_scores() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		return []
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var result = JSON.parse_string(file.get_as_text())
	return result if result is Array else []
