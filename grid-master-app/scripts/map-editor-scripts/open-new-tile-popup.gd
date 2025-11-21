extends Button



@onready var color_picker = $CanvasLayer/ColorPicker
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.pressed.connect(_on_Button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.

func _on_Button_pressed():
	var new_tile_popup = preload("res://editors/map_editor/create_new_tile.tscn").instantiate()
	get_tree().get_root().add_child(new_tile_popup)
	new_tile_popup.name = "create_new_tile_popup"
