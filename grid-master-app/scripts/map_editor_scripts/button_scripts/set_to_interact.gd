extends Node

@onready var parent_ref = $"../../../../../../.."


func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	parent_ref.change_input_state(parent_ref.InputState.INTERACT)
