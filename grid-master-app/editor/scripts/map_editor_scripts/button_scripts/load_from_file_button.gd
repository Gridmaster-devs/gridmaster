extends Node

@onready var parent_ref = $"../../../../../../.."

func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	if parent_ref.cur_gw == parent_ref.GridView.STRATEGIC: 
		parent_ref.load_button_pressed()
	
	
