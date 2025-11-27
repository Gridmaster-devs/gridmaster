extends Node


@onready var tile_lib = $"../.."
@onready var parent_ref = $"../../../../../../../../../.."

func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	var new_tile_popup = preload("res://editors/map_editor/popup_windows/new_tile.tscn").instantiate()
	get_tree().get_root().add_child(new_tile_popup)
	new_tile_popup.name = "create_new_tile_popup"
	new_tile_popup.tile_lib = tile_lib
	new_tile_popup.parent_ref = parent_ref
	
