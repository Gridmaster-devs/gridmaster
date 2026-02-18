class_name CustomGraphics
extends Node2D
## Class that stores custom draw commands and executes them

## The draw commands to be executed
var _draw_commands : Array[Callable]


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
