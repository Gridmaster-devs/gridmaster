extends Button

var root_ref

func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	root_ref.cur_set_cord = Vector2i(0, 0)
	root_ref.cur_source = 1
