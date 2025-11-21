extends Node2D

@onready var tile_map = $TileMapLayer
@onready var cam = $Camera2D

@onready var cur_set_cord := Vector2i(0,0)
@onready var cur_source := 0

@export var grid_color: Color = Color(1, 1, 1, 0.3)

func _ready():
	queue_redraw()
	$CanvasLayer/Panel/VBoxContainer/Button.root_ref = self
	$CanvasLayer/Panel/VBoxContainer/Button2.root_ref = self
	$CanvasLayer/Panel/VBoxContainer/Button3.root_ref = self
	$CanvasLayer/Panel/VBoxContainer/Button5.root_ref = self

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if get_viewport().gui_get_hovered_control() != null: 
				return
			var local_pos = tile_map.to_local(get_viewport().get_mouse_position() + cam.position)
			var grid_pos = tile_map.local_to_map(local_pos)
			
			tile_map.set_cell(grid_pos, cur_source, cur_set_cord, 0)
			
func _draw():
	
