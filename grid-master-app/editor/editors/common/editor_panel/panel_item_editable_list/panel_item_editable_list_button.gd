class_name PanelItemEditableListButton
extends Button
## Adds ID field to button, necessary for chosen item remove button in PanelItemEditableList

signal pressed_with_id(id: int)

var id: int

func _pressed():
	pressed_with_id.emit(id)
	
func _init(item_id: int):
	id = item_id
