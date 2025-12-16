extends Node

var tact_options = null
var parent_ref = null
var tactical_grid_name: String = ""

func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	
	if tact_options.visible == true: 
		tact_options.visible = false
		parent_ref.set_cur_selected_tactical_grid("")
		parent_ref.change_input_state(parent_ref.InputState.PAINT_TILE)
	else: 
		tact_options.visible = true  
		parent_ref.set_cur_selected_tactical_grid(tactical_grid_name)
		parent_ref.change_input_state(parent_ref.InputState.PAINT_TACTICAL)
	
	
