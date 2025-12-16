extends Button

var parent_ref = null

var source = 0

func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	parent_ref.cur_source = source
	parent_ref.input_state = parent_ref.InputState.PAINT_TILE
