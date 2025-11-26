extends Button

@onready var root_cntr = get_node("/root/MapEditor")

var source = 0
var set_cord_x = 0
var set_cord_y = 0

func _ready() -> void:
	self.pressed.connect(_on_button_pressed)

	
func _on_button_pressed():
	root_cntr.cur_set_cord = Vector2i(set_cord_x, set_cord_y)
	root_cntr.cur_source = source
