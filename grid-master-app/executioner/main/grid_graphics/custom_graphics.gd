class_name CustomGraphics
extends Node2D
## Class that stores, processes, and executes custom draw commands
##
## A draw command has an ID which it can later be removed with,
## a priority which defines the order in which order the draw commands are executed,
## and the draw command itself

# IDs 0 and up are reserved for units
# ID -1 is used for the hovering cursor

const TILE_CURSOR_ID : int = -1
const TILE_CURSOR_PRIORITY : int = 10

const MOVEMENT_PATH_PRIORITY : int = 2
const MOVEMENT_PATH_OUTSIDE_THICKNESS : int = 8
const MOVEMENT_PATH_OUTSIDE_COLOR : Color = Color(0.6, 0.6, 0.6)
const MOVEMENT_PATH_INSIDE_THICKNESS : int = 4
const MOVEMENT_PATH_INSIDE_COLOR : Color = Color(0.2, 0.2, 0.2)

const MOVEMENT_PATH_SMALL_PRIORITY : int = 0
const MOVEMENT_PATH_SMALL_OUTSIDE_THICKNESS : int = 8
const MOVEMENT_PATH_SMALL_OUTSIDE_COLOR : Color = Color(0.6, 0.6, 0.6, 0.5)
const MOVEMENT_PATH_SMALL_INSIDE_THICKNESS : int = 4
const MOVEMENT_PATH_SMALL_INSIDE_COLOR : Color = Color(0.2, 0.2, 0.2, 0.5)

const MOVEMENT_WAYPOINT_PRIORITY : int = 3
const MOVEMENT_TILE_PRIORTIY : int = 2


## The draw commands to be executed
var _draw_commands : Array[CustomGraphicsCommand]
var _tile_size : int = GridGraphics.TILE_SIZE



var movement_target : ImageTexture = ImageTexture.create_from_image(preload("res://executioner/media/movement_target_128.png").get_image())
var movement_waypoint : ImageTexture = ImageTexture.create_from_image(preload("res://executioner/media/movement_waypoint_128.png").get_image())
var selected_tile : ImageTexture = ImageTexture.create_from_image(preload("res://executioner/media/selected_tile_128.png").get_image())


func draw_tile_cursor(pos : Vector2i):
	if (pos == Vector2i(-1, -1)): return
	
	clear_id(TILE_CURSOR_ID)
	var draw_func = func():
		draw_texture(selected_tile, pos * GridGraphics.TILE_SIZE)
	
	add_draw_command(draw_func, TILE_CURSOR_ID, TILE_CURSOR_PRIORITY)


func draw_movement_tiles(tiles : Array[Vector2i], id : int):
	var draw_func = func():
		for tile : Vector2i in tiles:
			draw_texture(movement_target, tile * GridGraphics.TILE_SIZE)
	
	add_draw_command(draw_func, id, MOVEMENT_TILE_PRIORTIY)


func draw_waypoints(positions : Array[Vector2i], id : int):
	var draw_func = func():
		for pos in positions:
			draw_texture(movement_waypoint, pos * GridGraphics.TILE_SIZE)
	
	add_draw_command(draw_func, id, MOVEMENT_WAYPOINT_PRIORITY)


func draw_movement_path(path : Array[Vector2i], id : int):
	if path.size() < 2: return
	
	var point_path : PackedVector2Array = []
	for point : Vector2i in path:
		point_path.append((point * _tile_size) + Vector2i(_tile_size / 2, _tile_size / 2)) 
	
	var draw_func = func():
		draw_polyline(point_path, MOVEMENT_PATH_OUTSIDE_COLOR, MOVEMENT_PATH_OUTSIDE_THICKNESS, true)
		draw_polyline(point_path, MOVEMENT_PATH_INSIDE_COLOR, MOVEMENT_PATH_INSIDE_THICKNESS, true)
	
	add_draw_command(draw_func, id, MOVEMENT_PATH_PRIORITY)


func draw_movement_path_small(path : Array[Vector2i], id : int):
	if path.size() < 2: return
	
	var point_path : PackedVector2Array = []
	for point : Vector2i in path:
		point_path.append((point * _tile_size) + Vector2i(_tile_size / 2, _tile_size / 2))
	
	var draw_func = func():
		draw_polyline(point_path, MOVEMENT_PATH_SMALL_OUTSIDE_COLOR, MOVEMENT_PATH_SMALL_OUTSIDE_THICKNESS, true)
		draw_polyline(point_path, MOVEMENT_PATH_SMALL_INSIDE_COLOR, MOVEMENT_PATH_SMALL_INSIDE_THICKNESS, true)
	
	add_draw_command(draw_func, id, MOVEMENT_PATH_SMALL_PRIORITY)


## Adds a draw command to the array
func add_draw_command(command : Callable, id : int, priority : int) -> void:
	_draw_commands.append(CustomGraphicsCommand.new(command, id, priority))
	queue_redraw()


## Clears all draw commands from the array
func clear() -> void:
	_draw_commands.clear()
	queue_redraw()


func clear_id(id : int) -> void:
	_draw_commands = _draw_commands.filter(func(command : CustomGraphicsCommand): return command.id != id)
	queue_redraw()


func _draw() -> void:
	_draw_commands.sort_custom(CustomGraphicsCommand.sort_func)
	for command in _draw_commands:
		command.draw_command.call()


func _ready() -> void:
	movement_target.set_size_override(Vector2(_tile_size, _tile_size))
	movement_waypoint.set_size_override(Vector2(_tile_size, _tile_size))
	selected_tile.set_size_override(Vector2(_tile_size, _tile_size))

class CustomGraphicsCommand:
	var id : int
	var priority : int
	var draw_command : Callable
	
	# commands with a higher priority get drawn later, which is on top.
	static func sort_func(p1 : CustomGraphicsCommand, p2 : CustomGraphicsCommand):
		return p1.priority < p2.priority
	
	func _init(draw_command_p : Callable, id_p : int, priority_p : int):
		id = id_p
		priority = priority_p
		draw_command = draw_command_p
