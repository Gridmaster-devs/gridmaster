extends Node


@onready var parent_ref = $"../../../../../../.."

func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	var settings_popup = preload("res://editors/map_editor/popup_windows/settings.tscn").instantiate()
	get_tree().get_root().add_child(settings_popup)
	settings_popup.name = "settings_popup"
	settings_popup.parent_ref = parent_ref
	
