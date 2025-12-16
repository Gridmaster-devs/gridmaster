extends Node


@onready var parent_ref = $"../../../../../../../.."
var tactical_grid_name = ""

func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	parent_ref.load_tactical_grid(parent_ref.cur_tactical_grid_name)
