extends Camera2D

var dragging := false
var last_mouse_pos := Vector2.ZERO

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				dragging = true
				last_mouse_pos = event.position
			else:
				dragging = false

	if dragging and event is InputEventMouseMotion:
		var delta = event.position - last_mouse_pos
		position -= delta
		last_mouse_pos = event.position
