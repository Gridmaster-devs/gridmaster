extends Node

@onready var parent_ref = $"../../../../../../../.."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	var add_color_popup = preload("res://editor/editors/map_editor/tile_color_picker.tscn").instantiate()
	get_tree().get_root().add_child(add_color_popup)
	add_color_popup.name = "add_tile_color_popup"
	add_color_popup.parent_ref = parent_ref
	
