extends Control

var dragging := false
var drag_offset := Vector2.ZERO
var parent_ref = null

@onready var line_edit = $"EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Tactical map name/HBoxContainer/tactical_grid_name_line_edit"

func init(parent_path: String): 
	parent_ref = get_node(parent_path)

func set_tactical_grid_name(grid_name: String): 
	line_edit.text = grid_name


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
