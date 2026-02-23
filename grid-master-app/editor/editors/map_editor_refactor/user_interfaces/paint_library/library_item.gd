extends Node
class_name LibraryItem


@onready var _button_label: Label = $Label
@onready var _button: Button = $Button

#signals
signal item_right_clicked 

func set_data(new_name: String, new_texture: Texture2D) -> void: 
	_set_name(new_name)
	_set_texture(new_texture)

func _set_name(new_name: String) -> void: 
	_button_label.text = new_name

func _set_texture(tex: Texture2D) -> void: 
	_button.icon = tex
	_button.expand_icon = true
	


func _input(event: InputEvent) -> void: 
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed == true:
			item_right_clicked.emit()
	

func get_button() -> Node: 
	return _button
