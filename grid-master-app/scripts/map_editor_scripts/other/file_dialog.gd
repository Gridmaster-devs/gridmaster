extends FileDialog

var parent_ref = null

func _ready() -> void:
	file_mode = FileDialog.FILE_MODE_SAVE_FILE
	access = FileDialog.ACCESS_FILESYSTEM
	filters = PackedStringArray(["*.tres ; GameMap resource"])

func _on_file_selected(path: String) -> void:
	if parent_ref and parent_ref.has_method("save_game_map"):
		parent_ref.save_game_map(path)
	else:
		push_error("parent_ref is invalid or missing save_game_map()")
