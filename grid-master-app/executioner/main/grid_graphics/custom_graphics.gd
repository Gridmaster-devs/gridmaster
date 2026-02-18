class_name CustomGraphics
extends Node2D
## Class that stores custom draw commands and executes them

const MOVEMENT_PATH_OUTSIDE_THICKNESS : int = 8
const MOVEMENT_PATH_OUTSIDE_COLOR : Color = Color(0.6, 0.6, 0.6)
const MOVEMENT_PATH_INSIDE_THICKNESS : int = 4
const MOVEMENT_PATH_INSIDE_COLOR : Color = Color(0.2, 0.2, 0.2)

## The draw commands to be executed
var _draw_commands : Array[Callable]
var _tile_size : int = GridGraphics.TILE_SIZE

var movement_target := ImageTexture.create_from_image(Image.load_from_file("res://executioner/media/movement_target_128.png"))
var movement_waypoint := ImageTexture.create_from_image(Image.load_from_file("res://executioner/media/movement_waypoint_128.png"))


func draw_movement_tiles(tiles : Array[Vector2i]):
	var draw_func = func():
		for tile : Vector2i in tiles:
			draw_texture(movement_target, tile * GridGraphics.TILE_SIZE)
	
	add_draw_command(draw_func)


func draw_waypoint(pos : Vector2i):
	var draw_func = func():
		draw_texture(movement_waypoint, pos * GridGraphics.TILE_SIZE)
	
	add_draw_command(draw_func)


func draw_movement_path(path : Array[Vector2i]):
	var point_path : PackedVector2Array = []
	for point : Vector2i in path:
		point_path.append((point * _tile_size) + Vector2i(_tile_size / 2, _tile_size / 2)) 
	
	var draw_func = func():
		draw_polyline(point_path, MOVEMENT_PATH_OUTSIDE_COLOR, MOVEMENT_PATH_OUTSIDE_THICKNESS, true)
		draw_polyline(point_path, MOVEMENT_PATH_INSIDE_COLOR, MOVEMENT_PATH_INSIDE_THICKNESS, true)
	
	add_draw_command(draw_func)


## Adds a draw command to the array
func add_draw_command(command : Callable) -> void:
	_draw_commands.append(command)
	queue_redraw()


## Clears all draw commands from the array
func clear() -> void:
	_draw_commands.clear()
	queue_redraw()


func _draw() -> void:
	for command : Callable in _draw_commands:
		command.call()


func _ready() -> void:
	movement_target.set_size_override(Vector2(_tile_size, _tile_size))
	movement_waypoint.set_size_override(Vector2(_tile_size, _tile_size))
	
	draw_movement_path([Vector2i(1,0), Vector2i(2, 0), Vector2i(2,1), Vector2i(2,2), Vector2i(3,2)])
	
