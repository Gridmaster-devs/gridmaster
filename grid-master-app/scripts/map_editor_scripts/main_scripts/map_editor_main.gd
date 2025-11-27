extends Control

@onready var tile_map = $VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer/SubViewport/TileMapLayer
@onready var grid_tile_map = $VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer/SubViewport/TileMapGrid
@onready var cam = $VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer/SubViewport/Camera2D
@onready var subview = $VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer/SubViewport
@onready var subview_cont = $VBoxContainer/HBoxContainer/SubViewControl/SubViewportContainer

@onready var cur_set_cord := Vector2i(0,0)
@onready var cur_source := -1
@onready var interacting := false

@export var width = 100
@export var height = 100

#tile description: 
@onready var tile_name_ui = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Current tile/Name/HBoxContainer/LineEdit"
@onready var tile_protection_ui = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Current tile/Protection/HBoxContainer/LineEdit"
@onready var tile_movement_ui = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Current tile/Movement/HBoxContainer/LineEdit"
@onready var tile_hiding_ui = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Current tile/Hiding/HBoxContainer/LineEdit"
@onready var tile_image_ui = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Current tile/image_hbox/TextureRect"
@onready var tile_dimage_ui = $"VBoxContainer/HBoxContainer/EditorPanel/TopVBox/ScrollContainer/ContentsVBox/Current tile/dimage_hbox/TextureRect"


var tile_info_grid: Array = []
var tile_info_map: Dictionary = {}

var dragging = false

func _ready():
	resize(width, height)
	tile_info_grid.clear() 
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(TileInformation.new())
		tile_info_grid.append(row)

func resize(x: int, y: int): 
	width = x
	height = y
	grid_tile_map.resize()

func get_tile_position() -> Vector2i:
	var subview_pos = subview.get_mouse_position()
	var world_pos = (subview_pos / cam.zoom) + cam.position
	var tile_pos = tile_map.local_to_map(tile_map.to_local(world_pos))
	return tile_pos

func is_mouse_blocking() -> bool: 
	if get_viewport().gui_get_hovered_control() != subview_cont: 
		return true
	return false

func handle_mouse_left_paint(): 
	var tile_pos = get_tile_position()
	if grid_tile_map.get_cell_source_id(tile_pos) != -1:
		tile_map.set_cell(tile_pos, cur_source, cur_set_cord, 0)
		if cur_source == -1:
			tile_info_grid[tile_pos.y][tile_pos.x] = TileInformation.new()
		else: 
			tile_info_grid[tile_pos.y][tile_pos.x] = tile_info_map[cur_source]
		dragging = true
	else:
		dragging = false

func _input(event):
	if is_mouse_blocking(): 
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true:
			if interacting: 
				var tile_pos = get_tile_position()
				var cur_tile = tile_info_grid[tile_pos.y][tile_pos.x]
				if cur_tile.name.is_empty(): 
					tile_name_ui.text = ""
					tile_hiding_ui.text = ""
					tile_protection_ui.text = ""
					tile_movement_ui.text = ""
					tile_image_ui.texture = Texture2D.new()
				else:
					tile_name_ui.text = cur_tile.name
					tile_hiding_ui.text = str(cur_tile.hiding)
					tile_protection_ui.text = str(cur_tile.protection)
					tile_movement_ui.text = str(cur_tile.movement)
					tile_image_ui.texture = cur_tile.texture
			else:
				handle_mouse_left_paint()
		else:
			dragging = false

	if dragging and event is InputEventMouseMotion:
		var tile_pos = get_tile_position()
		if grid_tile_map.get_cell_source_id(tile_pos) != -1:
			tile_map.set_cell(tile_pos, cur_source, cur_set_cord, 0)
			if cur_source == -1:
				tile_info_grid[tile_pos.y][tile_pos.x] = TileInformation.new()
			else: 
				tile_info_grid[tile_pos.y][tile_pos.x] = tile_info_map[cur_source]
