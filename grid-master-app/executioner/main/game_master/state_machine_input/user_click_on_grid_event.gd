class_name GridTileClickedEvent
extends GameplayEvent

var mouse_button : MouseButton ## Which mouse button was clicked
var grid_pos : Vector2i ## Which grid tile was clicked. (-1, -1) if user clicked outside the grid.

func _init(button : MouseButton, pos : Vector2i):
	mouse_button = button
	grid_pos = pos
