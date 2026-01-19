extends Node

@onready var parent_ref = $"../../../../.."
@onready var tactical_grid_name = $"../Tactical map name/HBoxContainer/tactical_grid_name_line_edit"

func _ready() -> void:
	self.pressed.connect(_on_button_pressed)


	
func _on_button_pressed():
	parent_ref.parent_ref.save_tactical_grid(tactical_grid_name.text)
	parent_ref.queue_free()
