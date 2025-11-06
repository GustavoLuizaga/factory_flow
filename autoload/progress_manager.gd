extends Node
const SAVE_PATH := "user://save.json"

var highest_unlocked := 1  # nivel máximo desbloqueado

func _ready() -> void:
	_load()

func unlock(level:int) -> void:
	if level > highest_unlocked:
		highest_unlocked = level
		_save()

func is_unlocked(level:int) -> bool:
	return level <= highest_unlocked

func _save() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"highest_unlocked": highest_unlocked}))
		f.close()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var d = JSON.parse_string(f.get_as_text())
		if typeof(d) == TYPE_DICTIONARY:
			highest_unlocked = int(d.get("highest_unlocked", 1))
		f.close()
