@abstract
class_name PopupWindow
extends Control
##id
var _name: String = "unknown"

##draggable variables
var dragging := false
var drag_offset := Vector2.ZERO

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_offset = get_global_mouse_position() - global_position
			else:
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() - drag_offset

func set_popup_name(new_name: String) -> void: 
	_name = new_name

func get_popup_name() -> String: 
	return _name

func add_to_tree() -> void:
	Global.popup_manager.add_popup(self)

func remove_from_tree() -> void: 
	Global.popup_manager.close_popup(self)

#CALL SET_POPUP_NAME() when extending
@abstract func _init() -> void

func center() -> void:
	position = (get_viewport_rect().size - size) / 2
