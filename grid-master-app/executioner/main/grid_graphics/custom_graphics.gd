class_name CustomGraphics
extends Node2D
## Class that stores custom draw commands and executes them

## The draw commands to be executed
var _draw_commands : Array[Callable]

var movement_target := ImageTexture.create_from_image(Image.load_from_file("res://executioner/media/movement_target_128.png"))
var movement_waypoint := ImageTexture.create_from_image(Image.load_from_file("res://executioner/media/movement_waypoint_128.png"))


func draw_movement_tiles(tiles : Array[Vector2i]):
	var draw_func = func():
		for tile : Vector2i in tiles:
			draw_texture(movement_target, tile * GridGraphics.TILE_SIZE)
	
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
	var ts = GridGraphics.TILE_SIZE
	movement_target.set_size_override(Vector2(ts, ts))
	movement_waypoint.set_size_override(Vector2(ts, ts))
