extends Button

var parent_ref = null

var source = 0
var set_cord_x = 0
var set_cord_y = 0

func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	parent_ref.cur_set_cord = Vector2i(set_cord_x, set_cord_y)
	parent_ref.cur_source = source
	parent_ref.interacting = false
