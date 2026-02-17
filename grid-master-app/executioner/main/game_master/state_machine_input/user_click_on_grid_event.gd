class_name UserClickOnGridEvent
extends StateMachineEvent

var mouse_button : MouseButton ## Which mouse button was clicked
var button_up : bool ## Whether the mouse button was pressed down or lifted up
var grid_pos : Vector2i ## Which grid tile was clicked. (-1, -1) if user clicked outside the grid.
