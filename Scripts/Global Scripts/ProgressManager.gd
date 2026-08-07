extends Node

signal progress_changed

var completed_flags: Dictionary[StringName, bool] = {}

func complete(flag: StringName) -> void:
	if completed_flags.get(flag, false):
		return
	
	completed_flags[flag] = true
	progress_changed.emit()

func has_completed(flag: StringName) -> bool:
	return completed_flags.get(flag, false)
