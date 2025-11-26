extends Control

@onready var tile_map = $VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer/SubViewport/TileMapLayer
@onready var cam = $VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer/SubViewport/Camera2D
@onready var subview = $VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer/SubViewport

@onready var cur_set_cord := Vector2i(0,0)
@onready var cur_source := 0

@export var grid_color: Color = Color(1, 1, 1, 0.3)

var dragging = false

func _ready():
	$VBoxContainer/HBoxContainer/Panel/VBoxContainer/Button5.root_ref = self


func get_tile_position() -> Vector2i:
	var subview_pos = subview.get_mouse_position()
	var world_pos = (subview_pos / cam.zoom) + cam.position
	var tile_pos = tile_map.local_to_map(tile_map.to_local(world_pos))
	return tile_pos

func is_mouse_blocking() -> bool: 
	if get_viewport().gui_get_hovered_control() != null: 
		return true
	return false

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed == true:
				tile_map.set_cell(get_tile_position(), cur_source, cur_set_cord, 0)
				dragging = true
			else:
				dragging = false
	if dragging and event is InputEventMouseMotion:
		tile_map.set_cell(get_tile_position(), cur_source, cur_set_cord, 0)
